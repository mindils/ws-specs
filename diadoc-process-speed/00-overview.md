# 00. Обзор: ускорение наработки пакетов Diadoc (`/api/diadoc/processPacket`)

## Цель

Устранить причины медленной обработки (наработки) пакетов Diadoc в rvk-ws: от seq-scan'ов
неиндексированных таблиц и N+1-запросов до избыточно широкой advisory-блокировки.

## Цепочка обработки (что именно тормозит)

```text
NiFi → GET /api/diadoc/processPacket
  → PacketParserRestController (diadoc/controller/PacketParserRestController.java:42-56)
  → PacketParserService.parsePacket (diadoc/service/PacketParserService.java:76-89)
  → DiadocLocalPacketService.loadOrSync (diadoc/service/DiadocLocalPacketService.java:125-137)
      при отсутствии пакета в зеркале — синхронный REST-вызов к rvk-diadoc (task 05)
  → LocalPacketReportFactory.buildReport
  → dispatch → парсеры:
      TR2/ДЕП/КАП → AbstractDrRepairPacketParserService (dr/service/...:211-344)
      TR1, PARTS_REPAIR, REMOVED_PARTS, RECLAMATION, VU23, MAINTAINABILITY, PARTS — свои парсеры
  → DiadocPacketCheckResultService.findCheckResult
```

Внутри ремонтных каналов (ТР-2, ДЕП/КАП) фаза записи — одна транзакция
(`AbstractDrRepairPacketParserService.java:315-343`), в которой под advisory-локом
ремонта выполняются: очистка delete+insert, сохранение строк, `resolveOrigins`
(N+1, task 02) и валидации.

## Сводка проблем

| Task | Приоритет | Проблема | Где |
|------|-----------|----------|-----|
| [01](./01-mh-repair-uid-index.md) | P1 | Индекс `IDX_..._MH_REPAIR_UID` создан по колонке `repair_uid_plan` (copy-paste-дефект); отдельного индекса по `repair_uid` нет → seq-scan таблицы МХ на каждый пакет | `liquibase/changelog/01-tbl/024-dr_diadoc_wag_oper_repair_contract_mh.xml:122-128, 217-226` |
| [02](./02-resolve-origins-batching.md) | P1 | N+1: до 4-5 запросов к БД на каждую номерную строку МХ-3 в `resolveOrigins` | `dr/service/MhDetailOriginService.java:106-160` |
| [03](./03-ws-store-mirror-indexes.md) | P1 | Seq-scan `ws_store.dr_wag_oper_repair_contract` / `dr_wag_plan_repair_contract` по `wagnum` в `f_diadoc_connection_tr2/_plan`; `pt_1c_balance` без индексов | `03_fn/fn-f_diadoc_connection_tr2.xml`, миграции `migration/ws_store` |
| [04](./04-advisory-lock-scope.md) | P2 | Advisory-lock на ключ ремонта удерживается всю транзакцию со всем N+1 и валидациями → сериализация параллельной наработки одного ремонта | `AbstractDrRepairPacketParserService.java:327` |
| [05](./05-sync-on-demand-latency.md) | P2 | Синхронный REST-вызов к rvk-diadoc внутри пользовательского HTTP-запроса при отсутствии пакета в зеркале | `DiadocLocalPacketService.java:125-137`, `SyncPacketService.java:27-42` |
| [06](./06-recreate-delete-insert.md) | P2 | Полный delete+insert без diff при переобработке пакета | `DrTr2PacketCleaner.java:28-38`, `DrPlanRepairParserService.java:73-81`, `Vu23PacketParserService.java:254-255` |
| [07](./07-misc.md) | P3 | `Pattern.compile` внутри метода построчно; линейные `anyMatch/filter` на каждую строку работ | `DiadocDetailAttributeResolverService.java:307`, `RepairWorkClassificationService.java:72-104` |

## Порядок выполнения

1. **Task 01** — один недостающий индекс, минимальный риск, максимальный эффект.
2. **Task 02** — батчинг запросов в `resolveOrigins`; после 01 эффект seq-scan'ов уже меньше,
   но сотни round-trip остаются.
3. **Task 03** — требует согласования (внешняя зона `ws_store`), начинать параллельно с 01-02.
4. **Task 04** — после 02 (пока N+1 внутри, сужение лока лишь частично помогает).
5. **Tasks 05-07** — по мере возможности.

## Диагностика перед правками

Подключённый в сессии postgres-MCP был подключён к другой БД (схем `main`/`ws_store` нет) —
фактическое состояние индексов живой БД обязательна к проверке через MCP `rvk-ws`:

```sql
-- факт по индексам (схема main):
SELECT schemaname, tablename, indexname, indexdef
FROM pg_indexes
WHERE tablename IN ('dr_diadoc_wag_oper_repair_contract_mh',
                    'diadoc_packet_doc_link', 'diadoc_packet_doc',
                    'diadoc_packet_doc_operation');

-- факт по зеркалу (схема ws_store):
SELECT schemaname, tablename, indexname, indexdef
FROM pg_indexes
WHERE schemaname = 'ws_store'
  AND tablename IN ('dr_wag_oper_repair_contract', 'dr_wag_plan_repair_contract',
                    'pt_1c_balance');

-- размеры (понять, насколько болят seq-scan'ы):
SELECT relname, pg_size_pretty(pg_total_relation_size(c.oid))
FROM pg_class c JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname IN ('main', 'ws_store')
  AND relname IN ('dr_diadoc_wag_oper_repair_contract_mh', 'pt_1c_balance',
                  'dr_wag_oper_repair_contract', 'dr_wag_plan_repair_contract');
```

Профиль конкретной тормозящей обработки — `pg_stat_statements`
(`SELECT query, calls, mean_exec_time FROM pg_stat_statements ORDER BY mean_exec_time DESC LIMIT 30;`)
и `EXPLAIN (ANALYZE, BUFFERS)` на:

```sql
-- сигнатура: f_diadoc_connection_tr2(a_wagnum NUMERIC, a_defect_date, a_repair_date,
--   a_repair_date_vu36, a_act_date, a_depo_code SMALLINT, a_delta_plus_hours, a_delta_minus_hours)
SELECT * FROM main.f_diadoc_connection_tr2(71345678::numeric, NULL, NULL, NULL,
    '2026-06-01'::timestamp, 72, 72, 72);
SELECT ... FROM main.dr_diadoc_wag_oper_repair_contract_mh mh
  LEFT JOIN main.dr_diadoc_wag_oper_repair_contract r ON mh.repair_uid = r.id
 WHERE mh.is_mh3 = true AND r.id = :repairUid;   -- seq-scan до фикса task 01
```

## Критерий успеха

- `mean_exec_time` запросов пути наработки в `pg_stat_statements` снизился;
- пакет с десятками номерных деталей МХ-3 даёт O(1) запросов вместо O(N);
- `EXPLAIN` запросов по `repair_uid` и `wagnum` показывает index scan вместо seq scan;
- конкурентные пакеты одного ремонта не ждут друг друга дольше фазы реальной записи.
