# RVK Filter на страницах раздела «Контейнеры»

Состояние: active
Дата согласования: 2026-09-16
Предыдущая работа: [conteiner/summary.md](../conteiner/summary.md)

## Цель и границы

Раздел «Контейнеры» (ветка `f/container`, worktree
`../worktrees/rvk-ws/cyan-fennel/rvk-ws`; в `main` кода раздела нет) сдан с
панелями штатных `propertyFilter` на 19 list view: реестр, ремонты,
освидетельствования, акты, договоры, гарантийные условия и 13 справочников
`cnt_*`. Пользователь сделал аддон фильтрации `rvk-filter`
(`../rvk-filter`), он уже подключён в приложение как jar
(`libs/rvk-filter-0.0.1.jar`, `libs/rvk-filter-starter-0.0.1.jar`,
`app/build.gradle`, include changelog-а в `liquibase/changelog.xml`), образец
использования — `nsi/view/vdepo/v-depo-list-view.xml`.

Результат: на всех 19 списках раздела стоит `flt:rvkFilter` (строка поиска,
набор условий, пресеты) вместо прежних панелей; фильтры по справочникам
`cnt_*` остаются штатными компонентами над `rvkFilter` и становятся выбором
из справочника; личные пресеты доступны каждому пользователю UI через
минимальную роль.

Не входит: доработка самого аддона (entity picker, выбор операции, AND/OR);
перенос справочных фильтров внутрь `rvkFilter` (пользователь сделает после
доработки аддона); вкладки карточки контейнера (там фильтров нет); слияние
`f/container` в `main`; переключатель «старые/новые фильтры» из ветки
`f/new-filter`.

## Материалы

- Аддон: `../rvk-filter/README.md`, `docs/xml-api.md`, `docs/java-api.md`,
  `docs/persistence-and-security.md`, `docs/compatibility.md`, примеры
  `docs/examples/*.xml`. Jar в `libs/` собран из рабочего дерева аддона и
  содержит `operation`, `valueList`, `configurationKey` (проверено по XSD и
  классам внутри jar 2026-09-16).
- Образец `rvkFilter` в проекте: `nsi/view/vdepo/v-depo-list-view.xml`,
  тест `nsi/view/vdepo/VDepoListViewTest.java`.
- Образец штатного фильтра-выбора из справочника:
  `pt/view/ptrepairclaim/pt-repair-claim-list-view.xml` (`contractFilter` с
  `entityComboBox` и `itemsContainer`).
- Текущие списки раздела:
  `app/src/main/resources/ru/fgk/ws/app/container/view/**/*-list-view.xml`,
  контракты закрытой работы — [conteiner/contracts.md](../conteiner/contracts.md),
  раздел «Списки».
- UI-тесты раздела: `app/src/test/java/ru/fgk/ws/app/container/view/*UiTest`.

## Общие решения

Ответы пользователя 2026-09-16:

- Старые панели `propertyFilter` заменяются на `rvkFilter`; неиспользуемые
  ключи `…ListView.filter.*` удаляются из `messages_ru.properties`.
- Пресеты (личные фильтры) должны быть у всех, кто имеет доступ к странице:
  право даётся минимальной роли — `app/security/UiMinimalRole.java`
  объявляется `extends RvkFilterUserRole`
  (`ru.fgk.component.rvkfilter.security`). Row-level роль
  `rvk-filter-config-row-level` в resource-роль не наследуется; сервис
  пресетов (`RvkFilterConfigServiceImpl`) сам ограничивает выборку
  `username is null or username = :current` и проверяет владельца при записи,
  поэтому row-level роль — дополнительное ужесточение, которое администратор
  назначает отдельно. Это правило эксплуатации, а не код.
- Работа ведётся прямо в ветке `f/container` (worktree cyan-fennel) поверх
  незакоммиченных файлов закрытой работы: их не откатывать, коммиты — только
  по указанию пользователя.
- Фильтры по справочникам `cnt_*` (реестр: модель, тип, размер; ремонты: вид
  ремонта; освидетельствования: вид; акты: тип акта; договоры: тип договора;
  гарантии: тип гарантии, тип контейнера) остаются штатными `propertyFilter`
  над `rvkFilter` и становятся выбором из справочника: `property` — сама
  ссылка, `operation="EQUAL"`, внутри `entityComboBox` с `itemsContainer`.
  Внутри `rvkFilter` эти поля текстом не дублируются.

Технические решения (основание — код аддона и Jmix 3.0.x, проверено
2026-09-16):

- **Порядок в XML: штатные `propertyFilter` объявляются выше
  `flt:rvkFilter`.** `RvkFilter.setDataLoader` захватывает
  `loader.getCondition()` как base-условие (`FilterLoaderConditions.forLoader`),
  а штатный фильтр добавляет своё условие в корневой `LogicalCondition`
  loader-а при создании (`SingleFilterComponentBase.updateDataLoaderCondition`)
  и потом меняет только значение параметра. Штатный фильтр, объявленный ниже
  `rvkFilter`, потерялся бы при первом Apply. Совместная работа обоих на одном
  loader закрывается UI-тестом (T02).
- Ловушка префикса `container_` (см. contracts.md закрытой работы, T04) для
  `rvkFilter` не действует: `AbstractDataLoadCoordinator.configureAutomatically`
  сканирует параметры условий при инициализации view, а `rvkFilter`
  добавляет своё условие в PreLoad первой загрузки. Но
  `PropertyCondition.createWithValue` даёт параметр `container_contNumXXXX`,
  поэтому фильтр по `container.contNum` в ремонтах и освидетельствованиях
  проверяется тестом; запасной вариант — `jpqlFilter` с
  `{E}.container.contNum like ?`, `type="text"`,
  `parameterClass="java.lang.String"` (префикс параметра аддона `rvkflt_p`).
- Id компонента везде `rvkFilter`; ключ пресетов `<viewId>.rvkFilter`
  образуется сам, `configurationKey` не задаётся. `enableSavedFilters` по
  умолчанию (включены).
- Даты — одно поле `type="dateRange"` вместо пары «с/по»; числа — по
  метаданным (`numberRange`); «ИД» гарантии — `operation="EQUAL"` (один ввод);
  boolean — `type="boolean"`. Подписи полей по пути через ссылку — явный
  `label="msg://…"` (для прямых свойств подпись берётся из метаданных).
- Состав полей: `defaultVisible="true"` у полей прежних панелей (минус ссылки,
  ушедшие в выпадающие списки); остальные скалярные колонки грида и
  `<ссылка>.<название>` для ссылок вне выпадающих списков — скрытые поля
  (`defaultVisible` по умолчанию). Поля аудита и `FileRef` не добавляются.
- Id полей `rvkFilter`: имя свойства; для пути — camelCase без точки
  (`ownerShortname`, `containerContNum`). `order` — шаг 10 в порядке прежних
  панелей.
- `dataLoadCoordinator auto`, `settings auto`, `urlQueryParameters pagination`,
  панель кнопок, грид, lookup-действия и Java-контроллеры списков не
  меняются. `formLayout id="filterPanel"` остаётся только там, где есть
  выпадающие списки, иначе удаляется.

### Шаблон страницы

```xml
<view xmlns="http://jmix.io/schema/flowui/view"
      xmlns:flt="http://fgk.ru/schema/rvk-filter" ...>
  <data>
    <collection id="repairsDc" .../>   <!-- как сейчас -->
    <collection id="repairTypesDc"
                class="ru.fgk.ws.app.container.entity.CntRepairType">
      <fetchPlan extends="_instance_name"/>
      <loader id="repairTypesDl" readOnly="true">
        <query><![CDATA[select e from cnt_CntRepairType e order by e.repairTypeName]]></query>
      </loader>
    </collection>
  </data>
  <layout>
    <formLayout id="filterPanel" width="100%">   <!-- только справочные ссылки -->
      <responsiveSteps>...как сейчас...</responsiveSteps>
      <propertyFilter id="repairTypeFilter" property="repairType" operation="EQUAL"
                      operationTextVisible="false" labelPosition="TOP"
                      dataLoader="repairsDl" width="100%">
        <entityComboBox metaClass="cnt_CntRepairType" itemsContainer="repairTypesDc" width="100%">
          <actions><action id="entityClearAction" type="entity_clear"/></actions>
        </entityComboBox>
      </propertyFilter>
    </formLayout>
    <flt:rvkFilter id="rvkFilter" dataLoader="repairsDl" searchProperty="container.contNum" width="100%">
      <flt:filters>
        <flt:propertyFilter id="containerContNum" property="container.contNum"
                            label="msg://containerRepairListView.filter.container"
                            defaultVisible="true" order="10"/>
        <flt:propertyFilter id="rejectDate" property="rejectDate" type="dateRange"
                            defaultVisible="true" order="50"/>
        ...
      </flt:filters>
    </flt:rvkFilter>
    <hbox id="buttonsPanel" .../>   <!-- далее без изменений -->
```

### Страницы

| View | searchProperty | Выпадающие списки (штатно) | defaultVisible в rvkFilter |
|---|---|---|---|
| `cnt_Container.list` | `contNum` | `model`, `type`, `size` | `manufNum`, `manufacturer`, `owner.shortname`, `nextSurveyDate` |
| `cnt_ContainerRepair.list` | `container.contNum` | `repairType` | `container.contNum`, `org.shortname`, `repContract.contractNum`, `rejectDate`, `dateBegin`, `dateEnd` |
| `cnt_ContainerSurvey.list` | `container.contNum` | `surveyType` | `container.contNum`, `org.shortname`, `dateBegin`, `dateEnd`, `dateNext` |
| `cnt_ContainerAct.list` | `actNum` | `actType` | `contract.contractNum`, `dateSign` |
| `cnt_ContainerContract.list` | `contractNum` | `contractType` | `org.shortname`, `dateSign`, `dateBegin`, `dateEnd` |
| `cnt_ContainerWarranty.list` | `contract.contractNum` | `warrType`, `contType` | `id` (EQUAL), `contract.contractNum` |
| 13 `cnt_Cnt*.list` | поле названия | нет, `filterPanel` удаляется | поле названия |

Поля названия справочников: `CntModel.model`, `CntContainerType.typeName`,
`CntContainerSize.code`, `CntGeneralCharacteristic.charName`,
`CntPropertyType.propTypeName`, `CntFileType.fileTypeName`,
`CntSurveyType.surveyTypeName`, `CntRepairType.repairTypeName`,
`CntDefectReason.defectReasonName`, `CntDefect.defectName`,
`CntActType.actTypeName`, `CntContractType.contractTypeName`,
`CntWarrantyType.warrTypeName`. Остальные колонки гридов справочников —
скрытые поля (`CntDefect.defectReason` — скрытое поле по пути
`defectReason.defectReasonName`).

Скрытые поля основных страниц: остальные скалярные колонки грида (реестр —
`contNum`, массы, `capacity`, `constrDate`, `roofUpgrade`, `roofUpgradeDate`,
`genChar.charName`; ремонты — `id`, прочие даты, `defect.defectName`,
`defectReason.defectReasonName`, станции `repSt.stName`, `rejectSt.stName`,
`repStInstr.stName`, стоимости, `vat`, текстовые поля, `roofUpgrade`;
акты — `id`, `actNum`, `comment`; договоры — `id`, `contractNum`; гарантии —
`warrDuration`, `extWarrDuration`, `inspInDays`, `penalty`,
`warrBegin.actTypeName`). Исполнитель может сократить список, если поле в
аддоне не поддерживается — с записью в `result.md`.

## Критерии всей работы

- На всех 19 списках раздела есть `rvkFilter` со строкой поиска и полями по
  таблице «Страницы»; прежних панелей `propertyFilter` нет, кроме выпадающих
  списков по справочникам `cnt_*` над `rvkFilter`.
- Поиск и условия `rvkFilter` фильтруют грид; выпадающий список справочника
  фильтрует одновременно с `rvkFilter` (пересечение), Reset возвращает полный
  список; фильтр по `container.contNum` в ремонтах и освидетельствованиях
  работает.
- Пользователь с ролями `ui-minimal` + `container-read` сохраняет личный
  пресет и видит его после переоткрытия страницы.
- Сырых `msg://` нет, неиспользуемых ключей `…ListView.filter.*` нет;
  `spotlessCheckAll`, контейнерный пакет тестов и `UiMinimalRoleTest` зелёные.

## Таски

Порядок строк — порядок выполнения.

| Таск | Результат | Зависит от |
|---|---|---|
| [T01](tasks/T01/task.md) | `UiMinimalRole extends RvkFilterUserRole`, тест роли | — |
| [T03](tasks/T03/task.md) | 13 справочников: `rvkFilter` вместо `filterPanel`, messages | — |
| [T02](tasks/T02/task.md) | 6 основных страниц: выпадающие списки + `rvkFilter`, messages, `ContainerRvkFilterUiTest` | — |
| [T04](tasks/T04/task.md) | Сквозная проверка: тесты раздела, `spotlessCheckAll`, браузерный проход, правка дефектов | T01, T02, T03 |

## Параллельность и тестирование

| Таск | Область | Общие ресурсы | Параллельно с | Проверка |
|---|---|---|---|---|
| T01 | `app/security/UiMinimalRole.java`, новый `app/src/test/.../security/UiMinimalRoleTest.java` | БД, gradle daemon | T02, T03 | первой |
| T03 | `container/view/cnt*/*-list-view.xml`, свои ключи `messages_ru.properties` | БД, gradle daemon | T01, T02 | после T01 |
| T02 | `container/view/{container,containerrepair,containersurvey,containeract,containercontract,containerwarranty}/*-list-view.xml`, свои ключи `messages_ru.properties`, `container/view/ContainerRvkFilterUiTest.java` | БД, gradle daemon, порт 8080, браузер | T01, T03 | после T03 |
| T04 | правки дефектов в областях T01–T03 | всё | — | последней |

Все таски выполняются в одном worktree `../worktrees/rvk-ws/cyan-fennel/rvk-ws`
(ветка `f/container`, схема `main_rvk_ws` из `application-local.properties`,
тесты — по `app/src/test/resources/application-test-local.properties`
worktree). Код T01–T03 пишется параллельно в разных сессиях: файлы не
пересекаются, `messages_ru.properties` каждый правит только своими ключами и
перечитывает файл перед правкой. Чужие незакоммиченные файлы закрытой работы
не трогать. `./gradlew :app:test`, `bootRun` и браузер занимают БД, gradle
daemon и порт 8080 — проверки идут последовательно в порядке таблицы
«Таски», один проверяющий на ресурсе; приложение для браузера поднимает сам
проверяющий (`bootRun` в фоне, ждать `/actuator/health` = UP) и останавливает
только свой процесс.

Перед тестами: `docker info`, `(cd docker && docker compose ps)`, наличие
`app/src/test/resources/application-test-local.properties`. Команда тестов
раздела: `./gradlew :app:test --tests 'ru.fgk.ws.app.container.*'`.

## Как выполнять

1. T01, T02, T03 стартуют сразу в трёх сессиях.
2. Проверки: T01 → T03 → T02.
3. T04 после `done` у T01–T03; затем `task-close`.

Перед каждым таском прочитать skills `jmix-create-list-view`,
`jmix-add-i18n-keys`, `jmix-ide-static-analysis`, `jmix-create-test`; для
T01 — `jmix-create-resource-role`. Gate 1 — IDE-инспекция каждого изменённого
`*-view.xml`, иначе `./gradlew :app:compileJava` и механические проверки.
Gate 2 — тесты раздела. Gate 3 (T02, T04) — `playwright-cli`; без браузера
писать `render not browser-verified`.
