# Task 03 (P1): Seq-scan таблиц-зеркал `ws_store` (wagnum, pt_1c_balance)

## Проблема

Два самых горячих обращения наработки идут в внешнюю схему `ws_store`, где индексов нет:

### 1. Поиск ремонта: `f_diadoc_connection_tr2` / `f_diadoc_connection_plan`

Функция на каждом из 4 уровней поиска фильтрует
`ws_store.dr_wag_oper_repair_contract WHERE d.wagnum = a_wagnum`
(`app/.../liquibase/changelog/03_fn/fn-f_diadoc_connection_tr2.xml:58, 73, 90, 107`),
плановая — аналогично `ws_store.dr_wag_plan_repair_contract`
(`fn-f_diadoc_connection_plan.xml`).

Вызывается на каждый пакет ремонтного канала:
`DiadocWagOperRepairContractNativeRepositoryImpl.java:39-59`
(`SELECT * FROM f_diadoc_connection_tr2(...)`, параметр `wagnum`) из
`DrOperRepairTr2ParserService` / `DrPlanRepairParserService`.

Индексов по `wagnum` нет: в `migration/ws_store/migrator/01_tbl/` файлы
`tbl_20241217_dr_wag_oper_repair_contract.xml`, `tbl_20241217_dr_wag_plan_repair_contract.xml`
не содержат ни одного `createIndex`. Плюс join на view `rp_v_repair` без гарантии pushdown
предиката.

### 2. Остатки: `ws_store.pt_1c_balance`

View `main.v_pt_1c_balance` — простой `select ... from ws_store.pt_1c_balance`
(`02_view/independent/01-v_pt_1c_balance.xml`); в
`migration/ws_store/migrator/01_tbl/tbl_20250526_pt_1c_balance.xml` индексов нет.
Запрос `Pt1cBalanceLookup.findAllByDetailUidHash` (см. task 02) — seq-scan таблицы
остатков на каждую строку МХ-3.

## Ограничение

`migration/ws_store` — read-only зона (AGENTS.md §11): миграции внешней схемы в этом
репозитории — описание чужой структуры, индексы там создаёт владелец зеркала.
Прямое «добавить createIndex в миграцию» невозможно без согласования.

## Варианты (по убыванию предпочтения)

1. **Запросить у владельца `ws_store`** индексы:
   - `dr_wag_oper_repair_contract (wagnum) WHERE recdelete_dt IS NULL`
     (или INCLUDE `repair_uid`);
   - `dr_wag_plan_repair_contract (wagnum) WHERE recdelete_dt IS NULL`;
   - `pt_1c_balance (detail_uid_hash)` (+ депо/дата, если фильтр по ним есть в view).
2. **Материализация горячих срезов в основной схеме** своей Liquibase-миграцией
   (02_view/таблица + регулярное обновление): например, таблица остатков, отфильтрованная
   по нужным колонкам, с своим индексом. Тянет за собой задачу обновления — рассматривать
   только если п.1 отвергнут.
3. **Кэш в приложении** для `Pt1cBalanceLookup` (по аналогии с `ValidationDictionaryService`
   / `PartTypeDiadocResolverService`, кэш 5 мин) — смягчает повторные вызовы, но не первый
   доступ; допустимо как временная мера.

## Проверка

```sql
EXPLAIN (ANALYZE, BUFFERS)
SELECT * FROM main.f_diadoc_connection_tr2(71345678::numeric, NULL, NULL, NULL,
    '2026-06-01'::timestamp, 72, 72, 72);
-- до: Seq Scan on dr_wag_oper_repair_contract (x4 уровня)
-- после: Index Scan / Bitmap Index Scan по wagnum
```

`pg_stat_statements`: `mean_exec_time` вызова функции и запроса к `v_pt_1c_balance`
до/после.
