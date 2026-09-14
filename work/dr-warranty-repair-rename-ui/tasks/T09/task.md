# T09 — Гонка при конкурентной синхронизации OIDC-пользователя

Статус: done
План: ../../plan.md
Зависимости: нет
Актуальная проверка: [checks/001.md](checks/001.md) — pass; результат — [result.md](result.md), итерация 1
Связанные вопросы: [Q03](../../questions/Q03.md) — resolved, таск заведён по ответу пользователя

## Результат и контекст

Единственный красный тест ветки — `ru.fgk.ws.app.sso.SsoOidcUserMapperConcurrencyIT.concurrentLoginsOfTheSameUserDoNotFail`
(`app/src/test/java/ru/fgk/ws/app/sso/SsoOidcUserMapperConcurrencyIT.java`).
Шесть потоков одновременно вызывают `SsoSynchronizingOidcUserMapper.toJmixUser(...)`;
падение — `jakarta.persistence.OptimisticLockException` (EclipseLink-5006) на
`ru.fgk.sso.entity.User`. Отказ воспроизводимый, не флаки: подтверждён
отдельными прогонами при разборе Q03, последний — на рабочем дереве
`feature/caseone-table` (HEAD `f2b96adc2`) с наработками T01,
`1 test completed, 1 failed`.

Тест появился в этой же ветке коммитом `dd71c094f «Добавлены таблицы для
caseone»`, в `main` его нет: это незавершённая работа ветки по SSO, а не
регрессия `main` и не следствие T01 (T01 трогает только четыре entity
`legal.warrantyrepair`, четыре changelog-а и блок i18n-ключей
`…warrantyrepair…`).

**Причина установлена по исходникам `io.jmix.oidc` 3.0.1**
(`jmix-oidc-3.0.1-sources.jar`):

- `io.jmix.oidc.usermapper.BaseOidcUserMapper.toJmixUser` защищает всю
  синхронизацию блоком `synchronized (getOidcUserUsername(oidcUser))` — по
  **неинтернированной** строке имени пользователя. Каждый `OidcUser` даёт
  свой экземпляр `String`, мониторы разные, взаимного исключения нет. Тест
  это подчёркивает намеренно: `String freshUsername = new String(username)`.
- `SynchronizingOidcUserMapper.saveJmixUserAndRoleAssignments` в одном
  `SaveContext` (с `PersistenceHints.SOFT_DELETION = false`) удаляет **все**
  `RoleAssignmentEntity` пользователя, создаёт новые из claims и сохраняет
  `User`. Параллельные логины читают одну и ту же версию `User` и один и тот
  же набор назначений: второй коммит падает на optimistic lock, а при другом
  чередовании остаются дубли назначений.

**Требуемый результат.** Конкурентные логины одного пользователя не падают;
после них в `sec_RoleAssignmentEntity` ровно одно назначение на роль из
claims; `./gradlew :app:test` зелёный без исключений (гейт 2 работы держится
строго зелёным — решение по [Q03](../../questions/Q03.md)).

## Реализация

Правится только
`sso-plagin/sso-plagin/src/main/java/ru/fgk/sso/impl/SsoSynchronizingOidcUserMapper.java`
(модуль composite build; по `CLAUDE.md` addon-модули меняются по
необходимости). Код `io.jmix.oidc` не патчим, тест не ослабляем и не
отключаем.

Опора решения — два уровня:

1. **Повтор при конфликте версий — основной механизм.** Переопределить
   `saveJmixUserAndRoleAssignments` (либо `toJmixUser`), ловить
   `jakarta.persistence.OptimisticLockException` и
   `org.springframework.dao.OptimisticLockingFailureException`, заново
   загружать `User` по username (свежая версия), заново заполнять атрибуты и
   повторять сохранение. Ограниченное число попыток (3–5) и небольшая пауза;
   при исчерпании — пробросить исходное исключение, а не глотать. Работает и
   при нескольких экземплярах приложения.
2. **Канонический per-username монитор — чтобы попытки не молотили вхолостую
   внутри JVM.** Собственный реестр объектов-замков
   (`ConcurrentHashMap.computeIfAbsent` или guava `Striped`), а не
   `synchronized` по строке и не `String.intern()` на пользовательском вводе.
   Только в пределах JVM, поэтому пункт 1 не заменяет.

Границы: поведение одиночного логина не меняется; `setSynchronizeRoleAssignments(true)`
сохраняется; схема `ru.fgk.sso.entity.User` не трогается. Changelog и i18n не
нужны — нового пользовательского текста нет. Constructor injection, без field
`@Autowired` (скил `jmix-create-service`). Если для проверки нужен ещё один
тест — скил `jmix-create-test`, тесты `sso-plagin` кладутся в свой модуль.

## Критерии приёмки

- C1: `./gradlew :app:test --tests "ru.fgk.ws.app.sso.SsoOidcUserMapperConcurrencyIT"`
  зелёный **три прогона подряд** (отказ был воспроизводимым, разовый зелёный
  ничего не доказывает).
- C2: `./gradlew :app:test` целиком — `0 failing`.
- C3: сценарий и утверждения теста сохранены: 6 потоков, `new String(username)`,
  ровно одно назначение роли. Изменения теста, ослабляющие проверку
  (уменьшение числа потоков, retry внутри теста, смягчение assert), не
  допускаются.
- C4: одиночный логин не деградировал — `./gradlew :sso-plagin:sso-plagin:test`
  зелёный; при отсутствии конкуренции повторное сохранение не выполняется
  (первая попытка успешна).
- C5: изменения только в `sso-plagin`; `app/src/main` не затронут.
- C6: при исчерпании попыток исключение пробрасывается — отказ логина не
  маскируется тихим успехом с неполным набором ролей.

## Проверка

Инфраструктура (`CLAUDE.md`): `docker info`; `(cd docker && docker compose ps)`;
`(cd docker && docker compose up -d)`; `app/src/test/resources/application-test-local.properties`
указывает на `localhost:5432` поднятого `docker-rvk-db-1`.

```bash
./gradlew :app:compileJava
./gradlew spotlessApply spotlessCheckAll
./gradlew :app:test --tests "ru.fgk.ws.app.sso.SsoOidcUserMapperConcurrencyIT"   # три раза
./gradlew :sso-plagin:sso-plagin:test
./gradlew :app:test
```

Гейт 1 (статика): инспекция IDE (`get_file_problems`) по изменённому файлу;
запасное — `compileJava` + скил `jmix-ide-static-analysis`.
Гейт 2: полный `:app:test` без отказов.
Гейт 3 не применим: views в этом таске не создаются.

Точные команды, число прогонов и итоговые счётчики тестов записать в `result.md`.

## Прогресс и продолжение

- [x] Воспроизвести отказ на своей машине и зафиксировать исходный стектрейс
      (`1 test completed, 1 failed`, `OptimisticLockException` EclipseLink-5006,
      брошено напрямую — ловится по типу `jakarta.persistence.OptimisticLockException`).
- [x] Реализовать повтор при конфликте версий и канонический per-username монитор
      (повтор на уровне `toJmixUser`, 5 попыток; 64 `ReentrantLock` по хешу имени).
- [x] Починить тестовый контур `sso-plagin`: без launcher-а JUnit Platform задача
      `:sso-plagin:sso-plagin:test` не запускалась вовсе (отказ был до T09), после
      подключения вскрылись отсутствующий бин `UserRepository`, отсутствующий
      `JwtDecoder` и changelog тестов без таблиц `io.jmix.securitydata`.
- [x] Прогнать C1 (три прогона `--rerun-tasks`, все `1 passing`), C4
      (`:sso-plagin:sso-plagin:test` — 6 тестов, 0 отказов), полный `:app:test`
      (**1348 passing, 0 failing, 12 pending**).
- [x] Передать результат на независимую проверку.
- [x] Независимая проверка пройдена — [checks/001.md](checks/001.md), итог `pass`:
      C1 три прогона подряд `1 passing` (плюс четвёртый внутри полного прогона),
      C2 `:app:test` — 1348 passing, 12 pending, 0 failing (exit 0),
      C3 тест байт-в-байт равен версии в HEAD, C4 `:sso-plagin:sso-plagin:test`
      6/0, C5 в `app/src` нет файлов T09, C6 подтверждён кодом и тестом.
      Дополнительно снят негативный контроль: откат одного только
      `SsoSynchronizingOidcUserMapper.java` возвращает `OptimisticLockException`
      (EclipseLink-5006), файл восстановлен и сверен по md5.

Таск закрыт. Пункт 5 «Требуемого результата» плана выполнен: постоянного
исключения из гейта 2 у работы больше нет.
Ближайший шаг: следующий доступный таск — `task-execute` по
`specs/work/dr-warranty-repair-rename-ui/tasks/T02/task.md`.
Препятствия: нет.
