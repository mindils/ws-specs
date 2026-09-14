# Результат T01

Таск: [task.md](task.md)
Итерация: 2
Обновлено: 2026-09-11

Ветка: `feature/caseone-table`, база — мерж-коммит `f2b96adc2 «step 1»`
(слияние `a9b082e2f` из `main` завершено). Изменения T01 **не закоммичены** —
проверять по рабочему дереву.

## Что реализовано

Переименование выполнено полностью и накатано на объединённую с `main` ветку:
четыре таблицы `legal_warranty_repair*` стали `dr_warranty_repair*`, колонки и
Java-поля переименованы по таблицам постановки, i18n-ключи приведены к новым
именам полей, индекс отцепки сделан уникальным. Состав колонок не менялся:
175 колонок до и 175 после, ни одна не добавлена и не удалена.

Liquibase применяется к пустой от этих таблиц БД с нуля: все четыре таблицы
созданы, индексы созданы, включая уникальный по `(wagnum, defect_date)` и
частичный уникальный по претензии под новым именем.

Главное отличие от итерации 1: **гейт 2 разблокирован**. Ранее контекст не
поднимался и падало 169 тестов ([Q02](../../questions/Q02.md)); теперь
`./gradlew :app:test` — 1265 passing, 12 pending, **1 failing**, и этот
единственный отказ к таску не относится (см. «Ограничения» и
[Q03](../../questions/Q03.md)).

## Изменения и решения

Что сделано в этой итерации: наработки итерации 1 лежали в `stash@{0}`, сделанном
на старом `main`, и содержали 329 файлов — целиком применять его нельзя, он
откатил бы посторонние изменения. Поэтому из стеша перенесены **только файлы
таска**:

- `git checkout stash@{0} --` по четырём entity;
- `git rm` четырёх `32?-legal_warranty_repair*.xml` + `git checkout stash@{0} --`
  четырёх `32?-dr_warranty_repair*.xml`;
- `messages_ru.properties` — точечная замена блока ключей `…warrantyrepair…`
  (217 строк, 207 ключей) версией из стеша; остальной файл не тронут
  (`git diff --stat`: 44 вставки / 44 удаления — только переименования ключей,
  число ключей до и после 207).

Changelog-и (переименованы, `createTable` переписан на месте,
`renameTable`/`renameColumn` не добавлялись):

- `320-legal_warranty_repair.xml` → `320-dr_warranty_repair.xml`
- `321-legal_warranty_repair_deps.xml` → `321-dr_warranty_repair_deps.xml`
- `322-legal_warranty_repair_du.xml` → `322-dr_warranty_repair_du.xml`
- `323-legal_warranty_repair_case_one.xml` → `323-dr_warranty_repair_case_one.xml`

Entity (имена классов, пакет и имена Jmix `legal_WarrantyRepair*` не менялись):
`LegalWarrantyRepair.java`, `LegalWarrantyRepairDeps.java`,
`LegalWarrantyRepairDu.java`, `LegalWarrantyRepairCaseOne.java`.

Существенные решения (перенесены из итерации 1, не пересматривались):

- Имена констант БД в верхнем регистре переименованы вместе с таблицами:
  `PK_/IDX_/UQ_/FK_LEGAL_WARRANTY_REPAIR*` → `*_DR_WARRANTY_REPAIR*`
  (в changelog-ах, `@Table(indexes = …)` и `@DdlGeneration(unmappedConstraints
  = …)`). Постановка называет только `IDX_…WAG_DEFECT` и `UQ_…DEPS_CLAIM`,
  остальные переименованы для единообразия.
- Индекс `(wagnum, defect_date)` сделан уникальным одновременно в changelog
  (`unique="true"`) и в entity (`@Index(… unique = true)`).
- `LegalWarrantyRepairRole` не изменялся: во всех `@EntityAttributePolicy`
  уже стоит `attributes = "*"`, перечислений атрибутов нет. Файл в стеше не
  отличается от текущего — переносить было нечего.
- `next_repair_vrp_name` → `last_repair_depo_name` — как указано в постановке.
- `rebill_calc_by` / `rebill_calc_date` оставлены как есть.

## Предварительные проверки

Все команды выполнены в этой сессии на ветке `feature/caseone-table`
(мерж-коммит `f2b96adc2`), БД — `docker-rvk-db-1` (PostgreSQL 16.11) на
`localhost:5432`.

| Команда или сценарий | Результат |
|---|---|
| `./gradlew :app:compileJava` | BUILD SUCCESSFUL |
| `./gradlew spotlessCheckAll` | BUILD SUCCESSFUL |
| C1 — `grep -rni 'legal_warranty_repair' app/src` | вхождений нет |
| C1 — `grep -rn 'LEGAL_WARRANTY_REPAIR' app/src` | вхождений нет |
| C2 — `checks/verify.py` | OK: старых имён в области таска нет; новые есть в changelog + entity + i18n. 49 / 76 / 34 / 16 колонок, столько же `@Column`/`@JoinColumn` в entity |
| C3 — Liquibase с нуля (таблицы и строки `databasechangelog` предварительно удалены), состав в БД | 4 таблицы созданы; 49 + 76 + 34 + 16 = **175** колонок; таблиц `legal_warranty_repair*` в схеме `main` не осталось |
| C4 — имена entity ↔ changelog (`checks/verify.py`) | OK, 175 из 175 |
| C4 — типы entity ↔ фактическая БД (`checks/typecheck.py`) | OK, 175 из 175 по типу, длине, precision/scale |
| C5 — индексы в БД | `idx_dr_warranty_repair_wag_defect` UNIQUE; `uq_dr_warranty_repair_deps_claim` UNIQUE … `WHERE (deleted_date IS NULL)`; также `uq_dr_warranty_repair_du_deps`, `uq_dr_warranty_repair_case_one_deps` |
| C6 — i18n (`checks/verify.py`) | OK: осиротевших ключей нет, полей без ключа нет; 207 ключей до и после |
| Гейт 1 (статика) | `compileJava` + `spotlessCheckAll`; инспекция IDE не выполнялась — MCP IDE в сессии не подключён, новых `*-view.xml` в таске нет |
| Гейт 2 — `./gradlew :app:test` | 1278 тестов: **1265 passing, 12 pending, 1 failing**. Контекст Spring/Jmix поднимается. Единственный отказ — `SsoOidcUserMapperConcurrencyIT`, к таску не относится |
| Гейт 2 — базовая линия того же теста без изменений T01 (`git stash push` по путям таска, прогон только этого теста, затем `git stash pop`) | тот же `OptimisticLockException`, отказ воспроизводится без T01 |
| Гейт 3 | не применим, views в таске не создаются |

Скрипты проверок — рядом с таском, в `checks/`: `maps.py` (таблицы
переименований), `verify.py` (C1, C2, C4 по именам, C6), `typecheck.py`
(C4 по типам фактической БД). Запуск — из каталога `checks/`; для
`typecheck.py` предварительно нужен дамп колонок, путь к нему задан в скрипте
константой (в этой сессии поправлен на текущий scratchpad — перед прогоном
поправить под свой):

```bash
docker exec docker-rvk-db-1 psql -U root -d postgres -At -F'|' -c "
  select table_name, column_name, data_type,
         coalesce(character_maximum_length,-1),
         coalesce(numeric_precision,-1), coalesce(numeric_scale,-1)
  from information_schema.columns
  where table_schema='main' and table_name like 'dr_warranty_repair%'
  order by table_name, ordinal_position;" > <путь>/dbcols.txt
```

## Для независимой проверки

Инфраструктура. Порт 5432 может занимать посторонний контейнер
`freight-postgres` (другой проект) — в этой сессии он уже остановлен, и
`docker-rvk-db-1` слушает 5432. Если порт снова занят, повторить
`docker stop freight-postgres`.

```bash
git checkout feature/caseone-table            # ожидается HEAD f2b96adc2 «step 1»
docker info
(cd docker && docker compose up -d rvk-db)
docker port docker-rvk-db-1                   # ожидается 5432/tcp -> 0.0.0.0:5432
./gradlew :app:compileJava
./gradlew spotlessCheckAll
./gradlew :app:test
```

Файл `app/src/test/resources/application-test-local.properties` должен
существовать и указывать на `jdbc:postgresql://localhost:5432/postgres?currentSchema=main`
(в этой сессии — так).

Статические критерии целиком:

```bash
grep -rni 'legal_warranty_repair' app/src     # ожидается пусто
cd specs/work/dr-warranty-repair-rename-ui/tasks/T01/checks && python3 verify.py
```

C3 и C5 по БД:

```bash
docker exec docker-rvk-db-1 psql -U root -d postgres -c "
  select table_name, count(*) from information_schema.columns
  where table_schema='main' and table_name like '%warranty_repair%'
  group by table_name order by 1;"

docker exec docker-rvk-db-1 psql -U root -d postgres -c "
  select indexname, indexdef from pg_indexes
  where schemaname='main' and tablename like 'dr_warranty_repair%'
  order by tablename, indexname;"
```

Повторное применение Liquibase с нуля (перед прогоном тестов):

```bash
docker exec docker-rvk-db-1 psql -U root -d postgres -c "
  drop table if exists main.dr_warranty_repair_case_one, main.dr_warranty_repair_du,
    main.dr_warranty_repair_deps, main.dr_warranty_repair,
    main.legal_warranty_repair_case_one, main.legal_warranty_repair_du,
    main.legal_warranty_repair_deps, main.legal_warranty_repair cascade;
  delete from main.databasechangelog where filename like '%warranty_repair%';"
```

затем `./gradlew :app:test` (или любой интеграционный тест) — Liquibase
создаст таблицы заново.

Секретов и учётных данных здесь нет: `root/root` — креденшелы локального
контейнера из `docker/docker-compose.yml`.

## Ограничения и связанные изменения

- **Гейт 2 красный на одном тесте, не связанном с таском.**
  `ru.fgk.ws.app.sso.SsoOidcUserMapperConcurrencyIT.concurrentLoginsOfTheSameUserDoNotFail`
  падает с `OptimisticLockException` на `ru.fgk.sso.entity.User` в
  `SynchronizingOidcUserMapper` (`io.jmix.oidc`) — гонка при конкурентной
  синхронизации пользователя OIDC. Отказ воспроизводим (три прогона подряд),
  воспроизведён **без изменений T01** на базовой линии, и тест добавлен самой
  веткой (коммит `dd71c094f`), в `main` его нет. Исправление — правка
  production-кода SSO, вне постановки T01. Вынесено в
  [Q03](../../questions/Q03.md) как решение по формулировке гейта 2 для всех
  тасков работы; T01 оно не блокирует.
- **Расхождение в числах постановки.** Критерий C3 и план говорят о 197
  колонках; фактически в четырёх `createTable` — 175 (49 + 76 + 34 + 16), и
  столько же в БД и в entity. Ни одна колонка не добавлена и не удалена, так
  что 175 = 175; цифра 197 в плане и таске неверна. То же с числом i18n-ключей:
  в плане 234, фактически 207. Постановку не правил — это решение архитектора.
- **Область проверки C2 сужена** до артефактов гарантийных ремонтов (четыре
  changelog-а, пакет `ru.fgk.ws.app.legal.warrantyrepair`, блок ключей
  `…warrantyrepair…`). Буквальный поиск старых имён по всему `app/src` даёт
  ложные срабатывания: `damage_name`, `next_repair_date`, `next_repair_type`,
  `vrk` и т. п. законно живут в других фичах (`da`, `wagons`, `repair`,
  `asuvrk`, `dr`) и к этой работе отношения не имеют.
- **`specs/dr-warranty-repair/04-new-model.md` устарел** — он выгружен из
  старых changelog-ов и описывает `legal_warranty_repair*` со старыми
  колонками. План это предусматривал («устареет после T01»); обновление в T01
  не входило.
- **Изменения не закоммичены.** В рабочем дереве также лежат посторонние
  правки `.idea/encodings.xml` и неотслеживаемые каталоги инструментов
  (`.agents/`, `.claude/`, `.playwright-cli/`) — к таску не относятся, не тронуты.
- Изменения затрагивают структуру, от которой зависят T02–T06 и T08; их
  проверенных доказательств пока нет (все `todo`/`blocked`), снимать нечего.
  T02 остаётся `blocked` до `done` у T01 и T08.
