# Результат T01

Таск: [task.md](task.md)
Итерация: 2
Обновлено: 2026-09-15

## Что реализовано

Итерация 2 (эта передача) — только правка чужого changelog-а
`01-tbl/tbl-pt_repair_packet.xml` по ответу [Q03](../../questions/Q03.md).
Колонка `PACK_CHECKED_CODE` типа `INT` с remarks из changeSet `16` добавлена в
основной `createTable` (changeSet `1`), а в конец файла добавлен отдельный
changeSet `23` (author `dr`) с `addColumn` и `preConditions onFail="MARK_RAN"`
→ `<not><columnExists .../></not>`. ChangeSet `17` оставлен без изменений. Код
entity, listener-а, `EntityCopySupport` и messages не менялся; ручная правка
схемы больше не нужна и снята.

Фактическое поведение итерации 2:

- На **полностью пустой схеме** контекст поднимается: `jmix_Liquibase` проходит,
  тестовый changelog `010-pt_repair_packet-data.xml::test-001` вставляет 6
  строк, колонка `pack_checked_code integer` есть с нужным комментарием,
  changeSet `23` получает MARK_RAN (колонка уже пришла из `createTable`).
- На **существующей схеме без колонки** changeSet `1` перезапускается по
  `runOnChange` и получает exectype `RERAN` (его preCondition `not tableExists`
  не выполняется, DDL не идёт, обновляется только checksum), а changeSet `23`
  получает EXECUTED и создаёт колонку с тем же комментарием.
- Повторный прогон на той же схеме идемпотентен: миграции не падают, тесты
  зелёные.

Итерация 1 (подтверждена отчётом [checks/001.md](checks/001.md)) — persistence-
основа контейнерного раздела целиком: 9 основных и 13 справочных entity в
`ru.fgk.ws.app.container.entity`, по одному changelog-у на таблицу, русские
подписи entity и всех атрибутов, listener нормализации номера контейнера и
утилита копирования записи. Экранов и ролей в таске нет. Фактическое поведение:

- 22 таблицы `cnt_*` создаются миграциями, 35 индексов (в том числе уникальные
  `cnt_container(cont_num)` и `cnt_act_container(act_id, container_id)`),
  внешних ключей нет ни одного.
- Удаление мягкое: после `remove` запись не возвращается загрузкой, а строка
  остаётся в таблице с `deleted_date`.
- Номер контейнера при сохранении обрезается и переводится в верхний регистр
  на любом пути записи; пустой после обрезки отклоняется с русским сообщением;
  повтор номера отклоняется, в том числе если прежний контейнер удалён.
- Удаление записи, на которую ссылаются, отклоняется
  (`DeletePolicyException`) и снова разрешается после мягкого удаления
  ссылающихся записей.
- `EntityCopySupport.copy(...)` возвращает новую entity без id, версии, аудита,
  soft delete и `FileRef`, с бизнес-полями и ссылками; у контейнера очищает
  номер.
- Ссылки на `VStation` (`Integer` id) и `VOrgPassport` (`Long` id) сохраняются
  и читаются вместе с подписью по fetch plan `_instance_name`.

## Изменения и решения

Изменено в итерации 2 — один файл:

- `app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/01-tbl/tbl-pt_repair_packet.xml`
  — строка колонки в `createTable` changeSet `1` и новый changeSet `23`.

Решения итерации 2:

- **Следующий свободный id — `23`.** В файле есть id 1–9, 11–17, 19–22 (id `10`
  и `18` пропущены исторически и не переиспользуются).
- **Author нового changeSet — `dr`**, как у changeSet `16` и `17`, которые
  завели и переименовали `pack_checked_code`; правило проекта допускает
  feature-префикс, и `dr` сохраняет владение историей этой колонки.
- **Тип `INT`** — по `PtRepairPacket.packCheckedCode` (`Integer`,
  `@Column(name = "pack_checked_code")`, `app/.../pt/entity/PtRepairPacket.java:278`).
- **ChangeSet `17` не удалён и не ослаблен**: на старых базах, где колонка
  `status` есть, он по-прежнему выполняет переименование; на схемах, где
  колонка уже пришла из `createTable`, его preCondition не выполняется и он
  получает MARK_RAN.
- **Remarks продублированы** и в `createTable`, и в `addColumn`, чтобы
  комментарий появлялся обоими путями: changeSet `16` со своим
  `setColumnRemarks` по `status` на чистой схеме не выполняется.

Изменённые области итерации 1:

- `app/src/main/java/ru/fgk/ws/app/container/entity/` — 22 entity.
- `app/src/main/java/ru/fgk/ws/app/container/listener/ContainerSavingListener.java`.
- `app/src/main/java/ru/fgk/ws/app/container/service/EntityCopySupport.java`.
- `app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/01-tbl/tbl-cnt_*.xml`
  — 22 файла, author `cnt`, preConditions на каждом changeSet,
  `objectQuotingStrategy="QUOTE_ONLY_RESERVED_WORDS"`, `remarks` на таблицу и
  каждую колонку.
- `app/src/main/resources/ru/fgk/ws/app/messages_ru.properties` — 319 новых
  ключей (добавление в конец файла).
- `app/src/test/java/ru/fgk/ws/app/container/` — 5 тестовых классов и фикстуры.
- `specs/work/conteiner/contracts.md` — зафиксирован результат проверки DENY с
  soft delete и раздел «Фактические имена (T01)».

Существенные решения итерации 1:

- **DENY учитывает soft delete, сервисная проверка не нужна.** Проверено по
  исходникам Jmix 3.0.1: `DeletePolicyProcessor#referenceExists` считает
  ссылающиеся записи обычным JPQL, а `SoftDeleteAdditionalCriteriaProvider`
  добавляет soft-deletable дескрипторам критерий `this.deletedDate is null`.
  Подробности записаны в contracts.md, поведение закреплено тестом.
- **Уникальность номера — обычный уникальный индекс по `cont_num`**, без
  `deleted_date` в составе: по решению пользователя номер удалённого
  контейнера не переиспользуется.
- **Непустота номера проверяется в listener-е**, а не только ограничением БД:
  строка из одних пробелов после обрезки становится пустой, и БД её приняла бы.
  Сообщение — `CustomValidationException` с ключом
  `ru.fgk.ws.app.container.listener/contNumRequired`.
- **`EntityCopySupport` копирует только загруженные атрибуты.** Незагруженную
  ссылку скопировать нечем, поэтому вызывающий код должен загружать источник с
  fetch plan-ом, включающим нужные ссылки (в тестах так и сделано).
- **`@InstanceName` методом** там, где подходящего поля нет:
  `ContainerSurvey`, `ContainerRepair`, `ContainerActLink`,
  `ContainerWarranty`. Формат без слов, чтобы не было текста мимо i18n.
- **В `cnt_act_container` отдельный индекс по `act_id` не создавался** — он
  совпадает с ведущей колонкой уникального индекса.
- Системные атрибуты (`id`, `version`, аудит, soft delete) получили русские
  подписи явно: `MessageTools` ищет их по ключу `<Entity>.<property>` в группе
  пакета entity и при отсутствии показывает сам ключ.

## Предварительные проверки

Итерация 2:

| Команда или сценарий | Результат |
|---|---|
| `./gradlew :app:compileJava` | успешно |
| XML нового changelog-а разбирается парсером | успешно |
| Пустая схема `main_t01i2`, `./gradlew :app:test --tests "ru.fgk.ws.app.container.ContainerNumberIT"` | 3 зелёных, контекст поднялся, `jmix_Liquibase` прошёл |
| Тот же прогон повторно (`--rerun-tasks`) на той же схеме | 3 зелёных — миграции идемпотентны |
| SQL-осмотр `main_t01i2` | `pack_checked_code integer` + remarks, changeSet `23` MARK_RAN, 6 строк тестовых данных, 22 таблицы `cnt_*` |
| Схема `main_rvk_ws`: снята ручная колонка, затем `./gradlew :app:test --tests "ru.fgk.ws.app.container.*"` | 64 зелёных; changeSet `1` RERAN, changeSet `23` EXECUTED, колонка восстановлена миграцией с remarks |
| `PtRepairPacket.packCheckedCode` сверен с типом колонки | `Integer` ↔ `INT`, совпадает |

Прогон `--tests "ru.fgk.ws.app.container.*"` сейчас захватывает 15 классов: к
пяти классам T01 добавились контейнерные тесты последующих тасков, живущие в
том же worktree. Все 64 теста зелёные.

Тестовые классы T01: `ru.fgk.ws.app.container.ContainerCrudIT`,
`ContainerNumberIT`, `ContainerDeletePolicyIT`, `EntityCopySupportIT`,
`ContainerNsiReferenceIT` (плюс фикстуры `ContainerTestData`).

Итерация 1 (историческая, код не менялся):

| Команда или сценарий | Результат |
|---|---|
| `./gradlew :app:compileJava` | успешно |
| `./gradlew :app:compileTestJava` | успешно |
| `./gradlew spotlessApply` | новые файлы отформатированы, чужие не затронуты |
| `./gradlew :app:test --tests "ru.fgk.ws.app.container.*"` | 13 тестов, все зелёные |
| Тот же прогон повторно (`--rerun-tasks`) | 13 зелёных — уборка не оставляет строк |
| Smoke: миграции на схеме `main_rvk_ws` при старте тестов | 22 таблицы `cnt_*`, 35 индексов, 0 внешних ключей (проверено SQL) |
| Механические проверки `jmix-ide-static-analysis` по новым файлам | пусто: нет файлов без `package`, нет 0-байтовых, XML-прологи чистые, FK в changelog-ах нет |
| Сверка `@Index` в entity и `<createIndex>` в changelog-ах скриптом | 35 = 35, расхождений нет |
| Сверка колонок entity и `createTable` скриптом | расхождений нет |
| Полнота message-ключей для всех атрибутов 22 entity скриптом | пропусков и пустых значений нет |

Не запускалось, оставлено проверяющему: полный `./gradlew :app:test`; прогон
миграций на схеме `main` (её не трогали намеренно); браузерные проверки (в этом
таске экранов нет); Entity Inspector для визуальной проверки подписей; проверка
ролей (их ещё нет).

## Для независимой проверки

Окружение — worktree `/home/mindils/data/dev/fgk/worktrees/rvk-ws/cyan-fennel/rvk-ws`
(ветка `f/container`), схема `main_rvk_ws` в общем Docker PostgreSQL
(`localhost:5432`), `ws_store` общая. Настройки worktree —
`app/src/main/resources/application-local.properties` (не в git), JDBC тестов —
`app/src/test/resources/application-test-local.properties` (не в git).

Ручная правка схемы из итерации 1 больше не нужна и снята: колонка
`pack_checked_code` в `main_rvk_ws` сейчас создана миграцией (changeSet `23`),
значения тестовых строк восстановлены.

```bash
docker info && (cd docker && docker compose ps)          # rvk-db должен быть Up
./gradlew :app:compileJava
./gradlew :app:test --tests "ru.fgk.ws.app.container.*"
./gradlew :app:test
```

Проверка миграционной части (C1) на пустой схеме. Схему создать, прогнать любой
интеграционный тест, затем вернуть JDBC тестов на свою схему:

```sql
create schema main_<slug>;
```

```bash
# временно в app/src/test/resources/application-test-local.properties:
# main.datasource.url = jdbc:postgresql://localhost:5432/postgres?currentSchema=main_<slug>
./gradlew :app:test --tests "ru.fgk.ws.app.container.ContainerNumberIT"
./gradlew :app:test --tests "ru.fgk.ws.app.container.ContainerNumberIT" --rerun-tasks
```

Ожидается: контекст поднимается, тесты зелёные оба раза; ниже — SQL-осмотр.

```sql
select column_name, data_type from information_schema.columns
 where table_schema = 'main_<slug>' and table_name = 'pt_repair_packet'
   and column_name in ('status', 'pack_checked_code');
-- ожидается ровно одна строка: pack_checked_code | integer

select id, author, exectype from main_<slug>.databasechangelog
 where filename = 'ru/fgk/ws/app/liquibase/changelog/01-tbl/tbl-pt_repair_packet.xml'
 order by orderexecuted;
-- ожидается: 1 EXECUTED, 3 MARK_RAN, 16 MARK_RAN, 17 MARK_RAN, 23 MARK_RAN

select count(*), count(pack_checked_code) from main_<slug>.pt_repair_packet;
-- ожидается 6 | 6 — тестовый changelog 010-pt_repair_packet-data.xml отработал
```

Поведение на существующей схеме без колонки (что и произошло на `main_rvk_ws`
после снятия ручной правки): changeSet `1` получает exectype `RERAN`, а не
MARK_RAN — он объявлен `runOnChange="true"`, поэтому при изменении checksum
перезапускается; DDL при этом не выполняется, потому что его preCondition
`not tableExists` не проходит. ChangeSet `23` получает EXECUTED и создаёт
колонку. На схеме `main` ожидается то же для changeSet `1` и MARK_RAN для
changeSet `23`, так как колонку там уже завёл changeSet `17`. Схему `main` в
этой сессии не трогали.

SQL-осмотр контейнерной части схемы:

```sql
select table_name from information_schema.tables
 where table_schema = 'main_rvk_ws' and table_name like 'cnt%' order by 1;      -- ожидается 22
select indexname, indexdef from pg_indexes
 where schemaname = 'main_rvk_ws' and tablename like 'cnt%' order by 1;          -- ожидается 35 + 22 pk
select conname from pg_constraint
 where connamespace = 'main_rvk_ws'::regnamespace and contype = 'f'
   and conrelid::regclass::text like '%cnt%';                                    -- ожидается 0 строк
```

Тестовые данные тесты создают и убирают сами: контейнеры получают номер с
префиксом `TSTU`, строки удаляются физически в `@AfterEach` (мягкого удаления
для уборки недостаточно — номер остался бы занят). Тест
`ContainerNsiReferenceIT` сеет одну строку в
`ws_store.ora_assb_org_passport_current` с `org_id = 999000001`, потому что
локальная копия справочника организаций пуста, и удаляет её там же. `ws_store`
общая на все worktree — прогон занимает её на время теста.

Изоляция общих ресурсов: своя схема `main_rvk_ws` и порт 8082 из
`application-local.properties`. Временная схема `main_t01i2`, на которой
проверялась пустая база, удалена после прогона.

## Ограничения и связанные изменения

- [Q03](../../questions/Q03.md) закрыт правкой самого changelog-а; обходной
  `alter table ... add column` из итерации 1 снят и больше нигде не нужен.
  Отчёт [checks/001.md](checks/001.md) в части C1 стал историческим: схема
  теперь разворачивается миграциями без ручных шагов.
- Правка затрагивает чужую область (`pt`/`dr`). Данные она не меняет: на
  существующих базах колонка уже есть, на чистых приходит из `createTable`.
  Доказательства других тасков это не обесценивает — колонки на `main` и так
  не было видно из контейнерного кода.
- IDE-инспекция (`get_file_problems`) и Context7 MCP в сессии недоступны, как и
  MCP `mcp__rvk-ws__query`. Символы Jmix проверялись по исходникам Jmix 3.0.1
  из кэша Gradle (`jmix-core`, `jmix-data`, `jmix-eclipselink`), схема — прямым
  `psql` в контейнере. Gate 1 для новых файлов покрыт `compileJava` плюс
  механическими проверками; переинспектировать файлы стоит в сессии, где
  инспекция доступна.
- Виртуальные поля реестра (тенты, дуги, тросы, вентиляция, наименование типа,
  длина в футах) в модель не добавлялись: по contracts.md они показываются
  read-only по property path из ссылок и в БД не хранятся — это объём T03.
- Рабочая копия содержит чужие изменения (`application.properties`,
  `01-tbl/020-dr_diadoc_wag_oper_repair_contract.xml`, `menu.xml`,
  `messages_ru.properties` и файлы последующих тасков контейнерного раздела);
  они не трогались и не откатывались.
