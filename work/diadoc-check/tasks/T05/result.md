# Результат T05

Таск: [task.md](task.md)
Итерация: 1
Обновлено: 2026-09-21

## Что реализовано

Реализовано полностью, блокеров нет. В `rvk-diadoc` счёт-фактура, привязанная
по ИдПУД к ФПУ-26, попадает документом-дополнением в каждый пакет, где эта
ФПУ-26 присутствует — и в пакет-владелец, и в пакет-корректировку, подтянувший
ту же ФПУ-26 через `docid_arr`. Признак хранится в новой колонке
`diadoc_packet_doc_link.supplement_document` и уходит наружу: в бандл
`getPacketForSync` (`links[].supplementDocument`) и в `DocumentItemDto`
(`is_supplement`).

Исключение «ambiguous FPU_26 links» убрано. Вместо него при обработке СЧФ
собираются пакеты, которые уже линкуют её ФПУ-26, но саму СЧФ ещё нет, и
уходят в `relatedMessageIdsToProcess` (глубина 1 в `DocumentProcessingService`
не менялась). Правило самозатухающее: после дообработки пакет линкует СЧФ и
кандидатом не является, поэтому повторные прогоны ничего не порождают.

Итоговое состояние на данных -26 одинаково для всех четырёх порядков обработки
A/B/C и подтверждено тестами.

Ветка и коммит: `f/schf-supplement`, `b27af3a` (репозиторий
`/home/mindils/data/dev/fgk/rvk-diadoc`, ответвлена от `main` `1cb6ae6`).

## Изменения и решения

Модель и контракт:

- `processing/entity/DiadocPacketDocLink` — `Boolean supplementDocument`
  (`supplement_document`); changelog `01-tbp/tbl-diadoc_packet_doc_link.xml` —
  колонка в `createTable` и новый `changeSet id="10"` (`addColumn`,
  `defaultValueBoolean="false"`, preConditions `not columnExists`);
  ключ `DiadocPacketDocLink.supplementDocument` в `messages_ru.properties`.
- `PacketSyncLinkDto.supplementDocument` + `PacketSyncBundleAssembler.toLink`;
  `DocumentItemDto` — `@JsonProperty("is_supplement") Boolean supplement`;
  заполняется в `PacketDocumentDtoBuilder.toDocumentItemDto` и
  `PersistedPacketDtoAssembler.toDocumentItem`.
- `PacketAssemblyDocument` — компонент `boolean supplement` между `related` и
  `dataSource`; `DiadocPacketWriter` пишет его и сравнивает в
  `linkFieldsChanged` как `Boolean.TRUE.equals(link.get…) != doc.supplement()`,
  чтобы `null` на старых строках не считался изменением.

Алгоритм (`PacketAssemblyService`):

- признак `supplement` = не `invalidCurrentSchf`, тип `SCHF`, `parentEntityId`
  входит в множество `entityId` ФПУ-26 сборки; от `related`/`dataSource` не
  зависит;
- шаг ФПУ-26 → СЧФ: снят фильтр `!isDocidArrSource` (вынесен общий метод
  `fpuEntityIds`), остальное (SCHF-only, `!isInvalidSchfMessage`,
  `absorbedMessageIds`) без изменений;
- шаг СЧФ → ФПУ-26: загрузка родителей и `addDocs` сохранены, исключение и
  `addMessageIds(fpuDocs, expandableMessageIds)` убраны. Сообщение-владелец
  ФПУ-26 расширяет сборку только через `addExistingSchfParentDocuments` — и
  только когда родителя в сборке ещё нет; иначе в пакет-корректировку утёк бы
  чужой `PACKET` (тест `…whenPacketDocumentsOverlap`);
- `collectSupplementPacketMessageIds` — кандидаты на дообработку: живые линки
  на родителя минус пакеты, уже линкующие СЧФ; `retainExistingPackets`
  оставляет только messageId с живой строкой `diadoc_packet` (иначе чужой линк
  без пакета уводит дообработку в `No documents found`);
- `collectRelatedMessageIdsToProcess` объединяет `DOCID_ARR`-сообщения и
  кандидатов, вычитая текущее/каноническое/поглощённые;
- `loadLinkedMessageIdsByEntityIds` — снят фильтр по `originalMessageId`
  (soft-deleted линки и так скрыты);
- параметр `expandableMessageIds` у `addCrossMessageSchfLinks` стал
  неиспользуемым и удалён;
- `resolveCanonicalMessageId`, `DocumentProcessingService` (кроме javadoc и
  текста лога) и `PacketViolationService` не менялись.

Локальные решения, выходящие за букву постановки:

1. **Идентификаторы в плане перепутаны.** В разделе «Материалы» плана сообщение
   C указано как `fe79c311-…`, а СЧФ-entity — как `b17c632e-…`. В файле
   `rvk_diadoc_entity_detail-26.sql` наоборот: сообщение C =
   `b17c632e-9013-4db3-8c3b-868a9826b062`, entity СЧФ =
   `fe79c311-9419-4cad-8473-bad0e713d818` (ИдПУД `D0075456469`, TorID
   `D0075648756`). Тесты написаны по фактическим данным.
2. **Схема в тестовом SQL.** `rvk_diadoc_entity_detail-26.sql` обращался к
   `diadoc.diadoc_entity_detail`; тестовая БД подключается с
   `currentSchema=public`, и Liquibase падал с `relation … does not exist`.
   Префикс `diadoc.` убран — как во всех остальных файлах `liquibase/sql/`.
   Данные не менялись.
3. **Tombstone сообщения СЧФ.** Своя строка `diadoc_packet` у сообщения СЧФ
   появляется, только если оно обрабатывалось до наработки ФПУ-26 (standalone).
   В порядках A-B-C, B-C-A и A-C-B такой строки нет вовсе, и tombstone'ить
   нечего — в rvk-ws удалять тоже нечего. Поэтому `assertFinalState()`
   требует отсутствия живого пакета и живых линков C, а `deleted_date`
   проверяет, только если строка была создана.
4. **`spotlessApply` переформатировал `Fpu26ContentExtractor.java`** —
   нарушение форматирования существовало в `main` до этой задачи (перенос
   параметров record и двойной пробел). Изменение только форматное, вне
   области таска, но оставлено: иначе `spotlessCheckAll` у проверяющего
   покажет дифф.

## Предварительные проверки

| Команда или сценарий | Результат |
|---|---|
| `./gradlew compileJava` | успешно |
| `./gradlew spotlessApply` | применено; повторный прогон без диффа |
| `./gradlew test --tests "ru.fgk.rvk.diadoc.processing.SchfSupplementLinkingTest"` | 6 passing |
| `./gradlew test --tests "ru.fgk.rvk.diadoc.processing.PacketDocumentCrossMessageLinkingTest"` | 16 passing |
| `./gradlew test --tests "…PacketViolationServiceTest" --tests "…PacketDocumentSyncServiceTest" --tests "…PacketDocumentDtoBuilderTest" --tests "…DocumentProcessingServiceUnitTest"` | 25 passing |
| `select column_name, column_default from information_schema.columns where table_name='diadoc_packet_doc_link'` | `supplement_document boolean default false` — миграция применилась |

Не запускалось, оставлено проверяющему: полный `./gradlew test`,
`spotlessCheckAll`, ручная проверка через `bootRun` (порт 8081) и REST
(`POST /api/v2/documents/process`, `GET
/rest/services/packetDocument/getPacketForSync`), SQL-сверка
`diadoc_packet_doc_link` для A/B/C.

## Для независимой проверки

Окружение: контейнер `db-rvk-diadoc` (`localhost:5436`) поднят
(`cd envs/dev && docker compose ps`); `src/test/resources/
application-test-local.properties` на месте. Все команды — из корня
`/home/mindils/data/dev/fgk/rvk-diadoc`, ветка `f/schf-supplement`, коммит
`b27af3a`, рабочее дерево чистое.

```bash
(cd envs/dev && docker compose ps)
./gradlew test
./gradlew spotlessApply && git status --short   # ожидается пусто
```

Данные -26 (подключены как `test-026`, применяются Liquibase при старте
контекста):

| Роль | messageId | Ключевые entity |
|---|---|---|
| A — комплект ТР-2, владелец ФПУ-26 | `14bf2bcd-9a45-483d-a0b5-f76f001d9138` | PACKET `7417ec4a-cda2-4c66-99b1-a7c150e77f1a`, ФПУ-26 `a2532529-6c3c-41d8-8ea6-7aa84202d42e` (TorID `D0075456469`) |
| B — корректировка, ФПУ-26 из `docid_arr` | `be5aa61d-e5a0-4448-b5cb-9417a6d54c05` | PACKET `2e64406f-a615-49f1-8060-846667c6ad70` |
| C — СЧФ | `b17c632e-9013-4db3-8c3b-868a9826b062` | СЧФ `fe79c311-9419-4cad-8473-bad0e713d818` (TorID `D0075648756`, ИдПУД `D0075456469`) |

Ручной сценарий: `./gradlew bootRun` (профиль `dev`, порт 8081), затем
`POST /api/v2/documents/process` с `{"messageId": "<C>"}`, `<A>`, `<B>` в любом
порядке и `GET /rest/services/packetDocument/getPacketForSync?messageId=<B>` —
у линка на `fe79c311-…` ожидается `supplementDocument=true`,
`relatedDocument=true`, `originalMessageId` = C. SQL-сверка:

```sql
select message_id, entity_id, related_document, supplement_document,
       data_source, original_message_id, deleted_date
from diadoc_packet_doc_link
where message_id in ('14bf2bcd-9a45-483d-a0b5-f76f001d9138',
                     'be5aa61d-e5a0-4448-b5cb-9417a6d54c05',
                     'b17c632e-9013-4db3-8c3b-868a9826b062')
order by message_id, entity_id;
```

Негатив: `PacketDocumentCrossMessageLinkingTest.
shouldReturnStandaloneSchf_whenProcessSfchWithoutPreparedPacket` — СЧФ без
наработанной ФПУ-26 остаётся standalone с `is_supplement=false` (проверка
добавлена в тест).

Общие ресурсы: занята только БД `localhost:5436` и порт 8081 этого
репозитория; с T01/T03 не пересекается.

## Ограничения и связанные изменения

- В rvk-ws ничего не менялось; приём `supplementDocument` зеркалом — T03.
- Заменён тест `PacketDocumentCrossMessageLinkingTest.
  shouldThrow_whenSchfCanBeLinkedToMultiplePackets`: исключения больше нет,
  вместо него позитивный
  `shouldIgnoreLinkWithoutPacket_whenSchfLinkedToFpu26`.
- Кандидатами на дообработку становятся только сообщения с живой строкой
  `diadoc_packet`. Пакет, чья строка ещё не записана (линк без пакета),
  СЧФ-дополнение не получит до своей следующей обработки — это осознанный
  размен на защиту от `No documents found`.
- Известный пробел `PacketViolationService` (ложный `MISSING_DOCUMENT`, если
  единственный экземпляр TorID лежит в поглощённом сообщении) вне границ
  работы и не трогался.
