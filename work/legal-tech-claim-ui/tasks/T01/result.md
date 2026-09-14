# Результат T01

Таск: [task.md](task.md)
Итерация: 2
Обновлено: 2026-09-14

## Что реализовано

Раздел претензий по технологическим неисправностям переименован в
`legal_tech_claim*` на всех слоях: таблицы и view, файлы changelog-ов,
константы БД, пакет `ru.fgk.ws.app.legal.techclaim`, классы entity и enum,
Jmix-имена, сервисы расчёта сроков, роль администратора раздела, ключи i18n,
тесты и карта кода в документе отличий. Ни одна колонка, ни один тип и ни один
алгоритм не изменены. Локальная БД пересоздана с нуля: таблицы и view раздела
созданы под новыми именами, объектов со старыми именами не осталось.

Итерация 2 (исправление [F01](fixes/F01.md)): из набора `app` снят
отложенный тест `SsoOidcUserMapperConcurrencyIT` — единственное падение
итерации 1. Полный `./gradlew :app:test` теперь зелёный.

Перед переименованием пришлось восстановить базовую линию. На старте рабочее
дерево было рассогласовано: новые файлы раздела (сроки, НСИ, view, тесты)
лежали на месте, а правки уже закоммиченных файлов отсутствовали — entity
указывали на устаревшие таблицы `legal_warranty_repair*` со старыми именами
колонок, а в `messages_ru.properties` не было ни одного ключа для сроков,
view и НСИ. Причина — `git stash` перед слиянием `main` в
`feature/caseone-table` без последующего `git stash pop`. Относящаяся к T01
часть `stash@{1}` (2026-09-14 09:52) возвращена `git apply --3way`, правки
`main` при этом сохранены. Stash не изменялся и не удалялся.

## Изменения и решения

Восстановлено из `stash@{1}` (до переименования): `LegalWarrantyRepair`,
`…Deps`, `…Du`, `…CaseOne`, `LegalWarrantyRepairRole`, `menu.xml` (узел НСИ
«Сроки претензий» из T07 прежней работы), `messages_ru.properties` (+317
строк, включая ключи сроков и НСИ) и удаление устаревших changelog-ов
`01-tbl/320…323-legal_warranty_repair*.xml`.

Переименование:

- каталоги `legal/warrantyrepair` → `legal/techclaim` в `main` и `test`,
  перенос через `git mv` для отслеживаемых файлов;
- классы: `LegalTechClaim`, `…Deps`, `…Du`, `…CaseOne`,
  `LegalTechClaimDeadline`, `VLegalTechClaim`, семь `TechClaim*Enum`,
  `TechClaimDeadlineService`, `TechClaimDeadlineRecalculationListener`,
  `TechClaimDeadlinePublicationHandler`, `LegalTechClaimAdminRole`
  (код роли `legal-tech-claim-admin`, `@ResourceRole(name =
  "LegalTechClaimAdmin")`, методы политик `techClaim*()`);
- классы `ClaimTerm*` и `ClaimTermOverdueLevelEnum` имена сохранили, как
  требует таск;
- таблицы `legal_tech_claim`, `_deps`, `_du`, `_case_one`, `_deadlines`,
  view `legal_v_tech_claim`; константы `PK_/IDX_/UQ_LEGAL_TECH_CLAIM*`;
  файлы `01-tbl/320…324-legal_tech_claim*.xml`,
  `02_view/independent/legal_v_tech_claim.xml`;
- тесты `TechClaimDeadlineIT`, `TechClaimViewIT`,
  `legal/techclaim/service/ClaimTermCalculatorTest`.

Локальные решения:

- `author` во всех девяти changeSet-ах шести файлов раздела приведён к
  `legal` (было `app` и `dr`). Таск требует `author="legal"` явно только для
  view; для таблиц оставлять `dr` после переименования в `legal_tech_claim`
  было бы противоречиво, а идентичность changeSet-а всё равно меняется
  вместе с именем файла, и БД раздела пересоздаётся.
- В локальной БД дополнительно удалены таблицы `legal_warranty_repair*` и
  строки `databasechangelog` по ним: их changelog-и удалены восстановленной
  частью stash, объекты остались бы сиротами.
- Строка о переименовании в документе отличий намеренно не содержит старых
  имён — иначе она сама попадала бы под grep критерия C6.
- Итерация 2: удалён файл
  `app/src/test/java/ru/fgk/ws/app/sso/SsoOidcUserMapperConcurrencyIT.java`
  (каталог `app/src/test/java/ru/fgk/ws/app/sso/` больше не существует). Тест
  закоммичен в `dd71c094f` в рамках T09 прежней работы и без кода
  `sso-plagin`, отложенного пользователем в `stash@{1}`, падает с
  `OptimisticLockException`. Основание — ответ пользователя в
  [Q02](../../questions/Q02.md) и способ исправления в
  [F01](fixes/F01.md). Stash не изменялся: в `git stash list` прежние восемь
  записей. Возврат теста вместе с кодом:
  `git checkout dd71c094f -- app/src/test/java/ru/fgk/ws/app/sso/SsoOidcUserMapperConcurrencyIT.java`.

## Предварительные проверки

| Команда или сценарий | Результат |
|---|---|
| `(cd system && ./change-gradle-to-remote-repo.sh)` | wrapper переключён на `services.gradle.org` (вне корпоративной сети) |
| `./gradlew :app:compileJava :app:compileTestJava` | BUILD SUCCESSFUL |
| `./gradlew spotlessApply` + `spotlessCheckAll` | BUILD SUCCESSFUL |
| grep C1 (из «Самопроверки») | остались только допустимые остатки: поля `warrantyRepair` entity модулей `dr`, `rp`, `wagons`, `drcontract`, их ключи i18n, `LegalTechClaim.warrantyRepair` (колонка `warranty_repair`, enum `ru.fgk.ws.app.dr.entity.WarrantyRepairEnum`) |
| `./gradlew :app:test --tests "ru.fgk.ws.app.legal.techclaim.*" --tests "ru.fgk.ws.app.it.TechClaimDeadlineIT" --tests "ru.fgk.ws.app.it.TechClaimViewIT"` | 57 passing, 0 failing |
| Пересоздание БД (п. 7 реализации) + запрос числа колонок | `legal_tech_claim` 49, `_deps` 76, `_du` 34, `_case_one` 16, `_deadlines` 37, `legal_v_tech_claim` 104; таблиц `%warranty_repair%` — 0 |
| Запрос по `pg_indexes` | все шесть индексов из C3 на месте, `idx_legal_tech_claim_wag_defect` UNIQUE, `uq_legal_tech_claim_deps_claim` частичный `WHERE deleted_date IS NULL` |
| Сверка ключей i18n скриптом | 354 ключа раздела до и после; осиротевших ключей и полей без ключа нет |
| Итерация 2: `./gradlew :app:test` (полный набор — прямо требует F01) | 1347 passing, 12 pending, 0 failing |
| Итерация 2: `git stash list` | восемь записей, ни одна не изменена |

В прогоне итерации 2 выполнены и зелёные тесты раздела и регрессии:
`TechClaimDeadlineIT` 14, `TechClaimViewIT` 3, `ClaimTermCalculatorTest` 6,
`WorkCalendarReferenceDataIT` 12, `NsiClaimTermEditRoleIT` 3 — без падений и
пропусков (по `app/build/test-results/test/*.xml`).

Не запускалось, оставлено проверяющему: повторная сверка критериев C1–C4 и C6
после исправления, проверка ролей и любые браузерные сценарии
(`render not browser-verified`; экранов раздела ещё нет).

## Для независимой проверки

Окружение вне корпоративной сети: сначала
`(cd system && ./change-gradle-to-remote-repo.sh)`, иначе wrapper не скачает
дистрибутив Gradle. Нужен запущенный Docker Compose и локальный override
datasource `app/src/test/resources/application-test-local.properties`
(в дереве уже есть, JDBC на `localhost:5432`).

```bash
docker info && (cd docker && docker compose up -d)
docker exec docker-rvk-db-1 psql -U root -d postgres -c "select count(*) from information_schema.tables where table_schema='main' and table_name like '%warranty_repair%';"
./gradlew :app:compileJava spotlessCheckAll
./gradlew :app:test
docker exec docker-rvk-db-1 psql -U root -d postgres -c "select table_name, count(*) from information_schema.columns where table_schema='main' and (table_name like 'legal_tech_claim%' or table_name='legal_v_tech_claim') group by 1 order by 1;"
docker exec docker-rvk-db-1 psql -U root -d postgres -c "select indexname from pg_indexes where schemaname='main' and tablename like 'legal_tech_claim%' order by 1;"
```

Пересоздавать таблицы раздела заново не нужно: они уже созданы Liquibase с
нуля под новыми именами в этой сессии, старых в БД нет. Если проверка идёт на
другой БД, сначала выполнить п. 7 реализации, добавив к нему
`drop table if exists main.legal_warranty_repair_case_one,
main.legal_warranty_repair_du, main.legal_warranty_repair_deps,
main.legal_warranty_repair cascade;`.

Общий ресурс — локальная БД `docker-rvk-db-1`; изоляции для неё нет,
параллельных сессий во время проверки быть не должно.

## Ограничения и связанные изменения

- Остаток `stash@{1}`/`stash@{2}` вне области T01 не восстанавливается —
  [Q02](../../questions/Q02.md) решён 2026-09-14: пользователь отложил код
  OIDC намеренно, настройки окружения ведёт сам, два changelog-а не являются
  потерянной работой. Следствие: кода T09 прежней работы (`sso-plagin`) в
  дереве нет и его тест в `app` снят — T09 остаётся исторически проверенным,
  но не воспроизводимым, о чём приписано в `summary.md` прежней работы.
- Изменения затрагивают артефакты прежней работы (T01, T02, T07, T08
  `dr-warranty-repair-rename-ui`) — их прежние доказательства относятся к
  старым именам. Работа закрыта, переоткрытие её тасков не требуется:
  актуальное поведение подтверждается проверкой этого таска.
- Каталог `app/bin/**` (вывод сборки IDE, не отслеживается Git) содержит
  устаревшие классы со старыми именами. На Gradle-сборку и тесты не влияет,
  чистится пересборкой в IDE.
