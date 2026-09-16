# T11 — Карточка контейнера: «Описание» первой вкладкой

Статус: todo
План: [plan.md](../../plan.md)
Зависимости: нет
Сложность: medium — XML карточки, контроллер и UI-тест; меняется контракт
доступности вкладок, образец tabSheet в проекте есть.
Сложность проверки: hard — браузер: новый и сохранённый контейнер, две ширины
экрана, роли чтения и редактирования.
Актуальная проверка: нет

## Коротко

Перекомпоновываем карточку контейнера: вместо аккордеона «Описание» над
скрытыми вкладками — один tabSheet, где «Описание» является первой вкладкой,
как в старой ЕРК. У нового контейнера остальные вкладки видны, но неактивны до
первого сохранения; текст-подсказка убирается. Кнопки «Сохранить / OK / Отмена»
всегда внизу и не наезжают на форму; поля описания сгруппированы по смыслу.

## Результат и контекст

Сейчас (`container-detail-view.xml`, `ContainerDetailView`): `vbox content
height="100%"` → `details descriptionSection` с формой → `span tabsHint` →
`tabSheet containerTabSheet`, который скрыт до сохранения. Форма выше области,
содержимое вылезает, и `detailActions` рисуются поверх полей (замечания 1, 2, 6
в [ui-review-2026-09-16.md](../../input/ui-review-2026-09-16.md)). Старая
карточка — [img_3.png](../../input/img_3.png): вкладки «Описание |
Характеристики | … | История». Целевой контракт — раздел «Пересмотр UI
2026-09-16 → Карточка контейнера» в [contracts.md](../../contracts.md).

## Область и изоляция

Меняет: `app/src/main/resources/ru/fgk/ws/app/container/view/container/container-detail-view.xml`,
`app/src/main/java/ru/fgk/ws/app/container/view/container/ContainerDetailView.java`,
`app/src/test/java/ru/fgk/ws/app/container/view/ContainerRegistryViewsUiTest.java`,
свои ключи в `app/src/main/resources/ru/fgk/ws/app/messages_ru.properties`
(префикс `ru.fgk.ws.app.container.view.container/containerDetailView.*`),
раздел контракта в `contracts.md`. Фрагменты вкладок и их контракт
(`setContainerDc`, `refresh()`) не меняются. Общие ресурсы: БД, порт, браузер,
gradle daemon. Параллельно с T12, T13, T14 в своём worktree; в
`messages_ru.properties` — только свои ключи. Проверка после T14.

## Реализация

- Skills: `jmix-create-detail-view`, `jmix-verify-api-symbol`,
  `jmix-add-i18n-keys`, `jmix-style-ui` (чтобы не добавлять CSS),
  `jmix-create-test`.
- `layout` → `tabSheet id="containerTabSheet" width="100%" height="100%"
  themeNames="small"` → `hbox id="detailActions"`. Первая вкладка
  `descriptionTab` (`msg://containerDetailView.tab.description`), затем
  существующие `propertiesTab`, `repairsTab`, `surveysTab`, `actsTab`,
  `filesTab`, `historyTab` с тем же содержимым. `details`, `span tabsHint` и
  `vbox content` удаляются.
- `descriptionTab`: `scroller` (100 %/100 %, `scrollBarsDirection="VERTICAL"`)
  → `formLayout id="form" dataContainer="containerDc"`, responsiveSteps
  1 / 2 (≥40em) / 3 (≥80em). Группы — подзаголовки `h5` с `colspan="3"` внутри
  формы, ключи `containerDetailView.group.identity|model|mass|dates`:
  1. «Идентификация»: `contNumField`*, `manufNumField`, `manufacturerField`,
     `ownerField`.
  2. «Модель, тип и размер»: `modelField`, `modelTentyField`,
     `modelDugiField`, `modelTrosyField`, `modelVentField`, `typeField`,
     `sizeField`, `sizeWidthFField`, `genCharField`.
  3. «Массы и объём»: `maxGrossMassField`, `tareMassField`, `payloadField`,
     `capacityField`.
  4. «Даты и модернизация»: `constrDateField`, `nextSurveyDateField`,
     `roofUpgradeField`, `roofUpgradeDateField`.
  Все id, `itemsQuery`, `actions`, `readOnly` и `required` полей — как сейчас.
- Контроллер: вместо `setVisible` у tabSheet/hint — `setEnabled(false)` у
  шести вкладок, пока `getEditedEntity()` новый (Vaadin `Tab` реализует
  `HasComponents` → `HasEnabled`). Доступ к вкладке — `@ViewComponent
  ("containerTabSheet.repairsTab") Tab` либо
  `containerTabSheet.getSubPart("repairsTab")`; подтвердить символ по
  `jmix-verify-api-symbol`. В `AfterSaveEvent` — включить вкладки и оставить
  существующие `refresh()` фрагментов и `historyFragment.setLogTarget`.
  Подсказки и tooltip нет. Javadoc класса переписать под новую компоновку.
- Messages: добавить `tab.description`, `group.*`; удалить `description`,
  `tabsHint`. Неиспользуемых ключей не оставлять.
- Никаких `css="..."`, новых `classNames`, custom properties.
- `ContainerRegistryViewsUiTest`: в тесте нового контейнера — все вкладки,
  кроме `descriptionTab`, `!isEnabled()`; в тесте сохранённого — все
  `isEnabled()`; выбранная вкладка у нового — `descriptionTab`.
- `contracts.md`: в разделе «Пересмотр UI 2026-09-16» отметить фактические
  имена, если отклонились.

## Критерии приёмки

- C1: Новый контейнер: открыта вкладка «Описание», остальные шесть неактивны
  (клик не переключает), подсказки нет; после ввода номера и «Сохранить»
  вкладки активны, «Ремонты» открывается, «Создать» в ней работает.
- C2: Сохранённый контейнер: все вкладки активны сразу, данные вкладок
  загружены (регрессия T03, T04, T07).
- C3: При 1366×768 и 1920×1080 с полностью заполненным описанием кнопки
  «Сохранить / OK / Отмена» видны внизу, не перекрывают поля; форма
  прокручивается внутри вкладки.
- C4: Все 22 поля описания на месте в четырёх группах; в XML нет `details`,
  `css=`, сырых `msg://` в браузере.
- C5: Роль `container-read`: карточка открывается, вкладки активны, поля
  read-only; роль `container-edit` — редактирование и сохранение.
- C6: UI-тест состояния вкладок зелёный; `./gradlew :app:test --tests
  "ru.fgk.ws.app.container.view.*UiTest"` зелёный.

## Самопроверка исполнителя

Gate 1 по изменённому XML (IDE-инспекция либо `jmix-ide-static-analysis`),
`./gradlew :app:compileJava`, `./gradlew spotlessApply`,
`./gradlew :app:test --tests "ru.fgk.ws.app.container.view.*UiTest"`;
один браузерный smoke C1 (`playwright-cli`, свой порт), без браузера — `render
not browser-verified` в result.md. Полный `:app:test` — проверяющему.

## Независимая проверка

Браузер (`playwright-cli`): C1–C5 с обоими разрешениями и двумя ролями
(пользователи и роли — как в [T08/checks/002.md](../T08/checks/002.md)).
Проверить, что при неактивных вкладках клик по ним не меняет выбранную
вкладку. `./gradlew :app:test --tests "ru.fgk.ws.app.container.*"` — зелёный.
Порт и процесс `bootRun` — свои; очередь проверок по plan.md.

## Прогресс и продолжение

- [ ] XML: tabSheet с «Описанием» первой вкладкой, группы полей.
- [ ] Контроллер: неактивные вкладки у нового, включение после сохранения.
- [ ] Messages, UI-тест, contracts.md.
- [ ] Передать результат на независимую проверку.

Ближайший шаг: открыть `container-detail-view.xml` и контракт «Пересмотр UI
2026-09-16» в contracts.md.
Препятствия: нет
