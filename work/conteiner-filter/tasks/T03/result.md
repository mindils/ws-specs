# Результат T03

Таск: [task.md](task.md)
Итерация: 1
Обновлено: 2026-09-16

## Что реализовано

На всех 13 списках справочников раздела «Контейнеры» вместо панели с
единственным текстовым `propertyFilter` стоит `flt:rvkFilter`: строка поиска
по полю названия, видимое поле условия по тому же названию и скрытые поля по
остальным колонкам грида. Панель `formLayout id="filterPanel"` удалена во всех
13 файлах, Java-контроллеры не менялись. Все 13 list view и 13 detail view
справочников открываются (`ContainerNsiViewsUiTest`, 2 passing). Реализация
завершена.

## Изменения и решения

- 13 файлов `app/src/main/resources/ru/fgk/ws/app/container/view/cnt*/cnt-*-list-view.xml`:
  добавлен `xmlns:flt="http://fgk.ru/schema/rvk-filter"`, удалён
  `formLayout id="filterPanel"`, перед `buttonsPanel` вставлен
  `<flt:rvkFilter id="rvkFilter" dataLoader="<loaderId>" searchProperty="<поле
  названия>" width="100%">` с блоком `flt:filters`.
- `configurationKey`, `enableSavedFilters`, `css` не задаются — ключ пресетов
  образуется из `<viewId>.rvkFilter`, пресеты включены по умолчанию.
- Порядок полей `flt:filters` повторяет порядок колонок грида (как в образце
  `v-depo-list-view.xml`), `order` — шаг 10. Поле названия справочника несёт
  `defaultVisible="true"`, остальные остаются скрытыми.
- `type` и `label` у полей не задаются: все скалярные колонки справочников —
  это `String` и `Long`, метаданные дают верный редактор и подпись. Явный
  `label` понадобился только полю по пути.
- `CntDefect.defectReason` — поле по пути `defectReason.defectReasonName`,
  `id="defectReasonName"` (camelCase без точки, как `railwayName` у образца),
  `label="msg://cntDefectListView.filter.defectReason"`. Fetch plan списка уже
  содержит `defectReason` с `_instance_name`, менять его не потребовалось.
- `app/src/main/resources/ru/fgk/ws/app/messages_ru.properties` — добавлен один
  ключ
  `ru.fgk.ws.app.container.view.cntdefect/cntDefectListView.filter.defectReason=Причина
  неисправности` (рядом с ключами заголовков `cntdefect`). Других изменений в
  бандле нет; ключей `cnt*ListView.filter.*` у справочников не было, удалять
  было нечего. В `app` один locale-файл, `messages_ru.properties`.
- Состав полей по справочникам (поле названия — первое `defaultVisible`):
  модели (`model`, `tenty`, `dugi`, `trosy`, `vent`), типы контейнеров
  (`code`, `typeName`, `detail`, `kindId`), размеры (`code`, `height`,
  `heightTxt`, `widthF`, `comments`), характеристики (`charName`,
  `charNamePf`), виды характеристик (`propTypeName`, `propGroupName`,
  `propSubgroupName`, `comment`, `propTypeNameLat`), типы актов
  (`actTypeName`, `inclSign`), неисправности (`defectName`,
  `defectReason.defectReasonName`), остальные семь — одно поле названия.
  Сокращать состав относительно колонок грида не пришлось.

Работа велась в worktree `../worktrees/rvk-ws/cyan-fennel/rvk-ws` (ветка
`f/container`). Незакоммиченные файлы закрытой работы и области T01/T02 не
трогались; коммитов не делалось.

## Предварительные проверки

| Команда или сценарий | Результат |
|---|---|
| `./gradlew spotlessApply :app:compileJava` | BUILD SUCCESSFUL |
| `./gradlew :app:test --tests 'ru.fgk.ws.app.container.view.ContainerNsiViewsUiTest'` | BUILD SUCCESSFUL, 2 passing (29.2s) |
| `grep -L 'flt:rvkFilter' cnt*/cnt-*-list-view.xml` | пусто |
| `grep -l 'filterPanel' cnt*/cnt-*-list-view.xml` | пусто |
| `find . -name 'cnt-*-list-view.xml' -size 0` | пусто |
| Проверка пролога XML и разбор каждого из 13 файлов парсером | без ошибок |
| Сверка всех `msg://` из 13 файлов с `messages_ru.properties` | все 14 ключей резолвятся |

IDE-инспекция (JetBrains `get_file_problems`) в этой сессии недоступна:
Gate 1 пройден по правилу отката — `compileJava` плюс механические проверки
дескрипторов. 13 XML стоит переинспектировать в сессии, где инспекция есть.

Не запускалось, оставлено проверяющему: полный пакет тестов раздела
(`ru.fgk.ws.app.container.*`), `spotlessCheckAll`, браузерный проход
(поиск, условие по второй колонке, Reset, сохранение личного пресета).
Критерий C2 браузером не проверялся — `render not browser-verified`.

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
`user`/`user`, меню «Справочники → Контейнеры». Открыть «Модели контейнеров»,
«Виды ремонтов контейнеров», «Неисправности контейнеров» и «Размеры
контейнеров»: строка поиска сужает грид по подстроке названия; добавить
условие по второй колонке (`CntModel.tenty`, у неисправностей — «Причина
неисправности»); Reset возвращает полный список; сохранить личный пресет и
переоткрыть страницу. Проверить, что в серверном логе нет исключений, а на
странице нет сырых `msg://`.

## Ограничения и связанные изменения

- Личные пресеты работают только с правом из T01 (`UiMinimalRole extends
  RvkFilterUserRole`) — этот пункт браузерного сценария имеет смысл после
  проверенного T01 (проверка 001 — pass).
- Доказательства других тасков не затронуты: изменены только 13 XML
  справочников и один новый ключ в бандле, области T01 и T02 не пересекаются.
