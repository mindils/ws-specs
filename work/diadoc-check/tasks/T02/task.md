# T02 — Нарушения при process: флаги зеркала и связанные документы по настройкам

Статус: done
План: [plan.md](../../plan.md)
Зависимости: T01, T03
Сложность: hard — новый сервис проверки поверх девяти типов пакетов с
разными таблицами результата, состояния подписания, фикс типов данных
Сложность проверки: medium — IT на replay-фикстурах с прямой SQL-подготовкой
состояния, регрессия `PacketReplayIT`
Актуальная проверка: [checks/C01.md](checks/C01.md)

## Коротко

`process` начинает учитывать нарушения, наработанные rvk-diadoc и
перекачанные в `diadoc_packet.violations`, и проверять связанные документы
пакета — по настройкам контрагента из T01. Результат пишется по-русски в
тот же результат контроля, что и остальные проверки, поэтому `ok` ответа и
колонки «Контроль»/«Результат проверки» отражают новые нарушения. Попутно
закрываются дефекты: ТР-1 не читался, `pack_checked_text` ВУ-23 ограничен
255 символами.

## Результат и контекст

Диспетчер — `app/src/main/java/ru/fgk/ws/app/diadoc/service/
PacketParserService.java`: `dispatchAndResolve` (114-145) вызывает парсер по
типу (`dispatch`, 147-167), затем `DiadocPacketCheckResultService.
findCheckResult(snapshot.packet())` и возвращает `ProcessPacketResult.ok`
только при `NORM`. `DiadocPacketCheckResultService` (тот же пакет) знает
таблицу результата по типу: `PARTS_REPAIR` → `PtRepairPacket`
(`packCheckedCode`, `errors`, `errorsWarning`, CLOB); `TR2` →
`DiadocWagOperRepairContract` (`fullPackCheckedCode/Text` — вычисляемые из
`packCheckedCode/Text` + связи); `DEPO`, `CAPITAL` →
`DiadocWagPlanRepairContract`; `REMOVED_PARTS/VU23/RECLAMATION/
MAINTAINABILITY/PARTS` → `DrDiadocOperRepairPacket` (`pack_checked_text
varchar(255)`); метод `findOperRepairTr1Result` для `TR1` есть, но в
`switch` не подключён — дефект. Отметки пишут через
`dr/entity/PackCheckedHolder.setPackCheckedStatus` (реализуют
`DrDiadocOperRepairPacket`, `ImportedPacketArch`, контракты через
`ImportedWagRepairContract`) с правилами `PackCheckedStatusAccumulator`
(VIOLATION sticky, дедуп текста, разделитель `\r\n`); для ТР-2/ДЕП/КАП
валидаторы отмечают и контракт, и `ImportedPacketArch` (`dr_wag_vrk_arch`,
`xml_hash` = messageId), см. `PackCheckedHolder.apply(...)`.
`PtRepairPacket` держателем не является: `RemDetParserService.
applyValidationResult` (347-380) пишет `errors` через `String.join("\n")`.
Все парсеры сбрасывают отметку в начале разбора, повторный process не
накапливает старое.

Зеркало: `DiadocPacket.violations` (`JsonNode`, массив `{violationType,
torDocumentId, entityId, relatedMessageIds, message}`; типы
`DUPLICATE_TOR_DOCUMENT`, `CROSS_PACKET_REFERENCE`, `MISSING_DOCUMENT`),
`DiadocPacket.contractor`; линки `DiadocPacketDocLink` (`relatedDocument`,
`supplementDocument` из T03, `originalMessageId`, `document` →
`DiadocPacketDoc.signatureStatus` `'8002'` подписан / `'8015'` отклонён,
`documentNumber`, `filename`, `documentType`). `LocalPacketSnapshot`
линков не содержит — их грузит новый сервис по `snapshot.packet().getId()`
(с учётом подмены на корректировку в `DiadocLocalPacketService.load`).
Подписание в rvk-ws: `DiadocDocumentFlowService.checkCanApprove(messageId)`
возвращает `PROCESS_IN_PROGRESS` для `PacketFlow` в `TO_SIGN, PENDING_SIGN,
PENDING_SIGN_REJECT, PENDING_REJECT, TO_REJECT`; `PacketDocumentFlow`
(`entityId`, `messageId`, `originMessageId`, `status`
`PacketDocumentFlowStatus`) — статусы документа, нефинальные определить по
enum и его javadoc (`NEW`, `PENDING_SIGN`, `PENDING_SIGN_REJECT`,
`SENT_FOR_SIGNING`).

Требуемое поведение (план, «Общие решения»):

1. Настройки — `DiadocProcessingSettingsService.resolveForPacket(packet)`
   (T01).
2. Нарушения зеркала: для каждого элемента `violations` при включённом
   соответствующем флаге — `PackCheckResult.violation(text)`; текст из
   `messages_ru.properties`, ключи блока `ru.fgk.ws.app.diadoc.service/`:
   `violation.duplicateTorDocument=Документ TorID %s выложен более одного раза (также в пакетах: %s)`,
   `violation.crossPacketReference=Документ TorID %s перечислен в пакете, но вложен в другое сообщение: %s`,
   `violation.missingDocument=Документ TorID %s перечислен в пакете, но не найден ни в одном действующем пакете`;
   `relatedMessageIds` — через запятую; неизвестный `violationType` —
   WARN в лог и пропуск; при пустом `message`/данных — текст источника как
   запасной вариант.
3. Связанные документы при `showRelatedDocuments=true`: для линков
   `relatedDocument=true` и `supplementDocument!=true` (а) исходный пакет
   `originalMessageId` в незавершённом подписании либо `PacketDocumentFlow`
   по `entityId` в нефинальном статусе → `violation.relatedInSigning=Связанный документ %s находится в процессе подписания (пакет %s)`;
   (б) иначе `signatureStatus='8015'` → `violation.relatedRejected=В системе есть отклонённые документы: %s`;
   `'8002'` → `violation.relatedSigned=В системе есть подписанные документы: %s`
   (в списке — «тип/номер (entityId)», по одному сообщению на группу).
4. Запись — новый метод `DiadocPacketCheckResultService.appendResults(
   DiadocPacket packet, List<PackCheckResult> results)`: для каждого типа
   та же сущность, что читается в `findCheckResult`; ТР-2/ДЕП/КАП — контракт
   и `ImportedPacketArch` по `xml_hash`; `PtRepairPacket` — `errors`
   дописывается (перевод строки, дедуп) и `packCheckedCode` по
   `PackCheckedStatusAccumulator.accumulateCode`; сохранение
   `saveWithoutReload`. Пустой список — без записи. Добавить `case TR1 ->
   findOperRepairTr1Result` и соответствующую ветку записи.
5. Хук — `PacketParserService.dispatchAndResolve` после успешного
   `dispatch` и до `findCheckResult`; исключение проверки не должно ронять
   process: логируется, отметка `VIOLATION` с текстом
   `violation.checkFailed=Проверка нарушений не выполнена: %s`.
6. `dr_diadoc_oper_repair_packet.pack_checked_text` → `CLOB`
   (`tbl-dr_diadoc_oper_repair_paket.xml`: тип в `createTable` +
   `modifyDataType` с preConditions), entity `DrDiadocOperRepairPacket.
   packCheckedText` — аннотации как у `ImportedPacketArch.packCheckedText`.

## Область и изоляция

Меняются: `diadoc/service/PacketParserService.java`,
`diadoc/service/DiadocPacketCheckResultService.java`, новый
`diadoc/service/DiadocPacketViolationCheckService.java`,
`dr/entity/DrDiadocOperRepairPacket.java` (только тип поля),
`liquibase/changelog/01-tbl/tbl-dr_diadoc_oper_repair_paket.xml`, блок
ключей `ru.fgk.ws.app.diadoc.service/violation.*` в `messages_ru.properties`,
новый IT `app/src/test/java/ru/fgk/ws/app/it/DiadocViolationCheckReplayIT.java`,
unit-тест сервиса в `app/src/test/java/ru/fgk/ws/app/diadoc/service/`.
Не менять: парсеры типов, валидаторы `dr/validation`, views (T04),
настройки (T01), sync (T03). Ресурсы — схема `main_f_diadoc_check`,
Gradle daemon; код параллельно с T04, прогоны тестов — по очереди с T04.

## Реализация

1. Сервис — `jmix-create-service` (constructor injection, `@Transactional`
   только на запись). Чтение флагов подписания через существующие
   `DiadocDocumentFlowService.checkCanApprove` и загрузку
   `PacketDocumentFlow` по `entityId` (`DataManager`, fetch plan `_base`).
2. Тексты — `jmix-add-i18n-keys`, `Messages.getMessage(...)`, форматирование
   `String.format`; тестам удобно сравнивать полные строки.
3. Тест на `BaseIntegrationTest` + `PacketReplayFixtures` (образец
   `PacketReplayIT`): ТР-2 пакет `f75bd11a-ec04-5be5-bcf0-3c2c99a86e17`.
   Подготовка через `JdbcTemplate`: `update main.diadoc_packet set violations
   = '[...]'::jsonb`, строка `diadoc_sign_settings` контрагента пакета с
   флагами (или умолчания через `DiadocProcessingSettingsService` — строка
   `DiadocSettings` создаётся в той же транзакции), для связанных — вставка
   `diadoc_packet_doc` + `diadoc_packet_doc_link` (`related_document=true`,
   `original_message_id` = другой UUID) и `diadoc_packet_flow` в
   `PENDING_SIGN` либо `signature_status='8015'/'8002'`. Проверка —
   `fixtures.loadChecks(messageId)`: код `VIOLATION`, `messages()` содержит
   ожидаемые русские строки; при выключенных флагах — как в `PacketReplayIT`
   (регресс). Отдельный кейс: линк с `supplement_document=true` и
   `signature_status='8002'` нарушения не даёт. Кейс Рем.Дет на
   `replay-rem-det` (`RemDetPacketReplayIT` как образец) — текст в `errors`.
4. Unit-тест `DiadocPacketViolationCheckService` на разбор JSON и
   фильтрацию по флагам (без контекста, моки `DataManager` не нужны, если
   разбор вынести в чистый метод).

## Критерии приёмки

- C1: ТР-2 пакет с `violations` трёх типов и всеми флагами → три русских
  сообщения в `pack_checked_text`, код `VIOLATION`, `ProcessPacketResult.
  ok=false` с текстом; с флагами `false` — прежний результат `PacketReplayIT`.
- C2: Связанный документ с `PacketFlow` исходного пакета в `PENDING_SIGN`
  → «в процессе подписания»; с `'8015'` → «отклонённые»; с `'8002'` →
  «подписанные»; дополнение (`supplement_document=true`) и линки без
  `related_document` нарушений не дают; при `showRelatedDocuments=false`
  проверка не выполняется.
- C3: Повторный process того же пакета не дублирует строки.
- C4: `TR1`: `findCheckResult` возвращает результат из
  `dr_diadoc_oper_repair_tr1` (unit/IT с записью через `DataManager`).
- C5: ВУ-23 с текстом > 255 символов сохраняется полностью (IT: три
  нарушения зеркала на пакет `vu23`).
- C6: `PacketReplayIT`, `RemDetPacketReplayIT`, `PacketParserServiceTest`,
  `Vu23PacketParserServiceTest` зелёные.

## Самопроверка исполнителя

`./gradlew :app:compileJava`, `spotlessApply`, `./gradlew :app:test --tests
"ru.fgk.ws.app.it.DiadocViolationCheckReplayIT" --tests
"ru.fgk.ws.app.it.PacketReplayIT" --tests
"ru.fgk.ws.app.diadoc.service.PacketParserServiceTest"`. Полный набор и
браузер не нужны.

## Независимая проверка

Те же тесты плюс `--tests "ru.fgk.ws.app.it.RemDetPacketReplayIT" --tests
"ru.fgk.ws.app.diadoc.service.*"`; SQL-сверка типа колонки
`pack_checked_text` (`text`). Негатив: битый JSON в `violations`
(например, объект вместо массива) — process не падает, в отметке текст
`violation.checkFailed`. Регресс: `GET /api/diadoc/processPacket?messageId=
<пакет без violations и без related>` через `bootRun` даёт прежний ответ.

## Прогресс и продолжение

- [x] Сервис проверки и тексты
- [x] Запись результата по типам, `TR1`
- [x] Хук в диспетчере
- [x] Расширение `pack_checked_text`
- [x] Независимая проверка пройдена: [C01](checks/C01.md)

Ближайший шаг: реализация UI-таска [T04](../T04/task.md)
Препятствия: нет
