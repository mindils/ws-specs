# T01 — Переименование таблиц и колонок гарантийных ремонтов

Статус: done
План: ../../plan.md
Зависимости: нет
Результат: [result.md](result.md), итерация 2
Актуальная проверка: [checks/002.md](checks/002.md)
Связанные вопросы: [Q02](../../questions/Q02.md) — resolved, гейт 2 разблокирован после слияния с main;
[Q03](../../questions/Q03.md) — resolved, красный `SsoOidcUserMapperConcurrencyIT` отнесён к новому таску
[T09](../T09/task.md) и для T01 отказом не считается

## Результат и контекст

Структура из 4 таблиц реализована в ветке `f/caseone-task` (коммит
`a72fc2ba3 «сделал структуру»`, в `main` не влит). Пользователь пересмотрел
именование и записал правки в `specs/dr-warranty-repair/09-update.md`:
зачёркнуто старое имя, жирным — новое.

Нужно применить эти переименования к таблицам, колонкам, полям entity,
i18n-ключам и changelog-ам.

**Что НЕ меняется:** пакет `ru.fgk.ws.app.legal.warrantyrepair`, имена
классов `LegalWarrantyRepair*`, имена сущностей Jmix `legal_WarrantyRepair*`,
типы колонок, состав колонок. Ни одна колонка не удаляется и не добавляется
(было 197 суммарно — должно остаться 197).

**`09-update.md` читать осторожно:** он сделан на основе черновика
`04-new-model.md`, а не реализованной модели. Полный перечень расхождений —
в разделе «Материалы» плана. Из него берутся **только** пары
«зачёркнутое → новое». Таблицы ниже уже сверены с реальными entity —
работать по ним, а не по 09 напрямую.

## Реализация

Ветка: `git checkout feature/caseone-table` (слияние с `main` выполнено).

Файлы:

- `app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/01-tbl/320-legal_warranty_repair.xml` → `320-dr_warranty_repair.xml`
- `…/321-legal_warranty_repair_deps.xml` → `321-dr_warranty_repair_deps.xml`
- `…/322-legal_warranty_repair_du.xml` → `322-dr_warranty_repair_du.xml`
- `…/323-legal_warranty_repair_case_one.xml` → `323-dr_warranty_repair_case_one.xml`
- `app/src/main/java/ru/fgk/ws/app/legal/warrantyrepair/entity/LegalWarrantyRepair.java`
- `…/entity/LegalWarrantyRepairDeps.java`
- `…/entity/LegalWarrantyRepairDu.java`
- `…/entity/LegalWarrantyRepairCaseOne.java`
- `…/security/LegalWarrantyRepairRole.java`
- `app/src/main/resources/ru/fgk/ws/app/messages_ru.properties`

Корневой changelog подхватывает `01-tbl/` через `includeAll` — регистрировать
новые имена файлов не нужно. `createTable` переписывается на месте (новые
имена сразу), `renameTable`/`renameColumn` **не добавляем**: changeset-ы
нигде, кроме локальной БД, не применялись. Локальную БД перед проверкой
пересоздать: `drop table if exists main.legal_warranty_repair, main.legal_warranty_repair_deps, main.legal_warranty_repair_du, main.legal_warranty_repair_case_one cascade;` плюс удалить их строки из `databasechangelog`.

Скил: `jmix-create-liquibase-changelog` (preConditions обязательны,
`objectQuotingStrategy="QUOTE_ONLY_RESERVED_WORDS"`, `<addForeignKeyConstraint>`
запрещён, индексы `idx_<table>_<column>`).

### 1. `legal_warranty_repair` → `dr_warranty_repair`

| Колонка: было | Стало | Java-поле |
|---|---|---|
| `operation_type` | `category_oper` | `operationType` → `categoryOper` |
| `acquisition_date` | `own_start` | `acquisitionDate` → `ownStart` |
| `vrp_code` | `depo_code` | `vrpCode` → `depoCode` |
| `vrp_name` | `depo_name` | `vrpName` → `depoName` |
| `vrk` | `vrk_code` | `vrk` → `vrkCode` |
| `damage_code_1` | `defect_code_1` | `damageCode1` → `defectCode1` |
| `damage_code_2` | `defect_code_2` | `damageCode2` → `defectCode2` |
| `damage_code_3` | `defect_code_3` | `damageCode3` → `defectCode3` |
| `damage_code_tn` | `defect_code_tn` | `damageCodeTn` → `defectCodeTn` |
| `damage_name` | `defect_name` | `damageName` → `defectName` |
| `damage_note` | `defect_note` | `damageNote` → `defectNote` |
| `repair_accept_date` | `repair_arrival_date` | `repairAcceptDate` → `repairArrivalDate` |
| `inventory_date` | `insert_vagtk_date` | `inventoryDate` → `insertVagtkDate` |
| `repair_depo_per_act` | `depo_act_code` | `repairDepoPerAct` → `depoActCode` |
| `next_repair_date` | `last_repair_date` | `nextRepairDate` → `lastRepairDate` |
| `next_repair_type` | `last_repair_type` | `nextRepairType` → `lastRepairType` |
| `next_repair_vrp` | `last_repair_depo` | `nextRepairVrp` → `lastRepairDepo` |
| `next_repair_vrp_name` | `last_repair_depo_name` | `nextRepairVrpName` → `lastRepairDepoName` |
| `next_repair_vrk` | `last_repair_vrk` | `nextRepairVrk` → `lastRepairVrk` |
| `plan_repair_contract_num` | `last_repair_contract_num` | `planRepairContractNum` → `lastRepairContractNum` |
| `plan_repair_contract_date` | `last_repair_contract_date` | `planRepairContractDate` → `lastRepairContractDate` |
| `last_tr_damage_code` | `last_tr_defect_code` | `lastTrDamageCode` → `lastTrDefectCode` |

`next_repair_vrp_name` → `last_repair_depo_name` в 09 отсутствует —
переименовано по той же логике, что и соседние `next_repair_*`.

Без изменений: `repair_uid`, `wagnum`, `defect_date`, `railway_code`,
`railway_mnkd`, `is_cis_railway`, `repair_date`, `repair_type`,
`mileage_at_defect`, `wagon_model`, `build_date`, `uncoupling_tr_count`,
`guarantee_kp_count`, `last_tr_date`, `last_tr_depo`, `last_tr_depo_name`,
`last_tr_vrk`, `last_tr_railway_mnkd`, `last_tr_type`, `last_tr_mileage`,
`lease_contract_num`, `lease_contractor_name`, `warranty_repair`, аудит.

Дополнительно:

- Аксессоры enum: `getNextRepairType()`/`setNextRepairType(WarrantyPlanRepairTypeEnum)`
  → `getLastRepairType()`/`setLastRepairType(...)`. Класс enum
  `WarrantyPlanRepairTypeEnum` не переименовывается.
- Индекс `IDX_LEGAL_WARRANTY_REPAIR_WAG_DEFECT` → `IDX_DR_WARRANTY_REPAIR_WAG_DEFECT`
  и сделать его **уникальным** (`@Index(unique = true)` + `unique="true"` в
  changelog): по ответу на вопрос 2 в `06-open-questions.md` пара
  «вагон + дата браковки» уникальна.

### 2. `legal_warranty_repair_deps` → `dr_warranty_repair_deps`

| Колонка: было | Стало | Java-поле |
|---|---|---|
| `at_fault_is_vrp` | `warranty_is_vrp` | `atFaultIsVrp` → `warrantyIsVrp` |
| `at_fault_vrp_code` | `warranty_depo_code` | `atFaultVrpCode` → `warrantyDepoCode` |
| `at_fault_railway_code` | `warranty_railway_code` | `atFaultRailwayCode` → `warrantyRailwayCode` |
| `at_fault_type` | `warranty_type` | `atFaultType` → `warrantyType` |
| `at_fault_name` | `warranty_name` | `atFaultName` → `warrantyName` |
| `at_fault_note` | `warranty_note` | `atFaultNote` → `warrantyNote` |
| `dislocation_in_waybill_num` | `invoice_for_repair_num` | `dislocationInWaybillNum` → `invoiceForRepairNum` |
| `dislocation_in_debit_date` | `invoice_for_repair_date_debit` | `dislocationInDebitDate` → `invoiceForRepairDateDebit` |
| `dislocation_in_amount` | `invoice_for_repair_cost` | `dislocationInAmount` → `invoiceForRepairCost` |
| `dislocation_out_waybill_num` | `invoice_after_repair_num` | `dislocationOutWaybillNum` → `invoiceAfterRepairNum` |
| `dislocation_out_debit_date` | `invoice_after_repair_date_debit` | `dislocationOutDebitDate` → `invoiceAfterRepairDateDebit` |
| `dislocation_out_amount` | `invoice_after_repair_cost` | `dislocationOutAmount` → `invoiceAfterRepairCost` |
| `broken_tariff_waybill_num` | `broken_tariff_invoice_num` | `brokenTariffWaybillNum` → `brokenTariffInvoiceNum` |
| `broken_tariff_amount` | `broken_tariff_cost` | `brokenTariffAmount` → `brokenTariffCost` |
| `reimbursable_repair_cost` | `warranty_repair_cost` | `reimbursableRepairCost` → `warrantyRepairCost` |
| `rebill_calc_amount` | `calculated_invoice_cost` | `rebillCalcAmount` → `calculatedInvoiceCost` |
| `pre_claim_amount` | `pre_claim_cost` | `preClaimAmount` → `preClaimCost` |

`broken_tariff_amount` и `pre_claim_amount` в 09 не зачёркнуты, но общее
правило «денежные колонки → `*_cost`» согласовано пользователем.

`rebill_calc_by` / `rebill_calc_date` (аудит расчёта перевыставления) —
**не переименовывать**: они не денежные, префикс `rebill_calc_` остаётся.

Без изменений: `id`, `repair_uid` (FK), `claim_index`, `src_id_zap`,
`subject_to_claim`, `telegram_number/_send_date/_received_by/_receive_date`,
`reclamation_check_date`, `reclamation_result`, `reclamation_reject_reason`,
`reclamation_note`, `vu41_number`, `vu41_date`, `doc_package_ready_date`,
`doc_transfer_to`, `doc_transfer_date`, `pre_claim_department`,
`pre_claim_transfer_date`, `tariff_rebill_subject`,
`tariff_rebill_transfer_date`, `tariff_rebill_total`, `claim_transfer_date`,
`claim_contractor_guid/_name/_inn`, `claim_contract_num`, `claim_contract_date`,
`downtime_days`, `downtime_penalty_per_day`, `broken_tariff_debit_date`,
`rework_return_date`, `rework_return_rk_number`, `pre_claim_number`,
`pre_claim_date`, `pre_claim_send_date`, `pre_claim_result`,
`pre_claim_reply_number`, `pre_claim_reply_date`, `psr_number`,
`psr_material_number`, `psr_material_date`, `law_registry_num/_date/_by/_sys_date`,
`agent_sng_percent`, `agent_sng_cost`, `repair_block_modified_by/_date`,
аудит, `deleted_by`, `deleted_date`.

`psr_number` (`DoPret_PassPP_Name`) и `psr_material_number`/`_date`
(`PSRMatNom`/`PSRMatDate`) — **разные колонки**, обе остаются: ответ
пользователя на вопрос 3 в `06-open-questions.md`.

Частичный уникальный индекс `UQ_LEGAL_WARRANTY_REPAIR_DEPS_CLAIM`
(`(repair_uid, claim_index) WHERE deleted_date IS NULL`, отдельный
`<sql>`-changeSet) → `UQ_DR_WARRANTY_REPAIR_DEPS_CLAIM`.

### 3. `legal_warranty_repair_du` → `dr_warranty_repair_du`

| Колонка: было | Стало | Java-поле |
|---|---|---|
| `claim_amount` | `claim_cost` | `claimAmount` → `claimCost` |
| `lawsuit_amount` | `lawsuit_cost` | `lawsuitAmount` → `lawsuitCost` |
| `lawsuit_accept_amount` | `lawsuit_accept_cost` | `lawsuitAcceptAmount` → `lawsuitAcceptCost` |
| `at_fault_accepted_amount` | `at_fault_accepted_cost` | `atFaultAcceptedAmount` → `atFaultAcceptedCost` |
| `payment_amount` | `payment_cost` | `paymentAmount` → `paymentCost` |

`claim_amount` → `claim_cost` соответствует паре `~~repair_cost~~ → claim_cost`
из 09 (источник `Stoim`); остальные — по тому же правилу `*_cost`.

Без изменений: `id`, `deps_id`, `rework_return_date`,
`rework_return_rk_number`, `branch_review_result`,
`branch_review_reject_reason`, `claim_number`, `claim_date`,
`claim_send_date`, `claim_result`, `at_fault_receive_date`,
`at_fault_reply_date`, `at_fault_reply_number`, `claim_reject_reason`,
`to_law_date`, `payment_date`, `payment_number`, `reimbursement_basis`,
`payment_note`, `lawsuit_number`, `lawsuit_date`, `case_number`,
`lawsuit_result`, `lawsuit_modified_by`, `lawsuit_modified_date`, аудит.

**Не применять** раскладку 09 для `Gar_Prich`/`Prich_Otkl`: в 09 они
называются `at_fault_review_note` / `claim_reject_reason` и разложены иначе.
Это старый черновик, исправленный в `08-status-and-next-steps.md`. Остаётся
как реализовано: `du.claim_reject_reason` = `Gar_Prich`,
`deps.reclamation_reject_reason` = `Prich_Otkl`.

### 4. `legal_warranty_repair_case_one` → `dr_warranty_repair_case_one`

Меняется только имя таблицы. Колонки (`case_one_status`, `card_guid`,
`card_url`, `assignee_guid`, `assignee_name`, `folder_guid`, `folder_name`,
`sent_date`, `fields_modified_date`, `error_text`, аудит) остаются как есть —
префикс `case_one_` из 09 не применяем, имя таблицы его уже несёт.

### 5. i18n и роль

Ключи в `messages_ru.properties` завязаны на имена Java-полей, например
`ru.fgk.ws.app.legal.warrantyrepair/LegalWarrantyRepair.vrpCode=…` —
переименовать вместе с полями. Ключи сущностей и enum-ов не меняются
(классы не переименовываются). Скил `jmix-add-i18n-keys`.

В `LegalWarrantyRepairRole` проверить, что в `@EntityAttributePolicy`
используются `*`, а не перечисления атрибутов; если перечисления есть —
обновить. Роль пока одна; разделение на ДЭПС/ДЮ — в T03.

## Критерии приёмки

- C1: `grep -rn 'legal_warranty_repair' app/src` не находит ничего
  (имена сущностей Jmix `legal_WarrantyRepair*` — с заглавными, под шаблон
  не попадают).
- C2: ни одно старое имя колонки/поля из таблиц выше не встречается в
  `app/src`; каждое новое имя встречается и в changelog, и в entity, и в
  ключе `messages_ru.properties`.
- C3: после пересоздания БД liquibase применяется с нуля без ошибок, созданы
  4 таблицы `dr_warranty_repair*`; суммарное число колонок — 197.
- C4: сверка entity ↔ changelog: имя и тип каждой колонки совпадают, лишних
  и недостающих нет ни с одной стороны.
- C5: индекс по `(wagnum, defect_date)` создан уникальным; частичный
  уникальный индекс претензии сохранился под новым именем.
- C6: в `messages_ru.properties` нет осиротевших ключей
  `…warrantyrepair/…` и нет полей entity без ключа.

## Проверка

Инфраструктура: `docker info`; `(cd docker && docker compose ps)`;
`(cd docker && docker compose up -d)`. Порт 5432 может быть занят посторонним
контейнером (проверялось при планировании — висел `freight-postgres` чужого
проекта): убедиться, что поднялся `rvk-db` этого compose и что
`app/src/test/resources/application-test-local.properties` указывает на него.
Если `./gradlew` не тянет дистрибутив с `repo.main.vgk` —
`(cd system && ./change-gradle-to-remote-repo.sh)`, затем `./gradlew --version`.

```bash
git checkout f/caseone-task
# пересоздать таблицы задачи в локальной БД перед прогоном
./gradlew :app:compileJava
./gradlew spotlessApply spotlessCheckAll
./gradlew :app:test
```

Гейт 1 (статика): инспекция IDE (`get_file_problems`) по каждому изменённому
файлу; запасное — `compileJava` + скил `jmix-ide-static-analysis`.
Гейт 2: `./gradlew :app:test` — контекст поднимается; единственный допустимый
отказ — `SsoOidcUserMapperConcurrencyIT` (таск [T09](../T09/task.md)), любой
другой отказ считается отказом T01.
Гейт 3 не применим: views в этом таске не создаются.

Проверка колонок в БД:

```sql
select table_name, count(*) from information_schema.columns
where table_schema = 'main' and table_name like 'dr_warranty_repair%'
group by table_name order by 1;
```

Точные использованные команды записать в `result.md`.

## Прогресс и продолжение

- [x] Переключиться на рабочую ветку, поднять Docker, убедиться, что БД проекта доступна.
      Порт 5432 занимал чужой `freight-postgres` — остановлен, `docker-rvk-db-1` пересоздан.
- [x] Переименовать колонки и файлы в четырёх changelog-ах; индекс отцепки сделан уникальным.
- [x] Переименовать поля и аксессоры в четырёх entity.
- [x] Переименовать i18n-ключи; осиротевших нет, полей без ключа нет.
- [x] Завершить слияние `main` в `feature/caseone-table` — мерж-коммит `f2b96adc2 «step 1»`.
- [x] Накатить наработки T01 на объединённую ветку: из `stash@{0}` перенесены
      только файлы таска (4 entity, 4 changelog-а, блок ключей `…warrantyrepair…`
      в `messages_ru.properties`); стеш целиком не применялся — он сделан на старом
      `main` и содержит 329 посторонних файлов.
- [x] Пересоздать таблицы задачи в локальной БД и применить Liquibase с нуля.
- [x] `compileJava` и `spotlessCheckAll` — зелёные.
- [x] Сверить entity ↔ changelog ↔ БД по C1–C6: 175 колонок совпали по имени, типу,
      длине и precision/scale; индексы созданы; i18n без осиротевших ключей.
      Число 197 в критерии C3 неверно — фактически 175 и до, и после.
- [x] Гейт 2: `:app:test` — 1265 passing, 12 pending, 1 failing. Единственный отказ
      (`SsoOidcUserMapperConcurrencyIT`) воспроизведён на базовой линии **без**
      изменений T01 и вынесен в [Q03](../../questions/Q03.md).
- [x] Обновить `result.md` (итерация 2) и передать результат на независимую проверку.

Препятствий нет. Реализация завершена, все критерии C1–C6 подтверждены
собственными проверками; статус `done` ставит только `task-verify`.

Вопрос [Q03](../../questions/Q03.md) закрыт: причина отказа
`SsoOidcUserMapperConcurrencyIT` — неработающая блокировка в `io.jmix.oidc`
(`synchronized` по неинтернированной строке), починка ведётся таском
[T09](../T09/task.md). Для T01 этот отказ не `fail`: он воспроизведён на
базовой линии без изменений таска и критериев C1–C6 не касается.

Изменения **не закоммичены** — проверять по рабочему дереву ветки
`feature/caseone-table` (HEAD `f2b96adc2`).

Следующий шаг: `task-verify` по пути
`specs/work/dr-warranty-repair-rename-ui/tasks/T01/task.md`, итерация 2.
