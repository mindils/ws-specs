# Процедура `dbo.pThp_PretTehSelect2` (ВагТК, MSSQL)

Назначение (из заголовка процедуры): «Выбор данных по претензиям по
технологическим неисправностям», раздел ВагТК «Оплата ремонтов / Претензии /
Технологические / по вагонам». Именно эта процедура формирует набор данных для
формы «Гарантийные ремонты».

Структура процедуры:
1. `SELECT … INTO #TPret FROM dbo.TrkRemPretens r` + ~10 LEFT JOIN / OUTER APPLY
   (основные данные + справочники);
2. ~30 `UPDATE #TPret` — обогащение (договоры аренды, накладные, сроки через
   `nvPretSrok` + `fTHP_SrokDay`, реализация деталей из `DetMX`, история ремонтов);
3. Финальный `SELECT` с ветвлением:
   - `@Reg IS NULL` → **основной SELECT (228 колонок)** — именно этот ветка
     выполняется в примере из issue;
   - `@Reg = 1` → SELECT на 34 колонки (для `pTHP_PretTehSelectDocVozmZatr`);
   - иначе (в т.ч. `@Reg = 0`) → **результат не возвращается** (ловушка: 0 ≠ NULL).

## Параметры (35, в порядке объявления)

| # | Параметр | Тип | Назначение |
|---|---|---|---|
| 1 | `@Remont_dt_k` | smalldatetime | дата ремонта, конец |
| 2 | `@Remont_dt_n` | smalldatetime | дата ремонта, начало |
| 3 | `@DorogaRemontID` | varchar(3) | код дороги ремонта |
| 4 | `@Nom_Vag` | char(8) | номер вагона |
| 5 | `@Id_Login` | int | id пользователя (null → −1, без ограничения по филиалу) |
| 6 | `@RegRed` | tinyint | режим редактирования (0 — список, 6 — выставление, 10 — виновник, 12 — претензия) |
| 7 | `@Nom_Pret` | varchar(100) | маска номера претензии |
| 8 | `@IdSpis` | int | id списка вагонов (`THP_SpisVag`) |
| 9 | `@DatBrakBegin` | smalldatetime | период браковки, начало |
| 10 | `@DatBrakEnd` | smalldatetime | период браковки, конец |
| 11 | `@vrp` | int | фильтр по ВРП |
| 12 | `@vrpVin` | int | фильтр по виновнику (ВРП) |
| 13 | `@dorVin` | varchar(3) | дорога виновника ('999' — спецрежим) |
| 14 | `@vrk` | tinyint | фильтр по ВРК |
| 15 | `@checkKodBrak` | tinyint | фильтр: KodBrak1 заполнен |
| 16 | `@checkOtpr` | tinyint | фильтр: Dat_Send заполнен |
| 17 | `@kodPret` | tinyint | фильтр по KodPret |
| 18 | `@nopret` | tinyint | фильтр по NoPret |
| 19 | `@VidRem` | tinyint | фильтр по виду ремонта |
| 20 | `@result` | varchar(10) | маска результата ('1'/'2'/'3') |
| 21 | `@PRemVid` | varchar(10) | маска вида план. ремонта ('1'/'2'/'5') |
| 22 | `@verParams` | tinyint | объявлен, **не используется** в теле |
| 23 | `@Reg` | tinyint | null — обычный выбор; 1 — выбор для DocVozmZatr |
| 24 | `@Col` | varchar(100) | отчётная колонка-фильтр (Srok_*_Kol/Nar/…) |
| 25 | `@ID_Department` | int | филиал (0 — «не филиал», −2 — дороги СНГ) |
| 26 | `@FilG_NameVar` | varchar(50) | подразделение (ДКФ, ОАПС, филиал) |
| 27 | `@Start2` | smalldatetime | передача в допрет. работу, начало |
| 28 | `@Finish2` | smalldatetime | передача в допрет. работу, конец |
| 29 | `@GarantKP` | tinyint | фильтр по гарантийным КП |
| 30 | `@Reestr_NomDU` | varchar(50) | реестр ДЮ |
| 31 | `@DatBeginDU` | smalldatetime | реестр ДЮ, начало |
| 32 | `@DatEndDU` | smalldatetime | реестр ДЮ, конец |
| 33 | `@NomPSR` | varchar(50) | материалы ПСР |
| 34 | `@DatBeginPSR` | smalldatetime | ПСР, начало |
| 35 | `@DatEndPSR` | smalldatetime | ПСР, конец |

### Пример вызова из issue (28 позиционных аргументов)

```
exec pThp_PretTehSelect2 '20260630', '20260601', null, null, null, 0,
  null, null, null, null, null, null, null, null, null, null, null, 0,
  null, null, null, null, null, null, null, null, null, null
```

Эффективные значения: окно ремонта `Dat_Rem > 2026-06-01 AND Dat_Rem <= 2026-07-01`
(начало **исключительно**, конец включительно +1 день), `@RegRed=0`,
`@nopret=0` → только `isnull(NoPret,0)=0` («подлежит»), `@Reg=NULL` → основной
ветка на 228 колонок.

## Базовая выборка строк (WHERE первого SELECT)

```sql
WHERE (@Remont_dt_n is null or r.Dat_Rem > @Remont_dt_n)        -- начало ИСКЛЮЧИТЕЛЬНО
  AND (@Remont_dt_k is null or r.Dat_Rem <= @Remont_dt_k + 1)   -- конец включительно +1 день
  AND (@DatBrakBegin is null or r.Neispr_dt > @DatBrakBegin)
  AND (@DatBrakEnd   is null or r.Neispr_dt <= @DatBrakEnd + 1)
  AND (@Start2 is null or r.FilG_Get > @Start2)
  AND (@Finish2 is null or r.FilG_Get <= @Finish2 + 1)
  AND (@FilG_NameVar is null or r.FilG_Name = @FilG_NameVar)
  AND r.KodPret = 1                    -- только технологические претензии
  AND r.Korr_pr <> 1                   -- не удалённые
  AND (r.Nom_Vag = @Nom_Vag or @Nom_Vag is null)
  AND (дорога = @DorogaRemontID or null or '00' or ('999' and филиал есть))
  AND (фильтр по филиалу @ID_Department: 0/-2/конкретный)
  AND (права редактирования по @RegRed / @Id_Login)
  AND (NomPret like @Nom_Pret or null)
  AND (@IdSpis is null or вагон в списке THP_SpisVag)
  AND (@vrp / @vrpVin / @vrk / @checkOtpr / @checkKodBrak / @kodPret /
       @nopret / @VidRem / @result / @PRemVid — опциональные фильтры)
  AND (реестр ДЮ: @Reestr_NomDU / @DatBeginDU / @DatEndDU)
  AND (ПСР: @NomPSR / @DatBeginPSR / @DatEndPSR)
```

После temp-таблицы: `if @dorVin is not null and @dorVin<>'999'
delete from #TPret where DorVRP_Garant <> @dorVin`.

`ORDER BY r2.DorogaId, r2.Dat_Rem DESC, r2.Index_Pret ASC`.

## Источниковые таблицы

**Основная:** `dbo.TrkRemPretens` (alias `r`) — из неё берутся практически все
бизнес-колонки результата.

**JOIN при построении `#TPret`:**
- `dbo.nsTovPR_FOROSV` (osv, по `r.VRP`) — реестр предприятий (SNAME, VRK, дорога при `'??'`);
- `dbo.nsDoroga` (d) — дороги (MNKD, CountryID);
- `dbo.nvTRK_Departments` (dp1/pdp1/dp2/pdp2) — логика филиалов;
- `DOVagon` + `DODogovorInf` + `DODogovorInfRem` — договор аренды (OUTER APPLY, Otvetstv=1, DogType in (1,3));
- `dbo.nvTRK_login` (l по `r.IdLogin`, l2 по `r.ID_Login_Reestr`) — ФИО;
- `nvBrakGroup` (скаляр, флаг `TehKP`).

**Обогащение (UPDATE по `#TPret`):**
- `dbo.DetDopPak` (ServiceType=3) — состояние пакета документов (IdPak, Pak_Pr, Or_Pr_Dt, Prich_Otkl, Or_Pr_Login);
- `VagPrivatRem` / `VagPrivatRemJour` — станции stan53/stan54;
- `VagPrivatRemOtpr` — накладные в/из ремонта, транзит (VRem_*, IzRem_*, Tranz_*, Dosil_*);
- `nsStan` — названия станций;
- `dbo.nsTHP_PrStamp` — gr1 / TypeVRP_Garant / DorVRP_Garant;
- `DOVagon` + `DODogovorInf` (+`DODogovorInfRem`) — 2-й/3-й проход договоров аренды;
- `dbo.DOClientInf` — Name_KT, Name_Garant (ФГК);
- `dbo.nvVagPrivatArx` — korr_nom, Vag_GR, Model, Postr_dt;
- `dbo.DRVagTR` — блок счёта оплаты (Or_IdZap, OtchMonth, Or_Kompl, Or_Pr_Dt, Or_Pr, Or_Prim, Or_Kompl_Buh, Or_Prv, Rad_Garant по умолчанию);
- `DrVagTR` (2-й JOIN по `Date53 = Neispr_dt`) — fallback Or_IdZap;
- `dbo.DRVagTRDoc` — Source;
- `dbo.DetMX` + `DRVagTRPrZatrat` + `DetDopPak` + `DRVagTR` + `DRVagRem` — блок реализации деталей (Det_prv/Det_Dop/Det_Rash…);
- `dbo.drVagRem` — IdZap_Dr, DogNomer (последний плановый ремонт);
- `dbo.drVagRemVRK` + `dbo.nvDrSprDogovor` — fallback DogNomer/DogRem_Dat;
- `dbo.nvVagPrivatDob` — конфигурация `@dMon` (KodPos=42, mnkd='dMon');
- `dbo.nvPretSrok` — параметры сроков (Srok, SrokType по IdOper 9…16);
- `dbo.TrkPretensObodKP` — счётчик GarantKP (только ФГК);
- `dbo.VagPrivatRemDop` — ProbegOtc, ProbegTekRem;
- `dbo.VagPrivatRemBrak` — блок последнего ТР (DatTekRem, DepTekRem, VidTekRem, NeisprTekRem);
- `TrkRemPretensColor` — временная окраска ФГК → Porog (в комментарии: «вещь ВРЕМЕННАЯ и требует удаления!!!!!»);
- `dbo.nsTovPr_ForOsv` (Pr) — флаг ЦДИ для автоподсчёта Dat_Pass.

**JOIN финального SELECT:** `dbo.nvTRK_DD` (DD, DDV), `nsTovPR_FOROSV`
(osv2 по PRemVRP, osvVRP по VRP), `dbo.nsTHP_PrStamp` (prs, prsVRP),
`kcmod.dbo.CaseOneParticipants` (KA), `dbo.nsBrak` (b — расшифровка
неисправности), `kcmod.dbo.nsTovPr_ForOsv` (osvTR по DepTekRem), `dbo.nsFilVRK`,
`dbo.nsDoroga`.

**Конфигурация:** `dbo.nvservernastr` (nastrid=3 → `@IsTK`),
`kcmod.dbo.nvServerNastr` (nastrID=72 → `@KodKomplex`; 89/90 = ФГК),
`dbo.nvTRK_Login`, `nvTRK_Departments`, `nvtrk_dd`, `dbo.THP_SpisVag`.

**Функции:** `dbo.fTHP_SrokDay(date, n, type)` (расчёт рабочих дней),
`dbo.fTHP_DetPart(NomDet, 0|1|2)` (разбор номера детали).

## Выходные колонки основного SELECT (228, в порядке результата)

Формат: `# | alias в результате | источник/выражение`. `r2.X` — колонка
`#TPret` (в скобках — откуда она первоначально).

| # | Alias | Источник |
|---|---|---|
| 1 | `IdZap` | `Or_IdZap` ← `DRVagTR.IdZap` (или DrVagTR по Date53) |
| 2 | `DorogaMnkd` | `nsDoroga.MNKD` либо название филиала |
| 3 | `Id_DepTOP` | id филиала для прав редактирования (блок ТОР) |
| 4 | `DorogaId` | TrkRemPretens.DorogaId ('??' → из справочника) |
| 5 | `Nom_Vag` | TrkRemPretens |
| 6 | `Neispr_dt` | TrkRemPretens (дата неисправности/отцепки) |
| 7 | `Dat_Rem` | TrkRemPretens (дата ремонта) |
| 8 | `Neispr_kod123` | `ISNULL(KodBrak1,'000')+'+'+KodBrak2+'+'+KodBrak3` (по 3 символа) |
| 9 | `Neispr_name` | `nsBrak.name` по `KodBrakTn` (или 2-й код, если 1-й начинается с 9), `BrakVid_ev=3` |
| 10 | `VrpSname` | `nsTovPR_FOROSV.SNAME` по VRP |
| 11 | `VRP` | TrkRemPretens |
| 12 | `PREm_dt` | TrkRemPretens (дата последнего план. ремонта) |
| 13 | `PREmVRK` | CASE: ЦДРВ/ВРК1/НВРК/ОМК/НВТ/ЦДИ/Завод (`nsTHP_PrStamp.VRK`, `IdStampDep`, флаг ЦДИ) |
| 14 | `ef6` | mnkd филиала ВРК/дороги (nsFilVRK/nsDoroga) |
| 15 | `PREmVRP` | TrkRemPretens |
| 16 | `PREmVRPSName` | `nsTHP_PrStamp.SNAME` по PRemVRP |
| 17 | `ProbegOtc` | `VagPrivatRemDop` (ProbegGruz+ProbegPorogn), fallback `VagPrivatRemJour` |
| 18 | `Dat_Pass` | TrkRemPretens.Dat_Pass; для ФГК — автоподсчёт (см. вычисляемые) |
| 19 | `NomPret` | TrkRemPretens |
| 20 | `Dat_Send` | TrkRemPretens (ФГК: `isnull(Dat_Send, DatPret)`) |
| 21 | `Stoim` | TrkRemPretens (сумма претензии) |
| 22 | `Result` | текст: 1='к оплате', 2='отклонено', 3='частично' |
| 23 | `ResultId` | TrkRemPretens.Result (isnull 0) |
| 24 | `Prim` | TrkRemPretens |
| 25 | `Dat_Money` | TrkRemPretens (ФГК: fallback `Sud_Dat_Korr` при полном судебном удовлетворении) |
| 26 | `VidRem` | текст: 1=ДЕП, 2=КАП, 3=ТР-1, 4=ТР-2 |
| 27 | `VidRemId` | TrkRemPretens.VidRem |
| 28 | `DatPret` | TrkRemPretens (дата претензии) |
| 29 | `PRemVidId` | TrkRemPretens.PRemVid |
| 30 | `PRemVid` | текст: 1=ДЕП, 2=КАП, 5=ПОСТ |
| 31 | `VladStart_dt` | TrkRemPretens |
| 32 | `Kol_TR` | TrkRemPretens |
| 33 | `Nom_VT` | TrkRemPretens |
| 34 | `Dat_SendVT` | TrkRemPretens |
| 35 | `FIO_RsvVT` | TrkRemPretens |
| 36 | `Dat_RsvVT` | TrkRemPretens |
| 37 | `NoPret` | текст: 0='подлежит', 1='не подлежит' |
| 38 | `NoPretId` | TrkRemPretens.NoPret (isnull 99) |
| 39 | `VRP_Garant` | `isnull(VRP_Garant, PRemVRP)` |
| 40 | `Dor_Garant` | TrkRemPretens |
| 41 | `FilG_Get` | TrkRemPretens (передача в допретензионную работу) |
| 42 | `FilG_Sogl` | текст: 1='принят', 2='отклонён' |
| 43 | `FilG_SoglId` | TrkRemPretens.FilG_Sogl (isnull 0) |
| 44 | `FilG_Prich` | TrkRemPretens |
| 45 | `Gar_Get` | TrkRemPretens (получение гарантийным подразделением) |
| 46 | `Gar_RassmSut` | `datediff(day, Gar_Get, isnull(Gar_Send, getdate()))` |
| 47 | `Gar_Send` | TrkRemPretens |
| 48 | `Gar_Prich` | TrkRemPretens |
| 49 | `Send_PD` | `isnull(Send_PD, DatPret)` — передача в претензионную работу |
| 50 | `ef11` | `nsDoroga.MNKD` |
| 51 | `ef27` | mnkd/филиал по дороге виновника |
| 52 | `Id_DepV` | id филиала для прав (блок виновника) |
| 53 | `gr1` | `nsTHP_PrStamp.SNAME` (виновный ВРП) |
| 54 | `pd1` | `DRVagTR.Or_Kompl` |
| 55 | `pd2` | `DRVagTR.Or_Pr_Dt` |
| 56 | `pd3` | текст: 1='принят', 0='отклонен', 2='возвращено' |
| 57 | `pd3Id` | `DRVagTR.Or_Pr` |
| 58 | `pd4` | 'нет в оплате' либо `DRVagTR.Or_Prim` |
| 59 | `pd5` | `DRVagTR.Or_Kompl_Buh` |
| 60 | `Or_IdZap` | `DRVagTR.IdZap` (дубль колонки #1) |
| 61 | `Rekl_Dat` | TrkRemPretens |
| 62 | `Rekl_Sogl` | текст: 1='принят', 2='отклонён', 3='возврат' |
| 63 | `Rekl_SoglId` | TrkRemPretens.Rekl_Sogl (isnull 0) |
| 64 | `Rekl_Prich` | TrkRemPretens |
| 65 | `Sum_money` | `isnull(Sum_money>0, fallback ФГК: Sud_SumSogl при полном удовлетворении, иначе 0)` |
| 66 | `Nedopl_money` | (Stoim если ResultId=1; PriznRub если 3; DoPret_Sum если DoPret_Result=1) − Sum_money |
| 67 | `Gar_SendNom` | TrkRemPretens |
| 68 | `Nom_money` | TrkRemPretens (ФГК: fallback ФИО судебного корректора) |
| 69 | `DatEndPret` | `DateAdd(year, 1, Dat_Rem)` — срок предъявления претензии |
| 70 | `PriznRub` | Stoim (при ResultId=1) либо PriznRub (при 3) |
| 71 | `OtklRub` | Stoim (при 2) либо Stoim−PriznRub (при 3) |
| 72 | `SmotrRub` | Stoim (при ResultId=0 — на рассмотрении) |
| 73 | `Nomer_KT` | договор аренды № (DOVagon/DODogovorInf.Nomer) |
| 74 | `NAME_KT` | `DOClientInf.Client_name` |
| 75 | `Osnov` | TrkRemPretens.Osnov (isnull 0) |
| 76 | `OsnovName` | 1='по претензии', 2='по суду' |
| 77 | `Vag_GR` | `nvVagPrivatArx` |
| 78 | `DogNomer` | DogRem_Nom → `drVagRem.DogovorNom` → `nvDrSprDogovor.DocNomer` |
| 79 | `DogRem_Dat` | DogRem_Dat → `nvDrSprDogovor.DocFrom` |
| 80 | `Prim_Neispr` | TrkRemPretens |
| 81 | `Det_prv` | кол-во перевыставленных деталей (#DetMX) |
| 82 | `Det_Dop` | детали из пакетов хранения |
| 83 | `Det_DopBuh` | max(`DetDopPak.Or_Kompl_Buh`) |
| 84 | `Det_Rash` | реализованные детали (найдены МХ-3) |
| 85 | `Det_RashBuh` | дата передачи реализации в бух. учёт |
| 86 | `Det_RashBuhCnt` | кол-во реализованных и в учёте |
| 87 | `VremId` | TrkRemPretens.VidRem |
| 88 | `Srok_PassDoc` | `fTHP_SrokDay(Dat_Pass, nvPretSrok IdOper=16)` |
| 89 | `Srok_PassDocColor` | 1/2/3 по превышению 10/30 рабочих дней |
| 90 | `PassDoc_Name` | TrkRemPretens |
| 91 | `PassDoc_Date` | TrkRemPretens |
| 92 | `Srok_FilG` | `fTHP_SrokDay(isnull(PassDoc_Date, Dat_Pass), IdOper=9)` |
| 93 | `Srok_FilGColor` | вычислено |
| 94 | `Srok_DoPret` | `fTHP_SrokDay(FilG_Get, IdOper=10)` |
| 95 | `Srok_DoPretColor` | вычислено |
| 96 | `Srok_PassPP` | `fTHP_SrokDay(…IdOper=11)`, 5-веточный CASE |
| 97 | `Srok_PassPPColor` | вычислено |
| 98 | `Srok_Pret` | `fTHP_SrokDay(Send_PD, IdOper=12)` |
| 99 | `Srok_PretColor` | вычислено |
| 100 | `Srok_PassSud` | `fTHP_SrokDay(isnull(Gar_Send, Dat_Send+14), IdOper=13)`; перезапись `Pret_Vozvrat_Dt+14` |
| 101 | `Srok_PassSudColor` | вычислено |
| 102 | `Srok_Sud` | `fTHP_SrokDay(Sud_PassDt, IdOper=14)` |
| 103 | `Srok_SudColor` | вычислено |
| 104 | `FilG_Name` | TrkRemPretens |
| 105 | `TypeVRP_Garant` | 'ВРК-1/2/3', 'ЦДРВ', 'ТВМ', 'ЦДИ', 'ВСЗ' (nsTHP_PrStamp) |
| 106 | `Type_Garant` | TrkRemPretens ('Аренда' для ФГК) |
| 107 | `Name_Garant` | TrkRemPretens / DOClient (ФГК) |
| 108 | `Rad_Garant` | `isnull(Rad_Garant,0)` (+default из DRVagTR.Prv для ФГК) |
| 109 | `Type_GarantShow` | CASE по Rad_Garant (TypeVRP_Garant либо Type_Garant) |
| 110 | `Vrp_GarantShow` | `isnull(VRP_Garant, PRemVRP)` (если Rad_Garant=0) |
| 111 | `Name_GarantShow` | gr1 либо Name_Garant |
| 112 | `Prim_Garant` | TrkRemPretens |
| 113 | `DoPret_Vozvrat_Dt` | TrkRemPretens |
| 114 | `DoPret_Vozvrat_NomRK` | TrkRemPretens |
| 115 | `DoPret_Nom` | TrkRemPretens |
| 116 | `DoPret_Dat` | TrkRemPretens |
| 117 | `DoPret_Sum` | TrkRemPretens |
| 118 | `DoPret_Send` | TrkRemPretens (ФГК: `isnull(DoPret_Send, DoPret_Dat)`) |
| 119 | `DoPret_Result` | TrkRemPretens (1/2/3) |
| 120 | `DoPret_Otvet_Nom` | TrkRemPretens |
| 121 | `DoPret_Otvet_Dat` | TrkRemPretens |
| 122 | `DoPret_PassPP_Dt` | всегда NULL (комментарий «удалить») |
| 123 | `DoPret_PassPP_Name` | TrkRemPretens |
| 124 | `DoPret_OtvSut` | `DateDiff(day, DoPret_Send, isnull(DoPret_Otvet_Dat, getdate()))` |
| 125 | `Sud_PassDt` | TrkRemPretens |
| 126 | `Sud_NomZ` | TrkRemPretens |
| 127 | `Sud_Dat` | TrkRemPretens |
| 128 | `Sud_NomD` | TrkRemPretens |
| 129 | `Sud_Result` | TrkRemPretens |
| 130 | `Sud_Sum` | `nullif(Sud_Sum,0)` |
| 131 | `Sud_SumSogl` | `nullif(Sud_SumSogl,0)` |
| 132 | `Sud_SumOtkaz` | `Sud_Sum − Sud_SumSogl` (если Sud_Result>0) |
| 133 | `Prich_Otkl` | TrkRemPretens (причина отклонения) |
| 134 | `OtchMonth` | `DRVagTR.OtchMonth` |
| 135 | `idlogin` | TrkRemPretens.IdLogin |
| 136 | `FIO` | `nvTRK_login.FIO` (IdLogin) |
| 137 | `Dat_Korr` | TrkRemPretens |
| 138 | `VRem_Nom` | TrkRemPretens / `VagPrivatRemOtpr` (фильтр плательщика) |
| 139 | `VRem_DT_Accredit` | TrkRemPretens / VagPrivatRemOtpr |
| 140 | `VRem_Sum` | TrkRemPretens; иначе `VRem_pl+VRem_Dob` (заполняется только при NULL — правило 04.12.2024); 0→null |
| 141 | `IzRem_Nom` | TrkRemPretens (пустая строка → NULL) / VagPrivatRemOtpr |
| 142 | `IzRem_DT_Accredit` | TrkRemPretens / VagPrivatRemOtpr |
| 143 | `IzRem_Sum` | TrkRemPretens / VagPrivatRemOtpr (`IzRem_pl+IzRem_Dob`) |
| 144 | `Tranz_Nom` | TrkRemPretens / VagPrivatRemOtpr (только если Dosil_Sum>0) |
| 145 | `Dosil_DT_Accredit` | `isnull(Dosil_DT_Accredit, Tranz_DT_Accredit)` |
| 146 | `Dosil_Sum` | `Tranz_Dob+Dosil_Dob` (если плательщик совпадает и stan53<>stan54) |
| 147 | `Tarif_NoPret` | TrkRemPretens; default: 0 если (VRem+IzRem+coalesce(Rasch,Dosil))>0, иначе 1 |
| 148 | `Tarif_NoPretChar` | 'подлежит'/'не подлежит' по тому же условию |
| 149 | `Tarif_PassDat` | TrkRemPretens |
| 150 | `Tarif_Sum` | `VRem_Sum+IzRem_Sum+coalesce(Rasch_Dosil_sum,Dosil_sum,0)` (если >0, иначе null) |
| 151 | `VRem_mOtprId` | VagPrivatRemOtpr |
| 152 | `VRem_DT_Accept` | VagPrivatRemOtpr |
| 153 | `IzRem_mOtprId` | VagPrivatRemOtpr |
| 154 | `IzRem_DT_Accept` | VagPrivatRemOtpr |
| 155 | `Tranz_mOtprId` | VagPrivatRemOtpr |
| 156 | `Tranz_DT_Accept` | VagPrivatRemOtpr |
| 157 | `Tranz_pl` | VagPrivatRemOtpr (0→null) |
| 158 | `Tranz_StanOtpr` | VagPrivatRemOtpr |
| 159 | `Tranz_StanOtprName` | `nsStan.Name` |
| 160 | `Tranz_Stan` | VagPrivatRemOtpr |
| 161 | `Tranz_StanName` | `nsStan.Name` |
| 162 | `stan53` | VagPrivatRem / VagPrivatRemJour |
| 163 | `Namestan53` | `nsStan.Name` |
| 164 | `stan54` | VagPrivatRem / VagPrivatRemJour |
| 165 | `Namestan54` | `nsStan.Name` |
| 166 | `ProstSut` | часы(Neispr_dt→Dat_Rem)/24, округление вверх при остатке >6 ч |
| 167 | `Porog` | 1 для вагонов ФГК из `TrkRemPretensColor`, иначе 0 (временная вещь) |
| 168 | `Sud_Dat_Korr` | TrkRemPretens |
| 169 | `Sud_IdLogin` | TrkRemPretens |
| 170 | `Sud_FIO_Korr` | `nvTRK_login` (Sud_IdLogin) |
| 171 | `Rasch_Dosil_sum` | TrkRemPretens (затем `isnull(Rasch_Dosil_sum, Dosil_sum)`) |
| 172 | `Rasch_Dosil_sum_Date_sys` | TrkRemPretens |
| 173 | `Rasch_Dosil_sum_FIO` | `nvTRK_login` (Rasch_Dosil_sum_IdLogin) |
| 174 | `Tranz_Dob` | VagPrivatRemOtpr (0→null) |
| 175 | `Dosil_Dob` | VagPrivatRemOtpr (0→null) |
| 176 | `IdPak` | `DetDopPak.IdPak` (ServiceType=3) |
| 177 | `Or_Pr_Dt` | `DetDopPak` |
| 178 | `Prich_OtklPak` | `DetDopPak` |
| 179 | `Or_Pr_Login` | `DetDopPak` |
| 180 | `Or_Pr_Login_FIO` | `nvTRK_login` |
| 181 | `Pak_Pr` | текст: 1='принят', 0='отклонён', 2='возврат', 3='на проверке', 4='возврат-1', 5='возврат-2', 6='принят-1', 7='принят-2' |
| 182 | `DateOtch` | дубль #134 |
| 183 | `Source` | `DRVagTRDoc.Source` (4→1 для ТК) |
| 184 | `Pret_Vozvrat_NomRK` | TrkRemPretens |
| 185 | `Pret_Vozvrat_Dt` | TrkRemPretens |
| 186 | `GarantKP` | `isnull(count(TrkPretensObodKP),0)` (ФГК) |
| 187 | `IdzapPret` | TrkRemPretens.IdZap |
| 188 | `Index_Pret` | TrkRemPretens |
| 189 | `PREmVRP1` | то же CASE, что #13, но по `r2.VRP` и `Neispr_dt < '20110701'` |
| 190 | `Depo_Rem_Akt` | TrkRemPretens |
| 191 | `KAgPret_Name` | `isnull(KAgPret_Name, CaseOneParticipants.Name)` |
| 192 | `KAgPret_Dog` | `ISNULL(KAgPret_Dog, DogNomer)` |
| 193 | `Vozm_Summ` | TrkRemPretens |
| 194 | `Straf_Summ` | `isnull(ProstSut, формула) * Straf_Sut` |
| 195 | `Tarif_Sum1` | дубль #150 |
| 196 | `CaseOneStatus` | TrkRemPretens |
| 197 | `CaseOneDate` | TrkRemPretens |
| 198 | `CaseOneGuid` | TrkRemPretens |
| 199 | `CaseOneError` | TrkRemPretens |
| 200 | `CaseOneStatusName` | 1='Передано', 7/8='Ошибка', 9='Ошибка с файлами' |
| 201 | `Straf_Sut` | TrkRemPretens |
| 202 | `ProstSut_Edit` | `isnull(ProstSut, формула)` (редактируемое значение) |
| 203 | `KAgPret_Dog_Dt` | TrkRemPretens |
| 204 | `KAgPret_Dog_Edit` | = #192 |
| 205 | `KAgPret_Dog_Dt_Edit` | `ISNULL(KAgPret_Dog_Dt, DogRem_Dat)` |
| 206 | `KAgPret_GUID` | TrkRemPretens |
| 207 | `KAgPret_GUID_Edit` | `isnull(KAgPret_GUID, CaseOneParticipants.ID)` |
| 208 | `KAgPret_Name_Edit` | = #191 |
| 209 | `Reestr_Nom` | TrkRemPretens |
| 210 | `Reestr_Date` | TrkRemPretens |
| 211 | `ID_Login_Reestr` | TrkRemPretens |
| 212 | `Date_Sys_Reestr` | TrkRemPretens |
| 213 | `Reestr_FIO` | `nvTRK_login` (ID_Login_Reestr) |
| 214 | `VU41_Nom` | TrkRemPretens |
| 215 | `VU41_Dat` | TrkRemPretens |
| 216 | `PSRMatNom` | TrkRemPretens |
| 217 | `PSRMatDate` | TrkRemPretens |
| 218 | `IsSngDor` | `nsDoroga.CountryID <> '0643'` → 1 (дорога не РФ) |
| 219 | `Model` | `nvVagPrivatArx.Model` |
| 220 | `Postr_dt` | `nvVagPrivatArx.Postr_dt` |
| 221 | `Postr_God` | `year(Postr_dt)` |
| 222 | `VRKLTekRem` | 'ВРК'+VRK по DepTekRem (kcmod.nsTovPr_ForOsv) |
| 223 | `DorLTekRem` | MNKD дороги последнего ТР |
| 224 | `DepoLTekRem` | `Str(DepTekRem,4)+' '+SName` |
| 225 | `DatLTekRem` | `VagPrivatRemBrak.Date_LastTR` (null если < Date_LastPlRem) |
| 226 | `VidLTekRem` | 3='ТР-1', 4='ТР-2' |
| 227 | `NeisprLTekRem` | `VagPrivatRemBrak.KodBrak_LastTR` |
| 228 | `ProbegLTekRem` | `VagPrivatRemDop` (ProbegPorogn+ProbegGruz на DatTekRem) |

## Вычисляемые поля (логика)

**Суммы:**
- `DatEndPret` = `Dat_Rem + 1 год` — срок предъявления претензии;
- `Sum_money` = оплаченная сумма; для ФГК fallback — `Sud_SumSogl` при полном
  судебном удовлетворении (`Sud_Sum = Sud_SumSogl`), иначе 0;
- `Nedopl_money` = (Stoim при ResultId=1; PriznRub при 3; DoPret_Sum при
  DoPret_Result=1) − Sum_money — недовозмещение;
- `PriznRub` = Stoim (полное принятие) либо PriznRub (частичное);
- `OtklRub` = Stoim (полное отклонение) либо Stoim − PriznRub (частичное);
- `SmotrRub` = Stoim при ResultId=0 (на рассмотрении);
- `Sud_SumOtkaz` = Sud_Sum − Sud_SumSogl (если Sud_Result > 0);
- `Straf_Summ` = `isnull(ProstSut, формула) * Straf_Sut` — штраф за простой;
- `Tarif_Sum` = VRem_Sum + IzRem_Sum + coalesce(Rasch_Dosil_sum, Dosil_sum, 0)
  (если >0, иначе null); `Tarif_NoPret/Char` — «подлежит/не подлежит
  перевыставлению» по тому же условию >0;
- `VRem_Sum`/`IzRem_Sum` из накладных `*_pl + *_Dob` (заполняются только если
  сохранённое значение NULL — правило от 04.12.2024: обнулённые значения
  уважаются, пересчитываются только NULL), фильтр плательщика
  (`isnull(*_Payer, @Payer) = @Payer`, для ФГК `'4000005146'`); 0 → null;
- `Dosil_Sum`/`Tranz_Dob`/`Dosil_Dob` — только если `stan53 <> stan54`
  (ломаный тариф) и плательщик совпадает.

**Даты/продолжительность:**
- `Gar_RassmSut` = дни(Gar_Get → isnull(Gar_Send, сегодня));
- `DoPret_OtvSut` = дни(DoPret_Send → isnull(DoPret_Otvet_Dat, сегодня));
- `ProstSut` = часы(Neispr_dt→Dat_Rem)/24, округление вверх при остатке >6 ч;
- `Dat_Pass` (авто для ФГК, только Index_Pret=1 и без пользовательской даты):
  ЦДИ без деталей → `isnull(Dat_Pass, Or_Kompl_Buh)`; ВРК/СНГ →
  `fTHP_SrokDay(isnull(Dat_Pass, Or_Kompl_Buh), 45, 2)` (45 раб. дней);
  ЦДИ с деталями → cap на `fTHP_SrokDay(Or_Kompl_Buh, 45, 2)`, не раньше
  Or_Kompl_Buh и только если основной пакет передан в бух. учёт.

**Сроки `Srok_*` + цвета `Srok_*Color`:** все считаются как
`fTHP_SrokDay(<базовая дата>, @Srok, @SrokType)`, где @Srok/@SrokType из
`nvPretSrok` по IdOper: 9 → Srok_FilG (база `isnull(PassDoc_Date, Dat_Pass)`),
10 → Srok_DoPret (база FilG_Get), 11 → Srok_PassPP (база — дата отказа/возврата/
`DoPret_Send+14`/дата пакета, 5-веточный CASE; только если DoPret_Result in
(0,2,3) и NoPret=0), 12 → Srok_Pret (база Send_PD), 13 → Srok_PassSud (база
`isnull(Gar_Send, Dat_Send+14)`, перезапись `Pret_Vozvrat_Dt+14` после возврата),
14 → Srok_Sud (база Sud_PassDt), 16 → Srok_PassDoc (база Dat_Pass).
Цвета: 1=жёлтый / 2=оранжевый / 3=красный по превышению 1/10/30 рабочих дней.

**Расшифровки кодов:** Result, NoPret, FilG_Sogl, Rekl_Sogl, VidRem, PRemVid,
OsnovName, Pak_Pr, CaseOneStatusName, pd3, Tarif_NoPretChar, VidLTekRem,
PREmVRK/PRemVRP1 (ЦДРВ/ВРК1/НВРК/ОМК/НВТ/ЦДИ/Завод), TypeVRP_Garant
(ВРК-1/2/3, ЦДРВ, ТВМ, ЦДИ, ВСЗ), Neispr_kod123 («000+000+000»), Neispr_name
(nsBrak; правило 12.08.2022: если первый код начинается с 9 — расшифровывается
второй: `left(Neispr_kod123,1)=9 → substring(Neispr_kod123,5,3)`, иначе KodBrakTn).

**Блок реализации деталей:** `#DetMX` заполняется из (a) сохранённых
расчётов перевыставления `DRVagTRPrZatrat` (SourceType=1, Type=3, Perev>0,
TipPr<>4) с разбором `fTHP_DetPart`; (b) пакетов хранения `DetMX`
(Vid_Rem=4, ServiceType=4, MXType 'МХ-1Х'/'Акт ТМЦ') — только если нет
сохранённого расчёта; (c) аналогично из ремонтов (ServiceType in (2,10)).
Реализация МХ-3 — cross apply по совпадающим TDet/Izg/Nom_Det/God и ВРП с
позднейшей Doc_Date. Детали КП — только если `TehKP=1` (проверка nvBrakGroup).

**Прочее:** `IdZap` (DRVagTR.IdZap по вагону+дате ремонта, Korr_dt is null;
fallback по Date53=Neispr_dt), `Rad_Garant` по умолчанию 1 для ФГК если
DRVagTR.Prv=1, `Source` из DRVagTRDoc (4→1 для ТрансКонтейнер),
`IdZap_Dr`+`DogNomer`/`DogRem_Dat` из последнего планового ремонта (drVagRem в
±`@dMon` месяцев от PRem_dt, затем drVagRemVRK→nvDrSprDogovor),
`korr_nom`/`Vag_GR`/`Model`/`Postr_dt` из nvVagPrivatArx (max Korr_nom до даты
ремонта), договор аренды `DogId/ClientId/Nomer_KT/Name_KT` тремя проходами
(аренда с выдачей Otvetstv=1 → аренда с приёмкой → любой договор),
`ProbegOtc` (VagPrivatRemDop, fallback последний VagPrivatRemJour с
Probeg_Norm>0), блок последнего ТР (VagPrivatRemBrak, только если
Date_LastTR >= Date_LastPlRem), `GarantKP` (ФГК: count TrkPretensObodKP),
`Porog` (ФГК: вагон в TrkRemPretensColor), `IsSngDor` (CountryID <> '0643'),
`DorogaId` ('??' → osv.DorogaId).

## Особенности, важные для переноса

1. **`@Reg = 0` не возвращает результат** — основной SELECT идёт только при
   `@Reg IS NULL`. В примере из issue на позиции 23 стоит null — ок.
2. **Начало периода исключительное** (`Dat_Rem > @Remont_dt_n`), конец —
   включительно +1 день.
3. Дубли в результате: `IdZap` (#1) ≡ `Or_IdZap` (#60); `OtchMonth` (#134) ≡
   `DateOtch` (#182); `KAgPret_Dog` ≡ `KAgPret_Dog_Edit`; `KAgPret_Name` ≡
   `KAgPret_Name_Edit`; `Tarif_Sum` (#150) ≡ `Tarif_Sum1` (#195).
4. `DoPret_PassPP_Dt` — всегда null (помечено «удалить»).
5. JOIN `nvd` (nvTRK_Departments) в финальном SELECT объявлен, но не
   используется (мёртвый).
6. `DepTekRemName` объявлен в `#TPret`, но никогда не заполняется.
7. `TrkRemPretensColor` (Porog) — явно временная конструкция.
8. `SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED` + зависимости от
   `getdate()` (Gar_RassmSut, Srok_*Color, DoPret_OtvSut) — результат
   зависит от момента выполнения.
9. Различия ФГК/ТК управляются `@KodKomplex` (89/90 = ФГК) и `@IsTK`
   (nvservernastr nastrid=3) — при переносе в новую систему (ФГК) берутся
   ветки ФГК.
10. Ветвление `@Reg = 1` (34 колонки) потребляется
    `pTHP_PretTehSelectDocVozmZatr` — если нужен отчёт «документы на
    возмещение затрат», его логика тоже придётся переносить.
