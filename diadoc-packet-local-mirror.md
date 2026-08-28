# Локальная копия пакетов Diadoc в rvk-ws

> **Обновлено:** локальное зеркало приведено к 4-табличной модели rvk-diadoc (1:1). Подробности и
> маппинг — в [`processing-refactor.md`](processing-refactor.md). Таблица `diadoc_packet_document`
> разделена на `diadoc_packet_doc` (PK `entity_id`) + `diadoc_packet_doc_link` (m2m); колонки
> `diadoc_*` из `diadoc_packet` удалены.

## Контекст

В `rvk-ws` пакеты Diadoc раньше читались напрямую из `rvk-diadoc` через REST DataStore. Это неудобно для гридов и фильтров, где нужно объединять данные Diadoc с локальными ws-таблицами: JPQL join с REST entity невозможен, а `propertyFilter` поверх REST работает неэффективно.

Дополнительная проблема: удаление пакета в `rvk-diadoc` должно быть видно в `rvk-ws`, чтобы локальная копия не оставалась активной после soft delete источника.

## Реализованное решение

1. В `rvk-ws` заведены локальные таблицы `main.diadoc_packet`, `main.diadoc_packet_doc`, `main.diadoc_packet_doc_link`, `main.diadoc_packet_doc_operation`.
2. В `rvk-diadoc` добавлен sync REST-метод, который возвращает пакет по `message_id`, включая soft-deleted запись.
3. В `rvk-ws` добавлен `POST /api/diadoc/syncPacket?messageId={uuid}` для поштучной синхронизации из NiFi.
4. Активный пакет синхронизируется как upsert.
5. Если источник в `rvk-diadoc` soft-deleted, локальный пакет в `rvk-ws` тоже soft-delete-ится.
6. Если источник физически отсутствует, endpoint возвращает `404`, локальная запись не меняется.

## Локальные таблицы rvk-ws

### `diadoc_packet`

Заголовок пакета. Primary key `message_id` равен `message_id` из `rvk-diadoc`.

Основные поля:

- `status`, `document_type`, `inn`, `kpp`, `available_from`, `correct_packet`, `error_message`
- `main_entity_id`, `main_signature_type`, `main_signature_at`
- `operations_first_at`, `operations_last_at`
- плоские поля из `content`: `depo`, `depo_code`, `wagnum`, `defect_date`, `repair_date`, `document_date`, `repair_date_vu36`
- `extra_data jsonb` для остатка `content`
- локальный аудит Jmix: `created_date`, `last_modified_date`, `deleted_date`, `deleted_by`

Локальные `created_date`/`last_modified_date` остаются audit-полями `rvk-ws` и отражают время
изменения локальной копии. Отдельного аудита источника (`diadoc_*`) больше нет — структура
выровнена с `rvk-diadoc` 1:1.

### `diadoc_packet_doc`

Документ, уникален по `entity_id` (PK). Привязка к пакетам — через `diadoc_packet_doc_link` (m2m).

Основные поля:

- `entity_id` (PK), `source_document_id`, `message_id` (исходное сообщение документа), `parent_entity_id`
- `entity_type`, `document_type`, `tor_document_id`, `filename`
- `signature_status`, `signature_timestamp`
- `document_number`, `document_date`, `amount`, `quantity`
- `extra_data jsonb`, `additional_data jsonb`, `xml`

### `diadoc_packet_doc_link`

m2m связь пакет ↔ документ. `id` детерминированный = `md5(message_id :: entity_id)`.

Основные поля:

- `id` (PK), `message_id` (пакет), `entity_id` (документ)
- `main_document`, `related_document`, `data_source`

### `diadoc_packet_doc_operation`

Операции документа:

- `entity_id`
- `entity_type_id`
- `last_oper_date`

`message_id` и `entity_id` в локальной БД всегда UUID. Если `rvk-diadoc` отдает их строками, sync приводит значения к UUID до сохранения. Foreign key constraints в Liquibase не создаются по правилу проекта. UUID-типы в changelog используются через `${uuid.type}`.

Так как таблицы `diadoc_packet*` новые и еще не должны нести историю production-миграций, их changelog-и держатся чистыми: итоговая структура описана в `createTable`, без отдельных корректирующих `addColumn`/`dropColumn` changeSet-ов. Если в локальной dev/test БД уже были старые варианты этих таблиц без данных, их можно удалить и дать Liquibase создать таблицы заново.

Проверенная структура в `main`:

- `diadoc_packet.message_id` - UUID primary key;
- `diadoc_packet.main_entity_id` - UUID ссылки на главный документ пакета;
- `diadoc_packet_doc.entity_id` - UUID сущности документа (primary key);
- `diadoc_packet_doc_link.message_id` / `diadoc_packet_doc_link.entity_id` - UUID связи пакет ↔ документ;
- `diadoc_packet_doc_operation.entity_id` - UUID сущности документа;
- `diadoc_packet_doc_operation.entity_type_id` - integer тип операции.

## Soft Delete

### В rvk-diadoc

В `PacketDocument` есть Jmix soft delete поля:

- `@DeletedDate deletedDate`
- `@DeletedBy deletedBy`

Обычный метод чтения пакета продолжает скрывать soft-deleted записи. Для синхронизации добавлен отдельный метод:

```java
PacketDocumentDto getPacketDocumentDtoForSync(String messageId)
```

Он загружает `PacketDocument` с `PersistenceHints.SOFT_DELETION=false`, поэтому возвращает как активный, так и soft-deleted пакет. Если запись физически отсутствует, возвращается `null`.

REST-метод в `rvk-diadoc`:

```text
/rest/services/packetDocument/getPacketDocumentForSync
```

DTO дополнен полями:

- `deleted_date`
- `deleted_by`

### В rvk-ws

Локальный `PacketDocument` тоже использует Jmix soft delete.

Поведение sync:

- active remote packet: локальная запись создается или обновляется, `deleted_date`/`deleted_by` очищаются;
- soft-deleted remote packet: локальная запись создается при необходимости и помечается soft-deleted;
- physically absent remote packet: `404`, локальная запись не меняется.

Локальные `deleted_date`/`deleted_by` отражают сам факт удаления локальной копии в `rvk-ws`
(`deleted_by = diadoc-sync`). Отдельный аудит источника не хранится — структура выровнена с
`rvk-diadoc` 1:1.

Child-строки `diadoc_packet_doc` и `diadoc_packet_doc_operation` при активной синхронизации
upsert-ятся/пересоздаются, а линки `diadoc_packet_doc_link` пересоздаются по `message_id`. Для
soft-deleted пакета линки и child-строки этого пакета удаляются физически, а tombstone остается в
`diadoc_packet`.

## Sync Endpoint rvk-ws

```text
POST /api/diadoc/syncPacket?messageId={uuid}
```

Endpoint оставлен под `@AnonymousAllowed` и выполняет синхронизацию через `SystemAuthenticator`, как внутренний интеграционный вход для NiFi. Ответ всегда `application/json` с одной схемой `SyncPacketResponse`.

HTTP-коды:

- `200 OK` — пакет синхронизирован: `result=synced` (upsert активного) или `result=deleted` (распространение soft delete).
- `404 Not Found` — пакет физически отсутствует в `rvk-diadoc`, `result=not_found`, локальная запись не меняется.
- `500 Internal Server Error` — ошибка REST, парсинга или БД, `result=internal_error`.

`GET /api/diadoc/syncPacket` не разрешён (`405 Method Not Allowed`).

### Схема ответа `SyncPacketResponse`

| Поле                | Тип       | Когда заполнено                                            |
|---------------------|-----------|------------------------------------------------------------|
| `status`            | string    | всегда (`ok` \| `error`)                                   |
| `result`            | string    | всегда (`synced` \| `deleted` \| `not_found` \| `internal_error`) |
| `messageId`         | UUID      | всегда (из query-параметра)                                |
| `message`           | string    | всегда (человекочитаемое описание)                         |
| `items`             | int       | `result=synced` — кол-во сохранённых `diadoc_packet_doc` |
| `operations`        | int       | `result=synced` — кол-во сохранённых `diadoc_packet_doc_operation` |
| `mainEntityId`      | UUID      | `result=synced` — UUID главного документа (может быть `null`) |
| `removedItems`      | int       | `result=deleted` — кол-во удалённых child-строк документов |
| `removedOperations` | int       | `result=deleted` — кол-во удалённых operation-строк        |

Поля `null` в ответ не включаются (`@JsonInclude(Include.NON_NULL)`).

### Примеры ответов

```json
// 200 — активная синхронизация
{
  "status": "ok",
  "result": "synced",
  "messageId": "9ce9a0bc-8ec5-4fe8-a545-db71f627b903",
  "message": "Packet synced",
  "items": 2,
  "operations": 3,
  "mainEntityId": "a3f1c2d4-..."
}

// 200 — soft delete распространён
{
  "status": "ok",
  "result": "deleted",
  "messageId": "9ce9a0bc-...",
  "message": "Packet soft-deleted locally",
  "removedItems": 2,
  "removedOperations": 3
}

// 404 — нет в rvk-diadoc
{
  "status": "error",
  "result": "not_found",
  "messageId": "00000000-0000-0000-0000-000000000000",
  "message": "Remote PacketDocument not found for messageId=00000000-0000-0000-0000-000000000000"
}

// 500 — необработанная ошибка
{
  "status": "error",
  "result": "internal_error",
  "messageId": "9ce9a0bc-...",
  "message": "<exception message>"
}
```

Пример вызова из NiFi:

```bash
curl -i -X POST "http://localhost:8080/api/diadoc/syncPacket?messageId=<UUID>"
```

## Правило `main_entity_id`

`main_entity_id` заполняется UUID `entityDetail` главного документа в таком порядке:

1. Сначала используется `main_document` из DTO пакета, потому что это явное поле источника и оно заполнено у части реальных пакетов даже тогда, когда в `documents[]` нет `is_main=true`.
2. Если `main_document` отсутствует, используется документ из `documents[]` с `is_main=true`.
3. Если `main_document` есть, но такого документа нет в `documents[]`, sync создает локальную строку документа из `main_document` и помечает ее как main.

Такой порядок сохраняет явный источник истины из `rvk-diadoc` и закрывает кейс реальных пакетов, где `documents[]` не содержит main-флаг.

## Файлы rvk-ws

Основные изменения:

- `app/src/main/java/ru/fgk/ws/app/diadoc/entity/PacketDocument.java`
- `app/src/main/java/ru/fgk/ws/app/diadoc/service/SyncPacketService.java`
- `app/src/main/java/ru/fgk/ws/app/diadoc/service/SyncPacketOutcome.java`
- `app/src/main/java/ru/fgk/ws/app/diadoc/service/SyncPacketResponse.java`
- `app/src/main/java/ru/fgk/ws/app/diadoc/service/SyncRemotePacketDto.java`
- `app/src/main/java/ru/fgk/ws/app/diadoc/service/SyncRemoteDocumentDto.java`
- `app/src/main/java/ru/fgk/ws/app/diadoc/service/PacketDocumentRemoteService.java`
- `app/src/main/java/ru/fgk/ws/app/diadoc/controller/SyncPacketRestController.java`
- `app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/01-tbl/tbl-diadoc_packet.xml`
- `app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/01-tbl/tbl-diadoc_packet_doc.xml`
- `app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/01-tbl/tbl-diadoc_packet_doc_link.xml`
- `app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/01-tbl/tbl-diadoc_packet_doc_operation.xml`
- `app/src/main/resources/ru/fgk/ws/app/messages_ru.properties`
- `app/src/test/java/ru/fgk/ws/app/diadoc/service/SyncPacketServiceTest.java`

## Файлы rvk-diadoc

Основные изменения:

- `src/main/java/ru/fgk/rvk/diadoc/processing/dto/PacketDocumentDto.java`
- `src/main/java/ru/fgk/rvk/diadoc/processing/mapper/PacketDocumentMapper.java`
- `src/main/java/ru/fgk/rvk/diadoc/service/PacketDocumentService.java`
- `src/main/java/ru/fgk/rvk/diadoc/service/rest/PacketDocumentRestService.java`
- `src/test/java/ru/fgk/rvk/diadoc/service/PacketDocumentSyncServiceTest.java`

## Тесты

Добавлены тесты `rvk-ws`:

- активный sync создает пакет, документы, source audit, `main_entity_id` из `main_document`; возвращает `SyncPacketOutcome.Synced` с верными счётчиками;
- повторный active sync не дублирует child-строки;
- soft-deleted remote пакет soft-delete-ит существующий локальный пакет, удаляет child-строки и возвращает `SyncPacketOutcome.Deleted` с счётчиками удалённых;
- soft-deleted remote пакет создает локальный tombstone, если записи еще нет;
- active sync реактивирует ранее soft-deleted локальный пакет;
- `POST /api/diadoc/syncPacket` для активного пакета возвращает JSON с `result=synced`, `items`, `operations`, `mainEntityId`;
- `POST` для soft-deleted remote возвращает JSON с `result=deleted`, `removedItems`, `removedOperations`;
- `POST` возвращает `404` с JSON `result=not_found`, когда remote пакет физически отсутствует;
- `GET /api/diadoc/syncPacket` отвечает `405 Method Not Allowed`.

Добавлены тесты `rvk-diadoc`:

- sync-метод возвращает активный пакет;
- sync-метод возвращает soft-deleted пакет;
- sync-метод возвращает `null`, если пакет физически отсутствует.

### Проверочные команды

Узкие тесты:

```bash
cd /home/mindils/data/dev/fgk/rvk-ws
./gradlew :app:test --tests "ru.fgk.ws.app.diadoc.service.SyncPacketServiceTest" --rerun-tasks

cd /home/mindils/data/dev/fgk/rvk-diadoc
./gradlew test --tests "ru.fgk.rvk.diadoc.service.PacketDocumentSyncServiceTest" --rerun-tasks
```

Результат узкого прогона `rvk-ws`: успешно, `7 passing`, `BUILD SUCCESSFUL`.

Полный прогон:

```bash
cd /home/mindils/data/dev/fgk/rvk-ws
./gradlew :app:test --rerun-tasks

cd /home/mindils/data/dev/fgk/rvk-diadoc
./gradlew test --rerun-tasks
```

Последний результат полного прогона `rvk-ws` после переименования локальных колонок:

- `rvk-ws`: успешно, `290 passing`, `3 pending`, `BUILD SUCCESSFUL`.
- `rvk-diadoc`: `BUILD FAILED`, `205 tests completed`, `34 failed`.

Новый `PacketDocumentSyncServiceTest` в `rvk-diadoc` внутри полного прогона прошел. Падения полного `rvk-diadoc` находятся в существующих наборах:

- `DiadocOutboundSendServiceTest`
- `DocumentSignatureTest`
- `DocumentValidationTest`
- `PacketDocumentContentFieldsTest`
- `PacketDocumentContentTest`
- `PacketDocumentCrossMessageLinkingTest`
- `PacketDocumentEntitiesTest`
- `PrPacketDocumentPersistenceIntegrationTest`
- `ProcessorSelectionTest`
- `DocumentProcessingServiceTest`
- `DocumentProcessingServiceUnitTest`
- `RawdataReportServiceTest`
- `RepairabilityRequestReportServiceTest`

Отчет Gradle: `/home/mindils/data/dev/fgk/rvk-diadoc/build/reports/tests/test/index.html`.

## Smoke Check

Активный пакет:

```bash
curl -i -X POST "http://localhost:8080/api/diadoc/syncPacket?messageId=<ACTIVE_UUID>"
```

Ожидаемо: `200 OK`, тело —
```json
{ "status": "ok", "result": "synced", "messageId": "<ACTIVE_UUID>",
  "message": "Packet synced",
  "items": <N>, "operations": <M>, "mainEntityId": "<UUID>" }
```
Запись есть в `main.diadoc_packet`, документы в `main.diadoc_packet_doc`, линки в `main.diadoc_packet_doc_link`. Счётчики `items`/`operations` совпадают с фактическим числом строк.

Soft-deleted пакет:

```bash
curl -i -X POST "http://localhost:8080/api/diadoc/syncPacket?messageId=<SOFT_DELETED_UUID>"
```

Ожидаемо: `200 OK`, тело —
```json
{ "status": "ok", "result": "deleted", "messageId": "<SOFT_DELETED_UUID>",
  "message": "Packet soft-deleted locally",
  "removedItems": <N>, "removedOperations": <M> }
```
Запись в `main.diadoc_packet` имеет локальный `deleted_date`, поля `diadoc_deleted_date`/`diadoc_deleted_by` содержат значения источника, child-строки физически удалены.

Физически отсутствующий пакет:

```bash
curl -i -X POST "http://localhost:8080/api/diadoc/syncPacket?messageId=00000000-0000-0000-0000-000000000000"
```

Ожидаемо: `404 Not Found`, тело —
```json
{ "status": "error", "result": "not_found",
  "messageId": "00000000-0000-0000-0000-000000000000",
  "message": "Remote PacketDocument not found for messageId=..." }
```
Локальная БД не меняется.
