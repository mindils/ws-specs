# Результат T01

Таск: [task.md](task.md)
Итерация: 1
Обновлено: 2026-09-15

## Что реализовано

Persistence-основа контейнерного раздела целиком: 9 основных и 13 справочных
entity в `ru.fgk.ws.app.container.entity`, по одному changelog-у на таблицу,
русские подписи entity и всех атрибутов, listener нормализации номера
контейнера и утилита копирования записи. Экранов и ролей нет — это объём T02 и
далее. Все критерии C1–C6 реализованы и покрыты интеграционными тестами;
блокеров нет.

Фактическое поведение:

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

Изменённые области:

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

Существенные решения:

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

Тестовые классы: `ru.fgk.ws.app.container.ContainerCrudIT`,
`ContainerNumberIT`, `ContainerDeletePolicyIT`, `EntityCopySupportIT`,
`ContainerNsiReferenceIT` (плюс фикстуры `ContainerTestData`).

Не запускалось, оставлено проверяющему: полный `./gradlew :app:test`; прогон
миграций на полностью пустой схеме с нуля; браузерные проверки (в этом таске
экранов нет); Entity Inspector для визуальной проверки подписей; проверка ролей
(их ещё нет).

## Для независимой проверки

Окружение — worktree `/home/mindils/data/dev/fgk/worktrees/rvk-ws/cyan-fennel/rvk-ws`
(ветка `f/container`), схема `main_rvk_ws` в общем Docker PostgreSQL
(`localhost:5432`), `ws_store` общая. Настройки worktree —
`app/src/main/resources/application-local.properties` (не в git), JDBC тестов —
`app/src/test/resources/application-test-local.properties` (не в git).

```bash
docker info && (cd docker && docker compose ps)          # rvk-db должен быть Up
./gradlew :app:compileJava
./gradlew :app:test --tests "ru.fgk.ws.app.container.*"
./gradlew :app:test
```

**Перед первым прогоном на новой схеме** нужна разовая правка, см.
[Q03](../../questions/Q03.md): без неё контекст не поднимается вообще.

```sql
alter table main_rvk_ws.pt_repair_packet add column if not exists pack_checked_code integer;
```

SQL-осмотр схемы:

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
`application-local.properties`; параллельных сессий на момент выполнения не
было.

## Ограничения и связанные изменения

- [Q03](../../questions/Q03.md) — на любой чистой схеме контекст не
  поднимается из-за чужого changelog-а `tbl-pt_repair_packet.xml` (колонка
  `pack_checked_code` создаётся только переименованием колонки `status`,
  которой на новой схеме нет). К T01 отношения не имеет, воспроизводится и без
  его изменений. Обойдено правкой схемы `main_rvk_ws` руками; сам changelog не
  трогался, так как лежит вне области таска. Вопрос неблокирующий: T01 готов
  целиком.
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
  `01-tbl/020-dr_diadoc_wag_oper_repair_contract.xml`); они не трогались и не
  откатывались.
