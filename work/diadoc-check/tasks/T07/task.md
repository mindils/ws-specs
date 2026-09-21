# T07 — Убрать жёсткую схему `main` из SQL тестов и тестовых данных

Статус: todo
План: [plan.md](../../plan.md)
Зависимости: нет
Сложность: medium — правка механическая, но 28 файлов, живая БД и полный
прогон набора
Сложность проверки: hard — полный `:app:test` на живой PostgreSQL с
пересозданием схемы
Актуальная проверка: нет

## Коротко

Интеграционные тесты и тестовые данные Liquibase обращаются к таблицам с
жёстким именем схемы `main`, тогда как подключение рабочей копии идёт на
свою схему (в этом worktree — `main_f_diadoc_check`). Подготовка и уборка
уходят в чужую схему, из-за чего `./gradlew :app:test` даёт 90 падений.
После таска полный набор зелёный в любой схеме, а гейт работы «`:app:test`
с `0 failing`» выполняется буквально.

## Результат и контекст

Решение принято в [Q01](../../questions/Q01.md) (ответ пользователя
2026-09-21): чинить привязку внутри этой работы, критерий C4 таска
[T06](../T06/task.md) не смягчать.

Что установлено разбором:

- `app/src/test/java` — 262 вхождения `main.<имя>`; SQL-квалификаторы в 21
  файле. Падают 19 классов, список —
  [app-test-failures-worktree.txt](../T06/app-test-failures-worktree.txt).
- Тестовые данные Liquibase тоже жёстко на `main`: 7 файлов
  `app/src/test/resources/ru/fgk/ws/app/liquibase/sql/*.sql` (42
  вхождения), подключаются `changelog-test.xml` → `test-changelog/*.xml`
  через `<sqlFile>`. `defaultSchemaName` нигде не задан, значит Liquibase
  пишет в схему соединения. Без этой части `0 failing` недостижим — именно
  поэтому падает `TechClaimDemoDataIT`, где своего `main.` нет.
- Схема соединения приходит из JDBC (`currentSchema=…` в
  `application-test.properties` и локальном
  `application-test-local.properties`), то есть `search_path` уже указывает
  на нужную схему.
- Продуктовый код `app/src/main/java` SQL со схемой `main` не содержит,
  поведение приложения таск не меняет.

## Область и изоляция

Меняются только тесты и тестовые ресурсы.

Java (21 файл):

- `app/src/test/java/ru/fgk/ws/app/it/`: `ContractRepairCountIT`,
  `DiadocPacketCorrectionIT`, `DrOperRepairTr2ParserServiceIT`,
  `DrPlanRepairParserServiceIT`, `FullPackCheckedTextIT`,
  `Mh1mPacketMergeIT`, `MhDetailOriginServiceIT`, `MhReferenceCostLookupIT`,
  `NewInspectionCountProcedureIT`, `NsiClaimTermEditRoleIT`,
  `PtRepairPacketCorrectionIT`, `ReceiptCostReplayIT`, `TechClaimDeadlineIT`,
  `TechClaimSecurityIT`, `TechClaimViewIT`, `WheelsetArchiveViewIT`,
  `WorkCalendarReferenceDataIT`;
- `app/src/test/java/ru/fgk/ws/app/diadoc/service/SyncPacketServiceTest.java`;
- `app/src/test/java/ru/fgk/ws/app/dr/service/DrOperRepairParserServiceTest.java`;
- `app/src/test/java/ru/fgk/ws/app/legal/techclaim/view/TechClaimDetailViewUiTest.java`;
- `app/src/test/java/ru/fgk/ws/app/nsi/view/claimtermnorm/NsiClaimTermNormViewsUiTest.java`;
- плюс абзац правила в javadoc `app/src/test/java/ru/fgk/ws/app/it/BaseIT.java`.

Ресурсы (7 файлов) —
`app/src/test/resources/ru/fgk/ws/app/liquibase/sql/`:
`legal_tech_claim_demo.sql`, `data_test_da_claim_depo.sql`,
`data_test_da_claim_depo_station.sql`, `cnt_demo.sql`,
`pt_repair_packet_mh.sql`, `data_nsi_diadoc_document_type.sql`,
`data_dr_diadoc_wag_oper_repair_contract.sql`.

**Не трогать:** продуктовый код; `LocalTestDataSource` (ключи свойств
`main.datasource.*`); `CaseOneUrlsTest` (`http://case.main.vgk`);
`DiadocSqlValidatorTest` (проверяет продуктовое правило «разрешена только
схема main» в `ai/tool/DiadocSqlValidator`); `DiadocPacketDocumentsReadTest`
(имя файла `main.xml`); `PacketReplayFixtures` и `RemDetPacketReplayIT` —
там схема уже берётся через `current_schema()` и нужна как значение;
changelog-XML в `test-changelog/` (changeSet-ы `runOnChange="true"`,
переедут сами).

Общие ресурсы: схема `main_f_diadoc_check` в `docker-rvk-db-1`
(`localhost:5432`, `root`/`root`) и Gradle daemon. Таск выполняется один,
перед T06; параллельных тасков нет.

## Реализация

Основной приём — снять квалификатор: `from main.pt_repair_packet` →
`from pt_repair_packet`. Имя схемы уже в `search_path` соединения, диф
минимальный, новых полей в классах не появляется, продуктовый код
обращается к таблицам так же. То же в тестовых `*.sql`:
`insert into main.X` → `insert into X`.

`select current_schema()` применять точечно — только там, где имя схемы
нужно как значение. Известный случай один:
`NewInspectionCountProcedureIT` (`set search_path = main, public` и
`call main.p_wag_oper_repair_contract_modify()`) — подставить полученное
значение в `set search_path`, вызов процедуры оставить неквалифицированным.

Упоминания `main.<таблица>` в javadoc и комментариях тестов (6 мест,
например `WheelsetArchiveViewIT:19`) привести в соответствие.

В javadoc `BaseIT` добавить абзац с правилом: схема берётся из
`currentSchema` соединения, таблицы в SQL тестов именем `main` не
квалифицируются — в рабочей копии схема другая. Это предотвращает
повторение дефекта, а не пересказывает диф.

## Критерии приёмки

- C1: `grep -rnE '"[^"]*\bmain\.[a-z_]+' app/src/test/java
  app/src/test/resources` даёт только согласованные исключения выше.
- C2: `./gradlew :app:test` в схеме worktree — `0 failing` (сейчас 90).
- C3: `./gradlew spotlessCheckAll` — BUILD SUCCESSFUL.
- C4: правило про схему записано в javadoc `BaseIT`.

## Самопроверка исполнителя

`./gradlew :app:compileJava`, `spotlessApply`, затем классы наибольшего
риска: `./gradlew :app:test --tests "ru.fgk.ws.app.it.TechClaim*" --tests
"ru.fgk.ws.app.it.DrOperRepairTr2ParserServiceIT" --tests
"ru.fgk.ws.app.it.NewInspectionCountProcedureIT"`. Полный набор запускать
не обязательно, если он уже занят — записать это в `result.md`.

## Независимая проверка

Пересоздать схему (`DROP SCHEMA main_f_diadoc_check CASCADE; CREATE SCHEMA
main_f_diadoc_check`), чтобы тестовые данные Liquibase легли заново, и
прогнать полный `./gradlew :app:test` — ожидание `0 failing`; затем
`spotlessCheckAll` и механическая проверка C1. Браузер не нужен:
продуктовое поведение не меняется. Негатив: убедиться, что список
пройденных тестов не сократился — число выполненных тестов не меньше
прежних 1548, то есть падавшие классы теперь проходят, а не пропускаются.

## Прогресс и продолжение

- [ ] Java-тесты: снять квалификатор, поправить комментарии
- [ ] Тестовые `*.sql` Liquibase
- [ ] Правило в javadoc `BaseIT`
- [ ] Самопроверка и полный прогон
- [ ] Передать результат на независимую проверку.

Ближайший шаг: снять `main.` в `app/src/test/java`, начиная с
`DrOperRepairTr2ParserServiceIT` (45 вхождений).
Препятствия: нет
