# Результат T02

Таск: [task.md](task.md)
Итерация: 1
Обновлено: 2026-09-16

## Что реализовано

На шести основных списках раздела «Контейнеры» (реестр, ремонты,
освидетельствования, акты, договоры, гарантийные условия) панели штатных
текстовых фильтров и пар «с/по» заменены на `flt:rvkFilter` со строкой поиска,
набором условий и пресетами. Фильтры по справочникам `cnt_*` остались штатными
`propertyFilter` и стоят в XML выше `rvkFilter`, но теперь это выбор из
справочника: `property` — сама ссылка, `operation="EQUAL"`, внутри
`entityComboBox` с `itemsContainer` и `entity_clear`. Java-контроллеры, гриды,
панели кнопок, lookup-действия и фасеты не менялись. Реализация завершена;
браузерный проход оставлен проверяющему.

Ловушка префикса `container_` на `rvkFilter` не сработала: поиск и условие по
`container.contNum` в ремонтах и освидетельствованиях работают на живой
загрузке, запасной `jpqlFilter` из плана не понадобился.

## Изменения и решения

- Шесть файлов
  `app/src/main/resources/ru/fgk/ws/app/container/view/{container,containerrepair,containersurvey,containeract,containercontract,containerwarranty}/*-list-view.xml`:
  добавлен `xmlns:flt="http://fgk.ru/schema/rvk-filter"`, в `<data>` добавлены
  `collection` + `loader readOnly` по справочникам выпадающих списков
  (`fetchPlan extends="_instance_name"`, `order by` поле названия), в
  `filterPanel` остались только фильтры-справочники, сразу за ним — блок
  `flt:rvkFilter` перед `buttonsPanel`.
- Порядок «штатные фильтры выше `rvkFilter`» зафиксирован комментарием в
  каждом из шести файлов: он объясняет причину (base-условие захватывается при
  `setDataLoader`), а не пересказывает разметку.
- `searchProperty`: `contNum`, `container.contNum`, `container.contNum`,
  `actNum`, `contractNum`, `contract.contractNum`. `searchOperation`,
  `configurationKey`, `enableSavedFilters` не задаются — по умолчанию
  `contains` и включённые пресеты, ключ пресетов образуется из
  `<viewId>.rvkFilter`.
- Подписи выпадающих списков берутся из метаданных ссылки: они дословно
  совпадают с прежними подписями панелей («Модель», «Тип», «Размер», «Вид
  ремонта», «Вид освидетельствования», «Тип акта», «Тип договора», «Вид
  гарантии», «Гарантия на контейнеры типа»), поэтому явный `label` не нужен, а
  прежние ключи `filter.model|type|size|repairType|surveyType|actType|contractType|warrType|contType`
  удалены как неиспользуемые.
- Поля по пути через ссылку несут явный `label`. Там, где для подписи был
  прежний ключ view, он переиспользован (`filter.owner`, `filter.container`,
  `filter.org`, `filter.repContract`, `filter.contract`, `filter.id`).
  Скрытым полям по пути, у которых такого ключа не было, подпись задана
  ссылкой на подпись самой ссылки в бандле сущностей
  (`msg://ru.fgk.ws.app.container.entity/Container.genChar`,
  `…/ContainerRepair.defect`, `…/ContainerRepair.defectReason`,
  `…/ContainerRepair.repSt`, `…/ContainerRepair.rejectSt`,
  `…/ContainerRepair.repStInstr`,
  `…/ContainerWarranty.warrBegin`) — новых ключей не заводилось.
- Даты — `type="dateRange"` (одно поле вместо пары «с/по»), boolean —
  `type="boolean"`, «ИД» гарантии — `operation="EQUAL"`. Числам `type` не
  задаётся: аддон по метаданным даёт `number` с выбором операции, что для
  масс, стоимостей и НДС удобнее диапазона. Id полей — имя свойства, для пути
  camelCase без точки; `order` — шаг 10, сначала видимые поля в порядке
  прежних панелей, затем скрытые.
- Состав полей — по таблице «Страницы» плана. Сокращать не пришлось; не
  добавлялись только поля аудита, `FileRef` (`document`, `surveyAct`,
  `actDoc`) и конечные ссылки на entity: `ContainerRepair.repByWarr` и
  `warrOnRep` ссылаются на `ContainerWarranty`, чьё имя экземпляра —
  вычисляемое `@JmixProperty`, фильтровать по нему нельзя, а сам entity picker
  в аддоне пока не поддержан.
- `app/src/main/resources/ru/fgk/ws/app/messages_ru.properties`: удалены 29
  ключей `container*ListView.filter.*` (все «с/по» и подписи ушедших текстовых
  фильтров-справочников). Остались ровно те 10 ключей, которые используются
  как `label` полей по пути; сверка «ключи в бандле ↔ `msg://` в XML» сходится
  в обе стороны. В `app` один locale-файл.
- Новый тест
  `app/src/test/java/ru/fgk/ws/app/container/view/ContainerRvkFilterUiTest.java`
  (3 сценария). Данные создаются `DataManager` с уникальным маркером в номере
  контейнера, убираются в `@AfterEach` через `JdbcTemplate`, поэтому проверки
  не зависят от содержимого базы.
- Отдельных тестов на открытие актов и гарантий не потребовалось: список
  договоров, гарантийных условий и актов уже открывает
  `ContainerContractViewsUiTest` («Списки договоров, гарантийных условий и
  актов открываются»).

Работа велась в worktree `../worktrees/rvk-ws/cyan-fennel/rvk-ws` (ветка
`f/container`). Незакоммиченные файлы закрытой работы и области T01/T03 не
трогались; коммитов не делалось.

## Предварительные проверки

| Команда или сценарий | Результат |
|---|---|
| `./gradlew spotlessApply :app:compileJava :app:compileTestJava` | BUILD SUCCESSFUL |
| `./gradlew :app:test --tests 'ru.fgk.ws.app.container.view.*'` | BUILD SUCCESSFUL, 26 passing (51.6s) |
| `./gradlew spotlessCheckAll` | BUILD SUCCESSFUL |
| Разбор каждого из шести XML парсером, проверка размера | без ошибок, пустых файлов нет |
| Сверка всех `msg://` шести файлов с `messages_ru.properties` | все 27 ключей резолвятся |
| Остаток ключей `container*ListView.filter.*` в бандле | 10 ключей, все используются |

`ContainerRvkFilterUiTest` — три зелёных сценария: поиск по
`container.contNum` в ремонтах, `dateRange` по `dateBegin` в
освидетельствованиях, пересечение штатного `modelFilter` и поиска на реестре
плюс сохранение условия модели после `filter.reset()`.

IDE-инспекция (JetBrains `get_file_problems`) в этой сессии недоступна: Gate 1
пройден по правилу отката — `compileJava` плюс механические проверки
дескрипторов. Шесть XML стоит переинспектировать в сессии, где инспекция есть.

Не запускалось, оставлено проверяющему: полный пакет тестов раздела
(`ru.fgk.ws.app.container.*`), браузерный проход по шести страницам, пресеты
под ролями, регрессия копирования/удаления/Excel-экспорта. Критерии C1 и C3 в
части отрисовки браузером не проверялись — `render not browser-verified`.

## Для независимой проверки

Окружение: worktree `../worktrees/rvk-ws/cyan-fennel/rvk-ws` (ветка
`f/container`), PostgreSQL из `docker/docker-compose.yml` (контейнер
`docker-rvk-db-1`, `localhost:5432`, схема `main_rvk_ws`), локальный override
`app/src/test/resources/application-test-local.properties` на месте. Перед
тестами — `docker info` и `(cd docker && docker compose ps)`.

```bash
cd ../worktrees/rvk-ws/cyan-fennel/rvk-ws
./gradlew :app:test --tests 'ru.fgk.ws.app.container.*'
./gradlew spotlessCheckAll
```

Браузерный сценарий: `./gradlew :app:bootRun` в фоне, дождаться
`/actuator/health` = UP, зайти на `http://localhost:8080/local-login` как
`user`/`user`. На каждой из шести страниц: строка поиска сужает грид (реестр —
номер контейнера, ремонты и освидетельствования — номер контейнера, акты —
номер акта, договоры — номер договора, гарантии — номер договора); добавить
условие (дата-диапазон, текст по организации, «ИД» гарантии); выбрать значение
в выпадающем списке справочника над панелью — грид сужается вместе с условием
`rvkFilter`; ✕ на чипе снимает условие; Reset возвращает выборку при
сохранённом выборе справочника; сохранить личный пресет, переоткрыть страницу,
выбрать его. Дополнительно — открыть реестр как lookup из формы ремонта
(кнопка выбора контейнера) и проверить `rvkFilter` в диалоге. В серверном логе
0 `ERROR`, сырых `msg://` на страницах нет.

Тестовых данных для браузера сценарий не требует сверх того, что уже есть в
схеме; при пустых справочниках выпадающие списки будут пусты — это ожидаемо,
не дефект.

## Ограничения и связанные изменения

- Личные пресеты работают только с правом из T01 (`UiMinimalRole extends
  RvkFilterUserRole`) — этот пункт браузерного сценария имеет смысл после
  проверенного T01 (проверка 001 — pass).
- Числовые поля (`maxGrossMass`, `tareMass`, `payload`, `capacity`, `repCost`,
  `costWithVat`, `vatRub`, `vat`, `warrDuration`, `inspInDays`, `penalty`,
  `id`) остались скрытыми полями типа `number` — это выбор операции и одно
  значение, а не диапазон, как записано в плане. Поведение равнозначное,
  отличие названо здесь намеренно.
- Доказательства других тасков не затронуты: изменены только шесть XML
  основных списков, свои ключи бандла и добавлен новый тест; области T01 и T03
  не пересекаются.
