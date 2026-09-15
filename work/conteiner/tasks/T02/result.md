# Результат T02

Таск: [task.md](task.md)
Итерация: 1
Обновлено: 2026-09-15

## Что реализовано

Экраны ведения 13 контейнерных справочников (13 пар list + detail), три
ресурсные роли и каркас меню. Пользователь с ролью НСИ заводит, правит и
удаляет записи справочников; формы других тасков смогут открывать эти же
списки как lookup. C1, C4 и C5 подтверждены самопроверкой, включая браузерный
проход одного справочника и сценария lookup. C2 подтверждён частично: создание,
изменение и мягкое удаление проверены в браузере под `admin`, отказ удаления по
ссылке — инвариант T01, в UI под ролью НСИ не проверялся. C3 реализован
политиками, но под ролями `container-edit` и `container-read` в браузере не
проходился — пользователей с этими ролями в схеме нет, это объём проверяющего.

Фактическое поведение:

- 26 view-ов `cnt_Cnt*.list` / `cnt_Cnt*.detail` открываются; каждый list даёт
  фильтр по названию, пагинацию, настройку видимости колонок, сохранение
  настроек, действия создать/изменить/удалить и асинхронный экспорт в Excel.
- Каждый list одновременно работает как lookup: `@LookupComponent` на гриде,
  действия `lookup_select` / `lookup_discard` и скрытая панель кнопок, которую
  Jmix показывает в режиме выбора.
- Detail каждого справочника содержит все поля матрицы; подписи полей и колонок
  берутся из message-ключей entity, созданных в T01 (у `CntContainerSize` поле
  `widthF` уже подписано «Длина (фут)»).
- У `CntDefect` причина неисправности — `entityComboBox` с `itemsQuery` по
  `:searchString` плюс действия `entity_lookup` (открывает
  `cnt_CntDefectReason.list`) и `entity_clear`.
- Раздел меню «Справочники → Контейнеры» содержит 13 пунктов. Раздел
  «Контейнеры» верхнего уровня создан пустым — см. решение ниже.
- Роли `container-read`, `container-edit`, `container-nsi-edit` заданы
  аннотациями; тест ролей проверяет состав политик и отсутствие доступа роли
  НСИ к основным записям.

## Изменения и решения

Изменённые области:

- `app/src/main/java/ru/fgk/ws/app/container/view/<13 пакетов>/` — 26
  контроллеров (`<Entity>ListView`, `<Entity>DetailView`).
- `app/src/main/resources/ru/fgk/ws/app/container/view/<13 пакетов>/` — 26
  XML-дескрипторов.
- `app/src/main/java/ru/fgk/ws/app/container/security/` —
  `ContainerReadRole`, `ContainerEditRole`, `ContainerNsiEditRole`.
- `app/src/main/resources/ru/fgk/ws/app/menu.xml` — добавлены раздел
  `container` и подгруппа `nsi_container` с 13 пунктами; существующие пункты не
  тронуты.
- `app/src/main/resources/ru/fgk/ws/app/messages_ru.properties` — 30
  ключей: 26 заголовков view, 4 ключа меню (добавление в конец файла).
- `app/src/test/java/ru/fgk/ws/app/container/security/ContainerRolesTest.java`,
  `app/src/test/java/ru/fgk/ws/app/container/view/ContainerNsiViewsUiTest.java`.

Существенные решения:

- **Раздел `container` создан пустым.** Проверено по исходникам Jmix 3.0.2
  (`io.jmix.flowui.menu.ListMenuBuilder#createListMenu`,
  `menu.xsd/menuType`): пустой `<menu>` валиден по схеме, не ломает разбор и
  просто не отрисовывается — в лог пишется `Menu bar item 'container' is
  skipped as it does not have children`. В прогоне приложения это
  подтвердилось: предупреждение пишется при каждой сборке меню (за смоук — 4
  раза), исключений нет, остальное меню работает. Заглушечный пункт не
  добавлен, как требует таск; раздел станет видимым, когда T03 добавит
  `cnt_Container.list`. В `menu.xml` рядом с разделом оставлен комментарий,
  какие таски добавляют пункты.
- **Поля `Long` показываются `textField`-ом.** `integerField` и `numberField`
  в Jmix типизированы `Integer` и `Double`; сам Jmix для любого `Number`
  генерирует `textField`
  (`io.jmix.flowui.view.template.impl.ComponentXmlFactory#getDatatypeComponentName`),
  конвертацию делает datatype свойства.
- **Поле-подпись (`@InstanceName`) в detail помечено `required="true"`.**
  Таблица «Обязательные поля (UI)» в contracts.md справочники не перечисляет,
  но пустая подпись ломает выбор записи в каждом lookup-е; остальные поля
  справочников необязательны, как и требует общее правило.
- **Экспорт — действие `fgk_async_excel_export`** (`common/action/
  AsyncCollectionExcelExportAction`), а не `async_excel_export` из `core`: в
  `app` используется только оно (28 применений против 0), оно поддерживает
  выбор режима выгрузки и фоновую задачу. Право на саму выгрузку даёт
  существующая роль `async-export-role` (единственная в проекте, кто выдаёт
  политики на `ExportTask`); контейнерные роли её не дублируют — как и все
  остальные feature-роли проекта.
- **Открытие detail — режим по умолчанию (навигация), без `openMode`.**
  `CreateAction`/`EditAction` сами переключаются на диалог, когда list открыт
  в диалоге (`isComponentAttachedToDialog`), поэтому «создать» внутри
  lookup-а не уводит со страницы, а прямой URL detail остаётся рабочим для
  проверки C3.
- **Политики на `audit_EntityLog` / `audit_EntityLogAttr`** (READ + VIEW)
  включены в `ContainerReadRole` и `ContainerEditRole` по таблице ролей
  contracts.md, хотя сам экран истории делает T09.
- **Роли не наследуют друг друга.** `ContainerEditRole` повторяет READ-часть
  явно: по C3 роль `container-edit` должна давать видимость справочников сама
  по себе, а образцы проекта (`DaContract*Role`) тоже не используют
  `extends`.

Поведение, которое стоит знать проверяющему при разборе C3: при праве только
READ Jmix не прячет кнопку «Изменить», а переименовывает её в «Просмотр» и
открывает detail в режиме только чтения (`EditAction#refreshState`,
`#isPermitted`). Кнопка «Создать» при этом недоступна, сохранить из detail
нельзя. Это штатное поведение фреймворка, а не пропуск политики.

## Предварительные проверки

| Команда или сценарий | Результат |
|---|---|
| `./gradlew :app:compileJava :app:compileTestJava` | успешно |
| `./gradlew spotlessApply` | новые файлы отформатированы, чужие не затронуты |
| `./gradlew :app:test --tests "ru.fgk.ws.app.container.security.ContainerRolesTest" --tests "ru.fgk.ws.app.container.view.ContainerNsiViewsUiTest"` | 6 тестов, все зелёные |
| Механические проверки `jmix-ide-static-analysis` по новым файлам | пусто: нет файлов без `package`, нет 0-байтовых, XML-прологи чистые, нет сырых `com.vaadin...Dialog`, `itemsQuery` использует `:searchString` |
| Скрипт: резолв всех 346 ссылок `msg://` в новых дескрипторах и `menu.xml` | все ключи контейнерного раздела резолвятся; непокрытыми остались только ключи чужих бандлов (`io.jmix.*`, `ru.fgk.ws.core`, `ru.fgk.sso`) |
| Скрипт: сверка 75 property-путей, `dataContainer`, `dataLoader`, `focusComponent`, `urlQueryParameters`, `gridColumnVisibility` и ссылок кнопок на actions | расхождений нет |
| Скрипт: сверка view-id в контроллерах, ролях и `menu.xml`; наличие XML по каждому `@ViewDescriptor`; уникальность `@Route` | 26 = 26 = 26, расхождений и дублей нет |
| XML well-formed по 26 дескрипторам и `menu.xml` | ошибок нет |
| Браузер (`playwright-cli`, `bootRun` на :8082, вход `admin`): меню «Справочники → Контейнеры» | группа и все 13 пунктов с русскими подписями и ожидаемыми маршрутами |
| Браузер: «Модели контейнеров» — открытие, создание, изменение, мягкое удаление, фильтр по названию | всё работает; после удаления строка исчезает из списка, в `cnt_model` остаётся с `deleted_date` |
| Браузер: «Неисправности контейнеров» — `entity_lookup` причины: диалог списка → «Создать» внутри диалога → «Выбрать» | форма создания открылась вложенным диалогом (не навигацией), выбранная запись вернулась в `entityComboBox` |
| Браузер: ошибки консоли и серверные исключения за смоук | серверных исключений 0; в консоли единственная ошибка — недоступный корпоративный аватар `info.main.vgk` (вне контура, к таску не относится) |
| Браузер: сырые `msg://` в снимках страниц | не найдено |

Тестовые классы: `ru.fgk.ws.app.container.security.ContainerRolesTest` (4 теста),
`ru.fgk.ws.app.container.view.ContainerNsiViewsUiTest` (2 теста, внутри —
открытие всех 13 list и всех 13 detail на новой записи).

Не запускалось, оставлено проверяющему: полный `./gradlew :app:test`;
браузерный проход по остальным 12 справочникам; работа под ролями
`container-nsi-edit`, `container-edit`, `container-read` (C2 и C3), включая
прямой URL detail; выгрузка в Excel с фильтром (нужна роль `async-export-role`);
отказ удаления записи справочника, на которую ссылается контейнер или ремонт.

Данные смоука убраны: строки `SMOKE-T02-*` в `cnt_model` и `cnt_defect_reason`
удалены физически, обе таблицы снова пусты. Приложение остановлено, порт 8082
свободен.

## Для независимой проверки

Окружение — worktree
`/home/mindils/data/dev/fgk/worktrees/rvk-ws/cyan-fennel/rvk-ws` (ветка
`f/container`), схема `main_rvk_ws` в общем Docker PostgreSQL
(`localhost:5432`), `ws_store` общая, приложение на порту 8082
(`app/src/main/resources/application-local.properties`, не в git). JDBC тестов
— `app/src/test/resources/application-test-local.properties` (не в git).

```bash
docker info && (cd docker && docker compose ps)          # rvk-db должен быть Up
./gradlew :app:compileJava
./gradlew :app:test --tests "ru.fgk.ws.app.container.*"
./gradlew :app:test
./gradlew :app:bootRun                                   # http://localhost:8082
```

На чистой схеме перед первым прогоном нужна разовая правка из
[Q03](../../questions/Q03.md); на `main_rvk_ws` она уже применена.

Вход: `/local-login`, в схеме `main_rvk_ws` заведён единственный пользователь
`admin` с ролью `system-full-access`. Для сценариев C2 и C3 нужны отдельные
пользователи с ролями `container-nsi-edit`, `container-edit`, `container-read`
— их назначает проверяющий (экран «Прочее → Пользователи и роли»); ни один
существующий пользователь эти роли автоматически не получает.

Браузерные сценарии:

- «Справочники → Контейнеры» — 13 пунктов; пройти по каждому, создать запись,
  проверить состав полей по матрице, изменить, удалить, экспорт с фильтром.
- В «Неисправности контейнеров» проверить выбор причины и кнопку lookup-а,
  открывающую список причин.
- Удаление причины неисправности, на которую ссылается неисправность, должно
  отклоняться (`DeletePolicyException`, инвариант T01).
- Под `container-edit` и `container-read`: справочники видны, «Создать»
  недоступно, «Изменить» показано как «Просмотр» и сохранить нельзя, прямой URL
  detail (`/cnt-models/<id>`) открывается только на чтение.
- Раздел «Контейнеры» верхнего уровня в меню пока не отображается — пунктов в
  нём нет (см. решение выше); это ожидаемо до T03.

Изоляция общих ресурсов: своя схема `main_rvk_ws`, порт 8082, свой worktree.
Приложение для браузера проверяющий поднимает сам и гасит только свой процесс.

## Ограничения и связанные изменения

- View-id экранов реестра, ремонтов, освидетельствований, договоров, гарантий
  и актов в роли не выданы — их дописывают T03, T04, T06, T07, как задано
  таском.
- Фрагмент и экран истории (EntityLog) не делались — это T09; в ролях уже
  есть READ на `audit_EntityLog` и `audit_EntityLogAttr`.
- Справочники создаются пустыми, наполнение — T10 ([Q02](../../questions/Q02.md)
  ждёт выгрузок).
- IDE-инспекция (`get_file_problems`) и Context7 MCP в сессии недоступны;
  Gate 1 для новых файлов покрыт `compileJava`, механическими проверками и
  собственными скриптами сверки (msg://, property paths, view-id, XML), а
  render-проход — UI-тестом по всем 26 view. Символы Jmix проверялись по
  исходникам Jmix 3.0.2 из кэша Gradle.
- Рабочая копия содержит незакоммиченные изменения T01 и чужие правки
  (`application.properties`,
  `01-tbl/020-dr_diadoc_wag_oper_repair_contract.xml`); они не трогались.
