# Новая модель данных: 4 таблицы + кэш справочников Case.one

Реализовано. Код — `ru.fgk.ws.app.legal.warrantyrepair`, таблицы — `legal_warranty_*`
(префикс `legal_`, как у существующей `legal_caseone_settings`).

Таблицы и колонки в этом файле выгружены **из фактических changelog-ов**
(`app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/01-tbl/32*.xml`,
`tbl-legal_caseone_ref.xml`), поэтому расхождения со схемой быть не может.

## Связи

```
legal_warranty_repair (1) ──< (N) legal_warranty_repair_deps      [repair_uid + claim_index]
legal_warranty_repair_deps (1) ─── (0..1) legal_warranty_repair_du        [deps_id UNIQUE]
legal_warranty_repair_deps (1) ─── (0..1) legal_warranty_repair_case_one  [deps_id UNIQUE]
```

- **`legal_warranty_repair`** — 1 запись = 1 **отцепка** (вагон + дата браковки),
  автозаполнение из ЕО/ВагТК и НСИ. PK `repair_uid` (обычный UUID, генерируется
  при заливке данных — формулы MD5 нет).
- **`legal_warranty_repair_deps`** — 1 запись = 1 **претензия**, поля пользователей
  ДЭПС. PK — суррогатный `id` (bigint identity). Индекс претензии уникален в
  пределах отцепки среди неудалённых строк: частичный уникальный индекс
  `UQ_LEGAL_WARRANTY_REPAIR_DEPS_CLAIM (repair_uid, claim_index) WHERE deleted_date IS NULL`.
- **`legal_warranty_repair_du`** — поля пользователей ДЮ, 1:1 с претензией.
- **`legal_warranty_repair_case_one`** — карточка Case.one и результат отправки, 1:1
  с претензией.
- **`legal_caseone_ref`** — кэш справочников Case.one (контрагенты, пользователи,
  каталоги), общий для домена `legal`.

Внешние ключи в миграциях **не создаются** (правило проекта); на entity стоит
`@DdlGeneration(unmappedConstraints = ...)`.

## Классы

| Таблица | Entity | Имя в Jmix |
|---|---|---|
| `legal_warranty_repair` | `LegalWarrantyRepair` | `legal_WarrantyRepair` |
| `legal_warranty_repair_deps` | `LegalWarrantyRepairDeps` | `legal_WarrantyRepairDeps` |
| `legal_warranty_repair_du` | `LegalWarrantyRepairDu` | `legal_WarrantyRepairDu` |
| `legal_warranty_repair_case_one` | `LegalWarrantyRepairCaseOne` | `legal_WarrantyRepairCaseOne` |
| `legal_caseone_ref` | `CaseOneRef` (пакет `legal.caseone.entity`) | `legal_CaseOneRef` |

## Типы: старое → новое

| MSSQL (ВагТК) | PostgreSQL / Java |
|---|---|
| `smalldatetime` со временем в данных (`Neispr_dt`, `Dat_Rem`, `Dat_Prib`, `VladStart_dt`, `Dat_Korr`) | `timestamp` / `LocalDateTime` — иначе перенос не lossless |
| `smalldatetime` без времени (даты писем, платежей) | `date` / `LocalDate` |
| `datetime` (системная метка) | `timestamp` / `LocalDateTime`; аудит Jmix — `timestamptz` / `OffsetDateTime` |
| `numeric(8,2)`, `numeric(12,2)`, `money` | `DECIMAL(12,2)` / `BigDecimal` (расширено, перенос lossless) |
| `numeric(16,2)` (накладные) | `DECIMAL(16,2)` |
| `tinyint`/`smallint` (код enum) | `int2` / `Integer` + enum-аксессор |
| `char(n)` / `varchar(n)` | `varchar(n)` / `String` |
| `uniqueidentifier` | `uuid` / `UUID` |
| коды-флаги (`NoPret`, `Rad_Garant`, `Tarif_NoPret`) | `boolean` / `Boolean` |

> Пользователи старой системы (`IdLogin`, `Sud_IdLogin`, `ID_Login_Reestr`,
> `Id_Login_Rem`, `Rasch_Dosil_sum_IdLogin`) переносятся **как ФИО** в
> `varchar(255)` — процедура отдаёт их в колонках `FIO`, `Sud_FIO_Korr`,
> `Reestr_FIO`, `Rasch_Dosil_sum_FIO`.

## Enum-ы

Хранятся кодом (`int2`), в Java — поле `Integer` + аксессор enum-типа (паттерн
`ru.fgk.ws.app.dt.entity.DtOperRepair`).

| Enum | Значения | Поля |
|---|---|---|
| `WarrantyRepairTypeEnum` | 1=ДЕП, 2=КАП, 3=ТР-1, 4=ТР-2 | `repair.repair_type` |
| `WarrantyPlanRepairTypeEnum` | 1=ДЕП, 2=КАП, 5=ПОСТ | `repair.next_repair_type` |
| `WarrantyClaimResultEnum` | 1=к оплате, 2=отклонено, 3=частично | `du.claim_result`, `deps.pre_claim_result`, `du.lawsuit_result` |
| `WarrantyReclamationResultEnum` | 1=принят, 2=отклонён, 3=возврат | `deps.reclamation_result` |
| `WarrantyBranchReviewResultEnum` | 1=принята, 2=отклонена | `du.branch_review_result` |
| `WarrantyReimbursementBasisEnum` | 1=по претензии, 2=по суду | `du.reimbursement_basis` |
| `WarrantyCaseOneStatusEnum` | 1=создана, 2=требуется обновление, 8=ошибка создания, 9=ошибка файлов | `case_one.case_one_status` |
| `CaseOneRefType` | PARTICIPANT / USER / FOLDER | `caseone_ref.ref_type` |
| `CaseOneParticipantType` | Individual / Company | `caseone_ref.participant_type` |

Переиспользуется существующий `ru.fgk.ws.app.dr.entity.WarrantyRepairEnum`
(0=ФГК, 1=ВРК1) для `repair.warranty_repair`.

`operation_type` (ВГК/Арен), `at_fault_type` (ВРК/Завод/ЦДИ/Аренда) и
`next_repair_vrk` оставлены строками: в старой БД это свободный текст, enum
заблокировал бы перенос.

Вычисляемые поля процедуры (`Srok_*`, `Nedopl_money`, `Straf_Summ`, `OtklRub`,
`SmotrRub`, `Sud_SumOtkaz`, `DatEndPret`, `Gar_RassmSut`, `DoPret_OtvSut`) **не
хранятся** — считаются в сервисе/UI.

---

## 1. `legal_warranty_repair` — отцепка

Заполняется автоматически; пользователи не редактируют.

| Колонка | Тип | Источник в ВагТК | Описание |
|---|---|---|---|
| `repair_uid` | UUID | — | Идентификатор отцепки |
| `wagnum` | numeric | `Nom_Vag` | Номер вагона |
| `defect_date` | DATETIME | `Neispr_dt` | Дата браковки (неисправности, отцепки) |
| `repair_date` | DATETIME | `Dat_Rem` | Дата выпуска из ремонта (окончание ремонта) |
| `repair_accept_date` | DATETIME | `Dat_Prib` | Дата приёма вагона в ремонт |
| `repair_type` | INT2 | `VidRem` | Вид ремонта: 1 - ДЕП, 2 - КАП, 3 - ТР-1, 4 - ТР-2 |
| `inventory_date` | DATETIME | `Dat_Ins` | Дата инвентаризации |
| `mileage_at_defect` | INT | — | Пробег вагона на момент отцепки, км |
| `railway_code` | VARCHAR(2) | `DorogaId` | Код дороги ремонта |
| `railway_mnkd` | VARCHAR(20) | — | Мнемокод дороги ремонта (филиал по ТОР) |
| `is_cis_railway` | BOOLEAN | — | Дорога СНГ (страна не РФ) |
| `vrp_code` | INT | `VRP` | Код ремонтного вагонного депо (ВРП) |
| `vrp_name` | VARCHAR(100) | — | Наименование ремонтного вагонного депо |
| `vrk` | INT2 | `VRK` | Номер ВРК предприятия ремонта |
| `repair_depo_per_act` | VARCHAR(150) | `Depo_Rem_Akt` | Наименование депо по акту выполненных работ |
| `damage_code_tn` | INT | `KodBrakTn` | Основной код технологической неисправности (ТН) |
| `damage_code_1` | INT | `KodBrak1` | Код неисправности 1 |
| `damage_code_2` | INT | `KodBrak2` | Код неисправности 2 |
| `damage_code_3` | INT | `KodBrak3` | Код неисправности 3 |
| `damage_name` | VARCHAR(300) | — | Наименование неисправности |
| `damage_note` | VARCHAR(100) | `Prim_Neispr` | Примечание к неисправности |
| `operation_type` | VARCHAR(4) | — | Оперирование вагона: ВГК / Арен |
| `wagon_model` | VARCHAR(50) | — | Модель вагона |
| `build_date` | DATE | — | Дата постройки вагона |
| `acquisition_date` | DATETIME | `VladStart_dt` | Дата приобретения вагона (начало владения) |
| `next_repair_date` | DATETIME | `PRem_dt` | Дата последнего планового ремонта или постройки |
| `next_repair_type` | INT2 | `PRemVid` | Вид планового ремонта: 1 - ДЕП, 2 - КАП, 5 - ПОСТ |
| `next_repair_vrp` | INT | `PRemVRP` | Клеймо предприятия планового ремонта (код ВРП) |
| `next_repair_vrp_name` | VARCHAR(100) | — | Наименование предприятия планового ремонта |
| `next_repair_vrk` | VARCHAR(10) | — | Завод/ВРК планового ремонта: ВРК1, НВРК, ОМК, ЦДРВ, НВТ, ЦДИ, Завод |
| `plan_repair_contract_num` | VARCHAR(100) | `DogRem_Nom` | Договор на плановый ремонт/поставку вагона: номер |
| `plan_repair_contract_date` | DATE | `DogRem_Dat` | Договор на плановый ремонт/поставку вагона: дата |
| `uncoupling_tr_count` | INT2 | `Kol_TR` | Количество отцепок в ТР после планового ремонта |
| `guarantee_kp_count` | INT2 | — | Количество обточенных гарантийных колёсных пар |
| `last_tr_date` | DATETIME | — | Последний ТР: дата |
| `last_tr_depo` | INT | — | Последний ТР: код депо |
| `last_tr_depo_name` | VARCHAR(100) | — | Последний ТР: наименование депо |
| `last_tr_vrk` | VARCHAR(10) | — | Последний ТР: ВРК |
| `last_tr_railway_mnkd` | VARCHAR(20) | — | Последний ТР: мнемокод дороги |
| `last_tr_type` | INT2 | — | Последний ТР: вид ремонта (3 - ТР-1, 4 - ТР-2) |
| `last_tr_damage_code` | INT | — | Последний ТР: код неисправности |
| `last_tr_mileage` | INT | — | Последний ТР: пробег, км |
| `lease_contract_num` | VARCHAR(100) | — | Договор аренды вагона: номер |
| `lease_contractor_name` | VARCHAR(150) | — | Договор аренды вагона: контрагент |
| `warranty_repair` | INT2 | — | Тип гарантийного ремонта: 0 - ФГК, 1 - ВРК1 |
| `created_by` | VARCHAR(255) | — | Кем создана запись |
| `created_date` | timestamptz | — | Дата создания записи |
| `last_modified_by` | VARCHAR(255) | — | Кем изменена запись |
| `last_modified_date` | timestamptz | — | Дата изменения записи |

Индекс `IDX_LEGAL_WARRANTY_REPAIR_WAG_DEFECT (wagnum, defect_date)` —
**не уникальный**: в истории возможны отцепки с одной датой браковки и разной
датой ремонта (см. [06-open-questions.md](06-open-questions.md)).

---

## 2. `legal_warranty_repair_deps` — претензия, зона ДЭПС

Заголовок формы (вагон, отцепка, неисправность, плановый ремонт) читается из
`legal_warranty_repair`; блок «Наименование контрагента, ответственного за
возмещение затрат» визуально в заголовке, но хранится **на претензию** —
как в старой системе.

| Колонка | Тип | Источник в ВагТК | Описание |
|---|---|---|---|
| `id` | BIGINT | — | Идентификатор претензии |
| `repair_uid` | UUID | — | Идентификатор отцепки (legal_warranty_repair) |
| `claim_index` | INT2 | `Index_Pret` | Индекс претензии по отцепке (нумерация с 1) |
| `src_id_zap` | INT | `IdZap` | Ключ записи в старой системе (TrkRemPretens.IdZap) для прослеживаемости переноса |
| `at_fault_is_vrp` | BOOLEAN | `Rad_Garant` | Виновник указан как ВРП (иначе - текстовый контрагент) |
| `at_fault_vrp_code` | INT | `VRP_Garant` | Виновник: клеймо предприятия (код ВРП) |
| `at_fault_railway_code` | VARCHAR(2) | `Dor_Garant` | Виновник: код дороги |
| `at_fault_type` | VARCHAR(10) | `Type_Garant` | Виновник: тип - ВРК / Завод / ЦДИ / Аренда |
| `at_fault_name` | VARCHAR(150) | `Name_Garant` | Виновник: наименование контрагента |
| `at_fault_note` | VARCHAR(500) | `Prim_Garant` | Виновник: примечание |
| `subject_to_claim` | BOOLEAN | `NoPret` | Подлежит выставлению претензии |
| `telegram_number` | VARCHAR(100) | `Nom_VT` | Вызывная телеграмма: номер |
| `telegram_send_date` | DATE | `Dat_SendVT` | Вызывная телеграмма: дата отправки |
| `telegram_received_by` | VARCHAR(30) | `FIO_RsvVT` | Вызывная телеграмма: ФИО принявшего |
| `telegram_receive_date` | DATE | `Dat_RsvVT` | Вызывная телеграмма: дата принятия |
| `reclamation_check_date` | DATE | `Rekl_Dat` | Приёмка рекламационных документов: дата проверки |
| `reclamation_result` | INT2 | `Rekl_Sogl` | Приёмка рекламационных документов: 1 - принят, 2 - отклонён, 3 - возврат |
| `reclamation_reject_reason` | VARCHAR(300) | `Prich_Otkl` | Приёмка рекламационных документов: причина отклонения |
| `reclamation_note` | VARCHAR(500) | `Rekl_Prich` | Приёмка рекламационных документов: примечание |
| `vu41_number` | VARCHAR(50) | `VU41_Nom` | Акт рекламации ВУ-41: номер |
| `vu41_date` | DATE | `VU41_Dat` | Акт рекламации ВУ-41: дата |
| `doc_package_ready_date` | DATE | `Dat_Pass` | Дата формирования полного комплекта документов |
| `doc_transfer_to` | VARCHAR(50) | `PassDoc_Name` | Передача документов для организации работ: наименование подразделения |
| `doc_transfer_date` | DATE | `PassDoc_Date` | Передача документов для организации работ: дата прикрепления документов |
| `pre_claim_department` | VARCHAR(50) | `FilG_Name` | Передача документов в допретензионную работу: наименование подразделения |
| `pre_claim_transfer_date` | DATE | `FilG_Get` | Передача документов в допретензионную работу: дата передачи |
| `tariff_rebill_subject` | BOOLEAN | `Tarif_NoPret` | Перевыставление тарифа подлежит |
| `tariff_rebill_transfer_date` | DATE | `Tarif_PassDat` | Перевыставление тарифа: дата передачи накладных |
| `claim_transfer_date` | DATE | `Send_PD` | Передача документов в претензионную работу: дата передачи |
| `claim_contractor_guid` | UUID | `KAgPret_GUID` | Контрагент претензии: идентификатор в Case.one (снимок выбора) |
| `claim_contractor_name` | VARCHAR(500) | `KAgPret_Name` | Контрагент претензии: наименование (снимок выбора) |
| `claim_contractor_inn` | VARCHAR(20) | — | Контрагент претензии: ИНН (снимок выбора) |
| `claim_contract_num` | VARCHAR(50) | `KAgPret_Dog` | Расчёт требований: номер договора |
| `claim_contract_date` | DATE | `KAgPret_Dog_Dt` | Расчёт требований: дата договора |
| `downtime_days` | INT2 | `ProstSut` | Простой: количество суток |
| `downtime_penalty_per_day` | DECIMAL(12, 2) | `Straf_Sut` | Простой: сумма штрафа за 1 сутки, руб |
| `dislocation_in_waybill_num` | VARCHAR(50) | `VRem_Nom` | Передислокация вагона в ремонт: номер накладной |
| `dislocation_in_debit_date` | DATE | `VRem_DT_Accredit` | Передислокация вагона в ремонт: дата раскредитования |
| `dislocation_in_amount` | DECIMAL(16, 2) | `VRem_Sum` | Передислокация вагона в ремонт: сумма платежа, руб |
| `dislocation_out_waybill_num` | VARCHAR(50) | `IzRem_Nom` | Передислокация вагона из ремонта: номер накладной |
| `dislocation_out_debit_date` | DATE | `IzRem_DT_Accredit` | Передислокация вагона из ремонта: дата раскредитования |
| `dislocation_out_amount` | DECIMAL(16, 2) | `IzRem_Sum` | Передислокация вагона из ремонта: сумма платежа, руб |
| `broken_tariff_waybill_num` | VARCHAR(50) | `Tranz_Nom` | Ломаный тариф: номер накладной |
| `broken_tariff_debit_date` | DATE | `Dosil_DT_Accredit` | Ломаный тариф: дата раскредитования |
| `broken_tariff_amount` | DECIMAL(16, 2) | `Dosil_Sum` | Ломаный тариф: сумма платежа, руб |
| `rebill_calc_amount` | DECIMAL(19, 4) | `Rasch_Dosil_sum` | Расчётная сумма перевыставления затрат, руб |
| `rebill_calc_by` | VARCHAR(255) | `Rasch_Dosil_sum_IdLogin` | Расчёт перевыставления: кем выполнен |
| `rebill_calc_date` | DATETIME | `Rasch_Dosil_sum_Date_sys` | Расчёт перевыставления: дата выполнения |
| `tariff_rebill_total` | DECIMAL(12, 2) | `Tarif_Sum` | Итого перевыставление провозных платежей, руб |
| `reimbursable_repair_cost` | DECIMAL(12, 2) | `Vozm_Summ` | Сумма ремонта, подлежащая возмещению, руб |
| `rework_return_date` | DATE | `DoPret_Vozvrat_Dt` | Возврат на доработку в ДЭПС из допретензионной работы: дата |
| `rework_return_rk_number` | VARCHAR(50) | `DoPret_Vozvrat_NomRK` | Возврат на доработку в ДЭПС из допретензионной работы: тех. номер РК в ЕАСД |
| `pre_claim_number` | VARCHAR(50) | `DoPret_Nom` | Допретензионное письмо: номер |
| `pre_claim_date` | DATE | `DoPret_Dat` | Допретензионное письмо: дата |
| `pre_claim_amount` | DECIMAL(12, 2) | `DoPret_Sum` | Допретензионное письмо: сумма, руб |
| `pre_claim_send_date` | DATE | `DoPret_Send` | Допретензионная работа: дата отправки виновнику |
| `pre_claim_result` | INT2 | `DoPret_Result` | Рассмотрение письма контрагентом: 1 - к оплате, 2 - отклонено, 3 - частично |
| `pre_claim_reply_number` | VARCHAR(50) | `DoPret_Otvet_Nom` | Рассмотрение письма контрагентом: номер ответа |
| `pre_claim_reply_date` | DATE | `DoPret_Otvet_Dat` | Рассмотрение письма контрагентом: дата ответа |
| `psr_number` | VARCHAR(50) | `DoPret_PassPP_Name` | Передача документов в претензионную работу: номер ПСР по ЕАСД |
| `psr_material_number` | VARCHAR(20) | `PSRMatNom` | Материалы ПСР: номер |
| `psr_material_date` | DATE | `PSRMatDate` | Материалы ПСР: дата |
| `law_registry_num` | VARCHAR(50) | `Reestr_Nom` | Реестр передачи в ДЮ: номер |
| `law_registry_date` | DATE | `Reestr_Date` | Реестр передачи в ДЮ: дата |
| `law_registry_by` | VARCHAR(255) | `ID_Login_Reestr` | Реестр передачи в ДЮ: кем сформирован |
| `law_registry_sys_date` | DATETIME | `Date_Sys_Reestr` | Реестр передачи в ДЮ: системная дата вставки |
| `agent_sng_percent` | DECIMAL(10, 6) | `AgentSNGProc` | Агент СНГ: процент |
| `agent_sng_cost` | DECIMAL(19, 4) | `AgentSNGStoim` | Агент СНГ: стоимость, руб |
| `repair_block_modified_by` | VARCHAR(255) | `Id_Login_Rem` | Ремонтный блок: кем изменён |
| `repair_block_modified_date` | DATETIME | `Date_Sys_Rem` | Ремонтный блок: дата изменения |
| `created_by` | VARCHAR(255) | — | Кем создана запись |
| `created_date` | timestamptz | — | Дата создания записи |
| `last_modified_by` | VARCHAR(255) | `IdLogin` | Кем выполнена последняя корректировка |
| `last_modified_date` | timestamptz | `Dat_Korr` | Дата последней корректировки |
| `deleted_by` | VARCHAR(255) | `Korr_pr` | Кем удалена запись |
| `deleted_date` | timestamptz | `Korr_pr` | Дата удаления записи |

---

## 3. `legal_warranty_repair_du` — зона ДЮ

Вкладки «Претензия» и «Судебная работа».

| Колонка | Тип | Источник в ВагТК | Описание |
|---|---|---|---|
| `id` | BIGINT | — | Идентификатор записи |
| `deps_id` | BIGINT | — | Идентификатор претензии (legal_warranty_repair_deps) |
| `rework_return_date` | DATE | `Pret_Vozvrat_Dt` | Возврат на доработку в ДЭПС из претензионной работы: дата |
| `rework_return_rk_number` | VARCHAR(50) | `Pret_Vozvrat_NomRK` | Возврат на доработку в ДЭПС из претензионной работы: тех. номер РК в ЕАСД |
| `branch_review_result` | INT2 | `FilG_Sogl` | Рассмотрение претензии филиалом по виновному предприятию: 1 - принята, 2 - отклонена |
| `branch_review_reject_reason` | VARCHAR(500) | `FilG_Prich` | Рассмотрение претензии филиалом по виновному предприятию: причина отклонения |
| `claim_number` | VARCHAR(100) | `NomPret` | Претензия: номер письма |
| `claim_date` | DATE | `DatPret` | Претензия: дата составления |
| `claim_amount` | DECIMAL(12, 2) | `Stoim` | Претензия: сумма, руб |
| `claim_send_date` | DATE | `Dat_Send` | Претензия: дата отправления виновнику |
| `at_fault_receive_date` | DATE | `Gar_Get` | Рассмотрение претензии виновным предприятием: дата получения |
| `claim_result` | INT2 | `Result` | Рассмотрение претензии виновным предприятием: 1 - к оплате, 2 - отклонено, 3 - частично |
| `at_fault_reply_date` | DATE | `Gar_Send` | Рассмотрение претензии виновным предприятием: дата ответа |
| `at_fault_reply_number` | VARCHAR(100) | `Gar_SendNom` | Рассмотрение претензии виновным предприятием: номер ответа |
| `at_fault_accepted_amount` | DECIMAL(12, 2) | `PriznRub` | Рассмотрение претензии виновным предприятием: признано, руб |
| `claim_reject_reason` | VARCHAR(500) | `Gar_Prich` | Отклонение претензии: причина отклонения |
| `to_law_date` | DATE | `Sud_PassDt` | Отклонение претензии: дата передачи в судебную работу |
| `payment_date` | DATE | `Dat_Money` | Получение денежных средств: дата |
| `payment_amount` | DECIMAL(12, 2) | `Sum_money` | Получение денежных средств: сумма, руб |
| `payment_number` | VARCHAR(20) | `Nom_money` | Получение денежных средств: номер платёжного поручения |
| `reimbursement_basis` | INT2 | `Osnov` | Получение денежных средств: основание (1 - по претензии, 2 - по суду) |
| `payment_note` | VARCHAR(200) | `Prim` | Получение денежных средств: примечание |
| `lawsuit_number` | VARCHAR(50) | `Sud_NomZ` | Судебная работа: номер искового заявления |
| `lawsuit_date` | DATE | `Sud_Dat` | Судебная работа: дата искового заявления |
| `case_number` | VARCHAR(50) | `Sud_NomD` | Судебная работа: номер дела |
| `lawsuit_amount` | DECIMAL(12, 2) | `Sud_Sum` | Судебная работа: сумма, заявленная в исковых требованиях, руб |
| `lawsuit_result` | INT2 | `Sud_Result` | Судебная работа: результат рассмотрения (1 - к оплате, 2 - отклонено, 3 - частично) |
| `lawsuit_accept_amount` | DECIMAL(12, 2) | `Sud_SumSogl` | Судебная работа: сумма, подлежащая удовлетворению, руб |
| `lawsuit_modified_by` | VARCHAR(255) | `Sud_IdLogin` | Судебная работа: кем выполнена последняя корректировка |
| `lawsuit_modified_date` | DATETIME | `Sud_Dat_Korr` | Судебная работа: дата последней корректировки |
| `created_by` | VARCHAR(255) | — | Кем создана запись |
| `created_date` | timestamptz | — | Дата создания записи |
| `last_modified_by` | VARCHAR(255) | — | Кем изменена запись |
| `last_modified_date` | timestamptz | — | Дата изменения записи |

---

## 4. `legal_warranty_repair_case_one` — карточка Case.one

Заполняется по кнопке «Отправить». Наименования ответственного и каталога
хранятся снимком на момент выбора, чтобы грид и печать не зависели от
доступности Case.one.

| Колонка | Тип | Источник в ВагТК | Описание |
|---|---|---|---|
| `id` | BIGINT | — | Идентификатор записи |
| `deps_id` | BIGINT | — | Идентификатор претензии (legal_warranty_repair_deps) |
| `case_one_status` | INT2 | `CaseOneStatus` | Статус: 1 - создана, 2 - требуется обновление дела, 8 - ошибка создания, 9 - ошибка добавления файлов |
| `card_guid` | UUID | `CaseOneGuid` | Идентификатор карточки в Case.one |
| `card_url` | VARCHAR(1000) | — | Ссылка на карточку в Case.one |
| `assignee_guid` | UUID | `CaseOneAssignee` | Ответственный в Case.one: идентификатор |
| `assignee_name` | VARCHAR(500) | — | Ответственный в Case.one: наименование (снимок выбора) |
| `folder_guid` | UUID | `CaseOneFolder` | Каталог в Case.one: идентификатор |
| `folder_name` | VARCHAR(500) | — | Каталог в Case.one: наименование (снимок выбора) |
| `sent_date` | DATETIME | `CaseOneDate` | Дата создания карточки либо дата ошибки |
| `fields_modified_date` | DATETIME | `CaseOneDateEdit` | Дата редактирования полей, требующих обновления карточки |
| `error_text` | VARCHAR(2000) | `CaseOneError` | Текст ошибки операции с Case.one |
| `created_by` | VARCHAR(255) | — | Кем создана запись |
| `created_date` | timestamptz | — | Дата создания записи |
| `last_modified_by` | VARCHAR(255) | — | Кем изменена запись |
| `last_modified_date` | timestamptz | — | Дата изменения записи |

---

## 5. `legal_caseone_ref` — кэш справочников Case.one

Одна таблица на все справочники, PK — идентификатор записи **в самой Case.one**,
поэтому сохранение идемпотентно без предварительного поиска.

Полного зеркала справочников нет сознательно: у Case.one нет ни выборки по дате
изменения, ни признака удаления, поэтому зеркало неизбежно расходится с
источником. В таблице оседает только то, что пользователь выбрал в форме, что
явно загрузили кнопкой «Обновить» (папки приходят одним запросом целиком,
пользователей сотни) либо что разрезолвили при переносе данных. Контрагенты —
всегда только поиск по ИНН/наименованию.

Ссылки из претензии хранятся **снимком** (идентификатор + наименование, для
контрагента ещё ИНН), а не внешним ключом: `deps.claim_contractor_guid` /
`claim_contractor_name` / `claim_contractor_inn`, `case_one.assignee_guid` /
`assignee_name`, `case_one.folder_guid` / `folder_name`. Строку кэша нельзя
удалять, даже если запись пропала в Case.one — вместо этого проставляется
`not_found_at`.

| Колонка | Тип | Описание |
|---|---|---|
| `id` | UUID | Идентификатор записи в Case.one |
| `ref_type` | VARCHAR(20) | Справочник: PARTICIPANT - контрагент, USER - пользователь, FOLDER - каталог |
| `name` | VARCHAR(500) | Наименование записи |
| `source_url` | VARCHAR(1000) | Ссылка на запись в Case.one |
| `participant_type` | VARCHAR(20) | Контрагент: тип - Individual (физлицо) или Company (организация) |
| `inn` | VARCHAR(20) | Контрагент: ИНН |
| `kpp` | VARCHAR(20) | Контрагент: КПП |
| `address` | VARCHAR(2000) | Контрагент: адрес (используется при печати претензии) |
| `email` | VARCHAR(255) | Адрес электронной почты (контрагент либо пользователь) |
| `external_id` | VARCHAR(255) | Пользователь: внешний идентификатор (Windows-логин) |
| `is_locked` | BOOLEAN | Пользователь: учётная запись заблокирована |
| `parent_id` | UUID | Каталог: идентификатор родительского каталога |
| `full_path` | VARCHAR(2000) | Каталог: полный путь от корня |
| `has_children` | BOOLEAN | Каталог: есть вложенные каталоги (вычисляется по непустому Items, не по IsLeaf) |
| `fetched_at` | timestamptz | Когда запись последний раз получена из Case.one |
| `last_used_at` | timestamptz | Когда запись последний раз выбрали в интерфейсе |
| `use_count` | INT | Сколько раз запись выбирали (для подсказки «недавние») |
| `not_found_at` | timestamptz | Когда Case.one последний раз ответил 404 - запись удалена или скрыта |
| `created_by` | VARCHAR(255) | Кем создана запись |
| `created_date` | timestamptz | Дата создания записи |
| `last_modified_by` | VARCHAR(255) | Кем изменена запись |
| `last_modified_date` | timestamptz | Дата изменения записи |

Индексы: `(ref_type, name)`, `inn`, `external_id`, `parent_id`, `last_used_at`.

Загрузка справочников из API, DTO ответов, журнал обращений и отправка карточки
в объём этой задачи не входят — они делаются поверх этой структуры.
