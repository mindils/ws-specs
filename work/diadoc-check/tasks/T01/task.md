# T01 — Настройки Диадок: поля контрагента, умолчания, экраны, роль, сервис

Статус: done
План: [plan.md](../../plan.md)
Зависимости: нет
Сложность: medium — новая entity, поля в существующей, два экрана, роль и
сервис по готовым образцам; контракт сервиса задан планом
Сложность проверки: medium — IT на резолв и роль, два экрана в браузере
Актуальная проверка: [checks/001.md](checks/001.md)

## Коротко

Появляются настройки обработки пакетов Диадок: четыре флага по контрагенту
внутри существующих «Настроек подписания» (экран переименовывается в
«Настройки Диадок по контрагентам») и singleton «Настройки Диадок по
умолчанию», который действует для контрагентов без своей строки. Их
редактирует новая роль `diadoc-settings-admin`. Сервис
`DiadocProcessingSettingsService` — единственная точка чтения; его
контракт используют T02 и T04.

## Результат и контекст

Сейчас `DiadocSignSettings` (`app/src/main/java/ru/fgk/ws/app/diadoc/entity/
DiadocSignSettings.java`, таблица `diadoc_sign_settings`) хранит только
`contractor` и дочерние типы пакетов/документов; экраны —
`app/src/main/java/ru/fgk/ws/app/diadoc/view/settings/
DiadocSignSettingsListView.java` (`@ViewController(id =
"DiadocSignSettingsDocType.list")`, route `diadoc-sign-settings`) и
`DiadocSignSettingsDetailView.java` (`DiadocSignSettings.detail`), XML рядом в
`app/src/main/resources/ru/fgk/ws/app/diadoc/view/settings/`; пункт меню
`menu.xml:284-286` в `<menu id="diadoc">`; ни одна роль их не выдаёт
(только `system-full-access`). Глобальных настроек Диадок нет; образец
singleton — `legal/caseone/entity/CaseOneSettings.java`,
`legal/caseone/service/CaseOneSettingsService.java`,
`legal/caseone/view/settings/CaseOneSettingsView.java` (`StandardView`,
`InstanceContainer`, загрузка через сервис), роль
`legal/security/LegalCaseOneAdminRole.java`.

Нужно (решения — раздел «Общие решения» плана, контракт менять нельзя):

- `DiadocSignSettings`: поля `showRelatedDocuments`,
  `checkDuplicateTorDocument`, `checkCrossPacketReference`,
  `checkMissingDocument` — `Boolean`, `@NotNull`, колонки
  `show_related_documents`, `check_duplicate_tor_document`,
  `check_cross_packet_reference`, `check_missing_document`.
- Новая entity `DiadocSettings` (`ru.fgk.ws.app.diadoc.entity`, таблица
  `diadoc_settings`, `Long id` IDENTITY, те же четыре поля `@NotNull`),
  «в таблице всегда ровно одна строка».
- `DiadocProcessingSettingsService` (`ru.fgk.ws.app.diadoc.service`):
  `record DiadocProcessingSettings(boolean showRelatedDocuments, boolean
  checkDuplicateTorDocument, boolean checkCrossPacketReference, boolean
  checkMissingDocument)`; `DiadocSettings getDefaults()` (создаёт строку с
  начальными значениями `true,false,false,false`, если её нет);
  `DiadocProcessingSettings resolve(@Nullable DiadocContractor)` — строка
  контрагента (`DiadocSignSettings` по `contractor`), иначе умолчания;
  `DiadocProcessingSettings resolveForPacket(DiadocPacket)` — по
  `packet.getContractor()` (может быть `null`). Без кеша, только
  constructor injection.
- Роль `DiadocSettingsAdminRole` (`ru.fgk.ws.app.security.diadoc`, код
  `diadoc-settings-admin`, scope UI) и specific-контекст
  `DiadocSettingsEditEnabled` (`ru.fgk.ws.app.security.diadoc.specific`,
  `NAME = "diadocSettingsEdit.enabled"`, образец
  `DiadocSigningEditEnabled`). Роль даёт: `EntityPolicy ALL` и
  `EntityAttributePolicy MODIFY *` на `DiadocSettings`,
  `DiadocSignSettings`, `DiadocSignSettingsPacketType`,
  `DiadocSignSettingsDocType`; READ на `nsi_DiadocContractor` и
  `DiadocDocumentType`; `@ViewPolicy` на `DiadocSignSettingsDocType.list`,
  `DiadocSignSettings.detail`, `DiadocSignSettingsPacketType.detail`,
  `DiadocSignSettingsDocType.detail` (точные id взять из контроллеров) и
  новый `diadoc_DiadocSettings.view`; `@MenuPolicy` на оба пункта;
  `@SpecificPolicy(resources = DiadocSettingsEditEnabled.NAME)`.
- Экраны: в `diadoc-sign-settings-detail-view.xml` блок «Обработка
  пакетов» с четырьмя `checkbox` (при создании новой строки поля
  инициализируются из `getDefaults()` в `InitEntityEvent`); в списке —
  четыре колонки-флажка; заголовки списка/меню — «Настройки Диадок по
  контрагентам». Новый `DiadocSettingsView` (`StandardView`, id
  `diadoc_DiadocSettings.view`, route `diadoc/settings`, пакет
  `ru.fgk.ws.app.diadoc.view.settings`) с теми же четырьмя чекбоксами и
  кнопкой «Сохранить»; пункт меню «Настройки Диадок по умолчанию» рядом с
  существующим. Удалить лишний символ `s` после `<h4 text="Тип пакета">` в
  detail XML.
- Подписи: `showRelatedDocuments` — «Показывать связанные документы»,
  `checkDuplicateTorDocument` — «Нарушение: документ выложен более одного
  раза (задвоение по TorID)», `checkCrossPacketReference` — «Нарушение:
  документ перечня вложен в другое сообщение», `checkMissingDocument` —
  «Нарушение: документ перечня не найден». Ключи entity в блоке
  `ru.fgk.ws.app.diadoc.entity/*`, view — `ru.fgk.ws.app.diadoc.view.settings/*`,
  роль — рядом с другими ролями `security.diadoc`.

## Область и изоляция

Меняются: `diadoc/entity/DiadocSignSettings.java`, новый
`diadoc/entity/DiadocSettings.java`, новый
`diadoc/service/DiadocProcessingSettingsService.java` (+ record),
`diadoc/view/settings/*` (XML и Java, включая новый view),
`security/diadoc/DiadocSettingsAdminRole.java`,
`security/diadoc/specific/DiadocSettingsEditEnabled.java`,
`liquibase/changelog/01-tbl/tbl-diadoc_sign_settings.xml` (обновить
`createTable` + отдельные `addColumn` с preConditions и `defaultValue`),
новый `01-tbl/tbl-diadoc_settings.xml`, `menu.xml`, блоки ключей в
`messages_ru.properties`, новые тесты `app/src/test/java/ru/fgk/ws/app/it/
DiadocProcessingSettingsIT.java` и `DiadocSettingsAdminRoleIT.java`. Не
менять: `DiadocPacketDetailView`, `PacketParserService`, sync-код (области
T02/T03/T04). Общие ресурсы — схема `main_f_diadoc_check`
(`localhost:5432`), порт 8082, Gradle daemon; код параллельно с T03/T05,
прогон `:app:test` — не одновременно с T03 (порядок по плану).

## Реализация

1. Entity и changelog — скилы `jmix-create-entity`,
   `jmix-create-liquibase-changelog`; `@DdlGeneration` для FK не нужен
   (новых ссылок нет). Для существующих строк `diadoc_sign_settings`
   `addColumn` с `defaultValueBoolean` (`true` для показа, `false` для
   проверок) и `NOT NULL`.
2. Сервис — `jmix-create-service`, образец `CaseOneSettingsService`
   (`@Transactional` на создание умолчаний, `saveWithoutReload` не нужен,
   строка возвращается).
3. Роль — `jmix-create-resource-role`; ролям с CREATE нужны MODIFY на
   редактируемых атрибутах. Проверить, что `WsUserRole`/`ws-user` экраны
   настроек не получает.
4. Экраны — `jmix-create-detail-view`/`jmix-create-list-view`,
   `jmix-add-i18n-keys`; `jmix-verify-api-symbol` для незнакомых
   символов. После правки XML — инспекция дескрипторов
   (`jmix-ide-static-analysis`).
5. Тесты — `jmix-create-test`: IT на `BaseIT` (без транзакции, уборка в
   `@AfterEach`): резолв без строки контрагента → умолчания, со строкой →
   значения строки, `resolveForPacket` с `contractor=null` → умолчания;
   роль — по образцу `NsiClaimTermEditRoleIT`: пользователь с
   `diadoc-settings-admin` сохраняет `DiadocSettings`, с `ws-user` получает
   `AccessDeniedException`.

## Критерии приёмки

- C1: После миграций существуют `diadoc_settings` и четыре новые колонки
  `diadoc_sign_settings` с умолчаниями; повторный прогон миграций
  идемпотентен.
- C2: `resolve(null)` и `resolve(контрагент без строки)` возвращают
  `(true,false,false,false)` при нетронутых умолчаниях; после правки
  умолчаний — новые значения; строка контрагента перекрывает умолчания.
- C3: Пользователь с ролью `diadoc-settings-admin` видит оба пункта меню,
  открывает и сохраняет оба экрана; `ws-user` их не видит и не может
  сохранить `DiadocSettings`.
- C4: Существующие функции подписания (`DiadocSignSettingsService.
  getSignSettingsDocTypeList`) не меняются: `DiadocPacketFlowServiceTest`,
  `DiadocDocumentFlowServiceTest` зелёные.
- C5: Ни одного сырого `msg://` на экранах, лишний символ `s` в detail
  XML убран.

## Самопроверка исполнителя

`./gradlew :app:compileJava`, `./gradlew spotlessApply`,
`./gradlew :app:test --tests "ru.fgk.ws.app.it.DiadocProcessingSettingsIT"
--tests "ru.fgk.ws.app.it.DiadocSettingsAdminRoleIT"`, инспекция XML
дескрипторов. Один smoke: `bootRun` (порт 8082), вход `user`/`user`,
назначить `diadoc-settings-admin`, открыть оба экрана. Полный `:app:test`
и браузерный проход остальных экранов не нужны.

## Независимая проверка

`./gradlew :app:compileJava`, `spotlessCheckAll`, `./gradlew :app:test
--tests "ru.fgk.ws.app.it.DiadocProcessingSettingsIT" --tests
"ru.fgk.ws.app.it.DiadocSettingsAdminRoleIT" --tests
"ru.fgk.ws.app.diadoc.service.*"`. SQL-сверка колонок и умолчаний в
схеме `main_f_diadoc_check`. Браузер (`playwright-cli`, `bootRun` 8082,
`/local-login`): под `diadoc-settings-admin` — создать строку контрагента
CDI (ИНН 7708503727) с включёнными проверками, сохранить, переоткрыть;
изменить умолчания; под пользователем только с `ws-user` — пунктов меню
нет, прямой переход на `diadoc/settings` закрыт. Негатив: сохранение
второй строки умолчаний невозможно (view единственный, создаёт сервис).
Ресурсы — по разделу «Область и изоляция».

## Прогресс и продолжение

- [x] Entity, changelog, messages
- [x] Сервис резолва и умолчаний
- [x] Роль и specific-контекст
- [x] Экраны и меню
- [x] Тесты
- [x] Передать результат на независимую проверку.
- [x] Независимая проверка: все критерии подтверждены ([checks/001.md](checks/001.md)).

Ближайший шаг: таск завершён, переход к зависимым таскам (T02, T04) после завершения T03.
Препятствия: нет
