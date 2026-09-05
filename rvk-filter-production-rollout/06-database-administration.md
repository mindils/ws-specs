# F06. Хранение и обслуживание пресетов

[К плану](README.md) · Репозиторий: `rvk-filter`; подключение миграции — `rvk-ws` · Статус: **не начато**.

Цель: пресет можно добавить, исправить, удалить и восстановить через административный экран или явную SQL-операцию. Сохраняем читаемый TEXT JSON; отдельной таблицы условий для этого не требуется.

## F06.1. Текущая и целевая схема

Таблица `rvk_filter_config`, entity `rvkflt_RvkFilterConfig`. В локальной БД приложения таблицы пока нет. Структура ниже сверена с исходным changelog; столбец version и дополнительные ограничения — **целевые изменения**.

| Колонка | Тип / правило |
|---|---|
| id | UUID PK, существующую стратегию JmixGeneratedValue сохранить; не переводить на Long |
| component_id | VARCHAR(255) NOT NULL, стабильный ключ страницы/компонента |
| name | VARCHAR(255) NOT NULL, trim и запрет пустого имени |
| username | VARCHAR(255), NULL означает global, непустое значение — owner login; FK на app User не добавлять |
| default_for_me / default_for_all | BOOLEAN; целевое NOT NULL DEFAULT false после заполнения старых NULL |
| sort_order | INTEGER; целевое NOT NULL DEFAULT 0 |
| payload | TEXT NOT NULL, JSON object с типизированными значениями; не opaque binary |
| schema_version | INTEGER NOT NULL; версия формата, совместимая с payload |
| version | **Добавить** INTEGER NOT NULL DEFAULT 0 и JPA optimistic locking |
| created_by / last_modified_by | VARCHAR(255), nullable audit |
| created_date / last_modified_date | Тип `${offsetDateTime.type}`, nullable audit |

Существующие индексы: component_id, уникальное имя личного `(component_id, username, name)` WHERE username IS NOT NULL и общего `(component_id, name)` WHERE username IS NULL. Их сохранить.

- [ ] Добавить уникальные partial indexes для единственного личного и общего default. Перед созданием выполнить диагностику дубликатов; конфликтующие записи не удалять и не выбирать победителя автоматически.
- [ ] Добавить CHECK согласованности scope/default: username=NULL запрещает default_for_me=true, username!=NULL запрещает default_for_all=true. Пустой username, пустое name/component_id и неположительная schema_version запрещены.
- [ ] JSON object проверять на сервисном уровне обязательно; DB CHECK валидности JSON/object добавлять после проверки legacy payload. Повреждённые записи сначала доступны admin для исправления, а не приводят к массовому удалению.
- [ ] Нормализацию имён проводить только после отчёта о потенциальных коллизиях trim; коллизии останавливают миграцию с объяснением.
- [ ] Default-изменение сериализовать в транзакции по component/scope/owner; сбросить прежний default до назначения нового. Уникальный индекс остаётся последней защитой. Concurrent conflict показывать как конфликт, не тихий last-write-wins.

Для PostgreSQL допустим scoped transaction advisory lock; ключ блокировки строится сервером из component/scope/owner. Не применять JVM synchronized как единственную защиту — экземпляров приложения может быть несколько. Optimistic version отдельно защищает редактирование одной записи.

## F06.2. Миграции

- [ ] Аддон владеет своим changelog; приложение добавляет include `/ru/fgk/component/rvkfilter/liquibase/changelog.xml` перед собственными изменениями, зависящими от таблицы.
- [ ] Новые changeset имеют preConditions и QUOTE_ONLY_RESERVED_WORDS. DDL не обновлять через runOnChange старого createTable. Новые author использовать `app`, исторические id/author/file identities сохранить.
- [ ] Обновить описание createTable для чистой БД **и** добавить addColumn/constraints/index changesets для существующей. Для уже применённого createTable учесть checksum и текущий runOnChange явно; проверить upgrade с настоящей legacy DATABASECHANGELOG, не очищая checksums вслепую.
- [ ] Добавление version/NOT NULL выполняется с заполнением старых значений. Не менять UUID и не вводить FK к пользователю/странице; удаление пользователя не должно автоматически уничтожать пресеты.
- [ ] Протестировать пустую БД, существующую таблицу с данными, повторный запуск и upgrade с некорректными записями. onFail=MARK_RAN подходит только для уже существующего объекта, а не для ошибки содержимого данных.
- [ ] Новые версии payload мигрировать при чтении по F05; массовая перезапись пользовательских конфигураций — отдельная явная операция с резервной копией.

## F06.3. Универсальный административный экран

- [ ] Поставить list/detail view в самом аддоне, с точечными view/menu policies роли maintainer. В app — только подключение меню/назначение роли.
- [ ] Список: component key, имя, scope, owner, defaults, schema/version, audit и признак совместимости; фильтры по component/owner/scope/name, сортировка и пагинация.
- [ ] Действия: создать, изменить имя/содержимое, копировать, удалить с подтверждением, назначить/снять default, перенести owner/component отдельной подтверждаемой операцией, экспортировать/импортировать одну запись.
- [ ] Если определение компонента зарегистрировано приложением, использовать его обычный редактор/validator. Для неизвестного или повреждённого пресета предоставить raw JSON с форматированием, диагностику версии и возможность исправления/удаления.
- [ ] Конфигурационный registry регистрируется при старте/конфигурации приложения, а не зависит от того, открыл ли кто-то нужный view. Не открывать произвольные бизнес-views ради получения metadata.
- [ ] Raw-редактор не делает несовместимый payload пригодным автоматически: структурно корректную запись неизвестного component можно сохранить с предупреждением, но обычная панель обязана валидировать её перед Apply.
- [ ] Права управления всеми пресетами проверять на сервере перед выдачей чужого payload; не включать его в ответы обычной панели.

## F06.4. SQL runbook

Следующие SELECT применимы после создания таблицы; сейчас можно выполнить только запрос существования. Примеры изменений относятся к **целевой схеме F06 с version**. Это инструкции для отдельного обслуживания, они не выполнялись при написании спецификаций. Подключение/пароли в файлах не хранить.

```sql
SELECT table_schema, table_name
FROM information_schema.tables
WHERE table_name IN ('rvk_filter_config', 'flowui_filter_configuration');

SELECT id, component_id, name, username, default_for_me, default_for_all,
       schema_version, version, last_modified_date
FROM main.rvk_filter_config
ORDER BY component_id, username NULLS FIRST, name;

SELECT component_id, username, count(*)
FROM main.rvk_filter_config
WHERE (username IS NULL AND default_for_all IS TRUE)
   OR (username IS NOT NULL AND default_for_me IS TRUE)
GROUP BY component_id, username HAVING count(*) > 1;
```

В psql задать `preset_id`, `expected_version`, `new_name`, `operator_name` через `\set`. Перед изменением выгрузить выбранную запись в файл, включая payload и audit; не ограничиваться только скриншотом имени. Команда возвращает JSON даже для повреждённого payload, потому что payload остаётся строкой:

```sql
SELECT row_to_json(c) FROM main.rvk_filter_config c WHERE id = :'preset_id'::uuid;
```

Переименование с проверкой конкурентного изменения (проверить, что RETURNING вернул **ровно одну** строку; иначе ROLLBACK):

```sql
BEGIN;
UPDATE main.rvk_filter_config
SET name = btrim(:'new_name'), version = version + 1,
    last_modified_by = :'operator_name', last_modified_date = CURRENT_TIMESTAMP
WHERE id = :'preset_id'::uuid AND version = :'expected_version'::integer
RETURNING id, name, version;
-- После проверки результата оператор выполняет COMMIT; иначе ROLLBACK.
```

Удаление не требует удаления дочерних таблиц: нормализованных condition rows/FK сейчас нет. Сначала резервная копия выше, затем:

```sql
BEGIN;
DELETE FROM main.rvk_filter_config
WHERE id = :'preset_id'::uuid AND version = :'expected_version'::integer
RETURNING id, component_id, name;
-- Проверить одну строку; COMMIT или ROLLBACK.
```

Добавление персонального пресета без условий в совместимом v1-формате (после F03.4 reader должен уметь мигрировать его в памяти в v2). Значения `component_key`, `owner_name`, `new_name`, `operator_name` задать явно; не угадывать component по названию view:

```sql
BEGIN;
INSERT INTO main.rvk_filter_config
    (id, component_id, name, username, default_for_me, default_for_all,
     sort_order, payload, schema_version, version, created_by, created_date)
VALUES
    (gen_random_uuid(), :'component_key', btrim(:'new_name'), :'owner_name', false, false,
     0, '{"version":1,"query":"","activeFieldIds":[],"values":{},"selectedSavedFilterId":null}',
     1, 0, :'operator_name', CURRENT_TIMESTAMP)
RETURNING id, component_id, name;
-- Проверить одну строку; COMMIT или ROLLBACK.
```

Для добавления общего пресета username задаётся SQL NULL. Не назначать default в том же непроверенном INSERT; использовать административный сервис с транзакцией и блокировкой scope. Любая SQL-операция выполняется от привилегированного DB-подключения и обходит Jmix-проверки, поэтому после неё повторно открыть панель и проверить права/совместимость обычным пользователем.

Замена payload: сначала валидировать через admin import/validator F05 и экспортировать исходную запись; затем параметризованный UPDATE payload/schema_version/version по id+expected_version. Прямую конкатенацию JSON в SQL не использовать. Восстановление из сохранённого row JSON выполняется INSERT с исходным UUID и всеми полями после проверки отсутствия текущего id; при конфликте восстановить как копию с новым UUID. Готовую выгрузку можно подать параметром `backup_json`:

```sql
BEGIN;
INSERT INTO main.rvk_filter_config
SELECT restored.*
FROM json_populate_record(NULL::main.rvk_filter_config, :'backup_json'::json) restored
WHERE NOT EXISTS (SELECT 1 FROM main.rvk_filter_config c WHERE c.id = restored.id)
RETURNING id, component_id, name;
-- Проверить одну строку; конфликты имени/default не обходить отключением индексов.
-- COMMIT или ROLLBACK.
```

После изменения структуры таблицы старый backup адаптировать через admin import, а не выполнять этот INSERT вслепую. `migration/ws_store` не менять; здесь обслуживается только main/таблица аддона.

## Приёмка

- [ ] PostgreSQL: существующая/чистая БД, повторная миграция, CRUD, дубли, два одновременных default, optimistic conflict, восстановление backup.
- [ ] Реально прочитать/сохранить TEXT payload через EclipseLink в PostgreSQL, проверив взаимодействие текущего @Lob и text mapping; HSQL этого не доказывает.
- [ ] Admin screen позволяет удалить повреждённый preset без открытия сломанной бизнес-страницы.
- [ ] Зелёные skipped-тесты заменить реальными PostgreSQL-тестами; инструкции SQL проверить в одноразовой БД, не на пользовательских пресетах.
