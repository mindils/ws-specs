# T13 — Освидетельствование, вкладка «Файлы», карточка договора

Статус: done — итерация 2 принята, [checks/002.md](checks/002.md)
План: [plan.md](../../plan.md)
Зависимости: нет
Сложность: medium — три view с одним общим паттерном видимости панели
просмотра и одной правкой компоновки.
Сложность проверки: hard — браузер: выбор строк с файлом и без, загрузка
акта, длинная карточка договора.
Актуальная проверка: [checks/002.md](checks/002.md)

## Коротко

Доводим остальные формы раздела до тех же правил, что карточка и форма
ремонта: просмотр файла показывается только когда файл есть, без заглушек с
картинкой и без `split`/CSS; форма освидетельствования и вкладка «Файлы»
карточки получают простую компоновку; карточка договора перестаёт рисовать
кнопки поверх формы.

## Результат и контекст

- `container-survey-detail-view.xml` — `split` со `scroller` слева и
  `DisplayFile` справа (`css="min-width: 20%;"`); без файла —
  `displayNotFoundFile`.
- `container-file-fragment.xml` + `ContainerFileFragment` — `split` грид +
  `DisplayFile`; без выбора строки — заглушка.
- `container-contract-detail-view.xml` — `vbox content height="100%"` с формой
  и секцией условий `height="100%"`: та же причина наезда кнопок, что в
  карточке контейнера (замечание 2).
Замечания 2, 4, 5 в [ui-review-2026-09-16.md](../../input/ui-review-2026-09-16.md).
Контракт — раздел «Пересмотр UI 2026-09-16 → Освидетельствование, «Файлы»,
карточка договора» в [contracts.md](../../contracts.md).

## Область и изоляция

Меняет: `container/view/containersurvey/container-survey-detail-view.xml` и
`ContainerSurveyDetailView.java`; `container/view/fragment/containerfile/
container-file-fragment.xml` и `ContainerFileFragment.java`;
`container/view/containercontract/container-contract-detail-view.xml`
(и `ContainerContractDetailView.java`, только если компоновка потребует);
`ContainerSurveyViewsUiTest`, `ContainerContractViewsUiTest`; свои ключи
messages (`containerSurveyDetailView.*`, `containerFileFragment.*`,
`containerContractDetailView.*`); раздел контракта. Не менять: `DisplayFile`
(общий фрагмент, другие хосты пользуются `displayNotFoundFile`), форму файла
`container-file-detail-view.xml`, карточку контейнера (T11). Общие ресурсы:
БД, порт, браузер, gradle daemon, MinIO. Параллельно с T11, T12, T14 в своём
worktree. Проверка после T12.

## Реализация

- Skills: `jmix-create-detail-view`, `jmix-create-fragment`,
  `jmix-verify-api-symbol`, `jmix-add-i18n-keys`, `jmix-style-ui`,
  `jmix-create-test`.
- Освидетельствование: `layout` → `hbox` 100 %/100 % → слева `formLayout`
  одной колонкой (`maxWidth="40em"`, поля как сейчас, при необходимости в
  `scroller`), справа `fragment displayFile` на оставшуюся ширину
  (`expand` / `width="100%"`), видимый только при `surveyAct != null`;
  `detailActions` (OK, Отмена, Скачать акт) внизу. Контроллер:
  `updateFilePreview()` — `setVisible(false)` вместо `displayNotFoundFile`,
  «Скачать акт» активна только при файле; подписка на
  `ItemPropertyChangeEvent("surveyAct")` остаётся; `setContainerReadOnly`
  сохранить. Ключ `containerSurveyDetailView.noFile` удалить, если стал
  неиспользуемым.
- Вкладка «Файлы»: `split` → `hbox` 100 %/100 %: грид (`expand`, `minWidth`
  штатным атрибутом) и `fragment displayFile` (около половины ширины);
  в `ItemChangeEvent`: нет строки или у неё нет файла → `setVisible(false)`,
  иначе `setVisible(true)` + `setFile`. После `refresh()` без выбора панель
  скрыта. Ключ `containerFileFragment.noFile` удалить, если не используется.
  Javadoc фрагмента обновить.
- Карточка договора: обернуть содержимое в `scroller` 100 %/100 %
  (образец `drcontract/view/v-dr-contract-detail-view.xml`) либо дать
  `expand` секции условий с `minHeight` у грида — так, чтобы `detailActions`
  всегда были внизу, а форма и грид прокручивались. Поведение «грид условий
  только у сохранённого договора», `warrantiesHint` и кнопка «Сохранить» не
  меняются.
- Никаких `css="..."`, `split`, новых `classNames`.
- UI-тесты: у нового освидетельствования `displayFile` невидим; карточка
  договора по-прежнему открывается для нового и сохранённого.

## Критерии приёмки

- C1: Освидетельствование без акта: панели просмотра и битой картинки нет,
  форма слева, «Скачать акт» неактивна; после загрузки PDF панель появляется
  справа сразу, кнопка активна; у сохранённой записи с актом панель видна при
  открытии. Из вкладки карточки — контейнер read-only (регрессия T04).
- C2: Вкладка «Файлы»: без выбора грид на всю ширину; выбор строки с PDF
  показывает просмотр; снятие выбора (например, после «Создать» и
  `refresh()`) скрывает; «Скачать» работает (регрессия T03).
- C3: Карточка договора с заполненной формой и гридом условий при 1366×768:
  кнопки «Сохранить / OK / Отмена» внизу, не перекрывают поля; у нового
  договора — подсказка вместо грида, как прежде (регрессия T06).
- C4: В трёх XML нет `split`, `css=`, `details`; сырых `msg://` нет;
  `ContainerSurveyIT`, `ContainerContractWarrantyIT` и UI-тесты пакета
  зелёные.

## Самопроверка исполнителя

Gate 1 по трём XML, `./gradlew :app:compileJava`, `./gradlew spotlessApply`,
`./gradlew :app:test --tests "ru.fgk.ws.app.container.view.*UiTest"`; один
браузерный smoke C1 (свой порт, MinIO), без браузера — `render not
browser-verified`.

## Независимая проверка

Браузер: C1–C3 под `container-edit`, открытие под `container-read`.
`./gradlew :app:test --tests "ru.fgk.ws.app.container.*"`. Очередь — по
plan.md (после T12).

## Прогресс и продолжение

- [x] Освидетельствование: компоновка и видимость панели.
- [x] Вкладка «Файлы»: компоновка и видимость панели.
- [x] Карточка договора: кнопки внизу.
- [x] Messages, UI-тесты, contracts.md.
- [x] Передать результат на независимую проверку.
- [x] Исправить замечание [F01.1](fixes/F01.md) — javadoc
      `ContainerSurveyDetailView` без ссылки на решение пользователя.

Итерация 1 проверена ([checks/001.md](checks/001.md), `fail`): критерии C1–C4 и
открытие под `container-read` подтверждены, осталось одно замечание по
комментариям в коде. Итерация 2 содержала только правку этого javadoc и принята
([checks/002.md](checks/002.md), `pass`): поиск по изменённым файлам дал 0
совпадений, критерии C1–C4 и открытие под `container-read` сняты заново в
браузере и тестами (68 passing, 0 failures).

Ближайший шаг: таск закрыт; по очереди plan.md дальше идёт сквозной
[T15](../T15/task.md).
Препятствия: нет
