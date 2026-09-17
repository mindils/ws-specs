# Результат T05

Таск: [task.md](task.md)
Итерация: 1
Обновлено: 2026-09-17

## Что реализовано

Jar аддона в `libs/` обновлён до 0.0.2 (поддержка типов `entity`/`entityList`),
и все справочные ссылки на семи страницах раздела переехали внутрь
`flt:rvkFilter` как поля выбора сущности. `formLayout id="filterPanel"` со
штатными `propertyFilter` + `entityComboBox`, комментарий о порядке панелей и
справочные `collection`/`loader` удалены — штатных фильтров на 19 списках
раздела не осталось. Текстовые поля по пути (`owner.shortname`,
`org.shortname`, `repContract.contractNum`, `contract.contractNum`,
`defect.defectName`, `defectReason.defectReasonName`, `warrBegin.actTypeName`,
`genChar.charName`) заменены entity-полями по самой ссылке.

В браузере на реестре поле «Модель» отдаёт опции с сервера по вводу («1СС-4» →
одна опция «1СС-40»), кнопка «Выбрать…» открывает диалог «Модели контейнеров»,
после «Найти» грид сужается с 8 до 3 строк, в поле остаётся название с кнопкой
«Очистить выбор». Реализация завершена, блокеров нет.

Пересборка dev-бандла Vaadin (шаг 6 «Реализации») не понадобилась: поля
сущности отрисовались и заработали на бандле от 2026-09-14 без удаления
`app/src/main/bundles`.

## Изменения и решения

- `libs/rvk-filter-0.0.2.jar`, `libs/rvk-filter-starter-0.0.2.jar` — собраны
  `./gradlew clean test :rvk-filter:jar :rvk-filter-starter:jar
  -PaddonVersion=0.0.2` из рабочего дерева `../../../../rvk-filter`
  (незакоммиченное состояние), тесты аддона зелёные. Пара 0.0.1 убрана из Git
  (`git rm`, deletions в staging) и с диска, новая пара добавлена в staging.
  `rvkFilterVersion = '0.0.2'` в `app/build.gradle`; в `libs/README.md` версии
  в командах обновлены и добавлен абзац про поставку 0.0.2.
- Семь XML в `app/src/main/resources/ru/fgk/ws/app/container/view/`
  (`container`, `containerrepair`, `containersurvey`, `containeract`,
  `containercontract`, `containerwarranty`, `cntdefect`): entity-поля по
  таблице таска — `<flt:propertyFilter id="<ссылка>" property="<ссылка>"/>` без
  `type`, `operation`, `lookup` и без `label`. Единственный явный `label` —
  `contract` на гарантиях (метаданные дают «Гарантия к договору»).
  `searchProperty`, fetchPlan основных коллекций, гриды, панели кнопок,
  фасеты и Java-контроллеры не тронуты.
- `order` (шаг 10) внутри каждой страницы: сначала видимые entity-поля в
  порядке прежних выпадающих списков, затем прочие видимые поля в прежнем
  порядке, затем скрытые в прежнем порядке (скрытое entity-поле занимает место
  текстового поля, которое заменило). Формулировка таска «entity-поля первыми»
  прямо покрывает только бывшие выпадающие списки; видимые поля оставлены выше
  скрытых, как было на всех страницах раздела до T05.
- `messages_ru.properties`: удалены семь ключей, чьи подписи совпали с
  атрибутами entity (`containerListView.filter.owner`,
  `containerRepairListView.filter.org`,
  `containerRepairListView.filter.repContract`,
  `containerSurveyListView.filter.org`,
  `containerContractListView.filter.org`,
  `containerActListView.filter.contract`,
  `cntDefectListView.filter.defectReason`). Остались ровно четыре ключа
  `…ListView.filter.*` контейнерных view, и все четыре используются из XML —
  сверка сделана в обе стороны.
- `ContainerRvkFilterUiTest`: вместо теста штатного фильтра —
  `containerList_entityConditionIntersectsSearch` (условие `model` по id
  вместе с поиском даёт один контейнер, после `reset()` возвращаются все три
  контейнера с маркером) и новый `repairList_contractEntityCondition` (условие
  `repContract` по id даёт один ремонт из двух). Helper `modelFilter` и импорт
  `PropertyFilter` удалены, добавлены фабрика `contract(...)` и уборка
  `delete from cnt_contract`, Javadoc класса обновлён. После `reset()`
  выборка не ограничена ничем, поэтому проверка сначала отбирает строки с
  маркером, а потом сверяет их состав.

## Предварительные проверки

| Команда или сценарий | Результат |
|---|---|
| `./gradlew spotlessApply :app:compileJava :app:compileTestJava` | BUILD SUCCESSFUL |
| `./gradlew :app:test --tests 'ru.fgk.ws.app.container.view.*'` | BUILD SUCCESSFUL, 27 тестов, 0 падений; `ContainerRvkFilterUiTest` — 4 теста зелёные |
| Gate 1 без IDE: XML разбираются парсером, нет BOM и пустых файлов, `<propertyFilter` и `filterPanel` в `container/view/` не встречаются | чисто |
| Браузерный smoke: реестр под `user_read`, поле «Модель» — подсказки по вводу, «Выбрать…», «Найти» | 8 → 3 строки, 0 `ERROR` в логе приложения |

Не запускалось, оставлено проверяющему: полный `:app:test`, команды C3 (весь
пакет `ru.fgk.ws.app.container.*`, `nsi.view.vdepo.*`, `UiMinimalRoleTest`),
`./gradlew spotlessCheckAll`, браузерные сценарии C5 целиком (ремонты,
справочник «Виды неисправностей» под `user_nsi`, пресет с entity-условием,
негативные сценарии и регрессии), проход под `user_edit`.

## Для независимой проверки

Окружение: Docker-контейнеры из `docker/docker-compose.yml` подняты
(`docker-rvk-db-1` на `localhost:5432`), тесты читают
`app/src/test/resources/application-test-local.properties` (схема
`main_rvk_ws`). Команды C3 и `spotlessCheckAll` — из корня worktree.

Приложение для браузера: `./gradlew :app:bootRun` в фоне, профиль `local`,
порт 8082, готовность по `Started AppApplication` в логе и `200` на
`http://localhost:8082/local-login`; гасить только свой процесс. Вход через
`/local-login`: локального `user`/`user` в этой схеме нет, роли
`user_read` / `user_nsi` / `user_edit` заведены в `main_rvk_ws.sso_user`,
пароли хранятся там же с префиксом `{noop}` и читаются запросом к БД.

Сценарии, которые стоит пройти в браузере: реестр (`/containers`) — поле
«Модель» по вводу, «Выбрать…» → `cnt_CntModel.list` и возврат выбора,
пересечение с поиском, Reset; ремонты — «Исполнитель» (`VOrgPassport`, кнопки
выбора нет, только поиск по вводу) и «Договор на ремонт» через lookup;
справочник «Виды неисправностей» под `user_nsi` — скрытое поле «Причина
неисправности» через «Добавить поле»; пресет с entity-условием после
переоткрытия страницы показывает название, а не id. Панель фильтра
разворачивается кнопкой «Фильтр», изменение условия применяется кнопкой
«Найти» внутри панели (до этого панель показывает «Есть неприменённые
изменения»).

Данные на 2026-09-17 в `main_rvk_ws`: 9 контейнеров (`1АА-40` — 4, `1СС-20` —
2, `1СС-40` — 3, в гриде под `user_read` видно 8), 7 ремонтов, 4 договора.

## Ограничения и связанные изменения

- Gate 1 прошёл без Jmix-осведомлённой IDE-инспекции: в сессии нет JetBrains
  MCP, поэтому семь изменённых XML проверены только компиляцией, разбором
  парсером, механическими проверками дескрипторов и живым открытием реестра в
  браузере. Остальные шесть страниц статически на нерезолвящийся `msg://` и
  property path не инспектировались — это стоит закрыть проходом проверяющего.
- Доказательства T02 про выпадающие списки над `rvkFilter` этой работой
  обесценены: такого UI больше нет. Статус T02 не меняю — [Q01](../../questions/Q01.md)
  решил, что T01–T04 приняты, новый объём вынесен в T05, а повторный проход
  делает T04.
- В ветке лежат два пустых файла вне области таска —
  `app/src/main/resources/ru/fgk/ws/app/diadoc/view/packetdocument/packet-document-detail-view.xml`
  и `…/packet-document-list-view.xml` (закоммичены в `0c510be9f`). К T05
  отношения не имеют, но по правилам проекта пустой `*-view.xml` отравляет
  реестр view, поэтому отмечаю находку.
- Коммитов не делал; удаление пары jar 0.0.1 и добавление пары 0.0.2 лежат в
  staging.
