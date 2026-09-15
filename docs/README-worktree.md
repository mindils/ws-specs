# Git worktree: свой порт и своя схема БД

Каждый дополнительный worktree работает на своём порту и в своей схеме
`main_<slug>` общей PostgreSQL из `docker/docker-compose.yml`. Схема `ws_store`
общая. Схема создаётся пустой — структуру и данные разворачивает Liquibase при
первом `bootRun` (и `changelog-test.xml` в тестах).

## Как это устроено

- `application.properties`: `spring.profiles.group.dev=local` — профиль `local`
  идёт после `dev` и перекрывает его.
- `app/src/main/resources/application-local.properties` (не в git) — единственный
  файл с настройками worktree: `main.datasource.url` с `currentSchema=main_<slug>`
  и `server.port`. Его создаёт `system/worktree-setup.sh`; slug — из имени ветки.
- `app/src/test/resources/application-test-local.properties` копируется из
  основного worktree, в нём патчится только `currentSchema` (его читает
  `LocalTestDataSource` напрямую, минуя Spring).
- Порт выбирается из 8082..8099: не занятый другими worktree
  (`application-local.properties` каждого) и не слушающийся на хосте.
  8080 — основной worktree, 8081 — `rvkdiadoc`, 8088 — Temporal UI.

## Запуск

Из Zed: создание worktree само запускает задачу `worktree: setup (hook)`
(`.zed/tasks.json`). Вручную из любого каталога:

```bash
system/worktree-setup.sh /path/to/worktree        # идемпотентно
system/worktree-setup.sh --dry-run /path/to/worktree
system/worktree-setup.sh --recreate /path/to/worktree   # пересоздать пустую схему
system/worktree-setup.sh --no-db --no-specs /path/to/worktree
```

Скрипт также: копирует `application-dev.properties`,
`migration/ws_store/liquibase.properties`, `.ignore`, `.use-public-repos`;
переносит симлинки agent-kit (`CLAUDE.md`, `AGENTS.md`, `.claude/`, `.agents/`);
делает симлинки `specs/` и `openspec/` на основной worktree (это отдельные
git-репозитории, task-скилы ходят по `specs/work/...`); переключает
gradle-wrapper на `services.gradle.org`, если так сделано в основном worktree.

Удаление:

```bash
system/worktree-teardown.sh /path/to/worktree                    # DROP SCHEMA
system/worktree-teardown.sh --remove-worktree /path/to/worktree  # + git worktree remove
```

## Keycloak

Клиент `ws-app` в `docker/myrealm-export.json` разрешает redirect на
`http://localhost:8080` и `8082..8099`. Realm импортируется только при первом
создании контейнера, для уже существующего volume:

```bash
(cd docker && docker compose exec sso /opt/keycloak/bin/kc.sh import \
   --file /opt/keycloak/data/import/myrealm-export.json --override true \
 && docker compose restart sso)
```

Либо пересоздать volume `docker_keycloak-db`. До этого на портах, отличных от
8080, вход через `/local-login` (`user` / `user`).

## Редактирование specs/ по симлинку из агентов

Проверено 2026-09-14 на файле `specs/work/.../note.md` из дополнительного
worktree:

- Claude Code (2.1.x) — редактирует без дополнительных настроек.
- Codex (0.154) — в sandbox `workspace-write` запись по симлинку за пределы
  worktree блокируется («Failed to write file»). Лечится один раз в
  `~/.codex/config.toml` (либо флагом `-c` с тем же ключом):

  ```toml
  [sandbox_workspace_write]
  writable_roots = ["/home/<user>/data/dev/fgk/rvk-ws/specs", "/home/<user>/data/dev/fgk/rvk-ws/openspec"]
  ```

- agy — не проверялся.

Если появится отказ в Claude Code — в `.claude/settings.local.json` worktree
добавить `permissions.additionalDirectories` с теми же путями.

## Ограничения

- Temporal общий (`localhost:7233`, namespace `default`): workers всех worktree
  берут задачи из одной очереди. При необходимости в
  `application-local.properties` добавить `spring.temporal.start-workers=false`.
- Views/функции с жёстким `main.` в SQL смотрят в общую схему `main`, пока не
  переведены на неквалифицированные имена.
- Справочники `migration/main` (standalone Liquibase) в новую схему не
  накатываются автоматически.
- `node_modules` и кеш Gradle не копируются: первый `bootRun` долгий.
- MCP `rvk-ws` смотрит в основную БД; схему worktree — явным префиксом.
