# Матрица переноса: `TrkRemPretens` → новые таблицы

Реализованная модель — см. [04-new-model.md](04-new-model.md).

**Источник истины при сверке** — `Таблица_претензий_с_колонками.xlsx` (отчёт
«Перечень вагонов» старой системы): строка 12 содержит имена колонок процедуры
ровно под русскими заголовками формы. По нему исправлено несколько ошибок
первоначального черновика — они помечены в таблице.

Покрытие: из 129 колонок `TrkRemPretens` переносится **127**, осознанно не
переносится **2**. Колонок без цели нет.

## Колонки

| Колонка `TrkRemPretens` | Новая колонка | Примечание |
|---|---|---|
| `IdZap` | `legal_warranty_repair_deps.src_id_zap` | служебное поле прослеживаемости и идемпотентности повторной заливки |
| `Index_Pret` | `legal_warranty_repair_deps.claim_index` |  |
| `Nom_Vag` | `legal_warranty_repair.wagnum` |  |
| `Dat_Rem` | `legal_warranty_repair.repair_date` |  |
| `DorogaId` | `legal_warranty_repair.railway_code` |  |
| `KodPret` | — не переносится | раздел зафиксирован: только технологические неисправности |
| `KodBrak1` | `legal_warranty_repair.damage_code_1` |  |
| `KodBrak2` | `legal_warranty_repair.damage_code_2` |  |
| `KodBrak3` | `legal_warranty_repair.damage_code_3` |  |
| `VRP` | `legal_warranty_repair.vrp_code` |  |
| `VRK` | `legal_warranty_repair.vrk` |  |
| `VidRem` | `legal_warranty_repair.repair_type` |  |
| `Dat_Prib` | `legal_warranty_repair.repair_accept_date` |  |
| `Prost` | — не переносится | простой вагона — отдельный функционал (dt_oper_repair) |
| `Dat_Ins` | `legal_warranty_repair.inventory_date` |  |
| `Stoim` | `legal_warranty_repair_du.claim_amount` | **исправлено**: «Сумма претензии» (DM), зона ДЮ |
| `Dat_Pass` | `legal_warranty_repair_deps.doc_package_ready_date` |  |
| `Dat_Send` | `legal_warranty_repair_du.claim_send_date` | **исправлено**: «Дата отправ. винов.» (DN), зона ДЮ |
| `Result` | `legal_warranty_repair_du.claim_result` | **исправлено**: «к оплате/отклонено/частично» в блоке рассмотрения виновным предприятием (DS), зона ДЮ |
| `Prim` | `legal_warranty_repair_du.payment_note` | «Примечание» (EO) — в форме показано в блоке «Получение денежных средств» зоны ДЮ |
| `Dat_Money` | `legal_warranty_repair_du.payment_date` |  |
| `Dat_Korr` | `legal_warranty_repair_deps.last_modified_date` |  |
| `IdLogin` | `legal_warranty_repair_deps.last_modified_by` | переносится ФИО (`FIO` из процедуры), а не код пользователя |
| `Korr_pr` | `legal_warranty_repair_deps.deleted_date`, `legal_warranty_repair_deps.deleted_by` | `Korr_pr = 1` → строка переносится как удалённая (soft delete Jmix) |
| `Neispr_dt` | `legal_warranty_repair.defect_date` |  |
| `PRem_dt` | `legal_warranty_repair.next_repair_date` |  |
| `PRemVRP` | `legal_warranty_repair.next_repair_vrp` |  |
| `NomPret` | `legal_warranty_repair_du.claim_number` | **исправлено**: блок «Претензионная работа → Претензия» (DJ–DN) — зона ДЮ, на экране ДЭПС этих полей нет |
| `KodBrakTn` | `legal_warranty_repair.damage_code_tn` |  |
| `DatPret` | `legal_warranty_repair_du.claim_date` | **исправлено**: зона ДЮ |
| `PRemVid` | `legal_warranty_repair.next_repair_type` |  |
| `VladStart_dt` | `legal_warranty_repair.acquisition_date` |  |
| `Kol_TR` | `legal_warranty_repair.uncoupling_tr_count` | «Кол-во отцепок в ТР после план.» (V) |
| `Nom_VT` | `legal_warranty_repair_deps.telegram_number` |  |
| `Dat_SendVT` | `legal_warranty_repair_deps.telegram_send_date` |  |
| `FIO_RsvVT` | `legal_warranty_repair_deps.telegram_received_by` |  |
| `Dat_RsvVT` | `legal_warranty_repair_deps.telegram_receive_date` |  |
| `NoPret` | `legal_warranty_repair_deps.subject_to_claim` |  |
| `VRP_Garant` | `legal_warranty_repair_deps.at_fault_vrp_code` |  |
| `Dor_Garant` | `legal_warranty_repair_deps.at_fault_railway_code` |  |
| `FilG_Get` | `legal_warranty_repair_deps.pre_claim_transfer_date` |  |
| `FilG_Sogl` | `legal_warranty_repair_du.branch_review_result` |  |
| `FilG_Prich` | `legal_warranty_repair_du.branch_review_reject_reason` |  |
| `Gar_Get` | `legal_warranty_repair_du.at_fault_receive_date` |  |
| `Gar_Send` | `legal_warranty_repair_du.at_fault_reply_date` |  |
| `Gar_Prich` | `legal_warranty_repair_du.claim_reject_reason` | **исправлено**: колонка DW — «причина отклонения претензии», зона ДЮ |
| `Send_PD` | `legal_warranty_repair_deps.claim_transfer_date` |  |
| `Rekl_Dat` | `legal_warranty_repair_deps.reclamation_check_date` |  |
| `Rekl_Sogl` | `legal_warranty_repair_deps.reclamation_result` |  |
| `Rekl_Prich` | `legal_warranty_repair_deps.reclamation_note` | **исправлено**: колонка AY — «примечание» (для ФГК причина лежит в `Prich_Otkl`) |
| `Sum_money` | `legal_warranty_repair_du.payment_amount` |  |
| `Gar_SendNom` | `legal_warranty_repair_du.at_fault_reply_number` | **добавлено**: «номер ответа» виновного предприятия (DQ) — в черновике значилось «не переносится» |
| `PriznRub` | `legal_warranty_repair_du.at_fault_accepted_amount` |  |
| `Nom_money` | `legal_warranty_repair_du.payment_number` |  |
| `Osnov` | `legal_warranty_repair_du.reimbursement_basis` |  |
| `Prim_Neispr` | `legal_warranty_repair.damage_note` |  |
| `DogRem_Nom` | `legal_warranty_repair.plan_repair_contract_num` |  |
| `DogRem_Dat` | `legal_warranty_repair.plan_repair_contract_date` |  |
| `PassDoc_Name` | `legal_warranty_repair_deps.doc_transfer_to` |  |
| `PassDoc_Date` | `legal_warranty_repair_deps.doc_transfer_date` |  |
| `FilG_Name` | `legal_warranty_repair_deps.pre_claim_department` |  |
| `Type_Garant` | `legal_warranty_repair_deps.at_fault_type` |  |
| `Name_Garant` | `legal_warranty_repair_deps.at_fault_name` |  |
| `Rad_Garant` | `legal_warranty_repair_deps.at_fault_is_vrp` |  |
| `DoPret_Vozvrat_Dt` | `legal_warranty_repair_deps.rework_return_date` | возврат **из допретензионной** работы (CM), вкладка ДЭПС |
| `DoPret_Vozvrat_NomRK` | `legal_warranty_repair_deps.rework_return_rk_number` | возврат из допретензионной работы (CN) |
| `DoPret_Nom` | `legal_warranty_repair_deps.pre_claim_number` |  |
| `DoPret_Dat` | `legal_warranty_repair_deps.pre_claim_date` |  |
| `DoPret_Sum` | `legal_warranty_repair_deps.pre_claim_amount` |  |
| `DoPret_Send` | `legal_warranty_repair_deps.pre_claim_send_date` |  |
| `DoPret_Result` | `legal_warranty_repair_deps.pre_claim_result` |  |
| `DoPret_Otvet_Nom` | `legal_warranty_repair_deps.pre_claim_reply_number` |  |
| `DoPret_Otvet_Dat` | `legal_warranty_repair_deps.pre_claim_reply_date` |  |
| `DoPret_PassPP_Name` | `legal_warranty_repair_deps.psr_number` | «Номер ПСР по ЕАСД» (CZ) |
| `Sud_PassDt` | `legal_warranty_repair_du.to_law_date` |  |
| `Sud_NomZ` | `legal_warranty_repair_du.lawsuit_number` |  |
| `Sud_Dat` | `legal_warranty_repair_du.lawsuit_date` |  |
| `Sud_NomD` | `legal_warranty_repair_du.case_number` |  |
| `Sud_Sum` | `legal_warranty_repair_du.lawsuit_amount` |  |
| `Sud_Result` | `legal_warranty_repair_du.lawsuit_result` |  |
| `Sud_SumSogl` | `legal_warranty_repair_du.lawsuit_accept_amount` |  |
| `Sud_Dat_Korr` | `legal_warranty_repair_du.lawsuit_modified_date` |  |
| `Sud_IdLogin` | `legal_warranty_repair_du.lawsuit_modified_by` | переносится ФИО (`Sud_FIO_Korr`) |
| `Prich_Otkl` | `legal_warranty_repair_deps.reclamation_reject_reason` | **исправлено против черновика**: по отчёту «Перечень вагонов» (колонка AX) это причина отклонения рекламационных документов, а не претензии |
| `Tarif_NoPret` | `legal_warranty_repair_deps.tariff_rebill_subject` |  |
| `Tarif_Sum` | `legal_warranty_repair_deps.tariff_rebill_total` |  |
| `Tarif_PassDat` | `legal_warranty_repair_deps.tariff_rebill_transfer_date` |  |
| `Rasch_Dosil_sum` | `legal_warranty_repair_deps.rebill_calc_amount` |  |
| `Rasch_Dosil_sum_IdLogin` | `legal_warranty_repair_deps.rebill_calc_by` | переносится ФИО (`Rasch_Dosil_sum_FIO`) |
| `Rasch_Dosil_sum_Date_sys` | `legal_warranty_repair_deps.rebill_calc_date` |  |
| `Pret_Vozvrat_Dt` | `legal_warranty_repair_du.rework_return_date` | возврат **из претензионной** работы (DF), вкладка ДЮ |
| `Pret_Vozvrat_NomRK` | `legal_warranty_repair_du.rework_return_rk_number` | возврат из претензионной работы (DG) |
| `KAgPret_Name` | `legal_warranty_repair_deps.claim_contractor_name` |  |
| `KAgPret_Dog` | `legal_warranty_repair_deps.claim_contract_num` |  |
| `KAgPret_Dog_Dt` | `legal_warranty_repair_deps.claim_contract_date` |  |
| `ProstSut` | `legal_warranty_repair_deps.downtime_days` |  |
| `Straf_Sut` | `legal_warranty_repair_deps.downtime_penalty_per_day` |  |
| `Vozm_Summ` | `legal_warranty_repair_deps.reimbursable_repair_cost` |  |
| `Id_Login_Rem` | `legal_warranty_repair_deps.repair_block_modified_by` | переносится ФИО |
| `Date_Sys_Rem` | `legal_warranty_repair_deps.repair_block_modified_date` |  |
| `Depo_Rem_Akt` | `legal_warranty_repair.repair_depo_per_act` |  |
| `Reestr_Nom` | `legal_warranty_repair_deps.law_registry_num` |  |
| `Reestr_Date` | `legal_warranty_repair_deps.law_registry_date` |  |
| `ID_Login_Reestr` | `legal_warranty_repair_deps.law_registry_by` | переносится ФИО (`Reestr_FIO`) |
| `Date_Sys_Reestr` | `legal_warranty_repair_deps.law_registry_sys_date` |  |
| `CaseOneStatus` | `legal_warranty_repair_case_one.case_one_status` |  |
| `CaseOneGuid` | `legal_warranty_repair_case_one.card_guid` |  |
| `CaseOneAssignee` | `legal_warranty_repair_case_one.assignee_guid` |  |
| `CaseOneFolder` | `legal_warranty_repair_case_one.folder_guid` |  |
| `CaseOneDate` | `legal_warranty_repair_case_one.sent_date` |  |
| `CaseOneDateEdit` | `legal_warranty_repair_case_one.fields_modified_date` |  |
| `CaseOneError` | `legal_warranty_repair_case_one.error_text` |  |
| `KAgPret_GUID` | `legal_warranty_repair_deps.claim_contractor_guid` | идентификатор контрагента Case.one; лежит рядом с наименованием в `deps`, т.к. это выбор пользователя ДЭПС, а не результат отправки |
| `PSRMatDate` | `legal_warranty_repair_deps.psr_material_date` |  |
| `PSRMatNom` | `legal_warranty_repair_deps.psr_material_number` | заведено отдельно от `psr_number` — совпадение проверяется на данных |
| `VU41_Nom` | `legal_warranty_repair_deps.vu41_number` |  |
| `VU41_Dat` | `legal_warranty_repair_deps.vu41_date` |  |
| `VRem_Nom` | `legal_warranty_repair_deps.dislocation_in_waybill_num` |  |
| `VRem_DT_Accredit` | `legal_warranty_repair_deps.dislocation_in_debit_date` |  |
| `VRem_Sum` | `legal_warranty_repair_deps.dislocation_in_amount` |  |
| `IzRem_Nom` | `legal_warranty_repair_deps.dislocation_out_waybill_num` |  |
| `IzRem_DT_Accredit` | `legal_warranty_repair_deps.dislocation_out_debit_date` |  |
| `IzRem_Sum` | `legal_warranty_repair_deps.dislocation_out_amount` |  |
| `Tranz_Nom` | `legal_warranty_repair_deps.broken_tariff_waybill_num` |  |
| `Dosil_DT_Accredit` | `legal_warranty_repair_deps.broken_tariff_debit_date` |  |
| `Dosil_Sum` | `legal_warranty_repair_deps.broken_tariff_amount` |  |
| `Prim_Garant` | `legal_warranty_repair_deps.at_fault_note` | есть только в живой БД; «Примечание» в блоке виновного предприятия (BN) |
| `AgentSNGProc` | `legal_warranty_repair_deps.agent_sng_percent` | есть только в живой БД, в CREATE TABLE из issue отсутствует |
| `AgentSNGStoim` | `legal_warranty_repair_deps.agent_sng_cost` | есть только в живой БД |
## Данные из других таблиц старой системы → `legal_warranty_repair`

Вычисляются процедурой из справочников и истории; в новой системе попадают в
`legal_warranty_repair` при автозаполнении.

| Колонка процедуры | Источник в ВагТК | Новая колонка |
|---|---|---|
| `DorogaMnkd` / `ef11` | `nsDoroga.MNKD` | `railway_mnkd` |
| `IsSngDor` | `nsDoroga.CountryID <> '0643'` | `is_cis_railway` |
| `VrpSname` | `nsTovPR_FOROSV.SNAME` | `vrp_name` |
| `Neispr_name` | `nsBrak.name` по `KodBrakTn` | `damage_name` |
| `PREmVRK` | `nsTHP_PrStamp` + флаг ЦДИ | `next_repair_vrk` |
| `PREmVRPSName` | `nsTHP_PrStamp.SNAME` по `PRemVRP` | `next_repair_vrp_name` |
| `ProbegOtc` | `VagPrivatRemDop` / `VagPrivatRemJour` | `mileage_at_defect` |
| `Model` | `nvVagPrivatArx.Model` | `wagon_model` |
| `Postr_dt` | `nvVagPrivatArx.Postr_dt` | `build_date` |
| `Vag_GR` | `nvVagPrivatArx.Vag_GR` | `operation_type` |
| `GarantKP` | `TrkPretensObodKP` (вагон + `Dat_Rem`, только ФГК) | `guarantee_kp_count` |
| `DatLTekRem` | `VagPrivatRemBrak.Date_LastTR` | `last_tr_date` |
| `DepoLTekRem` | `VagPrivatRemBrak.VRP_LastTR` + НСИ | `last_tr_depo`, `last_tr_depo_name` |
| `VRKLTekRem` | `kcmod.nsTovPr_ForOsv` по депо | `last_tr_vrk` |
| `DorLTekRem` | MNKD дороги последнего ТР | `last_tr_railway_mnkd` |
| `VidLTekRem` | `VagPrivatRemBrak.Vid_LastTR` | `last_tr_type` |
| `NeisprLTekRem` | `VagPrivatRemBrak.KodBrak_LastTR` | `last_tr_damage_code` |
| `ProbegLTekRem` | `VagPrivatRemDop` | `last_tr_mileage` |
| `Nomer_KT` | `DOVagon` + `DODogovorInf` | `lease_contract_num` |
| `NAME_KT` | `DOClientInf.Client_name` | `lease_contractor_name` |

`warranty_repair` (0=ФГК, 1=ВРК1) аналога в старой таблице не имеет — правило
заполнения см. [06-open-questions.md](06-open-questions.md).

## Не переносится: вычисляемые поля процедуры

Считаются на лету; в новой системе — в сервисе/UI при необходимости:

- **Сроки и цвета:** `Srok_PassDoc`, `Srok_FilG`, `Srok_DoPret`, `Srok_PassPP`,
  `Srok_Pret`, `Srok_PassSud`, `Srok_Sud` и все `Srok_*Color` (параметры из
  `nvPretSrok`, расчёт `fTHP_SrokDay`);
- **Суммы:** `Nedopl_money`, `OtklRub`, `SmotrRub`, `Sud_SumOtkaz`, `Straf_Summ`
  (`ProstSut` × `Straf_Sut`), `Tarif_Sum1`, `Tarif_NoPretChar`, `DatEndPret`
  (`Dat_Rem` + 1 год);
- **Продолжительности:** `Gar_RassmSut`, `DoPret_OtvSut`, `ProstSut_Edit`;
- **Блоки из смежных таблиц:** счёт оплаты (`DRVagTR`: `Or_IdZap`, `OtchMonth`,
  `pd1`…`pd5`, `Source`), пакет документов (`DetDopPak`: `IdPak`, `Pak_Pr`,
  `Or_Pr_Dt`, `Prich_OtklPak`, `Or_Pr_Login*`), реализация деталей (`Det_*`),
  накладные (`VagPrivatRemOtpr`: `*_mOtprId`, `*_DT_Accept`, `Tranz_*`,
  `stan53/54`);
- **Служебные и дублирующие:** `ef6`, `ef27`, `Id_DepTOP`, `Id_DepV`, `gr1`,
  `TypeVRP_Garant`, `PREmP1`, `PRemVRP1`, `*Show`, `*_Edit`, `*Id`, текстовые
  расшифровки кодов, `Porog`, `IdzapPret`, `DoPret_PassPP_Dt` (всегда NULL).

## Алгоритм переноса

1. **`legal_warranty_repair`** — сгруппировать строки `TrkRemPretens` по отцепке
   (`Nom_Vag` + `Neispr_dt`). На каждую уникальную отцепку одна запись,
   `repair_uid` = свежий UUID. Колонки берутся из любой строки группы (они
   одинаковы) и дополняются данными НСИ (таблица выше).
2. **`legal_warranty_repair_deps`** — на **каждую** строку `TrkRemPretens` одна
   запись: `repair_uid` из шага 1, `claim_index` = `Index_Pret`,
   `src_id_zap` = `IdZap`; при `Korr_pr = 1` заполнить `deleted_date`/`deleted_by`.
3. **`legal_warranty_repair_du`** — на строку с заполненными ДЮ-колонками одна
   запись, `deps_id` = `id` из шага 2.
4. **`legal_warranty_repair_case_one`** — на строку с заполненными
   `CaseOne*`-колонками одна запись, `deps_id` = `id` из шага 2.
5. **`legal_caseone_ref`** — контрагентов по перенесённым `KAgPret_GUID`
   дозаполнить из Case.one; до резолвинга формы работают на снимке
   `claim_contractor_name`.

Повторный запуск идемпотентен по `deps.src_id_zap` (уникален в старой системе).
