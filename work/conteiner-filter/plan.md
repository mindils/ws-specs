# RVK Filter на страницах раздела «Контейнеры»

Состояние: active
Дата согласования: 2026-09-16
Пересмотр: 2026-09-17 — [questions/Q01.md](questions/Q01.md), справочные
фильтры переносятся внутрь `rvkFilter` (T05)
Пересмотр: 2026-09-17 — jar аддона обновлён до `0.0.3` (чистый HEAD `16f138d`);
умолчание `lookup` в аддоне сменилось с `auto` на `none`, поэтому на
entity-полях раздела атрибут `lookup="auto"` объявляется явно
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
набор условий, пресеты) вместо прежних панелей; ссылки на справочники
`cnt_*`, организации `VOrgPassport` и договоры `ContainerContract` — поля
`rvkFilter` с выбором сущности (серверный поиск по вводу, кнопка «Выбрать…»
через штатный list view); штатных `propertyFilter` на списках не остаётся;
личные пресеты доступны каждому пользователю UI через минимальную роль.

Доработка 2026-09-17 ([Q01](questions/Q01.md)): аддон получил типы
`entity`/`entityList`, поэтому 9 выпадающих списков над `rvkFilter` (T02) и
ссылки, стоявшие текстом по пути (`owner.shortname`, `org.shortname`,
`contract.contractNum`, `defect.defectName`…), переносятся внутрь панели
одним таском T05 с обновлением jar в `libs/`; T04 после этого проходится
повторно.

Не входит: доработка самого аддона (выбор операции, AND/OR); поля по
станциям `VStation` как выбор сущности (вычисляемый `@InstanceName`, нужен
свой `itemsQuery` — остаются текстом); вкладки карточки контейнера (там
фильтров нет); слияние `f/container` в `main`; переключатель «старые/новые
фильтры» из ветки `f/new-filter`.

## Материалы

- Аддон: `../rvk-filter/README.md`, `docs/xml-api.md`, `docs/java-api.md`,
  `docs/persistence-and-security.md`, `docs/compatibility.md`, примеры
  `docs/examples/*.xml`. Jar 0.0.1 в `libs/` (2026-09-14) содержит
  `operation`, `valueList`, `configurationKey`, но не ссылки на сущности.
  Поддержка `entity`/`entityList` (`lookup`, `optionsLimit`,
  `<flt:itemsQuery>`) — в рабочем дереве аддона (uncommitted, jar
  `rvk-filter/build/libs/rvk-filter-0.0.1-SNAPSHOT.jar` от 2026-09-17):
  `docs/xml-api.md` «Ссылки на сущности», `docs/examples/entity-view.xml`,
  `docs/compatibility.md` (оговорка про `use-inner-join-in-condition` и
  формат пресетов). Changelog аддона не менялся. В T05 jar пересобран
  как 0.0.2 по `libs/README.md`; 2026-09-17 он заменён на 0.0.3, собранный
  из чистого HEAD `16f138d` аддона (`entityInput`, умолчание `lookup` →
  `none`, новый административный список пресетов; changelog по-прежнему без
  изменений — миграция не нужна).
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
- Отменено 2026-09-17 ([Q01](questions/Q01.md)): фильтры по справочникам
  `cnt_*` (реестр: модель, тип, размер; ремонты: вид ремонта;
  освидетельствования: вид; акты: тип акта; договоры: тип договора; гарантии:
  тип гарантии, тип контейнера) были штатными `propertyFilter` +
  `entityComboBox` над `rvkFilter` (сделано в T02). Теперь они переносятся
  внутрь `rvkFilter` (T05).

Ответы пользователя 2026-09-17 ([Q01](questions/Q01.md)):

- Внутрь `rvkFilter` переносятся 9 прежних выпадающих списков и ссылки на
  `VOrgPassport`, `ContainerContract`, `cnt_*`, стоявшие текстом по пути:
  `owner`, `org`, `repContract`, `contract`, `defect`, `defectReason`,
  `warrBegin`, `genChar`, `CntDefect.defectReason`. Режим — одно значение
  (`entity`, EQUAL), как у прежних выпадающих списков. Ссылки на `VStation`
  и `container.contNum` (searchProperty ремонтов и освидетельствований)
  остаются текстом.
- Entity-поле: `<flt:propertyFilter id="<ссылка>" property="<ссылка>"
  lookup="auto"/>` без `type` и `operation` (автотип `entity`, EQUAL).
  С jar `0.0.3` умолчание `lookup` — `none`, поэтому атрибут ставится явно
  на всех ссылочных полях: кнопка «Выбрать…» появляется у `cnt_*` и
  `ContainerContract`, у `VOrgPassport` list view нет — там `auto`
  разрешается в «кнопки нет», остаётся поиск по вводу. Подпись — из метаданных ссылки;
  явный `label` только где метаданные не подходят
  (`ContainerWarranty.contract` = «Гарантия к договору» → ключ
  `containerWarrantyListView.filter.contract` = «Договор» остаётся).
- `formLayout id="filterPanel"`, штатные `propertyFilter` и справочные
  `collection`/`loader` удаляются со всех списков раздела; ключи
  `…ListView.filter.*`, чьи подписи совпали с атрибутами entity, удаляются.
- Jar аддона в `libs/` обновляется до 0.0.2 по `libs/README.md` (пара jar,
  `rvkFilterVersion`, прежняя пара убирается из Git).

Технические решения (основание — код аддона и Jmix 3.0.x, проверено
2026-09-16, дополнено 2026-09-17):

- Неактуально после T05: правило «штатные `propertyFilter` выше
  `flt:rvkFilter`» (base-условие `RvkFilter.setDataLoader` захватывает
  `loader.getCondition()`, штатный фильтр ниже терялся бы при первом Apply).
  Штатных фильтров на списках не остаётся; тест пересечения со штатным
  фильтром в `ContainerRvkFilterUiTest` заменяется тестом entity-условия.
- Entity-условие аддон строит по `<property>.<pkName>` (сравнение с колонкой
  FK, без join к справочнику); опции ищутся `contains` без учёта регистра по
  строковым `@InstanceName` через constrained `DataManager` — `container-read`
  уже даёт READ на `VOrgPassport`, `ContainerContract`, `cnt_*`.
  `jmix.eclipselink.use-inner-join-in-condition=true` в приложении на EQUAL
  не влияет; отрицания по ссылке не используются. В пресете хранится только
  id, подпись подгружается — переименование справочника видно сразу.
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
- Состав полей: `defaultVisible="true"` у полей прежних панелей, включая
  прежние выпадающие списки; остальные скалярные колонки грида — скрытые
  поля (`defaultVisible` по умолчанию); ссылки на `cnt_*`, `VOrgPassport`,
  `ContainerContract` — entity-поля, ссылки на `VStation` и
  `container.contNum` — текст по пути `<ссылка>.<название>`. Поля аудита и
  `FileRef` не добавляются.
- Id полей `rvkFilter`: имя свойства (для entity-поля — имя ссылки:
  `model`, `org`, `repContract`); для пути — camelCase без точки
  (`containerContNum`, `repStName`). `order` — шаг 10: сначала entity-поля
  в порядке прежних выпадающих списков, затем остальные в прежнем порядке.
- `dataLoadCoordinator auto`, `settings auto`, `urlQueryParameters pagination`,
  панель кнопок, грид, lookup-действия и Java-контроллеры списков не
  меняются. `formLayout id="filterPanel"` удаляется везде (T05).

### Шаблон страницы

Целевое состояние после T05 (до T05 на шести страницах стоял
`formLayout id="filterPanel"` со штатными `propertyFilter` + `entityComboBox`
и справочные `collection`/`loader` — всё это удаляется):

```xml
<view xmlns="http://jmix.io/schema/flowui/view"
      xmlns:flt="http://fgk.ru/schema/rvk-filter" ...>
  <data>
    <collection id="repairsDc" .../>   <!-- как сейчас; справочных collection нет -->
  </data>
  <layout>
    <flt:rvkFilter id="rvkFilter" dataLoader="repairsDl" searchProperty="container.contNum" width="100%">
      <flt:filters>
        <!-- entity-поля: без type/operation — автотип entity, EQUAL; lookup объявлен явно -->
        <flt:propertyFilter id="repairType" property="repairType" lookup="auto"
                            defaultVisible="true" order="10"/>
        <flt:propertyFilter id="org" property="org" lookup="auto" defaultVisible="true" order="20"/>
        <flt:propertyFilter id="repContract" property="repContract" lookup="auto"
                            defaultVisible="true" order="30"/>
        <!-- текст по пути: searchProperty и ссылки на VStation -->
        <flt:propertyFilter id="containerContNum" property="container.contNum"
                            label="msg://containerRepairListView.filter.container"
                            defaultVisible="true" order="40"/>
        <flt:propertyFilter id="rejectDate" property="rejectDate" type="dateRange"
                            defaultVisible="true" order="50"/>
        ...
        <flt:propertyFilter id="defect" property="defect" order="..."/>   <!-- скрытое entity-поле -->
      </flt:filters>
    </flt:rvkFilter>
    <hbox id="buttonsPanel" .../>   <!-- далее без изменений -->
```

### Страницы

| View | searchProperty | Entity-поля (defaultVisible) | Entity-поля (скрытые) | Прочие defaultVisible |
|---|---|---|---|---|
| `cnt_Container.list` | `contNum` | `model`, `type`, `size`, `owner` | `genChar` | `manufNum`, `manufacturer`, `nextSurveyDate` |
| `cnt_ContainerRepair.list` | `container.contNum` | `repairType`, `org`, `repContract` | `defect`, `defectReason` | `container.contNum`, `rejectDate`, `dateBegin`, `dateEnd` |
| `cnt_ContainerSurvey.list` | `container.contNum` | `surveyType`, `org` | — | `container.contNum`, `dateBegin`, `dateEnd`, `dateNext` |
| `cnt_ContainerAct.list` | `actNum` | `actType`, `contract` | — | `dateSign` |
| `cnt_ContainerContract.list` | `contractNum` | `contractType`, `org` | — | `dateSign`, `dateBegin`, `dateEnd` |
| `cnt_ContainerWarranty.list` | `contract.contractNum` | `warrType`, `contType`, `contract` (label «Договор») | `warrBegin` | `id` (EQUAL) |
| `cnt_CntDefect.list` | `defectName` | — | `defectReason` | `defectName` |
| 12 прочих `cnt_Cnt*.list` | поле названия | — | — | поле названия |

До T05 столбцы entity-полей были «выпадающие списки над `rvkFilter`» (первый
столбец) и текстовые поля по пути `owner.shortname`, `org.shortname`,
`repContract.contractNum`, `contract.contractNum`, `defect.defectName`,
`defectReason.defectReasonName`, `warrBegin.actTypeName`, `genChar.charName`.

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
`genChar` (entity); ремонты — `id`, прочие даты, `defect`, `defectReason`
(entity), станции текстом `repSt.stName`, `rejectSt.stName`,
`repStInstr.stName`, стоимости, `vat`, текстовые поля, `roofUpgrade`;
акты — `id`, `actNum`, `comment`; договоры — `id`, `contractNum`; гарантии —
`warrDuration`, `extWarrDuration`, `inspInDays`, `penalty`,
`warrBegin` (entity)). Исполнитель может сократить список, если поле в
аддоне не поддерживается — с записью в `result.md`.

## Критерии всей работы

- На всех 19 списках раздела есть `rvkFilter` со строкой поиска и полями по
  таблице «Страницы»; штатных `propertyFilter` и `formLayout id="filterPanel"`
  нет ни на одном списке (после T05).
- Поиск и условия `rvkFilter` фильтруют грид; entity-поле показывает опции
  по вводу, «Выбрать…» открывает штатный list view справочника и возвращает
  выбор, условие действует вместе с поиском (пересечение), чип и пресет
  показывают название, а не id; Reset возвращает полный список; фильтр по
  `container.contNum` в ремонтах и освидетельствованиях работает.
- Пользователь с ролями `ui-minimal` + `container-read` сохраняет личный
  пресет (в том числе с entity-условием) и видит его после переоткрытия
  страницы.
- Сырых `msg://` нет, неиспользуемых ключей `…ListView.filter.*` нет;
  `spotlessCheckAll`, контейнерный пакет тестов, `UiMinimalRoleTest` и тесты
  `nsi.view.vdepo.*` (другой пользователь jar-а) зелёные.

## Таски

Порядок строк — порядок выполнения.

| Таск | Результат | Зависит от |
|---|---|---|
| [T01](tasks/T01/task.md) | `UiMinimalRole extends RvkFilterUserRole`, тест роли | — |
| [T03](tasks/T03/task.md) | 13 справочников: `rvkFilter` вместо `filterPanel`, messages | — |
| [T02](tasks/T02/task.md) | 6 основных страниц: выпадающие списки + `rvkFilter`, messages, `ContainerRvkFilterUiTest` | — |
| [T05](tasks/T05/task.md) | Jar 0.0.2, справочные ссылки как entity-поля внутри `rvkFilter` на 7 страницах, messages, тест | T02, T03 |
| [T04](tasks/T04/task.md) | Сквозная проверка: тесты раздела, `spotlessCheckAll`, браузерный проход, правка дефектов | T01, T02, T03, T05 |

## Параллельность и тестирование

| Таск | Область | Общие ресурсы | Параллельно с | Проверка |
|---|---|---|---|---|
| T01 | `app/security/UiMinimalRole.java`, новый `app/src/test/.../security/UiMinimalRoleTest.java` | БД, gradle daemon | T02, T03 | первой |
| T03 | `container/view/cnt*/*-list-view.xml`, свои ключи `messages_ru.properties` | БД, gradle daemon | T01, T02 | после T01 |
| T02 | `container/view/{container,containerrepair,containersurvey,containeract,containercontract,containerwarranty}/*-list-view.xml`, свои ключи `messages_ru.properties`, `container/view/ContainerRvkFilterUiTest.java` | БД, gradle daemon, порт 8080, браузер | T01, T03 | после T03 |
| T05 | области T02 + `cntdefect/cnt-defect-list-view.xml`, `libs/`, `app/build.gradle`, ключи `filter.*` контейнерных view | всё (сборка аддона, БД, gradle daemon, порт, браузер) | — (после `done` T02, T03) | после T02 |
| T04 | правки дефектов в областях T01–T03, T05 | всё | — | последней |

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

1. T01, T02, T03 стартуют сразу в трёх сессиях. (Выполнено 2026-09-16.)
2. Проверки: T01 → T03 → T02. (Выполнено.)
3. T04 после `done` у T01–T03. (Пройден 2026-09-16, возвращён в `todo`
   пересмотром Q01.)
4. T05 в одной сессии (2026-09-17).
5. T04 повторно после `done` у T05; затем `task-close`.

Перед каждым таском прочитать skills `jmix-create-list-view`,
`jmix-add-i18n-keys`, `jmix-ide-static-analysis`, `jmix-create-test`; для
T01 — `jmix-create-resource-role`. Gate 1 — IDE-инспекция каждого изменённого
`*-view.xml`, иначе `./gradlew :app:compileJava` и механические проверки.
Gate 2 — тесты раздела. Gate 3 (T02, T04, T05) — `playwright-cli`; без
браузера писать `render not browser-verified`.
