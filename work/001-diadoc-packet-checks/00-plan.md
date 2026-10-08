---
by: architect
at: "2026-10-07T11:12:00-04:00"
---
# Диадок: единый результат проверок пакета и решение об автоподписании

## Цель и границы

Сейчас проверки пакета Диадок разбросаны:
- парсеры каждого типа пишут бизнес-проверки в свои таблицы:
  `dr_diadoc_wag_oper_repair_contract` / `dr_diadoc_wag_plan_repair_contract` + архив
  `dr_wag_vrk_arch`, `dr_diadoc_oper_repair_tr1`, `pt_repair_packet`, `dr_diadoc_oper_repair_packet`;
- `DiadocPacketViolationCheckService.applyTo` дописывает туда же флаги Диадок (поле
  `DiadocPacket.violations` по настройкам контрагента) и «связанный документ в подписании»;
- `/api/diadoc/approve` (`PacketApprovalService`) доверяет `ok` из запроса NiFi и согласует все
  ссылки пакета, включая связанные документы из других сообщений и СЧФ-дополнения.

Что нужно:
1. Одна новая таблица результата проверки пакета, позиции хранятся в JSON.
2. Конвейер проверок по типам пакета: видно, что проверяется у каждого типа, и новую проверку
   легко добавить.
3. Флаги Диадок пишутся только в новую таблицу. Бизнес-проверки пишутся и в старые таблицы
   (на них стоят экраны и АСУ ВРК), и в новую.
4. Решение «можно ли автоматически подписать пакет» с причинами отказа. Принимает его `/approve`.

**Не входит:**
- АСУ ВРК (`asuvrk/*`): не трогаем ни код, ни запись в общие таблицы;
- перенос бизнес-проверок из парсеров в шаги конвейера: парсеры не меняются, кроме g04;
- перевод старых экранов и фильтров «Контроль» (ВУ-23, Рем.Дет, ТР-1, рекламации, журнал загрузок)
  на новую таблицу. Флагов Диадок в этих экранах больше не будет — это согласовано;
- ручное согласование и подписание на карточке пакета;
- `../rvk-diadoc`;
- набор типов, которые автосогласуются: остаётся как сейчас (карта `AUTO_APPROVAL_CODES` в
  `PacketApprovalService` + значение настройки из `NvProcessingSettingsService`).

## Общие решения

### Новая таблица `packet_check`

Entity `PacketCheck` в `ru.fgk.ws.app.diadoc.entity`, changelog в
`app/.../liquibase/changelog/01-tbl/`, author `app`.

| Колонка | Смысл |
|---|---|
| `id` | Long IDENTITY |
| `source_type` | источник пакета: пока только `DIADOC` (задел под АСУ ВРК) |
| `source_key` | uuid: для Диадок — messageId пакета |
| `packet_type` | тип пакета (`PacketDocumentType` id) |
| `status` | итог по `PackCheckedCodeEnum`: NORM / WARNING / VIOLATION |
| `items` | jsonb, позиции проверки |
| `checked_at` | когда строка пересчитана наработкой |
| `auto_sign_allowed` | можно ли автоподписать (последний расчёт), nullable |
| `auto_sign_blockers` | jsonb, причины запрета (последний расчёт), nullable |
| `auto_sign_checked_at` | когда посчитано решение, nullable |

- Пара `source_type` + `source_key` уникальна.
- Строка перезаписывается целиком при каждой наработке, без накопления (в отличие от
  `PackCheckedStatusAccumulator` старых таблиц).
- `status` = VIOLATION, если есть позиция VIOLATION; иначе WARNING, если есть WARNING; иначе NORM.
- jsonb в entity — по образцу `DiadocPacket.violations` (`JsonNodeDatatype`) или типизированной
  обёртки; решает Программист t01, остальные таски пользуются его API.

Позиция в `items`:

| Поле | Значение |
|---|---|
| `source` | `PROCESSING` (сбой наработки, сбой самой проверки) / `BUSINESS` / `DIADOC` |
| `code` | код проверки: вид нарушения Диадок, `ProcessPacketErrorType`, `BUSINESS_<TYPE>`, `CHECK_FAILED` |
| `severity` | `VIOLATION` / `WARNING` |
| `message` | готовый русский текст для пользователя |
| `params` | параметры подстановки (TorID, связанные messageId и т.п.), необязательно |
| `documentEntityId` | документ, к которому относится позиция, необязательно |

Причина запрета в `auto_sign_blockers`: `code` + `message` (+ `params`).

### Уровни нарушений в настройках контрагента

- `DiadocViolationLevel` становится: Не применяется (`not_applicable`) / Нарушение (`violation`) /
  Предупреждение (`warning`). Значения `error` больше нет.
- Нарушение даёт позицию VIOLATION, Предупреждение — WARNING, Не применяется — позиции нет.
- Существующие строки `violation` (changeSet-ы 4 и 9 в `tbl-diadoc_sign_settings_violation.xml`)
  остаются блокирующими. Новый changeSet с preConditions переводит `error` → `violation`.
  Старые changeSet-ы не менять.

### Правила результата

- **Автоподписание блокирует только VIOLATION.** WARNING показывается, но не мешает.
- **`ok` в ответе `/api/diadoc/processPacket` — как сейчас по смыслу:** `true` только если пакет
  наработан и `status` строки = NORM. Флаги Диадок в `ok` учитываются, любое предупреждение даёт
  `ok = false` / `CHECK_FAILED`, `message` — тексты позиций. Контракт `ProcessPacketResponse` не
  меняется.
- **«Связанный документ в подписании»** больше не нарушение, а причина запрета автоподписания.
- **Флаги Диадок** пишутся только в новую таблицу: в старые таблицы типа ничего не дописывается.

### Конвейер проверок

- **Шаг конвейера** — проверка с источником (`PROCESSING` / `BUSINESS` / `DIADOC`). Получает
  контекст (срез `LocalPacketSnapshot`, пакет, тип, `DiadocProcessingSettings`, итог разбора
  `PacketParseOutcome`) и возвращает позиции. В базу сам не пишет.
- **Состав шагов по типам** задаётся явно в одном классе: открыв его, видно, что проверяется у
  каждого типа из `PacketParserService.dispatch`.
- **Падение шага** не роняет наработку: оно становится позицией `PROCESSING` / `CHECK_FAILED`
  уровня VIOLATION (как сейчас в `applyTo`).
- **Запуск** — в `PacketParserService.dispatchAndResolve` после парсера, и при успешном разборе,
  и при непройденном. `PACKET_NOT_FOUND` строки не создаёт. СЧФ через `processPacket` не
  нарабатывается, строки у неё нет.
- **Шаги первого этапа**, общие для всех типов:
  - `PROCESSING` — сбой разбора: `PacketParseOutcome` не processed (`REPAIR_NOT_FOUND`,
    `MULTIPLE_REPAIRS`, `STALE_PACKET`, `CONTRACTOR_MISMATCH`, `DOCUMENTS_NOT_FOUND`, …) → одна
    позиция VIOLATION, код = `ProcessPacketErrorType`, текст = сообщение исхода. Так на пакете не
    остаётся отметка прошлой наработки;
  - `DIADOC` — флаги из `violations` по уровням настроек; логика и тексты переезжают из
    `MirrorPacketViolationService.collectResults`;
  - `BUSINESS` — адаптер старых таблиц (g01.t03): читает отметку, которую записал парсер, и
    раскладывает её на позиции.
- **Бизнес-адаптер:** код позиции грубый — `BUSINESS_<TYPE>` по типу пакета. Текст режется по
  строкам (разделители `\r\n` у накопителя, `\n` у Рем.Дет). Уровень:
  - контракты ТР-2 и ДЕП/КАП: `pack_checked_text` — по коду пакета (V), `pack_warning_text` —
    WARNING, тексты связей МХ3-МХ1 (`listRelation.checkedText`) — по коду связи; итог
    `WARNING_ECP` (донор не подписан) — отдельная позиция WARNING;
  - Рем.Дет: `errors` — VIOLATION, `errors_warning` — WARNING;
  - ТР-1 и `dr_diadoc_oper_repair_packet` (МХ-1, ВУ-23, Рекламация, Рем.Приг., Хранение): уровень
    каждой строки = общий код пакета.
- **Новые бизнес-шаги** (в этой работе их нет, но механизм нужен): позиции `BUSINESS`, выданные
  не адаптером, конвейер дублирует в старую таблицу типа через существующий
  `DiadocPacketCheckResultService.appendResults`. Позиции `DIADOC` и `PROCESSING` не дублируются.

### Решение об автоподписании

- Принимает `/approve` (`PacketApprovalService`). Поле `ok` из запроса больше не учитывается
  (остаётся в DTO для совместимости), тип ошибки `OK_STATUS_IS_FALSE` больше не выдаётся.
- Отдельный сервис решения. При расчёте:
  - пересчитывает шаг `DIADOC` на текущее зеркало и настройки (после наработки могла прийти
    синхронизация или поменяться настройка);
  - обновляет в строке `DIADOC`-позиции, `status` и `auto_sign_*`;
  - возвращает `allowed` и список причин (код + текст).
- Причины запрета (все найденные, не только первая):
  - автосогласование для типа не настроено или выключено — как сейчас (`AUTO_APPROVAL_CODES` +
    `NvProcessingSettingsService.getSettingValue`, «1» = включено);
  - нет строки проверки (пакет не нарабатывался);
  - в строке есть VIOLATION;
  - флаги Диадок ещё не рассчитаны (`DiadocPacket.violationsCalculatedAt == null`);
  - есть подписанные / отклонённые / аннулированные документы — по зеркалу
    (`DiadocPacketDoc.signatureStatus`: SIGNED / REJECTED / ANNULLED) и по нашему
    `PacketDocumentFlow` (`SIGNED` / `SIGNED_REJECT`);
  - подписание уже идёт или пакет уже согласован: `DiadocDocumentFlowService.checkCanApprove(messageId)`
    ≠ AVAILABLE; незавершённый `PacketDocumentFlow` по entityId документа (статусы из
    `DiadocPacketViolationCheckService.PENDING_DOCUMENT_FLOW_STATUSES`); для связанного
    документа — ещё и `checkCanApprove` его исходного пакета (`originalMessageId`);
  - нет своих документов для согласования.
- **Какие документы проверяются:** свои документы пакета; при `showRelatedDocuments` из настроек
  контрагента (`DiadocProcessingSettingsService.resolveForPacket`) — ещё и связанные. СЧФ-дополнения
  (`DiadocPacketDocLink.supplementDocument`) никогда не проверяются и не подписываются. Удалённые
  ссылки (`deletedDate` не null) не учитываются.
- **Какие документы согласует `/approve`:** только свои документы пакета — без связанных
  (`relatedDocument`), без дополнений, без удалённых.
- **Ответ `/approve`:** старые поля `ApprovePacketResponse` остаются; добавляются тип ошибки
  `AUTO_SIGN_BLOCKED` и список причин (код + текст).

### Экраны

- **Карточка пакета (`DiadocPacketDetailView`):** кнопка результата проверки открывает окно с
  позициями (источник, уровень, текст) и блоком «Автоподписание: можно / нельзя — причины».
  Решение считается при открытии окна и не сохраняется. Для пакета без строки (СЧФ,
  ненаработанный) позиции `DIADOC` считаются на лету, как сейчас; блок автоподписания для СЧФ не
  показывается.
- **Список пакетов (`DiadocPacketListView`), колонка «Корректный пакет»:** да = в строке нет
  VIOLATION. Без строки — по флагам Диадок на лету, как сейчас. Строки `packet_check` грузятся
  пачкой на отображаемые пакеты, а не запросом на каждую строку.

### Окружение

- Тестам нужна PostgreSQL из Docker Compose и `application-test-local.properties` (см.
  `CLAUDE.md`, раздел «Окружение вне корпоративного контура»). БД у всех групп общая, поэтому
  таски с интеграционными тестами берут `locks: [db]`.
- Весь видимый текст — через messages (`messages_ru.properties`), никаких строк в коде UI.

## Материалы

- Обсуждение с человеком 2026-10-07 — решения выше.
- Ветка `feature/diadoc-sign-settings-violations`, коммиты `d91503f8` (строка настроек по
  умолчанию, уровни нарушений по контрагенту) и `7f3e7aae` (флаг `RELATED_DOCUMENT_REJECTED`,
  удалено нарушение «подписанные/отклонённые», колонка «Корректный пакет»).
- Где хранятся бизнес-проверки по типам и кто их читает — javadoc
  `DiadocPacketCheckResultService`, парсеры из `PacketParserService.dispatch`, `dr/validation/*`.
- Формат `violations`: `../rvk-diadoc/src/main/java/ru/fgk/rvk/diadoc/processing/service/PacketViolationService.java`.
- Скилы проекта — по таблице в `CLAUDE.md` (entity, changelog, i18n, роли, тесты, стили, fetch plan).

## Группы

| Группа | Таски | Когда начинается |
|---|---|---|
| g01 Таблица и конвейер | t01 уровни и таблица → t02 конвейер и наработка → t03 бизнес-адаптер | сразу |
| g02 Автоподписание | t04 | после g01 |
| g03 Экраны | t05 | после g01 и g02 |
| g04 Чистка контроля ремонтов | t06 | сразу, одновременно с g01 |
| g05 Приёмка | — | когда готово всё |

- g01 → g02 → g03 — цепочка: решение об автоподписании читает таблицу и шаг `DIADOC` из g01,
  экраны показывают и строку, и решение.
- g04 трогает другой код (`ImportedWagRepairContract`, пустые валидаторы, вызовы в трёх парсерах)
  и ни от кого не зависит. Его стык с бизнес-адаптером (`WARNING_ECP`) закрывают тесты и приёмка.
- Отдельных групп-проверок нет: каждую группу закрывают тесты её Программистов, сквозной сценарий
  — приёмка.
