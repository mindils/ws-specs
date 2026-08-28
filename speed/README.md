# План ускорения сборки и запуска RVK-WS

## Цель

Сократить время локального запуска `./gradlew :app:bootRun` и повторной сборки модуля `app`, не меняя бизнес-логику приложения.

Документ фиксирует результаты диагностики и список рекомендуемых изменений. Это план работ: сами конфиги и код приложения в рамках этого документа не меняются.

## Baseline диагностики

Замеры выполнены из корня репозитория `/home/mindils/data/dev/fgk/rvk-ws`.

| Область | Результат | Комментарий |
| --- | ---: | --- |
| Холодная сборка `./gradlew :app:classes --profile --no-daemon` | ~39.5 s | Основное время: старт Gradle и загрузка проектов, затем Vaadin frontend prepare |
| Теплая сборка `./gradlew :app:classes --profile` | ~5.8 s | Gradle daemon резко сокращает startup/configuration время |
| Vaadin scan при `bootRun` | 33495 ms | Лог Vaadin прямо рекомендует использовать `vaadin.allowed-packages` |
| Liquibase changelog-файлы приложения | 262 файла | `includeAll` читает весь набор changelog-ов на старте |
| `main.databasechangelog` | 2276 строк | Есть repeated `MARK_RAN`/`RERAN` из-за `runAlways` |

Ключевой вывод: самая заметная задержка Spring/Jmix startup сейчас находится в Vaadin classpath scanning. Для сборки наиболее заметны холодный Gradle daemon, `vaadinPrepareFrontend` и участие `cyclonedxBom` в локальном task graph.

## P0: Быстрые изменения с максимальным эффектом

### 1. Включить `vaadin.allowed-packages`

Проблема:

- В `bootRun` Vaadin написал: `Search for subclasses and classes with annotations took 33495 ms`.
- В `app/src/main/resources/application-dev.properties` уже есть закомментированный блок `vaadin.allowed-packages`, но он не активен.

Рекомендация:

- Включить `vaadin.allowed-packages` в dev profile.
- Минимальный безопасный список:

```properties
vaadin.allowed-packages=\
ru/fgk/ws/app,\
ru/fgk/ws/core,\
ru/fgk/sso
```

Ожидаемый эффект:

- Сокращение Vaadin classpath scan с десятков секунд до нескольких секунд.
- Ускорение `bootRun` без изменения бизнес-логики.

Проверка:

```bash
./gradlew :app:bootRun
```

В логах проверить строку:

```text
Search for subclasses and classes with annotations took ...
```

Ожидаемое значение должно быть существенно ниже текущих `33495 ms`.

Справка Vaadin: https://vaadin.com/docs/latest/flow/integrations/spring/configuration

### 2. Убрать шумные debug-настройки из default dev profile

Проблема:

- В `app/src/main/resources/application-dev.properties` включены:
  - `logging.level.io.jmix = debug`
  - `spring.jpa.show-sql=true`
  - `logging.level.eclipselink.logging.sql=debug`
- При запуске это создает очень большой поток логов, особенно после открытия UI.

Рекомендация:

- В обычном `dev` profile оставить уровни `info`.
- Для SQL/debug сделать отдельный профиль, например `dev-debug-sql`, который включается только точечно.

Ожидаемый эффект:

- Меньше I/O в консоль.
- Быстрее воспринимаемый запуск и работа UI.
- Проще видеть реальные предупреждения startup.

Проверка:

```bash
./gradlew :app:bootRun
```

После старта не должно быть массового вывода SQL и транзакционных debug-логов без явного включения debug profile.

### 3. Исправить `runAlways` в Liquibase

Проблема:

- `app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/01-tbl/000-nsi_reject_reason.xml`
  содержит `runAlways="true"` для одноразового `createTable`.
- В БД этот changeset накопил 500+ repeated `MARK_RAN`.
- `app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/01-tbl/011-diadoc_packet_document_flow.xml`
  содержит `runAlways="true"` для backfill `UPDATE ... WHERE id IS NULL`, поэтому он проверяется и rerun-ится на каждом старте.

Рекомендация:

- Для `createTable` убрать `runAlways="true"`, оставить обычный one-time changeset с `preConditions`.
- Для backfill `id` заменить `runAlways` на одноразовую миграцию, если backfill уже применен на всех dev/prod БД.
- Если backfill еще нужен как страховка, вынести его в отдельную явную maintenance-миграцию или SQL-скрипт, а не выполнять на каждом startup.

Ожидаемый эффект:

- Меньше лишних проверок и записей в `DATABASECHANGELOG`.
- Ниже риск незаметных DML-операций при каждом старте.

Проверка:

```sql
select filename, id, author, exectype, count(*) as cnt
from main.databasechangelog
where filename in (
  'ru/fgk/ws/app/liquibase/changelog/01-tbl/000-nsi_reject_reason.xml',
  'ru/fgk/ws/app/liquibase/changelog/01-tbl/011-diadoc_packet_document_flow.xml'
)
group by filename, id, author, exectype
order by cnt desc;
```

После исправления и повторных стартов счетчики для этих changeset-ов не должны расти.

## P1: Оптимизация Gradle и локального task graph

### 4. Вынести `cyclonedxBom` из локальной сборки

Проблема:

- В `app/build.gradle` настроен `cyclonedxBom`.
- Даже в `UP-TO-DATE` состоянии он попадает в локальный task graph и занимает заметное время.
- SBOM нужен для CI/release, но обычно не нужен при каждом локальном `classes`/`bootRun`.

Рекомендация:

- Запускать `cyclonedxBom` только в CI/release task.
- Либо включать его по флагу, например `-Psbom=true`.
- Не привязывать `compileJava` и локальный `build` к генерации SBOM без необходимости.

Ожидаемый эффект:

- Быстрее `:app:classes`, `:app:bootRun`, локальные проверки.
- CI сохраняет SBOM как отдельный контролируемый шаг.

Проверка:

```bash
./gradlew :app:classes --profile
```

В profile report `cyclonedxBom` не должен быть в критическом пути обычной локальной сборки.

### 5. Настроить Gradle для локальной разработки

Проблема:

- В `gradle.properties` сейчас только `org.gradle.jvmargs=-Xmx1024M`.
- Холодный `--no-daemon` запуск занимает существенно дольше теплого daemon-запуска.

Рекомендация:

- Не использовать `--no-daemon` локально без необходимости.
- Рассмотреть после проверки:

```properties
org.gradle.jvmargs=-Xmx2g
org.gradle.caching=true
org.gradle.parallel=true
```

Ограничение:

- `org.gradle.configuration-cache=true` включать только отдельным экспериментом: Jmix/Vaadin/композитная сборка могут иметь несовместимые задачи.

Проверка:

```bash
./gradlew --status
./gradlew :app:classes --profile
```

Сравнить `Startup`, `Loading Projects`, `Task Execution` в profile report до и после изменений.

### 6. Контролировать `vaadinPrepareFrontend`

Проблема:

- В холодном замере `vaadinPrepareFrontend` занял около `13.1s`.
- В теплом замере задача стала `UP-TO-DATE`, но при изменениях frontend/bundle она снова может быть дорогой.

Рекомендация:

- Не удалять `app/node_modules`, `app/build/dev-bundle`, `.gradle` без необходимости.
- Следить, чтобы `app/src/main/bundles/dev.bundle` обновлялся осознанно.
- Если frontend-разработка не ведется, использовать precompiled dev bundle и не переключаться на hotdeploy.

Проверка:

```bash
./gradlew :app:classes --profile
```

В profile report `vaadinPrepareFrontend` должен быть `UP-TO-DATE` при повторном запуске без frontend-изменений.

## P2: Дополнительные улучшения

### 7. Сделать легкий локальный profile

Проблема:

- `application-dev.properties` подключает внешние интеграции: Keycloak, Temporal, REST DataStore, S3/MinIO.
- Если часть сервисов недоступна, startup или первые обращения могут ждать сетевые timeouts.

Рекомендация:

- Добавить отдельный profile, например `local-fast`.
- В нем отключать или подменять тяжелые интеграции, которые не нужны для текущей разработки.
- Для Temporal и REST Diadoc оставить явные локальные URL только когда соответствующие сервисы реально запущены.

Проверка:

```bash
./gradlew :app:bootRun --args='--spring.profiles.active=local-fast'
```

Сравнить время до строки `Application started at ...`.

### 8. Провести ревизию Liquibase `runOnChange`

Проблема:

- В changelog-ах найдено много `runOnChange`.
- Для views/functions это нормально, для таблиц и DML часто приводит к лишним проверкам и неожиданным rerun.

Рекомендация:

- Оставить `runOnChange` для `createView`/`createProcedure`, где это ожидаемый паттерн проекта.
- Убрать `runOnChange`/`runAlways` с одноразовых table/addColumn/backfill changeset-ов, если они не должны выполняться повторно.

Проверка:

```bash
rg -n 'runAlways="true"|runOnChange="true"' app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/01-tbl
```

Каждое найденное использование должно иметь явное обоснование.

### 9. Добавить регулярный startup benchmark

Проблема:

- Сейчас деградация startup обнаруживается вручную.

Рекомендация:

- Зафиксировать простой сценарий замера:

```bash
./gradlew :app:classes --profile
./gradlew :app:bootRun
```

- После крупных изменений в dependencies, Vaadin, Liquibase, Jmix modules сравнивать:
  - Gradle total build time;
  - Vaadin scan time;
  - Liquibase update time;
  - время до `Application started at ...`.

Ожидаемый эффект:

- Деградации запуска будут видны сразу, а не после накопления нескольких изменений.

## Acceptance checklist

- `vaadin.allowed-packages` включен в dev profile.
- Vaadin scan стал быстрее текущих `33495 ms`.
- Default dev profile не печатает SQL/debug-логи без явного debug profile.
- `runAlways` убран с одноразовых Liquibase changeset-ов.
- Повторный startup не добавляет новые `MARK_RAN` для `000-nsi_reject_reason.xml`.
- `cyclonedxBom` не замедляет обычный локальный `classes`/`bootRun`.
- Повторный `./gradlew :app:classes --profile` остается в районе нескольких секунд на warm daemon.

