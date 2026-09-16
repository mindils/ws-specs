# T02 — rvkFilter и выпадающие списки на шести основных страницах

Статус: todo
План: [../../plan.md](../../plan.md)
Зависимости: нет
Сложность: medium — шесть XML с новыми data-контейнерами и составом полей по контракту, новый UI-тест с программным Apply, без изменения контроллеров
Сложность проверки: hard — живое окружение: браузер, совместная работа двух фильтров, пресеты
Актуальная проверка: нет

## Коротко

На страницах «Реестр контейнеров», «Ремонты», «Освидетельствования», «Акты»,
«Договоры» и «Гарантийные условия» панели штатных `propertyFilter`
заменяются на `flt:rvkFilter` (строка поиска, условия, пресеты). Фильтры по
справочникам `cnt_*` остаются штатными компонентами над `rvkFilter`, но
превращаются из текста в выбор из справочника. По результату оператор ищет
ремонт по номеру контейнера в строке поиска, добавляет диапазон дат и вид
ремонта из списка и сохраняет это как личный фильтр.

## Результат и контекст

Файлы `app/src/main/resources/ru/fgk/ws/app/container/view/`:
`container/container-list-view.xml`,
`containerrepair/container-repair-list-view.xml`,
`containersurvey/container-survey-list-view.xml`,
`containeract/container-act-list-view.xml`,
`containercontract/container-contract-list-view.xml`,
`containerwarranty/container-warranty-list-view.xml`. Состав полей, поиск и
выпадающие списки — таблица «Страницы» и «Шаблон страницы» в плане; там же
правило порядка (штатные фильтры выше `rvkFilter`) и ловушка `container_`.
Прежние ключи `containerXxxListView.filter.*` в `messages_ru.properties`
переиспользуются как `label` полей по пути (`owner`, `org`, `container`,
`contract`, `repContract`, `contType`…), ключи «с/по» и ключи ушедших
текстовых фильтров удаляются.

## Область и изоляция

Шесть XML выше, ключи `containerListView.filter.*`,
`containerRepairListView.filter.*`, `containerSurveyListView.filter.*`,
`containerActListView.filter.*`, `containerContractListView.filter.*`,
`containerWarrantyListView.filter.*` в `messages_ru.properties`, новый тест
`app/src/test/java/ru/fgk/ws/app/container/view/ContainerRvkFilterUiTest.java`
и при необходимости расширение существующих `Container*ViewsUiTest`
(открытие списков актов и гарантий). Контроллеры `*ListView.java`, роли,
detail views, вкладки карточки не меняются. Параллельно с T01 и T03;
`messages_ru.properties` перечитывать перед правкой. Общие ресурсы: БД,
gradle daemon, порт 8080, браузер — проверки после T03.

## Реализация

1. Прочитать skills `jmix-create-list-view`, `jmix-add-i18n-keys`,
   `jmix-create-test`, `jmix-ide-static-analysis`; образцы
   `nsi/view/vdepo/v-depo-list-view.xml` и
   `pt/view/ptrepairclaim/pt-repair-claim-list-view.xml` (`contractFilter`).
2. Для каждого выпадающего списка: `collection` + `loader readOnly` по
   справочнику в `<data>` (`fetchPlan extends="_instance_name"`, `order by`
   поле названия), `propertyFilter property="<ссылка>" operation="EQUAL"` с
   `entityComboBox metaClass itemsContainer` и `entity_clear`. Оставшийся
   `formLayout id="filterPanel"` содержит только эти фильтры; `responsiveSteps`
   сохраняются. Подпись — из метаданных ссылки; если она неудачна, взять
   существующий ключ `filter.model|type|size|…`.
3. `flt:rvkFilter` сразу после `filterPanel`, перед `buttonsPanel`;
   `searchProperty` и поля по таблице плана; даты `type="dateRange"`, `id`
   гарантии `operation="EQUAL"`, boolean `type="boolean"`, пути — с `label`.
   Обязательно: штатные фильтры в XML выше `rvkFilter`.
4. `ContainerRvkFilterUiTest` (`BaseUiTest`, данные через `DataManager`,
   уборка в `@AfterEach` через `JdbcTemplate`, образец —
   `ContainerRegistryViewsUiTest`): компонент —
   `UiComponentUtils.findComponent(view, "rvkFilter")` → `RvkFilter`; state —
   `FilterState.of(query, activeFieldIds, values, null)`, значения —
   `FilterValue` (образец построения —
   `../rvk-filter/rvk-filter/src/test/java/ru/fgk/component/rvkfilter/RvkFilterLifecycleIntegrationTest.java`,
   helper `amount(...)`); после `filter.apply()` проверять
   `CollectionContainer.getItems()`. Сценарии:
   - ремонты: два контейнера с ремонтами, `query` = часть номера первого →
     остаётся один ремонт (закрывает ловушку `container_`);
   - освидетельствования: поле `dateBegin` с диапазоном, попадает одна
     запись;
   - реестр: две модели, у штатного `modelFilter` установлено значение
     (`PropertyFilter.setValue`) и одновременно `query` по номеру — в гриде
     пересечение; после `filter.reset()` условие модели продолжает
     действовать (base-условие сохранено).
   Если фильтр по `container.contNum` падает из-за префикса `container_`,
   применить запасной `jpqlFilter` из плана и записать это в `result.md`.
5. Убедиться, что списки актов и гарантий открываются каким-либо UI-тестом;
   если нет — добавить тесты по образцу `containerListView_displays`.

## Критерии приёмки

- C1: на шести страницах есть `rvkFilter` с поиском и полями по таблице
  плана, старых текстовых и «с/по» фильтров нет; выпадающие списки по
  справочникам стоят над `rvkFilter` и работают.
- C2: `ContainerRvkFilterUiTest` зелёный: поиск по `container.contNum`,
  `dateRange`, пересечение штатного фильтра и `rvkFilter`, сохранение
  base-условия после Reset.
- C3: все шесть списков открываются UI-тестами; сырых `msg://` нет; в
  `messages_ru.properties` не осталось неиспользуемых ключей `filter.*`
  этих view.
- C4: `spotlessCheckAll` зелёный; ни один XML не пуст.

## Самопроверка исполнителя

```bash
./gradlew spotlessApply :app:compileJava :app:compileTestJava
./gradlew :app:test --tests 'ru.fgk.ws.app.container.view.*'
```

Один smoke в браузере по желанию (реестр: поиск по номеру); полный набор и
роли — проверяющему.

## Независимая проверка

- `./gradlew :app:test --tests 'ru.fgk.ws.app.container.*'`,
  `./gradlew spotlessCheckAll`.
- Браузер (`bootRun` в фоне, `/actuator/health` UP, `playwright-cli`): под
  `user`/`user` пройти все шесть страниц: поиск сужает грид; добавить условие
  (дата-диапазон, текст по организации, «ИД» гарантии); выбрать значение в
  выпадающем списке справочника — грид сужается вместе с условием `rvkFilter`;
  ✕ на чипе снимает условие; Reset; открыть реестр как lookup из формы
  ремонта (кнопка выбора контейнера) — `rvkFilter` работает в диалоге;
  сохранить личный пресет, переоткрыть страницу, выбрать его. В серверном логе
  0 `ERROR`, сырых `msg://` нет. Без браузера — `render not browser-verified`.
- Негативно: пустой поиск и пустые условия не меняют выборку; неверная дата
  в поле не ломает страницу (сообщение аддона, прежние данные).
- Регрессия: копирование, удаление, Excel-экспорт на реестре и ремонтах
  работают как прежде.

## Прогресс и продолжение

- [ ] Реестр, ремонты, освидетельствования.
- [ ] Акты, договоры, гарантии.
- [ ] Ключи messages согласованы.
- [ ] `ContainerRvkFilterUiTest` и открытие актов/гарантий тестом.
- [ ] Передать результат на независимую проверку.

Ближайший шаг: открыть `container-repair-list-view.xml`, образцы VDepo и
`pt-repair-claim-list-view.xml`.
Препятствия: нет
