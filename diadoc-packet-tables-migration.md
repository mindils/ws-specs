# Миграция таблиц пакетов Diadoc (dev/test БД)

> Заметка для разработчиков. Касается локального зеркала пакетов Diadoc в `rvk-ws`.
> Структура приведена к модели `rvk-diadoc` 1:1 (подробно — [`processing-refactor.md`](processing-refactor.md)).
> **На проде применяется отдельно.** Ниже — что сделать на своей dev/test базе.

## Что поменялось

Было **3** таблицы → стало **4**. Таблица `diadoc_packet_document` разделена на документ +
m2m-связь.

| Старое | Новое | Что изменилось |
|---|---|---|
| `diadoc_packet` | `diadoc_packet` | убраны 4 колонки `diadoc_created_date`, `diadoc_last_modified_date`, `diadoc_deleted_date`, `diadoc_deleted_by` |
| `diadoc_packet_document` | `diadoc_packet_doc` | PK теперь `entity_id` (один документ — одна строка); добавлены `source_document_id`, `additional_data` (jsonb), `xml` (clob); `parent_entity_id` стал UUID; поля связи убраны |
| — | `diadoc_packet_doc_link` | **новая** m2m пакет↔документ: `message_id`, `entity_id`, `main_document`, `related_document`, `data_source`; `id = md5(message_id :: entity_id)` |
| `diadoc_packet_doc_operation` | `diadoc_packet_doc_operation` | без изменений |

Entity-классы переименованы: `PacketDocument → DiadocPacket`,
`PacketDocumentItem → DiadocPacketDoc`, `PacketDocumentItemOperation → DiadocPacketDocOperation`,
плюс новый `DiadocPacketDocLink`.

Данные в этих таблицах — локальное зеркало, наработаются заново синхронизацией. **Терять нечего.**

## Что сделать на dev/test базе

> Liquibase не дропает старые таблицы (по правилу проекта). Поэтому на уже существующей базе
> чистим вручную, иначе `createTable` уйдёт в `MARK_RAN` и структура `diadoc_packet` не обновится
> (останутся колонки `diadoc_*`).

Схема приложения — `main`.

### Шаг 1. Удалить таблицы

```sql
DROP TABLE IF EXISTS main.diadoc_packet;
DROP TABLE IF EXISTS main.diadoc_packet_doc_link;
DROP TABLE IF EXISTS main.diadoc_packet_doc_operation;
DROP TABLE IF EXISTS main.diadoc_packet_doc;
DROP TABLE IF EXISTS main.diadoc_packet_document; -- старая, если ещё осталась
```

### Шаг 2. Почистить историю Liquibase

Удаляем строки только по этим changelog-файлам. **`*_flow`-файлы НЕ трогаем** — это другие
таблицы (`diadoc_packet_flow`, `diadoc_packet_document_flow`), они вне изменений.

```sql
DELETE FROM main.databasechangelog
WHERE filename IN (
  'ru/fgk/ws/app/liquibase/changelog/01-tbl/tbl-diadoc_packet.xml',
  'ru/fgk/ws/app/liquibase/changelog/01-tbl/tbl-diadoc_packet_doc.xml',
  'ru/fgk/ws/app/liquibase/changelog/01-tbl/tbl-diadoc_packet_doc_link.xml',
  'ru/fgk/ws/app/liquibase/changelog/01-tbl/tbl-diadoc_packet_doc_operation.xml',
  'ru/fgk/ws/app/liquibase/changelog/01-tbl/tbl-diadoc_packet_document.xml'
);
```

(Превью того, что удалится — той же выборкой через `SELECT * FROM main.databasechangelog WHERE filename IN (...)`.)

### Шаг 3. Запустить приложение

Liquibase накатит 4 changelog-файла заново и создаст чистые таблицы в актуальной структуре.

### Шаг 4. Проверить

```sql
SELECT table_name, count(*) AS cols,
       count(*) FILTER (WHERE column_name LIKE 'diadoc\_%') AS diadoc_star
FROM information_schema.columns
WHERE table_schema = 'main'
  AND table_name IN ('diadoc_packet','diadoc_packet_doc',
                     'diadoc_packet_doc_link','diadoc_packet_doc_operation')
GROUP BY table_name
ORDER BY table_name;
```

Ожидаемо:

| table_name | cols | diadoc_star |
|---|---|---|
| `diadoc_packet` | 25 | 0 |
| `diadoc_packet_doc` | 19 | 0 |
| `diadoc_packet_doc_link` | 6 | 0 |
| `diadoc_packet_doc_operation` | 4 | 0 |

## Важно

- Структуру меняет именно **DROP**. Если удалить строки changelog, но не дропнуть таблицу —
  `createTable` снова уйдёт в `MARK_RAN` (precondition `not tableExists`), и `diadoc_*`-колонки в
  `diadoc_packet` останутся.
- Foreign key constraints на эти таблицы не создаются — зависимостей, мешающих DROP, нет.
