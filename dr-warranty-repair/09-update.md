# Новая модель данных: 4 таблицы

Раздел: `ru.fgk.ws.app.legal` (предлагаемый подпакет `warrantyrepair`). Имена таблиц — `dr_warranty_repair*` (код в `legal`, таблицы `dr_*`).

## Связи

```
dr_warranty_repair (1) ──< (N) dr_warranty_repair_deps         [repair_uid + claim_index]
dr_warranty_repair_deps (1) ─── (0..1) dr_warranty_repair_du        [deps_id, UNIQUE]
dr_warranty_repair_deps (1) ─── (0..1) dr_warranty_repair_case_one  [deps_id, UNIQUE]
```

---

## 1. `dr_warranty_repair` — отцепка (автозаполнение, PK = `repair_uid`)

<table>
<tr>
<th>Колонка</th>
<th>Тип</th>
<th>Старый источник</th>
<th>Описание</th>
</tr>
<tr>
<td>

`repair_uid`
</td>
<td>

uuid **PK**
</td>
<td>—</td>
<td>

Идентификатор отцепки (`MD5(wagnum || defect_date)`)
</td>
</tr>
<tr>
<td>

`wagnum`
</td>
<td>numeric NOT NULL</td>
<td>

`Nom_Vag`
</td>
<td>Номер вагона</td>
</tr>
<tr>
<td>

~~operation_type~~

**_`category_oper`_**
</td>
<td>varchar(4)</td>
<td>

`Vag_GR`
</td>
<td>

Оперирование из wn_v_wag_passport— `nvVagPrivatArx.Vag_GR` (ЕРВ)
</td>
</tr>
<tr>
<td>

~~acquisition_date~~

**`own_start`**
</td>
<td>date</td>
<td>

`VladStart_dt`
</td>
<td>Дата приобретения вагона из wn_v_wag_passport (отчёт: «Дата приобретения вагона»)</td>
</tr>
<tr>
<td>

`defect_date`
</td>
<td>date NOT NULL</td>
<td>

`Neispr_dt`
</td>
<td>Дата браковки (неисправности/отцепки)</td>
</tr>
<tr>
<td>

`railway_code`
</td>
<td>varchar(2)</td>
<td>

`DorogaId`
</td>
<td>Код дороги</td>
</tr>
<tr>
<td>

`railway_mnkd`
</td>
<td>varchar(20)</td>
<td>

`DorogaMnkd`
</td>
<td>

Мнемоника дороги (НСИ; в отчёте дублируется как `ef11`)
</td>
</tr>
<tr>
<td>

~~`vrp_code`~~

`depo_code`
</td>
<td>integer</td>
<td>

`VRP`
</td>
<td>

Предприятие ~~оперирования~~ ремонта (код ВРП)
</td>
</tr>
<tr>
<td>

~~`vrp_name`~~

`depo_name`
</td>
<td>varchar(100)</td>
<td>

`VrpSname`
</td>
<td>Наименование предприятия (НСИ)</td>
</tr>
<tr>
<td>

~~`vrk`~~

`vrk_code`
</td>
<td>integer</td>
<td>

`VRK`
</td>
<td>Код ВРК</td>
</tr>
<tr>
<td>

~~`damage_code_1`~~

`defect_code_1`
</td>
<td>integer</td>
<td>

`KodBrak1`
</td>
<td>Код неисправности 1</td>
</tr>
<tr>
<td>

~~`damage_code_2`~~

`defect_code_2`
</td>
<td>integer</td>
<td>

`KodBrak2`
</td>
<td>Код неисправности 2</td>
</tr>
<tr>
<td>

~~`damage_code_3`~~

`defect_code_3`
</td>
<td>integer</td>
<td>

`KodBrak3`
</td>
<td>Код неисправности 3</td>
</tr>
<tr>
<td>

~~`damage_code_tn`~~

`defect_code_tn`
</td>
<td>integer</td>
<td>

`KodBrakTn`
</td>
<td>Основной код неисправности (технологический)</td>
</tr>
<tr>
<td>

~~`damage_name`~~

`defect_name`
</td>
<td>varchar(300)</td>
<td>

`Neispr_name`
</td>
<td>

Наименование неисправности (НСИ `nsBrak`)
</td>
</tr>
<tr>
<td>

~~`damage_note`~~

`defect_note`
</td>
<td>varchar(100)</td>
<td>

`Prim_Neispr`
</td>
<td>Примечание к неисправности</td>
</tr>
<tr>
<td>

`repair_date`
</td>
<td>date</td>
<td>

`Dat_Rem`
</td>
<td>Дата ремонта (выпуск из ремонта)</td>
</tr>
<tr>
<td>

`repair_type`
</td>
<td>integer</td>
<td>

`VidRem`
</td>
<td>Вид ремонта (1=ДЕП, 2=КАП, 3=ТР-1, 4=ТР-2)</td>
</tr>
<tr>
<td>

~~`repair_accept_date`~~

`repair_arrival_date`
</td>
<td>date</td>
<td>

`Dat_Prib`
</td>
<td>

Дата ~~приёма~~ прибытия вагона в ремонт
</td>
</tr>
<tr>
<td>

~~`inventory_date`~~

insert_vagtk_date
</td>
<td>date</td>
<td>

`Dat_Ins`
</td>
<td>

Дата ~~инвентаризации~~ вставки записи в ВагТК
</td>
</tr>
<tr>
<td>

~~`repair_depo_per_act`~~

`depo_act_code`
</td>
<td>varchar(150)</td>
<td>

`Depo_Rem_Akt`
</td>
<td>Депо по акту выполненных работ</td>
</tr>
<tr>
<td>

~~`next_repair_date`~~

`last_repair_date`
</td>
<td>date</td>
<td>

`PREm_dt`
</td>
<td>

Дата ~~очередного~~ последнего планового ремонта/~~поставки~~ постройки
</td>
</tr>
<tr>
<td>

~~`next_repair_type`~~

`last_repair_type`
</td>
<td>integer</td>
<td>

`PRemVid`
</td>
<td>Вид последнего планового ремонта (1=ДЕП, 2=КАП, 5=ПОСТ)</td>
</tr>
<tr>
<td>

~~`next_repair_vrp`~~

`last_repair_depo`
</td>
<td>integer</td>
<td>

`PRemVRP`
</td>
<td>ВРП последнего планового ремонта</td>
</tr>
<tr>
<td>

~~`next_repair_vrk`~~

`last_repair_vrk`
</td>
<td>varchar(10)</td>
<td>

`PREmVRK`
</td>
<td>

ВРК план. ремонта (ВРК1/НВРК/ОМК/ЦДРВ/НВТ/ЦДИ/Завод; в отчёте также вычисляемый `PRemVRP1`)
</td>
</tr>
<tr>
<td>

~~`plan_repair_contract_num`~~

`last_repair_contract_num`
</td>
<td>varchar(100)</td>
<td>

`DogRem_Nom`
</td>
<td>

Договор на плановый ремонт/поставку вагона: номер (в отчёте — `DogNomer`)
</td>
</tr>
<tr>
<td>

~~`plan_repair_contract_date`~~

`last_repair_contract_date`
</td>
<td>date</td>
<td>

`DogRem_Dat`
</td>
<td>Договор на плановый ремонт/поставку вагона: дата</td>
</tr>
<tr>
<td>

`mileage_at_defect`
</td>
<td>integer</td>
<td>

`ProbegOtc`
</td>
<td>Пробег на момент отцепки</td>
</tr>
<tr>
<td>

`wagon_model`
</td>
<td>varchar(50)</td>
<td>

`Model`
</td>
<td>Модель вагона (НСИ)</td>
</tr>
<tr>
<td>

`build_date`
</td>
<td>date</td>
<td>

`Postr_dt`
</td>
<td>Дата постройки вагона (НСИ)</td>
</tr>
<tr>
<td>

`is_cis_railway`
</td>
<td>boolean</td>
<td>

`IsSngDor`
</td>
<td>

Дорога СНГ (CountryID \<\> '0643')
</td>
</tr>
<tr>
<td>

`guarantee_kp_count`
</td>
<td>integer</td>
<td>

`GarantKP`
</td>
<td>

Обт. гарантийных КП (кол-во) — `TrkPretensObodKP`, только ФГК (комплекс 89/90)
</td>
</tr>
<tr>
<td>

`warranty_repair`
</td>
<td>integer</td>
<td>— (новое)</td>
<td>

Тип гарантийного ремонта (0=ФГК, 1=ВРК1) — `WarrantyRepairEnum`
</td>
</tr>
<tr>
<td>

`last_tr_date`
</td>
<td>date</td>
<td>

`DatLTekRem`
</td>
<td>

Дата последнего ~~технического~~ текущего ремонта
</td>
</tr>
<tr>
<td>

`last_tr_depo`
</td>
<td>integer</td>
<td>

`DepoLTekRem`
</td>
<td>

Депо последнего ТР (код `VRP_LastTR`; процедура отдаёт отформатированную строку)
</td>
</tr>
<tr>
<td>

`last_tr_type`
</td>
<td>integer</td>
<td>

`VidLTekRem`
</td>
<td>Вид последнего ТР (3=ТР-1, 4=ТР-2)</td>
</tr>
<tr>
<td>

~~`last_tr_damage_code`~~

`last_tr_defect_code`
</td>
<td>integer</td>
<td>

`NeisprLTekRem`
</td>
<td>Неисправность последнего ТР</td>
</tr>
<tr>
<td>

`last_tr_mileage`
</td>
<td>integer</td>
<td>

`ProbegLTekRem`
</td>
<td>Пробег на последнем ТР</td>
</tr>
<tr>
<td>

`created_by`
</td>
<td>varchar(255)</td>
<td>—</td>
<td>Аудит: создание</td>
</tr>
<tr>
<td>

`created_date`
</td>
<td>datetime</td>
<td>—</td>
<td>Аудит: дата создания</td>
</tr>
<tr>
<td>

`last_modified_by`
</td>
<td>varchar(255)</td>
<td>—</td>
<td>Аудит: последняя корректировка</td>
</tr>
<tr>
<td>

`last_modified_date`
</td>
<td>datetime</td>
<td>—</td>
<td>Аудит: дата корректировки</td>
</tr>
</table>

**Не берём:** `Prost` (простой — отдельный функционал), `KodPret` (раздел фиксирован), `Korr_pr` (лог. удаление → стандартный Jmix), `IdZap` (старый ключ).

---

## 2. `dr_warranty_repair_deps` — данные ДЭПС (на претензию, PK = `id`)

Запись создаётся при создании претензии. `id` — суррогатный PK; `repair_uid` не уникален.

<table>
<tr>
<th>Колонка</th>
<th>Тип</th>
<th>Старый источник</th>
<th>Описание</th>
</tr>
<tr>
<td>

`id`
</td>
<td>bigint PK identity</td>
<td>—</td>
<td>Суррогатный ключ (уникальный PK)</td>
</tr>
<tr>
<td>

`repair_uid`
</td>
<td>uuid FK NOT NULL</td>
<td>—</td>
<td>

→ `dr_warranty_repair.repair_uid` (не уникален)
</td>
</tr>
<tr>
<td>

`claim_index`
</td>
<td>integer NOT NULL default 1</td>
<td>

`Index_Pret`
</td>
<td>Индекс претензии</td>
</tr>
<tr>
<td>

~~`at_fault_vrp_code`~~

`warranty_depo_code`
</td>
<td>integer</td>
<td>

`VRP_Garant`
</td>
<td>Виновник: ВРП (код)</td>
</tr>
<tr>
<td>

~~`at_fault_railway_code`~~

`warranty_railway_code`
</td>
<td>varchar(2)</td>
<td>

`Dor_Garant`
</td>
<td>Виновник: дорога</td>
</tr>
<tr>
<td>

~~`at_fault_type`~~

`warranty_type`
</td>
<td>varchar(10)</td>
<td>

`Type_Garant`
</td>
<td>Виновник: тип (ВРК/Завод/ЦДИ/Аренда)</td>
</tr>
<tr>
<td>

~~`at_fault_name`~~

`warranty_name`
</td>
<td>varchar(50)</td>
<td>

`Name_Garant`
</td>
<td>Виновник: наименование контрагента (если не ВРП)</td>
</tr>
<tr>
<td>

~~`at_fault_is_vrp`~~

`warranty_is_vrp`
</td>
<td>boolean</td>
<td>

`Rad_Garant`
</td>
<td>Виновник: 0=ВРП, 1=текстовый контрагент</td>
</tr>
<tr>
<td>

~~`at_fault_note`~~

`warranty_note`
</td>
<td>varchar(500)</td>
<td>

`Prim_Garant`
</td>
<td>Виновник: примечание</td>
</tr>
<tr>
<td>

`subject_to_claim`
</td>
<td>boolean</td>
<td>

`NoPret`
</td>
<td>Подлежит выставлению претензии (0=да, 1=нет)</td>
</tr>
<tr>
<td>

`telegram_number`
</td>
<td>varchar(100)</td>
<td>

`Nom_VT`
</td>
<td>Выданный телеграмм: номер</td>
</tr>
<tr>
<td>

`telegram_send_date`
</td>
<td>date</td>
<td>

`Dat_SendVT`
</td>
<td>Телеграмм: дата отправки</td>
</tr>
<tr>
<td>

`telegram_received_by`
</td>
<td>varchar(30)</td>
<td>

`FIO_RsvVT`
</td>
<td>Телеграмм: ФИО принявшего</td>
</tr>
<tr>
<td>

`telegram_receive_date`
</td>
<td>date</td>
<td>

`Dat_RsvVT`
</td>
<td>Телеграмм: дата принятия</td>
</tr>
<tr>
<td>

`reclamation_check_date`
</td>
<td>date</td>
<td>

`Rekl_Dat`
</td>
<td>Рекламация: дата проверки документов</td>
</tr>
<tr>
<td>

`reclamation_result`
</td>
<td>integer</td>
<td>

`Rekl_Sogl`
</td>
<td>Рекламация: 1=принят, 2=отклонён, 3=возврат</td>
</tr>
<tr>
<td>

`reclamation_reject_reason`
</td>
<td>varchar(500)</td>
<td>

`Rekl_Prich`
</td>
<td>Рекламация: причина/примечание</td>
</tr>
<tr>
<td>

`vu41_number`
</td>
<td>varchar(50)</td>
<td>

`VU41_Nom`
</td>
<td>Акт ВУ-41: номер</td>
</tr>
<tr>
<td>

`vu41_date`
</td>
<td>date</td>
<td>

`VU41_Dat`
</td>
<td>Акт ВУ-41: дата</td>
</tr>
<tr>
<td>

`doc_package_ready_date`
</td>
<td>date</td>
<td>

`Dat_Pass`
</td>
<td>Дата формирования полного комплекта документов</td>
</tr>
<tr>
<td>

`doc_transfer_to`
</td>
<td>varchar(30)</td>
<td>

`PassDoc_Name`
</td>
<td>Документы переданы (кому)</td>
</tr>
<tr>
<td>

`doc_transfer_date`
</td>
<td>date</td>
<td>

`PassDoc_Date`
</td>
<td>Документы переданы (дата)</td>
</tr>
<tr>
<td>

`pre_claim_transfer_date`
</td>
<td>date</td>
<td>

`FilG_Get`
</td>
<td>Передача в допретензионную работу: дата</td>
</tr>
<tr>
<td>

`pre_claim_department`
</td>
<td>varchar(50)</td>
<td>

`FilG_Name`
</td>
<td>Подразделение для допретензионной работы</td>
</tr>
<tr>
<td>

`claim_transfer_date`
</td>
<td>date</td>
<td>

`Send_PD`
</td>
<td>Передача в претензионную работу: дата</td>
</tr>
<tr>
<td>

`tariff_rebill_subject`
</td>
<td>boolean</td>
<td>

`Tarif_NoPret`
</td>
<td>Перевыставление тарифа (0=подлежит, 1=не подлежит)</td>
</tr>
<tr>
<td>

`tariff_rebill_transfer_date`
</td>
<td>date</td>
<td>

`Tarif_PassDat`
</td>
<td>Перевыставление тарифа: дата передачи накладных</td>
</tr>
<tr>
<td>

`claim_contractor_name`
</td>
<td>varchar(150)</td>
<td>

`KAgPret_Name`
</td>
<td>Контрагент претензии (расчёт требований)</td>
</tr>
<tr>
<td>

`claim_contract_num`
</td>
<td>varchar(50)</td>
<td>

`KAgPret_Dog`
</td>
<td>Контрагент претензии: номер договора</td>
</tr>
<tr>
<td>

`claim_contract_date`
</td>
<td>date</td>
<td>

`KAgPret_Dog_Dt`
</td>
<td>Контрагент претензии: дата договора</td>
</tr>
<tr>
<td>

`downtime_days`
</td>
<td>integer</td>
<td>

`ProstSut`
</td>
<td>Простой: количество суток</td>
</tr>
<tr>
<td>

`downtime_penalty_per_day`
</td>
<td>decimal(12,2)</td>
<td>

`Straf_Sut`
</td>
<td>Простой: штраф за 1 сутки</td>
</tr>
<tr>
<td>

~~`dislocation_in_waybill_num`~~

`invoice_for_repair_num`
</td>
<td>varchar(50)</td>
<td>

`VRem_Nom`
</td>
<td>Передислокация в ремонт: номер накладной</td>
</tr>
<tr>
<td>

~~`dislocation_in_debit_date`~~

`invoice_for_repair_date_debit`
</td>
<td>date</td>
<td>

`VRem_DT_Accredit`
</td>
<td>Передислокация в ремонт: дата раскредитования накладной</td>
</tr>
<tr>
<td>

~~`dislocation_in_amount`~~

`invoice_for_repair_cost`
</td>
<td>decimal(16,2)</td>
<td>

`VRem_Sum`
</td>
<td>Передислокация в ремонт: сумма</td>
</tr>
<tr>
<td>

~~`dislocation_out_waybill_num`~~

`invoice_after_repair_num`
</td>
<td>varchar(50)</td>
<td>

`IzRem_Nom`
</td>
<td>Передислокация из ремонта: номер накладной</td>
</tr>
<tr>
<td>

~~`dislocation_out_debit_date`~~

`invoice_after_repair_date_debit`
</td>
<td>date</td>
<td>

`IzRem_DT_Accredit`
</td>
<td>Передислокация из ремонта: дата раскредитования</td>
</tr>
<tr>
<td>

~~`dislocation_out_amount`~~

`invoice_after_repair_cost`
</td>
<td>decimal(16,2)</td>
<td>

`IzRem_Sum`
</td>
<td>Передислокация из ремонта: сумма</td>
</tr>
<tr>
<td>

~~`broken_tariff_waybill_num`~~

`broken_tariff_invoice_num`
</td>
<td>varchar(50)</td>
<td>

`Tranz_Nom`
</td>
<td>Ломаный тариф: номер накладной</td>
</tr>
<tr>
<td>

`broken_tariff_debit_date`
</td>
<td>date</td>
<td>

`Dosil_DT_Accredit`
</td>
<td>Ломаный тариф: дата раскредитования</td>
</tr>
<tr>
<td>

`broken_tariff_cost`
</td>
<td>decimal(16,2)</td>
<td>

`Dosil_Sum`
</td>
<td>Ломаный тариф: сумма</td>
</tr>
<tr>
<td>

`tariff_rebill_total`
</td>
<td>decimal(12,2)</td>
<td>

`Tarif_Sum`
</td>
<td>Итого перевыставление платежей</td>
</tr>
<tr>
<td>

~~`reimbursable_repair_cost`~~

`warranty_repair_cost`
</td>
<td>decimal(12,2)</td>
<td>

`Vozm_Summ`
</td>
<td>Сумма ремонта, подлежащая возмещению</td>
</tr>
<tr>
<td>

~~`calculated_rebill_amount`~~

`calculated_invoice_cost`
</td>
<td>decimal(19,4)</td>
<td>

`Rasch_Dosil_sum`
</td>
<td>

Расчётная стоимость перевыставления затрат **за пересылку**
</td>
</tr>
<tr>
<td>

~~`repair_cost`~~

`claim_cost`
</td>
<td>decimal(8,2)</td>
<td>

`Stoim`
</td>
<td>

~~Стоимость ремонта~~ Полная сумма претензии
</td>
</tr>
<tr>
<td>

`claim_number`
</td>
<td>varchar(100)</td>
<td>

`NomPret`
</td>
<td>Номер претензии (в форме — вкладка «Претензия» зоны ДЮ)</td>
</tr>
<tr>
<td>

`claim_date`
</td>
<td>date</td>
<td>

`DatPret`
</td>
<td>Дата претензии</td>
</tr>
<tr>
<td>

`claim_send_date`
</td>
<td>date</td>
<td>

`Dat_Send`
</td>
<td>Дата отправки претензии виновнику</td>
</tr>
<tr>
<td>

`claim_result`
</td>
<td>integer</td>
<td>

`Result`
</td>
<td>Результат (1=к оплате, 2=отклонено, 3=частично)</td>
</tr>
<tr>
<td>

`claim_note`
</td>
<td>varchar(200)</td>
<td>

`Prim`
</td>
<td>Примечание (в зоне ДЮ — «Получение денежных средств: Примечание»)</td>
</tr>
<tr>
<td>

`rework_return_date`
</td>
<td>date</td>
<td>

`DoPret_Vozvrat_Dt`
</td>
<td>

Возврат на доработку в ДЭПС **из допретензионной работы** (вкладка ДЭПС): дата
</td>
</tr>
<tr>
<td>

`rework_return_rk_number`
</td>
<td>varchar(50)</td>
<td>

`DoPret_Vozvrat_NomRK`
</td>
<td>

Возврат на доработку в ДЭПС **из допретензионной работы**: тех. номер РК в ЕАСД
</td>
</tr>
<tr>
<td>

`psr_number`
</td>
<td>varchar(50)</td>
<td>

`DoPret_PassPP_Name`
</td>
<td>Номер ПСР по ЕАСД (вкладка ДЭПС «Передача документов в претензионную работу»)</td>
</tr>
<tr>
<td>

`psr_date`
</td>
<td>date</td>
<td>

`PSRMatDate`
</td>
<td>Материалы ПСР: дата</td>
</tr>
<tr>
<td>

`law_registry_num`
</td>
<td>varchar(50)</td>
<td>

`Reestr_Nom`
</td>
<td>Реестр передачи в ДЮ: номер</td>
</tr>
<tr>
<td>

`law_registry_date`
</td>
<td>date</td>
<td>

`Reestr_Date`
</td>
<td>Реестр передачи в ДЮ: дата</td>
</tr>
<tr>
<td>

`law_registry_by`
</td>
<td>integer</td>
<td>

`ID_Login_Reestr`
</td>
<td>Реестр: пользователь</td>
</tr>
<tr>
<td>

`law_registry_sys_date`
</td>
<td>datetime</td>
<td>

`Date_Sys_Reestr`
</td>
<td>Реестр: системная дата</td>
</tr>
<tr>
<td>

`repair_block_modified_by`
</td>
<td>integer</td>
<td>

`Id_Login_Rem`
</td>
<td>Ремонтный блок: пользователь</td>
</tr>
<tr>
<td>

`repair_block_modified_date`
</td>
<td>datetime</td>
<td>

`Date_Sys_Rem`
</td>
<td>Ремонтный блок: системная дата</td>
</tr>
<tr>
<td>

`pre_claim_number`
</td>
<td>varchar(50)</td>
<td>

`DoPret_Nom`
</td>
<td>Допретензия (письмо): номер</td>
</tr>
<tr>
<td>

`pre_claim_date`
</td>
<td>date</td>
<td>

`DoPret_Dat`
</td>
<td>Допретензия (письмо): дата</td>
</tr>
<tr>
<td>

`pre_claim_tariff`
</td>
<td>decimal(8,2)</td>
<td>

`DoPret_Sum`
</td>
<td>Допретензия (письмо): сумма</td>
</tr>
<tr>
<td>

`pre_claim_date_send`
</td>
<td>date</td>
<td>

`DoPret_Send`
</td>
<td>Допретензия: дата отправления виновнику</td>
</tr>
<tr>
<td>

`pre_claim_result`
</td>
<td>integer</td>
<td>

`DoPret_Result`
</td>
<td>Допретензия: 1=к оплате, 2=отклонено, 3=частично</td>
</tr>
<tr>
<td>

`pre_claim_reply_number`
</td>
<td>varchar(50)</td>
<td>

`DoPret_Otvet_Nom`
</td>
<td>Ответ виновника: номер письма</td>
</tr>
<tr>
<td>

`pre_claim_reply_date`
</td>
<td>date</td>
<td>

`DoPret_Otvet_Dat`
</td>
<td>Ответ виновника: дата</td>
</tr>
<tr>
<td>

`created_by`
</td>
<td>varchar(255)</td>
<td>—</td>
<td>Аудит: создание</td>
</tr>
<tr>
<td>

`created_date`
</td>
<td>datetime</td>
<td>—</td>
<td>Аудит: дата создания</td>
</tr>
<tr>
<td>

`last_modified_by`
</td>
<td>varchar(255)</td>
<td>

`IdLogin`
</td>
<td>Аудит: последняя корректировка (пользователь)</td>
</tr>
<tr>
<td>

`last_modified_date`
</td>
<td>datetime</td>
<td>

`Dat_Korr`
</td>
<td>Аудит: дата корректировки</td>
</tr>
</table>

**UNIQUE:** `(repair_uid, claim_index)`.

> Поля допретензионного письма (`pre_claim_*`) размещены в `deps`, т.к. создаются пользователем ДЭПС; зона ДЮ их читает. Если ДЮ также редактирует — перенести в `du`

---

## 3. `dr_warranty_repair_du` — данные ДЮ (1:1 с претензией)

Связь **один к одному** с `deps` (FK `deps_id`, UNIQUE).

| Колонка | Тип | Старый источник | Описание |
|---------|-----|-----------------|----------|
| `id` | bigint PK identity | — | Идентификатор записи |
| `deps_id` | bigint FK UNIQUE NOT NULL | — | → `dr_warranty_repair_deps.id` (1:1) |
| `rework_return_date` | date | `Pret_Vozvrat_Dt` | Возврат на доработку в ДЭПС **из претензионной работы** (вкладка ДЮ «Претензия»): дата |
| `rework_return_rk_number` | varchar(50) | `Pret_Vozvrat_NomRK` | Возврат на доработку в ДЭПС **из претензионной работы**: тех. номер РК в ЕАСД |
| `branch_review_result` | integer | `FilG_Sogl` | Рассмотрение претензии филиалом по виновному предприятию (1=принята, 2=отклонена) |
| `branch_review_reject_reason` | varchar(500) | `FilG_Prich` | Рассмотрение филиалом: причина |
| `at_fault_receive_date` | date | `Gar_Get` | Рассмотрение виновником: дата получения |
| `at_fault_reply_date` | date | `Gar_Send` | Рассмотрение виновником: дата ответа/отправки |
| `at_fault_review_note` | varchar(500) | `Gar_Prich` | Рассмотрение виновником: причина/примечание |
| `at_fault_accepted_amount` | decimal(8,2) | `PriznRub` | Сумма, признанная виновником |
| `to_law_date` | date | `Sud_PassDt` | Отклонение: дата передачи в судебную работу |
| `claim_reject_reason` | varchar(300) | `Prich_Otkl` | Отклонение: причина |
| `payment_date` | date | `Dat_Money` | Получение денег: дата |
| `payment_amount` | decimal(8,2) | `Sum_money` | Получение денег: сумма |
| `payment_number` | varchar(20) | `Nom_money` | Получение денег: № платёжного поручения |
| `reimbursement_basis` | integer | `Osnov` | Основание возмещения (1=по претензии, 2=по суду) |
| `lawsuit_number` | varchar(50) | `Sud_NomZ` | Суд: номер искового заявления |
| `lawsuit_date` | date | `Sud_Dat` | Суд: дата заявления |
| `case_number` | varchar(50) | `Sud_NomD` | Суд: номер дела |
| `lawsuit_tariff` | decimal(8,2) | `Sud_Sum` | Суд: сумма в исковых требованиях |
| `lawsuit_result` | integer | `Sud_Result` | Суд: 1=к оплате, 2=отклонено, 3=частично |
| `lawsuit_accept_tariff` | decimal(8,2) | `Sud_SumSogl` | Суд: сумма, подлежащая удовлетворению |
| `lawsuit_modified_by` | integer | `Sud_IdLogin` | Суд: пользователь корректировки |
| `lawsuit_modified_date` | date | `Sud_Dat_Korr` | Суд: дата корректировки |
| `created_by` | varchar(255) | — | Аудит: создание |
| `created_date` | datetime | — | Аудит: дата создания |
| `last_modified_by` | varchar(255) | — | Аудит: последняя корректировка |
| `last_modified_date` | datetime | — | Аудит: дата корректировки |

**UNIQUE:** `(deps_id)` — связь 1:1 с претензией.

> `claim_note` (примечание к получению денег) в старой форме в зоне ДЮ, но в `TrkRemPretens` это одна общая колонка `Prim` → размещена в `deps.claim_note`. Если нужно отдельное примечание ДЮ — добавить `du.claim_note`.

---

## 4. `dr_warranty_repair_case_one` — карточка Case.one (1:1 с претензией)

Связь **один к одному** с `deps` (FK `deps_id`, UNIQUE).

| Колонка | Тип | Старый источник | Описание |
|---------|-----|-----------------|----------|
| `id` | bigint PK identity | — | Идентификатор записи |
| `deps_id` | bigint FK UNIQUE NOT NULL | — | → `dr_warranty_repair_deps.id` (1:1) |
| `case_one_status` | integer | `CaseOneStatus` | Статус (1=создана, 2=требуется обновление, 8=ошибка создания, 9=ошибка файлов) |
| `case_one_card_guid` | uuid | `CaseOneGuid` | Идентификатор карточки в Case.one |
| `case_one_assignee_guid` | uuid | `CaseOneAssignee` | Идентификатор ответственного в Case.one |
| `case_one_folder_guid` | uuid | `CaseOneFolder` | Идентификатор каталога в Case.one |
| `case_one_created_date` | date | `CaseOneDate` | Дата создания/ошибки |
| `case_one_modified_date` | date | `CaseOneDateEdit` | Дата редактирования изменяемых полей |
| `case_one_error` | varchar(2000) | `CaseOneError` | Текст ошибки операции с Case.one |
| `case_one_contractor_guid` | uuid | `KAgPret_GUID` | Идентификатор контрагента (GUID из Case.one Participants) |
| `created_by` | varchar(255) | — | Аудит: создание |
| `created_date` | datetime | — | Аудит: дата создания |
| `last_modified_by` | varchar(255) | — | Аудит: последняя корректировка |
| `last_modified_date` | datetime | — | Аудит: дата корректировки |

**UNIQUE:** `(deps_id)` — связь 1:1 с претензией.

---

## Enum'ы к созданию (предлагаемые)

Существующий: `ru.fgk.ws.app.dr.entity.WarrantyRepairEnum` (0=ФГК, 1=ВРК1) — для `dr_warranty_repair.warranty_repair`.

| Enum | Значения | Для полей |
|------|----------|-----------|
| `WarrantyResultEnum` | 1=К ОПЛАТЕ, 2=ОТКЛОНЕНО, 3=ЧАСТИЧНО | `deps.claim_result`, `deps.pre_claim_result`, `du.lawsuit_result` |
| `OperationTypeEnum` | ВГК, Арен | `repair.operation_type` |
| `SubjectToClaimEnum` / boolean | подлежит / не подлежит | `deps.subject_to_claim` |
| `RepairTypeEnum` | 1=ДЕП, 2=КАП, 3=ТР-1, 4=ТР-2 | `repair.repair_type` |
| `NextRepairTypeEnum` | 1=ДЕП, 2=КАП, 5=ПОСТ | `repair.next_repair_type` |
| `ReclamationResultEnum` | 1=ПРИНЯТ, 2=ОТКЛОНЁН, 3=ВОЗВРАТ | `deps.reclamation_result` |
| `BranchReviewResultEnum` | 1=ПРИНЯТ, 2=ОТКЛОНЁН | `du.branch_review_result` |
| `ReimbursementBasisEnum` | 1=ПО ПРЕТЕНЗИИ, 2=ПО СУДУ | `du.reimbursement_basis` |
| `TariffRebillSubjectEnum` / boolean | подлежит / не подлежит | `deps.tariff_rebill_subject` |
| `CaseOneStatusEnum` | 1=СОЗДАНА, 2=ТРЕБУЕТСЯ ОБНОВЛЕНИЕ, 8=ОШИБКА СОЗДАНИЯ, 9=ОШИБКА ФАЙЛОВ | `case_one.case_one_status` |

> Для `at_fault_is_vrp` и `subject_to_claim`/`tariff_rebill_subject` можно использовать `Boolean` вместо enum (как `subject_to_claim` в `dt_oper_repair`).

## Типы (соответствие старой → новой)

| Старый (MSSQL) | Новый (Jmix/PostgreSQL) |
|----------------|-------------------------|
| `smalldatetime` (дата) | `LocalDate` (date) |
| `datetime` (системная метка) | `LocalDateTime` (datetime) |
| `numeric(p,2)` / `money` | `BigDecimal` (decimal) |
| `tinyint` / `smallint` / `int` (код) | `Integer` (id enum'а) |
| `char(n)` / `varchar(n)` | `String` (varchar(n)) |
| `uniqueidentifier` | `UUID` |
| `bit`-подобные флаги | `Boolean` |
