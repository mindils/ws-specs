# Результат T14

Таск: [task.md](task.md)
Итерация: 1
Обновлено: 2026-09-16

## Что реализовано

Статика `/img/**` отдаётся без аутентификации: `IframeSecurity` разрешает этот
путь тем же способом, что и `/local-login`. Все пять картинок
`META-INF/resources/img/filetype/*.png` (`fileNotFound`, `docFileType`,
`xlsFileType`, `htmlFileType`, `otherFileType`) отвечают `200` и
`Content-Type: image/png` анонимному `curl`; закрытые страницы по-прежнему
редиректят на аутентификацию. Блокеров нет.

## Изменения и решения

Изменён один файл —
`app/src/main/java/ru/fgk/ws/app/security/IframeSecurity.java`: в существующем
вызове `http.authorizeHttpRequests(...)` к `requestMatchers("/local-login")`
добавлен `requestMatchers("/img/**").permitAll()`, рядом комментарий о причине
(каталог `img/` не входит в стандартные открытые статические пути Vaadin/Jmix,
браузер запрашивает картинки мимо Vaadin). Форматирование — `spotlessApply`,
поэтому цепочка матчеров разложена в несколько строк. Других изменений
security, ролей и view нет.

Место работы: worktree
`/home/mindils/data/dev/fgk/worktrees/rvk-ws/cyan-fennel/rvk-ws`, ветка
`f/container` — тот же worktree, в котором сделаны T01–T09 (схема
`main_rvk_ws`, порт 8082). Отдельный worktree под T14, как описано в plan.md
для волны пересмотра, не создавался: таск меняет один файл, не пересекающийся с
областями T11–T13, а хосты `DisplayFile` для C2 есть только в этой ветке. В
основном worktree (`f/worktree`) правки нет.

Замечание к формулировке самопроверки: `/actuator/health` в этой конфигурации
закрыт — отвечает `302` на `/oauth2/authorization/keycloak`, поэтому «health =
UP» недостижимо. Готовность приложения фиксировалась по ответам `200` на
`/local-login` и на сами картинки.

## Предварительные проверки

| Команда или сценарий | Результат |
|---|---|
| `./gradlew spotlessApply :app:compileJava` (worktree cyan-fennel) | успешно, файл переформатирован |
| `bootRun` на порту 8082, анонимный `curl -sI /img/filetype/fileNotFound.png` и `docFileType.png` | `200`, `Content-Type: image/png` |
| То же для `xlsFileType.png`, `htmlFileType.png`, `otherFileType.png` | `200`, `image/png` |
| Анонимный `curl` на `/local-login` и на `/containers` | `200` и `302` на `/oauth2/authorization/keycloak` — как прежде |
| Процесс `bootRun` погашен, порт 8082 освобождён | да |

Не запускалось, оставлено проверяющему: `./gradlew :app:test --tests
"ru.fgk.ws.app.container.security.*"` (C3), полный `:app:test`, вход через
`/local-login` в браузере и сценарий C2 с `.docx` в хосте `DisplayFile`.

## Для независимой проверки

Окружение: worktree `../worktrees/rvk-ws/cyan-fennel/rvk-ws`, ветка
`f/container`, общий Docker PostgreSQL (`localhost:5432`, схема `main_rvk_ws`),
MinIO из `docker/docker-compose.yml`, порт приложения 8082 из
`app/src/main/resources/application-local.properties`. Перед запуском —
`docker info` и `(cd docker && docker compose ps)`.

```bash
cd ../worktrees/rvk-ws/cyan-fennel/rvk-ws
./gradlew :app:bootRun            # фоном, ждать ответа 200 на /local-login
curl -sI http://localhost:8082/img/filetype/fileNotFound.png
curl -sI http://localhost:8082/img/filetype/docFileType.png
./gradlew :app:test --tests "ru.fgk.ws.app.container.security.*"
```

C1 — коды `200` и `Content-Type: image/png` без входа. C2 — вход `user` /
`user` через `http://localhost:8082/local-login`, любой хост `DisplayFile` с
загруженным `.docx` (например, форма освидетельствования или вкладка «Файлы»
карточки контейнера); иконка `docFileType.png` видна, в консоли браузера нет
ошибок загрузки. C3 — обычный вход через `/local-login` работает, закрытые
страницы без сессии по-прежнему редиректят на Keycloak, класс
`ru.fgk.ws.app.container.security.ContainerRolesTest` зелёный.

Состояние кода: правка лежит незакоммиченной в рабочей копии worktree
(`git status` в `cyan-fennel/rvk-ws` показывает изменённым только
`IframeSecurity.java` поверх коммита `1ad658d3f`).

Изоляция: порт 8082 и схема `main_rvk_ws` — параметры worktree; `:app:test` и
браузер занимают общую БД и gradle daemon, поэтому проверка T14 идёт первой в
очереди пересмотра (T14 → T11 → T12 → T13). Свой процесс `bootRun` погасить
после проверки.

## Ограничения и связанные изменения

- Несуществующий путь под `/img/**` (например, `/img/filetype/nope.png`)
  отвечает `200` с `text/html` — это SPA-fallback Vaadin, общий для любых
  неизвестных путей, а не следствие правила. При проверке C1 смотреть
  `Content-Type`, а не только код.
- Браузерный сценарий C2 исполнителем не выполнялся: `render not
  browser-verified`.
- Дефект, зафиксированный в «Ограничениях» [result.md T04](../T04/result.md),
  снят этой правкой; доказательства T04 менять не требуется — поведение
  контейнерных view не затронуто.
