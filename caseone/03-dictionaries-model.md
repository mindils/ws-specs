# 03. DTO и модель справочников-зеркал

> **Этап 2.** Начинать только после того, как этап 1 подтверждён на стенде и в
> `docs/caseone/samples/` лежат реальные JSON-ы. Колонки ниже выведены из спецификации
> февраля 2023 — сверять их надо с семплами, а не с PDF.

## Цель

DTO под ответы справочников + локальные таблицы-зеркала `participants`, `users`, `folders`
и журнал синхронизации.

## DTO справочников

`app/src/main/java/ru/fgk/ws/app/legal/caseone/dto/` — Java `record`-ы, по образцу
`app/src/main/java/ru/fgk/ws/app/diadoc/dto/rest/`.
`CaseOneTokenResponse` уже есть с задачи 02; здесь добавляются остальные.

Все — с `@JsonIgnoreProperties(ignoreUnknown = true)`: Case.one отдаёт заметно больше полей,
чем нам нужно, и состав меняется между версиями. Имена полей в JSON — **PascalCase**, маппим
через `@JsonProperty`.

| DTO | Поля |
|---|---|
| `CaseOnePage<T>` | `Items` (List&lt;T&gt;), `NextPageUrl` (String, nullable) |
| `CaseOneEntityRef` | `Id`, `Name` — общий вид вложенной ссылки |
| `CaseOneParticipantDto` | `Id`, `Name`, `Type`, `ClientId`, `PersonInfo`, `CompanyInfo`, `ContactInfo`, `CreationDate`, `LastChangeDate`, `Url` |
| `CaseOneUserDto` | `Id`, `Name`, `Email`, `ExternalId`, `FirstName`, `LastName`, `MiddleName`, `Initials`, `IsClient`, `IsLocked`, `WorkingStatus`, `CreationDate`, `LastChangeDate`, `Url` |
| `CaseOneFolderDto` | `Id`, `Name`, `HasChildren`, `Children`, `ObjectClass`, `CreationDate`, `LastChangeDate`, `Url` |

Вложенные: `CaseOnePersonInfo`, `CaseOneCompanyInfo`, `CaseOneContactInfo`, `CaseOneObjectClass`,
`CaseOneWorkingStatus`.

Даты — `OffsetDateTime` (в API формат `гггг-ММ-ддТЧЧ:мм:ss.fffZ`, UTC).

`CaseOnePage<T>` дженерик → для десериализации нужен `ParameterizedTypeReference` или
`TypeFactory.constructParametricType`.

### Типизированные методы в `CaseOneApiClient`

К сырому `get(path, query)` из задачи 02 добавляются типизированные:

```java
CaseOnePage<CaseOneParticipantDto> fetchParticipants(int page, int pageSize);
CaseOnePage<CaseOneUserDto>        fetchUsers(int page, int pageSize);
CaseOnePage<CaseOneFolderDto>      fetchFolders(@Nullable UUID parentId, int page, int pageSize);
<T> CaseOnePage<T> fetchNextPage(String nextPageUrl, Class<T> itemType);
```

Общий хелпер пагинации (чтобы не дублировать в трёх местах):

1. первая страница: `page=1`, `pageSize` из настроек;
2. пока `NextPageUrl != null` — идти по нему;
3. **fallback**, если на стенде `NextPageUrl` всегда null: инкремент `page`, пока `Items` не пуст;
4. жёсткий предел числа страниц (10 000) — защита от бесконечного цикла.

Если хост в `NextPageUrl` не совпадает с `baseUrl` из настроек (типично при работе через прокси) —
брать только path+query, хост подставлять из настроек.

## Общее решение по PK

`@Id UUID id` **без** `@GeneratedValue` — id приходит из Case.one. Это осознанное отклонение от
дефолта `CLAUDE.md` (`Long` + `IDENTITY`), обоснование:

- upsert идемпотентен без предварительного lookup по внешнему ключу;
- связи (участник → компания, папка → родитель) хранятся прямо как UUID источника, без
  разрешения ссылок;
- повторный полный прогон не плодит дубли даже при частичном сбое.

Журнал (`legal_caseone_sync_log`) и настройки (`legal_caseone_settings`) — обычные таблицы,
у них `Long id` + `IDENTITY`.

## Служебные колонки (у всех трёх зеркал)

| Колонка | Тип | Назначение |
|---|---|---|
| `source_creation_date` | timestamptz | `CreationDate` из Case.one |
| `source_last_change_date` | timestamptz | `LastChangeDate` — по нему считается дельта |
| `source_url` | varchar(1000) | `Url` записи в Case.one |
| `synced_at` | timestamptz | когда запись последний раз видели в источнике |
| `sync_run_id` | bigint | id прогона (`legal_caseone_sync_log.id`), в котором её видели |
| `is_missing` | boolean, default false | запись пропала из источника |

## `legal_caseone_participant` — контрагенты

`ru.fgk.ws.app.legal.caseone.entity.CaseOneParticipant`, `@JmixEntity(name = "legal_CaseOneParticipant")`,
`@InstanceName` на `name`.

| Колонка | Тип | Источник |
|---|---|---|
| `id` | UUID PK | `Id` |
| `name` | varchar(500) | `Name` |
| `participant_type` | varchar(50) | `Type` (физлицо / компания) |
| `client_id` | varchar(255) | `ClientId` |
| `last_name`, `first_name`, `middle_name` | varchar(255) | `PersonInfo.*` |
| `job_title` | varchar(500) | `PersonInfo.JobTitle` |
| `date_of_birth` | date | `PersonInfo.DateOfBirth` |
| `company_id` | UUID | `PersonInfo.Company.Id` — self-ссылка, **без FK** |
| `company_name` | varchar(500) | `CompanyInfo.Name` |
| `inn` | varchar(20) | `CompanyInfo.IdNumber` |
| `kpp` | varchar(20) | `CompanyInfo.KPP` |
| `ogrn` | varchar(20) | `CompanyInfo.OGRN` |
| `okpo` | varchar(20) | `CompanyInfo.OKPO` |
| `legal_form_id` | UUID | `CompanyInfo.LegalForm.Id` |
| `legal_form_name` | varchar(255) | `CompanyInfo.LegalForm.Name` |
| `email` | varchar(255) | `ContactInfo.Email` |
| `phone` | varchar(400) | `ContactInfo.Phone` |
| `site` | varchar(2000) | `ContactInfo.Site` |
| `address` | varchar(2000) | `ContactInfo.Address` |

Индексы: `source_last_change_date`, `is_missing`, `inn`, `company_id`.

## `legal_caseone_user` — пользователи

`ru.fgk.ws.app.legal.caseone.entity.CaseOneUser`, `@InstanceName` на `name`.

| Колонка | Тип | Источник |
|---|---|---|
| `id` | UUID PK | `Id` |
| `name` | varchar(500) | `Name` |
| `email` | varchar(255) | `Email` |
| `external_id` | varchar(255) | `ExternalId` |
| `first_name`, `last_name`, `middle_name` | varchar(255) | |
| `initials` | varchar(3) | `Initials` |
| `is_client`, `is_locked` | boolean | |
| `working_status_id` | UUID | `WorkingStatus.Id` |
| `working_status_name` | varchar(255) | `WorkingStatus.Name` |
| `working_status_sys_name` | varchar(100) | `WorkingStatus.SysName` |

Индексы: `source_last_change_date`, `is_missing`, `email`, `external_id`.

`external_id` — это Windows-логин; именно по нему в будущем свяжем пользователя Case.one с
пользователем `rvk-ws` при назначении ответственного за карточку.

## `legal_caseone_folder` — папки

`ru.fgk.ws.app.legal.caseone.entity.CaseOneFolder`, `@InstanceName` на `name`.

| Колонка | Тип | Источник |
|---|---|---|
| `id` | UUID PK | `Id` |
| `name` | varchar(500) | `Name` |
| `parent_id` | UUID | **не из ответа** — из контекста обхода дерева, без FK |
| `has_children` | boolean | `HasChildren` |
| `object_class_id` | UUID | `ObjectClass.Id` |
| `object_class_name` | varchar(255) | `ObjectClass.Name` |
| `object_class_sys_name` | varchar(100) | `ObjectClass.SysName` |
| `object_class_section` | varchar(256) | `ObjectClass.Section` |
| `object_class_icon` | varchar(100) | `ObjectClass.Icon` |
| `object_class_is_system` | boolean | `ObjectClass.IsSystem` |

Индексы: `source_last_change_date`, `is_missing`, `parent_id`.

## `legal_caseone_sync_log` — журнал синхронизации

`ru.fgk.ws.app.legal.caseone.entity.CaseOneSyncLog`, `Long id` + `IDENTITY`.

| Колонка | Тип |
|---|---|
| `dictionary` | varchar(30) — `PARTICIPANTS` / `USERS` / `FOLDERS` |
| `started_at`, `finished_at` | timestamptz |
| `status` | varchar(20) — `RUNNING` / `SUCCESS` / `ERROR` |
| `pages_read`, `items_read` | int |
| `created`, `updated`, `unchanged`, `marked_missing` | int |
| `error_text` | text |
| `triggered_by` | varchar(50) — `NIFI` / `UI` |

Индексы: `(dictionary, started_at desc)`, `status`.

## Enum-ы

`CaseOneDictionary` (PARTICIPANTS/USERS/FOLDERS), `CaseOneSyncStatus` (RUNNING/SUCCESS/ERROR),
`CaseOneParticipantType`, `CaseOneSyncTrigger` (NIFI/UI).

Через `io.jmix.core.metamodel.datatype.EnumClass` + паттерн `fromId` — см. skill `jmix-enums`.
Значения в БД — строковые id, а не ordinal. Локализация — в `messages_ru.properties`.

## Liquibase

Пять файлов в `app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/01-tbl/`:

- `tbl-legal_caseone_settings.xml` — уже создан в задаче 01
- `tbl-legal_caseone_participant.xml`
- `tbl-legal_caseone_user.xml`
- `tbl-legal_caseone_folder.xml`
- `tbl-legal_caseone_sync_log.xml`

Каждый — `runOnChange="true"` + `preConditions onFail="MARK_RAN"` на `tableExists`,
по образцу `tbl-diadoc_sign_settings.xml`. Индексы — отдельными changeSet-ами с
`preConditions` на `indexExists`. `<addForeignKeyConstraint>` **не использовать**.

Тип UUID в PostgreSQL — `uuid` (Jmix маппит `java.util.UUID` сам).
Сверяться со skill `jmix-liquibase`.

## Сверка с семплами — до написания Liquibase

Колонки выше выведены из спецификации февраля 2023, поля могли добавиться. Перед тем как
зафиксировать модель:

1. взять `docs/caseone/samples/*.json`, снятые тестовым экраном в задаче 02;
2. сверить состав полей с таблицами выше; расхождения внести в сущности **до** написания
   changelog-ов — переделывать созданную таблицу дороже;
3. по `folders-root.json` / `folders-children.json` проверить, приходит ли `Children`
   заполненным рекурсивно. Если да — обход дерева в задаче 04 не нужен, `parent_id`
   берётся из вложенности одного ответа.

Эти же файлы становятся фикстурами тестов десериализации (задача 07).

## Проверка

```sql
-- MCP rvk-ws
select table_name from information_schema.tables
 where table_schema = 'main' and table_name like 'legal_caseone%';
```
Ожидаем пять таблиц. `./gradlew :app:bootRun` поднимается без ошибок EclipseLink-маппинга.
