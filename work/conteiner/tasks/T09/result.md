# Результат T09

Таск: [task.md](task.md)
Итерация: 1
Обновлено: 2026-09-15

## Что реализовано

Журнал изменений Jmix Audit включён для всех 22 контейнерных entity, и появился
переиспользуемый фрагмент «История записи». Создание, изменение и мягкое
удаление любой `cnt_*` записи через `DataManager` попадают в
`audit_entity_log` как CREATE, MODIFY и DELETE с бизнес-атрибутами; в MODIFY
хранятся старое и новое значение изменённого поля. Штатный экран аддона
`entityLog.view` выведен в меню «Прочее». Все критерии C1–C5 реализованы,
блокеров нет.

Фактическое поведение:

- 22 строки в `audit_logged_entity` (`auto` и `manual` = true) и 116 строк в
  `audit_logged_attr` создаются миграцией; состав атрибутов совпадает с тем,
  что предлагает экран `entityLog.view`.
- Мягкое удаление пишется именно как DELETE, а не как MODIFY: EclipseLink
  различает soft delete и обычное изменение до вызова слушателей аддона.
  В записи DELETE значения атрибутов лежат в «старом» поле.
- Ссылки записываются подписью экземпляра и его id. Переименование справочника
  после события не меняет уже записанную историю — журнал хранит строки на
  момент события.
- Фрагмент по `entityName` и `entityId` показывает историю ровно одного
  экземпляра, новее сверху; выбор строки наполняет нижний грид атрибутами
  (атрибут, старое значение, новое значение); без выбора нижний грид пуст; без
  заданной цели пусты оба.
- Повторное применение миграции ничего не дублирует: оба changeSet-а
  идемпотентны сами по себе (`INSERT ... WHERE NOT EXISTS`), не только за счёт
  журнала Liquibase.

## Изменения и решения

Новые файлы:

- `app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/04-data/cnt_entity_log.xml`
  — два changeSet-а author `cnt`: entity и их атрибуты.
- `app/src/main/java/ru/fgk/ws/app/container/view/fragment/entitylog/EntityLogFragment.java`
  и `app/src/main/resources/ru/fgk/ws/app/container/view/fragment/entitylog/entity-log-fragment.xml`.
- `app/src/test/java/ru/fgk/ws/app/container/ContainerEntityLogIT.java`,
  `app/src/test/java/ru/fgk/ws/app/container/view/fragment/EntityLogFragmentUiTest.java`.

Изменены добавлением строк: `ru/fgk/ws/app/menu.xml` (группа `audit` с пунктом
`entityLog.view` внутри `other_menu`, рядом с Entity Inspector) и
`ru/fgk/ws/app/messages_ru.properties` (подпись группы меню и пять ключей
фрагмента).

Существенные решения:

- **Состав атрибутов.** Журналируются хранимые несистемные атрибуты. Системные
  (`id`, `version`, аудит создания/изменения, мягкое удаление) аддон отбрасывает
  сам (`MetadataTools.isSystem`), и экран `entityLog.view` их не предлагает.
  Вычисляемые `@JmixProperty`-подписи `linkName`, `repairName`, `surveyName`,
  `warrantyName` в настройку не включены: они не хранятся, полностью выводятся
  из уже журналируемых атрибутов, а их вычисление внутри аддона обращается к
  ссылкам, которых в момент удаления может не быть в fetch plan, — тогда аддон
  проглотил бы исключение и потерял запись целиком. Уточнение записано в
  [contracts.md](../../contracts.md), раздел «История (EntityLog)».
- **Идемпотентность вместо preConditions по каждому имени.** Вместо 22 пар
  changeSet-ов с preConditions «нет записи с таким name» — два changeSet-а с
  `INSERT ... SELECT ... WHERE NOT EXISTS`. preConditions остались на
  существование таблиц. Так настройка идемпотентна и при частично заполненной
  таблице, а файл читаем.
- **Свойство `jmix.audit.enabled` не трогали:** его значение по умолчанию
  `true` (`io.jmix.audit.AuditProperties`), `application.properties` не менялся.
- **API фрагмента для хостов:** `setLogTarget(entityName, entityId)` либо
  `setEntityName` / `setEntityId` плюс `refresh()`. Своей загрузки по готовности
  фрагмент не делает — у него нет параметров, пока хост не загрузил запись;
  поэтому вкладка «История» (T03) работает и на ещё не сохранённой записи.
- **Роли не менялись:** READ на `audit_EntityLog` и `audit_EntityLogAttr` уже
  есть в `ContainerReadRole` (добавлено в T02). Для `entityLog.view` политики
  обычных ролей не расширялись — экран для администраторов, как в контракте.

## Предварительные проверки

| Команда или сценарий | Результат |
|---|---|
| `./gradlew :app:compileJava`, `./gradlew :app:compileTestJava` | успешно |
| `./gradlew spotlessApply` | применено, повторная компиляция успешна |
| `./gradlew :app:test --tests "ru.fgk.ws.app.container.ContainerEntityLogIT"` | 4 теста, все зелёные |
| `./gradlew :app:test --tests "ru.fgk.ws.app.container.view.fragment.EntityLogFragmentUiTest"` | 3 теста, все зелёные |
| SQL-прогон обоих changeSet-ов дважды в одной транзакции с откатом | второй проход даёт `INSERT 0 0`; итог 22 entity и 116 атрибутов |
| Механические проверки дескрипторов (`jmix-ide-static-analysis`) | пролог XML, `package`, нет нулевых файлов среди новых, все `msg://` фрагмента резолвятся |

Что покрыто тестами: C1 и C2 — `ContainerEntityLogIT`
(контейнер, справочник `CntModel`, ремонт `ContainerRepair`; CREATE, MODIFY со
старым и новым значением, DELETE); C4 — там же, переименование `CntRepairType`
после события; C5 — там же, состав настройки сверяется с метамоделью (не с
копией списка) и проверяется отсутствие дублей; C3 — `EntityLogFragmentUiTest`,
фрагмент создаётся через `Fragments` и проверяется на двух контейнерах.

Не запускалось, оставлено проверяющему: полный `./gradlew :app:test`,
регрессии по другим модулям, браузерный проход (`entityLog.view` под
администратором, отрисовка фрагмента в реальном UI, локализация подписей
атрибутов в нижнем гриде), проверка на чистой схеме с нуля.

## Для независимой проверки

Окружение: Docker Compose поднят (`docker info`, `(cd docker && docker compose ps)`),
PostgreSQL на `localhost:5432`, схема worktree `main_rvk_ws` задаётся файлами
`app/src/main/resources/application-local.properties` и
`app/src/test/resources/application-test-local.properties`. Worktree —
`/home/mindils/data/dev/fgk/worktrees/rvk-ws/cyan-fennel/rvk-ws`, ветка
`f/container`, изменения не закоммичены.

Команды:

```bash
./gradlew :app:test
./gradlew :app:test --tests "ru.fgk.ws.app.container.ContainerEntityLogIT" \
                    --tests "ru.fgk.ws.app.container.view.fragment.EntityLogFragmentUiTest"
```

SQL для сверки настройки (22 строки, атрибуты без дублей):

```sql
select name, auto_, manual_ from main_rvk_ws.audit_logged_entity
 where name like 'cnt%' order by name;
select e.name, count(a.id) from main_rvk_ws.audit_logged_entity e
  join main_rvk_ws.audit_logged_attr a on a.entity_id = e.id
 where e.name like 'cnt%' group by e.name order by e.name;
```

Браузер: `./gradlew :app:bootRun` в фоне, дождаться `/actuator/health` = UP,
порт 8082 (`server.port` в `application-local.properties`), вход `user` / `user`
через `/local-login`. Сценарий: «Прочее» → «Журнал изменений» →
«Журнал изменений сущностей»; на вкладке «Просмотр» выбрать сущность
`cnt_Container` — видны события по контейнерам; на вкладке «Настройка» у
`cnt_Container` отмечены все бизнес-атрибуты. Записи для просмотра создаются
через любой контейнерный справочник (например, «Справочники → Контейнеры →
Модели контейнеров»): создать, изменить, удалить запись и открыть журнал по
`cnt_CntModel`. Свой процесс `bootRun` останавливать после проверки.

Фрагмент отдельного экрана не имеет: T03 ещё не сделан, поэтому вкладка
«История» карточки не существует. В браузере фрагмент проверить негде — его
поведение закрыто `EntityLogFragmentUiTest`; отрисовка в реальном UI станет
проверяемой вместе с T03.

## Ограничения и связанные изменения

- Доказательства других тасков не затронуты: T01 и T02 меняли только свои
  области, их код не правился. Общие файлы `menu.xml` и `messages_ru.properties`
  изменены добавлением строк.
- `entityLog.view` доступен по политикам администратора; обычные контейнерные
  роли его не открывают — это решение контракта, а не пробел.
- Фрагмент не рендерился в браузере (нет хоста до T03) — в отчёте проверки
  это стоит зафиксировать как `render not browser-verified` для фрагмента;
  `entityLog.view` браузером проверяется уже сейчас.
- [Q03](../../questions/Q03.md) остаётся открытым и здесь не обходился: схема
  `main_rvk_ws` уже починена вручную в T01, новая схема упрётся в ту же
  колонку `pt_repair_packet.pack_checked_code`.
