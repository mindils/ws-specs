# Результат T09

Таск: [task.md](task.md)
Итерация: 1
Обновлено: 2026-09-12

Ветка: `feature/caseone-table`, база — коммит `f2b96adc2 «step 1»`.
Изменения T09 **не закоммичены** — проверять по рабочему дереву. В дереве также
лежат незакоммиченные наработки T01, T02, T07 и T08 (`legal.warrantyrepair`,
`nsi`, changelog-и `320…324`, сервисы расчёта сроков); T09 их не трогает и
трогается ими только через общий прогон `:app:test`.

## Что реализовано

Конкурентные логины одного OIDC-пользователя больше не падают.

Отказ сначала воспроизведён на этой машине: `./gradlew :app:test --tests
"…SsoOidcUserMapperConcurrencyIT"` → `1 test completed, 1 failed`,
`jakarta.persistence.OptimisticLockException` (EclipseLink-5006, «The object
[ru.fgk.sso.entity.User-01a094c4-… [managed]] cannot be updated because it has
changed or been deleted since it was last read»), брошено напрямую, без обёртки
Spring — то есть ловится по типу `jakarta.persistence.OptimisticLockException`.

Причина подтверждена по исходникам `jmix-oidc-3.0.1-sources.jar` ровно так, как
описано в постановке: `BaseOidcUserMapper.toJmixUser` синхронизируется по
неинтернированной строке имени пользователя, поэтому мониторы у параллельных
потоков разные.

`SsoSynchronizingOidcUserMapper` закрывает это двумя уровнями:

1. **Повтор при конфликте версий.** `toJmixUser` переопределён и выполняет
   `super.toJmixUser(...)` в цикле до 5 попыток. Каждая попытка — это полный
   цикл базового класса: `initJmixUser` заново читает пользователя через
   `UserRepository.loadUserByUsername` (`AbstractDatabaseUserRepository` каждый
   раз идёт в БД, то есть попытка работает со свежей версией), затем заново
   заполняются атрибуты и полномочия и повторяется сохранение. Пауза между
   попытками 20 мс × номер попытки. Повтор срабатывает только на конфликте
   версий: `isVersionConflict` идёт по цепочке причин и ищет
   `jakarta.persistence.OptimisticLockException` либо
   `org.springframework.dao.OptimisticLockingFailureException`; любое другое
   исключение пробрасывается сразу, без повторов. При исчерпании попыток
   пробрасывается последнее исключение конфликта (C6).
2. **Канонический замок по имени пользователя** — фиксированный набор из 64
   `ReentrantLock`, индекс берётся по `Math.floorMod(username.hashCode(), 64)`.
   Это не `synchronized` по строке и не `String.intern()` на пользовательском
   вводе: реестр замков не растёт от имён из внешнего токена. Внутри JVM логины
   одного пользователя сериализуются, поэтому повторы не молотят вхолостую;
   между экземплярами приложения работает пункт 1.

Поведение одиночного логина не изменилось: первая попытка успешна — повторного
сохранения нет (доказано unit-тестом `singleLoginSavesOnce`).
`setSynchronizeRoleAssignments(true)` сохранён, схема `ru.fgk.sso.entity.User`
не тронута, код `io.jmix.oidc` не патчен, `SsoOidcUserMapperConcurrencyIT` не
изменён (6 потоков, `new String(username)`, `assertEquals(1L, count)` — C3).

## Изменения и решения

Все изменения — в `sso-plagin`; `app/src` не затронут (C5).

| Файл | Что сделано |
|---|---|
| `sso-plagin/sso-plagin/src/main/java/ru/fgk/sso/impl/SsoSynchronizingOidcUserMapper.java` | Переопределён `toJmixUser`: канонический замок + повтор при конфликте версий |
| `sso-plagin/sso-plagin/src/test/java/ru/fgk/sso/impl/SsoSynchronizingOidcUserMapperTest.java` | Новый unit-тест (5 сценариев), БД не нужна |
| `sso-plagin/sso-plagin/sso-plagin.gradle` | `testRuntimeOnly 'org.junit.platform:junit-platform-launcher'` |
| `sso-plagin/sso-plagin/src/test/java/ru/fgk/sso/SsoTest.java` | Контекст аддона поднимается без Keycloak: исключён OAuth2-автоконфиг клиента, `JwtDecoder` и `ClientRegistrationRepository` — `@MockitoBean` |
| `sso-plagin/sso-plagin/src/test/java/ru/fgk/sso/SsoTestConfiguration.java` | Бин `UserRepository` (`InMemoryUserRepository`) для контекста аддона |
| `sso-plagin/sso-plagin/src/test/resources/ru/fgk/sso/liquibase/changelog-test.xml` (новый) и `test-app.properties` | Мастер-changelog тестов аддона: сначала changelog-и `io.jmix.data` и `io.jmix.securitydata`, затем sso |

Существенные решения:

- **Повтор поставлен на уровень `toJmixUser`, а не `saveJmixUserAndRoleAssignments`.**
  Постановка допускает оба варианта. На уровне `toJmixUser` перезагрузка
  пользователя, перезаполнение атрибутов и повтор сохранения получаются
  штатным путём базового класса, и вызывающему возвращается тот экземпляр
  `User`, который реально сохранён, а не тот, что остался от неудачной попытки.
- **Striped-замки вместо `ConcurrentHashMap.computeIfAbsent`.** Постановка
  допускает оба; фиксированный набор не даёт внешнему вводу (имя пользователя
  из токена) наращивать реестр и не требует вычистки. Цена — логины двух разных
  пользователей с одинаковым остатком хеша по 64 сериализуются между собой;
  операция короткая, на практике это незаметно. Guava `Striped` не
  использовалась, чтобы не тянуть в аддон новую явную зависимость.
- **Отдельно от логики пришлось починить тестовый контур `sso-plagin`.**
  До этой задачи `./gradlew :sso-plagin:sso-plagin:test` вообще не запускался:
  `Could not start Gradle Test Executor … Failed to load JUnit Platform`
  (Gradle 9 требует launcher на runtime-классpath). Проверено отдельно, с
  временно убранным новым тестом, — отказ был до изменений T09. После
  подключения launcher-а вскрылись следующие слои, тоже существовавшие раньше
  и просто никогда не выполнявшиеся: у контекста аддона нет бина
  `UserRepository` (его даёт приложение), нет `JwtDecoder` (нужен Keycloak) и
  тестовый `main.liquibase.change-log` вёл только на changelog sso, который
  вставляет строку в `SEC_ROLE_ASSIGNMENT` — таблицу чужого модуля. Всё
  починено внутри `sso-plagin` тестовыми средствами, без правок main-кода
  аддона и без ослабления `SsoTest` (он по-прежнему поднимает контекст).

## Предварительные проверки

Инфраструктура: `docker info` — OK; `docker compose ps` — `docker-rvk-db-1`
(postgres 16.11) слушает `0.0.0.0:5432`, поднимать заново не потребовалось;
`app/src/test/resources/application-test-local.properties` указывает на
`jdbc:postgresql://localhost:5432/postgres?currentSchema=main`.

| Команда или сценарий | Результат |
|---|---|
| `./gradlew :app:test --tests "ru.fgk.ws.app.sso.SsoOidcUserMapperConcurrencyIT"` (до изменений) | `1 test completed, 1 failed` — `OptimisticLockException` EclipseLink-5006 |
| `./gradlew :app:compileJava` | BUILD SUCCESSFUL |
| `./gradlew spotlessApply` + `./gradlew spotlessCheckAll` | BUILD SUCCESSFUL; переформатированы только файлы `sso-plagin` этой задачи |
| `./gradlew :app:test --tests "ru.fgk.ws.app.sso.SsoOidcUserMapperConcurrencyIT" --rerun-tasks`, прогон 1 | `1 passing` (19 s) |
| то же, прогон 2 | `1 passing` (18.7 s) |
| то же, прогон 3 | `1 passing` (19 s) |
| `./gradlew :sso-plagin:sso-plagin:test --rerun-tasks` | BUILD SUCCESSFUL; `SsoSynchronizingOidcUserMapperTest` 5/0 failures, `SsoTest` 1/0 failures |
| `./gradlew :app:test` (полный) | BUILD SUCCESSFUL; **1348 passing, 0 failing, 12 pending** |

Гейт 1 — `compileJava` + `spotlessCheckAll`; инспекция IDE (`get_file_problems`)
не выполнялась: MCP JetBrains в этой сессии не подключён. Новых XML-дескрипторов
views в таске нет, единственный новый XML — Liquibase-мастер тестов аддона,
который реально применяется при зелёном `SsoTest`.
Гейт 2 — полный `:app:test` зелёный.
Гейт 3 не применим: views не создавались.

Что проверяет новый unit-тест (`:sso-plagin:sso-plagin:test`, БД не нужна):

- `singleLoginSavesOnce` — без конкуренции ровно один `dataManager.save` и одно
  чтение пользователя (C4);
- `retriesAndReloadsUserOnVersionConflict` — после `OptimisticLockException` и
  `OptimisticLockingFailureException` логин завершается успехом с третьей
  попытки, пользователь перечитан на каждой попытке;
- `propagatesConflictWhenAttemptsExhausted` — 5 попыток и наружу уходит то же
  самое исключение (C6);
- `doesNotRetryUnrelatedFailure` — обычная ошибка не превращается в 5 попыток;
- `concurrentLoginsOfTheSameUserAreSerialized` — 6 потоков с отдельными
  экземплярами строки имени; одновременно в сохранении не больше одного
  (канонический замок), при этом сохранений ровно 6.

## Для независимой проверки

```bash
docker info
(cd docker && docker compose ps)          # нужен docker-rvk-db-1 на localhost:5432
(cd docker && docker compose up -d)       # если не поднят

cd ~/data/dev/fgk/rvk-ws
./gradlew :app:compileJava
./gradlew spotlessCheckAll
./gradlew :sso-plagin:sso-plagin:test --rerun-tasks
for i in 1 2 3; do
  ./gradlew :app:test --tests "ru.fgk.ws.app.sso.SsoOidcUserMapperConcurrencyIT" --rerun-tasks
done
./gradlew :app:test
```

`--rerun-tasks` обязателен для повторных прогонов одного и того же теста: без
него Gradle отдаёт `UP-TO-DATE` и прогона не происходит.

Отдельная сессия окружения не нужна: тесты идут по уже поднятому Docker,
Keycloak и браузер не требуются, секретов заводить не нужно.

Проверка C5 (чужие файлы не тронуты):

```bash
git status --porcelain -- app/src   # только изменения T01/T02/T07/T08, без файлов T09
git status --porcelain -- sso-plagin
```

## Ограничения и связанные изменения

- Второй уровень защиты — канонический замок — действует только внутри JVM.
  При нескольких экземплярах приложения гонку разруливает повтор (пункт 1);
  это принятая постановкой граница, БД-блокировки не вводились.
- Striped-набор из 64 замков сериализует также логины разных пользователей,
  попавших в один stripe. Осознанный размен на отсутствие растущего реестра.
- Полный `:app:test` прогнан на рабочем дереве, где лежат незакоммиченные
  наработки T01, T02, T07 и T08. Он зелёный целиком (1348 passing), поэтому
  постоянного исключения из гейта 2 у работы больше нет: пункт 5 «Требуемого
  результата» плана закрыт.
- Инспекция IDE по изменённым файлам не выполнялась (нет подключения); её при
  наличии стоит прогнать по
  `SsoSynchronizingOidcUserMapper.java` и файлам тестов `sso-plagin`.
- Изменения T09 не отменяют доказательства других тасков: код
  `legal.warrantyrepair` и `nsi` не затронут.
