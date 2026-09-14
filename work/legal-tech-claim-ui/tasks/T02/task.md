# T02 — View `legal_v_tech_claim`: сроки, степени, колонки отчёта

Статус: done
План: [plan.md](../../plan.md)
Зависимости: [T01](../T01/task.md)
Сложность: medium — доработка существующей view по зафиксированному контракту
(имена колонок расчёта и формулы степеней известны), новые IT
Сложность проверки: medium — полный `:app:test` плюс SQL-фикстуры на
локальной БД относительно `current_date`; браузер не нужен
Актуальная проверка: [checks/001.md](checks/001.md)

## Коротко

Грид претензий читает db-view, чтобы фильтровать и сортировать всю выборку в
БД. Сейчас view отдаёт поля четырёх таблиц и суммы, но не отдаёт семь сроков
этапов, степени просрочки и часть колонок старого отчёта. Таск дополняет
view и её entity `VLegalTechClaim`, чтобы список T04 мог показать все колонки
отчёта «Перечень вагонов» и фильтровать по срокам.

## Результат и контекст

Существующая view (после T01 — `legal_v_tech_claim`, changelog
`02_view/independent/legal_v_tech_claim.xml`, entity `VLegalTechClaim`,
104 колонки): `deps ⨝ repair ⟕ du ⟕ case_one`, `where deps.deleted_date is
null`, одна строка на неудалённую претензию, вычисляемые
`downtime_penalty_cost`, `tariff_rebill_total_calc`, `total_reimbursement`,
`underpaid_cost`, `rejected_cost`, `in_review_cost`, `claim_deadline_date`.
Что и как считалось — `result.md` T02 прежней работы
(`../../../dr-warranty-repair-rename-ui/tasks/T02/result.md`).

Таблица расчёта `legal_tech_claim_deadlines` (entity `LegalTechClaimDeadline`,
уникальный `deps_id`): `revision_number`, `calculated_date` и по семи этапам
четыре даты — `<stage>_due_date`, `<stage>_level1_date`, `_level2_date`,
`_level3_date`, где `<stage>` ∈ `doc_attach`, `pre_claim_transfer`,
`pre_claim_letter`, `claim_transfer`, `claim_submit`, `law_transfer`,
`lawsuit_submit` (порядок — семь этапов старой процедуры `Srok_PassDoc`,
`Srok_FilG`, `Srok_DoPret`, `Srok_PassPP`, `Srok_Pret`, `Srok_PassSud`,
`Srok_Sud`). Контракт актуальности и таблица дат факта — раздел «Расчёт
сроков» в [документе отличий](../../input/calendar-behavior-differences.md).

Нужно добавить во view:

1. `LEFT JOIN legal_tech_claim_deadlines dl ON dl.deps_id = deps.id`
   (число строк не растёт — `deps_id` уникален).
2. Семь `<stage>_due_date` как есть.
3. Семь `<stage>_overdue_level smallint`: факт завершения этапа по таблице
   документа отличий (порядок `coalesce` строго как в SQL, `Send_PD` —
   эффективный `coalesce(deps.claim_transfer_date, du.claim_date)`), иначе
   `current_date`; затем `case when fact > level3 then 3 when fact > level2
   then 2 when fact >= level1 then 1 end`; `NULL`, если срок не назначен.
4. `deadlines_outdated boolean`: `dl.deps_id is null or dl.revision_number
   <> (select max(revision_number) from nsi_term_revision where status =
   'PUBLISHED')` — точное имя/значение статуса взять из
   `NsiTermRevision`/`TermRevisionStatusEnum`.
5. Колонки отчёта со статусом `добавить` и `вычисл.` из
   [report-columns.md](../../input/report-columns.md) (36 + 4): поля
   таблиц прокидываются как есть; вычисляемые — `defect_code_123`
   (`000+000+000` по `defect_code_1..3`, как `Neispr_kod123` в SQL),
   `pre_claim_review_days`, `claim_review_days`, `lawsuit_rejected_cost`,
   `claim_transfer_date_effective`. Формулы брать из
   [полного SQL](../../input/pThp_PretTehSelect2.sql) (искать `DoPret_OtvSut`,
   `Gar_RassmSut`, `Sud_SumOtkaz`, `Tarif_Sum1`); `Tarif_Sum1` сверить с
   существующей `tariff_rebill_total_calc` и при расхождении завести отдельную
   колонку.
6. `COMMENT ON` для всех новых колонок; entity и i18n сгенерировать из
   фактической структуры view (как сделано в прежней итерации, чтобы C2
   выполнялся по построению).

Второй changeSet в том же файле (`create or replace view` поверх, либо
`dropView ifExists` + `createView` с `runOnChange`) — существующие колонки
не переписывать без нужды. preConditions: существование таблиц раздела и
`nsi_term_revision`.

## Область и изоляция

Меняет: `02_view/independent/legal_v_tech_claim.xml`, `VLegalTechClaim`,
`TechClaimViewIT`, блок ключей `…legal.techclaim/VLegalTechClaim.*` в
`messages_ru.properties`. Не трогать: таблицы, сервисы расчёта, роли.
Общие ресурсы: БД, Gradle daemon. Параллельно с T03 (файлы не пересекаются;
`messages_ru.properties` — перечитать перед правкой, добавлять только свой
блок). Проверка — после T01, до T03.

## Реализация

Образцы `@DbView`: `dt/entity/DtVOperRepair.java`, текущая `VLegalTechClaim`.
Скилы: `jmix-create-liquibase-changelog`, `jmix-create-dto-entity` (для
`@DbView`-entity), `jmix-add-i18n-keys`, `jmix-create-test`. Степени в entity
— `Integer` + аксессор `ClaimTermOverdueLevelEnum` (паттерн enum-полей
проекта). Даты «сегодня» только `current_date` БД. Не считать рабочие дни в
SQL — только сравнения с сохранёнными порогами.

## Критерии приёмки

- C1: Liquibase создаёт view с нуля; `select * from legal_v_tech_claim
  limit 10` выполняется; на претензию одна строка (в т. ч. без `du`,
  `case_one`, `deadlines`).
- C2: у каждого поля `VLegalTechClaim` есть колонка view того же типа и
  наоборот; все колонки `report-columns.md` со статусом ≠ `нет` присутствуют.
- C3: семь `*_due_date` равны значениям таблицы расчёта; степени проверены
  на фикстурах до/на/после порогов +1/+10/+30 (на дате ровно level2/level3
  сохраняется предыдущая степень, на level1 — уже 1); завершённый этап
  фиксирует степень по факту, открытый использует `current_date`.
- C4: `deadlines_outdated` истинен при отсутствии строки расчёта и при
  устаревшем `revision_number`, ложен при актуальном; отличается от
  неприменимого этапа (`due_date is null`, `outdated = false`).
- C5: JPQL-фильтр/сортировка/count по `*_overdue_level`, `*_due_date` и
  вычисляемым суммам выполняются в БД (IT с `maxResults(1)` на выборке из
  двух подходящих строк возвращает старшую по сортировке; count = 2).
- C6: `./gradlew :app:test` — `0 failing`.

## Самопроверка исполнителя

```bash
./gradlew :app:compileJava spotlessApply
./gradlew :app:test --tests "ru.fgk.ws.app.it.TechClaimViewIT"
docker exec docker-rvk-db-1 psql -U root -d postgres -c "select count(*) from information_schema.columns where table_schema='main' and table_name='legal_v_tech_claim';"
```

Один smoke: SQL-фикстура с претензией и строкой расчёта, у которой
`level1_date = current_date - 1` — степень 1. Полный `:app:test` не
запускать. Точные команды — в `result.md`.

## Независимая проверка

Пересоздать view (удалить view и строки `databasechangelog` по имени файла),
прогнать `./gradlew :app:test`. Затем SQL-сценарий в транзакции с `rollback`
(образец `../../../dr-warranty-repair-rename-ui/tasks/T02/checks/fixtures_c3_c5.sql`):
отцепка + четыре претензии — с расчётом актуальной ревизии, с расчётом
устаревшей ревизии, без расчёта, с `deleted_date`; для актуальной — пороги
относительно `current_date` в трёх положениях. Сверить C1–C5, число строк
view = 3. Проверить регрессию сумм: значения `total_reimbursement`,
`underpaid_cost` и др. на тех же фикстурах не изменились относительно
формул из `result.md` прежней итерации. Данные убрать.

## Прогресс и продолжение

- [x] Выписать формулы факта завершения и недостающих колонок из SQL.
- [x] Второй changeSet view: join расчёта, сроки, степени,
      `deadlines_outdated`, колонки отчёта.
- [x] Перегенерировать `VLegalTechClaim` и i18n из структуры view.
- [x] Дополнить `TechClaimViewIT` (степени, актуальность, фильтр в БД).
- [x] Самопроверка, [result.md](result.md).
- [x] Передать результат на независимую проверку.
- [x] Независимая проверка: критерии C1–C6 подтверждены ([checks/001.md](checks/001.md)).

Ближайший шаг: таск T03 (`../T03/task.md`) — роли ДЭПС, ДЮ и администратора с
политиками доступа, сервис `TechClaimService.createClaim`.
Препятствия: нет.
