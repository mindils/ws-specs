# Результат T01

Таск: [task.md](task.md)
Итерация: 1
Обновлено: 2026-09-16

## Что реализовано

Минимальная UI-роль `ui-minimal` наследует роль аддона `rvk-filter-user`,
поэтому любой пользователь UI получает полный доступ к своим записям
`RvkFilterConfig` — список личных пресетов на страницах с `rvkFilter`
загружается, «Сохранить» и «Удалить» работают. Права администрирования
фильтров (`rvkfilter.manageGlobal`, `rvkfilter.manageAllConfigs`) в роль не
попадают: наследуется только `RvkFilterUserRole`. Прежние политики
`ui-minimal` не тронуты. Реализация завершена.

## Изменения и решения

- `app/src/main/java/ru/fgk/ws/app/security/UiMinimalRole.java` —
  `extends RvkFilterUserRole` (`ru.fgk.component.rvkfilter.security` из
  `libs/rvk-filter-0.0.1.jar`) плюс javadoc интерфейса: почему право на
  пресеты живёт в минимальной роли и что row-level роль
  `rvk-filter-config-row-level` администратор назначает отдельно.
- `app/src/test/java/ru/fgk/ws/app/security/UiMinimalRoleTest.java` — новый
  тест роли, наследник `ru.fgk.ws.app.it.BaseIT` (а не копия
  `@SpringBootTest`-настройки, как в `RepairPacketAccountingRoleTest`): у
  наследников `BaseIT` общий кеш контекста Spring. Три проверки:
  состав entity- и attribute-политик на `RvkFilterConfig`, отсутствие
  specific-политик администрирования, сохранность `ui.loginToUi`, `MainView`,
  `LoginView`.
- Имя entity в тесте не зашито строкой: берётся через `Metadata`
  (фактическое — `rvkflt_RvkFilterConfig`, проверено по `@Entity(name = …)` в
  jar).
- `RvkFilterUserRole` даёт `EntityPolicyAction.ALL`, поэтому тест ожидает все
  четыре действия (`read`, `create`, `update`, `delete`) — это шире, чем
  формулировка C1 «create», и соответствует контракту аддона.

Работа велась в worktree
`../worktrees/rvk-ws/cyan-fennel/rvk-ws` (ветка `f/container`). Кроме двух
названных файлов ничего не менялось; `spotlessApply` переформатировал только
их (проверено по времени изменения файлов и `git diff`). Незакоммиченные
файлы закрытой работы не тронуты, коммитов не делалось.

## Предварительные проверки

| Команда или сценарий | Результат |
|---|---|
| `docker info`, `(cd docker && docker compose ps)` | БД `docker-rvk-db-1` поднята, порт 5432 |
| `./gradlew spotlessApply :app:compileJava :app:compileTestJava` | BUILD SUCCESSFUL |
| `./gradlew :app:test --tests 'ru.fgk.ws.app.security.UiMinimalRoleTest'` | 3 passing |

Не запускалось, оставлено проверяющему: `./gradlew spotlessCheckAll`, тесты
раздела (`ru.fgk.ws.app.container.security.*` и остальной контейнерный пакет),
полный `:app:test`, браузерная проверка сохранения пресета под пользователем
с `ui-minimal` (по плану — T04).

## Для независимой проверки

Каталог: `../worktrees/rvk-ws/cyan-fennel/rvk-ws` (ветка `f/container`).
Схема БД — `main_rvk_ws` из `app/src/test/resources/application-test-local.properties`,
контейнеры из корневого `docker/docker-compose.yml` должны быть подняты.

```bash
./gradlew :app:test --tests 'ru.fgk.ws.app.security.UiMinimalRoleTest'
./gradlew :app:test --tests 'ru.fgk.ws.app.container.security.*'
./gradlew spotlessCheckAll
```

Негативный сценарий закрыт тестом `doesNotGrantFilterAdministration`:
в политиках `ui-minimal` нет `rvkfilter.manageGlobal` и
`rvkfilter.manageAllConfigs`.

Общие ресурсы (БД, gradle daemon) заняты только на время прогона тестов; порт
приложения и браузер не использовались.

## Ограничения и связанные изменения

- Живая проверка пресета в браузере в этом таске не выполнялась:
  `render not browser-verified`. Она предусмотрена планом в T04.
- Доказательства других тасков не затронуты: состав контейнерных ролей не
  менялся.
