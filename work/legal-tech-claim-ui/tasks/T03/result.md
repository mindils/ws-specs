# Результат T03

Таск: [task.md](task.md)
Итерация: 1
Обновлено: 2026-09-14

## Что реализовано

Зоны ДЭПС и ДЮ в карточке претензии разделены правами: заведены рабочие роли
`legal-tech-claim-deps` и `legal-tech-claim-du`, а прежняя полная роль
`legal-tech-claim-admin` дополнена до матрицы таска. Каждая из трёх ролей
открывает `legal_TechClaim.list` и `legal_TechClaim.detail` и пункт меню
`legal_TechClaim.list` — id зафиксированы планом, экраны появятся в T04/T05.
Роль `nsi-claim-term-edit` рабочим ролям не выдаётся: НСИ календаря, норм и
ревизий доступны всем трём ролям только на чтение.

Сервис `TechClaimService.createClaim(repairUid)` заводит дополнительную
претензию по уже загруженной отцепке: право CREATE проверяется явно, индекс
считается как максимум по неудалённым претензиям отцепки плюс один, сама
претензия сохраняется пользовательским `DataManager` (права и аудит
пользователя), парная пустая строка ДЮ — под системной аутентификацией через
`UnconstrainedDataManager`. Строка `case_one` не создаётся, расчёт сроков
заводит штатный слушатель T08. При конфликте частичного уникального индекса
индекс пересчитывается и создание повторяется один раз.

Критерии C1–C5 закрыты интеграционным тестом `TechClaimSecurityIT`
(10 тестов), распознавание конфликта индекса — unit-тестом
`TechClaimServiceTest` (4 теста). C6 (полный `:app:test`) оставлен
проверяющему.

## Изменения и решения

Изменённые области:

- `app/.../legal/techclaim/security/LegalTechClaimDepsRole.java`,
  `LegalTechClaimDuRole.java` — новые рабочие роли;
  `LegalTechClaimAdminRole.java` — добавлены `@ViewPolicy`/`@MenuPolicy`,
  чтение `VLegalTechClaim` и НСИ сроков, javadoc приведён к реальному составу.
- `app/.../legal/techclaim/service/TechClaimService.java` — новый сервис.
- `app/src/test/java/ru/fgk/ws/app/it/TechClaimSecurityIT.java`,
  `app/src/test/java/ru/fgk/ws/app/legal/techclaim/service/TechClaimServiceTest.java`
  — новые тесты.

Существенные решения:

- Общие для трёх ролей политики чтения выписаны в каждой роли, а не вынесены в
  общую роль-предок: таск фиксирует ровно три кода ролей, а лишняя роль в
  списке назначений путала бы администратора. Дублирование ловится тестом C1,
  который сверяет и отсутствие лишних политик.
- Повтор при конфликте индекса вынесен из `@Transactional` в
  `TransactionTemplate` с `REQUIRES_NEW`: нарушение ограничения PostgreSQL
  прерывает текущую транзакцию целиком, поэтому повторить вычисление внутри неё
  нельзя — следующий оператор упал бы с «current transaction is aborted».
  Претензия и парная строка ДЮ внутри одной попытки по-прежнему сохраняются
  атомарно.
- Индекс претензии считается мимо прав пользователя (системная аутентификация,
  `UnconstrainedDataManager`): строки, скрытые ограничениями доступа, всё равно
  занимают номер в уникальном индексе. Мягко удалённые строки номер
  освобождают — это поведение самого частичного индекса и оно проверено тестом.
- Право CREATE проверяется до записи через `AccessManager`/`CrudEntityContext`,
  хотя `DataManager` отверг бы сохранение и сам: иначе отказ приходил бы уже
  после вычисления индекса и ссылался бы на строку, а не на операцию.
- Ключи i18n не добавлялись: сервис не выдаёт пользователю текста, а роли в
  проекте сообщениями не сопровождаются (ср. `NsiClaimTermEditRole`).

Пользователи с ролями в IT создаются как в `NsiClaimTermEditRoleIT`:
`metadata.create(User.class)` + `unconstrainedDataManager.save(...)`, затем
`RoleAssignmentEntity` с `RoleAssignmentRoleType.RESOURCE` и кодом роли;
проверки идут внутри `systemAuthenticator.runWithUser(...)` /
`withUser(...)`. Данные теста помечены номером вагона `90000003` и убираются
через JDBC в `@AfterEach`.

## Предварительные проверки

| Команда или сценарий | Результат |
|---|---|
| `./gradlew :app:compileJava spotlessApply` | успешно |
| `./gradlew :app:test --tests "ru.fgk.ws.app.it.TechClaimSecurityIT"` | 10 passing |
| `./gradlew :app:test --tests "ru.fgk.ws.app.legal.techclaim.service.TechClaimServiceTest"` | 4 passing |
| SQL после прогона: строки вагона `90000003` и пользователи `t03-%` | не осталось |

Не запускалось, оставлено проверяющему: полный `./gradlew :app:test` (C6),
регрессии `TechClaimDeadlineIT` и `NsiClaimTermEditRoleIT`, повторный прогон с
`--rerun-tasks`, браузерные проходы (таск их не требует).

## Для независимой проверки

Нужны поднятый Docker Compose и локальная БД приложения на `localhost:5432`
(`docker/docker-compose.yml`), а также
`app/src/test/resources/application-test-local.properties` с локальным JDBC
URL — без него тестовый профиль уходит на `devx.main.vgk`.

```bash
(cd docker && docker compose up -d)
./gradlew :app:test
./gradlew :app:test --tests "ru.fgk.ws.app.it.TechClaimSecurityIT" --rerun-tasks
```

SQL-контроль после прогона (пользователь `root`, БД `postgres`, схема `main`):

```sql
select (select count(*) from main.legal_tech_claim where wagnum = 90000003),
       (select count(*) from main.sso_user where username like 't03-%'),
       (select count(*) from main.sec_role_assignment where username like 't03-%');
```

Общие ресурсы: БД и Gradle daemon; проверка T03 идёт после проверки T02, как
задано планом. Браузер не нужен.

## Ограничения и связанные изменения

- Ветка повтора при конфликте индекса в интеграционном тесте не гарантирована:
  тест «Одновременное создание двух претензий одной отцепки» проверяет
  результат (обе претензии созданы, индексы различны), но база в наблюдаемых
  прогонах разводила вставки без конфликта. Само распознавание конфликта
  (SQLState класса 23 и имя индекса в цепочке причин) покрыто
  `TechClaimServiceTest`, механика отдельной транзакции — обзором кода.
- Матрица таска не даёт роли ДЮ права CREATE на `LegalTechClaimDu`. Для
  претензий, заведённых `createClaim`, и для загруженных из старой системы пар
  это неважно, но план для T05 предполагает создание строки ДЮ в контейнере,
  если её нет. Если в T05 такой случай окажется реальным (претензия без парной
  строки), потребуется либо создание строки сервисом под системной
  аутентификацией, либо правка матрицы отдельным решением — в T03 матрица
  соблюдена как записана.
- `@ViewPolicy`/`@MenuPolicy` ссылаются на ещё не существующие
  `legal_TechClaim.list` и `legal_TechClaim.detail`: Jmix такие id при старте
  не проверяет, контекст поднимается. T04 и T05 обязаны использовать именно
  эти id и не трогать файлы ролей.
- Доказательства других тасков не затронуты: entity, changelog-и, view и
  `menu.xml` не изменялись.
