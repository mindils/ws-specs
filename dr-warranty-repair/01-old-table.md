# Старая таблица `dbo.TrkRemPretens` (ВагТК, MSSQL)

Одна строка = **одна претензия** по технологической неисправности. У одной
отцепки (вагон + дата браковки + дата ремонта) может быть несколько строк —
различаются `Index_Pret` (индекс претензии, по умолчанию 1).

Типы приведены по живой базе (проверено через `sys.columns`); описания — из
комментариев к `CREATE TABLE` в issue. Примечание: в живой базе
`DogRem_Nom varchar(100)` (в CREATE TABLE из issue — `varchar(30)`).

## Колонки

| Колонка | Тип | NULL | По умолчанию | Описание |
|---|---|---|---|---|
| `IdZap` | int | NOT NULL | identity(1,1) | Суррогатный ключ |
| `Index_Pret` | tinyint | NOT NULL | 1 | Индекс претензии (нумерация претензий по одной отцепке) |
| `Nom_Vag` | char(8) | NOT NULL | — | Номер вагона |
| `Dat_Rem` | smalldatetime | NULL | — | Дата ремонта (выпуск из ремонта) |
| `DorogaId` | char(2) | NOT NULL | — | Код дороги (`'??'` — заменяется на дорогу предприятия из справочника) |
| `KodPret` | tinyint | NOT NULL | — | 1 — технологические, 2 — простой в плановом (2 здесь не используется) |
| `KodBrak1` | smallint | NULL | — | Код неисправности 1 |
| `KodBrak2` | smallint | NULL | — | Код неисправности 2 |
| `KodBrak3` | smallint | NULL | — | Код неисправности 3 |
| `VRP` | smallint | NULL | — | ВРП — предприятие оперирования (код) |
| `VRK` | tinyint | NULL | — | ВРК |
| `VidRem` | tinyint | NULL | — | Вид ремонта: 1=ДЕП, 2=КАП, 3=ТР-1, 4=ТР-2 |
| `Dat_Prib` | smalldatetime | NOT NULL | — | Дата приёма вагона в ремонт |
| `Prost` | smallint | NOT NULL | — | Простой. **НЕ БЕРЁМ в таблицу претензий** — колонка для функционала простоя |
| `Dat_Ins` | smalldatetime | NULL | — | Дата инвентаризации |
| `Stoim` | numeric(8,2) | NOT NULL | — | Стоимость ремонта (сумма претензии) |
| `Dat_Pass` | smalldatetime | NULL | — | Дата формирования полного комплекта документов |
| `Dat_Send` | smalldatetime | NULL | — | Дата отправки претензии |
| `Result` | tinyint | NULL | — | Результат: 1 — к оплате, 2 — отклонено, 3 — частично |
| `Prim` | varchar(200) | NULL | — | Примечание |
| `Dat_Money` | smalldatetime | NULL | — | Дата получения денег |
| `Dat_Korr` | smalldatetime | NULL | — | Дата корректировки |
| `IdLogin` | smallint | NULL | — | Пользователь, сделавший корректировку |
| `Korr_pr` | tinyint | NOT NULL | 0 | Признак логического удаления (1 = удалено; в выборке фильтруется `Korr_pr <> 1`) |
| `Neispr_dt` | smalldatetime | NOT NULL | — | Дата неисправности (браковки/отцепки) |
| `PRem_dt` | smalldatetime | NULL | — | Дата последнего планового ремонта/поставки |
| `PRemVRP` | int | NULL | — | ВРП последнего планового ремонта |
| `NomPret` | varchar(100) | NULL | — | Номер претензии |
| `KodBrakTn` | smallint | NULL | — | Код неисправности по ТН (основной, для расшифровки из `nsBrak`) |
| `DatPret` | smalldatetime | NULL | — | Дата претензии |
| `PRemVid` | tinyint | NULL | — | Вид планового ремонта: 1=ДЕП, 2=КАП, 5=ПОСТ |
| `VladStart_dt` | smalldatetime | NULL | — | Дата начала владения |
| `Kol_TR` | tinyint | NULL | — | Количество ТР |
| `Nom_VT` | varchar(100) | NULL | — | Номер выданного телеграмма |
| `Dat_SendVT` | smalldatetime | NULL | — | Дата отправки телеграмма |
| `FIO_RsvVT` | varchar(30) | NULL | — | ФИО принявшего телеграмм |
| `Dat_RsvVT` | smalldatetime | NULL | — | Дата принятия телеграмма |
| `NoPret` | tinyint | NULL | — | 0 — подлежит, 1 — не подлежит выставлению претензии |
| `VRP_Garant` | smallint | NULL | — | ВРП — виновник по гарантийной ответственности |
| `Dor_Garant` | char(2) | NULL | — | Дорога виновника |
| `FilG_Get` | smalldatetime | NULL | — | Дата отправки в подразделение (филиалу по виновнику) для допретензионной работы |
| `FilG_Sogl` | tinyint | NULL | — | Согласование филиалом: 1 — принят, 2 — отклонён |
| `FilG_Prich` | varchar(500) | NULL | — | Причина (отклонения филиалом) |
| `Gar_Get` | smalldatetime | NULL | — | Дата получения гарантийным подразделением |
| `Gar_Send` | smalldatetime | NULL | — | Дата отправки гарантийным подразделением (ответа) |
| `Gar_Prich` | varchar(500) | NULL | — | Причина/примечание гарантийного подразделения |
| `Send_PD` | smalldatetime | NULL | — | Передача документов в претензионную работа / дата передачи |
| `Rekl_Dat` | smalldatetime | NULL | — | Дата проверки рекламационных документов |
| `Rekl_Sogl` | tinyint | NULL | — | Рекламация: 1 — принят, 2 — отклонён, 3 — возврат |
| `Rekl_Prich` | varchar(500) | NULL | — | Причина отклонения (для ФГК становится примечанием, а не причиной) |
| `Sum_money` | numeric(8,2) | NULL | — | Сумма, оплаченная виновником |
| `Gar_SendNom` | varchar(100) | NULL | — | Номер отправки гарантийным подразделением |
| `PriznRub` | numeric(8,2) | NULL | — | Сумма, признанная виновником по гарантийному письму |
| `Nom_money` | varchar(20) | NULL | — | Номер платёжного поручения |
| `Osnov` | tinyint | NULL | — | Основание возмещения: 1 — по претензии, 2 — по суду (для ФГК) |
| `Prim_Neispr` | varchar(100) | NULL | — | Примечание к неисправности |
| `DogRem_Nom` | varchar(100) | NULL | — | Договор на план. ремонт/поставку вагонов (изначально по данным АСУ ВРК на последний плановый ремонт, может быть скорректировано пользователем) |
| `DogRem_Dat` | smalldatetime | NULL | — | Дата договора на план. ремонт/поставку вагонов |
| `PassDoc_Name` | varchar(30) | NULL | — | Документы переданы (кому) |
| `PassDoc_Date` | smalldatetime | NULL | — | Документы переданы (дата) |
| `FilG_Name` | varchar(50) | NULL | — | Наименование подразделения (филиалу по виновнику), куда переданы документы для допретензионной работы |
| `Type_Garant` | varchar(10) | NULL | — | ВРК/Завод/ЦДИ/Аренда (варианты ФГК) |
| `Name_Garant` | varchar(50) | NULL | — | Наименование виновного контрагента, если это не ВРП |
| `Rad_Garant` | tinyint | NULL | — | Переключатель виновного контрагента: 0 — ВРП, 1 — прочий текстовый контрагент |
| `DoPret_Vozvrat_Dt` | smalldatetime | NULL | — | Возврат на доработку: дата |
| `DoPret_Vozvrat_NomRK` | varchar(50) | NULL | — | Возврат на доработку: тех. номер РК в ЕАСД |
| `DoPret_Nom` | varchar(50) | NULL | — | Допретензия: номер письма |
| `DoPret_Dat` | smalldatetime | NULL | — | Допретензия: дата письма |
| `DoPret_Sum` | numeric(8,2) | NULL | — | Сумма претензии по письму |
| `DoPret_Send` | smalldatetime | NULL | — | Допретензия: дата отправления виновнику |
| `DoPret_Result` | tinyint | NULL | — | 1 — к оплате, 2 — отклонено, 3 — частично |
| `DoPret_Otvet_Nom` | varchar(50) | NULL | — | Ответ виновника: номер письма |
| `DoPret_Otvet_Dat` | smalldatetime | NULL | — | Ответ виновника: дата |
| `DoPret_PassPP_Name` | varchar(50) | NULL | — | Передача ПП: наименование (материалы ПСР) |
| `Sud_PassDt` | smalldatetime | NULL | — | Дата передачи в судебную работу |
| `Sud_NomZ` | varchar(50) | NULL | — | Суд: номер нового заявления |
| `Sud_Dat` | smalldatetime | NULL | — | Суд: дата заявления |
| `Sud_NomD` | varchar(50) | NULL | — | Суд: номер дела |
| `Sud_Sum` | numeric(8,2) | NULL | — | Сумма, заявленная в исковых требованиях |
| `Sud_Result` | tinyint | NULL | — | 1 — к оплате, 2 — отклонено, 3 — частично |
| `Sud_SumSogl` | numeric(8,2) | NULL | — | Сумма, подлежащая удовлетворению (согласованная) |
| `Sud_Dat_Korr` | smalldatetime | NULL | — | Суд: дата корректировки |
| `Sud_IdLogin` | smallint | NULL | — | Суд: пользователь корректировки |
| `Prich_Otkl` | varchar(300) | NULL | — | Причина отклонения |
| `Tarif_NoPret` | tinyint | NULL | — | Перевыставление тарифа: 0 — подлежит, 1 — не подлежит |
| `Tarif_Sum` | numeric(12,2) | NULL | — | Сумма тарифа (итого перевыставление) |
| `Tarif_PassDat` | smalldatetime | NULL | — | Дата передачи документов/накладных в претензионную работу |
| `Rasch_Dosil_sum` | money | NULL | — | Расчётная стоимость перевыставления затрат |
| `Rasch_Dosil_sum_IdLogin` | int | NULL | — | Пользователь расчёта |
| `Rasch_Dosil_sum_Date_sys` | smalldatetime | NULL | — | Дата расчёта (системная) |
| `Pret_Vozvrat_Dt` | smalldatetime | NULL | — | Дата возврата в претензионную работу |
| `Pret_Vozvrat_NomRK` | varchar(50) | NULL | — | Номер возврата в претензионную работу |
| `KAgPret_Name` | varchar(150) | NULL | — | Наименование контрагента, в адрес которого будет направлена претензия |
| `KAgPret_Dog` | varchar(50) | NULL | — | Номер договора (контрагента претензии) |
| `KAgPret_Dog_Dt` | smalldatetime | NULL | — | Дата договора (контрагента претензии) |
| `ProstSut` | smallint | NULL | — | Количество суток простоя вагона с даты браковки до выпуска из ремонта |
| `Straf_Sut` | numeric(12,2) | NULL | — | Сумма штрафа за сутки |
| `Vozm_Summ` | numeric(12,2) | NULL | — | Сумма ремонта, подлежащая возмещению (руб.) |
| `Id_Login_Rem` | smallint | NULL | — | Пользователь (ремонт) |
| `Date_Sys_Rem` | datetime | NULL | — | Системная дата (ремонт) |
| `Depo_Rem_Akt` | varchar(150) | NULL | — | Наименование депо по акту выполненных работ |
| `Reestr_Nom` | varchar(50) | NULL | — | Номер реестра (передачи в ДЮ) |
| `Reestr_Date` | smalldatetime | NULL | — | Дата реестра |
| `ID_Login_Reestr` | smallint | NULL | — | Пользователь реестра |
| `Date_Sys_Reestr` | datetime | NULL | — | Системная дата реестра |
| `CaseOneStatus` | tinyint | NULL | — | Статус создания в case.one: 1 — создана, 2 — требуется обновление дела, 8 — ошибка создания, 9 — ошибка добавления файлов |
| `CaseOneGuid` | uniqueidentifier | NULL | — | Идентификатор созданной карточки в case.one |
| `CaseOneAssignee` | uniqueidentifier | NULL | — | Идентификатор ответственного в case.one |
| `CaseOneFolder` | uniqueidentifier | NULL | — | Идентификатор каталога в case.one |
| `CaseOneDate` | smalldatetime | NULL | — | Дата создания/ошибки |
| `CaseOneDateEdit` | smalldatetime | NULL | — | Дата редактирования изменяемых полей (Vozm_Summ, Tarif_Sum, ProstSut, …) |
| `CaseOneError` | varchar(2000) | NULL | — | Текст ошибки при операции с case.one |
| `KAgPret_GUID` | uniqueidentifier | NULL | — | Идентификатор контрагента (GUID из case.one, таблица `dbo.CaseOneParticipants`) |
| `PSRMatDate` | smalldatetime | NULL | — | Дата материалов ПСР |
| `PSRMatNom` | varchar(20) | NULL | — | Номер материалов ПСР |
| `VU41_Nom` | varchar(50) | NULL | — | Номер акта рекламации ВУ-41 |
| `VU41_Dat` | smalldatetime | NULL | — | Дата акта рекламации ВУ-41 (отцепки вагонов в ТОР) |
| `VRem_Nom` | varchar(50) | NULL | — | Передислокация в ремонт: номер накладной |
| `VRem_DT_Accredit` | smalldatetime | NULL | — | Передислокация в ремонт: дата раскредитования |
| `VRem_Sum` | numeric(16,2) | NULL | — | Передислокация в ремонт: сумма платежа |
| `IzRem_Nom` | varchar(50) | NULL | — | Передислокация из ремонта: номер накладной |
| `IzRem_DT_Accredit` | smalldatetime | NULL | — | Передислокация из ремонта: дата раскредитования |
| `IzRem_Sum` | numeric(16,2) | NULL | — | Передислокация из ремонта: сумма платежа |
| `Tranz_Nom` | varchar(50) | NULL | — | Ломаный тариф: номер накладной |
| `Dosil_DT_Accredit` | smalldatetime | NULL | — | Ломаный тариф: дата раскредитования |
| `Dosil_Sum` | numeric(16,2) | NULL | — | Ломаный тариф: сумма платежа |

## Колонки, присутствующие в живой базе, но отсутствующие в CREATE TABLE из issue

| Колонка | Тип | Описание (по контексту процедуры) |
|---|---|---|
| `Prim_Garant` | varchar(500) | Примечание по гарантийному контрагенту (выходит в результат процедуры) |
| `AgentSNGProc` | numeric(10,6) | Агент СНГ: процент |
| `AgentSNGStoim` | money | Агент СНГ: стоимость |

## Замечания

- `Korr_pr = 1` — логическое удаление; все выборки фильтруют `Korr_pr <> 1`.
- `DorogaId = '??'` — дорога подставляется из справочника предприятия (`nsTovPR_FOROSV`).
- Связи с другими таблицами (счёт оплаты, накладные, пакеты документов) в старой
  системе ведутся **не** через ключи в `TrkRemPretens`, а вычисляются процедурой
  по номеру вагона и датам (см. [02-old-procedure.md](02-old-procedure.md)) —
  в новой системе такие связи при необходимости оформляются явными FK.
