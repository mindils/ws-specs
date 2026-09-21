# Результат T07

Таск: [task.md](task.md)
Итерация: 1
Обновлено: 2026-09-21

## Что реализовано

Из SQL интеграционных тестов и тестовых данных Liquibase убрано жёсткое имя
схемы `main`: таблицы приложения именуются без квалификатора, схема берётся
из `currentSchema` соединения. Подготовка и уборка тестов теперь работают в
той же схеме, в которую пишет приложение, поэтому полный набор проходит в
любой рабочей копии.

Полный `./gradlew :app:test` на пересозданной схеме `main_f_diadoc_check` —
`1536 passing, 12 pending, 0 failing` (1548 выполненных, как и раньше).
Было 90 падений.

## Изменения и решения

- 25 файлов `app/src/test/java`: снят квалификатор `main.` в SQL-строках,
  приведены в соответствие упоминания таблиц в javadoc и комментариях.
  Помимо перечисленных в таске нашлись и поправлены ещё три файла с теми же
  вхождениями: `it/TechClaimDemoDataIT`, `it/ContractSupplyOutLookupIT`,
  `da/notice/service/RepairNoticeSendingServiceIT` — без них критерий C1 не
  выполняется.
- `it/NewInspectionCountProcedureIT`: `set search_path` строится из
  `select current_schema()` (добавлен приватный метод `currentSchema`),
  `public` в пути оставлен — процедура пользуется его объектами. Вызов
  процедуры стал неквалифицированным.
- 7 файлов `app/src/test/resources/ru/fgk/ws/app/liquibase/sql/*.sql`:
  `insert/update/delete ... main.X` → без схемы. ChangeSet-ы объявлены
  `runOnChange="true"`, поэтому новая редакция применяется сама.
- `it/BaseIT`: в javadoc добавлен абзац с правилом — схема приходит из
  `currentSchema`, таблицы приложения именем `main` не квалифицируются,
  `ws_store` квалифицируется как обычно, а если имя схемы нужно как
  значение, оно берётся `select current_schema()`.

Не менялись согласованные исключения: `DiadocSqlValidatorTest` (проверяет
продуктовое правило «только схема main»), `CaseOneUrlsTest` (`case.main.vgk`),
`LocalTestDataSource` (ключи `main.datasource.*`),
`DiadocPacketDocumentsReadTest` (`main.xml`), `diadoc/replay*/tables.txt`
(`main` там — плейсхолдер, `PacketReplayFixtures` подставляет вместо него
`current_schema()`), `application-test.properties` (`currentSchema=main` —
настройка подключения удалённого профиля). Продуктовый код не затронут.

## Предварительные проверки

| Команда или сценарий | Результат |
|---|---|
| `./gradlew :app:compileTestJava` | BUILD SUCCESSFUL |
| `./gradlew spotlessApply` + `./gradlew spotlessCheckAll` | BUILD SUCCESSFUL (C3) |
| `./gradlew :app:test --tests "ru.fgk.ws.app.it.TechClaim*" --tests "ru.fgk.ws.app.it.DrOperRepairTr2ParserServiceIT" --tests "ru.fgk.ws.app.it.NewInspectionCountProcedureIT"` | 56 passing, 0 failing |
| `grep -rnE '"[^"]*\bmain\.[a-z_]+' app/src/test/java app/src/test/resources` | только исключения выше (C1) |
| `DROP SCHEMA main_f_diadoc_check CASCADE; CREATE SCHEMA main_f_diadoc_check;` + `./gradlew :app:test --rerun-tasks` | 1536 passing, 12 pending, 0 failing (C2) |

Сверх минимума самопроверки полный набор всё-таки прогнан: без него не видно,
что правка закрывает все 90 падений.

Не запускалось, оставлено проверяющему: браузерные сценарии (продуктовое
поведение не менялось), тесты `core` и `sso-plagin`.

## Для независимой проверки

Нужны поднятый `docker compose` из `docker/` (PostgreSQL `docker-rvk-db-1`,
`localhost:5432`, пользователь `root`) и
`app/src/test/resources/application-test-local.properties` с
`currentSchema=main_f_diadoc_check`.

```bash
docker exec docker-rvk-db-1 psql -U root -d postgres \
  -c 'DROP SCHEMA main_f_diadoc_check CASCADE;' \
  -c 'CREATE SCHEMA main_f_diadoc_check;'
./gradlew :app:test --rerun-tasks
./gradlew spotlessCheckAll
grep -rnE '"[^"]*\bmain\.[a-z_]+' app/src/test/java app/src/test/resources
```

Ожидание: `0 failing` при 1548 выполненных тестах (1536 passing + 12
pending) — число не меньше прежнего, значит падавшие классы проходят, а не
пропускаются.

Изоляция: схема `main_f_diadoc_check` и Gradle daemon занимались только этой
сессией; `ws_store` только читается. Первый прогон после пересоздания схемы
дольше обычного — Liquibase разворачивает схему заново.

## Ограничения и связанные изменения

- До пересоздания схемы в ней лежал мусор от прежних прогонов: уборка
  уходила в схему `main`, а записи оставались в схеме рабочей копии. На
  таком остатке `TechClaimDetailViewUiTest` падал по
  `idx_legal_tech_claim_wag_defect` даже с исправленными тестами. Разовая
  чистка — пересоздание схемы; далее тесты убирают за собой сами.
- Остаток от прежних прогонов мог осесть и в общей схеме `main` (туда уходили
  `insert` тестовых данных Liquibase и `delete` уборки). Тесты туда больше не
  пишут; чистить эту схему в рамках таска не стали — она не наша.
- Снятие блокировки T06: полный `:app:test` c `0 failing` — его критерий C4.
