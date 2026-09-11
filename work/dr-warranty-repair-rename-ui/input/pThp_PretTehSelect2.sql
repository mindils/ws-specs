-- Источник: OBJECT_DEFINITION(OBJECT_ID('dbo.pThp_PretTehSelect2')) на MSSQL (rvk-ws), снято 2026-09-11
-- Расчёт Srok_* / Srok_*Color: строки ~1030-1181 (см. srok-calc-notes.md)



/***********************30.09.2014 Афанасьева Т.
* Выбор данных по претензиям по технологическим неисправностям
* ВагТК: "Оплата ремонтов / Претензии / Технологические / по вагонам"
* Переделано из процедуры [dbo].[pThpPA_UpvrTnW]
* 03.04.15 Афанасьева: подставляем @Id_Dep пользователя вместо департамента по отцепке и по виновнику,
*          если пользователю разрешены корректировки этих блоков (для определения доступов на форме "Редактирование претензии").
* 28.04.15 Афанасьева: отключена связка с таблицей приема TRKVagRemPriem (на форме не найдено использование этой колонки) 
*          В случае необходимости эти данные надо получать по update временной таблицы
*          (возникают задвоения записей)        
* 20.05.16 Афанасьева: Отображение признака "нет в оплате"
* 15.09.16 Афанасьева: Изменение привязки договора аренды через outer apply
* 14.11.2016 Хромов А.В. обработка поля DODogovorInf.Otvetstv
* 25.01.2017 Осмоловский В.В. Добавлено поле "Договор" для номера договора, по которому вагон проходил последний плановый ремонт.
* 20.04.2017 Афанасьева: определение nvVagPrivatArx.Korr_nom через сгруппированный select (старый вариант через подселект на ФГК зависал и не дожидались)
* 19.05.2017 Хромов А.В. Добавлено выходное поле Prim_Neispr
* 27.07.2017 Осмоловский В.В.  по согласованию с Романовым    
*            Для тех вагонов, по которым не найдены договора ПЕРЕДАЧИ или ПРИЕМА в аренду, по которым ответственность за ремонт в явном виде несет ФГК   
*            (DODogovorInf.Otvetstv=0) ищем договор, в который вагон был включен на дату ремонта
* 17.10.2017 Афанасьева: получаем IdZap из drVagRem последнего планового ремонта для более корректного заполнения номера Договора             
* 12.06.2018 Афанасьева: дата договора на ремонт     
* 15.06.2018 Афанасьева: Собираеем данные по реализации деталей из МХ-1-Х
* 21.06.2018 А.А.Валуев: В поле Det_prv добавлено количество перевыставлений, если нет ручных корректировок на форме "Возмещение затрат".
* 25.06.2018 А.А.Валуев: Добавлен расчёт выходных полей Det_Dop, Det_DopBuh, Det_Rash и Det_RashBuh.
* 27.06.2018 А.А.Валуев: Добавлено выходное поле VremId.
* 27.06.2018 Афанасьева: Определяем дату формирования полного пакета        
* 03.07.2018 А.А.Валуев: Исправлена ошибка выборки деталей из DetMX.
* 04.07.2018 Афанасьева: сроки передачи
* 11.07.2018 Афанасьева: срок передачи документов в допретензионную работу закрывается, если есть передача в претензионную.
* 12.07.2018 А.А.Валуев: Добавлен срок передачи искового заявления. Подкраска в зависимости от рабочих дней.
* 13.07.2018 А.А.Валуев: Исправлен расчёт сроков. Добавлен параметр @Reg.
* 16.07.2018 А.А.Валуев: Добавлен параметр @Col. Добавлено значение для параметра @DorogaRemontID = 'МП'.
* 16.07.2018 Осмоловский: Изменена привязка таблиц из-за задвоения СВР И ЮУР
* 18.07.2018 А.А.Валуев: Исправлен расчёт срока передачи в допретензионную работу.
* 30.07.2018 А.А.Валуев: При поиске ремонта для МХ-3 учтено, что в таблице DetMX теперь есть и плановые ремонты.
* 31.07.2018 А.А.Валуев: Исправлен фильтр по филиалу.
* 01.08.2018 А.А.Валуев: Исправлен расчёт количества МХ-3 для перевыставленных деталей (реализация). Добавлено выходное поле Rad_Garant для @Reg = 1. Добавлены новые варианты в @Col.
* 21.08.2018 Афанасьева: уточнение связи между пакетами для определения реализации деталей
* 21.08.2018 Афанасьева: если в оплате ТР стоит "перевыставление"="да", то для ФГК по умолчанию идет виновник - аренда
* 28.08.2018 Афанасьева: уточнение сроков по допретензионному разделу.
* 19.10.2018 Афанасьева: по звонку Романова от имени Быковича 
*            срок допретензионной работы назначается только тем вагонам, у к-рых есть договор аренды и нет договора на выполнение последнего планового ремонта.
		     Остальным сразу назначается срок претензионной работы
* 01.11.2018 А.А.Валуев Вагоны, у которых есть срок передачи в претензионную работу, но нет передачи в допретензионную работу, перенесены из блока 16-20 в соответствующие колонки блока 2-10.
* 01.11.2018 А.А.Валуев ДЭПС показываем как московский филиал.
* 10.01.2019 Хромов А. Изменения для договоров аренды с учётом периода действия.
* 20.06.2019 А.А.Валуев Исправлена ошибка определения перевыставления деталей, из-за которой неправильно возвращалось количество ремонтов.
* 28.07.2019 Афанасьева: для ФГК дата отправки виновнику по умолчанию доопределяется, как дата составления 
*                        в разделах допретензионного обращения и претензионной работы (заказ 247)
* 20.03.2020 Лапунов А.В. Добавлена колонка причина отклонения
* 30.03.2020 Лапунов А.В. Добавляем колонки IdZap и OtchMonth из DrVagTR
* 19.05.2020 Афанасьева: Дата формирования комплекта - не позже 45 раб.дней от даты передачи в бух. (Быкович письмо 27.04.2020)
* 20.05.2020 Афанасьева: проверка наличия технологической неисправности по КП
* 23.07.2020 Афанасьева: исправлено определение даты формирования полного комплекта в случае просрочки реализации 45 дней
* 12.08.2020 Малкиева Срок прикрепления комплектя документов.
* 04.09.2020 Лапунов А.В. Добавлен фильтр по колонке Srok_NotFull_Kompl
* 08.09.2020 Лапунов А.В. Добавлены фильтр по колонкам Srok_FilO_Kol, Srok_FilO_Nar, Srok_FilO_Nar_10, Srok_FilO_Nar_11_30, Srok_FilO_Nar_31
* 20.10.2020 Хромов А.В. Добавлены поля раздела "Передислокация вагона в/из ремонта".
* 26.10.2020 Хромов А.В. Добавлены поля для отчёта "Справка об отправке".
* 28.10.2020 Лапунов А.В. Добавлены фильтр по колонкe Srok_FilO_PerV и поле простой в ремонте в сутках ProstSut
* 02.11.2020 Хромов А.В. Добавлены поля для отчёта "Реестр провозных платежей по ломанному тарифу".
* 03.11.2020 Афанасьева: Плательщик по накладным в/из ремонта
* 10.11.2020 Лапунов А.В. Исправлен расчет простоя
* 26.11.2020 Лапунов А.В. Исправлена размерность поля Or_Prim
* 01.12.2020 Лапунов А.В. Добавлена раскраска вагонов для ФГК по списку в таблице TrkRemPretensColor вещь ВРЕМЕННАЯ ипотребует удаления!!!!!
* 31.03.2021 Хромов А.В. Выходные колонки, кто редактировал судебную работу
* 08.04.2021 Лапунов А.В. Добавлены колонки Rasch_Dosil_sum, Rasch_Dosil_sum_IdLogin, Rasch_Dosil_sum_Date_sys
* 30.04.2021 Лапунов А.В. По просьбе ФГК добавляем вот такую логику - на все разделы («Допретензионная работа», «Претензионная работа», «Судебная работа») в случае внесения данных по оплате в полном объеме, 
*                                                                    то процесс должен логически завершиться и не отображаться как не отработанный, в ожидании передачи на следующий этап организации работ по возмещению затрат.
* 05.05.2021 Лапунов А.В. По просьбе ФГК добавляем следующую логику -  если есть сумма по удовлетворено (блок судебной работы), 
*																			то автоматически подтягивается сумма, дата оплаты - дата внесение соответствующего изменения, номер платежа – ФИО вносившего изменения
* 06.06.2021 А.А.Валуев При поиске учтены доппакеты МХ-1.
* 07.07.2021 Афанасьева: если сам пакет не передан в бух, то не назначаем срок формирования комплекта по реализации деталей
* 29.07.2021 Хромов А.В. добавлен блок колонок по состоянию пакета рекламации: 	  Состояние комплекта; Причина отклонения; Дата проверки; ФИО.
* 07.09.2021 Афанасьева - не сдвигаем дату формировани комплекта в прошлое от даты передачи в бухгалтерию.
* 18.10.2021 Хромов А.В. Добавлены параметры: @FilG_NameVar, @Start2, @Finish2
* 19.11.2021 Лапунов А.В. Добавлены поля Pret_Vozvrat_NomRK и Pret_Vozvrat_Dt 
* 22.11.2021 Малкиева новый срок передачи в суодебную и претензионную работы если был возврат
* 06.12.2021 Лапунов А.В. Добавлен фильтр по гарантийным КП
* 08.12.2021 Лапунов А.В. Всвязи с реорганизацией таблицы TrkRemPretens в выходной набор добавляем поля IdZap, Index_Pret
* 10.12.2021 Лапунов А.В. Dat_Pass определяем только для обычных претензий
* 28.12.2021 Лапунов А.В. Доопределяем @Id_Login если он null
* 12.01.2022 Лапунов А.В. Исправление доопределения Dat_Money
* 13.01.2022 Лапунов А.В. добавил фильтр, когда департамент не верхнего уровня для пономерных списков
* 19.01.2022 Лапунов А.В. исправлен фильтр для пономерных списков - при вызове в режиме только просмотр ограничения по филиалам не действуют
* 02.03.2022 Афанасьева - добавлена дата отправки допрет.письма в режиме выбора для временной таблицы
* 11.09.2022 Афанасьева: при склеивании разбраковок дата браковки в VagPrivatRemOtpr может сползти в прошлое, нужно привязывать на попадание в диапазон
* 01.06.2022 Афанасьева: сохраняем пользовательскую дату формирования пакета
* 14.07.2022 Хромов А.В. Добавлены добавлена расшифровка кодов ремонта не только ТР1,2
* 12.08.2022 Осмоловский: Если первый код неисправности на 9, расшифровываем вторую неисправность
* 15.08.2022 Лапунов А.В. Код неисправности теперь в виде 000+000+000
* 13.10.2022 Хромов А.В. Добавлены варианты @DorogaRemontID='999' и @dorVin='999'
* 27.03.2023 Хромов А.В. Доопределение дороги (case when r.DorogaId='??' then osv.DorogaId else r.DorogaId end)
* 27.06.2023 Малкиева: добавление полей по заказу ФГК 324 - Реестр претензий
* 12.07.2023 Хромов А.В.  Добавлены поля для окна редактирования
* 26.07.2023 Хромов А.В. Reestr_Nom,Reestr_Date,ID_Login_Reestr,Date_Sys_Reestr, VU41_Nom, VU41_Dat
* 09.08.2023 Хромов А.В. Добавлены фильтры по реестру ДЮ
* 14.08.2023 Осмоловский: Пробег на момент отцепки
* 04.10.2023 Хромов А.В. доопределение Dat_Money и Sum_money Только для ФГК
* 29.03.2024 Хромов А.В. Добавлена выходная колонка Model вагона
* 16.04.2024 Хромов А.В. Добавлена выходная колонка Postr_dt вагона
* 23.04.2024 Малкиева убрала пустоту в строке
* 03.05.2024 Гавриялко К.Г Выдаем сохраненные значения
* 20.05.2024 Гавриялко К.Г По для ФГК все дороги СНГ под одним названием
* 03.06.2024 Лапунов А.В. Добавлена колонка Prim_Garant
* 07.06.2024 Малкиева добавила промерку на ''
* 29.10.2024 Хромов А.В. Добавлена выходная колонка Postr_God вагона
* 04.12.2024 Лапунов А.В. По письму Тимонина от 03.12.2024 считаем что в притензиях можно обнулить VRem_Sum  и доопределяем ее только если она null
* 26.11.2025 Осмоловский Данные о последнем ТР на дату отцепки
* 08.12.2025 Хромов В выходном select поправлено isnull(r2.VRP_Garant, r2.PRemVRP) end as Vrp_GarantShow 
**************************/
-- EXEC dbo.pThp_PretTehSelect2 '20180813','20180801','76',null,-1,0,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
-- EXEC dbo.pThp_PretTehSelect2 '20180429','20180402',null,null,-1,0,null,null,null,null,null,null,null,null,null,null,null,null,null,null,null
-- EXEC dbo.pThp_PretTehSelect2 '20200803','20200801',null,null,-1,0,null,null,null,null,null,null,null,null,null,null,null,0,null,null,null,null,null,null,null
-- exec pThp_PretTehSelect2 '20230707', '20230701', null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null, 0, null, null, null, null, null, null, null, null, null, null, null
CREATE PROCEDURE [dbo].[pThp_PretTehSelect2]
	  @Remont_dt_k smalldatetime = null,       -- дата ремонта конец gggg-mm-dd
	  @Remont_dt_n smalldatetime = '1900-01-01',  -- дата ремонта начало gggg-mm-dd
	  @DorogaRemontID varchar(3)=null,               -- код дороги ремонта	
	  @Nom_Vag char(8) = null,                    -- номер вагона    
	  -- 	признак выборки для режимов редактирования
	  @Id_Login int = null, --ид. пользователя
	  @RegRed tinyint = 0, --режим редактирования (6 - выставление, 12 - претензия, 10 - виновник)
	  --30.01.13 Афанасьева
	  @Nom_Pret varchar(100)=null, --маска номера претензии
	  @IdSpis int = null, --ид. списка
      @DatBrakBegin smalldatetime = null, -- Период браковки
      @DatBrakEnd   smalldatetime = null,
	  
	  @vrp int             = null,
	  @vrpVin int          = null,
	  @dorVin varchar(3)      = null,
	  @vrk tinyint         = null,
	  @checkKodBrak tinyint= null,
	  @checkOtpr tinyint   = null,
	  @kodPret tinyint     = null,
	  @nopret  tinyint     = null,
	  @VidRem  tinyint     = null,
	  @result  varchar(10) = null,
	  @PRemVid varchar(10) = null,
	  @verParams tinyint   = null,
	  @Reg tinyint         = null, --Режим выборки (null - обычная выборка, 1 - выборка для процедуры pTHP_PretTehSelectDocVozmZatr).
	  @Col varchar(100)    = null, --Колонка отчёта, для которой нужно отфильтровать результат.
	  @ID_Department int   = null, --Филиал, для которого формируется результат.
	--18.10.2021 Хромов А.В.
	@FilG_NameVar varchar(50)= null, -- Наименование подразделения (ДКФ, ОАПС, филиал)
	@Start2 smalldatetime= null, --Дата передачи в допретензионную работу (начало периода).
	@Finish2 smalldatetime= null, --Дата передачи в допретензионную работу (окончание периода).
	@GarantKP tinyint=null
	--09.08.2023 Хромов 
   ,@Reestr_NomDU varchar(50)  = null
   ,@DatBeginDU smalldatetime  = null
   ,@DatEndDU   smalldatetime  = null
   ,@NomPSR varchar(50)        = null
   ,@DatBeginPSR smalldatetime = null
   ,@DatEndPSR   smalldatetime = null
AS
	SET NOCOUNT ON
	SET TRANSACTION ISOLATION LEVEL READ UNCOMMITTED

	declare @IsTK tinyint --ТК или нет.
	select @IsTK = case when (select data from dbo.nvservernastr where nastrid = 3) like '%ТрансКонтейнер%' then 1 else 0 end

	declare @resIds table(id tinyint);
	declare @PRemVidIds table(id tinyint);
	if @result is not null begin
		if CHARINDEX('1', @result) > 0 insert into @resIds values (1);
		if CHARINDEX('2', @result) > 0 insert into @resIds values (2);
		if CHARINDEX('3', @result) > 0 insert into @resIds values (3);
	end;
	if @PRemVid is not null begin
		if CHARINDEX('1', @PRemVid) > 0 insert into @PRemVidIds values (1);
		if CHARINDEX('2', @PRemVid) > 0 insert into @PRemVidIds values (2);
		if CHARINDEX('5', @PRemVid) > 0 insert into @PRemVidIds values (5);
	end;
	--select * from @resIds
	
    DECLARE @Kz int --= 0
    SET @Kz = 0 
    DECLARE @Mes varchar(255) 
	--условия
	declare @CPretensRem  smallint --= 1 -- ремонт
	SET @CPretensRem = 1
	DECLARE @KodPretesPovrejd tinyint
	SET @KodPretesPovrejd = 3          -- повреждение  pai20120827
	
	declare @Korr_pr_del  tinyint --1-строка удалена "логически"
	SET @Korr_pr_del = 1
	declare @BrakVid_ev3  smallint --Вид брака
	SET @BrakVid_ev3 = 3
		
	declare @t0 datetime, @t1 datetime, @t2 datetime, --засекаем время
			@Kol int, @Today smalldatetime
	set @t1 = getdate()
	select @t0=@t1, @Today=@t1
	print 'Начало... '

	if @RegRed is null set @RegRed = 0;
	
	-- 28.12.2021 Лапунов А.В.
	Select @Id_Login=isnull(@Id_Login,-1)
	
	------------------------Код комплекса для особой обработки доступов по ВГК
	declare @KodKomplex int
	select @KodKomplex = Data from kcmod.dbo.nvServerNastr where nastrID = 72

	if @Nom_Pret is not null set @Nom_Pret = replace (@Nom_Pret, '*', '%')
	
	----------------АТ 19.09.12 Дороги для режима корректировок 01.04.2015 Новиков Д.В выбор дорог по новой структуре
	
	 CREATE TABLE #deps(ID  int Identity (1,1),Id_Dep smallint)
		insert INTO #deps  select ID_Department from nvTRK_Departments dp where dp.leveldep in (1,2)
		CREATE TABLE #ddn(DorogaId	Char(2),Id_Dep smallint)
		declare @i smallint 
		declare @k smallint

		set @i=1

		WHILE @i <= (select COUNT(*) from #deps)
		Begin
			set @k = (select Id_Dep from #deps where ID=@i)
			insert INTO #ddn select dd.DorogaId,@k from nvtrk_dd dd left join nvTRK_Departments dep on dep.ID_Department = dd.Id_Dep where dep.ID_Department=@k OR dep.ID_Parent = @k
			set @i=@i+1
		end
	
	declare @TDor table (Dor char (2))
	declare @Id_Dep smallint, @Centr TINYINT
	select @Id_Dep = ID_Department from dbo.nvTRK_Login where ID_Login=@Id_Login
	
	-----03.04.15 Вынесено из режима редактирования (@RegRed>0) для всех режимов
	-- чтобы можно было вызвать форму "Редактирование претензии" из режима просмотра (для определения доступов на форме "Редактирование претензии")
	if @Id_Login>0
	begin
		select @Centr = case when D.ID_Parent is null then 1 else 0 end
				  from dbo.nvTRK_Departments D where D.ID_Department=@Id_Dep
		if @Centr = 0 	    	   	   
		   insert into @TDor 
				  select DD.DorogaId from #ddn DD where DD.Id_Dep=@Id_Dep
	end			 
	if @RegRed>0 and @Id_Login>0
	BEGIN
	   --Для Трансконтейнера режим редактирования по виновнику относим к первому филиалу
	   declare @NameTK varchar(30)
	   select @NameTK=data from dbo.nvservernastr where nastrid=3
	   if @NameTK='ПАО"ТрансКонтейнер"' and @RegRed=10 set @RegRed=12
	   --if @RegRed=10 set @RegRed=12 --с 10.11.14 ВГК тоже все вводят по филиалу ТОР
	END
	 

	print 'Заполняем временную таблицу'
	select @t2 = getdate()
	print datediff(millisecond, @t1, @t2) 
	set @t1= @t2
	  
		  
	SELECT  cast(d.MNKD as varchar(50)) as DorogaMnkd,
            d.CountryID,
	        (case when r.DorogaId='??' then osv.DorogaId else r.DorogaId end) as DorogaId,
			r.Nom_Vag,
			r.Neispr_dt,
			r.Dat_Rem,
			ISNULL(CAST(nullif(r.KodBrak1,0) AS VARCHAR(3)),'000')+'+'+ISNULL(CAST(nullif(r.KodBrak2,0) AS VARCHAR(3)),'000')+'+'+ISNULL(CAST(nullif(r.KodBrak3,0) AS VARCHAR(3)),'000') AS Neispr_kod123,
			--проверка наличия технологической неисправности по КП
			(select top 1 1 from nvBrakGroup 
			 where Prich=1 and kodASOUP in (r.KodBrak1, r.KodBrak2, r.KodBrak3) and kodASOUP<200) as TehKP,
			--r.KodBrak1,  --j
			r.KodBrakTn,  --j  pai17.08.2012
			osv.SNAME AS VrpSname,
			r.VRP,
			r.PRem_dt,
			r.PRemVRP,
			osv.VRK,
			cast (null as bigint) as 'ProbegOtc', --14.08.2023 Осмоловский:
			r.Dat_Pass,
			Dat_Pass as Dat_Pass_User,
			r.NomPret,
			CASE WHEN @KodKomplex IN (89, 90) 
				 THEN ISNULL(r.Dat_Send, r.DatPret) -- 28.07.2019 Афанасьева: для ФГК дата отправки виновнику по умолчанию доопределяется, как дата составления претензии
				 ELSE r.Dat_Send
				 end AS Dat_Send, --дата отправки претензии виновнику
			r.Stoim,
			CASE r.Result
				WHEN 1 THEN 'к оплате'
				WHEN 2 THEN 'отклонено'	
				WHEN 3 THEN 'частично'		
			END as Result,
			r.Result as [ResultId],
			r.Prim,r.Dat_Money
			,r.DatPret, --дата претензии
			r.PRemVid,r.VladStart_dt,r.Kol_TR,r.Nom_VT,r.Dat_SendVT,r.FIO_RsvVT,r.Dat_RsvVT,
			CASE r.NoPret
				WHEN 0 THEN 'подлежит'
				WHEN 1 THEN 'не подлежит'		
			END as NoPret
			,r.NoPret as [NoPretId]	
			,r.VRP_Garant
			,r.Dor_Garant,r.FilG_Get
			,CASE  r.FilG_Sogl
				WHEN 1 THEN 'принят'
				WHEN 2 THEN 'отклонён'
			  END as FilG_Sogl
			,r.FilG_Sogl as [FilG_SoglId] 
			,r.FilG_Prich
			,r.Gar_Get, datediff(day,r.Gar_Get, isnull(r.Gar_Send,getdate())) as Gar_RassmSut, r.Gar_Send,r.Gar_Prich,
			isnull(r.Send_PD, r.DatPret) AS Send_PD --дата передачи в претензионную работу
			,r.VidRem
			,r.Rekl_Dat
			,CASE  r.Rekl_Sogl
				WHEN 1 THEN 'принят'
				WHEN 2 THEN 'отклонён'
				WHEN 3 THEN 'возврат'
			  END as Rekl_Sogl
			,r.Rekl_Sogl as [Rekl_SoglId] 
			,r.Rekl_Prich 
			,r.Sum_money
			,r.Gar_SendNom,
			----28/02/2013 Гегешидзе 
			r.PriznRub, --Признано к оплате виновным предприятием
			r.Nom_money, --номер платежного поручения
			-----------Колонки для данных из DrVagTR
			cast(null as smalldatetime) as 'Or_Kompl',
			cast(null as smalldatetime) as 'Or_Pr_Dt',
			cast(null as tinyint)       as 'Or_Pr',
			cast(null as varchar(1000))  as 'Or_Prim',
			cast(null as smalldatetime) as 'Or_Kompl_Buh',
			cast(0 as tinyint)  as Or_Prv,
			0 as 'Or_IdZap',
			--------Договор аренды
			Dogovor.DogId,
			Dogovor.ClientId,
			Dogovor.Nomer as Nomer_KT,
			cast(null as varchar(200)) as NAME_KT, --наименование контрагента по договору аренды
			-- 2015.03.15 Гавриляко К.Г.
			Osnov,
			0 as korr_nom,
			cast(null as char(4)) as Vag_GR,
			-- 12.06.2018 Афанасьева: сохраненный договор из TrkRemPretens
			r.DogRem_Nom  as 'DogNomer',
			r.DogRem_Dat,
			--
			-- 19.05.2017 Хромов А.В.
			Prim_Neispr, 
			0 as IdZap_Dr, --17.10.17 Афанасьева: IdZap из drVagRem последнего планового ремонта
			-- 15.06.2018 Афанасьева: блок "Реализация деталей"
			cast(null as tinyint) as Det_prv,
			cast(null as tinyint) as Det_Dop,
			cast(null as tinyint) as Det_Rash,
			cast(null as smalldatetime) as Det_DopBuh,
			cast(null as smalldatetime) as Det_RashBuh,
			cast(null as tinyint) as Det_RashBuhCnt,
			--28.06.18 Афанасьева: передача документов с первой вкладки
			PassDoc_Name , --Документы переданы (кому)
			r.PassDoc_Date , --Документы переданы (дата)
			FilG_Name	, --Наименование подразделения (филиалу по виновнику) куда переданы документы для допретензионной работы
			Type_Garant , --ВРК/Завод/ЦДИ/Аренда (варианты ФГК)
			Name_Garant, Rad_Garant,
			---
			cast(null as varchar(40)) as gr1, 
			cast(null as varchar(10)) as TypeVRP_Garant,
			cast(null as char(2)) as DorVRP_Garant,
			--04.07.2018 Афанасьева: сроки передачи
			cast(null as smalldatetime) as Srok_FilG,
			cast(null as tinyint) as Srok_FilGColor,
			--08.09.2020 Лапунов А.В. контроль срока передачи документов
			cast(null as tinyint) as Srok_FilOColor,

			cast(null as smalldatetime) as Srok_DoPret,
			cast(null as tinyint) as Srok_DoPretColor,
			cast(null as smalldatetime) as Srok_PassPP,
			cast(null as tinyint) as Srok_PassPPColor,
			
			cast(null as smalldatetime) as Srok_Pret,
			cast(null as tinyint) as Srok_PretColor,
			--Срок передачи в судебную работу
			cast(null as smalldatetime) as Srok_PassSud,
			cast(null as tinyint) as Srok_PassSudColor,
			--Срок подачи искового заявления.
			cast(null as smalldatetime) as Srok_Sud,
			cast(null as tinyint) as Srok_SudColor,
			--12.08.2020. Малкиева Срок прикрепления комплектя документов.
			cast(null as smalldatetime) as Srok_PassDoc,
			cast(null as tinyint) as Srok_PassDocColor,
			---Допретензионная работа
			DoPret_Vozvrat_Dt, 
			DoPret_Vozvrat_NomRK,
			DoPret_Nom,
			DoPret_Dat,
			DoPret_Sum, --cумма претензии по письму
			case when @KodKomplex in (89,90) then ISNULL(DoPret_Send, DoPret_Dat) --28.07.2019 Афанасьева: для ФГК дата отправки виновнику по умолчанию доопределяется, как дата составления допретензионного обращения
				 ELSE DoPret_Send
				 end as DoPret_Send,  
			DoPret_Result, -- 1 - к оплате, 2 - отклонено, 3 - частично
			DoPret_Otvet_Nom,
			DoPret_Otvet_Dat,
			DoPret_PassPP_Name,
			--------------05.07.18 Афанасьева: заказ 219 ФГК - Судебная работа
			Sud_PassDt,
			Sud_NomZ,
			Sud_Dat,
			Sud_NomD,
			Sud_Sum, --cумма заявленная
			Sud_Result, -- 1 - к оплате, 2 - отклонено, 3 - частично
			Sud_SumSogl --cумма подлежащая удовлетв.
			--20.03.2020 Лапунов А.В.
			,r.Prich_Otkl
			--30.03.2020 Лапунов А.В.
			--,cast (null as int) as IdZap	--из DrVagTR
			,cast (null as smalldatetime) as OtchMonth	--из DrVagTR
			---
			,r.IdLogin
			,l.FIO
			,r.Dat_Korr

			--20.10.2020 Хромов А.В.
			--Передислокация вагона в ремонт:
			,r.VRem_Nom           --номер накладной в ремонт
			,r.VRem_DT_Accredit   --дата раскредитования
			,r.VRem_Sum 		  --сумма платежа в ремонт (VRem_pl+VRem_Dob)
			--	Передислокация вагона из ремонта:
			,case when r.IzRem_Nom is not null and rtrim (r.IzRem_Nom)='' then NULL else r.IzRem_Nom end as IzRem_Nom --номер накладной из ремонта 23.04.2024 Малкиева убрала пустоту
			,r.IzRem_DT_Accredit --дата раскредитования
			-- Гавриялко К.Г 2024.05.03
            -- Выдаем сохраненные значения
            --,case when r.IzRem_Sum is not null and r.IzRem_Sum=0 then NULL else r.IzRem_Sum end as IzRem_Sum --сумма платежа из ремонта (IzRem_pl+IzRem_Dob) 23.04.2024 Малкиева убрала пустоту
			, r.IzRem_Sum
            --	Ломаный тариф:
			,r.Tranz_Nom         --номер накладной транзитной - в момент браковки
			,r.Dosil_DT_Accredit --дата раскредитования isnull(Dosil_DT_Accredit,Tranz_DT_Accredit)
			,r.Dosil_Sum         --Сумма добора тарифа. (Tranz_Dob+Dosil_Dob)

			--Передача документов:
			,r.Tarif_NoPret as Tarif_NoPret                        ---Подлежит / не подлежит перевыставлению сумма тарифа: 0 - Подлежит, 1 - Не подлежит
			,cast (null as varchar(15)) as Tarif_NoPretChar        ---Подлежит / не подлежит перевыставлению сумма тарифа
			,r.Tarif_PassDat as Tarif_PassDat                      ---Дата передачи документов в претензионную работу.
			,r.Tarif_Sum as Tarif_Sum                              ---cумма тарифа
			-- 26.10.2020 Хромов А. В.
			,cast (null as int) as VRem_mOtprId	
			,cast (null as smalldatetime) as VRem_DT_Accept
			,cast (null as int) as IzRem_mOtprId	
			,cast (null as smalldatetime) as IzRem_DT_Accept
			,cast (null as int) as Tranz_mOtprId	
			,cast (null as smalldatetime) as Tranz_DT_Accept
			--02.11.2020 Хромов А.В.
			,cast (null as decimal(12,2)) as Tranz_pl
			,cast (null as char(6)) as Tranz_StanOtpr
			,cast (null as char(6)) as Tranz_Stan
			,cast (null as char(6)) as stan53
			,cast (null as char(6)) as stan54
			,cast (null as varchar(100)) as Tranz_StanOtprName
			,cast (null as varchar(100)) as Tranz_StanName
			,cast (null as varchar(100)) as Namestan53
			,cast (null as varchar(100)) as Namestan54
			--01.12.2020 Лапунов А.В.
			,cast (null as tinyint) as Porog
			-- 31.03.2021 Хромов А.
			,r.Sud_Dat_Korr
			,r.Sud_IdLogin
			,cast (null as varchar(100)) as Sud_FIO_Korr
			--08.04.2021 Лапунов А.В.
			,r.Rasch_Dosil_sum 
			,r.Rasch_Dosil_sum_IdLogin
			,r.Rasch_Dosil_sum_Date_sys
			,cast (null as varchar(100)) as Rasch_Dosil_sum_FIO
			,cast (null as decimal(12,2)) as Tranz_Dob
			,cast (null as decimal(12,2)) as Dosil_Dob
			---- 29.07.2021 Хромов А.В.  блок колонок по состоянию пакета рекламации
			,cast (null as bigint) as IdPak
			,cast (null as tinyint) as Pak_Pr
			,cast (null as smalldatetime) as Or_Pr_DtPak
			,cast (null as smallint) as Or_Pr_Login
			,cast (null as varchar(300)) as Prich_OtklPak
			,cast (null as varchar(100)) as Or_Pr_Login_FIO
			--02.08.2021 Хромов А.
			,cast (null as tinyint) as Source
			--19.11.2021 Лапунов А.В.
			,Pret_Vozvrat_NomRK
			,Pret_Vozvrat_Dt 
		---------------
			--06.12.2021 Лаунов А.В.
			,cast(null as tinyint) as 'GarantKP'
			--08.12.2021 Лаунов А.В.
			,r.Idzap as 'IdZapPret'
			,r.Index_Pret
			--27.06.2023 Малкиева
			,Depo_Rem_Akt
			,KAgPret_Name, KAgPret_GUID
			,KAgPret_Dog, KAgPret_Dog_Dt
			,Vozm_Summ
			,Straf_Sut
			,ProstSut
            ,r.CaseOneStatus
            ,r.CaseOneDate
            ,r.CaseOneGuid
            ,r.CaseOneError
			,r.Reestr_Nom,r.Reestr_Date,r.ID_Login_Reestr,r.Date_Sys_Reestr, l2.fio as Reestr_FIO
			,r.VU41_Nom--Номер акта рекламации ВУ-41
		    ,r.VU41_Dat--Дата акта рекламации ВУ-41 (отцепки вагонов в ТОР)
            ,r.PSRMatNom
            ,r.PSRMatDate
            , case when d.CountryID <>'0643' then 1 end as [IsSngDor]
			,cast(null as varchar(12)) as Model --29.03.2024 Хромов А.В.
			,cast(null as smalldatetime) as Postr_dt --16.04.2024 Хромов А.В.
			,r.Prim_Garant
			----26.11.2025 Осмоловский:
			,convert(smalldatetime,null) as DatTekRem
			,convert(int,null) as DepTekRem
			,convert(varchar(100),null) as DepTekRemName
			,convert(tinyint,null) as VidTekRem
			,convert(varchar(50),null) as NeisprTekRem
			,convert(int,null) as ProbegTekRem
			into #TPret						
			FROM dbo.TrkRemPretens r
				 left join dbo.nsTovPR_FOROSV osv on r.VRP = osv.VRP_int
				 --left join dbo.nsTovPR_FOROSV osvVin on isnull(r.VRP_Garant, r.PRemVRP) = osvVin.VRP_int
				 left join dbo.nsDoroga d on (case when r.DorogaId='??' then osv.DorogaId else r.DorogaId end) = d.DorogaId --27.03.2023 Хромов А.В.
				 --left join nvTRK_DD dd on dd.DorogaId = (case when r.DorogaId='??' then osv.DorogaId else r.DorogaId end)
				 left join dbo.nvTRK_Departments dp1 on dp1.ID_Department = (select top 1 ddd.Id_Dep from nvTRK_DD ddd where ddd.DorogaId = d.DorogaId)--   dd.Id_Dep
				 left join dbo.nvTRK_Departments pdp1 on pdp1.ID_Department = dp1.ID_Parent and dp1.LevelDep = 2
				 left join dbo.nvTRK_Departments dp2 on dp2.DorogaID = (case when r.DorogaId='??' then osv.DorogaId else r.DorogaId end)
				 left join dbo.nvTRK_Departments pdp2 on pdp2.ID_Department = dp2.ID_Parent and dp2.LevelDep = 2
				 ---15.09.2016 Афанасьева: пытаемся подтянуть договор передачи вагона в аренду
				 outer apply (select top 1 DOVagon.DogId, DODogovorInf.ClientId, DODogovorInf.Nomer
						  from  DOVagon 
						  JOIN DODogovorInf ON DODogovorInf.DogId=DOVagon.DogId
						  -- 10.01.2019 Хромов А. Изменения для договоров аренды с учётом периода действия.
						  JOIN dbo.DODogovorInfRem ds ON ds.DogId=DODogovorInf.DogId and ds.Otvetstv=1
													 AND isnull(Dat_Rem, getdate()) >= ds.period_Date1 
													 AND isnull(Dat_Rem, getdate()) < isnull(ds.period_Date2+1,isnull(Dat_Rem, getdate())+1)
						  where DOVagon.Nom_Vag=r.Nom_Vag and Dat_Vkl<=isnull(Dat_Rem, getdate())
								and (Dat_Iskl>=isnull(Dat_Rem, getdate()) or Dat_Iskl is NULL)
								and DODogovorInf.DogType in (1, 3) ) Dogovor
				 ---
				 left join dbo.nvTRK_login l on l.ID_Login = r.IdLogin         
				 left join dbo.nvTRK_login l2 on l2.ID_Login = r.ID_Login_Reestr         
			WHERE
				-- Гавриляко К.Г. 22.04.2016 добавлен доп. фильтр по дате браковки
					  (@Remont_dt_n is null or r.Dat_Rem  > @Remont_dt_n)
				  AND (@Remont_dt_k is null or r.Dat_Rem <= @Remont_dt_k+1)

				  AND (@DatBrakBegin is null or r.Neispr_dt > @DatBrakBegin)
				  AND (@DatBrakEnd   is null or r.Neispr_dt <= @DatBrakEnd+1)

				  --18.10.2021 Хромов А.В.
				  AND (@Start2 is null or r.FilG_Get > @Start2)
				  AND (@Finish2   is null or r.FilG_Get <= @Finish2+1)
				  AND (@FilG_NameVar is null or r.FilG_Name = @FilG_NameVar)
				  --------------------------------------------------------

				  AND r.KodPret = @CPretensRem 
				  AND r.Korr_pr <> @Korr_pr_del
			 --
				  and (r.Nom_Vag = @Nom_Vag or @Nom_Vag is null)
				  AND ((case when r.DorogaId='??' then osv.DorogaId else r.DorogaId end) = 
					@DorogaRemontID or @DorogaRemontID is null OR @DorogaRemontID = '00' 
						OR (@DorogaRemontID = '999' and dp2.ID_Department is not null)
						)
				  and (@ID_Department is null --Все филиалы.
						or (@ID_Department = 0 and dp1.ID_Department is null and dp2.ID_Department is null) --Все НЕ филиалы.
						or (@ID_Department = -2 and d.CountryID <> '0643') -- дороги СНГ
						or coalesce(case when PassDoc_Name = 'ДЭПС' then 15 end, pdp1.ID_Department, dp1.ID_Department, pdp2.ID_Department, dp2.ID_Department) = @ID_Department) --Выбранный филиал.

			 --АТ 19.09.12 Ограничения для режима корректировки по первому филиалу
			 and (@RegRed in (0,10) or @Id_Login=-1 or @Centr=1
		 		 --по дорогам
		 		 or (@RegRed in (6, 12) and osv.DorogaID in (select Dor from @TDor TD))
				  )
			 --13
			 and (NomPret like @Nom_Pret or @Nom_Pret is null)
			 and (@IdSpis is null or exists (select top 1 Nvag from dbo.THP_SpisVag Sp where Sp.IdSpis=@IdSpis and Sp.NVag=r.Nom_Vag) )

			 -- Фильтры для детализации из сводных отчетов
			 and (@vrp          is null or r.VRP = @vrp)
			 and (@vrpVin       is null or isnull(r.VRP_Garant, r.PRemVRP) = @vrpVin)
			 --and (@dorVin       is null or osvVin.DorogaID = @dorVin)
			 and (@vrk          is null or isnull(osv.VRK,0) = @vrk)
			 and (@checkOtpr    is null or r.Dat_Send is not null)
			 and (@checkKodBrak is null or r.KodBrak1 is not null)
			 and (@kodPret      is null or isnull(KodPret,0) = @kodPret)
			 and (@nopret       is null or isnull(r.NoPret,0) = @nopret)
			 and (@VidRem       is null or VidRem = @VidRem)
			 and (@result       is null or isnull(r.Result,0) in (select id from @resIds)) -- @PRemVidIds
			 and (@PRemVid      is null or isnull(r.PRemVid,0) in (select id from @PRemVidIds))
			 --AND DOVagon.Nom_Vag=r.Nom_Vag
			 -- 09.08.2023 Хромов
 			 and (r.Reestr_Nom like @Reestr_NomDU or @Reestr_NomDU is null)
			 AND (@DatBeginDU is null or r.Reestr_Date >  @DatBeginDU)
			 AND (@DatEndDU   is null or r.Reestr_Date <= @DatEndDU+1)
 			 and (DoPret_PassPP_Name like @NomPSR or @NomPSR is null)
			 AND (@DatBeginPSR is null or isnull(r.Send_PD, r.DatPret) >  @DatBeginPSR)
			 AND (@DatEndPSR   is null or isnull(r.Send_PD, r.DatPret) <= @DatEndPSR+1)

	select @Kol=count(*) from #TPret
	print 'Выбрано во временную таблицу ' + Str(isnull(@Kol, 0), 6)+' записей.'
	select @t2 = getdate()
	print datediff(millisecond, @t1, @t2) 
	set @t1= @t2

	-------31.03.2021 Хромов А.-------------
	update r set Sud_FIO_Korr=left(l.FIO,100)
	FROM #TPret r left join dbo.nvTRK_login l on l.ID_Login = r.Sud_IdLogin         
	-----------------------
	---- 29.07.2021 Хромов А.В.  блок колонок по состоянию пакета рекламации
	update #TPret set IdPak=p.IdPak, Or_Pr_DtPak=p.Or_Pr_Dt, Prich_OtklPak=p.Prich_Otkl, Or_Pr_Login=p.Or_Pr_Login, Pak_Pr=p.Pak_Pr
		from #TPret
		inner join dbo.DetDopPak p on p.Nom_Vag=#TPret.Nom_Vag and p.Date_Rem=#TPret.Dat_Rem
	where  p.ServiceType=3

	update r set Or_Pr_Login_FIO=left(l.FIO,100)
	FROM #TPret r left join dbo.nvTRK_login l on l.ID_Login = r.Or_Pr_Login         
	-----------------------------------------------------

	update #TPret set stan53=tr.stan53, stan54=tr.stan54
		from #TPret
		inner join VagPrivatRem tr on tr.Nom_Vag=#TPret.Nom_Vag and tr.Neispr_dt=#TPret.Neispr_dt

	update #TPret set stan53=tr.stan53, stan54=tr.stan54
		from #TPret
		inner join VagPrivatRemJour tr on tr.Nom_Vag=#TPret.Nom_Vag and tr.Neispr_dt=#TPret.Neispr_dt

	--20.10.2020 Хромов А.В.
	declare @Payer char(10)
	if @KodKomplex in (89,90) select @Payer ='4000005146' --Плательщик ФГК

	update #TPret 
		   set VRem_Nom= case when #TPret.VRem_Nom is null or #TPret.VRem_Nom='' then case when @Payer is null or isnull(tr.VRem_Payer, @Payer) = @Payer then tr.VRem_Nom end
                                                                                 else #TPret.VRem_Nom end,  --07.06.2024 Малкиева добавила промерку на ''
			   VRem_DT_Accredit=isnull(#TPret.VRem_DT_Accredit, case when @Payer is null or isnull(tr.VRem_Payer, @Payer) = @Payer then tr.VRem_DT_Accredit end), 
			   
			   --04.12.2024 Лапунов А.В. пока просто комментирую предыдущий вариант
			   --VRem_Sum=case when #TPret.VRem_Sum is null or #TPret.VRem_Sum=0 then case when @Payer is null or isnull(tr.VRem_Payer, @Payer) = @Payer then isnull(tr.VRem_pl,0) +isnull(tr.VRem_Dob,0) end
               --                                                 else #TPret.VRem_Sum end,
	           
			   --04.12.2024 Лапунов А.В. По письму Тимонина от 03.12.2024 считаем что в притензиях можно обнулить VRem_Sum и доопределяем ее только если она null
			   VRem_Sum=case when #TPret.VRem_Sum is null then case when @Payer is null or isnull(tr.VRem_Payer, @Payer) = @Payer then isnull(tr.VRem_pl,0) +isnull(tr.VRem_Dob,0) end
                                                                else #TPret.VRem_Sum end,
			   IzRem_Nom=isnull(#TPret.IzRem_Nom, case when @Payer is null or isnull(tr.IzRem_Payer, @Payer) = @Payer then tr.IzRem_Nom end), 
			   IzRem_DT_Accredit=isnull(#TPret.IzRem_DT_Accredit, case when @Payer is null or isnull(tr.IzRem_Payer, @Payer) = @Payer then tr.IzRem_DT_Accredit end), 
			   IzRem_Sum=isnull(#TPret.IzRem_Sum, case when @Payer is null or isnull(tr.IzRem_Payer, @Payer) = @Payer then isnull(tr.IzRem_pl,0)+isnull(tr.IzRem_Dob,0) end),
		       
			   Tranz_Nom=isnull(#TPret.Tranz_Nom, case when @Payer is null or isnull(tr.Tranz_Payer, @Payer) = @Payer then tr.Tranz_Nom end),
			   Dosil_DT_Accredit=isnull(#TPret.Dosil_DT_Accredit, case when @Payer is null or isnull(tr.Tranz_Payer, @Payer) = @Payer then isnull(tr.Dosil_DT_Accredit,tr.Tranz_DT_Accredit) end),
			   Dosil_Sum=isnull(#TPret.Dosil_Sum, case when (@Payer is null or isnull(tr.Tranz_Payer, @Payer) = @Payer)
								   and #TPret.stan53 <> #TPret.stan54 
								   --and tr.Tranz_pl>0 --была получена плата по отправлению
						 then isnull(tr.Tranz_Dob,0)+isnull(tr.Dosil_Dob,0) end),
			   Tranz_Dob=case when (@Payer is null or isnull(tr.Tranz_Payer, @Payer) = @Payer)
								   and #TPret.stan53 <> #TPret.stan54 
								   --and tr.Tranz_pl>0 --была получена плата по отправлению
						 then isnull(tr.Tranz_Dob,0) end,
			   Dosil_Dob=case when (@Payer is null or isnull(tr.Tranz_Payer, @Payer) = @Payer)
								   and #TPret.stan53 <> #TPret.stan54 
								   --and tr.Tranz_pl>0 --была получена плата по отправлению
						 then isnull(tr.Dosil_Dob,0) end,		 
		---Это нужно для просмотра накладной, пусть будет не зависимо от плательщика
		VRem_mOtprId=tr.VRem_mOtprId,  VRem_DT_Accept=tr.VRem_DT_Accept
		,IzRem_mOtprId=tr.IzRem_mOtprId, IzRem_DT_Accept=tr.IzRem_DT_Accept
		,Tranz_mOtprId=tr.Tranz_mOtprId, Tranz_DT_Accept=tr.Tranz_DT_Accept
		--
		,Tranz_pl=tr.Tranz_pl
		,Tranz_StanOtpr=tr.Tranz_StanOtpr, Tranz_Stan=tr.Tranz_Stan
		from #TPret
		     join VagPrivatRemOtpr tr on tr.Nom_Vag=#TPret.Nom_Vag 
	    where --11.09.2022 Афанасьева: при склеивании разбраковок дата браковки в VagPrivatRemOtpr может сползти в прошлое
		      --нужно привязывать на попадание в диапазон
	          tr.Neispr_dt<=#TPret.Neispr_dt and #TPret.Neispr_dt<=isnull(tr.EndRem_DT, getdate())
		      and  tr.Vid_rem = #TPret.VidRem

	update #TPret set 
		 Tarif_NoPret=isnull(Tarif_NoPret,case when isnull(VRem_Sum,0)+isnull(IzRem_Sum,0)+coalesce(Rasch_Dosil_sum,Dosil_sum,0)>0 then 0 else 1 end)
		,Tarif_NoPretChar=case when isnull(Tarif_NoPret,case when isnull(VRem_Sum,0)+isnull(IzRem_Sum,0)+coalesce(Rasch_Dosil_sum,Dosil_sum,0)>0 then 0 else 1 end)=0 then 'подлежит' else 'не подлежит' end
		,Tarif_Sum=case when isnull(VRem_Sum,0)+isnull(IzRem_Sum,0)+coalesce(Rasch_Dosil_sum,Dosil_sum,0)>0 then isnull(VRem_Sum,0)+isnull(IzRem_Sum,0)+coalesce(Rasch_Dosil_sum,Dosil_sum,0) else null end
		--	Ломаный тариф:
		,Tranz_Nom=case when Dosil_Sum>0 then Tranz_Nom else null end
		,Dosil_DT_Accredit=case when Dosil_Sum>0 then Dosil_DT_Accredit else null end
		,Dosil_Sum=case when Dosil_Sum>0 then Dosil_Sum else null end
		,Tranz_Dob=case when Tranz_Dob>0 then Tranz_Dob else null end
		,Dosil_Dob=case when Dosil_Dob>0 then Dosil_Dob else null end
		,VRem_Sum=case when VRem_Sum>0 then VRem_Sum else null end
		,IzRem_Sum=case when IzRem_Sum>0 then IzRem_Sum else null end
		,Tranz_pl=case when Tranz_pl>0 then Tranz_pl else null end

	update r set Rasch_Dosil_sum_FIO=left(l.FIO,100)
		FROM #TPret r left join dbo.nvTRK_login l on l.ID_Login = r.Rasch_Dosil_sum_IdLogin

	update #TPret set Rasch_Dosil_sum=isnull(Rasch_Dosil_sum,Dosil_sum)
	update #TPret set Tranz_StanOtprName=st.Name from nsStan st where #TPret.Tranz_StanOtpr=st.stanid
	update #TPret set Tranz_StanName=st.Name from nsStan st where #TPret.Tranz_Stan=st.stanid
	update #TPret set Namestan53=st.Name from nsStan st where #TPret.stan53=st.stanid
	update #TPret set Namestan54=st.Name from nsStan st where #TPret.stan54=st.stanid
	-------------------------------------------------------------------------

	print 'Получены IdZap из DrVagTR.' 
	select @t2 = getdate()
	print datediff(millisecond, @t1, @t2) 
	set @t1= @t2     
     
	--27.06.18 Афанасьева. Характеристики ВРП-гаранта на дату последнего планового ремонта
	update #TPret 
		   set gr1 = p.SNAME, 
			   TypeVRP_Garant = case when p.VRK = 1 then 'ВРК-1'
									 when p.VRK = 2 then 'ВРК-2'
									 when p.VRK = 3 then 'ВРК-3'
									 when p.IdStampDep = 1 then 'ЦДРВ'
									 when p.IdStampDep = 3 then 'ТВМ'
									 when p.IdStampDep = 4 then 'ЦДИ'
									 when p.VRP_int = #TPret.PRemVRP and #TPret.PRemVid=5 then 'ВСЗ'
								end,
			   DorVRP_Garant = p.DorogaID
		from dbo.nsTHP_PrStamp p
		where p.VRP_int = isnull(#TPret.VRP_Garant, #TPret.PRemVRP) 
			  and p.StartDate <= #TPret.PRem_dt
			  and (p.FinishDate >= #TPret.PRem_dt or p.FinishDate is null)

	if @dorVin is not null and @dorVin<>'999'  
	   delete from #TPret where DorVRP_Garant<> @dorVin            
                           
	select @Kol=count(*) from #TPret
	print 'Отработал фильтр по дороге виновника ' + Str(isnull(@Kol, 0), 6)+' записей.'
	select @t2 = getdate()
	print datediff(millisecond, @t1, @t2) 
	set @t1= @t2     
     
----Только для тех вагонов, по которым не найден договор ПЕРЕДАЧИ в аренду, будем искать договор ПРИЕМА в аренду.     
--Тип договора аренды:
	-- 1 - передача в аренду
	-- 2 - прием в аренду
	-- 3 - передача в субаренду
	-- 4 - прием в субаренду     
/*
update #TPret    
set DogId=DODogovorInf.DogId, 
    ClientId=DODogovorInf.ClientId,
    Nomer_KT=dbo.DODogovorInf.Nomer,
    --Для ФГК 
    Type_Garant=case when @KodKomplex in (89, 90) then 'Аренда' else Type_Garant end --Аренда (варианты ФГК)
	
from dbo.DOVagon JOIN dbo.DODogovorInf ON DODogovorInf.DogId=DOVagon.DogId and DODogovorInf.Otvetstv=1 --  and DODogovorInf.Otvetstv=1 14.11.2016 Хромов 
where #TPret.DogId is null
      and DOVagon.Nom_Vag=#TPret.Nom_Vag and Dat_Vkl<=Dat_Rem
      and (Dat_Iskl>=Dat_Rem or Dat_Iskl is NULL)
*/
	update #TPret    
		set DogId=DODogovorInf.DogId, 
			ClientId=DODogovorInf.ClientId,
			Nomer_KT=dbo.DODogovorInf.Nomer,
			--Для ФГК 
			Type_Garant=case when @KodKomplex in (89, 90) then 'Аренда' else Type_Garant end --Аренда (варианты ФГК)
			
		from #TPret 
			join dbo.DOVagon on DOVagon.Nom_Vag=#TPret.Nom_Vag 
						and Dat_Vkl<=Dat_Rem and (Dat_Iskl>=Dat_Rem or Dat_Iskl is NULL)
			JOIN dbo.DODogovorInf ON DODogovorInf.DogId=DOVagon.DogId 
			-- 10.01.2019 Хромов А. Изменения для договоров аренды с учётом периода действия.
			JOIN dbo.DODogovorInfRem ds ON ds.DogId=DODogovorInf.DogId and ds.Otvetstv=1
									 AND Dat_Rem >= ds.period_Date1 
									 AND Dat_Rem < isnull(ds.period_Date2+1,Dat_Rem+1)
		where #TPret.DogId is null

	-- 27.07.2017 Осмоловский В.В.  по согласованию с Романовым    
	--  Для тех вагонов, по которым не найдены договора ПЕРЕДАЧИ или ПРИЕМА в аренду, по которым ответственность за ремонт в явном виде несет ФГК   
	--  (DODogovorInf.Otvetstv=0) ищем договор, в который вагон был включен на дату ремонта   
	update #TPret    
		set DogId=DODogovorInf.DogId, 
			ClientId=DODogovorInf.ClientId,
			Nomer_KT=dbo.DODogovorInf.Nomer,
			--Для ФГК 
			Type_Garant=case when @KodKomplex in (89, 90) then 'Аренда' else Type_Garant end  --Аренда (варианты ФГК)
		from dbo.DOVagon JOIN dbo.DODogovorInf ON DODogovorInf.DogId=DOVagon.DogId
		where #TPret.DogId is null
			  and DOVagon.Nom_Vag=#TPret.Nom_Vag and Dat_Vkl<=Dat_Rem
			  and (Dat_Iskl>=Dat_Rem or Dat_Iskl is NULL)    
	        
	print 'Выбираем наименования клиентов.'
 
      
	update #TPret    
		set Name_KT=Cl.Client_name,      
			Name_Garant=case when @KodKomplex in (89, 90) then Left(Cl.Client_Sname, 50) else Name_Garant end --Аренда (варианты ФГК)
		from dbo.DOClientInf Cl where Cl.ClientId= #TPret.ClientId   
     
	print 'Выбраны договора аренды.'
	select @t2 = getdate()
	print datediff(millisecond, @t1, @t2) 
	set @t1= @t2     
     
	---20.04.2017 Афанасьева: определение nvVagPrivatArx.Korr_nom через сгруппированный select (старый вариант через подселект зависал и не дожидались)
	update #TPret 
		set korr_nom = AG.Max_Korr_nom
		from (select max (A.Korr_nom) as Max_Korr_nom, #TPret.Nom_Vag, #TPret.Dat_Rem from #TPret join dbo.nvVagPrivatArx A on A.Nom_Vag=#TPret.Nom_Vag and A.Korr_dt<#TPret.Dat_Rem group by #TPret.Nom_Vag, #TPret.Dat_Rem) AG    
		where #TPret.Nom_Vag=AG.Nom_Vag and #TPret.Dat_Rem=AG.Dat_Rem

/* было до 20.04.2017 - на ФГК работало очень долго (вообще не выполнялось по таймауту)
update #TPret 
set korr_nom = isnull((select top 1 A.Korr_nom from dbo.nvVagPrivatArx A 
                       where A.Nom_Vag=#TPret.Nom_Vag and A.Korr_dt<#TPret.Dat_Rem order by A.Korr_nom desc),
                      0)
 */   
---------     
  
	print 'Получены korr_nom из nvVagPrivatArx.'
	select @t2 = getdate()
	print datediff(millisecond, @t1, @t2) 
	set @t1= @t2 
	--           
	update #TPret 
		set Vag_GR = A.Vag_GR
		   ,Model  = A.Model --29.03.2024 Хромов А.В.
		   ,Postr_dt  = A.Postr_dt --16.04.2024 Хромов А.В.
		from dbo.nvVagPrivatArx A 
		where A.Nom_Vag=#TPret.Nom_Vag and A.korr_nom=#TPret.korr_nom                 
	                
	select @Kol=count(*) from #TPret
	print 'Готова временная таблица - '+ Str(isnull(@Kol, 0), 4) + ' вагонов.'		 
	select @t2 = getdate()
	print datediff(millisecond, @t1, @t2) 
	set @t1= @t2
		  
	--AT 06.09.12 Пакет документов по оплате ТОР
	update #TPret
		set Or_IdZap=Dr.IdZap, OtchMonth=Dr.OtchMonth,
			Or_Kompl=Dr.Or_Kompl, Or_Pr_Dt=Dr.Or_Pr_Dt, Or_Pr=Dr.Or_Pr, Or_Prim=Dr.Or_Prim, Or_Kompl_Buh=Dr.Or_Kompl_Buh, Or_Prv=Dr.Prv,
			--21.08.2018 Афанасьева: если в оплате ТР стоит "перевыставление"="да", то для ФГК по умолчанию идет виновник - аренда
			Rad_Garant=isnull(Rad_Garant, case when @KodKomplex in (89, 90) and Dr.Prv=1 then 1 else 0 end)
		from dbo.DRVagTR Dr
		where DR.Nom_Vag = #TPret.Nom_Vag and DR.Date_Rem=#TPret.Dat_Rem and dr.Korr_dt is NULL

	--30.03.2020 Лапунов А.В.
	update #TPret set Or_IdZap=tr.idzap, OtchMonth=tr.OtchMonth
		from #TPret
		inner join DrVagTR tr on tr.Nom_Vag=#TPret.Nom_Vag and tr.Date53=#TPret.Neispr_dt
		where Or_IdZap=0
     
	 update #TPret set Source=case when @IsTK = 1 and doc.Source = 4 then 1 else isnull(doc.Source, 0) end
		from #TPret
		inner join dbo.DRVagTRDoc doc on doc.IdZap = #TPret.Or_IdZap

	print 'Подтянули данные по DrVagTR.'		 
	select @t2 = getdate()
	print datediff(millisecond, @t1, @t2) 
	set @t1= @t2		 

	--15.06.2018 Афанасьева: Собираеем данные по реализации деталей из МХ-1-Х
	create table #DetMX (IdZap int, 
						 TDet char(2), --Тип детали ('КП', 'НБ', 'БР', 'ПА', 'АС', 'ТХ')
						 Izg int, --Завод изготовитель детали.
						 Nom_Det varchar(12),--Номер детали.
						 God int, --Год изготовления детали.
						 UnNom varchar(30),--Номер детали в формате завод-номер-год.
						 Name varchar(500) not null, --Наименование детали, полученное из документа.
						 IdPak bigint, --Идентификатор пакета хранения ТОР ЭК.
						 MX3_IdRec bigint, --Идентификатор найденной МХ-3.
						 Doc_Date smalldatetime, --Дата документа.
						 VRP int --Предприятие, оформившее документ.
	)
	--Данные из сохраненных расчетов на перевыставление затрат
	insert into #DetMX (IdZap, TDet, Izg, Nom_Det, God, UnNom, Name, IdPak)
		select P.Or_IdZap, Z.TDet,
			dbo.fTHP_DetPart(z.NomDet, 0),
			dbo.fTHP_DetPart(z.NomDet, 1),
			dbo.fTHP_DetPart(z.NomDet, 2),
			Z.NomDet, --Номер детали в формате завод-номер-год.
			Z.Name,
			nullif(z.IdPak, 0)
		from #TPret P 
			join DRVagTRPrZatrat Z 
				on Z.IdZap = P.Or_IdZap 
					and Z.SourceType = 1 --претензии по технологии
					and [Type] = 3 --блок "детали из МХ-1Х"
					and Perev > 0
					and isnull(Z.TipPr, 0) <> 4 --20.05.2020 Афанасьева: не ждем реализацию забракованных деталей

	print 'Подтянули данные из сохраненных расчетов на перевыставление затрат.'		 
	select @t2 = getdate()
	print datediff(millisecond, @t1, @t2) 
	set @t1= @t2		 

	--Данные из МХ-1Х если нет сохранённых расчётов (из пакетов хранения).
	insert into #DetMX (IdZap, TDet, Izg, Nom_Det, God, UnNom, Name, IdPak, Doc_Date, VRP)
		select p.Or_IdZap, mx.TDet, mx.Izg, mx.Nom_Det, mx.God, cast(mx.Izg as varchar) + mx.Nom_Det + cast(mx.God as varchar), mx.Name, mx.IdPak, mx.Doc_Date, mx.VRP
			from #TPret p
				join DetMX mx on isnull(mx.Pak_State, 0) <> 4 and mx.IdZap = p.Or_IdZap and mx.Vid_Rem = 4 and mx.ServiceType = 4 and mx.MXType in ('МХ-1Х', 'Акт ТМЦ')
				left join DRVagTRPrZatrat z on z.IdZap = mx.IdZap and z.SourceType = 1
			where z.IdZap is null
				  and (mx.TDet <> 'КП' or p.TehKP = 1) --проверка наличия технологической неисправности по КП

	print 'Подтянули данные из МХ-1Х если нет сохранённых расчётов (из пакетов хранения).'
	select @t2 = getdate()
	print datediff(millisecond, @t1, @t2)
	set @t1= @t2

	--Данные из МХ-1Х если нет сохранённых расчётов (из ремонтов).
	insert into #DetMX (IdZap, TDet, Izg, Nom_Det, God, UnNom, Name, Doc_Date, VRP)
		select p.Or_IdZap, mx.TDet, mx.Izg, mx.Nom_Det, mx.God, cast(mx.Izg as varchar) + mx.Nom_Det + cast(mx.God as varchar), mx.Name, mx.Doc_Date, mx.VRP
			from #TPret p
				join DetMX mx on isnull(mx.Pak_State, 0) <> 4 and mx.IdZap = p.Or_IdZap and mx.Vid_Rem = 4
					and isnull(mx.ServiceType, 2) in (2, 10) --04.06.2021 А.А.Валуев Пакеты МХ-1 (ServiceType = 10) считаем здесь частью пакета ремонта.
					and mx.MXType in ('МХ-1Х', 'Акт ТМЦ')
				left join DRVagTRPrZatrat z on z.IdZap = mx.IdZap and z.SourceType = 1
			where z.IdZap is null and not exists (select top 1 1 from #DetMX where IdZap = p.Or_IdZap and TDet = mx.TDet and Izg = mx.Izg and Nom_Det = mx.Nom_Det and God = mx.God)
				  and (mx.TDet <> 'КП' or p.TehKP = 1) --20.05.2020 Афанасьева: проверка наличия технологической неисправности по КП
	
	print 'Подтянули данные из МХ-1Х если нет сохранённых расчётов (из ремонтов).'		 
	select @t2 = getdate()
	print datediff(millisecond, @t1, @t2) 
	set @t1= @t2		 

	--Находим для деталей МХ-3.
	update mx set MX3_IdRec = mx3.IdRec
		from #DetMX mx
			cross apply 
				 (select top 1 * 
				  from DetMX 
				  where isnull(Pak_State, 0) <> 4 and MXType = 'МХ-3Х' and IdZap <> mx.IdZap
						and datediff(day, mx.Doc_Date, Doc_Date) >= 0 
						and TDet = mx.TDet and Izg = mx.Izg and Nom_Det = mx.Nom_Det and God = mx.God
						and DetMX.VRP = mx.Vrp --21.08.2018 Афанасьева: уточнение связи между пакетами
				  order by Doc_Date /*desc*/, isnull(IdPak, 0) asc) mx3

	print 'Нашли для деталей МХ-3.'
	select @t2 = getdate()
	print datediff(millisecond, @t1, @t2)
	set @t1= @t2

	--Считаем количество перевыставленных деталей для каждого ремонта.
	update #TPret set Det_prv = Cnt_prv
		from (select IdZap, count(*) as Cnt_prv 
			  from #DetMX group by IdZap) D
		where D.IdZap = #TPret.Or_IdZap

	print 'Посчитали количество перевыставленных деталей для каждого ремонта.'		 
	select @t2 = getdate()
	print datediff(millisecond, @t1, @t2) 
	set @t1= @t2		 

	--Считаем количество перевыставленных деталей взятых из пакетов хранения.
	update #TPret set Det_Dop = Cnt_dop, Det_DopBuh = d.Or_Kompl_Buh
		from (select IdZap, count(*) as Cnt_dop, max(pak.Or_Kompl_Buh) as Or_Kompl_Buh
			  from #DetMX mx join DetDopPak pak on mx.IdPak = pak.IdPak group by IdZap) D
		where D.IdZap = #TPret.Or_IdZap

	print 'Посчитали количество перевыставленных деталей взятых из пакетов хранения.'		 
	select @t2 = getdate()
	print datediff(millisecond, @t1, @t2) 
	set @t1= @t2		 

	--Считаем количество МХ-3 для перевыставленных деталей (реализация).
	update #TPret set Det_Rash = Cnt_rash, Det_RashBuh = d.Or_Kompl_Buh, Det_RashBuhCnt = d.Cnt_rash_Buh
		from (select mx.IdZap, count(*) as Cnt_rash, max(coalesce(pak.Or_Kompl_Buh, tr.Or_Kompl_Buh, dr.Or_Kompl_Buh)) as Or_Kompl_Buh,
					 sum(case when pak.Or_Kompl_Buh is not null or tr.Or_Kompl_Buh is not null or dr.Or_Kompl_Buh is not null then 1 else 0 end) as Cnt_rash_Buh
					from #DetMX mx
						join DetMX mx3 on mx3.IdRec = mx.MX3_IdRec
						left join DRVagTR tr on mx3.Vid_Rem in (3, 4) and tr.IdZap = mx3.IdZap
						left join DRVagRem dr on mx3.Vid_Rem in (1, 2) and dr.IdZap = mx3.IdZap
						left join DetDopPak pak on pak.IdPak = mx3.IdPak
					group by mx.IdZap) d
	where d.IdZap = #TPret.Or_IdZap

	print 'Собраны данные по реализации деталей из МХ-1-Х.'		 
	select @t2 = getdate()
	print datediff(millisecond, @t1, @t2) 
	set @t1= @t2	

	--17.10.17 Афанасьева: получаем IdZap из drVagRem последнего планового ремонта для более корректного заполнения номера Договора 
	declare @dMon tinyint --доверительный интервал поиска ремонта в drVagRem в месяцах
	select @dMon=KodChar from dbo.nvVagPrivatDob where KodPos=42 and mnkd='dMon'
	if isnull(@dMon, 0) < 1 or @dMon>12 set @dMon=1

	update #TPret
	set IdZap_Dr=drVagRem.IdZap,
		DogNomer=isnull(DogNomer,DogovorNom)
	FROM #TPret join dbo.drVagRem 
		 on dbo.drVagRem.Nom_Vag=#TPret.Nom_Vag 
			and dbo.drVagRem.Date_Rem<=DateAdd(month, @dMon, #TPret.PRem_dt) 
			and dbo.drVagRem.Date_Rem>=DateAdd(month, -@dMon, #TPret.PRem_dt)
			AND isnull(dbo.drVagRem.Korr_pr,0) <>1
	  
	update #TPret
	set #TPret.DogNomer=Dog.DocNomer, DogRem_Dat=Dog.DocFrom
	FROM #TPret join dbo.drVagRemVRK VRK on IdZap_Dr=VRK.IdZap
				join dbo.nvDrSprDogovor Dog on VRK.KodDog=Dog.kod
	where IdZap_Dr>0 and  #TPret.DogNomer is null                    
			    
	/*27.06.18 Афанасьева. Автомат даты формирования пакета для ФГК (заказ 219)
	- в случае ремонта вагона на предприятиях ЦДИ 
	  указывается дата передачи комплектов документов в бухгалтерию, 
	  в случае наличия дополнительного пакета "хранение" (определение ремонтопригодности) и/или замены забракованной колесной пары, указывается соответствующая дата;
	- В случае проведения ремонта на предприятиях ВРК и СНГ, дата с учетом сроков оплаты за проведение работ, от даты передачи документов в бухгалтерию,  согласно условиям договоров.
	=======================
	- для ЦДИ без замены деталей дата формирования полного комплекта = дата передачи в бухгалтерию основного ремонта;
	- для ЦДИ с заменой деталей дата формирования полного комплекта = дата передачи в бухгалтерию из раздела «Реализация деталей», но не позже 45 дней от даты передачи основного ремонта;
	- для ВРК и СНГ с заменой и без замены деталей дата формирования полного комплекта = дата передачи в бухгалтерию основного ремонта + 45 раб. дней;

	*/ 
	if @KodKomplex in (89, 90)
	begin
		 -- для ЦДИ без замены деталей дата формирования полного комплекта = дата передачи в бухгалтерию основного ремонта;
		 -- для ВРК и СНГ дата формирования полного комплекта = дата передачи в бухгалтерию основного ремонта + 45 рабочих дней;
		 update #TPret 
				set Dat_Pass= case when Pr.CDI=1 then isnull(Dat_Pass, Or_Kompl_Buh)
								   else dbo.fTHP_SrokDay(isnull(Dat_Pass, Or_Kompl_Buh), 45, 2) --прибавляем 45 рабочих дней
								   end
				from dbo.nsTovPr_ForOsv Pr
		 where Pr.Vrp_int=#TPret.VRP --and Pr.CDI=1 
		       and (isnull(Det_prv, 0)=0 or isnull(Pr.CDI, 0)=0) --только для ЦДИ ждем реализацию деталей
	           and #TPret.Index_Pret=1 -- 10.12.2021 Лапунов А.В. только для обычных претензий
		 -- для ЦДИ с заменой деталей дата формирования полного комплекта = дата передачи в бухгалтерию из раздела «Реализация деталей»;
		 -- НО не позже 45 рабочих дней от даты передачи в бухгалтерию основного пакета
		 -- НО не раньше даты передачи в бухгалтерию основного комплекта
		 update #TPret set Dat_Pass=case when Det_prv>isnull(Det_RashBuhCnt, 0) and dbo.fTHP_SrokDay(Or_Kompl_Buh, 45, 2)<=@Today then dbo.fTHP_SrokDay(Or_Kompl_Buh, 45, 2) --конец ожидания реализации
										 when dbo.fTHP_SrokDay(Or_Kompl_Buh, 45, 2)<isnull(Det_RashBuh, @Today) then dbo.fTHP_SrokDay(Or_Kompl_Buh, 45, 2) --дата реализации вышла за границу 45 дней
										 when Or_Kompl_Buh>Det_RashBuh then Or_Kompl_Buh --07.09.2021 Афанасьева (не сдвигаем дату в прошлое)
										 else Det_RashBuh
										 end
				from dbo.nsTovPr_ForOsv Pr
		 where Pr.Vrp_int=#TPret.VRP --and Pr.CDI=1 
			   and Det_prv>0 
			   and Or_Kompl_Buh is not null --07.07.2021 Афанасьева: если сам пакет не передан, то не назначаем срок реализации деталей
			   and (Det_prv=Det_RashBuhCnt or dbo.fTHP_SrokDay(Or_Kompl_Buh, 45, 2)<=@Today)
			   and Pr.CDI=1
			   and #TPret.Index_Pret=1 -- 10.12.2021 Лапунов А.В. только для обычных претензий
			   and Dat_Pass_User is null --01.06.2022 Афанасьева: сохраняем пользовательскую дату формирования пакета
	end           

	-- === Определяем сроки передачи  ===
    --------------------------------------
    -- Цвет выделения колонки:
    -- 1 - желтый
    -- 2 - оранжевый
    -- 3 - красный
	declare @Srok TINYINT, @SrokType TINYINT
	
	
	--------------------------------------------------------------
		--12.08.2020. Малкиева Срок прикрепления комплектя документов.
--		cast(null as smalldatetime) as Srok_PassDoc,
--		cast(null as tinyint) as Srok_PassDocColor,

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
--------------------------------------------------------------
	
	--Срок передачи в КД (документов в допрет. работу) (исчисляется от "Даты формирования полного пакета" до FilG_Get или PassDoc_Date (что раньше)
	--Dat_Pass - Дата формирования полного комплекта документов
	--FilG_Get - Передача документов в допретензионную работу|Дата передачи (формирование)
	--PassDoc_Date - Передача документов для организации работ|Дата прикреп. компл. докум. (прикрепление)
	--Srok_DoPret - Допретензионная работа|Письмо|Срок предъяв.
	--Send_PD - Передача документов в претензионную работу|Дата передачи
	select top 1 @Srok = Srok, @SrokType = SrokType from dbo.nvPretSrok where IdOper = 9; 
	update #TPret set Srok_FilG = dbo.fTHP_SrokDay(isnull(PassDoc_Date,Dat_Pass), @Srok, @SrokType)
		where isnull(NoPretId, 0) = 0 and isnull(PassDoc_Date,Dat_Pass) is not null
		      and (FilG_Get is not null or Send_PD is null) --срок переносим к передаче в претензионную работу, если прямо передано в претез., минуя допретенз.
		      --19.10.2018 Афанасьева.
		      --по звонку Романова от имени Быковича срок допретензионной работы назначается только тем вагонам,
		      --к к-рых есть договор аренды и нет договора на выполнение последнего планового ремонта.
		      --Остальным сразу назначается срок претензионной работы
		      and (Nomer_KT is not null and isnull(DogNomer, '')='')
    -- цвет выделения колонки
    update #TPret set Srok_FilGColor = case
				when datediff(day, dbo.fTHP_SrokDay(Srok_FilG, 30, 2), coalesce(Send_PD, FilG_Get, getdate())) > 0 then 3
				when datediff(day, dbo.fTHP_SrokDay(Srok_FilG, 10, 2), coalesce(Send_PD, FilG_Get, getdate())) > 0 then 2
				when datediff(day, dbo.fTHP_SrokDay(Srok_FilG, 1, 2), coalesce(Send_PD, FilG_Get, getdate())) >= 0 then 1
			end
		where Srok_FilG is not null
	
	--Допретензинооая работа|Письмо|Срок предъяв.
    select @Srok = null, @SrokType = null
    select top 1 @Srok = Srok, @SrokType = SrokType from dbo.nvPretSrok where IdOper = 10; 
	update #TPret set Srok_DoPret = dbo.fTHP_SrokDay(FilG_Get, @Srok, @SrokType)
		where isnull(NoPretId, 0) = 0 and FilG_Get is not null 
		      --28.08.2018 Афанасьева - не назначаем срок предъявления письма, если уже есть передача в претензионный отдел
		      and (Send_PD is null or DoPret_Send is not null)
		      and FilG_Name<>'ДКФ'
    -- цвет выделения колонки
    update #TPret set Srok_DoPretColor = case
				when datediff(day, dbo.fTHP_SrokDay(Srok_DoPret, 30, 2), isnull(DoPret_Send, getdate())) > 0 then 3
				when datediff(day, dbo.fTHP_SrokDay(Srok_DoPret, 10, 2), isnull(DoPret_Send, getdate())) > 0 then 2
				when datediff(day, dbo.fTHP_SrokDay(Srok_DoPret, 1, 2), isnull(DoPret_Send, getdate())) >= 0 then 1
			end
		where Srok_DoPret is not null
    
    --Срок передачи документов в претензионную работу (в случае полного или частичного отказа или отсутствия ответа).
    --19.10.2018 Афанасьева.
    --по звонку Романова от имени Быковича срок допретензионной работы назначается только тем вагонам,
    --к к-рых есть договор аренды и нет договора на выполнение последнего планового ремонта.
    --Остальным сразу назначается срок претензионной работы
    select @Srok = null, @SrokType = null
    select top 1 @Srok = Srok, @SrokType = SrokType from dbo.nvPretSrok where IdOper = 11; 
	update #TPret 
	       set Srok_PassPP = case when DoPret_Otvet_Dat is not null and isnull(DoPret_Result, 2) in (2, 3)
								  then dbo.fTHP_SrokDay(DoPret_Otvet_Dat, @Srok, @SrokType) --срок от даты получения отказа
	                              
								  when Pret_Vozvrat_Dt is not null 
								  then dbo.fTHP_SrokDay(Pret_Vozvrat_Dt, @Srok, @SrokType) --срок от даты возврата--22.11.2021 Малкиева новый срок если был возврат
	                              
	                              when DoPret_Send is not null 
	                              then dbo.fTHP_SrokDay(DoPret_Send + 14, @Srok, @SrokType) --срок от даты отправки письма
	                              
	                              when FilG_Get is null and Send_PD is not null --прямая передача в претензионную работу, если прямо передано в претез., миную допретенз.
	                              then dbo.fTHP_SrokDay(isnull(PassDoc_Date,Dat_Pass), @Srok, @SrokType)
	                              
	                              else dbo.fTHP_SrokDay(isnull(FilG_Get, isnull(PassDoc_Date,Dat_Pass)), @Srok, @SrokType) --срок от даты передачи в доретенз. без отправки письма
	                              end
	where isnull(NoPretId, 0) = 0 and isnull(PassDoc_Date,Dat_Pass) is NOT NULL
	      and isnull(DoPret_Result, 0) in (0, 2, 3) --только в случае полного или частичного отказа или отсутствия ответа по допретензтонному обращению
	      and (DoPret_Send is not null  --срок от даты отправки письма виновнику
	           or FilG_Get is not null and DoPret_Send is null and Send_PD is not null
	           or FilG_Get is null and Send_PD is not null
	           or Nomer_KT is null --вагоны без аренды - прямая передача в претензионную
	           or DogNomer is not null) --вагоны после нашего планового - прямая передача в претензионную
		

    -- цвет выделения колонки
    update #TPret set Srok_PassPPColor = case
				when datediff(day, dbo.fTHP_SrokDay(Srok_PassPP, 30, 2), isnull(Send_PD, getdate())) > 0 then 3
				when datediff(day, dbo.fTHP_SrokDay(Srok_PassPP, 10, 2), isnull(Send_PD, getdate())) > 0 then 2
				when datediff(day, dbo.fTHP_SrokDay(Srok_PassPP, 1, 2), isnull(Send_PD, getdate())) >= 0 then 1
			end
		where Srok_PassPP is not null
    
    --Срок предъявления претензии контрагенту.
    select @Srok = null, @SrokType = null
    select top 1 @Srok = Srok, @SrokType = SrokType from dbo.nvPretSrok where IdOper = 12; 
	update #TPret set Srok_Pret = dbo.fTHP_SrokDay(Send_PD, @Srok, @SrokType)
	where isnull(NoPretId, 0)=0 
	      and Send_PD is not null

	-- цвет выделения колонки
	update #TPret set Srok_PretColor = case
				when datediff(day, dbo.fTHP_SrokDay(Srok_Pret, 30, 2), isnull(Dat_Send, getdate())) > 0 then 3
				when datediff(day, dbo.fTHP_SrokDay(Srok_Pret, 10, 2), isnull(Dat_Send, getdate())) > 0 then 2
				when datediff(day, dbo.fTHP_SrokDay(Srok_Pret, 1, 2), isnull(Dat_Send, getdate())) >= 0 then 1
			end
		where Srok_Pret is not null
    
    --Срок передачи в судебную работу
    select @Srok = null, @SrokType = null
    select top 1 @Srok = Srok, @SrokType = SrokType from dbo.nvPretSrok where IdOper = 13;
	update #TPret set Srok_PassSud = dbo.fTHP_SrokDay(isnull(Gar_Send, Dat_Send + 14), @Srok, @SrokType)
	where isnull(NoPretId, 0)=0 
	      and Dat_Send is not null
	      and isnull(ResultId,2) in (2, 3)
	--22.11.2021 Малкиева новый срок если был возврат
	update #TPret set Srok_PassSud = dbo.fTHP_SrokDay(Pret_Vozvrat_Dt+14, @Srok, @SrokType)
	where Pret_Vozvrat_Dt is not null and Pret_Vozvrat_Dt>Send_PD      

	-- цвет выделения колонки
	update #TPret set Srok_PassSudColor = case
				when datediff(day, dbo.fTHP_SrokDay(Srok_PassSud, 30, 2), coalesce(Sud_PassDt, Sud_Dat, getdate())) > 0 then 3
				when datediff(day, dbo.fTHP_SrokDay(Srok_PassSud, 10, 2), coalesce(Sud_PassDt, Sud_Dat, getdate())) > 0 then 2
				when datediff(day, dbo.fTHP_SrokDay(Srok_PassSud, 1, 2), coalesce(Sud_PassDt, Sud_Dat, getdate())) >= 0 then 1
			end
		where Srok_PassSud is not null
    
	--Срок подачи искового заявления.
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

	--- 08.09.2020 Лапунов А.В. Определяем просроченные документы
	update #TPret set Srok_FilOColor = case
				when datediff(day, dbo.fTHP_SrokDay(Dat_Pass, 30, 2), getdate()) > 0 then 3
				when datediff(day, dbo.fTHP_SrokDay(Dat_Pass, 10, 2), getdate()) > 0 then 2
				when datediff(day, dbo.fTHP_SrokDay(Dat_Pass, 1, 2), getdate()) >= 0 then 1
			end
		where Dat_Pass is not null and PassDoc_date is null and FilG_Get is null and Send_PD is null
	--06.12.2021 Лапунов А.В. Заполнение количества гарантийных КП
	if @KodKomplex IN (89, 90)
	begin
		update t Set GarantKP=Dat.Kol
		from #TPret t
		outer apply (select count(*) as 'Kol' from TrkPretensObodKP kp where t.Nom_Vag=kp.Obt_Nom_Vag and t.Dat_Rem=kp.Obt_Dat_Rem) Dat
		where Dat.Kol>0
	end

	--14.08.2023 Осмоловский:
	select *
	into #TRemJour
	from dbo.VagPrivatRemJour
	where Nom_Vag in (select distinct Nom_vag from #TPret)
		   
	update t
	set t.ProbegOtc = dop.ProbegGruz + dop.ProbegPorogn
	from #TPret t
	left join dbo.VagPrivatRemDop dop on dop.Nom_Vag = t.Nom_Vag and dop.Dat_Rem = t.Dat_Rem
	where dop.ProbegGruz is not null and dop.ProbegPorogn is not null
	
	update t
    set t.ProbegOtc  = jour.Probeg_Tek
    from #TPret t
    outer apply (select top 1 rem.Probeg_Tek, rem.Probeg_Norm
                 from #TRemJour rem
                 where rem.Nom_vag = t.Nom_vag and rem.EndRem_dt <= t.Neispr_dt
                 order by rem.Cicle desc) jour 
    where jour.Probeg_Norm > 0 and t.ProbegOtc is NULL
    
    ----26.11.2025 Осмоловский:
    update tmp 
           set DatTekRem    = case when b.Date_LastTR < b.Date_LastPlRem then null else b.Date_LastTR end
		      ,DepTekRem    = case when b.Date_LastTR < b.Date_LastPlRem then null else b.VRP_LastTR end
		      ,VidTekRem    = case when b.Date_LastTR < b.Date_LastPlRem then null else b.Vid_LastTR end
		      ,NeisprTekRem = case when b.Date_LastTR < b.Date_LastPlRem then null else b.KodBrak_LastTR end
    from #TPret tmp
	       inner join dbo.VagPrivatRemBrak b on tmp.Nom_Vag=b.Nom_Vag and b.Neispr_dt=tmp.Neispr_dt
    
    update #TPret 
           set ProbegTekRem=D.ProbegPorogn+D.ProbegGruz
    from dbo.VagPrivatRemDop D where D.Nom_Vag=#TPret.Nom_Vag and D.Dat_Rem=#TPret.DatTekRem
    ----
--******************************Rem***********************************************************
		--ВРЕМЕННАЯ раскраска!!!
	if @KodKomplex IN (89, 90)
		update t set Porog=1
		from #TPret t
		inner join TrkRemPretensColor c on c.Nom_Vag=t.Nom_Vag
	--____________________________________________________________________________________________________
	print '1111'
	if @Reg is null
	begin
		SELECT  --AT 13.09.2012 Филиал по ТОР
				Or_IdZap as IdZap,
				case 
                    -- По для ФГК все дороги СНГ под одним названием 
                    --when CountryID <> '0643' and @KodKomplex IN (89,90) then 'МП (СНГ и Балтия)'
                    when DD.Id_Dep is null 
					 then r2.DorogaMnkd --'Центр ап.' --
					 else (select top 1 Dpt.SName from dbo.nvTRK_Departments Dpt where Dpt.ID_Department=DD.Id_Dep)
					 end as 'DorogaMnkd',

				-- Афанасьев О.В. 17.10.2013 ---- кому можно редактировать часть по ТОР (по отцепке)
				case when exists (select top 1 1 from @TDor TD where TD.Dor=r2.DorogaId)
					 then @Id_Dep
					 else ISNULL(DD.Id_Dep,1)
					 end AS Id_DepTOP, 
		             
				-- было : ISNULL(DD.Id_Dep,1) AS Id_DepTOP,   
				--
				r2.DorogaId,
				r2.Nom_Vag,r2.Neispr_dt,r2.Dat_Rem,
				r2.Neispr_kod123,
				b.name AS Neispr_name,
				r2.VrpSname,r2.VRP,
				r2.PRem_dt,
				
				case 
					when isnull(prs.VRK,0) > 0 then
					case
						when r2.PRem_dt < '20110701' then 'ЦДРВ'
						when prs.VRK=1 then 'ВРК1'
						when prs.VRK=2 then 'НВРК'
						when prs.VRK=3 then 'ОМК'
					end 
					when prs.idStampDep=5 then 'НВТ'
					when osv2.CDI=1 then 'ЦДИ'
					else 'Завод' 
				end AS PRemVRK,
		        
				--prs.KodF,
				case when prs.VRK > 0 
					 then case when r2.PRem_dt < '20110701' 
							   then (select top 1 mnkd from dbo.nsDoroga Fil where Fil.DorogaId = osv2.Dir) 
							   else (select top 1 mnkd from dbo.nsFilVRK Fil where Fil.KodF = prs.KodF) 
							   end 
					 end as ef6,         
				r2.PRemVRP,
				prs.SNAME AS PRemVRPSName,
				r2.ProbegOtc,
				-- EXEC dbo.pThp_PretTehSelect '20170315','20170301',null,null,-1,0,null,null,null,null

				--Дата получения полного пакета документов
				/*27.06.18 Афанасьева. Автомат даты формирования пакета для ФГК (заказ 219)
				- в случае ремонта вагона на предприятиях ЦДИ указывается дата передачи комплектов документов в бухгалтерию, в случае наличия дополнительного пакета "хранение" (определение ремонтопригодности) и/или замены забракованной колесной пары, указывается соответствующая дата;
		- В случае проведения ремонта на предприятиях ВРК и СНГ, дата с учетом сроков оплаты за проведение работ, от даты передачи документов в бухгалтерию,  согласно условиям договоров.
		 
				**/
				r2.Dat_Pass,
				--
				r2.NomPret,r2.Dat_Send,r2.Stoim,r2.Result,
				isnull(r2.ResultId,0) as [ResultId],
				r2.Prim,
				isnull(r2.Dat_Money,case when @KodKomplex in (89,90) and nullif(r2.Sud_Sum,0)=nullif(r2.Sud_SumSogl,0) and nullif(r2.Sud_SumSogl,0) is not null then r2.Sud_Dat_Korr else null end) as Dat_Money  
				--Tn2 04.09.2012
				,case when r2.VidRem=3 then 'ТР-1' when r2.VidRem=4 then 'ТР-2' when r2.VidRem=1 then 'ДЕП' when r2.VidRem=2 then 'КАП' else Str(r2.VidRem, 2) end as 'VidRem'
				,r2.VidRem as [VidRemId]
				,r2.DatPret
				--AT 13.09.2012
				,r2.PRemVid as [PRemVidId] 
				,case when r2.PRemVid = 1 then 'ДЕП'
					  when r2.PRemVid = 2 then 'КАП'
					  when r2.PRemVid = 5 then 'ПОСТ'
					  else Str(r2.PRemVid, 2)
					  end as 'PRemVid',
				      
				r2.VladStart_dt,r2.Kol_TR,r2.Nom_VT,r2.Dat_SendVT,r2.FIO_RsvVT,r2.Dat_RsvVT,r2.NoPret,
				isnull(r2.NoPretId, 99) as [NoPretId],
				isnull(r2.VRP_Garant, r2.PRemVRP) as 'VRP_Garant'
				,r2.Dor_Garant,r2.FilG_Get,r2.FilG_Sogl,
				isnull(r2.FilG_SoglId,0) as [FilG_SoglId],
				r2.FilG_Prich
				,r2.Gar_Get,r2.Gar_RassmSut,r2.Gar_Send,r2.Gar_Prich,r2.Send_PD
				
				,r2.DorogaMnkd as 'ef11'
				--филиал по виновнику
				,case when DDV.Id_Dep is null 
					 then (select top 1 DF.mnkd from dbo.nsDoroga DF where DF.DorogaID=DorVRP_Garant) --'Центр ап.' --
					 else (select top 1 Dpt.SName from dbo.nvTRK_Departments Dpt where Dpt.ID_Department=DDV.Id_Dep)
					 end as 'ef27'
				---03.04.15 для прав доступа к блоку по виновнику:     
				,case when exists (select top 1 1 from @TDor TD where TD.Dor=r2.DorogaId) --если есть права редактирования на блок отцепки, то даем их и на блок виновника
					  then @Id_Dep
					  when @KodKomplex in (89,90)
						   and exists (select top 1 1 from @TDor TD where TD.Dor=DorVRP_Garant) --для ВГК сохраняем права на блок виновника для дорог ответственности филиала по виновнику
					  then @Id_Dep
					  else ISNULL(DD.Id_Dep,1)                                                                   	
					  end
				 AS Id_DepV,  --для всех даем права по тому филиалу, где был ремонт (по письму Ветчиновой от 10.11.14)     
				r2.gr1 as gr1 
				/* было до 28.06.18
				(select top 1 p.SNAME from dbo.nsTHP_PrStamp p
						where p.VRP_int = isnull(r2.VRP_Garant, r2.PRemVRP) and p.StartDate <= r2.PRem_dt
						order by p.StartDate DESC) as gr1
				 */
				--AT 06.09.12 Пакет документов по оплате ТОР
				,r2.Or_Kompl as 'pd1', r2.Or_Pr_Dt as 'pd2'
				, case
					when r2.Or_Pr=1 then 'принят'
					when r2.Or_Pr=0 then 'отклонен'
					when r2.Or_Pr=2 then 'возвращено'
				  end as 'pd3'---гегешидзе
				, r2.Or_Pr as [pd3Id]
        				, case when Or_IdZap=0 then 'нет в оплате' else r2.Or_Prim end as 'pd4'
				,r2.Or_Kompl_Buh	as 'pd5'
				, Or_IdZap
				--pai20120910
				,r2.Rekl_Dat,r2.Rekl_Sogl,
				isnull(r2.Rekl_SoglId, 0) as [Rekl_SoglId],
				r2.Rekl_Prich 
				--pai20120924
				,isnull(case when r2.Sum_money>0 then r2.Sum_money else null end, case when @KodKomplex in (89,90) and r2.Sud_Sum=r2.Sud_SumSogl and r2.Sud_SumSogl is not null then r2.Sud_SumSogl else 0.0 end) as Sum_money
				,(case
					when r2.ResultId=1 then Stoim
					when r2.ResultId=3 then r2.PriznRub
					WHEN DoPret_Result=1 THEN DoPret_Sum --28.07.2019 Афанасьева: сумма, согласованная по допретензионному обращению
					end - isnull(case when r2.Sum_money>0 then r2.Sum_money else null end, case when @KodKomplex in (89,90) and r2.Sud_Sum=r2.Sud_SumSogl and r2.Sud_SumSogl is not null then r2.Sud_SumSogl else 0.0 end)) as Nedopl_money
				,r2.Gar_SendNom,
				----28/02/2013 Гегешидзе 
				isnull(r2.Nom_money,case when r2.Sud_Sum=r2.Sud_SumSogl and r2.Sud_SumSogl is not null then r2.Sud_fio_Korr else null end) as Nom_money,--номер платежного поручения
				DateAdd(year, 1, r2.Dat_Rem) AS DatEndPret, --дата оканчания срока выставления претензии
				case
					when r2.ResultId=1 then Stoim
					when r2.ResultId=3 then r2.PriznRub
				end as PriznRub, --Признано к оплате виновным предприятием
		        
				case isnull(r2.ResultId,0)
					when 2 then r2.Stoim
					when 3 then r2.Stoim - r2.PriznRub
				end AS [OtklRub],--сумма откланенная виновником
		        
				case when isnull(r2.ResultId,0)=0 then r2.Stoim end as [SmotrRub],-- сумма на расмотрении виновного предприятия

				r2.Nomer_KT as Nomer_KT,
				r2.NAME_KT as NAME_KT,

				-- 2015.03.15 Гавриляко К.Г.
				isnull(r2.Osnov,0) as Osnov,
				case
					when r2.Osnov = 1 then 'по претензии'
					when r2.Osnov = 2 then 'по суду'
					else ''
				end AS OsnovName,
				r2.Vag_GR,
				r2.DogNomer, --25.01.2017 Осмоловский В.В. Добавлено поле "Договор"
				r2.DogRem_Dat, --06.12.2018 Афанасьева: дата договора на ремонт
				r2.Prim_Neispr, -- 19.05.2017 Хромов
				--Реализация деталей из МХ-1-Х
				r2.Det_prv,       
				r2.Det_Dop,
				r2.Det_DopBuh,
				r2.Det_Rash,
				r2.Det_RashBuh,
				r2.Det_RashBuhCnt, --реализация / передано в бух.
				r2.VidRem as VremId, --Для пункта меню "Учёт деталей".
				Srok_PassDoc,--срок передачи
				Srok_PassDocColor,
				PassDoc_Name , --Документы переданы (кому)
				PassDoc_Date , --Документы переданы (дата)
				
				--Сроки передачи документов
				r2.Srok_FilG,
				Srok_FilGColor, 
				Srok_DoPret, Srok_DoPretColor,
				Srok_PassPP, Srok_PassPPColor,
				Srok_Pret, Srok_PretColor,
				--Срок передачи в судебную работу
				Srok_PassSud, Srok_PassSudColor,
				--Срок подачи искового заявления
				Srok_Sud, Srok_SudColor,
				FilG_Name	, --Наименование подразделения (филиалу по виновнику) куда переданы документы для допретензионной работы
				r2.TypeVRP_Garant as TypeVRP_Garant,--ВРК/Завод/ЦДИ
				Type_Garant , --Аренда (варианты ФГК)
				Name_Garant ,
				isnull(Rad_Garant, 0) as Rad_Garant,
				---
				case when isnull(Rad_Garant, 0) =0 then r2.TypeVRP_Garant else Type_Garant end as Type_GarantShow,
				case when isnull(Rad_Garant, 0) =0 then isnull(r2.VRP_Garant, r2.PRemVRP) end as Vrp_GarantShow, --08.12.2025 Хромов isnull(r2.VRP_Garant, r2.PRemVRP) вместо r2.VRP_Garant
				case when isnull(Rad_Garant, 0) =0 then r2.gr1 else Name_Garant end as Name_GarantShow,
				r2.Prim_Garant,
				---Допретензионная работа
				DoPret_Vozvrat_Dt, 
				DoPret_Vozvrat_NomRK,
				DoPret_Nom,
				DoPret_Dat,
				DoPret_Sum, --cумма претензии по письму
				DoPret_Send,
				DoPret_Result, -- 1 - к оплате, 2 - отклонено, 3 - частично
				DoPret_Otvet_Nom,
				DoPret_Otvet_Dat,
				null as DoPret_PassPP_Dt, --удалить
				DoPret_PassPP_Name,
				DateDiff(day, DoPret_Send, isnull(DoPret_Otvet_Dat, getdate())) as DoPret_OtvSut, --на рассмотрении 
				--------------05.07.18 Афанасьева: заказ 219 ФГК - Судебная работа
				Sud_PassDt,
				Sud_NomZ,
				Sud_Dat,
				Sud_NomD,
				Sud_Result, -- 1 - к оплате, 2 - отклонено, 3 - частично
				nullif(Sud_Sum,0) as Sud_Sum, --cумма заявленная
				nullif(Sud_SumSogl,0) as [Sud_SumSogl], --cумма подлежащая удовлетв.
				CASE when Sud_Result >0 then nullif(Sud_Sum-Sud_SumSogl,0) end as [Sud_SumOtkaz] --отказ заполняем только при наличии результата рассмотрения
				--20.03.2020 Лапунов А.В.
				,r2.Prich_Otkl
				--30.03.2020 Лапунов А.В.
				-----,r2.IdZap эта колонка уже есть
				,r2.OtchMonth
				----
				,r2.idlogin
				,r2.FIO
				,r2.Dat_Korr
			--20.10.2020 Хромов А.В.
			--Передислокация вагона в ремонт:
			,VRem_Nom                ---номер накладной в ремонт
			,VRem_DT_Accredit  ---дата раскредитования
			,VRem_Sum 		   ---сумма платежа в ремонт (VRem_pl+VRem_Dob)
			--	Передислокация вагона из ремонта:
			,IzRem_Nom               ---номер накладной из ремонта
			,IzRem_DT_Accredit ---дата раскредитования
			,IzRem_Sum 		   ---сумма платежа из ремонта (IzRem_pl+IzRem_Dob)
			--	Ломаный тариф:
			,Tranz_Nom               ---номер накладной транзитной - в момент браковки
			,Dosil_DT_Accredit ---дата раскредитования isnull(Dosil_DT_Accredit,Tranz_DT_Accredit)
			,Dosil_Sum         ---Сумма добора тарифа. (Tranz_Dob+Dosil_Dob)

			--Передача документов:
			,Tarif_NoPret            ---Подлежит / не подлежит перевыставлению сумма тарифа: 0 - Подлежит, 1 - Не подлежит
			,Tarif_NoPretChar        ---Подлежит / не подлежит перевыставлению сумма тарифа
			,Tarif_PassDat           ---Дата передачи документов в претензионную работу.
			,Tarif_Sum               ---сумма тарифа
			--
			,VRem_mOtprId,  VRem_DT_Accept
			,IzRem_mOtprId, IzRem_DT_Accept
			,Tranz_mOtprId, Tranz_DT_Accept
			-- 02.11.2020 Хромов 
			,Tranz_pl
			,Tranz_StanOtpr, Tranz_StanOtprName
			,Tranz_Stan, Tranz_StanName
			,stan53, Namestan53
			,stan54, Namestan54
			--10.11.2020 Лапунов А.В.
			,case when datediff(hour,r2.Neispr_dt,r2.Dat_Rem)%24>6 then datediff(hour,r2.Neispr_dt,r2.Dat_Rem)/24 +1 else datediff(hour,r2.Neispr_dt,r2.Dat_Rem)/24 end as ProstSut
			,Porog
			-- 31.03.2021 Хромов А.В.
			,r2.Sud_Dat_Korr
			,r2.Sud_IdLogin
			,r2.Sud_FIO_Korr
			--08.04.2021 Лапунов А.В.
			,r2.Rasch_Dosil_sum 
			,r2.Rasch_Dosil_sum_Date_sys
			,r2.Rasch_Dosil_sum_FIO
			,r2.Tranz_Dob
			,r2.Dosil_Dob
			---- 29.07.2021 Хромов А.В.  блок колонок по состоянию пакета рекламации
			,r2.IdPak
			,r2.Or_Pr_DtPak as Or_Pr_Dt
			,r2.Prich_OtklPak
			,r2.Or_Pr_Login
			,r2.Or_Pr_Login_FIO
			,case r2.Pak_Pr when 1 then 'принят' when 0 then 'отклонён' when 2 then 'возврат' when 3 then 'на проверке' when 4 then 'возврат-1' when 5 then 'возврат-2' when 6 then 'принят-1' when 7 then 'принят-2' end as 'Pak_Pr'
			,r2.OtchMonth as [DateOtch]
			,r2.Source
			--19.11.2021 Лапунов А.В.
			,r2.Pret_Vozvrat_NomRK
			,r2.Pret_Vozvrat_Dt
			--06.12.2021 Лапунов А.В.
			,isnull(r2.GarantKP,0) as 'GarantKP'
			--08.12.2021 Лаунов А.В.
			,r2.IdzapPret
			,r2.Index_Pret
			--27.06.2023 Малкиева
			,case 
					when isnull(prsVRP.VRK,0) > 0 then
					case
						when r2.Neispr_dt < '20110701' then 'ЦДРВ'
						when prsVRP.VRK=1 then 'ВРК1'
						when prsVRP.VRK=2 then 'НВРК'
						when prsVRP.VRK=3 then 'ОМК'
					end 
					when prsVRP.idStampDep=5 then 'НВТ'
					when osvVRP.CDI=1 then 'ЦДИ'
					else 'Завод' 
			end AS PRemVRP1
			,r2.Depo_Rem_Akt
			,isnull(r2.KAgPret_Name,KA.[Name]) as KAgPret_Name--r2.KAgPret_Name
			,ISNULL(r2.KAgPret_Dog,r2.DogNomer) as KAgPret_Dog--r2.KAgPret_Dog
			,r2.Vozm_Summ
			,isnull(r2.ProstSut,(case when datediff(hour,r2.Neispr_dt,r2.Dat_Rem)%24>6 then datediff(hour,r2.Neispr_dt,r2.Dat_Rem)/24 +1 else datediff(hour,r2.Neispr_dt,r2.Dat_Rem)/24 end))*Straf_Sut as Straf_Summ
			,r2.Tarif_Sum as Tarif_Sum1
            ,r2.CaseOneStatus
            ,r2.CaseOneDate
            ,r2.CaseOneGuid
            ,r2.CaseOneError
            ,case r2.CaseOneStatus
                when 1 then 'Передано'
                --when 2 then 'Создан'
                when 7 then 'Ошибка' -- для нас
                when 8 then 'Ошибка'
                when 9 then 'Ошибка с файлами'
             end as CaseOneStatusName
			 -- 12.07.2023 Хромов А.В.  для окна редактирования
			 ,Straf_Sut 
			 ,isnull(r2.ProstSut,(case when datediff(hour,r2.Neispr_dt,r2.Dat_Rem)%24>6 then datediff(hour,r2.Neispr_dt,r2.Dat_Rem)/24 +1 else datediff(hour,r2.Neispr_dt,r2.Dat_Rem)/24 end)) as ProstSut_Edit
			 ,r2.KAgPret_Dog_Dt
			 ,ISNULL(r2.KAgPret_Dog,r2.DogNomer) as KAgPret_Dog_Edit
			 ,ISNULL(r2.KAgPret_Dog_Dt,r2.DogRem_Dat) as KAgPret_Dog_Dt_Edit
			 ,r2.KAgPret_GUID
			 ,isnull(r2.KAgPret_GUID,KA.ID) as KAgPret_GUID_Edit
			 ,isnull(r2.KAgPret_Name,KA.[Name]) as KAgPret_Name_Edit
			,r2.Reestr_Nom,r2.Reestr_Date,r2.ID_Login_Reestr,r2.Date_Sys_Reestr, r2.Reestr_FIO
			,r2.VU41_Nom--Номер акта рекламации ВУ-41
		    ,r2.VU41_Dat--Дата акта рекламации ВУ-41 (отцепки вагонов в ТОР)
            ,r2.PSRMatNom
            ,r2.PSRMatDate
            ,r2.IsSngDor
			,r2.Model -- 29.03.2024 Хромов А.В.
			,r2.Postr_dt --16.04.2024 Хромов А.В.
			,year(r2.Postr_dt) as Postr_God--29.10.2024 Хромов А.В.
			,case when osvTR.VRK is not null then 'ВРК'+ isnull( Str(osvTR.VRK,1), '') else NULL end as 'VRKLTekRem' --26.11.2025 Осмоловский:
			,(SELECT TOP 1 MNKD FROM dbo.nsDoroga WHERE DorogaID = osvTR.DorogaID) AS 'DorLTekRem'                    --26.11.2025 Осмоловский:
			,Str(r2.DepTekRem, 4) + '  ' + isnull(osvTR.SName, '') as 'DepoLTekRem'                                  --26.11.2025 Осмоловский:
			,r2.DatTekRem AS 'DatLTekRem'                                                                            --26.11.2025 Осмоловский:
			,CASE r2.VidTekRem WHEN 3 THEN 'ТР-1'
			                   WHEN 4 THEN 'ТР-2'
			 END AS 'VidLTekRem'                                                                                     --26.11.2025 Осмоловский:
			,r2.NeisprTekRem AS 'NeisprLTekRem'                                                                      --26.11.2025 Осмоловский:               
			,r2.ProbegTekRem as  'ProbegLTekRem'                                                                     --26.11.2025 Осмоловский:
			FROM #TPret r2
					outer apply (select top 1 * from dbo.nvTRK_DD d1 where d1.DorogaId=r2.DorogaId) DD --изменена привязка из-за задвоения СВР И ЮУР
					left join nvTRK_Departments nvd on DD.Id_Dep = nvd.ID_Department
					--
					left outer join nsTovPR_FOROSV osv2
						 on r2.PRemVRP = osv2.VRP_int        -- osv2.VRK
							
					outer apply (
						select top 1 p.SNAME, p.KodF, p.VRK, p.IdStampDep from dbo.nsTHP_PrStamp p
						where p.VRP_int = r2.PRemVRP and p.StartDate <= r2.PRem_dt
						order by p.StartDate DESC) prs	

					outer apply (
                        select top 1 w.ID, w.[Name] 
                        from kcmod.dbo.CaseOneParticipants w 
                        where w.vrk=prs.vrk and prs.vrk>0 and isnull(w.IsDel,0) = 0
						union
						select top 1 w.ID, w.[Name] 
                        from kcmod.dbo.CaseOneParticipants w 
                        where w.vrp_int=r2.PRemVRP and isnull(prs.vrk,0)=0 and isnull(w.IsDel,0) = 0
					) KA	

					left outer join nsTovPR_FOROSV osvVRP
						 on r2.VRP = osvVRP.VRP_int        -- osv2.VRK
							
					outer apply (
						select top 1 p.SNAME, p.KodF, p.VRK, p.IdStampDep from dbo.nsTHP_PrStamp p
						where p.VRP_int = r2.VRP and p.StartDate <= r2.Neispr_dt
						order by p.StartDate DESC) prsVRP	
													
					outer apply (select top 1 * from dbo.nvTRK_DD d1 where d1.DorogaId=DorVRP_Garant) DDV	   --филиал по виновнику   \
																											   --изменена привязка из-за задвоения СВР И ЮУР		
					left outer join dbo.nsBrak b on b.kodASOUP = case when left(r2.Neispr_kod123,1) = 9 then substring(r2.Neispr_kod123,5,3)
					                                                  else r2.KodBrakTn
                                                                 end --12.08.2022 Осмоловский:					
					--pai17.08.2011
								   and b.BrakVid_ev=3 --неисправности вагонов в справочнике идут с кодом 3
					--Проверки, нужно ли считать сроки.
					--=========================================================================
					outer apply (
				select
					--Есть срок передачи документов в претензионную или допретензионную работу.
					case when isnull(r2.Srok_FilG, r2.Srok_PassPP) is not null and isnull(r2.FilG_Get, r2.Send_PD) is null 
					          and r2.DoPret_Send is null --добавлено 02.03.2022
					          then 1 end as Has_Srok_FilG,
					--Есть срок предъявления документов для допретензионной работы.
					case when (r2.Srok_DoPret is not null and r2.DoPret_Send is null) then 1 end as Has_Srok_DoPret,
					--Есть дата передачи в допретензионную работу и срок подачи документов для ведения претензионной работы.
					case when isnull(r2.FilG_Get, DoPret_Dat) is not null and r2.Srok_PassPP is not null /*and r2.Send_PD is null*/ 
							  and (r2.DoPret_Sum>0 and isnull(r2.Stoim,0)=0 and r2.DoPret_Sum<>isnull(case when r2.Sum_Money>0 then Sum_Money else null end,--добавлено 02.03.2022
					                                        case when r2.Sud_Sum=r2.Sud_SumSogl and r2.Sud_SumSogl is not null 
					                                             then r2.Sud_SumSogl else 0.0 end) 
									or
									isnull(r2.Stoim,0)>0 and isnull(r2.Stoim,0)<>isnull(case when r2.Sum_Money>0 then Sum_Money else null end,
					                                        case when r2.Sud_Sum=r2.Sud_SumSogl and r2.Sud_SumSogl is not null 
					                                             then r2.Sud_SumSogl else 0.0 end) 
							  )

--							  and isnull(r2.Stoim,0)<>isnull(case when r2.Sum_Money>0 then Sum_Money else null end, -- было до 02.03.2022
--					                                        case when r2.Sud_Sum=r2.Sud_SumSogl and r2.Sud_SumSogl is not null 
--					                                             then r2.Sud_SumSogl else 0.0 end) 
					          then 1 end as Has_Srok_PassPP,
					--Есть срок предъявления претензии.
					case when r2.Srok_Pret is not null  and r2.Dat_Send is null and isnull(r2.Stoim,0)<>isnull(case when Sum_Money>0 then Sum_Money else null end,case when r2.Sud_Sum=r2.Sud_SumSogl and r2.Sud_SumSogl is not null then r2.Sud_SumSogl else 0.0 end) then 1 end as Has_Srok_Pret,
					
					--Есть срок подачи документов в судебную работу.
					case when r2.Srok_PassSud is not null and isnull(r2.Sud_PassDt, r2.Sud_Dat) is null and isnull(r2.Stoim,0)<>isnull(case when Sum_Money>0 then Sum_Money else null end,case when r2.Sud_Sum=r2.Sud_SumSogl and r2.Sud_SumSogl is not null then r2.Sud_SumSogl else 0.0 end) then 1 end as Has_Srok_PassSud,
					--Есть срок подачи искового заявления.
					case when r2.Srok_Sud is not null and r2.Sud_Dat is null and isnull(r2.Stoim,0)<>isnull(case when Sum_Money>0 then Sum_Money else null end,case when r2.Sud_Sum=r2.Sud_SumSogl and r2.Sud_SumSogl is not null then r2.Sud_SumSogl else 0.0 end) then 1 end as Has_Srok_Sud
				) t
					--==========================================================================
					/*outer apply (
						select
							--Есть срок передачи документов в претензионную или допретензионную работу.
							case when isnull(r2.Srok_FilG, r2.Srok_PassPP) is not null and isnull(r2.FilG_Get, r2.Send_PD) is null then 1 end as Has_Srok_FilG,
							--Есть срок предъявления документов для допретензионной работы.
							case when r2.Srok_DoPret is not null and r2.DoPret_Send is null then 1 end as Has_Srok_DoPret,
							--Есть срок подачи документов для ведения претензионной работы.
							case when r2.FilG_Get is not null and r2.Srok_PassPP is not null and r2.Send_PD is null and isnull(r2.Stoim,0)<>isnull(case when r2.Sum_money>0 then r2.Sum_money else null end,case when r2.Sud_Sum=r2.Sud_SumSogl and r2.Sud_SumSogl is not null then r2.Sud_SumSogl else 0.0 end) then 1 end as Has_Srok_PassPP,
							--Есть срок предъявления претензии.
							case when r2.Srok_Pret is not null and r2.Dat_Send is null and isnull(r2.Stoim,0)<>isnull(case when r2.Sum_money>0 then r2.Sum_money else null end,case when r2.Sud_Sum=r2.Sud_SumSogl and r2.Sud_SumSogl is not null then r2.Sud_SumSogl else 0.0 end) then 1 end as Has_Srok_Pret,
							--Есть срок подачи документов в судебную работу.
							case when r2.Srok_PassSud is not null and isnull(r2.Sud_PassDt, r2.Sud_Dat) is null and isnull(r2.Stoim,0)<>isnull(case when r2.Sum_money>0 then r2.Sum_money else null end,case when r2.Sud_Sum=r2.Sud_SumSogl and r2.Sud_SumSogl is not null then r2.Sud_SumSogl else 0.0 end) then 1 end as Has_Srok_PassSud,
							--Есть срок подачи искового заявления.
							case when r2.Srok_Sud is not null and r2.Sud_Dat is null and isnull(r2.Stoim,0)<>isnull(case when r2.Sum_money>0 then r2.Sum_money else null end,case when r2.Sud_Sum=r2.Sud_SumSogl and r2.Sud_SumSogl is not null then r2.Sud_SumSogl else 0.0 end) then 1 end as Has_Srok_Sud
						) t
					*/	--=========================================================================
				 left join kcmod.dbo.nsTovPr_ForOsv osvTR on osvTR.Vrp_int=r2.DepTekRem
			            WHERE  --АТ 19.09.12 Ограничения для режима корректировки по второму филиалу (виновнику)		
					(
						@RegRed in (6, 12) or (@RegRed=0 and @Col is null) --19.01.2022 Лапунов А.В.
						or @Id_Login=-1 or @Centr=1
						or (@RegRed =10 AND DorVRP_Garant in (select Dor from @TDor ))--по дорогам виновника
						or (@RegRed =10 AND r2.DorogaID in (select Dor from @TDor )) -- по филиалу
						or (@RegRed =0 AND @Centr=0 and r2.DorogaID in (select Dor from @TDor )) --13.01.2022 Лапунов А.В. добавил фильтр, когда департамент не верхнего уровня для пономерных списков
					)
					and (@Col is null
						or (@Col = 'Srok_FilG_Kol' and t.Has_Srok_FilG = 1)
						or (@Col = 'Srok_FilG_Nar' and t.Has_Srok_FilG = 1 and (r2.Srok_FilGColor > 0 or r2.Srok_PassPPColor > 0))
						or (@Col = 'Srok_FilG_Nar_Ar' and t.Has_Srok_FilG = 1 and (r2.Srok_FilGColor > 0 or r2.Srok_PassPPColor > 0) and r2.Rad_Garant = 1)
						or (@Col = 'Srok_FilG_Nar_10' and t.Has_Srok_FilG = 1 and (r2.Srok_FilGColor = 1 or r2.Srok_PassPPColor = 1))
						or (@Col = 'Srok_FilG_Nar_10_Ar' and t.Has_Srok_FilG = 1 and (r2.Srok_FilGColor = 1 or r2.Srok_PassPPColor = 1) and r2.Rad_Garant = 1)
						or (@Col = 'Srok_FilG_Nar_11_30' and t.Has_Srok_FilG = 1 and (r2.Srok_FilGColor = 2 or r2.Srok_PassPPColor = 2))
						or (@Col = 'Srok_FilG_Nar_11_30_Ar' and t.Has_Srok_FilG = 1 and (r2.Srok_FilGColor = 2 or r2.Srok_PassPPColor = 2) and r2.Rad_Garant = 1)
						or (@Col = 'Srok_FilG_Nar_31' and t.Has_Srok_FilG = 1 and (r2.Srok_FilGColor = 3 or r2.Srok_PassPPColor = 3))
						or (@Col = 'Srok_FilG_Nar_31_Ar' and t.Has_Srok_FilG = 1 and (r2.Srok_FilGColor = 3 or r2.Srok_PassPPColor = 3) and r2.Rad_Garant = 1)
						or (@Col = 'Srok_DoPret_Kol' and t.Has_Srok_DoPret = 1)
						or (@Col = 'Srok_DoPret_Nar' and t.Has_Srok_DoPret = 1 and r2.Srok_DoPretColor > 0)
						or (@Col = 'Srok_DoPret_Nar_10' and t.Has_Srok_DoPret = 1 and r2.Srok_DoPretColor = 1)
						or (@Col = 'Srok_DoPret_Nar_11_30' and t.Has_Srok_DoPret = 1 and r2.Srok_DoPretColor = 2)
						or (@Col = 'Srok_DoPret_Nar_31' and t.Has_Srok_DoPret = 1 and r2.Srok_DoPretColor = 3)
						or (@Col = 'Srok_PassPP_Kol' and t.Has_Srok_PassPP = 1)
						or (@Col = 'Srok_PassPP_Nar' and t.Has_Srok_PassPP = 1 and r2.Srok_PassPPColor > 0)
						or (@Col = 'Srok_PassPP_Nar_10' and t.Has_Srok_PassPP = 1 and r2.Srok_PassPPColor = 1)
						or (@Col = 'Srok_PassPP_Nar_11_30' and t.Has_Srok_PassPP = 1 and r2.Srok_PassPPColor = 2)
						or (@Col = 'Srok_PassPP_Nar_31' and t.Has_Srok_PassPP = 1 and r2.Srok_PassPPColor = 3)
						or (@Col = 'Srok_Pret_Kol' and t.Has_Srok_Pret = 1)
						or (@Col = 'Srok_Pret_Nar' and t.Has_Srok_Pret = 1 and r2.Srok_PretColor > 0)
						or (@Col = 'Srok_Pret_Nar_10' and t.Has_Srok_Pret = 1 and r2.Srok_PretColor = 1)
						or (@Col = 'Srok_Pret_Nar_11_30' and t.Has_Srok_Pret = 1 and r2.Srok_PretColor = 2)
						or (@Col = 'Srok_Pret_Nar_31' and t.Has_Srok_Pret = 1 and r2.Srok_PretColor = 3)
						or (@Col = 'Srok_PassSud_Kol' and t.Has_Srok_PassSud = 1)
						or (@Col = 'Srok_PassSud_Nar' and t.Has_Srok_PassSud = 1 and r2.Srok_PassSudColor > 0)
						or (@Col = 'Srok_PassSud_Nar_10' and t.Has_Srok_PassSud = 1 and r2.Srok_PassSudColor = 1)
						or (@Col = 'Srok_PassSud_Nar_11_30' and t.Has_Srok_PassSud = 1 and r2.Srok_PassSudColor = 2)
						or (@Col = 'Srok_PassSud_Nar_31' and t.Has_Srok_PassSud = 1 and r2.Srok_PassSudColor = 3)
						or (@Col = 'Srok_Sud_Kol' and t.Has_Srok_Sud = 1)
						or (@Col = 'Srok_Sud_Nar' and t.Has_Srok_Sud = 1 and r2.Srok_SudColor > 0)
						or (@Col = 'Srok_Sud_Nar_10' and t.Has_Srok_Sud = 1 and r2.Srok_SudColor = 1)
						or (@Col = 'Srok_Sud_Nar_11_30' and t.Has_Srok_Sud = 1 and r2.Srok_SudColor = 2)
						or (@Col = 'Srok_Sud_Nar_31' and t.Has_Srok_Sud = 1 and r2.Srok_SudColor = 3)
						--04.09.2020 Лапунов А.В.
						or (@Col = 'Srok_NotFull_Kompl' and r2.Or_Kompl_Buh is not null and r2.Dat_Pass is null)
						--08.09.2020 Лапунов А.В.
						or (@Col = 'Srok_FilO_Kol' and Dat_Pass is not null and PassDoc_date is null and FilG_Get is null and Send_PD is null)
						or (@Col = 'Srok_FilO_Nar' and Dat_Pass is not null and PassDoc_date is null and FilG_Get is null and Send_PD is null and r2.Srok_FilOColor > 0)
						or (@Col = 'Srok_FilO_Nar_10' and Dat_Pass is not null and PassDoc_date is null and FilG_Get is null and Send_PD is null and r2.Srok_FilOColor = 1)
						or (@Col = 'Srok_FilO_Nar_11_30' and Dat_Pass is not null and PassDoc_date is null and FilG_Get is null and Send_PD is null and r2.Srok_FilOColor = 2)
						or (@Col = 'Srok_FilO_Nar_31' and Dat_Pass is not null and PassDoc_date is null and FilG_Get is null and Send_PD is null and r2.Srok_FilOColor = 3)
						--28.10.2020 Лапунов А.В.
						or (@Col = 'Srok_FilO_PerV' and isnull(Tarif_NoPret,0)=0 and Tarif_PassDat is null)
					)
					--06.12.2021 Лапунов А.В.
					and (@GarantKP is null or isnull(GarantKP,0)>0)
				ORDER BY r2.DorogaId, r2.Dat_Rem DESC ,r2.Index_Pret asc
	end
	else if @Reg = 1
	begin
		select DorogaId, Dat_Rem, Dat_Pass, Srok_FilG, Srok_FilGColor, PassDoc_Date, PassDoc_Name, FilG_Get, Srok_DoPret, Srok_DoPretColor,
				DoPret_Send, Srok_PassPP, Srok_PassPPColor, Send_PD, Srok_Pret, Srok_PretColor, Dat_Send, Srok_PassSud,
				Srok_PassSudColor, Sud_PassDt, Sud_Dat, Srok_Sud, Srok_SudColor, Rad_Garant,Or_Kompl_Buh,Srok_FilOColor,Tarif_NoPret,Tarif_PassDat,
				case when isnull(Stoim, 0) = 0 and DoPret_Sum>0 then DoPret_Sum else Stoim end as Stoim, --02.03.2022
				--Stoim,
				Sum_money,
				Sud_Sum,Sud_SumSogl,
				DoPret_Dat, --02.03.2022 Афанасьева - добавлена дата отправки допрет.письма,
				ProbegOtc
			from #TPret r2
	end

	print 'Основная выборка выполнена'
	select @t2 = getdate()
	print datediff(millisecond, @t1, @t2) 
	set @t1= @t2

	print 'Полное время выполнения процедуры - '+ Str (datediff(millisecond, @t0, @t2), 8)


	RETURN @Kz	

	DROP  TABLE #ddn
	DROP  TABLE #deps

