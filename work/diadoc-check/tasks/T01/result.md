# Результат T01

Таск: [task.md](task.md)
Итерация: 1
Обновлено: 2026-09-21

## Что реализовано

Настройки обработки пакетов Диадок разделены на два уровня. У контрагента
четыре флага живут в существующей `DiadocSignSettings`
(`show_related_documents`, `check_duplicate_tor_document`,
`check_cross_packet_reference`, `check_missing_document`, все `NOT NULL`),
экран которой переименован в «Настройки Диадок по контрагентам». Умолчания
хранит новая singleton-entity `DiadocSettings` (таблица `diadoc_settings`) с
собственным экраном «Настройки Диадок по умолчанию»
(`diadoc_DiadocSettings.view`, route `diadoc/settings`).

Единственная точка чтения — `DiadocProcessingSettingsService`: `getDefaults()`
создаёт строку умолчаний при первом обращении со значениями
`true,false,false,false`; `resolve(DiadocContractor)` отдаёт строку контрагента,
а при её отсутствии или неопределённом контрагенте — умолчания;
`resolveForPacket(DiadocPacket)` разрешает настройки по `packet.getContractor()`.
Кеша нет, инъекция только через конструктор. Контракт (`record
DiadocProcessingSettings`) — тот, что зафиксирован планом для T02 и T04.

Оба экрана и связанные detail-диалоги выдаёт новая роль
`diadoc-settings-admin` (`DiadocSettingsAdminRole`, scope UI) вместе со
specific-контекстом `DiadocSettingsEditEnabled`
(`diadocSettingsEdit.enabled`) — его в T04 читает галочка на карточке пакета.
Рабочей роли `ws-user` настройки по-прежнему недоступны.

## Изменения и решения

- `diadoc/entity/DiadocSignSettings.java` — четыре `Boolean` `@NotNull` с
  инициализаторами по умолчанию (иначе `ConstraintViolationException` на пути
  `DataManager` для строк, созданных вне экрана).
- `diadoc/entity/DiadocSettings.java` — новая singleton-entity.
- `diadoc/service/DiadocProcessingSettings.java` (record) и
  `DiadocProcessingSettingsService.java`.
- `security/diadoc/DiadocSettingsAdminRole.java`,
  `security/diadoc/specific/DiadocSettingsEditEnabled.java`.
- `diadoc/view/settings/` — новый `DiadocSettingsView` + `diadoc-settings-view.xml`;
  в `diadoc-sign-settings-detail-view.xml` добавлен блок «Обработка пакетов»
  с четырьмя `checkbox` и убран лишний символ `s` после `<h4 text="Тип пакета">`;
  в `diadoc-sign-settings-list-view.xml` — четыре колонки-флажка;
  `DiadocSignSettingsDetailView.onInitEntity` инициализирует новую строку
  контрагента из `getDefaults()`.
- `liquibase/changelog/01-tbl/tbl-diadoc_settings.xml` (новый) и
  `tbl-diadoc_sign_settings.xml` (обновлён `createTable` плюс четыре
  `addColumn` с preConditions и `defaultValueBoolean`).
- `menu.xml` — пункт «Настройки Диадок по умолчанию» рядом с существующим.
- `messages_ru.properties` — подписи полей обеих entity, заголовки и тексты
  обоих экранов; заголовок списка и меню — «Настройки Диадок по контрагентам».

Существенные локальные решения:

- Сервис читает через `UnconstrainedDataManager`. Настройки нужны при показе
  карточки пакета и при обработке любому пользователю, а право их менять есть
  только у администратора; ограничение на запись остаётся на экранах, которые
  сохраняют обычным `DataManager` (это и проверяет `DiadocSettingsAdminRoleIT`).
- Заголовок detail-экрана контрагента изменён с «Настройки подписания» на
  «Настройки Диадок по контрагенту» — иначе переименование списка оставляет
  диалог со старым названием. Таск требовал переименовать только список и меню.
- Существующие `<h4 text="Тип пакета">` и `<h4 text="Настройки подписания
  документа">` в detail XML оставлены с hardcoded-текстом: это legacy-строки вне
  поручения, новый блок сделан через `msg://`.

## Предварительные проверки

| Команда или сценарий | Результат |
|---|---|
| `./gradlew :app:compileJava` | успешно |
| `./gradlew spotlessApply`, `./gradlew spotlessCheckAll` | успешно |
| `./gradlew :app:test --tests "ru.fgk.ws.app.it.DiadocProcessingSettingsIT" --tests "ru.fgk.ws.app.it.DiadocSettingsAdminRoleIT"` | 8 passing |
| Повторный прогон `DiadocProcessingSettingsIT` (второй проход миграций по существующей схеме) | 5 passing, changeSet-ы 4–7 отработали `MARK_RAN`, ошибок Liquibase нет |
| SQL-сверка колонок в `main_f_diadoc_check` | `diadoc_settings` и четыре колонки `diadoc_sign_settings` есть, `NOT NULL`, значения по умолчанию `true/false/false/false`, `id` — identity |
| Механические проверки дескрипторов (`jmix-ide-static-analysis`, п. 3) | чисто: пролог XML, package-строки, 0-байтовые файлы среди изменённых отсутствуют, все `msg://` изменённых XML и `menu.xml` резолвятся в `messages_ru.properties` |
| Браузерный smoke: `bootRun` (8082), `/local-login`, пользователь с `diadoc-settings-admin` | оба пункта меню видны; «Настройки Диадок по умолчанию» открываются с четырьмя чекбоксами и начальными значениями, сохранение даёт «Настройки сохранены» и строку в `diadoc_settings`; список настроек по контрагентам показывает пять колонок с русскими подписями; диалог создания приходит с блоком «Обработка пакетов», заполненным из умолчаний, сохранение пишет строку в `diadoc_sign_settings`; лишнего `s` после заголовка «Тип пакета» нет; сырых `msg://` нет |
| Браузерный негатив: тот же стенд под пользователем только с `ws-user` | пунктов меню нет, `/diadoc/settings` и `/diadoc-sign-settings` дают Access Denied (`UiShowViewConstraint` в логе) |

Единственная ошибка в консоли браузера на всех экранах — загрузка аватара с
`info.main.vgk` (корпоративный хост, снаружи контура не резолвится), к
изменениям T01 отношения не имеет.

Не запускалось, оставлено проверяющему: полный `./gradlew :app:test`
(в том числе `DiadocPacketFlowServiceTest`, `DiadocDocumentFlowServiceTest`
по C4), браузерный проход остальных экранов Диадок, проверка невозможности
завести вторую строку умолчаний через UI, редактирование уже существующей
строки контрагента и работа дочерних гридов типов пакетов/документов после
добавления блока «Обработка пакетов».

IDE-инспекция (`get_file_problems`) в этой сессии недоступна — Gate 1 пройден
откатом на `compileJava` плюс механические проверки. Переинспектировать стоит
`diadoc-settings-view.xml`, `diadoc-sign-settings-detail-view.xml`,
`diadoc-sign-settings-list-view.xml`.

## Для независимой проверки

Окружение: `docker compose` в `docker/` поднят, схема `main_f_diadoc_check` на
`localhost:5432` (`root`/`root`), `app/src/test/resources/application-test-local.properties`
указывает на неё. Порт приложения — 8082 (`application-local.properties`,
профиль `dev` включает `local` через `spring.profiles.group.dev=local`), так
что `bootRun` запускается без дополнительных ключей. Приложение в этой сессии
было остановлено — поднимать заново.

Команды:

```bash
./gradlew :app:compileJava
./gradlew spotlessCheckAll
./gradlew :app:test --tests "ru.fgk.ws.app.it.DiadocProcessingSettingsIT" \
  --tests "ru.fgk.ws.app.it.DiadocSettingsAdminRoleIT" \
  --tests "ru.fgk.ws.app.diadoc.service.*"
```

SQL-сверка (C1):

```sql
select table_name, column_name, data_type, column_default, is_nullable
from information_schema.columns
where table_schema = 'main_f_diadoc_check'
  and table_name in ('diadoc_settings', 'diadoc_sign_settings')
order by table_name, ordinal_position;
```

Браузер: `bootRun`, `http://localhost:8082/local-login`. В схеме
`main_f_diadoc_check` (она развёрнута только миграциями) из пользователей есть
один `admin` / `admin` с `system-full-access`; заявленного в CLAUDE.md
`user`/`user` здесь нет. Пользователя под роль нужно завести самому — либо
через администрирование под `admin`, либо напрямую:

```sql
insert into sso_user (id, version, username, password, active)
values (gen_random_uuid(), 1, '<имя>', '{noop}<пароль>', true);
insert into sec_role_assignment (id, username, role_code, role_type)
values (gen_random_uuid(), '<имя>', 'diadoc-settings-admin', 'resource'),
       (gen_random_uuid(), '<имя>', 'ws-user', 'resource'),
       (gen_random_uuid(), '<имя>', 'ui-minimal', 'resource');
```

`ui-minimal` обязателен: без `ui.loginToUi` вход в UI отклоняется, а
`diadoc-settings-admin` — надстройка и этого права не даёт (как и
`legal-caseone-admin`). Контрагентов в схеме тоже нет — для сценария с CDI
строку `nsi_diadoc_contractor` (ИНН 7708503727) нужно создать.

Сценарий: под ролью в меню «Диадок» видны «Настройки Диадок по контрагентам» и
«Настройки Диадок по умолчанию»; на первом — создать строку для CDI с
включёнными проверками, сохранить, переоткрыть; на втором — изменить умолчания
и сохранить. Под пользователем только с `ws-user` и `ui-minimal` пунктов меню
нет, прямой переход на `http://localhost:8082/diadoc/settings` и
`/diadoc-sign-settings` закрыт. Созданные для проверки пользователи, роли,
контрагенты и строки настроек нужно убрать — схема общая для всех тасков
работы.

Общие ресурсы (по разделу таска «Область и изоляция»): схема
`main_f_diadoc_check`, порт 8082, Gradle daemon — занимать по одному.

## Ограничения и связанные изменения

- `DiadocSignSettings` больше не сохраняется без значений четырёх флагов.
  Кода, создающего её вне экрана настроек, в проекте нет, поэтому на другие
  таски это не влияет; строки существующих БД закрываются `defaultValueBoolean`.
- В `DiadocSettingsAdminRoleIT` назначения ролей снимаются через
  `JdbcTemplate`, а не `DataManager`: удаление `RoleAssignmentEntity` через
  `DataManager` до таблицы не доходит, записи копились в общей схеме между
  прогонами (обнаружено и вычищено в этой сессии). Имена таблиц не
  квалифицированы схемой — схема задана в JDBC URL профиля тестов. Тот же
  дефект есть в существующих `NsiClaimTermEditRoleIT` и `TechClaimDeadlineIT`,
  но там уборка ещё и прибита к схеме `main.`, поэтому в worktree-схеме не
  работает вовсе; чинить их — вне поручения T01.
- Замечено вне области таска: `diadoc/view/packetdocument/packet-document-detail-view.xml`
  и `packet-document-list-view.xml` — нулевого размера с коммита `0c510be9f`.
  На реестр view это не влияет (на них не ссылается ни один `@ViewDescriptor`),
  трогать их в рамках T01 нечем.
