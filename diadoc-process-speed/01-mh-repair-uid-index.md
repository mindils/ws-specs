# Task 01 (P1): Потерянный индекс `repair_uid` на `dr_diadoc_wag_oper_repair_contract_mh`

## Проблема

В миграции
`app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/01-tbl/024-dr_diadoc_wag_oper_repair_contract_mh.xml`
индекс с именем `IDX_DR_DIADOC_WAG_OPER_REPAIR_CONTRACT_MH_REPAIR_UID` создан по колонке
**`repair_uid_plan`** — copy-paste ошибка, и она продублирована в двух changeSet-ах:

```xml
<!-- строки 122-125 (changeSet 1) и 217-220 (changeSet 8) -->
<createIndex indexName="IDX_DR_DIADOC_WAG_OPER_REPAIR_CONTRACT_MH_REPAIR_UID"
             tableName="dr_diadoc_wag_oper_repair_contract_mh">
  <column name="repair_uid_plan"/>   <!-- должно быть repair_uid -->
</createIndex>
```

В итоге на таблице есть два индекса по `repair_uid_plan` и **нет ни одного, пригодного для
фильтрации по `repair_uid`**: композитный
`IDX_..._MH_OPER_REPAIR_RELATION (detail_uid, repair_uid)` (строки 130-134, 259-263)
для этих запросов бесполезен — ведущая колонка `detail_uid` в предикате не участвует.

## Почему тормозит

Запросы вида `where r.id = :repairUid` через join по FK `repair_uid` выполняются
seq-scan'ом всей таблицы МХ (общая таблица строк МХ-1/МХ-3 обоих каналов, растёт каждым
пакетом):

- `MhDetailOriginService.loadOurMh3Rows` — `dr/service/MhDetailOriginService.java:217-236`
  (`left join e.repairUid r ... where r.id = :repairUid`);
- `MhDetailOriginService.loadOurMh1DetailUids` — там же, `:238-252`;
- все остальные обращения к строкам МХ по ремонту (content-сервисы, валидации,
  `mhRelationValidationService.validateByRepairUid`).

Вызывается на **каждый** пакет ремонтных каналов (ТР-2, ДЕП/КАП). Соседние таблицы
миграций 021/022/026 индексы по `repair_uid` имеют — дефект локальный для 024.

## Фикс

Новый changeSet в `024-...xml` (или отдельный файл `idx-dr_diadoc_wag_oper_repair_contract_mh_repair_uid.xml`
по конвенции именования индексов), author `dr`:

- `createIndex` по колонке `repair_uid` с `preConditions` (`not indexExists`);
- имя — новое, например `IDX_..._MH_REPAIR_UID_OPER`, т.к. старое имя уже занято
  индексом по `repair_uid_plan` (в живой БД);
- решение по старым дублям: индекс с именем `..._REPAIR_UID` (фактически по
  `repair_uid_plan`) — дубликат `..._REPAIR_UID_PLAN`; удалить его отдельным changeSet
  с `preConditions onFail="MARK_RAN"` (`indexExists`), чтобы снять лишний записываемый
  индекс на массово вставляемой таблице.

Правила: preConditions обязательны; текст `createTable` changeSet-а не переписывать
задним числом — индекс добавляется отдельным changeSet-ом; перед правкой сверить
фактическое состояние индексов живой БД (MCP `rvk-ws`, запросы в `00-overview.md`).

## Проверка

```sql
-- после применения: индекс по repair_uid есть, дубля нет
SELECT indexname, indexdef FROM pg_indexes
WHERE tablename = 'dr_diadoc_wag_oper_repair_contract_mh';

-- EXPLAIN: index scan вместо seq scan
EXPLAIN (ANALYZE, BUFFERS)
SELECT mh.id FROM main.dr_diadoc_wag_oper_repair_contract_mh mh
LEFT JOIN main.dr_diadoc_wag_oper_repair_contract r ON mh.repair_uid = r.id
WHERE mh.is_mh3 = true AND r.id = :repairUid;
```

Прогон: `./gradlew :app:test` (IT-тесты на базе `BaseIT` проходят путь парсеров МХ,
например `DiadocPacketCorrectionIT`, `DrOperRepairTr2ParserServiceIT`).
