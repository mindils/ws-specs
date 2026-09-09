# Журнал реализации

[К плану](README.md)

## 2026-09-09 — финальные app gates и host smoke

`./gradlew --refresh-dependencies :app:compileJava :app:test spotlessCheckAll`: PASS,
1196 passed + 9 skipped, 0 failures/errors. qa подтвердил текущие четыре страницы
под Lumo через local-login с FullAccess: для типов деталей, депо и типов документов
изменение строк подтверждено; у причин отклонения таблица пуста, проверен UI state.
Admin list открывается, detail в этом проходе не проверен. 360px без overflow.
Точные условия/count, артефакты и ограничения — [отчёт](15-addon-operations-verification.md).

## 2026-09-08 — операции, valueList, полный applied-list и актуализация плана

Продолжение в ../rvk-filter: фиксированные операции, строгий UUID и буквальный LIKE,
редактор списков с typed IN/NOT IN, номером неверного элемента и лимитом 1000,
полный список applied chips, корневые Studio metadata. Полный PostgreSQL-прогон:
**496 passed, 0 skipped/failures/errors**. qa подтвердил fixtures и исправление
геометрии длинной формы на 360px. [Доказательства и остаток](15-addon-operations-verification.md).

Новые страницы не подключались; F09/F10 остаются backlog кроме четырёх действующих.
Обновлены отставшие от кода статусы typed JPQL/IN, locale, presets и startup definitions.
Внешней публикации, назначения Keycloak и коммитов не выполнялось.


## 2026-09-07 — уточнён объём, проверены действующие страницы, реализован F08.2

По новому решению пользователя RVK Filter не добавляется на остальные страницы rvk-ws.
Создан [backlog из 136 карточек](13-pages-backlog.md); README, F08–F11 и генератор каталога
согласованы с этим объёмом. Текущие страницы — M001–M003 и N002.

Проверка выявила недоделанный режим fallback: закрытый details не отключал старые условия,
они складывались с RVK через AND. Добавлен `RvkFilterModes` и явный переключатель на четырёх
страницах, изоляция условий, восстановление applied при сохранённом draft, одна загрузка,
откат отменённой загрузки и `rvk.filter.legacy-views`. На N002 отключение возвращает исходный
список без пустой старой панели. Исправлены неподдерживаемые XML-атрибуты причин отклонения.

Свежая проверка: app **1192 passed / 9 skipped / 0 failures**, аддон на PostgreSQL
**404 passed / 0 skipped / 0 failures**. Новый тест режимов проверяет реальные ID и число
загрузок. Все четыре страницы открыты браузером; на M001/M003 снятие чипа сразу меняет
выборку и оставляет панель закрытой. Тем самым снято ограничение host-render из предыдущей
записи о чипах. Полный отчёт, пофайловая статика и незакрытые пункты —
[14-current-pages-verification.md](14-current-pages-verification.md).


## 2026-09-07 — ✕ на чипе применённого условия снимает фильтр сразу

Правка в `../rvk-filter` (рабочее дерево, коммитов нет); в `rvk-ws` изменена только
`docs/rvk-filter.md` и этот журнал.

**Симптом.** На пилотных страницах условие применено, в строке фильтра видна плашка
«Поле: значение», ✕ на ней не убирал ни плашку, ни условие из выборки.

**Причина.** Не баг, а прежнее решение аддона. Чипы строятся из `_appliedState`
(`rvk-filter.js` `_buildChips`), а `_onChipRemove` вызывал `_updateFieldValue` — правил
черновик `_state` и открывал панель. Снятие вступало в силу только после «Найти».
Это было записано в `rvk-filter/docs/frontend-contract.md` («Удаление applied chip редактирует
draft и открывает панель») и закреплено assert-ом `chip removal falsely applied` в
`rvk-filter/src/test/frontend/lifecycle-check.js`. Пользователь подтвердил, что ожидаемое
поведение — снятие немедленно, поэтому менялся и контракт.

**Правка.** `_onChipRemove` собирает новое состояние из `_appliedState` без этого условия
(`getDefaultValue(field)` для скаляра, фильтрация массива для multiSelect) и вызывает
`_handleApply()`. Панель не открывается. Базой взят именно applied, а не draft: иначе снятие
одного чипа попутно применило бы посторонние неприменённые правки панели. Побочный эффект
совпадает с «Сбросить» — неприменённый черновик теряется, так как сервер перезаписывает
property `state`. Java не менялась: `rvk-filter-apply` уже обрабатывается
`RvkFilter.FilterApplyDomEvent` → `doApply` → `executeState`.

Вместе с кодом обновлены `docs/frontend-contract.md`, `docs/testing.md`,
`docs/rollout-verification.md` (3 → 4 запроса) и `docs/release-notes.md` аддона.

**Проверено.**

| Гейт | Команда/сценарий | Результат |
|---|---|---|
| Аддон, сервер | `./gradlew --no-daemon clean test :rvk-filter:jar` | BUILD SUCCESSFUL, 404 теста, 0 падений, 12 skipped (без PG-переменных) |
| Аддон, браузер | `lifecycle-check.js` на production JS | `requests: 4`, `pageErrors: []`, чип исчезает после подтверждения, панель закрыта |
| Проверка самой проверки | тот же сценарий против копии кода до правки | падает на `chip removal did not send Apply` |
| Регресс соседних сценариев | `presets-check.js`, `dropdown-check.js` | оба зелёные, `pageErrors: []` |
| Публикация | `./gradlew --no-daemon publishToMavenLocal` | jar в mavenLocal содержит новый `_onChipRemove` |
| Приложение, Gate 2 | `./gradlew --refresh-dependencies :app:test` | BUILD SUCCESSFUL, 1189 passing, 9 pending |

**Ограничение: render not browser-verified.** Gate 3 на живом приложении не выполнен. В момент
проверки уже работал `:app:bootRun --args=--server.port=8080`, запущенный до публикации нового jar:
он держит HSQLDB-lock стора `vagtk` (второй экземпляр падает на
`Database lock acquisition failure ... vagtk.lck`) и отдаёт браузеру dev-бандл со **старым** JS,
так как открыл jar до его замены. Перезапуск чужой сессии не выполнялся по решению пользователя.
Проверить на реальных страницах после следующего перезапуска приложения: `/nvPartTypes` и `/depo` —
условие → «Найти» → чип; ✕ на чипе → чип исчез, число строк изменилось, панель не открылась,
error overlay нет; на `/depo` дополнительно multiSelect (снимается только выбранный пункт).

## 2026-09-07 — закрыт дефект аддона «dropdown-поля не применяются»

Правка в `../rvk-filter` (рабочее дерево, коммитов нет); в `rvk-ws` кода не менялось.

**Причина, подтверждённая по исходникам.** `rvk-filter-dropdown.js:328` и
`rvk-filter-picker.js:430` слали `change` с `bubbles: true, composed: true` и без `fieldId`.
Обработчик `_onFieldChange` (`rvk-filter.js:763`) висит на самом `<rvk-filter-field>`
(`rvk-filter.js:1373`), поэтому получал ДВА события: сначала корректное переизлучённое из
`RvkFilterField._emitChange` (с `fieldId`), затем всплывшее исходное — с `fieldId === undefined`,
которое писало `values["undefined"]`. Сервер отвергал payload целиком
(`FilterState.parseValidated` → `Unknown filter field: undefined`). Ключ оставался в draft,
поэтому падал каждый следующий Apply. Тот же путь используется debounced
`rvk-filter-state-changed`, так что ошибка появлялась и без нажатия «Найти».
Затронуты были `singleSelect`, `multiSelect`, `boolean`, режимы дат и **оператор числового
поля** — последнее объясняет, почему на `/depo` «Код депо» работал при вводе цифр
(`@input`) и ломался при выборе «Больше».

**Правка — три слоя.**

1. `rvk-filter-dropdown.js`, `rvk-filter-picker.js` — внутренние контролы шлют собственное
   `value-change` без `bubbles`/`composed`; `rvk-filter-field.js` слушает `@value-change`
   в пяти биндингах (singleSelect, multiSelect, boolean, режим даты, оператор числа).
   Внешний контракт поля (`change` с `{fieldId, value}`) не изменился.
2. `rvk-filter.js:_onFieldChange` — принимает только события с `fieldId` из каталога полей.
3. `rvk-filter.js:_normalizeState` — отбрасывает `values`/`activeFieldIds` вне каталога.
   Это лечит state и пресеты, сохранённые до правки; no-op пока каталог полей пуст.

**Регрессия.** Новые `dropdown-fixture.html` + `dropdown-check.js` в аддоне: 7 сценариев
(singleSelect, boolean, оператор числа, режим даты, multiSelect, payload `rvk-filter-apply`,
санация отравленного state). Проверка проверки: на коде до правки скрипт красный —
`singleSelect: ключ "undefined" в state.values -> ["vrkCode","undefined"]`. **Важно:** после
подмены исходников нужно закрыть и заново открыть сессию браузера, иначе ES-модули берутся
из кеша по URL и прогон идёт по старому коду (первая попытка сравнения дала ложный зелёный).

**Гейты.**

- Аддон: `./gradlew --no-daemon clean test :rvk-filter:jar` — BUILD SUCCESSFUL,
  404 теста, 0 failures, 12 skipped. `publishToMavenLocal` — jar в
  `~/.m2/repository/ru/fgk/component/`, наличие `value-change` в JS внутри jar проверено.
- Клиент: `dropdown-check.js`, `lifecycle-check.js`, `presets-check.js` — все зелёные,
  `pageErrors=[]`. Контракт внешних событий не изменился (`bubbles/composed` в presets-check).
- `rvk-ws` Gate 2: `./gradlew :app:test` — **1189 passing, 0 failures, 9 pending**.
- `rvk-ws` Gate 3: удалены `app/build/dev-bundle` и
  `app/src/main/frontend/generated/jar-resources/src/component/rvk-filter/`, `bootRun`,
  вход `/local-login` admin/admin, Chromium/Playwright 1600×1000. В браузере подтверждено,
  что загружен исправленный билд (`RvkFilterDropdown.prototype._select` содержит
  `value-change`).

**Сверка с БД** (`psql` в `docker-rvk-db-1`; MCP `rvk-ws` в этой сессии не подключён):

| Страница | Условие | state.values | UI | БД |
|---|---|---|---:|---:|
| M003 `/depo` | `vrkCode` = ВРС | `{"vrkCode":"6"}` | 9 | 9 |
| M003 | `vrkCode` = НВТ (смена значения тем же дропдауном) | `{"vrkCode":"4"}` | 8 | 8 |
| M003 | `id` оператор «Больше» 9500 | `{"id":{"operator":"greater","value":"9500"}}` | 31 | 31 |
| M003 | `recdatenew` режим «Сегодня» | `{"recdatenew":{"mode":"today",…}}` | 0 | 0 |
| M001 `/nvPartTypes` | `isNumbered` = Да | `{"isNumbered":"true"}` | 6 | 6 |
| M001 | `isNumbered` = Нет | `{"isNumbered":"false"}` | 20 | 20 |
| N002 `/diadoc-document-type` | `sortOrder` > 0 | `{"sortOrder":{"operator":"greater","value":"0"}}` | 23 | 23 |

Ни в одном состоянии ключа `undefined` нет, `[role="alert"]` пуст, повторный Apply без
изменений и «Сбросить» проходят чисто, `pageerror` нет, сырых `msg://` нет, в серверном
логе ни одного ERROR и ни одного `Unknown filter field`.

**Не проверено данными:** M002 `/reject-reasons` — таблица `main.nsi_reject_reason` локально
пуста (0 строк), поэтому подтверждено только отсутствие ошибки и чистый state при выборе
«Да»/«Нет» в boolean-поле, а не число строк. Все четыре boolean-поля присутствуют в меню
«Добавить поле» с корректными подписями.

## 2026-09-07 — тестовое подключение панели к 4 страницам (M001–M003, N002)

Первое использование `rvkFilter` в самом приложении: до этого grep по `app/src` давал 0
вхождений компонента в view-дескрипторах. Объём — **тестовый прогон**, не production-rollout:
переключателя «Новый / Старый» и feature flag по viewId (F08.2) нет, старые фильтры просто
переведены в закрытую гармошку и остаются рабочими, вклады обеих панелей объединяются через AND.
Публикация фиксированной версии аддона и заведение ролей в Keycloak не выполнялись.

Изменённые дескрипторы (Java-контроллеры не трогались ни на одной странице):

| Карточка | viewId | Поля панели | Старые фильтры |
|---|---|---|---|
| M001 | `nsi_NvPartType.list` | `mnem`, `name`, `info`, `usedDrContract`, `isNumbered`; search `name` | `details#filterPanel`, `opened=false` |
| M002 | `RejectReason.list` | `message`, `violationTech`, `violationDamage`, `violationOperRepair`, `nonPayment`; search `message` | `details#legacyFilterPanel`, `opened=false` |
| M003 | `nsi_VDepo.list` | `id`, `shortName`, `railway.rwName`, `rwCode`, `stCode`, `vrkCode` (singleSelect, 7 `<flt:option>` по `VrkEnum`), `recdatenew` (авто `dateTimeRange`); search `shortName` | `details#staticFilter`, `opened=false` |
| N002 | `DiadocDocumentType.list` | `name`, `code`, `sortOrder`, `vrkLoadingIdLabel`, `usageType`; search `name` | нет; пустая гармошка не создавалась |

i18n: один новый ключ `ru.fgk.ws.app/legacyFilters=Старые фильтры` (общая подпись гармошки).
Освободившиеся `ru.fgk.ws.app.nsi.view.nvparttype/filtersHeader` и
`ru.fgk.ws.app.nsi.view.rejectreason/Filters` удалены — на них не осталось ссылок.
На `nsi_VDepo.list` `focusComponent` переведён с `idFilter` на `vDepoesDataGrid`: старый
контрол теперь внутри закрытой гармошки.

**Находка, определившая разметку: порядок объявления в XML — не косметика.**
`SingleFilterComponentBase#updateDataLoaderCondition` (jmix-flowui 3.0.1, строки 163–175) при
биндинге штатного `propertyFilter` оборачивает условие загрузчика в `LogicalCondition.and()`,
вызывает `dataLoader.setCondition(root)` и добавляет своё условие **в этот объект**.
`FilterLoaderConditions.forLoader` (аддон) запоминает `loader.getCondition()` как `base`
единожды — в момент `RvkFilter#setDataLoader` из `RvkFilterLoader#loadComponent():102`, а каждый
Apply выполняет `dataLoader.setCondition(base AND contributions)`
(`RvkFilter.java:495/503/515`). Компоненты загружаются в порядке документа, поэтому объявление
`<flt:rvkFilter>` раньше старых фильтров захватило бы `base = null`, и первый же Apply
**молча выключил бы старые фильтры** — ни compileJava, ни `:app:test` этого не ловят.
Во всех трёх страницах со старыми фильтрами `<details>` объявлен раньше компонента.
Альтернатива для разметки «новый сверху» — `rvkFilter.setBaseCondition(loader.getCondition())`
в `onBeforeShow`; здесь не понадобилась.

**Gate 1.** `./gradlew :app:compileJava :app:compileTestJava` — BUILD SUCCESSFUL;
`spotlessApply` + `spotlessCheckAll` — BUILD SUCCESSFUL. Дескрипторы компилятору не видны,
поэтому дополнительно прогнан механический скрипт: XML well-formed (4/4), `dataLoader`
существует в `<data>`, каждый `property` (включая head вложенного пути) есть в entity, каждый
`msg://` резолвится в `messages_ru.properties`, дубликатов field id нет — 0 замечаний.
IDE-инспекция (`get_file_problems`) не выполнялась: MCP-подключение к IDE в этой сессии
отсутствует.

**Gate 2.** Добавлены 4 UI-теста навигации (наследники `test_support/BaseUiTest`, без
собственных `@TestConfiguration`) — `NvPartTypeListViewTest`, `RejectReasonListViewTest`,
`VDepoListViewTest`, `DiadocDocumentTypeListViewTest`. Это существенно: `:app:test` поднимает
контекст, но `*-view.xml` читается только при создании view, поэтому без них ошибка
конфигурации `rvkFilter` не была бы поймана автоматически. Прогон целевых тестов —
**4 passing**; полный `./gradlew :app:test` — см. ниже.

Побочно подтверждено, что панель пресетов инициализируется под пользователем `@UiTest` без
отдельных ролей: опасение о падении на `RvkFilterConfigService` не подтвердилось.

**Gate 3 (браузер).** `bootRun` в фоне, вход `/local-login` admin/admin, Chromium/Playwright,
1600×1000, тема Lumo. Все 4 страницы: компонент рендерится (1 узел `rvk-filter` на страницу),
error overlay нет, сырых `msg://` нет, `pageerror` нет, локализация русская.
Гармошка «Старые фильтры» присутствует и закрыта на M001/M002/M003; на N002 её нет.

Сверка результатов с БД (обычный SELECT в `docker-rvk-db-1`):

| Страница | Условие | UI | БД |
|---|---|---:|---:|
| M003 | `shortName` содержит «Германия» | 2 | 2 |
| M003 | `rwCode` = «51» | 85 | 85 |
| M003 | `id` = 6711 (число, exact) | 1 | 1 |
| M003 | `railway.rwName` содержит «Московская» | 148 | 148 |
| M001 | `name` содержит «Колесная» | 1 | 1 |
| N002 | `name` содержит «ВУ» | 7 | 7 |

Каталог полей и автоопределение типов подтверждены в меню «Добавить поле»: «Код депо ЧИСЛО»,
«Наименование дороги ТЕКСТ», «Код дороги ТЕКСТ», «Код станции ТЕКСТ», «Код ВРК СПИСОК»,
«Дата вставки ДАТА И ВРЕМЯ». Опции `vrkCode` отрисованы всеми семью объявленными значениями
с подписями `VrkEnum` в порядке объявления: (любой)/ВРК1/НВРК/ОМК/НВТ/ВРС/ЦДИ/ТВМ.

**Совместимость старого и нового фильтра подтверждена на M003** (ради чего и выбран порядок XML):
новая панель `shortName`~«Германия» → 2 строки; затем в раскрытой гармошке старый
`idFilter` = 6711 → **1 строка**, то есть пересечение обоих условий. Старый фильтр продолжает
участвовать в запросе после Apply новой панели.

Пресеты: «Сохранить как новый» → имя «Только Германия» → запись создана в
`main.rvk_filter_config` c `component_id = nsi_VDepo.list.rvkFilter`, `username = admin`,
`version = 1`, payload `{"query":"","activeFieldIds":["shortName"],"values":{"shortName":"Германия"}}`;
в панели она отображается в разделе «Сохранённые фильтры» как «личный», «Условий: 1».
**Тестовая запись оставлена в БД** — удалить можно из панели или через экран обслуживания.

### Найденный дефект аддона: dropdown-поля не применяются

> **Закрыт 2026-09-07** — см. верхнюю запись журнала. Ниже — разбор в момент обнаружения.

**Блокирует singleSelect, multiSelect, boolean и режимы дат** — то есть все нетекстовые контролы.

Воспроизведение: на `/depo` добавить поле «Код ВРК», выбрать «ЦДИ», нажать «Найти» →
панель показывает «Не удалось применить фильтр: Unknown filter field: undefined»,
«Есть неприменённые изменения», выборка остаётся прежней (1893). То же на `/nvPartTypes`
с boolean-полем «Номерная деталь».

Причина установлена по состоянию компонента и исходникам:

- `rvk-filter-dropdown.js:328` — `_select()` шлёт `new CustomEvent('change', {detail: {value},
  bubbles: true, composed: true})`, **без `fieldId`**.
- `rvk-filter.js:1373` — обработчик навешен как `@change=${this._onFieldChange}` на
  `<rvk-filter-field>`; `rvk-filter.js:763` делает `const {fieldId, value} = event.detail`.
- Всплывающий composed `change` внутреннего dropdown доходит до того же обработчика, `fieldId`
  равен `undefined`, и `_updateFieldValue` пишет `values["undefined"]`.
- Замерено в браузере: после выбора значения `_state.valueKeys` = `["vrkCode","undefined"]`
  (и `["isNumbered","undefined"]` для boolean).
- Сервер отвергает такой payload в `FilterState.java:210` — `Unknown filter field: undefined`.

Текстовые поля не затронуты: они используют `@input` (`rvk-filter-field.js:458`), а не `change`.

Возможные направления правки (в аддоне `rvk-filter`, не в rvk-ws): не всплывать событием
внутреннего контрола (`bubbles: false` или собственное имя вроде `value-change`), либо
`stopPropagation()` в `RvkFilterField._emitChange`, либо игнорировать в `_onFieldChange`
события без `fieldId`. Правка не выполнялась — задача касалась только подключения страниц.

Побочно: поведение аддона при этой ошибке корректно по F04.1 — неуспешный Apply не выдаёт себя
за успешный, прежние данные и пагинация сохраняются, draft не теряется.

Проверка числового поля сначала дала 0 строк, но это была ошибка тест-скрипта (поля
упорядочены по `order`, и ввод попал в соседнее поле), а не дефект: при вводе именно в поле
`id` состояние равно `{"id":{"operator":"exact","value":"6711"}}` и Apply даёт 1 строку.

**Окружение.** Первый запуск `bootRun` упал на `vagtkEntityManagerFactory` («Supported database
is not determined from JDBC URL»). Причина — не регрессия: HSQLDB-файлы `app/.jmix/hsqldb/vagtk*`
держал ещё живой Gradle-демон после прогона тестов (`*.lck` на месте). `./gradlew --stop`
освободил блокировки, повторный запуск прошёл.

## 2026-09-07 — F08.1: аддон подключён к rvk-ws, административный экран проверен браузером

Первые изменения в самом приложении. Коммитов нет.

- `app/build.gradle` — `ru.fgk.component:rvk-filter-starter:0.0.1-SNAPSHOT` (резолвится из
  mavenLocal; фиксированную опубликованную версию ещё предстоит выпустить).
- Master changelog приложения включает `/ru/fgk/component/rvkfilter/liquibase/changelog.xml`
  до собственного `includeAll`; `menu.xml` получил «Служебное меню → Фильтры списков» →
  `rvkflt_ConfigAdmin.list`; ключ меню добавлен в `messages_ru.properties`; появился
  [docs/rvk-filter.md](../../docs/rvk-filter.md) с описанием подключения, ролей и экрана.

**Gate 2:** `./gradlew :app:test` — **1194 теста, 1185 passed, 0 failures, 9 skipped.**

Перед этим Gate 2 падал 190 раз, и это оказалась не регрессия аддона, а среда: локальная копия
`ws_store` отставала от своего мигратора, поэтому app-changeset `02_view/independent/01-v_pt_1c_balance`
падал с `column "uid" does not exist`. Базовая линия подтверждена отдельным прогоном с
отключёнными изменениями — та же ошибка. Починка: `liquibase update` в `migration/ws_store`
(9 changeset-ов; `TRUNCATE` только по пустой локально таблице) плюс `DROP VIEW main.v_pt_1c_balance`,
который мешал ALTER и был заново создан миграцией приложения. Схему `ws_store` в репозитории не меняли.

**Gate 3 — выполнен, экран проверен в браузере.** `:app:bootRun` (старт 27,8 с), вход `user`
через Keycloak, Chromium/Playwright:

- Пункт меню и экран открываются, заголовок «Настройки фильтров», страница рендерится **внутри
  main view приложения** — подтверждает необходимость `layout = DefaultMainViewParent`.
- Все подписи локализованы, сырых `msg://` нет: фильтры, 12 колонок грида, кнопки, пагинация
  «0–0 из 0». Кнопки, требующие выделения, недоступны.
- Создание записи для незарегистрированного компонента показало ожидаемое подтверждение
  «Компонент не зарегистрирован. Проверена только структура JSON»; после «Да» строка появилась
  в гриде с диагностикой, scope «Общая», audit и `created_by = user` в `main.rvk_filter_config`.
- «Назначить по умолчанию» осталась недоступной для несовместимой записи; удаление запросило
  подтверждение с именем/компонентом/scope, после «Да» строка исчезла из грида и из БД.
- Error overlay нет. В консоли единственная ошибка — недоступный из внешней сети корпоративный
  URL аватара (`info.main.vgk`). В серверном логе единственный ERROR — `OptimisticLockException`
  в Jmix OIDC user mapper при первом входе (синхронизация role assignments), повторный вход
  прошёл; к аддону отношения не имеет. Тестовая запись удалена, bootRun погашен.

**Найдено:** назначения ролей синхронизируются из claims Keycloak при каждом входе
(`SsoSynchronizingOidcUserMapper`, `setSynchronizeRoleAssignments(true)`) — роли аддона нельзя
раздавать правкой `sec_role_assignment`, их нужно завести в Keycloak. Записано в F08.1.

**Следующий незавершённый шаг:** выпустить фиксированную версию аддона и заменить SNAPSHOT;
завести роли аддона в Keycloak и назначить пилотным пользователям; зафиксировать рецепт перевода
страницы; затем M001 (`nsi_NvPartType.list`) с режимами «Новый/Старый» и feature flag из F08.2.
F03/v2 и очередь M/N по-прежнему открыты.

---

## 2026-09-07 — F06.3 UI и выполненный SQL runbook

Продолжено рабочее дерево `../rvk-filter`, без коммитов и публичного релиза.
**F06 закрыт в объёме аддона. Открыто только подключение приложением (F08).**

Административные views, их messages и view/menu policies уже лежали в рабочем дереве от
прерванного этапа и не были проверены. Проверены как есть; найдены и исправлены два дефекта.

- Дефект 1: `SecurityFlowuiConfiguration`, добавленный ради `@ViewPolicy/@MenuPolicy`, включает
  `DeviceTimeZoneProvider`, который разыменовывает `UI.getCurrent()`. Любое применение фильтра
  без UI-потока падало с NPE — 9 из 10 lifecycle-тестов красные, запрос не выполнялся.
  `RvkFilter.resolveTimeZone()` теперь переходит на таймзону JVM вместо отказа.
- Дефект 2: `@Route` административного списка не задавал layout — экран рендерился бы вне
  main view приложения. Добавлен `layout = DefaultMainViewParent.class`, как во встроенных
  views Jmix.
- Views аддона: `rvkflt_ConfigAdmin.list` (route `rvk-filter-configurations`) и
  `rvkflt_ConfigAdmin.detail` (только диалог) под ролью `rvk-filter-maintainer`. Данные идут
  только через административный сервис: у views нет DataContext и entity loader.
- Список: фильтры component/owner/name, scope, сортировка, пагинация по применённому запросу,
  колонки scope/defaults/schema/version/audit/совместимость; неудачная перезагрузка гасит
  действия и не оставляет чужую строку выделенной.
- Действия: создание, редактирование без смены владельца, копирование, подтверждаемые transfer
  и удаление, назначение/снятие default, экспорт файла и импорт в явное назначение.
  Совместимый пресет правится обычной панелью из каталога registry с отключёнными пресетами и
  пустыми condition providers; неизвестный/повреждённый/future payload — raw JSON с валидацией.
  `INVALID` не сохраняется, `UNKNOWN_COMPONENT` требует подтверждения, отказ сервиса сохраняет
  ввод и оставляет форму открытой.
- SQL runbook F06.4 впервые выполнен: одноразовая БД со схемой `main`, снятой с таблицы
  PostgreSQL-прогона. Подтверждены все команды, включая 0 строк при устаревшей version и
  повторном восстановлении, и отказы БД (второй общий default, оба нарушения scope, пустое имя,
  `schema_version = 0`).

**Проверки:** `./gradlew --no-daemon clean test :rvk-filter:jar` — HSQL 404 cases,
**392 passed, 12 PostgreSQL-only skipped**, 0 failures/errors; PostgreSQL 16.11 (собственная БД
`rvk_filter_ui_20260907`) — **404 passed, 0 skipped**, вместе с `publishToMavenLocal`.
Целевой lifecycle-прогон до исправления: 9 из 10 красных, после — 10 passed. Новые 12 UI-кейсов
работают в общем контексте, без своей Spring-конфигурации, подмен бинов и тестовой транзакции,
с очисткой в `@AfterEach`. После прогона в тестовой БД 0 пресетов, 0 тестовых пользователей,
0 активных role assignments; БД приложения не затрагивалась, одноразовые БД удалены.

Gate 1: IDE MCP в этой сессии недоступен — **IDE semantic inspection не подтверждена**;
применён запасной путь: compileJava/compileTestJava, палантир-формат (Google, dry-run без
изменений), совпадение package/каталога, непустота, и механическая проверка дескрипторов —
19 + 15 `msg://` резолвятся в обеих локалях, 61 admin-ключ объявлен в обоих bundles и
используется, каждый `@ViewComponent` имеет id в XML, лишних id нет. Оба дескриптора
дополнительно открываются настоящим Jmix loader в UI-тесте.

Gate 3: **render not browser-verified.** Серверный UI-тест не открывает браузер; тема, Vaadin
transport, host-меню и отрисовка остаются на проходе приложения. Исходники rvk-ws не менялись,
`:app:test` не запускался.

[Пофайловый отчёт](../../../rvk-filter/docs/administration-ui-verification.md),
[контракт и экраны](../../../rvk-filter/docs/administration-api.md),
[воспроизводимые команды](../../../rvk-filter/docs/testing.md).

**Следующий незавершённый шаг:** F08 — зависимость аддона в rvk-ws, include changelog,
роль и пункт меню административного экрана, изоляция старого режима и flags; затем host-проход
браузером, который закрывает оставшиеся UX-пункты F07 и снимает «render not browser-verified».
F03/v2, typed entity/JPQL, adapters и F09/F10 (M/N) не закрыты. Чекбоксы F05/F07 в пакете
отстают от реализации намеренно: их отмечают после подтверждения на host-проходе.

---

## 2026-09-06 — F06.3: startup registry и защищённый административный API

Продолжено существующее рабочее дерево `../rvk-filter`, без коммитов и публичного релиза.
**Серверная часть F06.3 реализована и проверена. Административные экраны ещё не созданы.**

- Добавлен неизменяемый `RvkFilterDefinitionRegistry`, собирающий `RvkFilterDefinition` beans
  при старте. Property metadata, field IDs/types/options/ranges/search проверяются общим
  валидатором панели; CUSTOM providers при диагностике не выполняются. Для domain validation
  предусмотрен явный callback. Неизвестный компонент получает структурную проверку и warning.
- Найден и исправлен startup-дефект: MessageTools требовал Authentication для locale.
  Внутренний resolver получил явную Locale.ROOT; объявления для редактора сохраняют локаль UI.
- Обычный сервис проверяет зарегистрированный каталог при save/copy/default, включая старый
  setDefaultForMe. Обычная панель и constrained DataManager maintainer не открывают чужие записи.
- `RvkFilterAdminService` проверяет manageAllConfigs перед каждым entrypoint, включая чтение,
  validation и export. После проверки использует узкий unconstrained путь; audit — реальный
  оператор. Реализованы pagination/filter/sort, versioned CRUD/default, copy/transfer/import/export.
- Delete/clear default/export доступны для повреждённого/future payload; repair валидируется.
  Transfer сохраняет UUID/created audit и снимает defaults; import создаёт новую недефолтную
  копию в явном назначении, не доверяя входным id/audit/owner/default. Admin-default неизвестного
  компонента запрещён до регистрации. Подтверждения операций остаются задачей UI.
- Scope locks admin и панели общие; copy/transfer берут обе блокировки в едином порядке,
  перечитывают запись и проверяют version. Коллизия имени или несовместимое назначение
  не изменяют исходную запись/default.

**Проверка:** HSQL `./gradlew --no-daemon clean test :rvk-filter:jar` — 392 cases,
**380 passed, 12 PostgreSQL-only skipped**. PostgreSQL 16.11 — **392 passed, 0 skipped/errors**;
повторный `clean test :rvk-filter:jar publishToMavenLocal` тоже успешен. Новые 21 проверки
работают в общем Spring context, без тестовой транзакции, с реальными ролями и очисткой.
Проверены concurrent editors, противоположные transfers и default одновременно из admin/панели.
Своя БД `rvk_filter_admin_20260906_1700` удалена после проверки отсутствия активных fixtures;
БД приложения и ранее существующая тестовая БД не затронуты.

IDE отвергла projectPath аддона (открыт только rvk-ws); применены компиляция, package/path,
непустота, Palantir Google и проверки обоих bundles. JAR содержит 13 непустых ресурсов и новые
серверные классы; 7 JS прошли syntax check. [Пофайловый отчёт](../../../rvk-filter/docs/administration-verification.md),
[контракт API](../../../rvk-filter/docs/administration-api.md).

**Следующий шаг:** F06.3 list/detail UI поверх готового сервиса: обычный/JSON редактор,
подтверждения delete/transfer, import/export controls, точечные view/menu policies, проверка
настоящего рендеринга. Затем SQL runbook, оставшийся F05/F07 и F08. **render not browser-verified**;
app views и зависимость аддона не менялись, app Gate 2 не запускался. F03/F08–F10/M/N не закрыты.

---

## 2026-09-06 — продолжение F05/F06/F07: versioned CRUD, защита записи и PostgreSQL

Проверено и доведено незавершённое рабочее дерево `../rvk-filter`. Исходный снимок уже содержал
начатые роли/миграции/CRUD, не описанные в журнале. Исправлены отказ HSQL migration (`SELECT 1`),
устаревшие тесты вызовов сервиса и несовместимого payload; добавлена сервисная проверка v1,
перепроверка после блокировки и тесты реальных прав/конкуренции. Коммиты/публичный релиз не создавались.

**Реализовано и проверено в объёме этого этапа:**

- F05: update с ID/expectedVersion, versioned delete/default/copy; имя trim/255, явный scope,
  неизменяемые component/owner/scope; текущие права перечитываются сервером. Shared default больше
  не вызывает setDefaultForMe. Старый versionless Java API deprecated; панель его не использует.
- F05.3: row-level CREATE/UPDATE/DELETE по сохранённому владельцу, защита owner spoofing и
  частичных entity. Добавлены manageAllConfigs/maintainer с композицией resource-ролей;
  обычная панель maintainer по-прежнему показывает только общие/свои. Admin service ещё отсутствует.
- F05.4: общий v1 parser проверяет структуру/version/размер на сервисных save/copy/default;
  компонент дополнительно проверяет известные fields/types на select/default/save/Apply.
  Без каталога серверный сервис не подтверждает существование property и тип значения — это
  остаётся зависимостью registry F06.3. Повреждённые/future записи можно авторизованно удалить.
- F06.1/2: version, NOT NULL defaults/sort, partial unique defaults, CHECK scope/keys,
  PostgreSQL transaction advisory lock. Upgrade сохраняет UUID/payload/audit и исторический
  DATABASECHANGELOG checksum; коллизии останавливают миграцию без выбора/удаления строк.
- F07: save-as-new/update, versioned CRUD события, подтверждение удаления имени/scope,
  несовместимость в списке; формы ждут operationResult и сохраняют ввод при отказе. Выбор другого
  пресета закрывает прежний редактор. Applied условия не меняются побочно при CRUD.

**Проверки:** `./gradlew --no-daemon clean test :rvk-filter:jar`:
HSQL — **371 cases, 362 passed, 9 PostgreSQL-only skipped**; PostgreSQL 16.11 —
**371 passed, 0 failures/errors/skipped**. Новые security/concurrency тесты без тестовой транзакции
повторены; два редактора одной версии не могут оба сохранить изменения. Длинный Unicode payload
реально записан/прочитан через EclipseLink TEXT. Своя БД `rvk_filter_rollout_20260906` удалена после
проверки очистки; main не изменена. Повторный PG test и publishToMavenLocal — BUILD SUCCESSFUL;
JAR содержит 13 проверенных ресурсов (7 JS, XSD, 2 messages и 3 Liquibase XML).

Browser fixtures с production Lit: lifecycle (Apply/Reset/error/retry/chips) и presets
(select/update/new/default/copy/delete/error/retry), **pageErrors=[]**. Ответ сервера имитируется;
Vaadin transport и реальные страницы — **render not browser-verified**. IDE открыта только на
rvk-ws и отвергла инспекцию аддона; применены compile/tests и механическая статика.

Полный [пофайловый отчёт](../../../rvk-filter/docs/rollout-verification.md),
[контракт хранения/безопасности](../../../rvk-filter/docs/persistence-and-security.md),
[воспроизводимые команды](../../../rvk-filter/docs/testing.md).

**Следующий незавершённый шаг:** F06.3 — registry + защищённый administrative service и
list/detail (manageAllConfigs), затем SQL runbook/import/export и оставшийся F07 до F08/M001.
F03/v2, typed entity/JPQL, adapters и F08–F10 не закрыты. Страницы rvk-ws не подключались.
Пропуски старых PostgreSQL-тестов устранены при PG-прогоне, но это не закрывает весь F11.

---

## 2026-09-05 — продолжение: typed defaults и CollectionLoader lifecycle

**Текущий этап:** F02.3 реализован; F04.1 реализован для CollectionLoader, F04.2 частично;
начаты общий валидатор v1 и подтверждение результата UI из F05/F07. F05/F06, app integration
и M001–M095/N001–N045 ещё не выполнены. Страницы rvk-ws пока не изменились.

- Defaults text/select/boolean/чисел, списков и дат имеют каноническую форму. Структурный XML
  поддерживает mode/exact/from/to либо value list. Проверяются тип, ISO, границы и конфликт форм.
- Page defaults и default preset устанавливаются в PreLoad до первого запроса. PostLoad
  подтверждает applied. Несовместимый default блокирует автоматические запросы до Apply/Reset.
- Apply/Reset выполняют одну загрузку. Отмена, ошибка конвертации (включая search) и сбой запроса
  сохраняют прежние applied, строки контейнера, condition и пагинацию. Reset возвращает page default.
- Добавлены buildCondition/buildUserCondition, setBaseCondition, suspend/resume; вклад каждого
  фильтра и его JPQL-параметры изолированы. Повторное подключение того же loader не меняет base.
- JSON snapshots защищены от внешней мутации. Строгий v1 parser отклоняет malformed/future/unknown
  поля; это ещё не полная F05 service/CRUD/security validation и не v2 AND/OR.
- UI получает appliedState/operationResult, ждёт ответа и показывает ошибку/неприменённый draft.
  Chips отражают applied. Добавлены локализованные сообщения текущего шага.

**Проверка:** `./gradlew --no-daemon clean test :rvk-filter:jar` — 345 cases, **343 passed**,
0 failures/errors, **2 legacy PostgreSQL skipped**. Добавленные 10 lifecycle integration cases
пишут/читают реальные HSQL строки без транзакции вокруг теста, очищают свои данные. Проверены
первый запрос, Reset, сбой delegate, отмена PreLoad, invalid search/default, suspend/resume,
изменение host condition и два фильтра. PostgreSQL и app context этим не подтверждены.

7 production JS прошли syntax check; JAR содержит 7 JS и XSD; CLAUDE.md остаётся symlink.
Palantir Google применён к 20 Java-файлам. IDE по-прежнему открыта только для rvk-ws:
**IDE semantic inspection аддона не подтверждена**, таблица ниже — запасная проверка.

**Browser:** production Lit source в отдельном transport fixture, Chromium/Playwright:
draft/applied, pending, error/retry, Reset acknowledgement и chip removal прошли, pageErrors=[];
3 запроса Apply/Apply/Reset, success до ответа не объявлялся. HTML/script сохранены в
rvk-filter/src/test/frontend; воспроизведение — docs/testing.md аддона. Ответ сервера имитируется;
Vaadin transport, тема приложения и реальные app views — **render not browser-verified**.
Проверочный HTTP server и отдельная браузерная сессия остановлены.

| Изменённый/новый файл аддона | Вердикт |
|---|---|
| `docs/release-notes.md` | непустота OK; документация/fixture сверены с текущим контрактом |
| `docs/testing.md` | непустота OK; документация/fixture сверены с текущим контрактом |
| `rvk-filter/src/main/java/ru/fgk/component/rvkfilter/FilterLoaderConditions.java` | compileJava/compileTestJava OK; package/path, непустота OK; clean test OK |
| `rvk-filter/src/main/java/ru/fgk/component/rvkfilter/model/FilterDefaultValues.java` | compileJava/compileTestJava OK; package/path, непустота OK; clean test OK |
| `rvk-filter/src/main/java/ru/fgk/component/rvkfilter/model/FilterStateValidation.java` | compileJava/compileTestJava OK; package/path, непустота OK; clean test OK |
| `rvk-filter/src/test/frontend/lifecycle-check.js` | node --check OK; lifecycle browser fixture OK |
| `rvk-filter/src/test/frontend/lifecycle-fixture.html` | непустота OK; документация/fixture сверены с текущим контрактом |
| `rvk-filter/src/test/java/ru/fgk/component/rvkfilter/RvkFilterLifecycleIntegrationTest.java` | compileJava/compileTestJava OK; package/path, непустота OK; clean test OK |
| `rvk-filter/src/test/java/ru/fgk/component/rvkfilter/model/FilterStateValidationTest.java` | compileJava/compileTestJava OK; package/path, непустота OK; clean test OK |
| `rvk-filter/src/test/java/ru/fgk/component/rvkfilter/xml/RvkFilterLoaderIntegrationTest.java` | compileJava/compileTestJava OK; package/path, непустота OK; clean test OK |
| `rvk-filter/src/test/java/ru/fgk/component/rvkfilter/xml/RvkFilterSchemaTest.java` | compileJava/compileTestJava OK; package/path, непустота OK; clean test OK |
| `rvk-filter/src/test/java/ru/fgk/component/rvkfilter/xml/RvkFilterXmlValidationTest.java` | compileJava/compileTestJava OK; package/path, непустота OK; clean test OK |
| `docs/architecture.md` | непустота OK; документация/fixture сверены с текущим контрактом |
| `docs/examples/full-view.xml` | XML parsing OK; declaration XSD/runtime tests OK (ограничение layout.xsd ниже) |
| `docs/frontend-contract.md` | непустота OK; документация/fixture сверены с текущим контрактом |
| `docs/java-api.md` | непустота OK; документация/fixture сверены с текущим контрактом |
| `docs/xml-api.md` | непустота OK; документация/fixture сверены с текущим контрактом |
| `rvk-filter/src/main/java/ru/fgk/component/rvkfilter/RvkFilter.java` | compileJava/compileTestJava OK; package/path, непустота OK; clean test OK |
| `rvk-filter/src/main/java/ru/fgk/component/rvkfilter/RvkFilterConfigurer.java` | compileJava/compileTestJava OK; package/path, непустота OK; clean test OK |
| `rvk-filter/src/main/java/ru/fgk/component/rvkfilter/condition/DateRangeResolver.java` | compileJava/compileTestJava OK; package/path, непустота OK; clean test OK |
| `rvk-filter/src/main/java/ru/fgk/component/rvkfilter/condition/FilterConditionBuilder.java` | compileJava/compileTestJava OK; package/path, непустота OK; clean test OK |
| `rvk-filter/src/main/java/ru/fgk/component/rvkfilter/condition/ValueConversionException.java` | compileJava/compileTestJava OK; package/path, непустота OK; clean test OK |
| `rvk-filter/src/main/java/ru/fgk/component/rvkfilter/model/FilterState.java` | compileJava/compileTestJava OK; package/path, непустота OK; clean test OK |
| `rvk-filter/src/main/java/ru/fgk/component/rvkfilter/model/FilterValue.java` | compileJava/compileTestJava OK; package/path, непустота OK; clean test OK |
| `rvk-filter/src/main/java/ru/fgk/component/rvkfilter/xml/RvkFilterLoader.java` | compileJava/compileTestJava OK; package/path, непустота OK; clean test OK |
| `rvk-filter/src/main/java/ru/fgk/component/rvkfilter/xml/RvkFilterXmlSupport.java` | compileJava/compileTestJava OK; package/path, непустота OK; clean test OK |
| `rvk-filter/src/main/resources/META-INF/frontend/src/component/rvk-filter/rvk-filter.js` | node --check OK; lifecycle browser fixture OK |
| `rvk-filter/src/main/resources/ru/fgk/component/rvkfilter/messages.properties` | обе locale обновлены; context test OK; новые сообщения проверены в коде |
| `rvk-filter/src/main/resources/ru/fgk/component/rvkfilter/messages_ru.properties` | обе locale обновлены; context test OK; новые сообщения проверены в коде |
| `rvk-filter/src/main/resources/rvk-filter.xsd` | XML parsing OK; declaration XSD/runtime tests OK (ограничение layout.xsd ниже) |
| `rvk-filter/src/test/java/ru/fgk/component/rvkfilter/RvkFilterDataLoaderTest.java` | compileJava/compileTestJava OK; package/path, непустота OK; clean test OK |
| `rvk-filter/src/test/java/ru/fgk/component/rvkfilter/RvkFilterSavedFiltersTest.java` | compileJava/compileTestJava OK; package/path, непустота OK; clean test OK |
| `rvk-filter/src/test/java/ru/fgk/component/rvkfilter/condition/FilterConditionBuilderTest.java` | compileJava/compileTestJava OK; package/path, непустота OK; clean test OK |

Сложные loader adapters, export/count paths конкретных страниц и изоляция старого режима
проверяются на этапе F08/M. UI CRUD пресетов, полномочия записи, PostgreSQL migration/version,
admin screen и пилот остаются следующей работой; весь rollout завершённым не считается.

---

Ниже сохранён отчёт предыдущего этапа; его численные результаты относятся к F02.1.


## 2026-09-05 — F02.1, строгий XML-контракт

Репозиторий реализации: соседний `rvk-filter`. Начальная ревизия `54bf5d7`.
Изменения оставлены в рабочем дереве. В `rvk-ws` изменены только документы этого пакета;
зависимость аддона и страницы приложения пока не подключались.

**F02.1 реализован. F02.4 выполнен частично. Остальные этапы остаются открыты.**

Сделано:

- Полная структурная проверка выполняется до создания компонента. Проверяются неизвестные
  атрибуты/элементы, повторные singleton-элементы, пустые обязательные значения, уникальность
  field id и option value, допустимые типы и `order` в диапазоне Java int.
- При включённых пресетах обязателен стабильный component id. Имена поля и компонента вместе с
  полным origin view включены в диагностику; отсутствующий loader имеет понятное сообщение.
- Boolean-атрибуты принимают `true/false/1/0`. Опечатки отклоняются, пустые необязательные значения
  обрабатываются по документированным defaults. Исправлен разбор `visible=1` стандартным loader.
- Корневой контракт перечисляет поддержанные размеры, видимость и существующий `css`.
  Необрабатываемые `colspan/alignSelf/justifySelf` исключены из XSD и отклоняются runtime.
- Сохранены metadata type/label/enum options, приоритет явных значений и проверка property path.
  Метаданные конечной подписи пути сверены с `MessageTools` Jmix 3.0.0. Опции у non-select типов
  теперь отклоняются после определения типа, вместо игнорирования.
- Сохранён поиск contains/equals/startsWith и equals для нестроковых свойств; отсутствие
  searchProperty выключает поиск. Пустые необязательные search-атрибуты используют defaults.
- В XSD добавлен import layout; исправлены список атрибутов и тип order. Стандартный валидатор
  проверяет обе документированные декларации. В full-view.xml добавлен отсутствовавший itemsDl.
- Добавлены 75 тестов: 57 проверок XML, 10 XSD/examples и 8 интеграции loader с Jmix beans.
  [XML-контракт аддона](../../../rvk-filter/docs/xml-api.md) обновлён вместе с кодом.

## Выполненная проверка

Команды из корня `rvk-filter`:

```bash
./gradlew --no-daemon :rvk-filter:compileJava
./gradlew --no-daemon :rvk-filter:test --tests 'ru.fgk.component.rvkfilter.xml.*'
./gradlew --no-daemon clean test :rvk-filter:jar
./gradlew --no-daemon publishToMavenLocal
```

Итоговый clean test: **301 test cases, 299 passed, 0 failures/errors, 2 skipped**.
Два skipped — существующие PostgreSQL-проверки уникальности; они не закрывают F05/F06.
Spring-контекст поднимается с HSQLDB по существующей конфигурации аддона. Новые интеграционные
тесты не пишут в БД, не обёрнуты транзакцией и не создают отдельную конфигурацию Spring.
Factory detached-компонента заменена в тесте; loader, размерные настройки, message resolver,
metadata/configurer и data components — настоящие Spring/Jmix beans.
В starter нет собственных тестов (`NO-SOURCE`); он компилируется.

JAR проверен: 7 frontend JS, rvk-filter.xsd, оба messages-файла и 2 Liquibase XML присутствуют
и непусты. App-specific production imports отсутствуют. CLAUDE.md остаётся ссылкой на AGENTS.md.
Java отформатирован Palantir 2.90.0 в стиле Google. `git diff --check` — без ошибок.
Локальная Maven-публикация служит разработке; релиз фиксированной версии для F08 не выполнен.

## Статическая проверка по файлам

IDE MCP отклонила projectPath `rvk-filter`: открыт только `rvk-ws`. Поэтому IDE semantic
inspection для всех указанных файлов **не подтверждена**; нужен повтор после открытия аддона
как самостоятельного Gradle-проекта. Использован запасной путь проверки.

Пути в таблице относительно `rvk-filter`:

| Файл | Вердикт запасной проверки |
|---|---|
| `rvk-filter/src/main/java/ru/fgk/component/rvkfilter/xml/RvkFilterXmlSupport.java` | compileJava OK; структурные unit tests OK; package/path и непустота OK |
| `rvk-filter/src/main/java/ru/fgk/component/rvkfilter/xml/RvkFilterLoader.java` | compileJava OK; 8 loader integration tests OK; используемые Jmix API сверены с JAR 3.0.0 |
| `rvk-filter/src/main/java/ru/fgk/component/rvkfilter/RvkFilterConfigurer.java` | compileJava OK; существующие metadata tests и новые проверки несовместимых options OK |
| `rvk-filter/src/test/java/ru/fgk/component/rvkfilter/xml/RvkFilterXmlValidationTest.java` | compileTestJava OK; 57/57 passed; package/path и непустота OK |
| `rvk-filter/src/test/java/ru/fgk/component/rvkfilter/xml/RvkFilterSchemaTest.java` | compileTestJava OK; 10/10 passed с ограничением resolver ниже |
| `rvk-filter/src/test/java/ru/fgk/component/rvkfilter/xml/RvkFilterLoaderIntegrationTest.java` | compileTestJava OK; 8/8 passed; без записи данных и подмен Spring beans |
| `rvk-filter/src/main/resources/rvk-filter.xsd` | XML parsing OK; схема аддона компилируется и валидирует примеры с resolver ниже |
| `docs/examples/full-view.xml` | XML parsing OK; rvkFilter declaration прошла XSD/runtime structural validation; ссылка на itemsDl проверена |
| `docs/xml-api.md` | Контракт сверен с loader/XSD; локальные ссылки проверены |

Изменённые README.md, 02-xml-api.md и этот журнал в `specs` проверены на непустоту и локальные
ссылки; они исключены из основного Git, как описано в README пакета.

## Ограничения и следующий шаг

- **render not browser-verified.** Страницы, кнопки и поля приложения не менялись. XML-примеры
  используют условную entity Item; их declarations проверены, открытие реальных views ещё не
  выполнено. Применение видимости/размеров проверено на серверном компоненте, фактическая отрисовка
  и скрытие search в браузере остаются F11.
- Полная layout.xsd Jmix 3.0.0 не компилируется JDK XSD 1.0: `cos-all-limited.1.2`, строка 1670,
  расширение xs:all в collectionValidatorType. Resolver берёт из JAR ровно неизменённые
  resourceString/componentSize/hasSize, от которых зависит rvk-filter. Это не доказывает валидность
  полной схемы Jmix и не закрывает Studio metadata и всю F02.4.
- В текущем этапе не менялись JSON schema, defaults/state lifecycle, presets/security и БД.
  A14 исправлен; A15 исправлен частично. Остальные P0 из F01 остаются блокерами пилота.
- Следующая работа: F02.3 + F04.1/2 — типизированные исходные значения, корректные Apply/Reset,
  первый запрос и владение вкладом в loader; затем F05/F06 до подключения пилотных страниц.
