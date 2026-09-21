# T04 — UI: галочка по роли и настройке, дополнение на карточке, фильтры по контролю

Статус: done — повторная проверка [002.md](checks/002.md), исправление [F01](fixes/F01.md)
План: [plan.md](../../plan.md)
Зависимости: T01, T03
Сложность: medium — три существующих экрана, образцы фильтров и скрытия по
роли в проекте, контракты заданы
Сложность проверки: medium — UI-тесты и браузерный проход трёх экранов
Актуальная проверка: [002.md](checks/002.md)

## Коротко

Карточка пакета Диадок показывает связанные документы по настройке
контрагента, а галочку «Показать связанные документы» видят только
админы; СЧФ-дополнения показываются всегда и помечаются иконкой. На
списках «Пакеты по ремонту деталей» и «Пакеты ВУ-23» появляется фильтр по
результату контроля, и чинится кнопка «Текст ошибки» на ВУ-23.

## Результат и контекст

Карточка — `app/src/main/java/ru/fgk/ws/app/diadoc/view/diadocpacket/
DiadocPacketDetailView.java` (`showRelatedCheckbox` 244, `filterDocuments`
594-601 скрывает `relatedDocument=true`, `onShowRelatedCheckboxChange`
604-607, `documentItemsDlLoadDelegate` 589-592, renderer `relatedIcon`
1171-1190 с `vaadin:link` и tooltip `relatedIcon.tooltip`) и XML
`app/src/main/resources/ru/fgk/ws/app/diadoc/view/diadocpacket/
diadoc-packet-detail-view.xml` (checkbox 73-75, колонки `statusIcon`,
`relatedIcon` 90-91). Пакет карточки — `DiadocPacket` с `contractor`.
Образец скрытия по роли — `DiadocSigningListView.applyEditConstraints`
(143-147, `AccessManager.applyRegisteredConstraints(new
DiadocSigningEditEnabled())`).

Списки: `pt/view/ptrepairpacket/PtRepairPacketListView.java` + XML
(`propertyFilter`/`jpqlFilter` 55-145; образец multiSelect —
`diadocStatusFilter` 98-112 с `hasInExpression`, контроллер 116-128,
324-351 подменяет условие для синтетического значения «На проверке»;
колонка «Контроль» `packCheckedCode` 184);
`dr/view/drdiadocoperrepairpacket/DrDiadocOperRepairPacketVu23ListView.java`
+ XML (загрузка через `loadFromRepositoryDelegate` 143-160, фильтры
54-160, колонка «Результат проверки» `packCheckedCode` 223, кнопка
`showErrorText` 169-186; дефект 162-167: `PackCheckedCodeEnum.VIOLATION.
getId().equals(selected.getPackCheckedCode())` сравнивает `Integer` с enum
→ кнопка всегда неактивна). Enum — `dr/entity/PackCheckedCodeEnum`
(NORM/VIOLATION/WARNING/WARNING_ECP, подписи в `messages_ru` 6375-6379).

Контракты (T01, T03): `DiadocProcessingSettingsService.resolveForPacket(
DiadocPacket)` → `showRelatedDocuments`; `DiadocSettingsEditEnabled`
(`diadocSettingsEdit.enabled`); `DiadocPacketDocLink.supplementDocument`.

Требуемое поведение:

1. Карточка: при открытии показ связанных = `showRelatedDocuments`
   контрагента пакета (умолчания, если контрагента нет); переключает его
   кнопка «Показать/Скрыть связанные документы», видимая только по
   `DiadocSettingsEditEnabled`, — админ меняет состав в рамках экрана,
   настройка не пишется (первая редакция — галочка — заменена кнопкой по
   [Q02](../../questions/Q02.md): чекбокс блокируется read-only режимом
   карточки). `filterDocuments` при `false` скрывает
   только `relatedDocument=true && !supplementDocument`. В колонке
   `relatedIcon` для `supplementDocument=true` — `vaadin:paperclip`,
   tooltip `supplementIcon.tooltip=Дополнение к ФПУ-26`
   (плюс `originalMessageId`, как у связанных); для обычных связанных —
   как сейчас.
2. Списки: фильтр «Результат контроля» — `jpqlFilter` с
   `multiSelectComboBox` по `packCheckedCode` (значения enum с подписями
   из `PackCheckedCodeEnum` + «Не проверялся» → `is null`, механика как у
   `diadocStatusFilter`); на `pt-repair-packets` — в блоке фильтров рядом с
   `diadocStatusFilter`, сохранять в `ViewSettings` вместе с остальными;
   на ВУ-23 — рядом с `acceptStatusFilter`. Кнопка «Текст ошибки» —
   сравнивать enum с enum (`selected.getPackCheckedCode() == VIOLATION`),
   включать и для `WARNING`/`WARNING_ECP`, если текст есть.
3. Ключи: `showRelatedButton.show` / `showRelatedButton.hide` вместо
   `showRelatedCheckbox.label`; новые —
   `supplementIcon.tooltip`, `packCheckedCodeFilter.label=Результат контроля`,
   `packCheckedCodeFilter.notChecked=Не проверялся` в блоках своих view.

## Область и изоляция

Меняются: `diadoc/view/diadocpacket/DiadocPacketDetailView.java` и XML,
`pt/view/ptrepairpacket/PtRepairPacketListView.java` и XML,
`dr/view/drdiadocoperrepairpacket/DrDiadocOperRepairPacketVu23ListView.java`
и XML, ключи этих view в `messages_ru.properties`, UI-тесты
`app/src/test/java/ru/fgk/ws/app/pt/view/...`, `.../dr/view/...`,
`.../diadoc/view/diadocpacket/DiadocPacketListViewTest.java` (при
необходимости). Не менять: сервисы (T02), настройки (T01), sync (T03),
роли. Ресурсы — схема `main_f_diadoc_check`, порт 8082, браузер, Gradle
daemon; код параллельно с T02, тесты и `bootRun` — по очереди с T02.

## Реализация

1. Карточка: значение и видимость выставлять в `onBeforeShow`/после
   загрузки пакета до первой загрузки документов (`loadDocumentItemsAsync`
   использует `filterDocuments`). `jmix-verify-api-symbol` для иконки
   (`VaadinIcon.PAPERCLIP` существует), `jmix-style-ui` для цвета.
2. Фильтры — `jmix-create-list-view` (раздел фильтров), образец
   `diadocStatusFilter`; для ВУ-23 условие фильтра попадает в
   `JmixDataRepositoryContext` делегата — проверить, что
   `findAllByPacketDocumentType` его применяет (как остальные jpqlFilter
   этого экрана).
3. Тесты — `jmix-create-test`: `BaseUiTest` для обоих списков (открытие,
   выбор значения фильтра, отсутствие исключений и наличие условия в
   загрузчике); unit на `filterDocuments` (вынести в статический метод с
   параметром `showRelated`) — кейсы related/supplement/own.
4. Инспекция XML (`jmix-ide-static-analysis`) после правок.

## Критерии приёмки

- C1: Под `ws-user` кнопки нет; при `showRelatedDocuments=false` у
  контрагента связанные скрыты, дополнения видны с иконкой; при `true` —
  всё видно. Под `diadoc-settings-admin` (в том числе без UPDATE на
  `DiadocPacket`) кнопка видна с текстом по текущему состоянию и
  переключает состав; «Обработать повторно» с карточки не даёт «Ошибка
  обработки».
- C2: На обоих списках фильтр по результату контроля ограничивает строки
  (в т.ч. «Не проверялся»); на `pt-repair-packets` значение сохраняется в
  `ViewSettings` между открытиями.
- C3: На ВУ-23 кнопка «Текст ошибки» активна для строки с нарушением и
  показывает `packCheckedText`.
- C4: Нет сырых `msg://`, `DiadocPacketListViewTest` и существующие UI-
  тесты зелёные.

## Самопроверка исполнителя

`./gradlew :app:compileJava`, `spotlessApply`, новые UI-тесты и unit;
smoke в браузере: `bootRun` (8082), карточка любого пакета и оба списка с
фильтром. Полный `:app:test` не нужен.

## Независимая проверка

`./gradlew :app:test --tests "ru.fgk.ws.app.diadoc.view.*" --tests
"ru.fgk.ws.app.pt.view.*" --tests "ru.fgk.ws.app.dr.view.*"`. Браузер
(`playwright-cli`): под `ws-user` и под `diadoc-settings-admin` (роли
назначать в администрировании) — карточка пакета с related-линком
(создать через SQL в `diadoc_packet_doc_link`, `related_document=true`,
`supplement_document=false/true`) при `showRelatedDocuments=false` и
`true`; оба списка: выбрать «Нарушение», «Не проверялся», сбросить; ВУ-23
— кнопка «Текст ошибки». Без браузера — так и записать: `render not
browser-verified`.

## Прогресс и продолжение

- [x] Карточка пакета
- [x] Фильтры списков и кнопка ВУ-23
- [x] Тесты и инспекция
- [x] Независимая проверка пройдена: [001](checks/001.md)
- [x] Исправление [F01](fixes/F01.md): ошибка «Обработать повторно»,
      кнопка вместо галочки (по [Q02](../../questions/Q02.md)), новая
      итерация на проверку.
- [x] Повторная проверка пройдена: [002](checks/002.md)

Ближайший шаг: `task-execute` для [specs/work/diadoc-check/tasks/T06/task.md](../T06/task.md) — сквозная проверка двух приложений на данных -26
Препятствия: нет
Связанные исправления: [F01](fixes/F01.md)
