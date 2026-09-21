# T05 — rvk-diadoc: СЧФ-дополнение во всех пакетах с её ФПУ-26

Статус: ready_for_verify
План: [plan.md](../../plan.md)
Зависимости: нет
Сложность: hard — изменение алгоритма сборки пакетов в чужом репозитории,
порядконезависимость, tombstone
Сложность проверки: hard — интеграционные тесты на живой БД в четырёх
порядках обработки, проверка идемпотентности и отсутствия ложных нарушений
Актуальная проверка: нет

## Коротко

В `rvk-diadoc` (`/home/mindils/data/dev/fgk/rvk-diadoc`) счёт-фактура,
привязанная по ИдПУД к ФПУ-26, должна попадать в каждый пакет, где этот
ФПУ-26 присутствует (свой или подтянутый из `docid_arr`), как
«документ-дополнение» с новым признаком `supplement_document` в
`diadoc_packet_doc_link`. Исключение «ambiguous FPU_26 links» убирается.
Признак уходит в бандл для rvk-ws (`supplementDocument`) и в
`DocumentItemDto` (`is_supplement`). Проверяется на тестовых данных
`rvk_diadoc_entity_detail-26.sql`, которые нужно подключить в тестовый
changelog.

## Результат и контекст

Правила репозитория — его `CLAUDE.md`/`AGENTS.md`. Тесты — `./gradlew test
--tests "<класс>"` (профиль `test`, БД `localhost:5436` из
`envs/dev/docker-compose.yml`, контейнер `db-rvk-diadoc` поднят;
`src/test/resources/application-test-local.properties` есть). Тестовые SQL
применяются Liquibase при старте контекста через
`src/test/resources/ru/fgk/rvk/diadoc/liquibase/test-changelog/
010-rvk_diadoc_diadoc_diadoc_entity_detail-data.xml` (последний — `test-025`,
строки 169-174, `runOnChange="true"`). `BaseIntegrationTest`
(`src/test/java/ru/fgk/rvk/diadoc/test_support/`) — `@Transactional`,
чистит `diadoc_packet*` перед каждым тестом, мокает `DiadocApiClient`.

Текущее поведение (`src/main/java/ru/fgk/rvk/diadoc/processing/service/
PacketAssemblyService.java`):

- цикл 66-83: `ensurePacketTorDocuments` (документы перечня PACKET по
  TorID, помечаются `DOCID_ARR`), `addExistingSchfParentDocuments`
  (родитель СЧФ по `parentEntityId`, расширяет его сообщение),
  `addCrossMessageSchfLinks`, `addKnownMessageDocuments`;
- `addCrossMessageSchfLinks` 180-233: шаг ФПУ-26 → СЧФ только для ФПУ-26
  не из `DOCID_ARR` (фильтр строки 193) — поэтому корректировка B не
  получает СЧФ; шаг СЧФ → ФПУ-26 (206-232): `loadLinkedMessageIdsByEntityIds`
  (466-482) оставляет только линки-владельцы (`original_message_id` null
  или равен `message_id`), при >1 владельце — исключение 225-229;
  строка 231 расширяет сообщения владельцев ФПУ-26;
- `resolveCanonicalMessageId` 315-347: PACKET текущего сообщения, иначе
  единственный PACKET сборки (при нескольких — исключение), иначе
  сообщение первого ФПУ-26;
- `collectRelatedMessageIdsToProcess` 399-419 — сообщения `DOCID_ARR`-
  документов минус текущее/каноническое/поглощённые; их обрабатывает
  `DocumentProcessingService.processDocument` (87-104) отдельными
  транзакциями на глубину 1;
- `DiadocPacketWriter.writePacketAndLinks` пишет линки только для
  канонического messageId (поля 122-125, `linkFieldsChanged` 151-158),
  `tombstone` soft-удаляет пакет и линки поглощённых сообщений;
  `deleteNonCanonicalPacketDocuments` (259-267) вызывает его для всех
  `allMessageIds` кроме канонического.
- `SchfContentExtractor` (85-89) ставит `parentEntityId` = первый ФПУ-26
  по TorID из сырой таблицы — независимо от порядка обработки.

Данные -26 (раздел «Материалы» плана): A владеет ФПУ-26 `a2532529-…`
(TorID `D0075456469`), B — корректировка, перечисляющая его в `docid_arr`,
C — СЧФ `b17c632e-…` (свой TorID `D0075648756`, ИдПУД=`D0075456469`).
Ни один `docid_arr` не содержит TorID СЧФ, поэтому нарушений
MISSING/DUPLICATE по нему быть не должно; экземпляры из tombstone-сообщения
`PacketViolationService.loadLiveInstancesByTor` исключает.

Ожидаемое состояние после обработки A, B, C в любом порядке: пакет A —
ФПУ-26 (`related=false`, `dataSource=null`, `supplement=false`), СЧФ
(`related=true`, `supplement=true`, `originalMessageId=C`); пакет B —
ФПУ-26 (`related=true`, `dataSource=DOCID_ARR`, `originalMessageId=A`,
`supplement=false`), СЧФ (`related=true`, `supplement=true`,
`originalMessageId=C`), без линка на PACKET A; сообщение C — tombstone
(`deleted_date` у пакета и линков); в `violations` A и B нет записей по
`D0075648756`; повторная обработка C и B идемпотентна.

## Область и изоляция

Репозиторий `rvk-diadoc` целиком; в rvk-ws ничего не менять (зеркало —
T03). Файлы: `processing/service/PacketAssemblyService.java`,
`processing/assembler/PacketAssemblyDocument.java`,
`processing/service/DiadocPacketWriter.java`,
`processing/assembler/PacketDocumentDtoBuilder.java`,
`processing/assembler/PersistedPacketDtoAssembler.java`,
`processing/assembler/PacketSyncBundleAssembler.java`,
`processing/dto/{PacketSyncLinkDto,DocumentItemDto}.java`,
`processing/entity/DiadocPacketDocLink.java`,
`src/main/resources/ru/fgk/rvk/diadoc/liquibase/changelog/01-tbp/
tbl-diadoc_packet_doc_link.xml`, `messages_ru.properties`, тестовый
changelog и тесты. Ресурсы — БД 5436 и порт 8081 только этого репозитория;
параллельно с T01/T03 без ограничений.

## Реализация

1. Модель: `DiadocPacketDocLink.supplementDocument` (`@Column(name =
   "supplement_document")`, javadoc «документ-дополнение: СЧФ, привязанная
   по ИдПУД к ФПУ-26 пакета»); changelog — колонка в `createTable` после
   `related_document` и новый changeSet `addColumn` с preConditions
   `not columnExists`, `defaultValueBoolean="false"` (существующие линки
   не перезаписываются массово); ключ
   `ru.fgk.rvk.diadoc.processing.entity/DiadocPacketDocLink.supplementDocument=Документ-дополнение`.
   `PacketSyncLinkDto.supplementDocument` + `PacketSyncBundleAssembler.toLink`;
   `DocumentItemDto` — `@JsonProperty("is_supplement") Boolean supplement`
   рядом с `is_related`; `PacketDocumentDtoBuilder.toDocumentItemDto` и
   `PersistedPacketDtoAssembler.toDocumentItem` заполняют его.
   `PacketAssemblyDocument` получает компонент `boolean supplement` (между
   `related` и `dataSource`); `DiadocPacketWriter` пишет его и учитывает в
   `linkFieldsChanged` (null-safe: `Boolean.TRUE.equals(link.get…) !=
   doc.supplement()`).
2. `PacketAssemblyService.assemble`: признак `supplement` = не
   `invalidCurrentSchf`, тип `SCHF`, `parentEntityId` входит в множество
   `entityId` ФПУ-26 сборки; независим от `related`/`dataSource`.
3. `addCrossMessageSchfLinks`, шаг ФПУ-26 → СЧФ: снять фильтр
   `!isDocidArrSource` (строка 193) — остальное (SCHF-only,
   `!isInvalidSchfMessage`, `absorbedMessageIds`) как есть. Это даёт
   корректировке B СЧФ и tombstone C при обработке B.
4. Шаг СЧФ → ФПУ-26: сохранить загрузку родителей и `addDocs`; убрать
   `addMessageIds(fpuDocs, expandableMessageIds)` (строка 231 — иначе при
   обработке B в сборку утечёт PACKET A, что запрещает тест
   `shouldLinkDocidArrDocumentsWithOriginalMessageId_whenPacketDocumentsOverlap`);
   убрать исключение 225-229. Вместо него собрать
   `supplementPacketMessageIds`: для каждой СЧФ сборки с родителем P —
   все живые линки на P (в `loadLinkedMessageIdsByEntityIds` снять фильтр
   по `originalMessageId`; soft-deleted линки уже скрыты) минус пакеты, уже
   линкующие СЧФ, минус текущее сообщение и сообщение-владелец P; оставить
   только id с живой строкой `diadoc_packet` (иначе чужой линк без пакета
   приведёт к `No documents found` в дообработке). Добавить их в
   `relatedMessageIdsToProcess` (не в `absorbedMessageIds` и не в
   `expandableMessageIds`). Правило самозатухающее: после дообработки пакет
   линкует СЧФ и кандидатом не является.
5. `resolveCanonicalMessageId` и `DocumentProcessingService` не менять
   (обновить javadoc/лог про related-сообщения: «docid_arr или
   СЧФ-дополнение»). `PacketViolationService` не менять.
6. Тесты: `test-026` в тестовом changelog по образцу `test-025`;
   `PacketDocumentCrossMessageLinkingTest.shouldThrow_whenSchfCanBeLinkedToMultiplePackets`
   заменить позитивным (чужой линк на ФПУ-26 без строки пакета
   игнорируется, СЧФ линкуется в пакет с `supplement=true`,
   `related=true`, `originalMessageId` = сообщение СЧФ); в merge-тестах
   добавить проверку `is_supplement`; новый
   `src/test/java/ru/fgk/rvk/diadoc/processing/SchfSupplementLinkingTest.java`
   на данных -26 для порядков A-B-C, C-A-B, B-C-A, A-C-B с общим
   `assertFinalState()` (см. «Результат и контекст»), `entityManager.flush()/
   clear()` между вызовами `processDocument`, плюс идемпотентность
   повторной обработки C и B и проверка DTO `processDocument(C)`
   (`messageId == A`, СЧФ `is_supplement=true`); правки арности record в
   `PacketDocumentDtoBuilderTest`, `DocumentProcessingServiceUnitTest`;
   кейс в `PacketViolationServiceTest` (линк на СЧФ из tombstone-сообщения
   не даёт нарушений); `PacketDocumentSyncServiceTest` — поле в бандле.
7. Риски, которые нужно удержать: петли дообработки (глубина 1 в
   `DocumentProcessingService` + самозатухание), «Multiple PACKET
   messageIds» (кандидаты не расширяются), утечка чужого PACKET в
   корректировку (п.4), `hasSchfWithExtraDocuments` (guard'ы 59-62, 187-189,
   200 не трогать; `supplement=false` при `invalidCurrentSchf`).

## Критерии приёмки

- C1: `SchfSupplementLinkingTest` зелёный во всех четырёх порядках и на
  повторной обработке.
- C2: `PacketDocumentCrossMessageLinkingTest` зелёный целиком, включая
  заменённый тест и `…whenPacketDocumentsOverlap`.
- C3: `PacketViolationServiceTest`, `PacketDocumentSyncServiceTest`,
  `PacketDocumentDtoBuilderTest`, `DocumentProcessingServiceUnitTest`
  зелёные; бандл `getPacketForSync(A)` содержит `supplementDocument=true` у
  линка СЧФ.
- C4: Полный `./gradlew test` — `0 failing`; `spotlessApply` без диффа.
- C5: На существующих линках после миграции `supplement_document=false`,
  повторная обработка старого пакета не переписывает все его линки.

## Самопроверка исполнителя

`./gradlew compileJava`, `spotlessApply`, `./gradlew test --tests
"ru.fgk.rvk.diadoc.processing.SchfSupplementLinkingTest" --tests
"ru.fgk.rvk.diadoc.processing.PacketDocumentCrossMessageLinkingTest"`.
Полный `test` оставить проверяющему; записать в `result.md` точные
команды и id использованной ветки/коммита.

## Независимая проверка

Полный `./gradlew test` на БД 5436 (после `docker compose ps` в
`envs/dev`), `spotlessCheckAll`/`spotlessApply` без диффа. Дополнительно
вручную: `./gradlew bootRun` (8081), `POST /api/v2/documents/process`
`{"messageId": "<A|B|C>"}` в порядке C, A, B и запрос
`GET /rest/services/packetDocument/getPacketForSync?messageId=<B>` (или
`/api/diadoc/packetForSync`) — линк СЧФ с `supplementDocument=true`;
SQL по `diadoc_packet_doc_link` для A, B, C как в ожидаемом состоянии.
Негатив: обработка сообщения только с СЧФ, у которой ФПУ-26 не наработан,
остаётся standalone (`supplement=false`), как в существующем тесте
`shouldReturnStandaloneSchf_whenProcessSfchWithoutPreparedPacket`.

## Прогресс и продолжение

- [x] Модель, changelog, DTO, бандл
- [x] Алгоритм сборки и запись
- [x] `test-026` и тесты
- [x] Передать результат на независимую проверку.

Реализовано в `rvk-diadoc`, ветка `f/schf-supplement`, коммит `b27af3a`;
подробности и команды — [result.md](result.md). Две поправки к постановке:
в плане перепутаны id сообщения C и entity СЧФ (фактически сообщение C =
`b17c632e-…`, СЧФ = `fe79c311-…`), и из `rvk_diadoc_entity_detail-26.sql`
пришлось убрать префикс схемы `diadoc.` — тестовая БД работает с
`currentSchema=public`.

Ближайший шаг: независимая проверка (`task-verify` по этому `task.md`).
Препятствия: нет
