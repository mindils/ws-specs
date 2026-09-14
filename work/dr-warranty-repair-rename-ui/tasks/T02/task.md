# T02 — DB-view с вычисляемыми полями для гридов

Статус: todo
План: ../../plan.md
Зависимости: [T01](../T01/task.md), [T08](../T08/task.md)
Результат: [result.md](result.md), итерация 1 (частичная, на проверку не передана)
Актуальная проверка: нет

## Результат и контекст

Старая процедура `pThp_PretTehSelect2` отдаёт помимо колонок таблицы ещё и
вычисляемые поля: суммы штрафа за простой, итог перевыставления тарифа,
«ВСЕГО к возмещению», недоплату, отклонённую сумму, срок предъявления
претензии. В новой модели они не хранятся.

Пользователь (ответ на вопрос 6 в `specs/dr-warranty-repair/06-open-questions.md`)
решил считать их db-view: по вычисляемым полям нужны **фильтры в гриде**.
Обычное Java-свойство `@JmixProperty` само по себе не предоставляет
фильтрацию всей выборки в БД. Уточнение [Q01](../../questions/Q01.md):
включить все семь сроков этапов, которые рассчитывает и сохраняет Java-сервис T08.

Результат: PostgreSQL view `dr_v_warranty_repair_claim` — одна строка на
претензию, джойн четырёх таблиц и таблицы расчётов плюс вычисляемые колонки, и `@DbView` entity
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
статус Case.one), плюс вычисляемые. Присоединить через LEFT JOIN
`dr_warranty_repair_deadlines` из T08 по уникальному `deps_id`: число строк
не увеличивается, претензия без расчёта не исчезает из списка.

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

### Семь сроков и актуальная просрочка

Добавить семь дат окончания и семь кодов степени просрочки с локализацией.
Даты и пороги +1/+10/+30 брать из таблицы T08, рабочие дни в SQL повторно
не рассчитывать. Цветовые коды не содержат CSS/RGB и не сохраняются.
Формулы завершения этапов — из полного
[SQL](../../input/pThp_PretTehSelect2.sql), ориентир —
[разбор](../../input/srok-calc-notes.md). Учесть подготовку эффективного
`Send_PD = coalesce(r.Send_PD, r.DatPret)` до расчёта сроков.

Сравнивать дату завершения этапа, иначе текущую дату, в порядке:
`> порога +30` → 3; `> порога +10` → 2; `>= порога +1` → 1;
иначе NULL. Сохранять точные неравенства и приоритеты дат факта.
Смена дня отражается при следующем запросе без изменения таблицы расчётов.
Java и PostgreSQL должны использовать одну дату «сегодня»: источник для
detail-preview — та же дата БД, что и у view, без зависимости от часового
пояса браузера. Добавить тест границы дня.

Статус актуальности расчёта отличает отсутствующую/устаревшую строку от
успешного расчёта с неприменимыми этапами. Даты/цвета неактуального расчёта
не показывать как достоверные; строка претензии остаётся видимой с понятным
признаком «Требуется пересчёт». Согласовать с контрактом ревизии T07/T08.

Фильтрация, сортировка, count и пагинация по суммам, датам и степеням
просрочки выполняются в БД. Не фильтровать лишь загруженную страницу Java-кодом.
Восьмой `Srok_FilOColor` и агрегаты отчётных `@Col` сейчас не переносить.

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
- C6: все семь сроков совпадают с результатом T08, на претензию по-прежнему
  одна строка. Отсутствующий расчёт виден как требующий пересчёта.
- C7: степени проверены до, на и после порогов +1/+10/+30; фактическое
  завершение фиксирует просрочку, открытый этап использует дату БД.
- C8: фильтры/count/сортировка корректны на выборке больше размера страницы;
  смена дня обновляет степень при чтении без записи ежедневных цветов.

## Проверка

```bash
./gradlew :app:compileJava
./gradlew :app:test
```

Плюс SQL-проверка на локальной БД: вставить отцепку и три претензии (одну с
`_du`, одну без, одну с `deleted_date`), сверить выборку из view с
критериями C3–C8. Для семи сроков использовать реальные результаты T08,
включая неприменимый этап и отсутствие расчёта. Границы «сегодня» в DB-view
проверять фикстурами относительно даты БД, без перевода системных часов.
Данные после проверки убрать.

Гейт 1: инспекция IDE по новым файлам; запасное — `compileJava` + скил
`jmix-ide-static-analysis`. Гейт 2: `:app:test`. Гейт 3 не применим —
views UI в этом таске нет.

Точные команды и SQL записать в `result.md`.

## Прогресс и продолжение

- [x] Определить состав колонок view по гридам T04/T05 и формулам из `02-old-procedure.md`.
- [x] Написать changelog `02_view/independent/dr_v_warranty_repair_claim.xml`.
- [x] Создать `VWarrantyRepairClaim` и i18n-ключи.
- [ ] Присоединить семь сроков T08, добавить актуальную просрочку и статус расчёта.
- [x] Проверить SQL-сценарии C3–C5 на локальной БД (C6–C8 по срокам — нечем).
- [ ] Передать результат на независимую проверку.

Часть, независимая от T08, реализована и проверена — см.
[result.md](result.md), итерация 1. Критерии C1–C5 выполнены, C8 выполнен
частично (по суммам). На проверку таск **не передан**: без блока сроков
критерии C6 и C7 не могут быть выполнены.

### Препятствие (обновлено 2026-09-11, сессия `task-execute`)

Проверенное состояние: ветка `feature/caseone-table`, базовый коммит
`f2b96adc2`, изменения T01 и T02 в рабочем дереве не закоммичены; Docker
Compose поднят, `docker-rvk-db-1` (PostgreSQL 16.11) доступен на `localhost:5432`.

1. **T01 — снят.** Таск переведён в `done` проверкой
   [../T01/checks/002.md](../T01/checks/002.md); переименования накатаны в
   рабочее дерево (таблицы `dr_warranty_repair*`, 175 колонок в БД). View T02
   построена уже на этих именах.
2. **T08 — `done` (2026-09-12). Блокировка полностью снята.**
   Таблица `main.dr_warranty_repair_deadlines` создана, расчёт 7 сроков в Java реализован
   и подтверждён проверкой [../T08/checks/001.md](../T08/checks/001.md). Состав колонок,
   даты порогов и контракт актуальности зафиксированы в
   [документе отличий](../../input/calendar-behavior-differences.md) и [результате T08](../T08/result.md).
   Все зависимости T02 (T01 и T08) переведены в статус `done`.

### Условие продолжения

Условие выполнено: T08 переведён в `done` независимой проверкой. Таск T02 готов к продолжению реализации.

Ближайший шаг после снятия блокировки: добавить в
`02_view/independent/dr_v_warranty_repair_claim.xml` **второй changeSet**
(`create or replace view` поверх текущего определения) с LEFT JOIN
`dr_warranty_repair_deadlines` по `deps_id`, семью датами окончания этапов,
семью кодами степени просрочки и признаком «Требуется пересчёт»; дополнить
`VWarrantyRepairClaim` и i18n соответствующими полями; добавить тест границы
дня. Существующие колонки переписывать не нужно. Формулы завершения этапов —
из `../../input/pThp_PretTehSelect2.sql`, ориентир —
`../../input/srok-calc-notes.md`. Q01 разрешён.
