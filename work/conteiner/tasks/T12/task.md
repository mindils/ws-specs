# T12 — Форма ремонта: вкладки вместо аккордеонов

Статус: done — проверка [checks/002.md](checks/002.md)
План: [plan.md](../../plan.md)
Зависимости: нет
Сложность: medium — большая перекомпоновка XML, логика вкладок и валидации в
контроллере; образцы tabSheet и просмотра файла в проекте есть.
Сложность проверки: hard — браузер: загрузка PDF, валидация с другой вкладки,
обе точки входа (список и вкладка карточки).
Актуальная проверка: [checks/002.md](checks/002.md)

## Коротко

Форму ремонта контейнера собираем из пяти вкладок вместо шести аккордеонов:
«Ремонт», «Исполнитель и договор», «Документы и стоимость», «Уведомление
завода», «Документ». Просмотр документа показывается только когда файл есть;
заглушка с битой картинкой убирается. Если сохранение не прошло валидацию,
форма сама переключается на вкладку «Ремонт», где лежит обязательная «Дата
браковки».

## Результат и контекст

Сейчас `container-repair-detail-view.xml` — `split` (слева `scroller` с шестью
`details`, справа фрагмент `DisplayFile` с `css="min-width: 20%;"`), контроллер
`ContainerRepairDetailView` при отсутствии файла зовёт
`displayFile.displayNotFoundFile(...)` — картинка битая (см. T14). Замечания 3,
4, 5 в [ui-review-2026-09-16.md](../../input/ui-review-2026-09-16.md).
Порядок полей старой формы — [instruction-erk.md](../../input/instruction-erk.md),
строка про `image1, image2`. Целевой контракт и таблица распределения полей —
раздел «Пересмотр UI 2026-09-16 → Форма ремонта» в [contracts.md](../../contracts.md).

## Область и изоляция

Меняет: `app/src/main/resources/ru/fgk/ws/app/container/view/containerrepair/container-repair-detail-view.xml`,
`app/src/main/java/ru/fgk/ws/app/container/view/containerrepair/ContainerRepairDetailView.java`,
`app/src/test/java/ru/fgk/ws/app/container/view/ContainerRepairViewsUiTest.java`,
свои ключи в `messages_ru.properties` (префикс
`ru.fgk.ws.app.container.view.containerrepair/containerRepairDetailView.*`),
раздел контракта в `contracts.md`. Не менять: список ремонтов, фрагмент
вкладки `ContainerRepairFragment` (он открывает ту же форму через
`withViewConfigurer(view -> view.setContainerReadOnly(true))` — метод
сохранить), `DisplayFile`. Общие ресурсы: БД, порт, браузер, gradle daemon,
MinIO. Параллельно с T11, T13, T14 в своём worktree. Проверка после T11.

## Реализация

- Skills: `jmix-create-detail-view`, `jmix-verify-api-symbol`,
  `jmix-add-i18n-keys`, `jmix-style-ui`, `jmix-create-test`.
- `layout` → `tabSheet id="repairTabSheet" width="100%" height="100%"
  themeNames="small"` → `hbox detailActions` (OK, Отмена, Скачать документ).
  `split`, `scroller formScroller`, `vbox formSections`, все `details` —
  удалить.
- Каждая вкладка: `scroller` (100 %/100 %, VERTICAL) → `formLayout`
  (`dataContainer="containerRepairDc"`, 1 / 2 колонки при ≥40em). Все id полей,
  `itemsQuery`, `actions`, `required`, `readOnly` — как сейчас. Распределение:
  | Вкладка (id, ключ `tab.*`) | Поля (id) |
  |---|---|
  | `repairTab` «Ремонт» | `idField`, `containerField`*, `repairTypeField`, `defectReasonField`, `defectField`, `commentField`, `roofUpgradeField`, `rejectDateField`*, `rejectStField`, `departDateField`, `dateBeginField`, `dateEndField`, `returnDateField`, `dateNextField` |
  | `contractTab` «Исполнитель и договор» | `orgField`, `repContractField`, `repStField`, `repByWarrField`, `warrOnRepField` |
  | `documentsTab` «Документы и стоимость» | `h5` «Проверка документов» (`section.documents`): `docsSubmissionDateField`, `docsVerificationDateField`, `docsVerificationResultField`, `rejectionReasonField`; `h5` «Стоимость ремонта» (`section.costs`): `repCostField`, `vatField`, `vatRubField`, `costWithVatField` |
  | `manufacturerTab` «Уведомление завода» | `manufNotifDateField`, `repStInstrField`, `manufAnswDateField`, `manufReNotifDateField` |
  | `fileTab` «Документ» | `vbox` 100 %/100 %: `documentField` (`fileStorageUploadField`, `maxWidth` около 40em) и под ним `fragment displayFile` на оставшуюся высоту |
  Подзаголовки `h5` внутри `formLayout` с `colspan="2"`.
- Просмотр: `updateFilePreview()` при отсутствии файла —
  `displayFile.setVisible(false)`, `downloadButton.setEnabled(false)`; при
  файле — `setVisible(true)`, `setFile(document)`, кнопка активна.
  `displayNotFoundFile` больше не вызывать. Подписка на
  `ItemPropertyChangeEvent("document")` остаётся.
- Валидация: в `InitEvent` через `addValidationEventListener` (или другой
  подтверждённый по `jmix-verify-api-symbol` хук `StandardDetailView`,
  срабатывающий при ошибках валидации перед сохранением) при непустых ошибках
  выбирать `repairTab` (`repairTabSheet.setSelectedTab(...)`), чтобы
  подсвеченное поле было видно.
- Messages: добавить `tab.repair|contract|documents|manufacturer|file`;
  оставить `section.documents`, `section.costs`, `downloadButton.text`,
  `download.noFile`, `title`; удалить `section.repair|dates|contract|
  manufacturer|file` и `noFile`, если не используются.
- Javadoc класса и комментарии XML — про пять вкладок и просмотр только при
  файле; без ссылок на артефакты работы.
- Никаких `css="..."`, `split`, новых `classNames`.
- `ContainerRepairViewsUiTest`: дополнить проверкой, что у формы пять вкладок
  и выбрана первая; `displayFile` невидим у ремонта без документа.

## Критерии приёмки

- C1: Форма из списка ремонтов: пять вкладок в заданном порядке, «Ремонт»
  выбрана; все 33 поля матрицы `cnt_repair` присутствуют и привязаны
  (сверить по таблице выше и по [contracts.md](../../contracts.md)).
- C2: Заполнить контейнер, оставить «Дата браковки» пустой, перейти на
  «Документы и стоимость», нажать OK → форма переключилась на «Ремонт», поле
  подсвечено, запись не сохранена; заполнить дату → сохраняется.
- C3: Вкладка «Документ» без файла: панели просмотра и битой картинки нет;
  после загрузки PDF просмотр появляется сразу и «Скачать документ» активна;
  после очистки файла панель исчезает, кнопка неактивна. У сохранённого
  ремонта с документом панель видна при открытии.
- C4: Из вкладки «Ремонты» карточки контейнера открывается та же форма, поле
  контейнера read-only, после сохранения грид вкладки обновляется (регрессия
  T07).
- C5: Кнопки OK/Отмена/Скачать всегда внизу диалога и страницы
  (`/container-repairs/:id`), не перекрывают поля при 1366×768.
- C6: В XML нет `details`, `split`, `css=`; в браузере нет сырых `msg://`;
  `ContainerRepairIT` и UI-тесты пакета зелёные.

## Самопроверка исполнителя

Gate 1 по XML, `./gradlew :app:compileJava`, `./gradlew spotlessApply`,
`./gradlew :app:test --tests "ru.fgk.ws.app.container.view.*UiTest" --tests
"ru.fgk.ws.app.container.ContainerRepairIT"`; один браузерный smoke C2 или C3
(свой порт, MinIO из docker compose), без браузера — `render not
browser-verified`.

## Независимая проверка

Браузер: C1–C5 из обеих точек входа под ролью `container-edit`, плюс открытие
под `container-read`. Тестовый PDF — любой, сгенерированный во временном
каталоге сессии. `./gradlew :app:test --tests "ru.fgk.ws.app.container.*"`.
Порт, процесс и очередь — по plan.md (после T11).

## Прогресс и продолжение

- [x] XML: tabSheet, пять вкладок, распределение полей.
- [x] Контроллер: просмотр только при файле, переключение вкладки при
      ошибке валидации.
- [x] Messages, UI-тест, contracts.md.
- [x] Передать результат на независимую проверку.
- [x] [F01](fixes/F01.md): комментарий про ручной ввод стоимостей без ссылки
      на решение пользователя.

Ближайший шаг: нет — таск принят проверкой [checks/002.md](checks/002.md):
[F01](fixes/F01.md) исправлен, критерии C1–C6 и открытие под ролью чтения
подтверждены заново. Следующий таск очереди — [T13](../T13/task.md).
Препятствия: нет
