# Результат T02

Таск: [task.md](task.md)
Итерация: 1
Обновлено: 2026-09-14

## Что реализовано

View `legal_v_tech_claim` дополнена вторым changeSet-ом до 160 колонок (было
104). Добавлены `LEFT JOIN legal_tech_claim_deadlines`, семь `<stage>_due_date`,
семь `<stage>_overdue_level smallint`, `deadlines_outdated boolean`, 36 полей
таблиц со статусом `добавить` и пять вычисляемых колонок (`defect_code_123`,
`claim_transfer_date_effective`, `pre_claim_review_days`, `claim_review_days`,
`lawsuit_rejected_cost`). Число строк не изменилось: `deps_id` в таблице
расчёта уникален, претензия без `du`, `case_one` и без расчёта остаётся видимой.

Степень просрочки считается самой view: дата фактического завершения этапа
(порядок `coalesce` первоисточника), для открытого этапа — `current_date` базы,
сравнивается с сохранёнными порогами. На пороге level1 степень уже 1, на
порогах level2 и level3 сохраняется предыдущая. Смена дня меняет степень без
записи в базу.

`VLegalTechClaim` и блок i18n перегенерированы из фактической структуры view:
160 полей ↔ 160 колонок, 160 message-ключей, осиротевших ключей и полей без
ключа нет. `TechClaimViewIT` расширен с 3 до 9 тестов.

## Изменения и решения

- `app/.../liquibase/changelog/02_view/independent/legal_v_tech_claim.xml` —
  changeSet `2` (`author="legal"`, `runOnChange="true"`), preConditions на
  четыре таблицы раздела, `legal_tech_claim_deadlines` и `nsi_term_revision`.
- `app/.../legal/techclaim/entity/VLegalTechClaim.java` — 56 новых полей,
  семь аксессоров `ClaimTermOverdueLevelEnum` по паттерну остальных enum-полей.
- `app/.../messages_ru.properties` — 56 новых ключей блока `VLegalTechClaim.*`.
- `app/src/test/java/ru/fgk/ws/app/it/TechClaimViewIT.java` — фикстуры расчёта
  и шесть новых тестов.

Существенные решения:

- **Пересоздание view вместо `create or replace`.** Postgres не добавляет
  колонки в существующую view и не меняет их порядок, поэтому changeSet 2
  делает `dropView ifExists` + `createView` с полным определением. Выражения
  колонок changeSet 1 перенесены без единого изменения. `dropView` снимает и
  комментарии, поэтому блок `COMMENT ON` в changeSet 2 тоже полный: 160
  колонок плюс сама view.
- **`is distinct from` вместо `<>` в `deadlines_outdated`.** При отсутствии
  опубликованной ревизии подзапрос даёт `NULL`, и `<>` вернул бы `NULL`
  вместо `true`. Контракт C4 требует boolean, поэтому сравнение сделано
  NULL-устойчивым.
- **`Tarif_Sum1` отдельной колонкой не заводится.** В SQL
  `Tarif_Sum1 = r2.Tarif_Sum`, а `Tarif_Sum` — `case when a+b+c > 0 then
  a+b+c else null end` с `coalesce(Rasch_Dosil_sum, Dosil_sum, 0)`. Это
  ровно существующая `tariff_rebill_total_calc`
  (`nullif(greatest(сумма, 0), 0)`); расхождения нет.
- **Степени в entity — `Integer` + аксессор enum**, как у `claimResult` и
  прочих enum-полей проекта. `last_tr_type` оставлен `Integer` без enum:
  так же он объявлен в исходной `LegalTechClaim` (значения 3/4 не входят в
  `TechClaimRepairTypeEnum`).
- **Даты факта приводить к `date` не потребовалось**: все семь источников
  (`doc_transfer_date`, `claim_transfer_date`, `du.claim_date`,
  `pre_claim_transfer_date`, `pre_claim_send_date`, `du.claim_send_date`,
  `du.to_law_date`, `du.lawsuit_date`) уже имеют тип `date`.
- **Подписи i18n без старых имён процедуры.** Старые колонки (`Srok_PassDoc`,
  `Neispr_kod123` и др.) оставлены в javadoc и комментариях SQL; в
  пользовательские подписи грида они не попадают.

## Предварительные проверки

| Команда или сценарий | Результат |
|---|---|
| `./gradlew :app:compileJava spotlessApply` + `:app:spotlessCheck` | BUILD SUCCESSFUL |
| `./gradlew :app:test --tests "ru.fgk.ws.app.it.TechClaimViewIT"` | 9 passing, 0 failing |
| Пересоздание с нуля: `drop view` + удаление двух строк `databasechangelog`, повторный прогон теста | changeSet 1 и 2 `EXECUTED`, 160 колонок, 161 комментарий (160 колонок + view), `select count(*)` по view выполняется |
| Скрипт сверки полей entity и колонок view (имя, тип, длина, `int2`) | 160 ↔ 160, расхождений нет |
| Скрипт сверки `report-columns.md`: все строки со статусом ≠ `нет` | каждая имеет колонку во view |
| Скрипт сверки i18n: поля entity ↔ ключи блока `VLegalTechClaim.*` | 160 ↔ 160, без полей без ключа и без осиротевших ключей |
| Smoke таска: фикстура в транзакции с `doc_attach_level1_date = current_date - 1` | `doc_attach_overdue_level = 1`, `deadlines_outdated = false`, `rollback` |

Не запускалось, оставлено проверяющему: полный `./gradlew :app:test`,
регрессия сумм (`total_reimbursement`, `underpaid_cost` и др.) на SQL-фикстурах
по образцу прежней итерации, сценарий из «Независимой проверки» с четырьмя
претензиями и тремя положениями порогов, проверки других тасков. Браузер не
нужен и не запускался — экранов по этой view ещё нет
(`render not browser-verified`).

## Для независимой проверки

Окружение: запущенный Docker Compose и локальный override datasource
`app/src/test/resources/application-test-local.properties` (в дереве есть,
JDBC на `localhost:5432`). Вне корпоративной сети сначала
`(cd system && ./change-gradle-to-remote-repo.sh)`.

```bash
docker info && (cd docker && docker compose ps)
docker exec docker-rvk-db-1 psql -U root -d postgres -c "drop view if exists main.legal_v_tech_claim; delete from main.databasechangelog where filename like '%legal_v_tech_claim%';"
./gradlew :app:test
docker exec docker-rvk-db-1 psql -U root -d postgres -c "select id, exectype from main.databasechangelog where filename like '%legal_v_tech_claim%';"
docker exec docker-rvk-db-1 psql -U root -d postgres -c "select count(*) from information_schema.columns where table_schema='main' and table_name='legal_v_tech_claim';"
docker exec docker-rvk-db-1 psql -U root -d postgres -c "select * from main.legal_v_tech_claim limit 10;"
```

Ожидается: два changeSet-а `EXECUTED`, 160 колонок, `:app:test` без падений.

SQL-сценарий C1–C5 выполнять в транзакции с `rollback` по образцу
`../../../dr-warranty-repair-rename-ui/tasks/T02/checks/fixtures_c3_c5.sql`.
Номер актуальной ревизии брать запросом, а не константой:
`select max(revision_number) from main.nsi_term_revision where status =
'PUBLISHED'` — в локальной БД сейчас `1`, но `TechClaimDeadlineIT` публикует
свои ревизии. Устаревшей считать любое другое значение, например `0`.

Пороги в фикстурах задавать относительно `current_date` базы, а не даты JVM.
Соответствие этапов колонкам расчёта: `doc_attach`, `pre_claim_transfer`,
`pre_claim_letter`, `claim_transfer`, `claim_submit`, `law_transfer`,
`lawsuit_submit`.

Общий ресурс — локальная БД `docker-rvk-db-1` и Gradle daemon; изоляции нет,
проверка занимает их одна. По плану проверка T02 идёт после T01 и до T03.

## Ограничения и связанные изменения

- ChangeSet 1 остаётся в файле как история. Если его определение когда-нибудь
  изменят, `runOnChange` пересоздаст view по старому, 104-колоночному
  определению, а changeSet 2 при неизменном checksum повторно не отработает.
  Менять надо changeSet 2; в комментарии к нему это сказано.
- `deadlines_outdated` зависит от глобального `max(revision_number)` по
  `nsi_term_revision` со статусом `PUBLISHED`. Тесты, публикующие ревизии
  (`TechClaimDeadlineIT`), меняют это значение для всей базы; поэтому
  `TechClaimViewIT` читает актуальный номер, а не константу.
- Файлы T03 (роли) не трогались. Политик на `legal_VTechClaim` в проекте пока
  нет ни одной — ссылки на view появятся в T03 и T04.
