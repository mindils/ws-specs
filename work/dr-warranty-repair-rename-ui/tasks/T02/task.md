# T02 — DB-view с вычисляемыми полями для гридов

Статус: todo
План: ../../plan.md
Зависимости: [T01](../T01/task.md)
Актуальная проверка: нет

## Результат и контекст

Старая процедура `pThp_PretTehSelect2` отдаёт помимо колонок таблицы ещё и
вычисляемые поля: суммы штрафа за простой, итог перевыставления тарифа,
«ВСЕГО к возмещению», недоплату, отклонённую сумму, срок предъявления
претензии. В новой модели они не хранятся.

Пользователь (ответ на вопрос 6 в `specs/dr-warranty-repair/06-open-questions.md`)
решил считать их db-view: по вычисляемым полям нужны **фильтры в гриде**, а
`@JmixProperty` фильтровать нельзя.

Результат: PostgreSQL view `dr_v_warranty_repair_claim` — одна строка на
претензию, джойн четырёх таблиц плюс вычисляемые колонки, и `@DbView` entity
поверх неё. Это источник данных для гридов T04 и T05.

## Реализация

Паттерн в проекте уже есть — копировать рабочее место вызова:

- entity: `app/src/main/java/ru/fgk/ws/app/dt/entity/DtVOperRepair.java`
  (`@DbView` + `@JmixEntity` + `@Table(name = "dt_v_oper_repair")` +
  `@Entity(name = "dt_VOperRepair")`), также `rp/entity/VRpOperDefect.java`;
- changelog: `app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/02_view/independent/`
  — сюда, зависимостей от `ws_store` у нашей view нет.

Создать:

- `app/.../liquibase/changelog/02_view/independent/dr_v_warranty_repair_claim.xml`
  (`author` = `dr`, preConditions обязательны,
  `objectQuotingStrategy="QUOTE_ONLY_RESERVED_WORDS"`, `createView`/`<sql>` с
  `create or replace view`);
- `app/src/main/java/ru/fgk/ws/app/legal/warrantyrepair/entity/VWarrantyRepairClaim.java`
  — `@DbView`, `@Table(name = "dr_v_warranty_repair_claim")`,
  `@Entity(name = "legal_VWarrantyRepairClaim")`, PK — `id` (это `deps.id`),
  `@InstanceName` на номер вагона, из Lombok только `@Getter`/`@Setter`;
- i18n-ключи сущности и всех её атрибутов в `messages_ru.properties`.

Состав view: `dr_warranty_repair` ⨝ `dr_warranty_repair_deps` (по
`repair_uid`) ⟕ `dr_warranty_repair_du` ⟕ `dr_warranty_repair_case_one` (по
`deps_id`), `WHERE deps.deleted_date IS NULL`. Прокинуть колонки, нужные
гридам обеих зон (номер вагона, дата браковки, дорога, депо, неисправность,
вид ремонта, виновник, индекс претензии, реестр ДЮ, ПСР, результаты,
статус Case.one), плюс вычисляемые.

Вычисляемые колонки — формулы в `specs/dr-warranty-repair/02-old-procedure.md`
(строки 222–351 и 389–426), имена колонок даны в новой номенклатуре после T01:

| Колонка view | Формула | Старое имя |
|---|---|---|
| `downtime_penalty_cost` | `downtime_days * downtime_penalty_per_day` | `Straf_Summ` |
| `tariff_rebill_total_calc` | `invoice_for_repair_cost + invoice_after_repair_cost + coalesce(calculated_invoice_cost, broken_tariff_cost, 0)`, `null` если ≤ 0 | `Tarif_Sum` |
| `total_reimbursement` | `warranty_repair_cost + tariff_rebill_total_calc + downtime_penalty_cost` | «ВСЕГО к возмещению» |
| `underpaid_cost` | `(claim_cost при claim_result = 1; at_fault_accepted_cost при 3; pre_claim_cost при pre_claim_result = 1) - payment_cost` | `Nedopl_money` |
| `rejected_cost` | `claim_cost` при `claim_result = 2`; `claim_cost - at_fault_accepted_cost` при 3 | `OtklRub` |
| `in_review_cost` | `claim_cost`, пока `claim_result` не проставлен | `SmotrRub` |
| `claim_deadline_date` | `repair_date + interval '1 year'` | `DatEndPret` |

Все денежные — `numeric`, сопоставить с `BigDecimal` в entity; сложение через
`coalesce(..., 0)`, иначе один `null` обнуляет всю сумму.

**Вне объёма:** `Srok_*` и цвета подсветки — см. [Q01](../../questions/Q01.md).
Колонки под них в view сейчас не заводить.

## Критерии приёмки

- C1: liquibase создаёт `main.dr_v_warranty_repair_claim`; `select * from
  dr_v_warranty_repair_claim limit 10` выполняется без ошибок.
- C2: у каждого поля `VWarrantyRepairClaim` есть колонка view того же типа;
  лишних колонок во view нет.
- C3: на претензии с заполненными суммами значения `downtime_penalty_cost`,
  `tariff_rebill_total_calc` и `total_reimbursement` совпадают с ручным
  расчётом по формулам выше.
- C4: строка с `deleted_date is not null` во view не попадает.
- C5: претензия без `_du` и без `_case_one` во view присутствует (внешние
  джойны), вычисляемые поля при этом не падают в ошибку.

## Проверка

```bash
./gradlew :app:compileJava
./gradlew :app:test
```

Плюс SQL-проверка на локальной БД: вставить отцепку и две претензии (одну с
`_du`, одну без, одну с `deleted_date`), сверить выборку из view с
критериями C3–C5. Данные после проверки убрать.

Гейт 1: инспекция IDE по новым файлам; запасное — `compileJava` + скил
`jmix-ide-static-analysis`. Гейт 2: `:app:test`. Гейт 3 не применим —
views UI в этом таске нет.

Точные команды и SQL записать в `result.md`.

## Прогресс и продолжение

- [ ] Определить состав колонок view по гридам T04/T05 и формулам из `02-old-procedure.md`.
- [ ] Написать changelog `02_view/independent/dr_v_warranty_repair_claim.xml`.
- [ ] Создать `VWarrantyRepairClaim` и i18n-ключи.
- [ ] Проверить SQL-сценарии C3–C5 на локальной БД.
- [ ] Передать результат на независимую проверку.

Ближайший шаг: прочитать `specs/dr-warranty-repair/02-old-procedure.md`
строки 222–351 и выписать точные формулы.
Препятствия: нет; `Srok_*` вынесены в [Q01](../../questions/Q01.md) и на этот
таск не влияют.
