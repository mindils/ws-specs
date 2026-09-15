# Контракты контейнерного раздела

План: [plan.md](plan.md). Это постановка, не описание реализованного кода.
Исполнитель T01 дописывает в матрицу фактические Java-имена, если они
отклоняются от указанных; бизнес-состав не меняется.

## Материалы

| Материал | Содержание | Таски |
|---|---|---|
| [img.png](input/img.png) | Старое меню ЕРИ: Акты, Гарантийные условия, Договоры, Освидетельствования, Прикрепленные файлы, Реестр, Ремонтные предприятия, Ремонты, Характеристики | T02, T03, T06 |
| [img_1.png](input/img_1.png) | Список ремонтов: поиск, «Добавить запись», колонки ИД, файл (PDF), номер контейнера, вид ремонта, пагинация | T07 |
| [img_2.png](input/img_2.png) | Реестр: поиск, «Добавить запись», номер, заводской номер, изготовитель, собственник | T03 |
| [img_3.png](input/img_3.png) | Карточка: вкладки Описание, Характеристики, Операции, Накладные, Ремонты, Освидетельствования, Акты, Файлы, История | T03 |
| [img_4.png](input/img_4.png) | Форма файла: ИД (авто), контейнер, вид файла, комментарий, загрузка | T03 |
| [img_5.png](input/img_5.png) | Форма освидетельствования: ИД, контейнер, вид, три даты | T04 |
| [img_6.png](input/img_6.png) | Lookup контейнера с поиском по номеру | T04, T07 |
| [instruction-erk.md](input/instruction-erk.md) | Сценарии операторов, поля ремонта и файла, скриншоты docx | T03, T07, T08 |
| [issue.md](input/issue.md) | Старый DDL всех таблиц | T01 |

Ссылки `/uploads/...` в issue.md недоступны. Скриншоты показывают часть широких
форм; полный состав полей — матрица ниже.

## Единые правила модели

- Пакет `ru.fgk.ws.app.container` с подпакетами `entity`, `listener`,
  `service`, `repository` (при необходимости), `view/<name>`, `security`;
  ресурсы `app/src/main/resources/ru/fgk/ws/app/container/view/<name>/`.
- Таблицы `cnt_<name>`, `@Entity(name = "cnt_<Entity>")`, view-id
  `cnt_<Entity>.list` / `cnt_<Entity>.detail`. Changelog-и
  `app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/01-tbl/tbl-cnt_<table>.xml`,
  author `cnt`, preConditions на каждый changeSet,
  `objectQuotingStrategy="QUOTE_ONLY_RESERVED_WORDS"`. Начальные данные —
  `04-data/cnt/*.csv` и `04-data/cnt_seed.xml`; настройка EntityLog —
  `04-data/cnt_entity_log.xml`.
- Каждая `cnt_*` entity: `@Id @GeneratedValue(strategy = IDENTITY) Long id`;
  `@Version Integer version`; `@CreatedBy/@CreatedDate/@LastModifiedBy/
  @LastModifiedDate` (`String`, `OffsetDateTime`); `@DeletedBy/@DeletedDate`
  (`deleted_by`, `deleted_date`); Lombok только `@Getter/@Setter` на классе;
  `@InstanceName`. Образцы: `nsi/entity/NsiWsRepairDepo.java` (аудит),
  `diadoc/entity/DiadocPacket.java` (soft delete),
  `da/entity/DaContractAgentCopiesDocument.java` (FileRef, `@DdlGeneration`).
- FK в БД не создаются: `@DdlGeneration(unmappedConstraints = {"FK_<TABLE>_<COLUMN>"})`;
  на каждую ссылку индекс `idx_<table>_<column>` и в `@Table(indexes)`, и в
  changelog. Уникальные индексы: `cnt_container(cont_num)`,
  `cnt_act_container(act_id, container_id)`.
- На каждой `@ManyToOne` ссылке на контейнер, справочник, договор, гарантию и
  вид акта — `@OnDeleteInverse(DeletePolicy.DENY)`: удаление записи, на которую
  ссылаются, отклоняется. **Проверено в T01: DENY учитывает soft delete, и
  сервисная проверка не нужна.** Основание — исходники Jmix 3.0.1:
  `io.jmix.data.impl.DeletePolicyProcessor#referenceExists` считает ссылающиеся
  записи обычным JPQL (`select count(e) from <Entity> e where e.<prop>.id = ?1`),
  а `io.jmix.eclipselink.impl.mapping.SoftDeleteAdditionalCriteriaProvider`
  добавляет каждому soft-deletable дескриптору критерий
  `this.<deletedDate> is null`. Поэтому мягко удалённый ребёнок в счёт не
  попадает и родителя не блокирует. Поведение закреплено тестом
  `ContainerDeletePolicyIT`: удаление отклоняется, пока ребёнок жив, и проходит
  после его мягкого удаления.
- Ссылки на существующее НСИ: `VOrgPassport` (`Long id`, подпись `shortname`),
  `VStation` (`Integer id`, подпись `getFillName()`), дорога — через
  `VStation.rw`. Их не менять и не копировать.
- Старые технические поля (`data_id`, `trans_id`, `lastrec`, `recdatebegin`,
  `recdateend`, `recdatenew`, `user_name`) не переносятся. Бизнес-даты
  сохраняются. Nullable-поля старого DDL остаются nullable в БД; обязательность
  задаётся только в view.
- Денежные значения — `BigDecimal` / `numeric(19,2)`; проценты и количества —
  `Integer`/`Long`; даты — `LocalDate`.
- Нормализация номера контейнера (trim + верхний регистр) выполняется
  listener-ом `EntitySavingEvent` для `Container` (skill
  `jmix-add-entity-event-listener`), чтобы действовать на любом пути сохранения.
  Уникальность обеспечивает индекс БД; view показывает понятное сообщение при
  нарушении.
- Копирование: `container/service/EntityCopySupport` копирует бизнес-атрибуты
  через `MetadataTools`, очищает id, version, аудит, soft delete, `FileRef` и
  коллекции; у контейнера дополнительно очищает номер. Действие «Копировать» в
  списках реестра, ремонтов, освидетельствований, договоров открывает detail с
  новой копией.

## Матрица модели

### Основные таблицы

| Таблица | Entity | Поля и связи |
|---|---|---|
| `cnt_container` | `Container` | `cont_num` varchar(255) NOT NULL unique; `manuf_num` varchar(255); `manufacturer` varchar(255); `owner_org_id` → `VOrgPassport`; `model_id` → `CntModel`; `type_id` → `CntContainerType`; `size_id` → `CntContainerSize`; `max_gross_mass`, `tare_mass`, `payload`, `capacity` bigint; `next_survey_date` date; `gen_char_id` → `CntGeneralCharacteristic`; `constr_date` date; `roof_upgrade` boolean; `roof_upgrade_date` date |
| `cnt_container_property` | `ContainerProperty` | `container_id` NOT NULL; `prop_type_id` → `CntPropertyType`; `prop_value` varchar(2000); `comment` varchar(255) |
| `cnt_container_file` | `ContainerFile` | `container_id` NOT NULL; `file_type_id` → `CntFileType`; `comment` varchar(255); `file` FileRef varchar(1024); `file_name` varchar(255) — ручное «Имя файла» |
| `cnt_survey` | `ContainerSurvey` | `container_id` NOT NULL; `survey_type_id` → `CntSurveyType`; `date_begin`, `date_end`, `date_next` date; `org_id` → `VOrgPassport`; `survey_act` FileRef |
| `cnt_repair` | `ContainerRepair` | `container_id` NOT NULL; `repair_type_id` → `CntRepairType`; `org_id` → `VOrgPassport`; `date_next`, `date_end`, `date_begin`, `reject_date`, `manuf_answ_date`, `manuf_notif_date`, `manuf_re_notif_date`, `depart_date`, `return_date`, `docs_submission_date`, `docs_verification_date` date; `defect_id` → `CntDefect`; `defect_reason_id` → `CntDefectReason`; `rep_by_warr_id` → `CntWarranty`; `warr_on_rep_id` → `CntWarranty`; `rep_contract_id` → `CntContract`; `rep_st_id`, `reject_st_id`, `rep_st_instr_id` → `VStation`; `rep_cost`, `cost_with_vat`, `vat_rub` numeric(19,2); `vat` integer; `comment`, `docs_verification_result`, `rejection_reason` varchar(255); `roof_upgrade` boolean; `document` FileRef (старый `new_file`) |
| `cnt_contract` | `ContainerContract` | `contract_num` varchar(255); `contract_type_id` → `CntContractType`; `date_begin`, `date_end`, `date_sign` date; `org_id` → `VOrgPassport` |
| `cnt_warranty` | `ContainerWarranty` | `contract_id` → `CntContract`; `warr_type_id` → `CntWarrantyType`; `warr_duration` integer (мес.); `warr_begin_id` → `CntActType`; `ext_warr_duration` boolean; `insp_in_days` integer; `penalty` numeric(19,2); `cont_type_id` → `CntGeneralCharacteristic` |
| `cnt_act` | `ContainerAct` | `contract_id` → `CntContract`; `act_num` varchar(255); `act_type_id` → `CntActType`; `date_sign` date; `comment` varchar(255); `act_doc` FileRef |
| `cnt_act_container` | `ContainerActLink` | `act_id` NOT NULL → `ContainerAct`; `container_id` NOT NULL → `Container`; уникальная пара |

Виртуальные поля реестра берутся из ссылок и в БД не хранятся: тенты, дуги,
тросы, вент. отверстия — из модели; наименование типа — из типа; длина (фут) —
из размера. В формах их показывают read-only по property path
(`model.tenty` и т.п.) или через `@JmixProperty`-геттеры с
`@DependsOnProperties`.

### Справочники

| Таблица | Entity | Поля | Старый объект |
|---|---|---|---|
| `cnt_model` | `CntModel` | `model` varchar(255) (подпись), `tenty`, `dugi`, `trosy`, `vent` bigint | `cont_model_char` |
| `cnt_container_type` | `CntContainerType` | `code` varchar(255), `type_name` varchar(255) (подпись), `detail` varchar(255), `kind_id` bigint | `cont_type_big` |
| `cnt_container_size` | `CntContainerSize` | `code` varchar(255) (подпись), `height` bigint (мм), `height_txt` varchar(255), `width_f` varchar(255) (длина, фут), `comments` varchar(255) | `cont_size_big` |
| `cnt_general_characteristic` | `CntGeneralCharacteristic` | `char_name` (подпись), `char_name_pf` varchar(255) | `gen_char_cont` |
| `cnt_property_type` | `CntPropertyType` | `prop_type_name` (подпись), `prop_group_name`, `prop_subgroup_name`, `comment`, `prop_type_name_lat` varchar(255) | `cont_prop_type` |
| `cnt_file_type` | `CntFileType` | `file_type_name` varchar(255) | `eri_file_type` |
| `cnt_survey_type` | `CntSurveyType` | `survey_type_name` varchar(255) | `cont_survey_type` |
| `cnt_repair_type` | `CntRepairType` | `repair_type_name` varchar(255) | `cont_repair_type` |
| `cnt_defect_reason` | `CntDefectReason` | `defect_reason_name` varchar(255) | `cont_defect_reason` |
| `cnt_defect` | `CntDefect` | `defect_name` varchar(255), `defect_reason_id` → `CntDefectReason` | `cont_defect` |
| `cnt_act_type` | `CntActType` | `act_type_name` varchar(255), `incl_sign` bigint | `eri_act_type` |
| `cnt_contract_type` | `CntContractType` | `contract_type_name` varchar(255) | `eri_contract_type` |
| `cnt_warranty_type` | `CntWarrantyType` | `warr_type_name` varchar(255); структура уточняется по DDL из [Q02](questions/Q02.md) | `warranty_type` |

Существующие справочники проекта проверены и не подходят: `VDamageType`,
`NsiNvDefectGroup`, `RejectReason` — вагонные неисправности; `DiadocDocumentType`
— типы документов Диадок; отдельных справочников типов договоров, актов, файлов
нет. Все 13 создаются заново и наполняются в T10.

Не создаются: `cnt_operation`, `cnt_invoice`, `cnt_invoice_container`
([Q01](questions/Q01.md)), `cnt_entity_history`, копия `data_file`,
`remontnie_predpriyatiya`.

### Фактические имена (T01)

Бизнес-состав не менялся; ниже отклонения фактической реализации от текста
матрицы.

- Договор и гарантийное условие — это основные entity `ContainerContract`
  (`cnt_contract`) и `ContainerWarranty` (`cnt_warranty`). В колонке «Поля и
  связи» они названы `CntContract` и `CntWarranty`; читать как ссылки на эти
  entity.
- Java-имена ссылочных атрибутов короче имён колонок: `owner_org_id` →
  `owner`, `type_id` → `type`, `size_id` → `size`, `gen_char_id` → `genChar`,
  `org_id` → `org`, `defect_id` → `defect`, `warr_begin_id` → `warrBegin`,
  `cont_type_id` → `contType`. Остальные — camelCase от имени колонки
  (`rep_by_warr_id` → `repByWarr`, `rep_st_instr_id` → `repStInstr`,
  `width_f` → `widthF`, `height_txt` → `heightTxt` и так далее).
- `@InstanceName` там, где подходящего поля нет, — метод с
  `@DependsOnProperties`: `ContainerSurvey.getSurveyName()` и
  `ContainerRepair.getRepairName()` дают `<id> — <дата>`,
  `ContainerActLink.getLinkName()` — `<actNum> / <contNum>`,
  `ContainerWarranty.getWarrantyName()` — формат из раздела «Подписи и lookup».
  У `ContainerProperty` подпись — `propValue`, у `ContainerFile` — `fileName`.
- В `cnt_act_container` уникальный индекс называется
  `idx_cnt_act_container_act_id_container_id`. Отдельный индекс по `act_id` не
  создаётся: он совпадает с ведущей колонкой уникального индекса и был бы
  дублем. Индекс по `container_id` создан отдельно.
- `pk_<table>` — имя первичного ключа во всех 22 таблицах.

## Подписи и lookup

- Контейнер — `contNum`; договор — `contractNum`; акт — `actNum`;
  условие гарантии — метод `@InstanceName` с `@DependsOnProperties`:
  `"<id> — <contract.contractNum> / <warrType.warrTypeName>"` (пользователи
  знают условия по ИД); станция — существующий `getFillName()`; организация —
  `shortname`.
- Организация: `entityComboBox` с `itemsQuery` по `nsi_VOrgPassport`,
  регистронезависимый `like` по `shortname`, `name`, `okpo`, `order by shortname`.
  Станция: `entityComboBox` с `itemsQuery` по `stName`/`stCode` — образец
  `da/view/claimdepostation/claim-depo-station-detail-view.xml`. Lookup-view для
  `VOrgPassport` не создаётся.
- Контейнер в формах ремонта и освидетельствования: `entityComboBox` с
  `itemsQuery` по `contNum` (`like`, верхний регистр), плюс `entity_lookup` на
  `cnt_Container.list`. Из карточки контейнер предзаполнен и read-only.
- Справочные поля: `entityComboBox` + действия `entity_lookup` (открывает list
  view справочника, где роль НСИ создаёт запись и выбирает её) и `entity_clear`.

## Карточка контейнера и вкладки

- `cnt_Container.detail`: шапка «Описание» (все поля `cnt_container` +
  виртуальные), затем `tabSheet` с вкладками Характеристики, Ремонты,
  Освидетельствования, Акты, Файлы, История. Порядок как в старой карточке без
  Операций и Накладных.
- Вкладка = фрагмент (`@FragmentDescriptor`) в `container/view/fragment/<name>/`,
  получает `containerDc` через `<property name="containerDc" value="containerDc"
  type="CONTAINER_REF"/>`, загружает свой `collection` по
  `where e.container.id = :containerId` в `@Subscribe(target =
  Target.HOST_CONTROLLER) BeforeShowEvent`, с `simplePagination`. Образец —
  `drcontract/view/fragment/drcontractcopiesdocumentfg/`.
- Дочерние формы открываются диалогами `DialogWindows.detail(...)` с
  `withParentDataContext` и инициализатором `setContainer(...)`; после
  `StandardOutcome.SAVE` фрагмент перезагружает свой loader; после cancel —
  ничего.
- Для нового контейнера (`entityStates.isNew`) `tabSheet` недоступен до первого
  сохранения; сообщение подсказывает сохранить описание.
- Ремонт и освидетельствование: одна entity и одна detail-форма используются и
  из самостоятельного списка, и из вкладки. Форма принимает контейнер как
  инициализированное значение; из списка контейнер выбирается lookup-ом.
- Вкладка «Акты»: грид актов контейнера через `cnt_act_container`, действия
  «Создать» (акт с текущим контейнером в составе), «Добавить существующий»
  (lookup `cnt_ContainerAct.list`, создаётся связь без дубля), «Убрать из
  контейнера» (удаляется только связь), «Удалить акт» (soft delete акта и его
  связей одной транзакцией, предупреждение с перечнем других контейнеров).
- Вкладка «История» — фрагмент EntityLog из T09 с параметрами entity-name и id.

## Файлы

- Атрибуты `FileRef`, колонка `VARCHAR(1024)`; `fileStorageUploadField` с
  `fileStoragePutMode="IMMEDIATE"`, `clearButtonVisible`, `fileNameVisible`.
- Папка хранилища: `rvk.storage-folders.cnt-file=cnt_file` в
  `application.properties` по образцу существующих `rvk.storage-folders.*`
  (`app/storage/FileStorageFoldersConfiguration.java`); все контейнерные
  вложения используют её.
- Просмотр — фрагмент `common/view/displayfile/DisplayFile` (`setFile(FileRef)`),
  скачивание — `io.jmix.flowui.download.Downloader`.
- Заменённые файлы физически не удаляются; EntityLog хранит старое значение
  атрибута. Копирование записи не переносит `FileRef`.

## История (EntityLog)

- Настройка через liquibase `04-data/cnt_entity_log.xml`: INSERT в
  `audit_logged_entity` (`name` = entity-name, `auto` = true, `manual` = true)
  и `audit_logged_attr` для всех атрибутов каждой `cnt_*` entity; preConditions
  «нет записи с таким name». Проверить `jmix.audit.enabled`.
- Фрагмент `container/view/fragment/entitylog/EntityLogFragment`: свойства
  `entityName` (String) и `entityId` (Long); грид `audit_EntityLog` с
  `where e.entity = :entityName and e.entityRef.longEntityId = :entityId order
  by e.eventTs desc`, колонки дата, пользователь, тип (CREATE/MODIFY/DELETE);
  под гридом атрибуты выбранной записи (`name`, `oldValue`, `value`).
  Используется во вкладке «История» карточки и, по желанию, в формах ремонта/
  освидетельствования/договора.
- `entityLog.view` (стандартный экран аддона) — пункт в `other_menu` для
  администраторов; политики не расширяются для обычных ролей.

## Роли, меню, view-id

| Роль | code | Права |
|---|---|---|
| `ContainerReadRole` | `container-read` | READ + VIEW атрибутов всех `cnt_*` и `audit_EntityLog`/`EntityLogAttr`; view/menu всех list/detail раздела «Контейнеры» и справочников (только чтение); экспорт |
| `ContainerEditRole` | `container-edit` | Как read + CREATE/UPDATE/DELETE и MODIFY атрибутов `Container`, `ContainerProperty`, `ContainerFile`, `ContainerSurvey`, `ContainerRepair`, `ContainerContract`, `ContainerWarranty`, `ContainerAct`, `ContainerActLink`; справочники только READ |
| `ContainerNsiEditRole` | `container-nsi-edit` | READ основных записей не даёт; CRUD + MODIFY атрибутов 13 справочников, их list/detail и menu |

Роли назначаются совместно; существующим пользователям автоматически не
назначаются. Образец: `da/security/DaContractReadRole.java`,
`DaContractEditRole.java`. Каждый UI-таск добавляет свои view-id в роли.

Меню (`app/src/main/resources/ru/fgk/ws/app/menu.xml`), ключи в
`messages_ru.properties` с полной квалификацией пакета:

| menu id | Пункты (view-id) | Таск |
|---|---|---|
| `container` («Контейнеры», верхний уровень) | `cnt_Container.list` (T03), `cnt_ContainerRepair.list` (T07), `cnt_ContainerSurvey.list` (T04), `cnt_ContainerContract.list`, `cnt_ContainerWarranty.list`, `cnt_ContainerAct.list` (T06) | T02 создаёт раздел |
| `nsi/nsi_container` («Контейнеры» внутри «Справочники») | `cnt_CntModel.list`, `cnt_CntContainerType.list`, `cnt_CntContainerSize.list`, `cnt_CntGeneralCharacteristic.list`, `cnt_CntPropertyType.list`, `cnt_CntFileType.list`, `cnt_CntSurveyType.list`, `cnt_CntRepairType.list`, `cnt_CntDefectReason.list`, `cnt_CntDefect.list`, `cnt_CntActType.list`, `cnt_CntContractType.list`, `cnt_CntWarrantyType.list` | T02 |
| `other_menu` | `entityLog.view` | T09 |

Detail view-id: `cnt_<Entity>.detail`; они же указываются в `@ViewPolicy`, в
том числе открываемые только диалогом.

## Списки

- `propertyFilter`/`jpqlFilter`, `simplePagination` с `urlQueryParameters`,
  `gridColumnVisibility`, `<settings auto="true"/>`, экспорт
  `async_excel_export` (core). Образцы:
  `pt/view/ptrepaircontract/pt-repair-contract-list-view.xml`,
  `pt/view/ptpart/pt-part-list-view.xml`.
- Реестр: фильтры по номеру, заводскому номеру, изготовителю, собственнику,
  модели, типу, размеру, дате следующего освидетельствования. Ремонты: по
  контейнеру, виду, исполнителю, договору, датам браковки/начала/окончания.
  Освидетельствования: по контейнеру, виду, датам. Договоры: по номеру, типу,
  контрагенту. Акты: по номеру, типу, договору, дате.
- Действия списков: создать, редактировать, копировать, удалить (soft delete с
  подтверждением; при DENY-ссылках — понятное сообщение).

## Обязательные поля (UI)

| Форма | required |
|---|---|
| Контейнер | номер |
| Характеристика, файл, освидетельствование, ремонт | контейнер |
| Файл | файл |
| Ремонт | дата браковки |
| Гарантийное условие | договор |
| Акт | номер акта |

Остальные поля необязательны. Правило пользователя: обязательность настраивают
программисты в view, БД не ограничивает.
