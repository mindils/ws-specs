# pThp_PretTehSelect2 — расчёт Srok_* и Srok_*Color (точный код)

Источник: `pThp_PretTehSelect2.sql` (полный текст процедуры), строки ~1030–1181.
Снято с MSSQL (rvk-ws) 2026-09-11. Все вызовы `dbo.fTHP_SrokDay` — см. `fTHP_SrokDay.sql`,
сроки/типы — из `dbo.nvPretSrok` (`nvPretSrok_idoper_9-16.md`, SrokType=2 = рабочие дни).

## Общая логика цвета (одинаковая для всех колонок)

Комментарий в процедуре перед блоком: `-- 1 - желтый, 2 - ?, 3 - красный`
(строка 1030: `-- 3 - красный`). Пороги — в **рабочих днях** относительно срока:

```sql
update #TPret set Srok_XColor = case
    when datediff(day, dbo.fTHP_SrokDay(Srok_X, 30, 2), <факт>) >  0 then 3  -- просрочка > 30 раб. дн.
    when datediff(day, dbo.fTHP_SrokDay(Srok_X, 10, 2), <факт>) >  0 then 2  -- просрочка 11..30 раб. дн.
    when datediff(day, dbo.fTHP_SrokDay(Srok_X,  1, 2), <факт>) >= 0 then 1  -- просрочка 1..10 раб. дн.
end
where Srok_X is not null
```

`<факт>` — дата завершения этапа, иначе `getdate()`. Иначе Color = NULL (не просрочен).

## Таблица: колонка → этап

| Колонка срока | IdOper (Srok) | Стартовая дата | Факт для цвета |
|---|---|---|---|
| Srok_PassDoc | 16 (2) | `Dat_Pass` | `coalesce(PassDoc_Date, Send_PD, FilG_Get, getdate())` |
| Srok_FilG | 9 (12) | `isnull(PassDoc_Date, Dat_Pass)` | `coalesce(Send_PD, FilG_Get, getdate())` |
| Srok_DoPret | 10 (10) | `FilG_Get` | `isnull(DoPret_Send, getdate())` |
| Srok_PassPP | 11 (19) | 5 веток, см. ниже | `isnull(Send_PD, getdate())` |
| Srok_Pret | 12 (14) | `Send_PD` | `isnull(Dat_Send, getdate())` |
| Srok_PassSud | 13 (4) | `isnull(Gar_Send, Dat_Send+14)`, override `Pret_Vozvrat_Dt+14` | `coalesce(Sud_PassDt, Sud_Dat, getdate())` |
| Srok_Sud | 14 (14) | `Sud_PassDt` | `isnull(Sud_Dat, getdate())` |
| (нет колонки) Srok_FilOColor | — | `Dat_Pass` (срок не из справочника) | `getdate()` |

## Точный код блоков

### Предыстория Dat_Pass (45 рабочих дней, строки ~1001–1019)

`Dat_Pass` — стартер для Srok_PassDoc/Srok_FilG/Srok_FilOColor — сам может
подменяться датой окончания «ожидания реализации» (45 рабочих дней от `Or_Kompl_Buh`):

```sql
else dbo.fTHP_SrokDay(isnull(Dat_Pass, Or_Kompl_Buh), 45, 2) --прибавляем 45 рабочих дней
...
update #TPret set Dat_Pass=case when Det_prv>isnull(Det_RashBuhCnt, 0) and dbo.fTHP_SrokDay(Or_Kompl_Buh, 45, 2)<=@Today then dbo.fTHP_SrokDay(Or_Kompl_Buh, 45, 2) --конец ожидания реализации
    when dbo.fTHP_SrokDay(Or_Kompl_Buh, 45, 2)<isnull(Det_RashBuh, @Today) then dbo.fTHP_SrokDay(Or_Kompl_Buh, 45, 2) --дата реализации вышла за границу 45 дней
...
    and (Det_prv=Det_RashBuhCnt or dbo.fTHP_SrokDay(Or_Kompl_Buh, 45, 2)<=@Today)
```

### Srok_PassDoc — срок прикрепления комплекта документов (IdOper 16, Srok=2)

```sql
select @Srok = null, @SrokType = null
select top 1 @Srok = Srok, @SrokType = SrokType from dbo.nvPretSrok where IdOper = 16;
update #TPret set Srok_PassDoc = dbo.fTHP_SrokDay(Dat_Pass, @Srok, @SrokType)
	where Dat_Pass is not null
update #TPret set Srok_PassDocColor = case
		when datediff(day, dbo.fTHP_SrokDay(Srok_PassDoc, 30, 2), coalesce(PassDoc_Date, Send_PD, FilG_Get, getdate())) > 0 then 3
		when datediff(day, dbo.fTHP_SrokDay(Srok_PassDoc, 10, 2), coalesce(PassDoc_Date, Send_PD, FilG_Get, getdate())) > 0 then 2
		when datediff(day, dbo.fTHP_SrokDay(Srok_PassDoc, 1, 2), coalesce(PassDoc_Date, Send_PD, FilG_Get, getdate())) >= 0 then 1
	end
	where Srok_PassDoc is not null
```

### Srok_FilG — передача документов в допретензионную работу (IdOper 9, Srok=12)

Назначается ТОЛЬКО вагонам в аренде без договора на последний плановый ремонт
(`Nomer_KT is not null and isnull(DogNomer,'')=''`); остальным сразу Srok_PassPP.

```sql
select top 1 @Srok = Srok, @SrokType = SrokType from dbo.nvPretSrok where IdOper = 9;
update #TPret set Srok_FilG = dbo.fTHP_SrokDay(isnull(PassDoc_Date,Dat_Pass), @Srok, @SrokType)
	where isnull(NoPretId, 0) = 0 and isnull(PassDoc_Date,Dat_Pass) is not null
	      and (FilG_Get is not null or Send_PD is null) --срок переносим к передаче в претензионную работу, если прямо передано в претез., минуя допретенз.
	      and (Nomer_KT is not null and isnull(DogNomer, '')='')
update #TPret set Srok_FilGColor = case
		when datediff(day, dbo.fTHP_SrokDay(Srok_FilG, 30, 2), coalesce(Send_PD, FilG_Get, getdate())) > 0 then 3
		when datediff(day, dbo.fTHP_SrokDay(Srok_FilG, 10, 2), coalesce(Send_PD, FilG_Get, getdate())) > 0 then 2
		when datediff(day, dbo.fTHP_SrokDay(Srok_FilG, 1, 2), coalesce(Send_PD, FilG_Get, getdate())) >= 0 then 1
	end
	where Srok_FilG is not null
```

### Srok_DoPret — срок предъявления допретензионного письма (IdOper 10, Srok=10)

```sql
select @Srok = null, @SrokType = null
select top 1 @Srok = Srok, @SrokType = SrokType from dbo.nvPretSrok where IdOper = 10;
update #TPret set Srok_DoPret = dbo.fTHP_SrokDay(FilG_Get, @Srok, @SrokType)
	where isnull(NoPretId, 0) = 0 and FilG_Get is not null
	      --не назначаем срок предъявления письма, если уже есть передача в претензионный отдел
	      and (Send_PD is null or DoPret_Send is not null)
	      and FilG_Name<>'ДКФ'
update #TPret set Srok_DoPretColor = case
		when datediff(day, dbo.fTHP_SrokDay(Srok_DoPret, 30, 2), isnull(DoPret_Send, getdate())) > 0 then 3
		when datediff(day, dbo.fTHP_SrokDay(Srok_DoPret, 10, 2), isnull(DoPret_Send, getdate())) > 0 then 2
		when datediff(day, dbo.fTHP_SrokDay(Srok_DoPret, 1, 2), isnull(DoPret_Send, getdate())) >= 0 then 1
	end
	where Srok_DoPret is not null
```

### Srok_PassPP — передача документов в претензионную работу (IdOper 11, Srok=19)

5 веток стартовой даты (важнейшие отличия от пересказа в спецификации):

```sql
select @Srok = null, @SrokType = null
select top 1 @Srok = Srok, @SrokType = SrokType from dbo.nvPretSrok where IdOper = 11;
update #TPret
       set Srok_PassPP = case when DoPret_Otvet_Dat is not null and isnull(DoPret_Result, 2) in (2, 3)
							  then dbo.fTHP_SrokDay(DoPret_Otvet_Dat, @Srok, @SrokType) --срок от даты получения отказа

							  when Pret_Vozvrat_Dt is not null
							  then dbo.fTHP_SrokDay(Pret_Vozvrat_Dt, @Srok, @SrokType) --срок от даты возврата (22.11.2021 Малкиева)

                              when DoPret_Send is not null
                              then dbo.fTHP_SrokDay(DoPret_Send + 14, @Srok, @SrokType) --срок от даты отправки письма (+14 календарных дней)

                              when FilG_Get is null and Send_PD is not null --прямая передача в претензионную, минуя допретенз.
                              then dbo.fTHP_SrokDay(isnull(PassDoc_Date,Dat_Pass), @Srok, @SrokType)

                              else dbo.fTHP_SrokDay(isnull(FilG_Get, isnull(PassDoc_Date,Dat_Pass)), @Srok, @SrokType) --от даты передачи в допретенз. без отправки письма
                              end
where isnull(NoPretId, 0) = 0 and isnull(PassDoc_Date,Dat_Pass) is NOT NULL
      and isnull(DoPret_Result, 0) in (0, 2, 3) --полный/частичный отказ или отсутствие ответа по допретенз. обращению
      and (DoPret_Send is not null  --срок от даты отправки письма виновнику
           or FilG_Get is not null and DoPret_Send is null and Send_PD is not null
           or FilG_Get is null and Send_PD is not null
           or Nomer_KT is null --вагоны без аренды - прямая передача в претензионную
           or DogNomer is not null) --вагоны после нашего планового - прямая передача в претензионную

update #TPret set Srok_PassPPColor = case
		when datediff(day, dbo.fTHP_SrokDay(Srok_PassPP, 30, 2), isnull(Send_PD, getdate())) > 0 then 3
		when datediff(day, dbo.fTHP_SrokDay(Srok_PassPP, 10, 2), isnull(Send_PD, getdate())) > 0 then 2
		when datediff(day, dbo.fTHP_SrokDay(Srok_PassPP, 1, 2), isnull(Send_PD, getdate())) >= 0 then 1
	end
	where Srok_PassPP is not null
```

### Srok_Pret — срок предъявления претензии контрагенту (IdOper 12, Srok=14)

```sql
select @Srok = null, @SrokType = null
select top 1 @Srok = Srok, @SrokType = SrokType from dbo.nvPretSrok where IdOper = 12;
update #TPret set Srok_Pret = dbo.fTHP_SrokDay(Send_PD, @Srok, @SrokType)
where isnull(NoPretId, 0)=0
      and Send_PD is not null

update #TPret set Srok_PretColor = case
		when datediff(day, dbo.fTHP_SrokDay(Srok_Pret, 30, 2), isnull(Dat_Send, getdate())) > 0 then 3
		when datediff(day, dbo.fTHP_SrokDay(Srok_Pret, 10, 2), isnull(Dat_Send, getdate())) > 0 then 2
		when datediff(day, dbo.fTHP_SrokDay(Srok_Pret, 1, 2), isnull(Dat_Send, getdate())) >= 0 then 1
	end
	where Srok_Pret is not null
```

### Srok_PassSud — срок передачи в судебную работу (IdOper 13, Srok=4)

База — `isnull(Gar_Send, Dat_Send + 14)` (+14 календарных дней от даты отправки
претензии, если нет `Gar_Send`); при возврате претензии срок ПЕРЕзаписывается на
`Pret_Vozvrat_Dt + 14`:

```sql
select @Srok = null, @SrokType = null
select top 1 @Srok = Srok, @SrokType = SrokType from dbo.nvPretSrok where IdOper = 13;
update #TPret set Srok_PassSud = dbo.fTHP_SrokDay(isnull(Gar_Send, Dat_Send + 14), @Srok, @SrokType)
where isnull(NoPretId, 0)=0
      and Dat_Send is not null
      and isnull(ResultId,2) in (2, 3)
--22.11.2021 Малкиева новый срок если был возврат
update #TPret set Srok_PassSud = dbo.fTHP_SrokDay(Pret_Vozvrat_Dt+14, @Srok, @SrokType)
where Pret_Vozvrat_Dt is not null and Pret_Vozvrat_Dt>Send_PD

update #TPret set Srok_PassSudColor = case
		when datediff(day, dbo.fTHP_SrokDay(Srok_PassSud, 30, 2), coalesce(Sud_PassDt, Sud_Dat, getdate())) > 0 then 3
		when datediff(day, dbo.fTHP_SrokDay(Srok_PassSud, 10, 2), coalesce(Sud_PassDt, Sud_Dat, getdate())) > 0 then 2
		when datediff(day, dbo.fTHP_SrokDay(Srok_PassSud, 1, 2), coalesce(Sud_PassDt, Sud_Dat, getdate())) >= 0 then 1
	end
	where Srok_PassSud is not null
```

### Srok_Sud — срок подачи искового заявления (IdOper 14, Srok=14)

```sql
select @Srok = null, @SrokType = null
select top 1 @Srok = Srok, @SrokType = SrokType from dbo.nvPretSrok where IdOper = 14;
update #TPret set Srok_Sud = dbo.fTHP_SrokDay(Sud_PassDt, @Srok, @SrokType)
	where isnull(NoPretId, 0) = 0 and isnull(ResultId, 2) in (2, 3) and Sud_PassDt is not null
update #TPret set Srok_SudColor = case
		when datediff(day, dbo.fTHP_SrokDay(Srok_Sud, 30, 2), isnull(Sud_Dat, getdate())) > 0 then 3
		when datediff(day, dbo.fTHP_SrokDay(Srok_Sud, 10, 2), isnull(Sud_Dat, getdate())) > 0 then 2
		when datediff(day, dbo.fTHP_SrokDay(Srok_Sud, 1, 2), isnull(Sud_Dat, getdate())) >= 0 then 1
	end
	where Srok_Sud is not null
```

### Srok_FilOColor — «просроченные документы» (без колонки срока, 08.09.2020 Лапунов)

Срок не берётся из nvPretSrok: порог считается прямо от `Dat_Pass` (1/10/30 раб. дн.),
это «зависшие» комплекты, по которым не было ни прикрепления, ни передачи:

```sql
update #TPret set Srok_FilOColor = case
		when datediff(day, dbo.fTHP_SrokDay(Dat_Pass, 30, 2), getdate()) > 0 then 3
		when datediff(day, dbo.fTHP_SrokDay(Dat_Pass, 10, 2), getdate()) > 0 then 2
		when datediff(day, dbo.fTHP_SrokDay(Dat_Pass, 1, 2), getdate()) >= 0 then 1
	end
	where Dat_Pass is not null and PassDoc_date is null and FilG_Get is null and Send_PD is null
```

## Куда дальше идут колонки

- В итоговый SELECT (строки ~1398–1412): `Srok_PassDoc, Srok_PassDocColor,
  Srok_FilG, Srok_FilGColor, Srok_DoPret, Srok_DoPretColor, Srok_PassPP,
  Srok_PassPPColor, Srok_Pret, Srok_PretColor, Srok_PassSud, Srok_PassSudColor,
  Srok_Sud, Srok_SudColor` (+ `Srok_FilOColor`).
- В счётчики фильтров (@Col, строки ~1612–1710): `Has_Srok_*` и наборы
  `Srok_*_Kol` (есть срок), `Srok_*_Nar` (Color > 0), `Srok_*_Nar_10` (Color = 1),
  `Srok_*_Nar_11_30` (Color = 2), `Srok_*_Nar_31` (Color = 3), варианты `_Ar`
  дополнительно с `Rad_Garant = 1`; `Srok_NotFull_Kompl` =
  `Or_Kompl_Buh is not null and Dat_Pass is null`; `Srok_FilO_*` — по Srok_FilOColor;
  `Srok_FilO_PerV` = `isnull(Tarif_NoPret,0)=0 and Tarif_PassDat is null`.
