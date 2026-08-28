# Выравнивание модели пакетов Diadoc в rvk-ws под rvk-diadoc (1:1)

## Контекст

В `../rvk-diadoc` модель пакетов отрефакторена (ветка `feature/process-refactor`) в реляционную
модель из 4 таблиц. Чтобы данные можно было переливать из `rvk-diadoc` в `rvk-ws` один к одному
(raw DB→DB и/или поштучный sync), локальное зеркало `rvk-ws` приведено к той же структуре и тем же
именам таблиц/колонок. Данные неважны — наработаны заново.

## Целевые таблицы (одинаковы в rvk-diadoc и rvk-ws)

| Таблица | PK | Назначение |
|---|---|---|
| `diadoc_packet` | `message_id` (UUID) | заголовок бизнес-пакета |
| `diadoc_packet_doc` | `entity_id` (UUID) | документ (интринсик-поля), один на `entity_id` |
| `diadoc_packet_doc_link` | `id` (UUID, md5) | m2m связь пакет ↔ документ (`main_document`, `related_document`, `data_source`) |
| `diadoc_packet_doc_operation` | `id` (UUID) | операции документа 1—N |

## Что изменилось в rvk-ws

Старое зеркало было из 3 таблиц: `diadoc_packet`, `diadoc_packet_document`,
`diadoc_packet_doc_operation`. Таблица `diadoc_packet_document` смешивала поля документа и поля
связи с пакетом.

- **`diadoc_packet`** — убраны 4 колонки `diadoc_created_date`, `diadoc_last_modified_date`,
  `diadoc_deleted_date`, `diadoc_deleted_by` (их нет в rvk-diadoc). Аудит источника отдельно больше
  не хранится; локальные `created_date`/`last_modified_date`/`deleted_date`/`deleted_by` остаются
  Jmix-аудитом локальной копии.
- **`diadoc_packet_document` → `diadoc_packet_doc` + `diadoc_packet_doc_link`**. Документ теперь
  уникален по `entity_id` (PK), привязка к пакету (и `main_document`/`related_document`/`data_source`)
  вынесена в m2m-таблицу `diadoc_packet_doc_link` с детерминированным `id = md5(message_id :: entity_id)`.
  В `diadoc_packet_doc` добавлены `source_document_id`, `additional_data` (jsonb), `xml` (clob);
  `parent_entity_id` стал UUID.
- **`diadoc_packet_doc_operation`** — без изменений (уже совпадала 1:1).

### Решения

1. `SyncPacketService` переписан под 4-табличную модель (legacy-REST источник не изменился).
2. Колонки `diadoc_*` удалены ради точного 1:1.
3. Entity-классы переименованы в стиль rvk-diadoc.

## Маппинг entity-классов rvk-ws

| Было | Стало | Таблица |
|---|---|---|
| `PacketDocument` | `DiadocPacket` | `diadoc_packet` |
| `PacketDocumentItem` | `DiadocPacketDoc` | `diadoc_packet_doc` |
| — (новый) | `DiadocPacketDocLink` | `diadoc_packet_doc_link` |
| `PacketDocumentItemOperation` | `DiadocPacketDocOperation` | `diadoc_packet_doc_operation` |

Детерминированные id связей совпадают с rvk-diadoc через
`ru.fgk.ws.app.common.utils.UuidUtil.generateMd5Uuid(messageId, entityId)` (разделитель `::`).

## Изменённые файлы

- Liquibase: `01-tbl/tbl-diadoc_packet.xml` (правка), `01-tbl/tbl-diadoc_packet_doc.xml`
  (бывш. `tbl-diadoc_packet_document.xml`, переписан + drop legacy), `01-tbl/tbl-diadoc_packet_doc_link.xml`
  (новый), `01-tbl/tbl-diadoc_packet_doc_operation.xml` (без изменений).
- Entities: `DiadocPacket`, `DiadocPacketDoc`, `DiadocPacketDocLink`, `DiadocPacketDocOperation`
  (пакет `ru.fgk.ws.app.diadoc.entity`).
- Service: `SyncPacketService` (rewrite).
- i18n: `messages_ru.properties`.
- Tests: `SyncPacketServiceTest`.
- Spec: этот файл, обновлён `diadoc-packet-local-mirror.md`.

## Проверка

```bash
./gradlew :app:compileTestJava
./gradlew :app:test --tests "ru.fgk.ws.app.diadoc.service.SyncPacketServiceTest" --rerun-tasks
```

Сверка схемы 1:1 (через MCP `rvk-ws` vs `rvk-diadoc`):

```sql
SELECT column_name, data_type FROM information_schema.columns
WHERE table_name = 'diadoc_packet_doc' ORDER BY 1;
```

Sync smoke: `POST /api/diadoc/syncPacket?messageId=<UUID>` → строки в `diadoc_packet`,
`diadoc_packet_doc`, `diadoc_packet_doc_link` (с `id = md5(message_id::entity_id)`),
`diadoc_packet_doc_operation`.
