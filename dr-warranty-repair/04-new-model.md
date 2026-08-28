# Новая модель данных: 4 таблицы

Раздел: `ru.fgk.ws.app.legal` (предлагаемый подпакет `warrantyrepair`).
Имена таблиц — `dr_warranty_repair*` (согласовано: код в `legal`, таблицы `dr_*`).

## Конвенции именования (по Liquibase проекта)

Имена колонок приведены в соответствие с существующими таблицами проекта
(`app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/01-tbl/`), в
частности с `01-dt_oper_repair.xml` и `tbl-da_repair_claim.xml` — самый близкий
домен (ремонт + допретензия/претензия/суд):

| Понятие | Имя в проекте | Пример из changelog |
|---|---|---|
| Идентификатор ремонта (UUID, PK) | `repair_uid` | `dt_oper_repair`, `da_repair_claim`, `dr_diadoc_wag_oper_repair_contract` |
| Номер вагона | `wagnum` | `da_repair_claim.wagnum` |
| Дата браковки | `defect_date` | `da_repair_claim.defect_date` |
| Код/наименование неисправности | `damage_code` / `damage_name` | `da_repair_claim` |
| Дата/вид/стоимость ремонта | `repair_date` / `repair_type` / `repair_cost` | `dr_diadoc_wag_oper_repair_contract` |
| Очередной плановый ремонт | `next_repair_date` / `next_repair_type` | `da_repair_claim` |
| Дата постройки вагона | `build_date` | `da_repair_claim` |
| Подлежит претензии | `subject_to_claim` | `dt_oper_repair` |
| Допретензия | `pre_claim_number/date/date_send/result/reject_reason/note/accept_tariff` | `dt_oper_repair` |
| Претензия | `claim_number/date/tariff/result/note/payment_date/payment_number` | `dt_oper_repair` |
| Суд | `lawsuit_number/date/tariff/accept_tariff/payment_*`, `case_number`, `case_date`, `to_law_date` | `dt_oper_repair` |
| ПСР | `psr_number` / `psr_date` | `dt_oper_repair` |
| Договор / контрагент | `contract_num` / `contract_date` / `contractor_name` | `da_repair_claim` |
| Аудит | `created_by/date`, `last_modified_by/date` | все таблицы |

> `repair_uid` в проекте генерируется как
> `MD5(wagnum || defect_date)::uuid` (см. `tbl-da_repair_claim.xml`, changeSet 6) —
> т.е. отцепка однозначно определяется парой «вагон + дата браковки».

## Принципы

- **1 запись `dr_warranty_repair` = 1 отцепка** (вагон + дата браковки),
  заполняется автоматически (из ЕО/ВагТК и НСИ). **PK — `repair_uid` (UUID)**.
- **`dr_warranty_repair_deps`** — записывается при **создании претензии**.
  Суррогатный `id` — PK; `repair_uid` **не уникален** (несколько претензий на
  отцепку); UNIQUE `(repair_uid, claim_index)`.
- **`dr_warranty_repair_du`** и **`dr_warranty_repair_case_one`** — связь
  **один к одному** с `deps` (FK `deps_id`, UNIQUE).
- Кодовые поля (результаты, виды, основания) — `Integer` (id enum'а); enum'ы —
  в конце раздела.
- Вычисляемые в старой процедуре поля (`Srok_*`, `Nedopl_money`, `Straf_Summ`,
  `Tarif_Sum` и т.п.) **в таблицы не кладём** — считаются в сервисе/UI
  (см. [02-old-procedure.md](02-old-procedure.md)).

## Связи

```
dr_warranty_repair (1) ──< (N) dr_warranty_repair_deps         [repair_uid + claim_index]
dr_warranty_repair_deps (1) ─── (0..1) dr_warranty_repair_du        [deps_id, UNIQUE]
dr_warranty_repair_deps (1) ─── (0..1) dr_warranty_repair_case_one  [deps_id, UNIQUE]
```

---

## 1. `dr_warranty_repair` — отцепка (автозаполнение, PK = `repair_uid`)

> Имена колонок сверить с docx-заготовкой
> «Технологические_неисправности_по_вагонам.docx» (см. [06-open-questions.md](06-open-questions.md)).

| Колонка | Тип | Старый источник | Описание |
|---|---|---|---|
| `repair_uid` | uuid **PK** | — | Идентификатор отцепки (`MD5(wagnum \|\| defect_date)`) |
| `wagnum` | numeric NOT NULL | `Nom_Vag` | Номер вагона |
| `operation_type` | varchar(4) | `Vag_GR` | Оперирование (ВГК/Арен) — `nvVagPrivatArx.Vag_GR` (НСИ вагона) |
| `acquisition_date` | date | `VladStart_dt` | Дата приобретения вагона (отчёт: «Дата приобретения вагона») |
| `defect_date` | date NOT NULL | `Neispr_dt` | Дата браковки (неисправности/отцепки) |
| `railway_code` | varchar(2) | `DorogaId` | Код дороги |
| `railway_mnkd` | varchar(20) | `DorogaMnkd` | Мнемоника дороги (НСИ; в отчёте дублируется как `ef11`) |
| `vrp_code` | integer | `VRP` | Предприятие оперирования (код ВРП) |
| `vrp_name` | varchar(100) | `VrpSname` | Наименование предприятия (НСИ) |
| `vrk` | integer | `VRK` | ВРК |
| `damage_code_1` | integer | `KodBrak1` | Код неисправности 1 |
| `damage_code_2` | integer | `KodBrak2` | Код неисправности 2 |
| `damage_code_3` | integer | `KodBrak3` | Код неисправности 3 |
| `damage_code_tn` | integer | `KodBrakTn` | Основной код неисправности (ТН) |
| `damage_name` | varchar(300) | `Neispr_name` | Наименование неисправности (НСИ `nsBrak`) |
| `damage_note` | varchar(100) | `Prim_Neispr` | Примечание к неисправности |
| `repair_date` | date | `Dat_Rem` | Дата ремонта (выпуск из ремонта) |
| `repair_type` | integer | `VidRem` | Вид ремонта (1=ДЕП, 2=КАП, 3=ТР-1, 4=ТР-2) |
| `repair_accept_date` | date | `Dat_Prib` | Дата приёма вагона в ремонт |
| `inventory_date` | date | `Dat_Ins` | Дата инвентаризации |
| `repair_depo_per_act` | varchar(150) | `Depo_Rem_Akt` | Депо по акту выполненных работ |
| `next_repair_date` | date | `PREm_dt` | Дата очередного планового ремонта/поставки |
| `next_repair_type` | integer | `PRemVid` | Вид планового ремонта (1=ДЕП, 2=КАП, 5=ПОСТ) |
| `next_repair_vrp` | integer | `PRemVRP` | ВРП планового ремонта |
| `next_repair_vrk` | varchar(10) | `PREmVRK` | ВРК план. ремонта (ВРК1/НВРК/ОМК/ЦДРВ/НВТ/ЦДИ/Завод; в отчёте также вычисляемый `PRemVRP1`) |
| `plan_repair_contract_num` | varchar(100) | `DogRem_Nom` | Договор на плановый ремонт/поставку вагона: номер (в отчёте — `DogNomer`) |
| `plan_repair_contract_date` | date | `DogRem_Dat` | Договор на плановый ремонт/поставку вагона: дата |
| `mileage_at_defect` | integer | `ProbegOtc` | Пробег на отцепке |
| `wagon_model` | varchar(50) | `Model` | Модель вагона (НСИ) |
| `build_date` | date | `Postr_dt` | Дата постройки вагона (НСИ) |
| `is_cis_railway` | boolean | `IsSngDor` | Дорога СНГ (CountryID <> '0643') |
| `guarantee_kp_count` | integer | `GarantKP` | Обт. гарантийных КП (кол-во) — `TrkPretensObodKP`, только ФГК (комплекс 89/90) |
| `warranty_repair` | integer | — (новое) | Тип гарантийного ремонта (0=ФГК, 1=ВРК1) — `WarrantyRepairEnum` |
| `last_tr_date` | date | `DatLTekRem` | Дата последнего технического ремонта |
| `last_tr_depo` | integer | `DepoLTekRem` | Депо последнего ТР (код `VRP_LastTR`; процедура отдаёт отформатированную строку) |
| `last_tr_type` | integer | `VidLTekRem` | Вид последнего ТР (3=ТР-1, 4=ТР-2) |
| `last_tr_damage_code` | integer | `NeisprLTekRem` | Неисправность последнего ТР |
| `last_tr_mileage` | integer | `ProbegLTekRem` | Пробег на последнем ТР |
| `created_by` | varchar(255) | — | Аудит: создание |
| `created_date` | datetime | — | Аудит: дата создания |
| `last_modified_by` | varchar(255) | — | Аудит: последняя корректировка |
| `last_modified_date` | datetime | — | Аудит: дата корректировки |

**Не берём:** `Prost` (простой — отдельный функционал), `KodPret` (раздел
фиксирован), `Korr_pr` (лог. удаление → стандартный Jmix), `IdZap` (старый ключ).

---

## 2. `dr_warranty_repair_deps` — данные ДЭПС (на претензию, PK = `id`)

Запись создаётся при создании претензии. `id` — суррогатный PK; `repair_uid`
не уникален.

| Колонка | Тип | Старый источник | Описание |
|---|---|---|---|
| `id` | bigint PK identity | — | Суррогатный ключ (уникальный PK) |
| `repair_uid` | uuid FK NOT NULL | — | → `dr_warranty_repair.repair_uid` (не уникален) |
| `claim_index` | integer NOT NULL default 1 | `Index_Pret` | Индекс претензии |
| `at_fault_vrp_code` | integer | `VRP_Garant` | Виновник: ВРП (код) |
| `at_fault_railway_code` | varchar(2) | `Dor_Garant` | Виновник: дорога |
| `at_fault_type` | varchar(10) | `Type_Garant` | Виновник: тип (ВРК/Завод/ЦДИ/Аренда) |
| `at_fault_name` | varchar(50) | `Name_Garant` | Виновник: наименование контрагента (если не ВРП) |
| `at_fault_is_vrp` | boolean | `Rad_Garant` | Виновник: 0=ВРП, 1=текстовый контрагент |
| `at_fault_note` | varchar(500) | `Prim_Garant` | Виновник: примечание |
| `subject_to_claim` | boolean | `NoPret` | Подлежит выставлению претензии (0=да, 1=нет) |
| `telegram_number` | varchar(100) | `Nom_VT` | Выданный телеграмм: номер |
| `telegram_send_date` | date | `Dat_SendVT` | Телеграмм: дата отправки |
| `telegram_received_by` | varchar(30) | `FIO_RsvVT` | Телеграмм: ФИО принявшего |
| `telegram_receive_date` | date | `Dat_RsvVT` | Телеграмм: дата принятия |
| `reclamation_check_date` | date | `Rekl_Dat` | Рекламация: дата проверки документов |
| `reclamation_result` | integer | `Rekl_Sogl` | Рекламация: 1=принят, 2=отклонён, 3=возврат |
| `reclamation_reject_reason` | varchar(500) | `Rekl_Prich` | Рекламация: причина/примечание |
| `vu41_number` | varchar(50) | `VU41_Nom` | Акт ВУ-41: номер |
| `vu41_date` | date | `VU41_Dat` | Акт ВУ-41: дата |
| `doc_package_ready_date` | date | `Dat_Pass` | Дата формирования полного комплекта документов |
| `doc_transfer_to` | varchar(30) | `PassDoc_Name` | Документы переданы (кому) |
| `doc_transfer_date` | date | `PassDoc_Date` | Документы переданы (дата) |
| `pre_claim_transfer_date` | date | `FilG_Get` | Передача в допретензионную работу: дата |
| `pre_claim_department` | varchar(50) | `FilG_Name` | Подразделение для допретензионной работы |
| `claim_transfer_date` | date | `Send_PD` | Передача в претензионную работу: дата |
| `tariff_rebill_subject` | boolean | `Tarif_NoPret` | Перевыставление тарифа (0=подлежит, 1=не подлежит) |
| `tariff_rebill_transfer_date` | date | `Tarif_PassDat` | Перевыставление тарифа: дата передачи накладных |
| `claim_contractor_name` | varchar(150) | `KAgPret_Name` | Контрагент претензии (расчёт требований) |
| `claim_contract_num` | varchar(50) | `KAgPret_Dog` | Контрагент претензии: номер договора |
| `claim_contract_date` | date | `KAgPret_Dog_Dt` | Контрагент претензии: дата договора |
| `downtime_days` | integer | `ProstSut` | Простой: количество суток |
| `downtime_penalty_per_day` | decimal(12,2) | `Straf_Sut` | Простой: штраф за 1 сутки |
| `dislocation_in_waybill_num` | varchar(50) | `VRem_Nom` | Передислокация в ремонт: номер накладной |
| `dislocation_in_debit_date` | date | `VRem_DT_Accredit` | Передислокация в ремонт: дата раскредитования |
| `dislocation_in_amount` | decimal(16,2) | `VRem_Sum` | Передислокация в ремонт: сумма |
| `dislocation_out_waybill_num` | varchar(50) | `IzRem_Nom` | Передислокация из ремонта: номер накладной |
| `dislocation_out_debit_date` | date | `IzRem_DT_Accredit` | Передислокация из ремонта: дата раскредитования |
| `dislocation_out_amount` | decimal(16,2) | `IzRem_Sum` | Передислокация из ремонта: сумма |
| `broken_tariff_waybill_num` | varchar(50) | `Tranz_Nom` | Ломаный тариф: номер накладной |
| `broken_tariff_debit_date` | date | `Dosil_DT_Accredit` | Ломаный тариф: дата раскредитования |
| `broken_tariff_amount` | decimal(16,2) | `Dosil_Sum` | Ломаный тариф: сумма |
| `tariff_rebill_total` | decimal(12,2) | `Tarif_Sum` | Итого перевыставление платежей |
| `reimbursable_repair_cost` | decimal(12,2) | `Vozm_Summ` | Сумма ремонта, подлежащая возмещению |
| `calculated_rebill_amount` | decimal(19,4) | `Rasch_Dosil_sum` | Расчётная стоимость перевыставления затрат |
| `repair_cost` | decimal(8,2) | `Stoim` | Стоимость ремонта (сумма претензии) |
| `claim_number` | varchar(100) | `NomPret` | Номер претензии (в форме — вкладка «Претензия» зоны ДЮ) |
| `claim_date` | date | `DatPret` | Дата претензии |
| `claim_send_date` | date | `Dat_Send` | Дата отправки претензии виновнику |
| `claim_result` | integer | `Result` | Результат (1=к оплате, 2=отклонено, 3=частично) |
| `claim_note` | varchar(200) | `Prim` | Примечание (в зоне ДЮ — «Получение денежных средств: Примечание») |
| `rework_return_date` | date | `DoPret_Vozvrat_Dt` | Возврат на доработку в ДЭПС **из допретензионной работы** (вкладка ДЭПС): дата |
| `rework_return_rk_number` | varchar(50) | `DoPret_Vozvrat_NomRK` | Возврат на доработку в ДЭПС **из допретензионной работы**: тех. номер РК в ЕАСД |
| `psr_number` | varchar(50) | `DoPret_PassPP_Name` | Номер ПСР по ЕАСД (вкладка ДЭПС «Передача документов в претензионную работу») |
| `psr_date` | date | `PSRMatDate` | Материалы ПСР: дата |
| `law_registry_num` | varchar(50) | `Reestr_Nom` | Реестр передачи в ДЮ: номер |
| `law_registry_date` | date | `Reestr_Date` | Реестр передачи в ДЮ: дата |
| `law_registry_by` | integer | `ID_Login_Reestr` | Реестр: пользователь |
| `law_registry_sys_date` | datetime | `Date_Sys_Reestr` | Реестр: системная дата |
| `repair_block_modified_by` | integer | `Id_Login_Rem` | Ремонтный блок: пользователь |
| `repair_block_modified_date` | datetime | `Date_Sys_Rem` | Ремонтный блок: системная дата |
| `pre_claim_number` | varchar(50) | `DoPret_Nom` | Допретензия (письмо): номер |
| `pre_claim_date` | date | `DoPret_Dat` | Допретензия (письмо): дата |
| `pre_claim_tariff` | decimal(8,2) | `DoPret_Sum` | Допретензия (письмо): сумма |
| `pre_claim_date_send` | date | `DoPret_Send` | Допретензия: дата отправления виновнику |
| `pre_claim_result` | integer | `DoPret_Result` | Допретензия: 1=к оплате, 2=отклонено, 3=частично |
| `pre_claim_reply_number` | varchar(50) | `DoPret_Otvet_Nom` | Ответ виновника: номер письма |
| `pre_claim_reply_date` | date | `DoPret_Otvet_Dat` | Ответ виновника: дата |
| `created_by` | varchar(255) | — | Аудит: создание |
| `created_date` | datetime | — | Аудит: дата создания |
| `last_modified_by` | varchar(255) | `IdLogin` | Аудит: последняя корректировка (пользователь) |
| `last_modified_date` | datetime | `Dat_Korr` | Аудит: дата корректировки |

**UNIQUE:** `(repair_uid, claim_index)`.

> Поля допретензионного письма (`pre_claim_*`) размещены в `deps`, т.к.
> создаются пользователем ДЭПС; зона ДЮ их читает. Если ДЮ также редактирует —
> перенести в `du` (см. открытые вопросы).

---

## 3. `dr_warranty_repair_du` — данные ДЮ (1:1 с претензией)

Связь **один к одному** с `deps` (FK `deps_id`, UNIQUE).

| Колонка | Тип | Старый источник | Описание |
|---|---|---|---|
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

> `claim_note` (примечание к получению денег) в старой форме в зоне ДЮ, но в
> `TrkRemPretens` это одна общая колонка `Prim` → размещена в `deps.claim_note`.
> Если нужно отдельное примечание ДЮ — добавить `du.claim_note`.

---

## 4. `dr_warranty_repair_case_one` — карточка Case.one (1:1 с претензией)

Связь **один к одному** с `deps` (FK `deps_id`, UNIQUE).

| Колонка | Тип | Старый источник | Описание |
|---|---|---|---|
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

> Заполняется по кнопке «Отправить» (создание/обновление карточки в Case.one
> через `ru.fgk.ws.app.legal.caseone.*`). Состав полей карточки — см.
> `docs/caseone/pret_card_01 - пример карточки case one.json`; формирование
> карточки — задача по функционалу, не модель данных.

---

## Enum'ы к созданию (предлагаемые)

Существующий: `ru.fgk.ws.app.dr.entity.WarrantyRepairEnum` (0=ФГК, 1=ВРК1) —
для `dr_warranty_repair.warranty_repair`.

| Enum | Значения | Для полей |
|---|---|---|
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

> Для `at_fault_is_vrp` и `subject_to_claim`/`tariff_rebill_subject` можно
> использовать `Boolean` вместо enum (как `subject_to_claim` в `dt_oper_repair`).

## Типы (соответствие старой → новой)

| Старый (MSSQL) | Новый (Jmix/PostgreSQL) |
|---|---|
| `smalldatetime` (дата) | `LocalDate` (date) |
| `datetime` (системная метка) | `LocalDateTime` (datetime) |
| `numeric(p,2)` / `money` | `BigDecimal` (decimal) |
| `tinyint` / `smallint` / `int` (код) | `Integer` (id enum'а) |
| `char(n)` / `varchar(n)` | `String` (varchar(n)) |
| `uniqueidentifier` | `UUID` |
| `bit`-подобные флаги | `Boolean` |
