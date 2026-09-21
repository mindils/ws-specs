# Диадок: настройки по контрагентам, нарушения из rvk-diadoc, СЧФ-дополнения

Состояние: active
Дата согласования: 2026-09-21

## Цель и границы

Пакеты Диадок обрабатываются в двух проектах: `rvk-diadoc` нарабатывает
документы, связи и нарушения пакета, `rvk-ws` перекачивает результат в
локальное зеркало `diadoc_packet*`, нарабатывает бизнес-сущности
(`process`) и показывает пакеты пользователям. Работа закрывает пять
требований пользователя:

1. Галочка «Показать связанные документы» на карточке пакета
   (`DiadocPacketDetailView.showRelatedCheckbox`) — сейчас локальное
   состояние экрана. Нужна настройка по контрагенту, которую ставит админ;
   у остальных пользователей галочка скрыта, показ определяется настройкой.
2. Три нарушения, которые уже нарабатывает `rvk-diadoc`
   (`PacketViolationType`: `DUPLICATE_TOR_DOCUMENT` — задвоение по TorID,
   `CROSS_PACKET_REFERENCE` — документ перечня лежит в другом сообщении,
   `MISSING_DOCUMENT` — документ перечня не найден), должны включаться
   настройками по контрагенту.
3. `process` должен учитывать эти настройки и флаги из зеркала
   (`DiadocPacket.violations`, jsonb, уже перекачивается, но не читается),
   писать нарушения по-русски в тот же результат контроля, что и остальные
   проверки, и дополнительно проверять связанные документы: в подписании →
   не ок; отклонённые/подписанные в системе → нарушение.
4. Флаг «норм/не норм» при `process` — это `pack_checked_code`
   (`PackCheckedCodeEnum`: 0 Норма, 1 Нарушение, 2 Предупреждение,
   3 Предупреждение ЭЦП) в таблице типа пакета; `ok` ответа не хранится и
   равен `code == NORM`. По нему нужны фильтры на «Пакеты по ремонту
   деталей» (`pt-repair-packets`, колонка «Контроль») и «Пакеты ВУ-23»
   (`dr-diadoc-oper-repair-packet-vu23s`, колонка «Результат проверки»).
   Найденные дефекты хранения/показа входят в работу: ТР-1 не подключён к
   чтению результата контроля; `dr_diadoc_oper_repair_packet.
   pack_checked_text` — `varchar(255)`, а ВУ-23 пишет туда несколько
   строк; кнопка «Текст ошибки» на списке ВУ-23 всегда неактивна
   (сравнение `Integer` с enum); `DocumentDataSource` в rvk-ws не знает
   значение `DOCID_ARR`, которое пишет источник.
5. Счёт-фактура (СЧФ) привязывается по ИдПУД к ФПУ-26, но попадает только
   в пакет-владелец ФПУ-26; в пакет-корректировку, где тот же ФПУ-26
   пришёл из `docid_arr`, не попадает, а при двух пакетах-владельцах
   обработка падает. СЧФ должна привязываться ко всем пакетам с её ФПУ-26
   как «документ-дополнение», отличимый в link-таблице и показываемый
   всегда.

**Не входит:** перенос других настроек в новую модель, изменение
алгоритма самих нарушений в `rvk-diadoc`, кеширование настроек,
учёт СЧФ-дополнений в парсерах (`LocalPacketSnapshot.getActualDocs`),
известный пробел `PacketViolationService` (ложный `MISSING_DOCUMENT`, если
единственный экземпляр объявленного TorID лежит в поглощённом сообщении).

## Материалы

| Источник | Содержание |
|---|---|
| Постановка пользователя 2026-09-21 (чат) | Пять требований выше; ответы на вопросы — раздел «Общие решения» |
| `rvk-diadoc/src/main/java/ru/fgk/rvk/diadoc/processing/service/PacketViolationService.java`, `.../dto/PacketViolation.java`, `.../dto/PacketViolationType.java` | Наработка нарушений: JSON `{violationType, torDocumentId, entityId, relatedMessageIds, message}` в `diadoc_packet.violations`, пересчёт целиком на шаге 6 `DocumentProcessingService.processDocument` |
| `rvk-diadoc/.../processing/service/PacketAssemblyService.java`, `DiadocPacketWriter.java`, `DocumentProcessingService.java`, `content/SchfContentExtractor.java` | Сборка пакета, запись линков только для канонического messageId, tombstone поглощённых сообщений, привязка СЧФ по ИдПУД (`parent_entity_id`) |
| `rvk-diadoc/src/test/resources/ru/fgk/rvk/diadoc/liquibase/sql/rvk_diadoc_entity_detail-26.sql` (коммит `1cb6ae6`) | Данные организации CDI (7708503727/770845098): сообщение A `14bf2bcd-9a45-483d-a0b5-f76f001d9138` — PACKET ТР-2 (entity `7417ec4a-cda2-4c66-99b1-a7c150e77f1a`, TOR_PacketId `D0075461062`, docid_arr из 6 TorID) + ФПУ-26 `a2532529-6c3c-41d8-8ea6-7aa84202d42e` (TorID `D0075456469`) + РДВ, ВУ-22, МХ-3, ВУ-36, ГВЦ; сообщение B `be5aa61d-e5a0-4448-b5cb-9417a6d54c05` — PACKET-корректировка (entity `2e64406f-a615-49f1-8060-846667c6ad70`, oldPackId `D0075461062`, docid_arr из 8 TorID: 5 из A, включая ФПУ-26, + 3 своих); сообщение C `fe79c311-9419-4cad-8473-bad0e713d818` — СЧФ `b17c632e-9013-4db3-8c3b-868a9826b062` (TorID `D0075648756`, ИдПУД=`D0075456469`, packet_id как у B) + квитанция 8007. В тестовый changelog (`test-026`) файл не подключён |
| `app/src/main/java/ru/fgk/ws/app/diadoc/service/PacketParserService.java`, `DiadocPacketCheckResultService.java`, `dr/entity/PackCheckedHolder.java`, `PackCheckedStatusAccumulator.java`, `PackCheckResult.java` | Диспетчер `process`, чтение результата контроля по типу пакета, правила накопления отметок |
| `app/src/main/java/ru/fgk/ws/app/diadoc/view/diadocpacket/DiadocPacketDetailView.java` (строки 236-250, 589-607, 1171-1190) и XML | Галочка, фильтр `relatedDocument`, иконка `relatedIcon` |
| `app/src/main/java/ru/fgk/ws/app/diadoc/entity/DiadocSignSettings*.java`, `.../diadoc/view/settings/*`, `menu.xml:284-286`, `.../legal/caseone/service/CaseOneSettingsService.java`, `.../legal/security/LegalCaseOneAdminRole.java` | Существующие настройки по контрагенту (роль не выдана, только full-access), образец singleton-настроек и admin-роли |
| `app/src/main/java/ru/fgk/ws/app/diadoc/view/signing/DiadocSigningListView.java:143-147`, `.../security/diadoc/DiadocSigningEditRole.java` | Образец скрытия элемента по `@SpecificPolicy` через `AccessManager` |
| `app/src/test/java/ru/fgk/ws/app/it/PacketReplayIT.java`, `PacketReplayFixtures.java`, `app/src/test/resources/diadoc/replay*/` | Replay-фикстуры (CSV → `diadoc_packet*`, `dr_*`, `pt_*`), чтение отметок из `dr_wag_vrk_arch` |
| `app/src/main/resources/ru/fgk/ws/app/pt/view/ptrepairpacket/pt-repair-packet-list-view.xml`, `.../dr/view/drdiadocoperrepairpacket/dr-diadoc-oper-repair-packet-vu23-list-view.xml` и контроллеры | Списки с колонками контроля; образец multiSelect-фильтра `diadocStatusFilter` |

## Общие решения

| Решение | Основание |
|---|---|
| Настройки по контрагенту — четыре поля `Boolean NOT NULL` в `DiadocSignSettings` (`diadoc_sign_settings`): `showRelatedDocuments` (`show_related_documents`), `checkDuplicateTorDocument` (`check_duplicate_tor_document`), `checkCrossPacketReference` (`check_cross_packet_reference`), `checkMissingDocument` (`check_missing_document`). Экран списка и меню переименовываются в «Настройки Диадок по контрагентам»; id view не меняются | Ответ пользователя 2026-09-21 |
| Умолчания — singleton `DiadocSettings` (`diadoc_settings`, `Long id`, те же четыре поля; сервис создаёт строку при первом чтении по образцу `CaseOneSettingsService`). Применяются, когда у контрагента нет строки или контрагент пакета не определён. Начальные значения: `showRelatedDocuments=true`, три проверки `false`. Новая строка контрагента инициализируется из умолчаний | Ответ пользователя |
| Контракт чтения: `ru.fgk.ws.app.diadoc.service.DiadocProcessingSettingsService` с `record DiadocProcessingSettings(boolean showRelatedDocuments, boolean checkDuplicateTorDocument, boolean checkCrossPacketReference, boolean checkMissingDocument)` и методами `resolve(@Nullable DiadocContractor)`, `resolveForPacket(DiadocPacket)` (по `packet.getContractor()`), `getDefaults()`. Без кеша: строк мало, запрос дешёвый, правка в UI подхватывается сразу | Техническое; образец `CaseOneSettingsService` |
| Одна настройка `showRelatedDocuments` управляет и показом связанных на карточке, и проверкой связанных при `process` | Ответ пользователя |
| Админ — роль `diadoc-settings-admin` (`app/src/main/java/ru/fgk/ws/app/security/diadoc/DiadocSettingsAdminRole.java`, scope UI): `EntityPolicy ALL` + атрибуты MODIFY на `DiadocSettings`, `DiadocSignSettings`, `DiadocSignSettingsPacketType`, `DiadocSignSettingsDocType`; READ на `DiadocContractor`, `DiadocDocumentType`; view/menu policies всех экранов настроек Диадок; `@SpecificPolicy(resources = DiadocSettingsEditEnabled.NAME)` где `NAME = "diadocSettingsEdit.enabled"` (`.../security/diadoc/specific/DiadocSettingsEditEnabled`). Галочка на карточке пакета видна только при этой policy; `system-full-access` покрывает `*` | Ответ пользователя; образец `DiadocSigningEditRole` |
| Нарушения из зеркала пишутся кодом `VIOLATION` в результат контроля того же типа пакета, что и остальные проверки (`PackCheckedHolder`), после парсера и до чтения результата в `PacketParserService.dispatchAndResolve`. Тексты — из `messages_ru.properties`, ключи `ru.fgk.ws.app.diadoc.service/violation.*` (см. T02); `message` источника — запасной вариант, неизвестный `violationType` пропускается с WARN | Ответ пользователя; правило i18n проекта |
| Проверка связанных документов выполняется при `showRelatedDocuments=true` для линков пакета с `relatedDocument=true` и `supplementDocument!=true`: (а) исходный пакет `originalMessageId` в незавершённом подписании (`DiadocDocumentFlowService.checkCanApprove(originalMessageId) == PROCESS_IN_PROGRESS`, т.е. `PacketFlow` в `TO_SIGN, PENDING_SIGN, PENDING_SIGN_REJECT, PENDING_REJECT, TO_REJECT`) либо `PacketDocumentFlow` по `entityId` в нефинальном статусе → `VIOLATION` «документ в процессе подписания»; (б) иначе `signature_status='8015'` → «В системе есть отклонённые документы: …»; `'8002'` → «В системе есть подписанные документы: …». СЧФ-дополнения из проверки исключены | Ответ пользователя 2026-09-21 (два ответа) |
| СЧФ-дополнение: в `diadoc_packet_doc_link` обоих проектов новая колонка `supplement_document BOOLEAN` (rvk-diadoc — `defaultValueBoolean="false"`), `related_document` и `main_document` не меняют смысл. Контракт бандла `getPacketForSync`: `links[].supplementDocument` (Boolean); `DocumentItemDto` источника — `is_supplement`. На карточке пакета фильтр скрывает только `related && !supplement`; дополнение помечается иконкой `vaadin:paperclip` с подсказкой «Дополнение к ФПУ-26» | Ответ пользователя |
| Алгоритм привязки в `rvk-diadoc` (T05): любой ФПУ-26 сборки (свой или из `docid_arr`) подтягивает СЧФ-детей по `parentEntityId`; при обработке СЧФ канонический пакет — владелец ФПУ-26, остальные живые пакеты, линкующие ФПУ-26 и ещё не линкующие СЧФ, дообрабатываются через `relatedMessageIdsToProcess`; исключение «ambiguous FPU_26 links» убирается; сообщение СЧФ поглощается (tombstone) как сейчас | Техническое (разбор архитектора), подробности в T05 |
| Фильтр по результату контроля на обоих списках — `jpqlFilter` с `multiSelectComboBox` по `packCheckedCode` со значениями enum и «Не проверялся» (`is null`), образец `diadocStatusFilter` | Техническое |
| `pack_checked_text` в `dr_diadoc_oper_repair_packet` расширяется до `CLOB` (`createTable` + `modifyDataType` с preConditions), entity — как у `ImportedPacketArch.packCheckedText` | Правило проекта для смены типа |
| `rvk-diadoc` правится прямо в `/home/mindils/data/dev/fgk/rvk-diadoc` (ветка на усмотрение исполнителя, коммит — по правилам того репозитория) | Ответ пользователя |

## Критерии всей работы

- Экран «Настройки Диадок по контрагентам» и экран «Настройки Диадок по
  умолчанию» доступны роли `diadoc-settings-admin` и `system-full-access`,
  недоступны `ws-user`; поля сохраняются; резолв настроек для контрагента
  без строки даёт умолчания.
- На карточке пакета галочка «Показать связанные документы» видна только
  админу, для остальных состав документов определяется настройкой
  контрагента; СЧФ-дополнение показывается всегда с иконкой.
- `process` пакета контрагента с включёнными проверками пишет в результат
  контроля русские тексты нарушений из зеркала и проверки связанных
  документов; `ok=false`; при выключенных проверках поведение прежнее.
  ТР-1 получает результат контроля; ВУ-23 с несколькими ошибками
  сохраняется полностью.
- На списках `pt-repair-packets` и `dr-diadoc-oper-repair-packet-vu23s`
  работает фильтр по результату контроля; кнопка «Текст ошибки» на ВУ-23
  активна при нарушении.
- В `rvk-diadoc` на данных -26 при любом порядке обработки A/B/C оба
  пакета A и B содержат СЧФ-дополнение (`supplement_document=true`), C
  поглощён; бандл несёт `supplementDocument`; зеркало rvk-ws принимает его.
- Гейты: rvk-ws — `./gradlew :app:compileJava`, `spotlessCheckAll`,
  `:app:test` с `0 failing`, render-проход изменённых экранов;
  rvk-diadoc — `./gradlew test` с `0 failing`, `spotlessApply`.

## Таски

Порядок строк — порядок выполнения.

| Таск | Результат | Зависит от |
|---|---|---|
| [T01](tasks/T01/task.md) | Настройки Диадок: поля контрагента, singleton умолчаний, экраны, роль, сервис резолва | — |
| [T03](tasks/T03/task.md) | Зеркало rvk-ws: колонка `supplement_document`, sync, DTO, `DocumentDataSource.DOCID_ARR` | — |
| [T05](tasks/T05/task.md) | rvk-diadoc: СЧФ-дополнение во всех пакетах с ФПУ-26, колонка и бандл, тесты на -26 | — |
| [T02](tasks/T02/task.md) | Нарушения при `process`: зеркало + связанные документы по настройкам, запись в результат контроля, фикс ТР-1 и `pack_checked_text` | T01, T03 |
| [T04](tasks/T04/task.md) | UI: галочка по роли и настройке, дополнение на карточке, фильтры по контролю, фикс кнопки ВУ-23 | T01, T03 |
| [T06](tasks/T06/task.md) | Сквозная проверка двух приложений на данных -26, полный регресс | T02, T04, T05 |

## Параллельность и тестирование

| Таск | Область | Общие ресурсы | Параллельно с | Проверка |
|---|---|---|---|---|
| T01 | `diadoc/entity/{DiadocSettings,DiadocSignSettings}.java`, `diadoc/service/DiadocProcessingSettingsService.java`, `diadoc/view/settings/*`, `security/diadoc/DiadocSettingsAdminRole.java`, `security/diadoc/specific/DiadocSettingsEditEnabled.java`, `liquibase/01-tbl/tbl-diadoc_settings.xml`, `tbl-diadoc_sign_settings.xml`, `menu.xml`, блоки `diadoc.entity`, `diadoc.view.settings`, `security.diadoc` в `messages_ru.properties`, новые тесты | БД `main_f_diadoc_check`, порт 8082, Gradle daemon | T03, T05 | тесты после T03 при одновременном прогоне |
| T03 | `diadoc/entity/{DiadocPacketDocLink,DocumentDataSource}.java`, `diadoc/service/{SyncPacketBundleDto,SyncPacketUpsertRepository}.java`, `diadoc/dto/DocumentItemDto.java`, `dto/rest/DocumentItemRestDto.java`, `mapper/PacketDocumentMapper.java`, `liquibase/01-tbl/tbl-diadoc_packet_doc_link.xml`, ключ `DiadocPacketDocLink.supplementDocument`, тесты sync | те же | T01, T05 | первым в очереди прогонов |
| T05 | репозиторий `rvk-diadoc` целиком | БД `localhost:5436`, порт 8081, свой Gradle daemon | T01, T03 | независимо |
| T02 | `diadoc/service/{PacketParserService,DiadocPacketCheckResultService}.java`, новый `DiadocPacketViolationCheckService.java`, `dr/entity/DrDiadocOperRepairPacket.java` (тип поля), `liquibase/01-tbl/tbl-dr_diadoc_oper_repair_paket.xml`, ключи `diadoc.service/violation.*`, новый IT | те же, что T01 | T04 | после T04 или до — по очереди |
| T04 | `diadoc/view/diadocpacket/*`, `pt/view/ptrepairpacket/*`, `dr/view/drdiadocoperrepairpacket/DrDiadocOperRepairPacketVu23ListView.java` + XML, ключи этих view, UI-тесты | те же + браузер | T02 | последовательно с T02 |
| T06 | фикстуры/тесты, `result.md`; код — только исправления найденного | все: обе БД, порты 8081 и 8082, браузер | — | последним |

Изоляции внутри rvk-ws нет: одна схема `main_f_diadoc_check` в
`docker-rvk-db-1` (`localhost:5432`, `root`/`root`), один порт 8082
(`application-local.properties` worktree), один Gradle daemon. Код пишется
параллельно; `:app:test` и `bootRun` — по одному, в порядке T03, T01, T02,
T04, T06. Liquibase обеих задач T01/T03 накатывается на одну схему — это
нормально, changeSet'ы с preConditions идемпотентны. `rvk-diadoc` изолирован
своей БД (`envs/dev/docker-compose.yml`, `localhost:5436`) и портом 8081.

## Как выполнять

Волна 1 — T01, T03, T05 в трёх сессиях (`task-execute`). Волна 2 — T02 и
T04 после `done` у T01 и T03. Волна 3 — T06 после `done` у T02, T04, T05.
Затем `task-close`.

Окружение rvk-ws: `docker info`, `(cd docker && docker compose ps)` — все
сервисы уже подняты; `app/src/test/resources/application-test-local.properties`
указывает на схему worktree; `rvkdiadoc.baseUrl=http://localhost:8081/`
(dev/test-local) — для тестов на фикстурах rvk-diadoc не нужен, для
сквозной проверки его поднимает T06. Вход в браузер: `/local-login`,
`user`/`user`, роли назначать через администрирование.

Окружение rvk-diadoc: `(cd envs/dev && docker compose ps)` — контейнер
`db-rvk-diadoc` (5436) поднят; `src/test/resources/application-test-local.properties`
есть; `./gradlew test --tests "<класс>"`; приложение —
`./gradlew bootRun` (профиль `dev`, `application-dev.properties` локальный,
порт 8081).

Файлы `specs/` — отдельный git-репозиторий:
`git -C specs add -A && git -C specs commit -m "spec(diadoc-check): …"`.

## Закрытие

Работа открыта.
