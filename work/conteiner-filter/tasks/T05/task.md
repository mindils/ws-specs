# T05 — Справочные ссылки как entity-поля внутри rvkFilter

Статус: done — проверка 001
План: [../../plan.md](../../plan.md)
Зависимости: [T02](../T02/task.md), [T03](../T03/task.md) — оба `done`
Сложность: medium — семь XML по одному паттерну, обновление jar аддона в `libs/`, переписанный UI-тест; контроллеры не меняются
Сложность проверки: hard — живое окружение: серверный поиск опций, lookup-диалог, пресет с entity-условием, браузер под ролями
Актуальная проверка: [checks/001.md](checks/001.md)

## Коротко

Аддон RVK Filter научился полям-ссылкам на сущности, поэтому выпадающие
списки по справочникам, которые в T02 стояли над `rvkFilter` штатными
компонентами, и текстовые поля «по названию» организаций, договоров и
справочников `cnt_*` переносятся внутрь панели как выбор сущности. По
результату оператор в одной панели вводит часть названия модели или
исполнителя и выбирает из подсказок, либо открывает справочник кнопкой
«Выбрать…», а условие сохраняется в личный пресет. Штатных фильтров над
панелью не остаётся. Решение — [Q01](../../questions/Q01.md).

## Результат и контекст

Сейчас на шести основных списках (`container`, `containerrepair`,
`containersurvey`, `containeract`, `containercontract`, `containerwarranty`)
стоит `formLayout id="filterPanel"` со штатными `propertyFilter` +
`entityComboBox` (9 ссылок) и справочные `collection`/`loader` в `<data>`,
а ссылки на `VOrgPassport`, `ContainerContract`, `cnt_*` внутри `rvkFilter`
объявлены текстом по пути (`owner.shortname`, `org.shortname`,
`repContract.contractNum`, `contract.contractNum`, `defect.defectName`,
`defectReason.defectReasonName`, `warrBegin.actTypeName`,
`genChar.charName`); в справочнике «Виды неисправностей» — поле
`defectReason.defectReasonName`. Jar в `libs/` (0.0.1, 2026-09-14) ссылок на
сущности не поддерживает.

Нужно: jar 0.0.2 из рабочего дерева аддона; на семи страницах ссылки —
entity-поля `rvkFilter` по таблице ниже; `filterPanel`, штатные фильтры и
справочные `collection`/`loader` удалены; лишние ключи `filter.*` убраны;
`ContainerRvkFilterUiTest` проверяет entity-условие вместо штатного фильтра.
Правила — план, разделы «Общие решения» (ответы 2026-09-17), «Шаблон
страницы», «Страницы».

| View | Entity-поля (defaultVisible) | Entity-поля (скрытые) | Остаётся как есть |
|---|---|---|---|
| `container-list-view.xml` | `model`, `type`, `size`, `owner` (вместо `ownerShortname`) | `genChar` (вместо `genCharCharName`) | `manufNum`, `manufacturer`, `nextSurveyDate`, скалярные |
| `container-repair-list-view.xml` | `repairType`, `org` (вместо `orgShortname`), `repContract` (вместо `repContractContractNum`) | `defect`, `defectReason` (вместо `defectName`, `defectReasonName`) | `containerContNum` с label, `repStName`, `rejectStName`, `repStInstrName`, даты, суммы |
| `container-survey-list-view.xml` | `surveyType`, `org` | — | `containerContNum` с label, даты, `id` |
| `container-act-list-view.xml` | `actType`, `contract` (вместо `contractContractNum`) | — | `dateSign`, `id`, `actNum`, `comment` |
| `container-contract-list-view.xml` | `contractType`, `org` | — | даты, `id`, `contractNum` |
| `container-warranty-list-view.xml` | `warrType`, `contType`, `contract` с `label="msg://containerWarrantyListView.filter.contract"` | `warrBegin` (вместо `warrBeginActTypeName`) | `id` (EQUAL, label), `warrDuration`, `extWarrDuration`, `inspInDays`, `penalty` |
| `cnt-defect-list-view.xml` | — | `defectReason` (вместо `defectReasonName`) | `defectName` |

Entity-поле: `<flt:propertyFilter id="<ссылка>" property="<ссылка>" .../>`
без `type`, `operation`, `lookup`, `label` (автотип `entity`, EQUAL,
`lookup="auto"`, подпись из метаданных ссылки). Исключение — `contract` на
гарантиях: метаданные дают «Гарантия к договору», оставить ключ «Договор».
`searchProperty` не меняется. `order`: entity-поля первыми в порядке
прежних выпадающих списков, затем остальные в прежнем порядке, шаг 10.

## Область и изоляция

Меняются: семь XML выше в
`app/src/main/resources/ru/fgk/ws/app/container/view/`;
`libs/rvk-filter-0.0.2.jar`, `libs/rvk-filter-starter-0.0.2.jar`,
`libs/README.md` (прежняя пара 0.0.1 убирается из Git через `git rm`);
`rvkFilterVersion` в `app/build.gradle`; ключи `…ListView.filter.*`
контейнерных view в `app/src/main/resources/ru/fgk/ws/app/messages_ru.properties`;
`app/src/test/java/ru/fgk/ws/app/container/view/ContainerRvkFilterUiTest.java`.
Не меняются: контроллеры `*ListView.java`, роли, detail views, остальные 12
справочников, аддон в `../rvk-filter` (только сборка), другие пользователи
jar-а (`nsi/view/vdepo`). Коммиты в `rvk-ws` и в `../rvk-filter` — только по
указанию пользователя; `git rm` старых jar — staging.

Один исполнитель, одна сессия; занимает сборку аддона, БД, gradle daemon,
порт приложения (профиль `local` — 8082) и браузер. Параллельных тасков нет.

## Реализация

1. Прочитать skills `jmix-create-list-view`, `jmix-add-i18n-keys`,
   `jmix-ide-static-analysis`, `jmix-create-test`; в аддоне —
   `docs/xml-api.md` «Ссылки на сущности», `docs/examples/entity-view.xml`,
   `docs/compatibility.md`; `libs/README.md`.
2. Jar 0.0.2 по `libs/README.md` (аддон — `/home/mindils/data/dev/fgk/rvk-filter`,
   из worktree это `../../../../rvk-filter`):

   ```bash
   (cd /home/mindils/data/dev/fgk/rvk-filter && ./gradlew clean test :rvk-filter:jar :rvk-filter-starter:jar -PaddonVersion=0.0.2)
   cp /home/mindils/data/dev/fgk/rvk-filter/rvk-filter/build/libs/rvk-filter-0.0.2.jar libs/
   cp /home/mindils/data/dev/fgk/rvk-filter/rvk-filter-starter/build/libs/rvk-filter-starter-0.0.2.jar libs/
   git rm libs/rvk-filter-0.0.1.jar libs/rvk-filter-starter-0.0.1.jar
   unzip -p libs/rvk-filter-0.0.2.jar rvk-filter.xsd | grep -c lookup   # > 0
   ```

   `app/build.gradle`: `rvkFilterVersion = '0.0.2'`. `libs/README.md`: абзац
   про 0.0.2 — собрана 2026-09-17 из рабочего дерева аддона (uncommitted),
   добавляет `entity`/`entityList`, `lookup`, `optionsLimit`, `itemsQuery`;
   changelog аддона не менялся. Если тесты аддона красные — не чинить аддон,
   записать в `result.md` и остановиться (вопрос пользователю).
3. Семь XML: удалить `formLayout id="filterPanel"` с комментарием о порядке,
   `responsiveSteps` и справочные `collection`/`loader` из `<data>`; в
   `flt:filters` заменить/добавить entity-поля по таблице, перенумеровать
   `order`. Проверить, что `<data>` не содержит неиспользуемых контейнеров, а
   fetchPlan основной коллекции не тронут.
4. `messages_ru.properties`: удалить `containerListView.filter.owner`,
   `containerRepairListView.filter.org`,
   `containerRepairListView.filter.repContract`,
   `containerSurveyListView.filter.org`,
   `containerContractListView.filter.org`,
   `containerActListView.filter.contract`,
   `cntDefectListView.filter.defectReason` (подписи совпадают с атрибутами
   entity). Оставить `containerRepairListView.filter.container`,
   `containerSurveyListView.filter.container`,
   `containerWarrantyListView.filter.id`,
   `containerWarrantyListView.filter.contract`. Сверить в обе стороны:
   `grep -n 'ListView\.filter\.' … | grep -i 'container\|cnt'` против `msg://`
   в XML.
5. `ContainerRvkFilterUiTest`: заменить
   `containerList_dictionaryFilterIntersectsSearchAndSurvivesReset` (helper
   `modelFilter` и импорт `PropertyFilter` удалить) на
   `containerList_entityConditionIntersectsSearch`: состояние
   `FilterState.of("AAA" + marker, List.of("model"), Map.of("model", value("\"" + wantedModel.getId() + "\"")), null)`
   → один контейнер; после `filter.reset()` — все три контейнера с
   маркером (условие снято). Добавить `repairList_contractEntityCondition`:
   два `ContainerContract` с маркером (уборка `delete from cnt_contract`),
   два ремонта с разными договорами, условие `repContract` по id первого →
   один ремонт (ссылка не из `cnt_*`). Значение entity — строка с id
   (образец —
   `/home/mindils/data/dev/fgk/rvk-filter/rvk-filter/src/test/java/ru/fgk/component/rvkfilter/condition/EntityReferenceIntegrationTest.java`).
   Javadoc класса обновить: штатного фильтра больше нет.
6. Если после запуска в браузере у entity-поля нет подсказок и кнопки
   «Выбрать…» — dev bundle Vaadin не пересобрался: удалить gitignored
   `app/src/main/bundles` и перезапустить `bootRun`; записать в `result.md`.

## Критерии приёмки

- C1: на всех 19 списках раздела нет `<propertyFilter` вне namespace `flt:`
  и нет `filterPanel`; на семи страницах entity-поля по таблице, справочных
  `collection` в `<data>` нет.
- C2: `ContainerRvkFilterUiTest` зелёный (4 теста): поиск по
  `container.contNum`, `dateRange`, entity-условие `model` + поиск и снятие
  по Reset, entity-условие `repContract`.
- C3: `./gradlew :app:test --tests 'ru.fgk.ws.app.container.*' --tests 'ru.fgk.ws.app.nsi.view.vdepo.*' --tests 'ru.fgk.ws.app.security.UiMinimalRoleTest'`
  и `./gradlew spotlessCheckAll` зелёные на jar 0.0.2.
- C4: сырых `msg://` нет; ключей `…ListView.filter.*` контейнерных view без
  ссылки из XML нет; `libs/` содержит только пару 0.0.2, `rvkFilterVersion`
  = `0.0.2`, `libs/README.md` описывает поставку.
- C5 (браузер): реестр — поле «Модель» даёт подсказки по вводу, «Выбрать…»
  открывает `cnt_CntModel.list` и возвращает выбор, грид сужается вместе с
  поиском, чип показывает название; Reset снимает; ремонты — «Исполнитель»
  ищет по вводу (кнопки выбора нет — у `VOrgPassport` нет list view),
  «Договор на ремонт» выбирается через lookup; пресет с entity-условием
  сохраняется и после переоткрытия показывает название, а не id; 0 `ERROR` в
  логе.

## Самопроверка исполнителя

```bash
./gradlew spotlessApply :app:compileJava :app:compileTestJava
./gradlew :app:test --tests 'ru.fgk.ws.app.container.view.*'
```

Gate 1 — IDE-инспекция каждого изменённого XML либо `jmix-ide-static-analysis`.
Один smoke в браузере (реестр: подсказки в поле «Модель», выбор, Apply).
Полный набор и роли — проверяющему.

## Независимая проверка

- Перед тестами: `docker info`, `(cd docker && docker compose ps)`,
  `app/src/test/resources/application-test-local.properties`. Команды C3.
- Проверить C4 механически: `grep -rn '<propertyFilter' app/src/main/resources/ru/fgk/ws/app/container/view/`
  пусто; `ls libs/`; `grep rvkFilterVersion app/build.gradle`.
- Браузер (`bootRun` в фоне, готовность по `Started AppApplication` и `200`
  на `/local-login`, порт 8082, `playwright-cli`): сценарии C5 под
  `user_read` (`container-read` + `ui-minimal`) и справочник «Виды
  неисправностей» под `user_nsi` (скрытое поле «Причина неисправности» —
  добавить условие, выбрать, Apply). Негативно: пустое entity-поле в
  активных условиях не меняет выборку; Reset после выбора возвращает полный
  список. Регрессия: lookup контейнера из формы ремонта, копирование и
  Excel-экспорт на реестре, `v-depo` список открывается и фильтрует.
  Погасить только свой процесс. Без браузера — `render not browser-verified`.

## Прогресс и продолжение

- [x] Jar 0.0.2 в `libs/`, `rvkFilterVersion`, README.
- [x] Семь XML и `messages_ru.properties`.
- [x] `ContainerRvkFilterUiTest` переписан, тесты зелёные.
- [x] Smoke в браузере на реестре: подсказки, «Выбрать…», Apply — 8 → 3 строки.
- [x] Передать результат на независимую проверку.

Ближайший шаг: таск принят проверкой [checks/001.md](checks/001.md); дальше
повторный проход [T04](../T04/task.md).
Препятствия: нет
