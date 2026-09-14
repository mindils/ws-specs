# T01 — Переименование модели в `legal_tech_claim*`

Статус: done
План: [plan.md](../../plan.md)
Зависимости: нет
Сложность: medium — механическое, но сквозное переименование по ~40 файлам
всех слоёв; контракты не меняются, образец есть (T01 прежней работы)
Сложность проверки: medium — полный `:app:test`, пересоздание БД, сверка
имён скриптом; браузер не нужен
Актуальная проверка: [checks/002.md](checks/002.md)

## Коротко

Раздел претензий по технологическим неисправностям сейчас называется в коде
«гарантийные ремонты» (`warranty_repair`), а таблицы носят префикс `dr_`.
Пользователь выбрал имя `legal_tech_claim`. Таск переименовывает таблицы,
view, пакет, классы, Jmix-имена, роли, ключи i18n и тесты на месте, не меняя
ни одной колонки и ни одного алгоритма. По результату база пересоздаётся с
нуля с новыми именами и весь набор тестов остаётся зелёным.

## Результат и контекст

Текущее состояние (не закоммичено, ветка `feature/caseone-table`):

- пакет `ru.fgk.ws.app.legal.warrantyrepair` — `entity/` (4 entity, 7 enum,
  `VWarrantyRepairClaim`, `WarrantyRepairDeadline`, `ClaimTermOverdueLevelEnum`),
  `service/` (12 классов расчёта и пересчёта), `security/LegalWarrantyRepairRole`;
- changelog-и `01-tbl/320-dr_warranty_repair.xml`, `321-…_deps.xml`,
  `322-…_du.xml`, `323-…_case_one.xml`, `324-dr_warranty_repair_deadlines.xml`;
  `02_view/independent/dr_v_warranty_repair_claim.xml`;
- тесты `app/src/test/java/ru/fgk/ws/app/legal/warrantyrepair/service/ClaimTermCalculatorTest.java`,
  `app/src/test/java/ru/fgk/ws/app/it/WarrantyRepairDeadlineIT.java`,
  `…/it/WarrantyRepairClaimViewIT.java`;
- ключи `messages_ru.properties` вида `ru.fgk.ws.app.legal.warrantyrepair/LegalWarrantyRepair.wagnum=…`
  (≈250 ключей раздела);
- документ отличий [calendar-behavior-differences.md](../../input/calendar-behavior-differences.md)
  с картой кода по старым именам.

Целевые имена — таблица «Общие решения» плана, строка «Базовое имя». Сводка:

| Было | Стало |
|---|---|
| `dr_warranty_repair` / `LegalWarrantyRepair` / `legal_WarrantyRepair` | `legal_tech_claim` / `LegalTechClaim` / `legal_TechClaim` |
| `dr_warranty_repair_deps` / `LegalWarrantyRepairDeps` | `legal_tech_claim_deps` / `LegalTechClaimDeps` / `legal_TechClaimDeps` |
| `dr_warranty_repair_du` / `LegalWarrantyRepairDu` | `legal_tech_claim_du` / `LegalTechClaimDu` / `legal_TechClaimDu` |
| `dr_warranty_repair_case_one` / `LegalWarrantyRepairCaseOne` | `legal_tech_claim_case_one` / `LegalTechClaimCaseOne` / `legal_TechClaimCaseOne` |
| `dr_warranty_repair_deadlines` / `WarrantyRepairDeadline` / `legal_WarrantyRepairDeadline` | `legal_tech_claim_deadlines` / `LegalTechClaimDeadline` / `legal_TechClaimDeadline` |
| `dr_v_warranty_repair_claim` / `VWarrantyRepairClaim` / `legal_VWarrantyRepairClaim` | `legal_v_tech_claim` / `VLegalTechClaim` / `legal_VTechClaim` |
| `Warranty*Enum` (7 шт.: RepairType, PlanRepairType, ClaimResult, ReclamationResult, BranchReviewResult, ReimbursementBasis, CaseOneStatus) | `TechClaim*Enum` с тем же хвостом |
| `WarrantyRepairDeadlineService` / `…RecalculationListener` / `…PublicationHandler` | `TechClaimDeadlineService` / `TechClaimDeadlineRecalculationListener` / `TechClaimDeadlinePublicationHandler` |
| `LegalWarrantyRepairRole` (`legal-warranty-repair`) | `LegalTechClaimAdminRole` (`legal-tech-claim-admin`); состав политик не меняется |
| Файлы changelog `320…324-dr_warranty_repair*.xml` | `320…324-legal_tech_claim*.xml` (тот же номер) |
| `02_view/independent/dr_v_warranty_repair_claim.xml` | `02_view/independent/legal_v_tech_claim.xml`, `author="legal"` |
| Константы `PK_/IDX_/UQ_/FK_DR_WARRANTY_REPAIR*` | `PK_/IDX_/UQ_/FK_LEGAL_TECH_CLAIM*` |
| Тесты `WarrantyRepairDeadlineIT`, `WarrantyRepairClaimViewIT` | `TechClaimDeadlineIT`, `TechClaimViewIT` |

**Не меняются:** имена колонок (в т. ч. `warranty_repair`, `warranty_*`
виновника, `warranty_repair_cost`), типы, состав; классы `ClaimTerm*`,
`ClaimTermOverdueLevelEnum`; всё в пакете `nsi`; `legal_caseone_*`;
`WarrantyRepairEnum` из `dr`; алгоритмы и тексты сообщений.

## Область и изоляция

Меняет: пакет `legal/warrantyrepair` → `legal/techclaim` (Java и ресурсы),
changelog-и выше, три тестовых класса, блок ключей раздела в
`app/src/main/resources/ru/fgk/ws/app/messages_ru.properties`, разделы
«Реализация календаря» и «Расчёт сроков» в документе отличий (карта кода).
Не трогать: `nsi/**`, `legal/caseone/**`, `sso-plagin`. Дополнительно
разрешено (решение [Q02](../../questions/Q02.md)) удалить отложенный тест
`app/src/test/java/ru/fgk/ws/app/sso/SsoOidcUserMapperConcurrencyIT.java`.

Общие ресурсы: локальная БД `docker-rvk-db-1` (пересоздание таблиц раздела),
Gradle daemon. Параллельно ни с чем: все остальные таски ждут `done`.

## Реализация

1. Перед началом убедиться, что базовая линия закоммичена (см. план);
   если нет — сообщить пользователю и продолжать, переименовывая через
   `git mv`, чтобы сохранить историю.
2. Переименовать каталоги и файлы (`git mv`), затем содержимое: аннотации
   `@Table`, `@Entity`, `@JmixEntity`, `@Index`, `@DdlGeneration`,
   `@JoinColumn` не трогать (колонки те же), `@ResourceRole(code=…)`,
   импорты, javadoc. Проверять `grep -rn "WarrantyRepair\|warrantyrepair\|warranty_repair" app/src`
   с фильтрацией допустимых остатков (см. критерий C1).
3. Changelog-и: переписать `tableName`, имена индексов/PK/UQ и файлов;
   preConditions оставить; в view-changelog заменить имена таблиц в SQL и
   `COMMENT ON`; `dropView ifExists` на новое имя.
4. i18n: ключи `ru.fgk.ws.app.legal.warrantyrepair/…` → `ru.fgk.ws.app.legal.techclaim/…`,
   имена сущностей/enum в ключах — по новым классам. Число ключей до и после
   одинаково. Скил `jmix-add-i18n-keys`.
5. Тесты: переименовать классы и ссылки; SQL-фикстуры в IT — на новые
   таблицы.
6. Документ отличий: обновить карту кода (таблицы «Схема и код», «Где что
   лежит») и упоминания таблиц; добавить строку о переименовании 2026-09-14.
7. Локальную БД пересоздать: `drop table if exists main.dr_warranty_repair_deadlines,
   main.dr_warranty_repair_case_one, main.dr_warranty_repair_du,
   main.dr_warranty_repair_deps, main.dr_warranty_repair cascade; drop view if
   exists main.dr_v_warranty_repair_claim; delete from main.databasechangelog
   where filename like '%warranty_repair%';` Затем любой IT применит Liquibase.
8. `./gradlew spotlessApply`.

Образец полного прохода — `../../../dr-warranty-repair-rename-ui/tasks/T01/`
(там же скрипты `checks/verify.py`, `typecheck.py`, которые можно адаптировать).

## Критерии приёмки

- C1: `grep -rniE "warranty_?repair|warrantyrepair" app/src` находит только
  допустимые остатки: колонки `warranty_repair`, `warranty_repair_cost`,
  `warranty_is_vrp/depo_code/railway_code/type/name/note` и их Java-поля,
  enum `ru.fgk.ws.app.dr.entity.WarrantyRepairEnum` и ссылки на него,
  тексты сообщений. Ни одного имени таблицы, класса, пакета, Jmix-имени,
  константы БД, файла или ключа i18n со старым именем.
- C2: в БД после применения Liquibase с нуля есть `legal_tech_claim` (49),
  `_deps` (76), `_du` (34), `_case_one` (16), `_deadlines` (37) колонок и view
  `legal_v_tech_claim` (104 колонки); таблиц/view `dr_warranty_repair*` нет.
- C3: индексы `idx_legal_tech_claim_wag_defect` (UNIQUE),
  `uq_legal_tech_claim_deps_claim` (частичный UNIQUE `WHERE deleted_date IS NULL`),
  `uq_legal_tech_claim_du_deps`, `uq_legal_tech_claim_case_one_deps`,
  `uq_legal_tech_claim_deadlines_deps`, `idx_legal_tech_claim_deadlines_revision`
  созданы.
- C4: число ключей i18n раздела до и после равно; осиротевших ключей и полей
  без ключа нет.
- C5: `./gradlew :app:test` — `0 failing`; переименованные тесты выполняются
  (не пропали из прогона). Тест `SsoOidcUserMapperConcurrencyIT` из прогона
  убран вместе с отложенным кодом OIDC ([Q02](../../questions/Q02.md)).
- C6: документ отличий ссылается на новые имена; поиск `dr_warranty_repair`
  и `WarrantyRepairDeadline` по `input/calendar-behavior-differences.md`
  ничего не находит.

## Самопроверка исполнителя

```bash
./gradlew :app:compileJava
./gradlew spotlessApply spotlessCheckAll
grep -rniE "warranty_?repair|warrantyrepair" app/src | grep -viE "warranty_repair_cost|warrantyRepairCost|warranty_(is_vrp|depo_code|railway_code|type|name|note)|warranty(IsVrp|DepoCode|RailwayCode|Type|Name|Note)|dr\.entity\.WarrantyRepairEnum|WarrantyRepairEnum|\"warranty_repair\"|warrantyRepair;|getWarrantyRepair|setWarrantyRepair"
./gradlew :app:test --tests "ru.fgk.ws.app.legal.techclaim.*" --tests "ru.fgk.ws.app.it.TechClaimDeadlineIT" --tests "ru.fgk.ws.app.it.TechClaimViewIT"
```

Плюс пересоздание БД по п. 7 и один запрос числа колонок. Полный
`:app:test` — проверяющему. Точные команды и остаток grep записать в
`result.md`.

## Независимая проверка

```bash
docker info && (cd docker && docker compose up -d)
# пересоздать таблицы раздела (п. 7 реализации), затем:
./gradlew :app:compileJava spotlessCheckAll
./gradlew :app:test                         # C5: 0 failing
docker exec docker-rvk-db-1 psql -U root -d postgres -c "select table_name, count(*) from information_schema.columns where table_schema='main' and table_name like 'legal_tech_claim%' or table_name='legal_v_tech_claim' group by 1 order by 1;"
docker exec docker-rvk-db-1 psql -U root -d postgres -c "select indexname from pg_indexes where schemaname='main' and tablename like 'legal_tech_claim%' order by 1;"
docker exec docker-rvk-db-1 psql -U root -d postgres -c "select count(*) from information_schema.tables where table_schema='main' and table_name like '%warranty_repair%';"   # 0
```

C1 — grep из самопроверки, разобрать каждый остаток. C4 — сверка ключей
скриптом по образцу `verify.py` прежней работы. C6 — grep по документу.
Регрессия: тесты `nsi` (`WorkCalendarReferenceDataIT`, `NsiClaimTermEditRoleIT`)
зелёные, публикация ревизии по-прежнему вызывает обработчик пересчёта
(тест `TechClaimDeadlineIT` о публикации).

## Прогресс и продолжение

- [x] Восстановить исходное состояние раздела из `stash@{1}` (см. ниже).
- [x] Переименовать каталоги, файлы и классы (`git mv`), обновить ссылки.
- [x] Changelog-и таблиц и view, константы БД.
- [x] i18n-ключи и тесты.
- [x] Документ отличий.
- [x] Пересоздать БД, пройти самопроверку, записать `result.md`.
- [x] Передать результат на независимую проверку (итерация 1, отчёт
      [checks/001.md](checks/001.md) — `fail` по C5).
- [x] Исправление [F01](fixes/F01.md): отложенный тест
      `SsoOidcUserMapperConcurrencyIT` снят, `./gradlew :app:test` —
      0 failing; передана итерация 2.
- [x] Повторная независимая проверка: отчёт [checks/002.md](checks/002.md) —
      `pass` по всем критериям C1–C6. Таск завершён.

Ближайший шаг: переход к волне 2 плана — таски [T02](../T02/task.md) и
[T03](../T03/task.md).
Препятствия: нет.

### Восстановление базовой линии перед переименованием

Рабочее дерево на старте было рассогласовано: новые файлы раздела (сроки,
НСИ, view, тесты) лежали на месте, а правки уже закоммиченных файлов
отсутствовали, поэтому entity указывали на устаревшие таблицы
`legal_warranty_repair*` со старыми именами колонок. Причина — `git stash`
перед слиянием `main` без последующего `git stash pop` (`stash@{1}`,
2026-09-14 09:52). Относящаяся к T01 часть stash восстановлена
`git apply --3way`: четыре entity, роль, `menu.xml`,
`messages_ru.properties` и удаление устаревших changelog-ов
`320…323-legal_warranty_repair*.xml`; правки `main`, пришедшие слиянием,
сохранены. Stash не изменялся и не удалялся. Остаток stash вне области
таска не восстанавливается — [Q02](../../questions/Q02.md).
