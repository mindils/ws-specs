# Результат T02 — итерация 1 (частичная, на проверку НЕ передана)

Таск: [task.md](task.md)
Дата: 2026-09-11
Состояние кода: ветка `feature/caseone-table`, базовый коммит `f2b96adc2 «step 1»`,
изменения T01 и T02 в рабочем дереве (не закоммичены).
Окружение: Docker Compose, `docker-rvk-db-1` PostgreSQL 16.11 на `localhost:5432`,
`app/src/test/resources/application-test-local.properties`.

**Статус: реализована только часть таска, независимая от T08.** Блок семи сроков
и степеней просрочки (C6, C7 и часть C8) не реализован: таблицы
`main.dr_warranty_repair_deadlines` нет ни в коде, ни в БД, её состав колонок и
контракт актуальности расчёта определяет ещё не выполненный T08. Подробности —
в разделе «Что не сделано».

## Фактическое поведение

Появилась view `main.dr_v_warranty_repair_claim` — источник данных для гридов
T04 (ДЭПС) и T05 (ДЮ). Одна строка = одна не удалённая претензия.

- Состав: `dr_warranty_repair_deps` ⨝ `dr_warranty_repair` (по `repair_uid`)
  ⟕ `dr_warranty_repair_du` ⟕ `dr_warranty_repair_case_one` (по `deps_id`),
  `where deps.deleted_date is null`. Всего 104 колонки.
- Претензия без строки `_du` и/или без `_case_one` из выборки не исчезает,
  вычисляемые поля по ней дают `NULL`, а не ошибку.
- Вычисляемые суммы и срок предъявления считаются в самой view, поэтому
  фильтрация, сортировка, count и пагинация по ним выполняются в БД.

Семь вычисляемых колонок по таблице формул из постановки:

| Колонка | Реализация |
|---|---|
| `downtime_penalty_cost` | `downtime_days * downtime_penalty_per_day` |
| `tariff_rebill_total_calc` | `nullif(greatest(coalesce(invoice_for_repair_cost,0) + coalesce(invoice_after_repair_cost,0) + coalesce(calculated_invoice_cost, broken_tariff_cost, 0), 0), 0)` |
| `total_reimbursement` | сумма трёх слагаемых через `coalesce`; `NULL`, если пусты все три |
| `underpaid_cost` | `claim_result = 1` → `claim_cost`; `= 3` → `at_fault_accepted_cost`; иначе `pre_claim_result = 1` → `pre_claim_cost`; минус `coalesce(payment_cost, 0)` |
| `rejected_cost` | `claim_result = 2` → `claim_cost`; `= 3` → `claim_cost − at_fault_accepted_cost` |
| `in_review_cost` | `claim_cost`, пока `claim_result is null` |
| `claim_deadline_date` | `(repair_date + interval '1 year')::date` |

## Изменённые области

| Файл | Что |
|---|---|
| `app/.../liquibase/changelog/02_view/independent/dr_v_warranty_repair_claim.xml` | новый; `author = dr`, `runOnChange`, preConditions по четырём базовым таблицам, `dropView ifExists` + `createView`, `COMMENT ON` на view и все 104 колонки |
| `app/.../legal/warrantyrepair/entity/VWarrantyRepairClaim.java` | новый; `@DbView` + `@JmixEntity(name = "legal_VWarrantyRepairClaim")`, 104 поля, PK `id` (= `deps.id`), `@InstanceName` на `wagnum`, 9 enum-аксессоров, из Lombok только `@Getter`/`@Setter` |
| `app/src/main/resources/ru/fgk/ws/app/messages_ru.properties` | +105 ключей (сущность и все её атрибуты); в модуле `app` это единственный locale-файл |
| `app/src/test/java/ru/fgk/ws/app/it/WarrantyRepairClaimViewIT.java` | новый; 3 интеграционных теста |

Файлы проверки в `checks/`: `verify_c2.py` (сверка entity ↔ view),
`fixtures_c3_c5.sql` (фикстуры C3–C5, весь скрипт в транзакции с `rollback`).

## Существенные решения

1. **Имя файла changelog** — `dr_v_warranty_repair_claim.xml` без числового
   префикса: по CLAUDE.md независимые views именуются `feature_v_name.xml`.
2. **`total_reimbursement` = `NULL`, когда пусты все три слагаемых.** В гриде
   пустая претензия иначе показывала бы `0.00` как достоверный итог. Если хотя
   бы одно слагаемое заполнено, остальные берутся как `0` через `coalesce` —
   как требует постановка.
3. **`claim_deadline_date` приведён к `date`** (`::date`), а не оставлен
   `timestamp`: это срок, а не момент; так он фильтруется как дата и маппится
   на `LocalDate`.
4. **`downtime_penalty_cost` считается только по сохранённому `downtime_days`.**
   Старый `Straf_Summ` использовал `isnull(ProstSut, формула)` с запасным
   расчётом простоя из `Neispr_dt → Dat_Rem`. Таблица формул в постановке задаёт
   произведение без запасной ветки, реализовано по ней. Если в форме T04 нужен
   показ расчётного простоя при пустом `downtime_days` (старое `ProstSut_Edit`),
   это отдельное решение — отметить при разработке T04.
5. **Коллизия имён `_deps` и `_du`.** `rework_return_date` и
   `rework_return_rk_number` есть в обеих таблицах; колонки зоны ДЮ выведены как
   `du_rework_return_date` и `du_rework_return_rk_number`.
6. **Entity сгенерирована из фактической структуры view** (`information_schema`),
   а не написана вручную, — поэтому C2 выполняется по построению. Javadoc полей и
   тексты i18n взяты из тех же `COMMENT ON COLUMN`, так что подписи и комментарии
   БД не расходятся.
7. **Ролей таск не трогает.** `@EntityPolicy` на `VWarrantyRepairClaim` нужны
   ролям зон ДЭПС и ДЮ, которые создаются в T04 и T05 — без них грид не прочитает
   view. Вынесено в «Передать дальше».

## Команды и итоги предварительных проверок

```bash
# Гейт 1
./gradlew :app:compileJava            # BUILD SUCCESSFUL
./gradlew spotlessCheckAll            # BUILD SUCCESSFUL

# Гейт 2
./gradlew :app:test                   # 1268 passing, 12 pending, 1 failing
./gradlew :app:test --tests "ru.fgk.ws.app.it.WarrantyRepairClaimViewIT"   # 3 passing

# C2
python3 specs/work/dr-warranty-repair-rename-ui/tasks/T02/checks/verify_c2.py

# C1, C3, C4, C5 на локальной БД
docker exec -e PGPASSWORD=root docker-rvk-db-1 psql -U root -d postgres \
  -c "select count(*) from main.dr_v_warranty_repair_claim;"
docker cp specs/work/dr-warranty-repair-rename-ui/tasks/T02/checks/fixtures_c3_c5.sql \
  docker-rvk-db-1:/tmp/f.sql
docker exec -e PGPASSWORD=root docker-rvk-db-1 psql -U root -d postgres \
  -v ON_ERROR_STOP=1 -f /tmp/f.sql
```

**Гейт 1** — IDE-инспекция в этой сессии недоступна (MCP JetBrains не подключён),
использован откат: `compileJava` + `spotlessCheckAll` + механические проверки из
`jmix-ide-static-analysis`. Оба новых файла непустые, у `.java` есть строка
`package`, XML разбирается парсером и начинается с `<?xml`. `*-view.xml` в таске
нет, поэтому ключей `msg://` и property paths тоже нет — основной класс дефектов,
который ловит только инспекция, здесь не возникает. XML changelog проверен
сильнее статики: Liquibase реально применил его к чистой БД. **Долг:** оба новых
файла получили только компиляцию — переинспектировать в сессии, где инспекция
подключена.

**Гейт 2** — `:app:test`: 1268 passing, 12 pending, 1 failing. Единственное
падение — `ru.fgk.ws.app.sso.SsoOidcUserMapperConcurrencyIT
.concurrentLoginsOfTheSameUserDoNotFail` (`OptimisticLockException`,
EclipseLink-5006). Это фоновый дефект ветки по SSO: он вынесен в [Q03](../../questions/Q03.md)
и в отдельный таск T09, зафиксирован на базовой линии ветки в отчёте проверки
T01 ([../T01/checks/002.md](../T01/checks/002.md), пункт 6) с теми же
1265 passing / 12 pending / 1 failing. После T02 прибавилось ровно три
проходящих теста, состав падений не изменился. К гарантийным ремонтам отношения
не имеет.

**Гейт 3** — не применим: views UI в таске нет.

### Что проверено фактически

| Критерий | Итог | Доказательство |
|---|---|---|
| C1 | Выполнен | View удалена вручную, запись из `databasechangelog` удалена, после прогона теста Liquibase создал её заново (`EXECUTED`, `author = dr`). `select * from dr_v_warranty_repair_claim` отрабатывает. |
| C2 | Выполнен | `verify_c2.py`: полей entity 104, колонок view 104, расхождений имён и типов нет. |
| C3 | Выполнен | Фикстуры: простой 7 × 1500.00 = **10500.00**; перевыставление 12000.50 + 8000.25 + 3000.0000 = **23000.75** (`calculated_invoice_cost` имеет приоритет над `broken_tariff_cost` = 999.99); ВСЕГО 50000.00 + 23000.75 + 10500.00 = **83500.75**. Дополнительно проверены `underpaid_cost` по всем трём веткам (15000.00 при `claim_result=3`, 6000.00 при `=1`, 5000.00 через `pre_claim_result=1`), `rejected_cost` (23500.75 при `=3`, 2500.00 при `=2`), `in_review_cost` (7777.77 при пустом результате), запасная ветка `broken_tariff_cost` (100.00 + 50.00 = 150.00) и `claim_deadline_date` (2025-03-15 → 2026-03-15). |
| C4 | Выполнен | Претензия с `deleted_date` не видна: `deleted_rows_visible = 0`; в IT `deletedClaimIsNotVisible`. |
| C5 | Выполнен | Претензия без `_du` и без `_case_one` присутствует, вычисляемые поля дают `NULL` без ошибок; из 6 вставленных претензий видны 5 (шестая удалена), по одной строке на претензию — внешние джойны не размножают выборку. |
| C6 | **Не реализован** | Нет таблицы T08. |
| C7 | **Не реализован** | Нет таблицы T08. |
| C8 | Выполнен частично | По суммам подтверждено интеграционным тестом `computedColumnIsFilteredAndCountedInDatabase`: условие `totalReimbursement > 0` с `maxResults(1)` при двух подходящих строках возвращает именно старшую по сортировке — значит фильтр и сортировка ушли в запрос, а не отработали по загруженной странице; `count` по вычисляемой колонке в JPQL даёт 2. По степеням просрочки и смене дня — не проверено, нет предмета проверки. |

Данные фикстур после проверок удалены: SQL-скрипт завершается `rollback`,
интеграционный тест чистит за собой в `@AfterEach`; контрольный запрос
показывает 0 строк во всех четырёх таблицах и во view.

## Что не сделано и почему

Блокер — **T08 в статусе `todo`** (он сам зависит от `todo`-таска T07). Таблицы
`main.dr_warranty_repair_deadlines` нет ни в коде, ни в схеме `main`; её состав
колонок, идентификатор ревизии календаря и контракт «расчёт отсутствует /
устарел / успешен с неприменимыми этапами» определяет именно T08.

Не реализовано:

- LEFT JOIN `dr_warranty_repair_deadlines` по `deps_id`, семь дат окончания
  этапов и семь кодов степени просрочки (сравнение с порогами +1/+10/+30 по
  дате БД), признак «Требуется пересчёт» — критерии C6, C7 и часть C8;
- тест границы дня и согласование единой даты «сегодня» между Java и PostgreSQL.

Написанное сейчас этому не противоречит: блок сроков добавляется в view
**вторым changeSet** в том же файле (`create or replace view` поверх текущего
определения) и дополнительными полями entity, переписывать текущие колонки не
потребуется.

## Передать дальше

- **T08** фиксирует имя и состав колонок `main.dr_warranty_repair_deadlines`,
  включая признак актуальности расчёта. После его `done` T02 продолжается с
  шага «Присоединить семь сроков T08».
- **T04 и T05**: источник гридов готов к использованию по суммам и колонкам
  отцепки/претензии/ДЮ/Case.one. Ролям зон ДЭПС и ДЮ нужен `@EntityPolicy` с
  `READ` на `VWarrantyRepairClaim` и `@EntityAttributePolicy` — иначе грид
  ничего не прочитает. Колонки сроков появятся позже, верстать грид под них
  можно только после возврата T02 из блокировки.
- Наблюдение вне объёма таска: в репозитории есть два 0-байтовых дескриптора,
  `app/.../diadoc/view/packetdocument/packet-document-detail-view.xml` и
  `packet-document-list-view.xml`. Они закоммичены в `HEAD` (`0c510be9f`), в этой
  работе не затрагивались и на `:app:test` сейчас не влияют, но по правилам
  проекта пустой `*-view.xml` способен отравить реестр view. Стоит отдельной
  задачи.
