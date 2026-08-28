# Задачи по оптимизации CI/CD

Дата аудита: 2026-06-19.

Документ разбивает оптимизацию CI/CD на небольшие независимые задачи. Каждую
задачу следует выполнять отдельным коммитом и проверять отдельно. Не нужно
одновременно реализовывать несколько задач только потому, что они находятся в
одном разделе.

## Обозначения

| Статус | Значение t
|---|---|
| `WORKING TREE` | Изменение уже есть в незакоммиченном working tree, но ещё не подтверждено реальным GitLab pipeline |
| `NEEDS FIX` | Решение реализовано частично либо требует корректировки |
| `TODO` | Изменение ещё не реализовано |
| `OPTIONAL` | Выполнять только при выполнении условия, указанного в задаче |

Приоритеты:

- `P0` — корректность pipeline или обязательная основа для измерений.
- `P1` — ожидаемый заметный выигрыш по времени или надёжности.
- `P2` — полезная оптимизация после выполнения P0/P1.
- `P3` — выполнять только при наличии подтверждённой проблемы.

## Правила выполнения

1. Перед задачей сохранить длительность затрагиваемого job и всего pipeline.
2. Выполнять одну задачу одним отдельным коммитом.
3. После задачи повторить тот же сценарий минимум три раза.
4. Сравнивать медиану, а не один самый быстрый запуск.
5. Проверять холодный запуск без подходящего cache и прогретый запуск.
6. Не считать задачу завершённой только потому, что YAML проходит парсинг.
7. Для Gradle-изменений выполнить как минимум `./gradlew :app:test`.
8. Для production-сборки дополнительно выполнить:

   ```bash
   ./gradlew :app:bootJar -Pvaadin.productionMode=true
   ```

9. При изменении pipeline проверить оба пути:

   - ручной: `build_jar → scan_SBOM → docker_build → deploy_prod`;
   - автоматический: `full_auto_trigger → build_jar_auto → scan/docker → deploy`.

10. Любая оптимизация считается неудачной, если ускорение получено за счёт
    пропуска тестов, SBOM-проверки или проверки готовности приложения.

## Текущее состояние

На момент аудита:

- JAR приложения имеет размер примерно 262 MB.
- `migration/ws_store` занимает примерно 222 MB.
- Vaadin bundles занимают примерно 15 MB.
- Найдено 49 test-классов, из них примерно 12 используют Spring/Jmix
  integration test infrastructure.
- `:app:check` сейчас останавливается на существующих Spotless-ошибках.
- В `.gitlab-ci.yml` одновременно используются `needs` и `dependencies`.
- `scan_SBOM` допускает ошибку через `allow_failure`.
- Kaniko используется для container build, хотя проект Kaniko больше не
  является рекомендуемым поддерживаемым вариантом GitLab.
- Часть перечисленных ниже изменений уже находится в working tree и требует
  проверки в GitLab.

---

# Этап 1. Метрики и корректность pipeline

## CI-001. Добавить baseline и измерение этапов

- **Статус:** `TODO`
- **Приоритет:** `P0`
- **Зависимости:** нет
- [ ] Завершено

### Проблема

Сейчас невозможно достоверно определить, что именно занимает основное время:
Liquibase, Gradle configuration, тесты, cache upload/download, передача JAR,
container build, pull image или перезапуск приложения.

### Изменение

Добавить в CI явное измерение следующих операций:

- подготовка test database и `liquibase update`;
- Gradle configuration и выполнение тестов;
- production `bootJar`;
- создание и загрузка Gradle cache;
- загрузка и скачивание artifacts;
- генерация и сканирование SBOM;
- container build и push;
- `docker compose pull`;
- запуск контейнера и ожидание готовности.

Для shell-команд использовать единый небольшой helper либо печатать UTC-время
до и после операции. Не добавлять отдельный внешний сервис мониторинга в рамках
этой задачи.

### Проверка

- В логе каждого job видна длительность основных операций.
- Зафиксированы три холодных и три прогретых pipeline.
- Результаты добавлены в таблицу в этом документе или в отдельный
  `docs/ci-cd-performance.md`.

### Критерий завершения

Для каждой дальнейшей оптимизации существует baseline, с которым можно
сравнить результат.

## CI-002. Исключить дублирующиеся branch и merge-request pipeline

- **Статус:** `WORKING TREE`
- **Приоритет:** `P0`
- **Зависимости:** нет
- [ ] Завершено

### Проблема

Один push в ветку с открытым merge request может создать два pipeline. Это
повторно запускает тесты и Sonar.

### Изменение

Проверить текущие `workflow: rules` и оставить следующую семантику:

- merge-request pipeline создаётся для открытого merge request;
- обычный branch pipeline создаётся, только если для ветки нет открытого merge
  request;
- web/manual pipeline продолжает создаваться;
- tag pipeline не блокируется, если он используется процессом релиза.

### Проверка

Выполнить push:

1. В ветку без merge request — создан один branch pipeline.
2. В ветку с открытым merge request — создан один merge-request pipeline.
3. Через **Run pipeline** — создан один web pipeline.

### Критерий завершения

Для одного события не создаются два pipeline, и Sonar не запускается дважды из-за
дублирования pipeline.

## CI-003. Переиспользовать автоматические тесты после `full_auto_trigger`

- **Статус:** `WORKING TREE`
- **Приоритет:** `P0`
- **Зависимости:** CI-002
- [ ] Завершено

### Проблема

Раньше `full_auto_trigger` запускал отдельный второй test job, даже если
`fast_test_with_cache` уже выполнялся или завершился.

### Изменение

Сохранить один автоматический `fast_test_with_cache`. `build_jar_auto` должен:

- ждать `full_auto_trigger`;
- ждать существующий `fast_test_with_cache`;
- продолжить сборку, если тесты успешны;
- остановить цепочку, если тесты завершились ошибкой;
- не создавать `fast_test_with_cache_auto`.

Ручная цепочка после тестов должна оставаться доступной.

### Проверка

- Нажать `full_auto_trigger`, пока тесты выполняются: build ожидает этот job.
- Нажать после успешных тестов: build начинается без повторных тестов.
- Нажать после неуспешных тестов: build не запускается.
- В pipeline присутствует только один job с полным набором этих тестов.

### Критерий завершения

Автоматический deploy использует результат уже существующего test job.

## CI-004. Убрать совместное использование `needs` и `dependencies`

- **Статус:** `NEEDS FIX`
- **Приоритет:** `P0`
- **Зависимости:** CI-003
- [ ] Завершено

### Проблема

GitLab не рекомендует использовать `needs` и `dependencies` в одном job. Это
усложняет DAG и может давать различное поведение передачи artifacts на разных
версиях GitLab.

### Изменение

Для каждого job, использующего artifacts, перейти на структурированный `needs`:

```yaml
needs:
  - job: build_jar
    artifacts: true
```

Для зависимостей, от которых artifacts не нужны:

```yaml
needs:
  - job: some_job
    artifacts: false
```

После этого удалить `dependencies` из job. Выполнять замену отдельно для ручной,
автоматической и `notest` цепочек, не меняя их правила запуска.

### Проверка

- GitLab CI lint принимает конфигурацию.
- `scan_SBOM` получает `all_sbom.json`.
- container build получает JAR и `.version`.
- deploy получает требуемый version artifact.
- Job не скачивает artifacts от несвязанных предыдущих стадий.

### Критерий завершения

В `.gitlab-ci.yml` нет job, одновременно содержащего `needs` и `dependencies`.

## CI-005. Сделать SBOM обязательным production gate

- **Статус:** `NEEDS FIX`
- **Приоритет:** `P0`
- **Зависимости:** CI-004
- [ ] Завершено

### Проблема

Сейчас deploy ждёт `scan_SBOM`, но ошибка scan разрешена через `allow_failure`.
Это увеличивает критический путь, не блокируя небезопасный release.

### Изменение

- Удалить `allow_failure: true` у production SBOM scan.
- Оставить параллельный запуск scan и container build после `build_jar`.
- Разрешать deploy только после успешного завершения обоих jobs.
- Применить одинаковую политику к ручной, автоматической и `notest` цепочкам.
- Если для merge request нужен advisory scan, создать для него отдельный job с
  другим именем и явным `allow_failure`, не переиспользовать production gate.

### Проверка

- Ошибка SBOM scan блокирует production deploy.
- Успешный scan и успешный image build разрешают deploy.
- Image build не ждёт scan и выполняется параллельно с ним.

### Критерий завершения

Production deployment технически невозможен при неуспешном SBOM scan.

## CI-006. Гарантировать реальное выполнение тестов в CI

- **Статус:** `NEEDS FIX`
- **Приоритет:** `P0`
- **Зависимости:** нет
- [ ] Завершено

### Проблема

`test.outputs.cacheIf { false }` запрещает сохранение и восстановление результата
из Gradle build cache, но не запрещает Gradle пометить задачу `UP-TO-DATE`.
Тесты используют внешнюю БД, состояние которой не является Gradle input.

### Изменение

Сохранить отключение build cache для `test`, дополнительно запретить
`UP-TO-DATE` только в CI:

```groovy
if (System.getenv('CI')) {
    outputs.upToDateWhen { false }
}
```

Локальную инкрементальную работу Gradle не отключать.

### Проверка

- Два последовательных CI-запуска реально выполняют тесты.
- В логе нет `:app:test UP-TO-DATE` и `FROM-CACHE`.
- Локально без переменной `CI` поведение Gradle не ухудшилось.

### Критерий завершения

CI никогда не принимает старый test result за результат текущего состояния БД.

## CI-007. Исправить текущие Spotless-ошибки

- **Статус:** `TODO`
- **Приоритет:** `P0`
- **Зависимости:** нет
- [ ] Завершено

### Проблема

Полный `:app:check` сейчас не проходит из-за существующих нарушений Spotless.
Из-за этого невозможно использовать `check` как стабильный quality gate.

### Изменение

Исправить только файлы, перечисленные текущим отчётом Spotless. Не запускать
массовое форматирование legacy-кода и не смешивать исправление с CI
оптимизациями.

### Проверка

```bash
./gradlew :app:spotlessCheck
./gradlew :app:check -x :app:cyclonedxBom
```

### Критерий завершения

Обе команды завершаются успешно без нерелевантного массового diff.

## CI-008. Публиковать полноценные test reports

- **Статус:** `TODO`
- **Приоритет:** `P2`
- **Зависимости:** нет
- [ ] Завершено

### Проблема

При ошибке сохраняется только HTML `index.html` без связанных ресурсов и
детальных страниц. GitLab также не получает JUnit report.

### Изменение

- Добавить `artifacts:reports:junit` для XML-файлов Gradle.
- Сохранять всю директорию HTML test report при ошибке.
- Установить разумный `expire_in`, например 7 дней.
- Не сохранять build directories целиком.

### Проверка

- GitLab показывает количество и длительность тестов.
- Для специально сломанного теста доступен полный HTML report.
- Размер artifacts не содержит лишние Gradle outputs.

### Критерий завершения

Причину test failure можно определить из GitLab без повторного локального
запуска.

---

# Этап 2. Gradle, тесты и frontend

## CI-010. Исправить и сузить Gradle cache

- **Статус:** `NEEDS FIX`
- **Приоритет:** `P1`
- **Зависимости:** CI-001
- [ ] Завершено

### Проблема

В working tree добавлен путь `.gradle/build-cache/`, но Gradle local build cache
обычно находится в `$GRADLE_USER_HOME/caches/build-cache-1`. Кеширование всей
`.gradle/caches/` может тратить больше времени на упаковку и загрузку, чем
экономить.

### Изменение

1. Удалить несуществующий `.gradle/build-cache/`.
2. Измерить размеры и время restore/upload для:
   - `.gradle/wrapper/`;
   - `.gradle/caches/modules-2/`;
   - `.gradle/caches/build-cache-1/`;
   - version-specific Gradle caches;
   - module `.gradle/` directories.
3. Оставить только пути с измеренным положительным эффектом.
4. Сохранить branch key с fallback на default branch.
5. Test job может иметь `pull-push`; jobs-потребители должны использовать
   `pull`, если им не требуется обновлять cache.
6. При смене формата cache увеличивать явную версию ключа.

### Проверка

- Cache path реально существует после Gradle build.
- Время restore + upload меньше сэкономленного времени dependency resolution и
  compilation.
- Cache разных несовместимых Gradle версий не смешивается.
- Новая ветка использует fallback default branch.

### Критерий завершения

Прогретый test/build job стабильно быстрее baseline, включая время работы с
GitLab cache.

## CI-011. Проверить Gradle parallel execution и лимиты памяти

- **Статус:** `WORKING TREE`
- **Приоритет:** `P1`
- **Зависимости:** CI-001
- [ ] Завершено

### Проблема

В working tree включены `org.gradle.parallel=true` и build cache, но без данных
о CPU/RAM runner. Избыточное количество workers может замедлить сборку или
вызвать OOM.

### Изменение

- Зафиксировать доступные runner CPU и RAM.
- Сравнить запуск с parallel execution и без него.
- Установить `org.gradle.workers.max` только если runner сообщает больше CPU,
  чем реально доступно job.
- Согласовать `org.gradle.jvmargs`, `test.maxHeapSize` и память Node/Vaadin с
  лимитом контейнера.
- Проверить, распространяются ли настройки на composite builds `app`, `core` и
  `sso-plagin`.

### Проверка

- Нет OOM, daemon crash и активного swapping.
- Parallel execution быстрее либо не медленнее последовательного.
- Одновременно выполняемые Gradle tasks не используют общую изменяемую БД.

### Критерий завершения

Значения workers и памяти основаны на параметрах runner и результатах замеров.

## CI-012. Экспериментально проверить Gradle configuration cache

- **Статус:** `OPTIONAL`
- **Приоритет:** `P2`
- **Зависимости:** CI-011
- **Условие:** Gradle configuration занимает заметную часть повторной сборки
- [ ] Завершено

### Изменение

Сначала выполнить диагностический запуск:

```bash
./gradlew :app:test \
  --configuration-cache \
  --configuration-cache-problems=warn
```

Не включать configuration cache глобально, пока Vaadin, CycloneDX и composite
build tasks не проходят проверку.

### Проверка

- Второй запуск использует configuration cache.
- Нет проблем, способных привести к пропуску конфигурации или неверным inputs.
- Production `bootJar` также проверен отдельно.

### Критерий завершения

Configuration cache включается только для подтверждённо совместимых CI-команд.

## CI-013. Отвязать CycloneDX от выполнения тестов

- **Статус:** `NEEDS FIX`
- **Приоритет:** `P1`
- **Зависимости:** CI-007
- [ ] Завершено

### Проблема

`processResources` зависит от `cyclonedxBom`, поэтому `test` транзитивно запускает
SBOM generation через `classes`. Текущий CI обходит это через
`-x :app:cyclonedxBom`, что маскирует неправильный task graph.

### Изменение

- Удалить зависимость resource/test lifecycle от `cyclonedxBom`.
- Создавать Java SBOM только в production build/SBOM lifecycle.
- Если SBOM должен попасть в JAR, добавить отдельную production-задачу, явно
  выполняемую `build_jar`, а не каждым `processResources`.
- После изменения убрать `-x :app:cyclonedxBom` из test job.

### Проверка

```bash
./gradlew :app:test --dry-run
./gradlew :app:bootJar -Pvaadin.productionMode=true --dry-run
```

- В test graph отсутствует `cyclonedxBom`.
- Production build создаёт актуальный Java SBOM.

### Критерий завершения

Тесты не генерируют SBOM, а production release по-прежнему содержит полный SBOM.

## CI-014. Зафиксировать воспроизводимый процесс Vaadin bundles

- **Статус:** `WORKING TREE`
- **Приоритет:** `P1`
- **Зависимости:** нет
- [ ] Завершено

### Проблема

Bundles добавлены в working tree и проверяются checksum, но требуется определить
единый способ обновления `dev.bundle` и `prod.bundle`. Иначе build может
неожиданно переписывать файлы либо использовать устаревший frontend.

### Изменение

- Хранить оба bundles в Git только после проверки воспроизводимости.
- Добавить в README точные команды регенерации development и production bundle.
- Проверять, что обычный test/build не изменяет tracked bundles.
- Не смешивать регенерацию bundles с изменениями package manager.
- Если bundle зависит от версии Node/npm, зафиксировать эти версии.

### Проверка

1. Дважды регенерировать каждый bundle в чистом checkout.
2. Сравнить SHA256.
3. Выполнить tests и production build.
4. Проверить `git diff --exit-code -- app/src/main/bundles`.

### Критерий завершения

Bundles детерминированы, документированы и не меняются при обычной CI-сборке.

## CI-015. Привести frontend к одному package manager

- **Статус:** `NEEDS FIX`
- **Приоритет:** `P1`
- **Зависимости:** CI-014
- [ ] Завершено

### Проблема

В проекте смешаны pnpm-настройки `.npmrc`, секция `pnpm.overrides` и
npm-ориентированные изменения `package.json`. Из-за рассинхронизации
CycloneDX запускается с `--ignore-npm-errors`.

### Изменение

Рекомендуемый вариант:

- использовать npm, так как `pnpmEnable=false` соответствует текущему режиму;
- удалить pnpm-only настройки после проверки Vaadin generation;
- сохранить npm `overrides`;
- создать и закоммитить согласованный lockfile;
- запускать установку через `npm ci`, где установка действительно нужна;
- убрать `--ignore-npm-errors` после исправления dependency tree.

Если принято решение оставить pnpm, задача выполняется зеркально: включить pnpm
в Vaadin, оставить pnpm lockfile и удалить npm-only workflow. Одновременная
поддержка двух package managers не допускается.

### Проверка

- Чистая установка выполняется выбранным package manager.
- Vaadin production build успешен.
- CycloneDX npm SBOM создаётся без `--ignore-npm-errors`.
- Повторная установка не изменяет lockfile.

### Критерий завершения

`package.json`, lockfile, `.npmrc`, Vaadin и CycloneDX используют один package
manager.

## CI-016. Создать versioned CI image для тестов и сборки

- **Статус:** `TODO`
- **Приоритет:** `P1`
- **Зависимости:** CI-001
- [ ] Завершено

### Проблема

Часть jobs устанавливает системные пакеты и загружает Liquibase/инструменты при
каждом запуске. Это медленно, зависит от внешних репозиториев и плохо
воспроизводится.

### Изменение

Создать отдельный immutable CI image, содержащий:

- требуемую Java 21;
- выбранную версию Node и package manager;
- Liquibase;
- PostgreSQL client;
- шрифты, необходимые тестам;
- системные библиотеки frontend build;
- при необходимости CycloneDX merger и AppSec CLI.

Image тегировать версией, не использовать `latest`. Обновление image оформлять
отдельным процессом и changelog.

### Проверка

- Test/build jobs не выполняют `dnf/yum install`.
- Liquibase и Node версии печатаются в CI log.
- Job запускается без скачивания инструментов.
- Время старта меньше baseline.

### Критерий завершения

Все неизменяемые build dependencies находятся в versioned CI image.

## CI-017. Измерить стоимость полной миграции `ws_store`

- **Статус:** `TODO`
- **Приоритет:** `P1`
- **Зависимости:** CI-001
- [ ] Завершено

### Проблема

`migration/ws_store` занимает около 222 MB и содержит крупные XML/data-файлы.
Даже для уже обновлённой БД Liquibase должен прочитать changelog и проверить
changesets.

### Изменение

Отдельно измерить:

- запуск Liquibase на пустой test database;
- запуск на уже актуальной database;
- parsing/checksum без применения changesets;
- объём реально используемых тестами таблиц и данных.

На этом этапе не изменять changelog.

### Проверка

В отчёте указаны время, количество changesets и доля test job, занятая
Liquibase.

### Критерий завершения

Есть данные для выбора между сокращённым changelog и snapshot database.

## CI-018. Создать сокращённый test-only changelog

- **Статус:** `TODO`
- **Приоритет:** `P1`
- **Зависимости:** CI-017
- **Условие:** Liquibase занимает более 20% test job или более 60 секунд
- [ ] Завершено

### Проблема

Тестам может быть не нужна полная внешняя схема и все production reference
data.

### Изменение

- Определить таблицы, views и минимальные данные, реально используемые tests.
- Создать отдельный test-only changelog вне read-only зоны
  `migration/ws_store`.
- Не изменять production changelog и источник `ws_store`.
- Добавить проверку, что test schema содержит все объекты, к которым обращается
  приложение в тестах.
- При реализации использовать skill `jmix-liquibase` и обязательные
  preconditions проекта.

### Проверка

- Все `:app:test` проходят на чистой БД.
- Время подготовки БД меньше baseline.
- Production migration files не изменены.

### Критерий завершения

Tests используют минимальную, воспроизводимую схему без скрытой зависимости от
старой общей test database.

## CI-019. Использовать snapshot test database

- **Статус:** `OPTIONAL`
- **Приоритет:** `P2`
- **Зависимости:** CI-017
- **Условие:** сокращённый changelog неприменим или всё ещё занимает более 30 секунд
- [ ] Завершено

### Изменение

- Создать versioned snapshot/custom PostgreSQL image с уже применённой схемой.
- Версию snapshot привязать к hash changelog.
- При изменении changelog пересобирать snapshot.
- После запуска применять только новые changesets.
- Не хранить credentials или production data в image.

### Проверка

- Новая БД поднимается из snapshot в чистом runner.
- Все tests проходят.
- Изменение changelog инвалидирует старый snapshot.

### Критерий завершения

Время восстановления snapshot и применения delta меньше времени test-only
Liquibase migration.

> CI-018 и CI-019 являются альтернативными основными стратегиями. Не нужно
> внедрять обе без измеренного дополнительного выигрыша.

## CI-020. Разделить unit и integration tests

- **Статус:** `TODO`
- **Приоритет:** `P1`
- **Зависимости:** CI-006
- [ ] Завершено

### Проблема

Быстрые unit tests и тесты с Spring/Jmix/БД выполняются одной Gradle task. Из-за
этого любой test job требует подготовленной внешней database.

### Изменение

- Ввести явную маркировку integration tests.
- Создать отдельные Gradle tasks, например `unitTest` и `integrationTest`.
- Unit tests запускать без Liquibase/database.
- Integration tests запускать после подготовки test database.
- Итоговый quality gate должен зависеть от обеих задач.

### Проверка

- `unitTest` работает без подключения к БД.
- `integrationTest` выполняет все ранее существовавшие integration tests.
- Общее количество выполненных тестов не уменьшилось.

### Критерий завершения

Быстрый feedback не зависит от подготовки БД, полный pipeline по-прежнему
проверяет integration scope.

## CI-021. Включить параллельные test forks после изоляции БД

- **Статус:** `OPTIONAL`
- **Приоритет:** `P2`
- **Зависимости:** CI-020
- **Условие:** tests занимают значимую часть pipeline и не конфликтуют по данным
- [ ] Завершено

### Изменение

- Сначала проверить shared mutable state и очистку данных.
- Изолировать schema/database либо набор данных для каждого fork.
- Подобрать `maxParallelForks` по CPU и памяти runner.
- Не включать parallel forks для тестов, использующих одну общую изменяемую
  schema без транзакционной изоляции.

### Проверка

- Минимум десять последовательных запусков без flaky failures.
- Время tests ниже baseline.
- Database cleanup не оставляет данные между forks.

### Критерий завершения

Параллелизм ускоряет tests без снижения стабильности.

## CI-022. Сократить test logging

- **Статус:** `TODO`
- **Приоритет:** `P3`
- **Зависимости:** CI-008
- [ ] Завершено

### Изменение

В CI не печатать статус каждого успешного теста. Оставить:

- failed/skipped events;
- exception и stack trace;
- итоговую статистику;
- полный JUnit/HTML report в artifacts.

### Проверка

- Причина ошибки видна в job log.
- Размер лога уменьшился.
- Экономия времени подтверждена измерениями.

### Критерий завершения

Лог остаётся диагностически полезным и не содержит сотни однотипных строк.

---

# Этап 3. JAR и SBOM

## CI-030. Проверить cache инструментов SBOM

- **Статус:** `WORKING TREE`
- **Приоритет:** `P1`
- **Зависимости:** CI-001
- [ ] Завершено

### Проблема

CycloneDX npm, CycloneDX merger и AppSec CLI ранее скачивались в каждом
pipeline. В working tree добавлен cache, но его эффективность ещё не проверена.

### Изменение

- Проверить cache hit на втором pipeline.
- Разделить cache key по версии каждого инструмента.
- Не смешивать executable cache с Gradle cache.
- Если CI-016 выполнен, удалить этот cache и использовать инструменты из CI
  image.

### Проверка

- На прогретом запуске отсутствует повторная установка/скачивание.
- Смена версии инструмента создаёт новый cache key.
- Повреждённый cache не приводит к молчаливому использованию неверного binary.

### Критерий завершения

SBOM tools либо поставляются CI image, либо восстанавливаются из
версионированного cache быстрее повторной загрузки.

## CI-031. Проверять целостность загружаемых executable

- **Статус:** `NEEDS FIX`
- **Приоритет:** `P0`
- **Зависимости:** CI-030 или CI-016
- [ ] Завершено

### Проблема

Сейчас скачиваемые `cyclonedx-linux-x64` и `appsec-track-cli` запускаются без
проверки checksum или подписи.

### Изменение

Предпочтительный вариант — поместить инструменты в versioned CI image.
Допустимый промежуточный вариант:

- зафиксировать версии;
- хранить ожидаемый SHA256 в защищённой CI variable или tracked checksum file;
- проверять checksum до первого запуска;
- не сохранять непроверенный binary в cache.

### Проверка

- Correct binary проходит проверку.
- Изменение одного байта завершает job до запуска binary.
- Обновление версии требует явного обновления checksum.

### Критерий завершения

CI не исполняет загруженный файл с непроверенной целостностью.

## CI-032. Сузить JAR и SBOM artifacts

- **Статус:** `TODO`
- **Приоритет:** `P2`
- **Зависимости:** CI-004
- [ ] Завершено

### Изменение

- Передавать JAR только container build.
- Передавать merged SBOM только scan job.
- Передавать `.version` только jobs, которым он нужен.
- Установить минимально достаточный `expire_in`.
- Не включать `app/build` целиком.

### Проверка

- Сравнить размер и время upload/download artifacts.
- Все downstream jobs получают нужные файлы.
- Несвязанные jobs не скачивают JAR размером около 262 MB.

### Критерий завершения

Artifacts содержат только контрактные файлы между конкретными jobs.

## CI-033. Параллельно выполнять scan и container build

- **Статус:** `WORKING TREE`
- **Приоритет:** `P1`
- **Зависимости:** CI-004, CI-005
- [ ] Завершено

### Изменение

После `build_jar` одновременно запускать:

- `scan_SBOM`;
- `docker_build`.

Deploy должен ждать оба job. Ошибка любого из них блокирует deploy.

### Проверка

В GitLab DAG jobs начинаются одновременно при наличии runners. Deploy появляется
только после успешного окончания обоих.

### Критерий завершения

SBOM scan не задерживает начало container build, но остаётся обязательным gate.

---

# Этап 4. Container image

## CI-040. Использовать минимальный container build context

- **Статус:** `WORKING TREE`
- **Приоритет:** `P1`
- **Зависимости:** нет
- [ ] Завершено

### Проблема

Передача всего `app/` в container builder включает лишние исходники, frontend
dependencies и build outputs.

### Изменение

Передавать в context только:

- Dockerfile;
- application JAR или извлечённые Spring Boot layers;
- version metadata;
- другие файлы, явно используемые Dockerfile.

### Проверка

- Builder log показывает уменьшенный context.
- Image запускается и содержит корректную версию.
- В context нет credentials, source tree и `node_modules`.

### Критерий завершения

Container builder получает только файлы, необходимые Dockerfile.

## CI-041. Заменить Kaniko на rootless BuildKit

- **Статус:** `TODO`
- **Приоритет:** `P1`
- **Зависимости:** CI-040
- [ ] Завершено

### Проблема

Kaniko больше не является поддерживаемым рекомендуемым GitLab вариантом.
Оптимизация Kaniko cache полезна только как временное решение.

### Изменение

- Использовать rootless BuildKit.
- Настроить registry authentication без privileged Docker daemon.
- Использовать `$CI_REGISTRY_IMAGE`, а не собирать путь из registry и короткого
  имени проекта.
- Настроить registry cache import/export.
- Сохранить текущие image tags и release version contract.

### Проверка

- Холодная сборка создаёт и публикует image.
- Повторная сборка использует registry cache.
- Изменение только application layer не пересобирает system/dependency layers.
- Image доступен текущему deploy process.

### Критерий завершения

Все container jobs используют BuildKit; Kaniko executor и его cache flags
удалены.

## CI-042. Вынести `dnf` и создание пользователя в runtime base image

- **Статус:** `TODO`
- **Приоритет:** `P1`
- **Зависимости:** нет
- [ ] Завершено

### Проблема

Application Dockerfile устанавливает `msttcore-fonts`, `shadow-utils` и создаёт
пользователя при сборке каждого release image. Текущий `dnf` уже находится в
отдельном Docker layer, поэтому простое разделение `RUN` не даст существенной
оптимизации.

### Изменение

Создать отдельный versioned runtime base image:

- взять текущий Java runtime base;
- установить шрифты и только необходимые системные пакеты;
- использовать `install_weak_deps=False`, если пакеты это допускают;
- очистить package manager metadata;
- создать стабильного non-root `appuser` с фиксированными UID/GID;
- опубликовать image с immutable version tag.

Application Dockerfile должен начинаться с этого image и больше не содержать
`dnf`, `shadow-utils` и `useradd`.

### Проверка

- Application image собирается без обращения к package repository.
- Шрифты доступны приложению.
- Процесс работает под `appuser`.
- Изменение только JAR не пересобирает system layer.

### Критерий завершения

Установка ОС-пакетов выполняется только при обновлении runtime base image, а не
при каждом release приложения.

## CI-043. Заменить `RUN chown` на `COPY --chown`

- **Статус:** `TODO`
- **Приоритет:** `P1`
- **Зависимости:** CI-042
- [ ] Завершено

### Проблема

После копирования JAR выполняется отдельный `RUN chown -R`. Для JAR размером
около 262 MB это может создать дополнительный большой layer.

### Изменение

Копировать файл сразу с корректным владельцем:

```dockerfile
COPY --chown=appuser:appuser build/libs/*.jar /home/appuser/app/app.jar
```

Удалить отдельный recursive `chown`.

### Проверка

- В image history отсутствует отдельный chown layer.
- JAR принадлежит `appuser`.
- Контейнер запускается без root.
- Размер image не увеличился.

### Критерий завершения

Права назначаются во время `COPY`, без дополнительного filesystem layer.

## CI-044. Использовать Spring Boot layered image

- **Статус:** `TODO`
- **Приоритет:** `P1`
- **Зависимости:** CI-041, CI-042
- [ ] Завершено

### Проблема

Fat JAR около 262 MB копируется как один layer. Любое изменение application
classes инвалидирует весь JAR layer, включая примерно 248 MB библиотек.

### Изменение

- Использовать уже присутствующий `BOOT-INF/layers.idx`.
- В multi-stage Dockerfile извлечь Spring Boot layers.
- Копировать отдельными layers:
  - dependencies;
  - spring-boot-loader;
  - snapshot-dependencies;
  - application.
- Сохранять запуск под non-root пользователем.
- Не менять runtime параметры JVM в этой задаче.

### Проверка

- Первый build создаёт все layers.
- После изменения одного Java-класса BuildKit повторно использует dependency
  layers.
- Приложение стартует с тем же profile/config contract.
- Содержимое и версия приложения соответствуют fat JAR.

### Критерий завершения

Изменение application code пересобирает и передаёт только application layer.

## CI-045. Зафиксировать результат оптимизации image

- **Статус:** `TODO`
- **Приоритет:** `P2`
- **Зависимости:** CI-041, CI-043, CI-044
- [ ] Завершено

### Изменение

Сравнить старый и новый варианты:

- полный размер image;
- compressed push/pull size;
- холодное время build;
- тёплое время build после изменения Java-класса;
- время pull на production host;
- количество и размер layers.

### Критерий завершения

Результаты записаны в таблицу. Если новый вариант не быстрее или нарушает
runtime contract, изменение не принимается.

---

# Этап 5. Deploy

## CI-050. Перейти только на Docker Compose v2

- **Статус:** `TODO`
- **Приоритет:** `P1`
- **Зависимости:** нет
- [ ] Завершено

### Проблема

Deploy script смешивает `docker compose` и устаревший `docker-compose`.

### Изменение

- Проверить версию Compose на production host.
- Использовать только `docker compose`.
- Проверять наличие требуемой версии перед deploy.
- Аналогично обновить rollback command.

### Проверка

Deploy и rollback выполняются одной Compose implementation.

### Критерий завершения

В CI отсутствуют вызовы `docker-compose`.

## CI-051. Обновлять только application service без `down`

- **Статус:** `TODO`
- **Приоритет:** `P1`
- **Зависимости:** CI-050
- [ ] Завершено

### Проблема

Текущий `docker compose down app` останавливает приложение до запуска нового
контейнера и увеличивает downtime. В некоторых версиях Compose `down` вообще не
предназначен для отдельного сервиса.

### Изменение

Использовать обновление только application service:

```bash
docker compose pull app
docker compose up -d --no-deps app
```

Если установленная версия поддерживает требуемую семантику, допустимо
использовать `--pull always`. Не перезапускать database, proxy и другие сервисы.

### Проверка

- Обновляется только `app`.
- Остальные compose services не перезапускаются.
- Новый container использует ожидаемый image tag.
- Rollback может вернуть предыдущую версию.

### Критерий завершения

Deploy не выполняет полный teardown compose project.

## CI-052. Добавить healthcheck и ожидание готовности

- **Статус:** `TODO`
- **Приоритет:** `P0`
- **Зависимости:** CI-051
- [ ] Завершено

### Проблема

Фиксированный `sleep 5` не гарантирует, что Jmix application завершило startup и
готово обрабатывать запросы.

### Изменение

- Добавить container healthcheck на существующий безопасный readiness endpoint.
- Если endpoint отсутствует, отдельно определить минимальный endpoint без
  раскрытия служебной информации.
- Использовать `docker compose up -d --wait --wait-timeout ...`.
- Удалить фиксированный sleep.
- При timeout печатать `docker compose ps` и последние container logs.

### Проверка

- Быстрый startup не ждёт лишнее фиксированное время.
- Медленный startup ожидается до фактической готовности.
- Неуспешный startup завершает deploy job ошибкой.

### Критерий завершения

Deploy success означает, что приложение действительно готово, а не только что
container находится в состоянии `running`.

## CI-053. Объединить deploy в один SSH-сеанс

- **Статус:** `TODO`
- **Приоритет:** `P2`
- **Зависимости:** CI-052
- [ ] Завершено

### Проблема

Несколько SSH-вызовов увеличивают задержку и позволяют состоянию измениться
между отдельными командами.

### Изменение

- Передать один remote shell script через один SSH-сеанс.
- На remote side включить `set -euo pipefail`.
- В одном script выполнить сохранение прошлой версии, pull, update, wait и
  diagnostics.
- Не выводить credentials и содержимое deploy key.

### Проверка

- В job используется один основной SSH connection.
- Ошибка любой remote-команды завершает job.
- Rollback metadata записывается до изменения container.

### Критерий завершения

Deploy является одной атомарной с точки зрения CI remote-операцией.

## CI-054. Реализовать blue-green deployment

- **Статус:** `OPTIONAL`
- **Приоритет:** `P3`
- **Зависимости:** CI-052, CI-053
- **Условие:** после обычного service update downtime остаётся недопустимым
- [ ] Завершено

### Изменение

- Запускать новую версию параллельно на отдельном service/container.
- Дождаться readiness.
- Переключить reverse proxy.
- Сохранить старую версию до прохождения smoke checks.
- При ошибке вернуть traffic на старую версию.

### Критерий завершения

Переключение версии не создаёт наблюдаемого перерыва и имеет проверенный
автоматический rollback.

---

# Этап 6. Sonar

## CI-060. Подтвердить единственный Sonar job на pipeline

- **Статус:** `WORKING TREE`
- **Приоритет:** `P1`
- **Зависимости:** CI-002
- [ ] Завершено

### Изменение

Сохранить один Sonar job с правилами:

- для web pipeline — выбранное автоматическое или ручное поведение;
- для push/merge request — только одно появление job;
- job не дублируется через разные `only/rules` definitions.

### Проверка

Проверить branch, merge-request и web pipeline. В каждом допустимом pipeline
присутствует не более одного Sonar job.

### Критерий завершения

Sonar не запускается дважды для одного commit/pipeline.

## CI-061. Кешировать Sonar scanner data

- **Статус:** `OPTIONAL`
- **Приоритет:** `P3`
- **Зависимости:** CI-060
- **Условие:** загрузка scanner/analyzers занимает заметное время
- [ ] Завершено

### Изменение

- Направить Sonar user home внутрь project workspace.
- Кешировать только scanner/analyzer cache, например `.sonar/cache`.
- Версионировать cache key при смене scanner.
- Не кешировать результаты анализа.

### Проверка

Прогретый Sonar job не скачивает те же analyzers повторно и быстрее baseline.

### Критерий завершения

Cache уменьшает длительность Sonar job и не влияет на актуальность анализа.

---

# Итоговая проверка pipeline

После завершения всех обязательных задач выполнить полный набор сценариев.

## Автоматический сценарий

1. Push создаёт ровно один pipeline.
2. `fast_test_with_cache` запускается автоматически.
3. Нажатие `full_auto_trigger` не создаёт второй test job.
4. Build ожидает текущие tests.
5. Ошибка tests блокирует build.
6. После успешного JAR build параллельно запускаются SBOM scan и image build.
7. Ошибка SBOM или image build блокирует deploy.
8. Deploy ожидает readiness нового контейнера.

## Ручной сценарий

После успешных тестов доступны отдельные ручные jobs:

```text
build_jar → scan_SBOM → docker_build → deploy_prod
```

Ручные jobs должны использовать те же artifacts, security gates и container
build implementation, что и автоматическая цепочка.

## Локальная проверка

```bash
./gradlew :app:test
./gradlew :app:check -x :app:cyclonedxBom
./gradlew :app:bootJar -Pvaadin.productionMode=true
```

После CI-013 команда `check` должна выполняться без `-x :app:cyclonedxBom`.

## Таблица результатов

Заполнять после каждого изменения:

| Task | Before, cold | After, cold | Before, warm | After, warm | Pipeline result | Решение |
|---|---:|---:|---:|---:|---|---|
| CI-... |  |  |  |  |  | принять/откатить |

# Рекомендуемая последовательность

Последовательность учитывает корректность, зависимости и стоимость внедрения:

1. CI-001, CI-002, CI-003.
2. CI-004, CI-005, CI-006, CI-007.
3. CI-008, CI-010, CI-011, CI-013.
4. CI-014, CI-015, CI-016.
5. CI-017, затем выбрать CI-018 или CI-019.
6. CI-020, при необходимости CI-021 и CI-022.
7. CI-030, CI-031, CI-032, CI-033.
8. CI-040, CI-041.
9. CI-042, CI-043, CI-044, CI-045.
10. CI-050, CI-051, CI-052, CI-053.
11. CI-054 и CI-061 — только при подтверждённой необходимости.

# Официальная документация

- [GitLab CI/CD YAML (`needs`, `dependencies`, `artifacts`)](https://docs.gitlab.com/ci/yaml/)
- [GitLab job artifacts](https://docs.gitlab.com/ci/jobs/job_artifacts/)
- [GitLab: Kaniko is no longer maintained](https://docs.gitlab.com/ci/docker/using_kaniko/)
- [GitLab rootless BuildKit](https://docs.gitlab.com/ci/docker/using_buildkit/)
- [GitLab Docker layer caching](https://docs.gitlab.com/ci/docker/docker_layer_caching/)
- [Gradle build cache](https://docs.gradle.org/current/userguide/build_cache.html)
- [Gradle build cache performance](https://docs.gradle.org/current/userguide/build_cache_performance.html)
- [Gradle configuration cache](https://docs.gradle.org/current/userguide/configuration_cache.html)
- [Gradle performance](https://docs.gradle.org/current/userguide/performance.html)
- [Spring Boot efficient container images](https://docs.spring.io/spring-boot/reference/packaging/container-images/efficient-images.html)
- [Spring Boot Dockerfiles](https://docs.spring.io/spring-boot/reference/packaging/container-images/dockerfiles.html)
- [Vaadin Gradle configuration](https://vaadin.com/docs/latest/flow/configuration/gradle)
- [Docker Compose `up`](https://docs.docker.com/reference/cli/docker/compose/up/)
