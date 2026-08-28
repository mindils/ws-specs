# Матрица маппинга: `TrkRemPretens` → 4 новые таблицы

Каждая колонка старой таблицы → колонка новой модели или «не переносится»
с причиной. Обозначения: **R** = `dr_warranty_repair`, **D** =
`dr_warranty_repair_deps`, **DU** = `dr_warranty_repair_du`, **CO** =
`dr_warranty_repair_case_one`.

Структура связей (см. [04-new-model.md](04-new-model.md)):
- `R` — PK `repair_uid` (UUID), 1 запись на отцепку;
- `D` — суррогатный `id` (PK), `repair_uid` не уникален, UNIQUE `(repair_uid, claim_index)`;
- `DU`, `CO` — 1:1 с `D` через `deps_id` (UNIQUE), собственных `repair_uid`/`claim_index` не имеют.

> **Источник русских заголовков:** файл
> `Таблица_претензий_с_колонками.xlsx` (отчёт «Перечень вагонов» старой
> системы) — строка 12 содержит имена колонок процедуры в том же порядке, что
> и русские заголовки (строки 4–11), далее — выборка реальных данных. Использован
> для сверки назначения колонок и выявления полей, отсутствующих на форме
> (`VladStart_dt`, `Vag_GR`, `GarantKP`, `DogNomer` и др.).

## Колонки `TrkRemPretens`

| Старая колонка | Новая | Причина / примечание |
|---|---|---|
| `IdZap` | — (опц. `D.src_id_zap`) | Суррогатный ключ старой системы; для прослеживаемости переноса можно сохранить как служебное поле (см. вопросы) |
| `Index_Pret` | D.claim_index | Индекс претензии (входит в UNIQUE `D`); в DU/CO не дублируется — связь через `deps_id` |
| `Nom_Vag` | R.wagnum | |
| `Dat_Rem` | R.repair_date | |
| `DorogaId` | R.railway_code | |
| `KodPret` | — | В новой системе раздел фиксирован (технологические); код не нужен |
| `KodBrak1` | R.damage_code_1 | |
| `KodBrak2` | R.damage_code_2 | |
| `KodBrak3` | R.damage_code_3 | |
| `VRP` | R.vrp_code | |
| `VRK` | R.vrk | |
| `VidRem` | R.repair_type | |
| `Dat_Prib` | R.repair_accept_date | |
| `Prost` | — | **Не берём** (комментарий в issue: колонка простоя — отдельный функционал) |
| `Dat_Ins` | R.inventory_date | |
| `Stoim` | D.repair_cost | Сумма претензии — на уровне претензии |
| `Dat_Pass` | D.doc_package_ready_date | |
| `Dat_Send` | D.claim_send_date | |
| `Result` | D.claim_result | |
| `Prim` | D.claim_note | Общая колонка примечаний; «Примечание» в зоне ДЮ (получение денег) — та же колонка в старой системе (см. вопросы) |
| `Dat_Money` | DU.payment_date | |
| `Dat_Korr` | D.last_modified_date | Аудит (дата последней корректировки) |
| `IdLogin` | D.last_modified_by | Аудит (пользователь последней корректировки) |
| `Korr_pr` | — | Логическое удаление старой системы; в Jmix — стандартное удаление/архивация |
| `Neispr_dt` | R.defect_date | |
| `PRem_dt` | R.next_repair_date | |
| `PRemVRP` | R.next_repair_vrp | |
| `NomPret` | D.claim_number | |
| `KodBrakTn` | R.damage_code_tn | |
| `DatPret` | D.claim_date | |
| `PRemVid` | R.next_repair_type | |
| `VladStart_dt` | R.acquisition_date | Дата приобретения вагона (есть в отчёте «Перечень вагонов») |
| `Kol_TR` | — | Нет на форме; переносить ли — **вопрос** |
| `Nom_VT` | D.telegram_number | |
| `Dat_SendVT` | D.telegram_send_date | |
| `FIO_RsvVT` | D.telegram_received_by | |
| `Dat_RsvVT` | D.telegram_receive_date | |
| `NoPret` | D.subject_to_claim | |
| `VRP_Garant` | D.at_fault_vrp_code | В старой форме — в заголовке, но выбирается пользователем ДЭПС |
| `Dor_Garant` | D.at_fault_railway_code | |
| `FilG_Get` | D.pre_claim_transfer_date | |
| `FilG_Sogl` | DU.branch_review_result | Зона ДЮ («Рассмотрение претензии филиалом по виновнику») |
| `FilG_Prich` | DU.branch_review_reject_reason | |
| `Gar_Get` | DU.at_fault_receive_date | |
| `Gar_Send` | DU.at_fault_reply_date | |
| `Gar_Prich` | DU.at_fault_review_note | |
| `Send_PD` | D.claim_transfer_date | |
| `Rekl_Dat` | D.reclamation_check_date | |
| `Rekl_Sogl` | D.reclamation_result | |
| `Rekl_Prich` | D.reclamation_reject_reason | |
| `Sum_money` | DU.payment_amount | |
| `Gar_SendNom` | — | Нет на форме; переносить ли — **вопрос** |
| `PriznRub` | DU.at_fault_accepted_amount | |
| `Nom_money` | DU.payment_number | |
| `Osnov` | DU.reimbursement_basis | |
| `Prim_Neispr` | R.damage_note | Примечание к неисправности (блок «Неисправности») |
| `DogRem_Nom` | R.plan_repair_contract_num | Договор на план. ремонт/поставку вагона (в отчёте — `DogNomer`); справочные данные вагона → R |
| `DogRem_Dat` | R.plan_repair_contract_date | |
| `PassDoc_Name` | D.doc_transfer_to | |
| `PassDoc_Date` | D.doc_transfer_date | |
| `FilG_Name` | D.pre_claim_department | |
| `Type_Garant` | D.at_fault_type | |
| `Name_Garant` | D.at_fault_name | |
| `Rad_Garant` | D.at_fault_is_vrp | |
| `DoPret_Vozvrat_Dt` | D.rework_return_date | Возврат на доработку в ДЭПС **из допретензионной работы** (вкладка ДЭПС) |
| `DoPret_Vozvrat_NomRK` | D.rework_return_rk_number | |
| `DoPret_Nom` | D.pre_claim_number | Создаётся ДЭПС («Допретензионная работа»); читается в зоне ДЮ — **вопрос** |
| `DoPret_Dat` | D.pre_claim_date | |
| `DoPret_Sum` | D.pre_claim_tariff | |
| `DoPret_Send` | D.pre_claim_date_send | |
| `DoPret_Result` | D.pre_claim_result | |
| `DoPret_Otvet_Nom` | D.pre_claim_reply_number | |
| `DoPret_Otvet_Dat` | D.pre_claim_reply_date | |
| `DoPret_PassPP_Name` | D.psr_number | «Номер ПСР по ЕАСД» (вкладка ДЭПС «Передача документов в претензионную работу») |
| `Sud_PassDt` | DU.to_law_date | |
| `Sud_NomZ` | DU.lawsuit_number | |
| `Sud_Dat` | DU.lawsuit_date | |
| `Sud_NomD` | DU.case_number | |
| `Sud_Sum` | DU.lawsuit_tariff | |
| `Sud_Result` | DU.lawsuit_result | |
| `Sud_SumSogl` | DU.lawsuit_accept_tariff | |
| `Sud_Dat_Korr` | DU.lawsuit_modified_date | |
| `Sud_IdLogin` | DU.lawsuit_modified_by | |
| `Prich_Otkl` | DU.claim_reject_reason | |
| `Tarif_NoPret` | D.tariff_rebill_subject | |
| `Tarif_Sum` | D.tariff_rebill_total | |
| `Tarif_PassDat` | D.tariff_rebill_transfer_date | |
| `Rasch_Dosil_sum` | D.calculated_rebill_amount | |
| `Rasch_Dosil_sum_IdLogin` | — | Аудит расчёта; переносить ли — **вопрос** |
| `Rasch_Dosil_sum_Date_sys` | — | Аудит расчёта; переносить ли — **вопрос** |
| `Pret_Vozvrat_Dt` | DU.rework_return_date | Возврат на доработку в ДЭПС **из претензионной работы** (вкладка ДЮ «Претензия») |
| `Pret_Vozvrat_NomRK` | DU.rework_return_rk_number | |
| `KAgPret_Name` | D.claim_contractor_name | |
| `KAgPret_Dog` | D.claim_contract_num | |
| `KAgPret_Dog_Dt` | D.claim_contract_date | |
| `ProstSut` | D.downtime_days | |
| `Straf_Sut` | D.downtime_penalty_per_day | |
| `Vozm_Summ` | D.reimbursable_repair_cost | |
| `Id_Login_Rem` | D.repair_block_modified_by | |
| `Date_Sys_Rem` | D.repair_block_modified_date | |
| `Depo_Rem_Akt` | R.repair_depo_per_act | Депо по акту выполненных работ (данные ремонта → R) |
| `Reestr_Nom` | D.law_registry_num | |
| `Reestr_Date` | D.law_registry_date | |
| `ID_Login_Reestr` | D.law_registry_by | |
| `Date_Sys_Reestr` | D.law_registry_sys_date | |
| `CaseOneStatus` | CO.case_one_status | |
| `CaseOneGuid` | CO.case_one_card_guid | |
| `CaseOneAssignee` | CO.case_one_assignee_guid | |
| `CaseOneFolder` | CO.case_one_folder_guid | |
| `CaseOneDate` | CO.case_one_created_date | |
| `CaseOneDateEdit` | CO.case_one_modified_date | |
| `CaseOneError` | CO.case_one_error | |
| `KAgPret_GUID` | CO.case_one_contractor_guid | |
| `PSRMatDate` | D.psr_date | Материалы ПСР: дата |
| `PSRMatNom` | — | Номер материалов ПСР; на форме «Номер ПСР по ЕАСД» = `DoPret_PassPP_Name` → совпадает ли с `PSRMatNom` — **вопрос** |
| `VU41_Nom` | D.vu41_number | |
| `VU41_Dat` | D.vu41_date | |
| `VRem_Nom` | D.dislocation_in_waybill_num | |
| `VRem_DT_Accredit` | D.dislocation_in_debit_date | |
| `VRem_Sum` | D.dislocation_in_amount | |
| `IzRem_Nom` | D.dislocation_out_waybill_num | |
| `IzRem_DT_Accredit` | D.dislocation_out_debit_date | |
| `IzRem_Sum` | D.dislocation_out_amount | |
| `Tranz_Nom` | D.broken_tariff_waybill_num | |
| `Dosil_DT_Accredit` | D.broken_tariff_debit_date | |
| `Dosil_Sum` | D.broken_tariff_amount | |
| `Prim_Garant` (только в живой БД) | D.at_fault_note | Нет в CREATE TABLE из issue, есть в БД и в результате процедуры |
| `AgentSNGProc` (только в живой БД) | — | Агент СНГ; переносить ли — **вопрос** |
| `AgentSNGStoim` (только в живой БД) | — | Агент СНГ; переносить ли — **вопрос** |

## Данные из других таблиц старой системы → `dr_warranty_repair` (автозаполнение)

В старой системе эти данные не хранятся в `TrkRemPretens`, а вычисляются
процедурой из справочников/истории. В новой системе они попадают в
`dr_warranty_repair` при автозаполнении (из ЕО/ВагТК и НСИ):

| Выходная колонка процедуры | Источник в старой системе | Новая колонка |
|---|---|---|
| `DorogaMnkd` | `nsDoroga.MNKD` | R.railway_mnkd |
| `VrpSname` | `nsTovPR_FOROSV.SNAME` | R.vrp_name |
| `Neispr_name` | `nsBrak.name` (по `KodBrakTn`) | R.damage_name |
| `PREmVRK` | `nsTHP_PrStamp` + флаг ЦДИ | R.next_repair_vrk |
| `ProbegOtc` | `VagPrivatRemDop` / `VagPrivatRemJour` | R.mileage_at_defect |
| `Model` | `nvVagPrivatArx.Model` | R.wagon_model |
| `Postr_dt` | `nvVagPrivatArx.Postr_dt` | R.build_date |
| `Vag_GR` | `nvVagPrivatArx.Vag_GR` | R.operation_type (ВГК/Арен) |
| `GarantKP` | `TrkPretensObodKP` (count по вагон+Dat_Rem, только комплекс 89/90) | R.guarantee_kp_count |
| `IsSngDor` | `nsDoroga.CountryID <> '0643'` | R.is_cis_railway |
| `DatLTekRem` | `VagPrivatRemBrak.Date_LastTR` | R.last_tr_date |
| `DepoLTekRem` | `VagPrivatRemBrak.VRP_LastTR` + СНИ | R.last_tr_depo |
| `VidLTekRem` | `VagPrivatRemBrak.Vid_LastTR` | R.last_tr_type |
| `NeisprLTekRem` | `VagPrivatRemBrak.KodBrak_LastTR` | R.last_tr_damage_code |
| `ProbegLTekRem` | `VagPrivatRemDop` | R.last_tr_mileage |

`R.warranty_repair` (0=ФГК, 1=ВРК1) — новое поле, в старой системе аналога нет
(определяется по комплексу/дороге; в ВагТК — `@KodKomplex` 89/90 = ФГК).

## Не переносится: вычисляемые поля процедуры

Считаются на лету в старой процедуре; в новой системе — в сервисе/UI при
необходимости (задача по функционалу, не модель данных):

- **Сроки и цвета:** `Srok_PassDoc`, `Srok_FilG`, `Srok_DoPret`, `Srok_PassPP`,
  `Srok_Pret`, `Srok_PassSud`, `Srok_Sud` + все `Srok_*Color` (параметры из
  `nvPretSrok`, расчёт `fTHP_SrokDay`);
- **Суммы:** `Nedopl_money` (недовозмещение), `PriznRub` (расчётная),
  `OtklRub`, `SmotrRub`, `Sud_SumOtkaz`, `Straf_Summ` (ProstSut × Straf_Sut),
  `Tarif_Sum`/`Tarif_Sum1` (VRem+IzRem+Rasch/Dosil), `Tarif_NoPretChar`,
  `DatEndPret` (Dat_Rem + 1 год);
- **Продолжительности:** `Gar_RassmSut`, `DoPret_OtvSut`, `ProstSut` (формула
  по часам; в новой системе `D.downtime_days` — хранимое редактируемое значение),
  `ProstSut_Edit`;
- **Блок счёта оплаты (DRVagTR):** `IdZap`/`Or_IdZap`, `OtchMonth`/`DateOtch`,
  `pd1..pd5` (`Or_Kompl`, `Or_Pr_Dt`, `Or_Pr`, `Or_Prim`, `Or_Kompl_Buh`),
  `Source`;
- **Блок пакета документов (DetDopPak):** `IdPak`, `Or_Pr_Dt`, `Prich_OtklPak`,
  `Or_Pr_Login`, `Or_Pr_Login_FIO`, `Pak_Pr`;
- **Блок реализации деталей:** `Det_prv`, `Det_Dop`, `Det_DopBuh`, `Det_Rash`,
  `Det_RashBuh`, `Det_RashBuhCnt`;
- **Договор аренды:** `Nomer_KT`, `NAME_KT` (данные договора аренды вагона;
  в старой системе для ФГК (комплекс 89/90) по арендованному вагону
  `Type_Garant`/`Name_Garant` автоматически подставляются из договора аренды —
  см. вопросы);
- **Накладные (VagPrivatRemOtpr):** `VRem_mOtprId`, `VRem_DT_Accept`,
  `IzRem_mOtprId`, `IzRem_DT_Accept`, `Tranz_mOtprId`, `Tranz_DT_Accept`,
  `Tranz_pl`, `Tranz_StanOtpr(Name)`, `Tranz_Stan(Name)`, `Tranz_Dob`,
  `Dosil_Dob`, `stan53/54`, `Namestan53/54`;
- **ФГК-специфичное:** `Porog` (временная окраска `TrkRemPretensColor`),
  `AgentSNG*`;
- **Справочные/служебные:** `DorogaMnkd`-дубли (`ef11`, `ef27`, `ef6`),
  `Id_DepTOP`, `Id_DepV`, `gr1`, `TypeVRP_Garant`, `PREmVRPSName`, `PREmP1`,
  `Type_GarantShow`, `Vrp_GarantShow`, `Name_GarantShow`, `KAgPret_*_Edit`,
  `FIO`, `Sud_FIO_Korr`, `Reestr_FIO`, `Rasch_Dosil_sum_FIO`, `Postr_God`,
  `VRKLTekRem`, `DorLTekRem`, `IdzapPret`, `DoPret_PassPP_Dt` (всегда null),
  `VremId`, `ResultId`, `NoPretId`, `VidRemId`, `PRemVidId`, `FilG_SoglId`,
  `Rekl_SoglId`, `CaseOneStatusName`, `OsnovName`, `VidRem`/`PRemVid`/`NoPret`/
  `Result` в текстовом виде.

## Перенос данных из старой таблицы

Старая система: **1 строка `TrkRemPretens` = 1 претензия** (ключ `IdZap`,
индекс претензии `Index_Pret`). Новая система: отцепка и претензии разнесены по
таблицам. Алгоритм переноса по строкам старой таблицы:

1. **`dr_warranty_repair` (R)** — группировка строк старой таблицы по
   **отцепке** (`wagnum + defect_date`, т.е. `Nom_Vag + Neispr_dt`). На каждую
   уникальную отцепку — 1 запись R, `repair_uid = MD5(wagnum || defect_date)`
   (конвенция проекта, см. `tbl-da_repair_claim.xml`). Колонки R берутся из
   строки (одинаковы для всех претензий отцепки).
2. **`dr_warranty_repair_deps` (D)** — на **каждую** строку старой таблицы —
   1 запись D: `repair_uid` (из шага 1) + `claim_index` (`Index_Pret`) +
   колонки D.
3. **`dr_warranty_repair_du` (DU)** — 1:1 с D: на запись D с заполненными
   ДЮ-колонками — 1 запись DU (`deps_id` = `D.id`).
4. **`dr_warranty_repair_case_one` (CO)** — 1:1 с D: на запись D с заполненными
   Case.one-колонками — 1 запись CO (`deps_id` = `D.id`).

Примечания:
- Служебные системные поля старой системы (`Id_Login_Rem`, `Date_Sys_Rem`,
  `ID_Login_Reestr`, `Date_Sys_Reestr`, `IdLogin`, `Sud_IdLogin` и т.п.) при
  переносе можно оставить как есть (коды пользователей старой системы) либо
  маппить на пользователей новой — решение при реализации.
- Для прослеживаемости переноса рекомендуется сохранить старый `IdZap` в
  служебной колонке `D.src_id_zap` (опционально, см. вопросы).
- Вычисляемые в процедуре поля в переносе **не участвуют** (не хранятся).
