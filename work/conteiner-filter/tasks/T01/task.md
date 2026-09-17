# T01 — Право на пресеты фильтра у минимальной роли

Статус: done
План: [../../plan.md](../../plan.md)
Зависимости: нет
Сложность: easy — один файл роли по образцу `WsUserRole extends …`, контракт аддона готов
Сложность проверки: easy — тест роли через `ResourceRoleRepository` без браузера
Актуальная проверка: [checks/001.md](checks/001.md)

## Коротко

Личные пресеты RVK Filter требуют у пользователя роли `rvk-filter-user`, а её
в проекте никому не выдают. Пользователь решил, что сохранять личные фильтры
должен каждый, у кого есть доступ к странице, поэтому минимальная UI-роль
`ui-minimal` наследует роль аддона. По результату любой пользователь UI
сохраняет и выбирает свои пресеты на страницах с `rvkFilter`.

## Результат и контекст

`app/src/main/java/ru/fgk/ws/app/security/UiMinimalRole.java` объявляется
`extends RvkFilterUserRole` (`ru.fgk.component.rvkfilter.security`, jar
`libs/rvk-filter-0.0.1.jar`). Образец наследования —
`app/security/WsUserRole.java` (`extends WnBaseRole, AsyncExportRole, …`).
`RvkFilterUserRole` даёт `EntityPolicy ALL` и `MODIFY` атрибутов на
`RvkFilterConfig`; ограничение «только свои и общие» делает сам сервис аддона
(`RvkFilterConfigServiceImpl.loadForComponent`, проверка владельца в `save`/
`delete`). Row-level роль `rvk-filter-config-row-level` — отдельное
назначение администратора, в коде не появляется (решение плана).

Сейчас `initSavedFilters` у пользователя без роли тихо пишет `warn` и
показывает пустой список пресетов, а «Сохранить» падает с сообщением.

## Область и изоляция

Меняется только `UiMinimalRole.java` и добавляется тест
`app/src/test/java/ru/fgk/ws/app/security/UiMinimalRoleTest.java`. Другие
роли, `messages`, view не трогать. Общие ресурсы: БД и gradle daemon при
запуске тестов. Параллельно с T02, T03; чужие незакоммиченные файлы в
worktree не откатывать.

## Реализация

1. Прочитать skill `jmix-create-resource-role`.
2. `UiMinimalRole extends RvkFilterUserRole`; javadoc на интерфейсе — почему
   право на пресеты живёт в минимальной роли (решение: пресеты у всех, кто
   видит страницу) и что row-level роль назначается отдельно.
3. Тест по образцу `container/security/ContainerRolesTest.java` (наследник
   `BaseIT`, `ResourceRoleRepository.getRoleByCode("ui-minimal")`): среди
   `getResourcePolicies()` есть entity policy на
   `rvkflt_RvkFilterConfig` (имя entity проверить по `RvkFilterConfig` в jar:
   `@JmixEntity(name = …)`) с действием `create` и attribute policy `modify`.

## Критерии приёмки

- C1: `ResourceRoleRepository.getRoleByCode("ui-minimal")` содержит политики
  `RvkFilterUserRole` (entity `RvkFilterConfig`: create/read/update/delete,
  атрибуты modify).
- C2: контекст приложения поднимается, прежние политики `ui-minimal`
  (`MainView`, `LoginView`, `ui.loginToUi`, `KeyValueEntity`, логи) сохранены —
  тест проверяет хотя бы `ui.loginToUi` и `MainView`.
- C3: `spotlessCheckAll` зелёный для изменённых файлов.

## Самопроверка исполнителя

```bash
./gradlew spotlessApply :app:compileJava :app:compileTestJava
./gradlew :app:test --tests 'ru.fgk.ws.app.security.UiMinimalRoleTest'
```

Браузер и полный набор тестов не нужны.

## Независимая проверка

- Та же команда теста плюс `./gradlew :app:test --tests 'ru.fgk.ws.app.container.security.*'`
  (роли раздела не должны измениться) и `./gradlew spotlessCheckAll`.
- Негативный сценарий: убедиться, что `UiMinimalRole` не получил
  `rvkfilter.manageGlobal` / `manageAllConfigs` (наследуется только
  `RvkFilterUserRole`, не `RvkFilterAdminRole`/`RvkFilterMaintainerRole`).
- Живая проверка пресета под пользователем с `ui-minimal` выполняется в T04.

## Прогресс и продолжение

- [x] `UiMinimalRole extends RvkFilterUserRole` с javadoc.
- [x] `UiMinimalRoleTest` (наследник `BaseIT`, 3 проверки), 3 passing.
- [x] Передать результат на независимую проверку: [result.md](result.md),
      итерация 1.
- [x] Независимая проверка: [checks/001.md](checks/001.md), итог pass.

Ближайший шаг: таск T03 (справочники) по плану.
Препятствия: нет
