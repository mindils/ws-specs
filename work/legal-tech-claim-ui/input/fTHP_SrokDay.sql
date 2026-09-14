-- Источник: OBJECT_DEFINITION(OBJECT_ID('dbo.fTHP_SrokDay')) на MSSQL (rvk-ws), снято 2026-09-11
--
-- Краткая справка по семантике:
--   @type = 1 -> КАЛЕНДАРНЫЕ дни: просто dateadd(day, @Srok, @DatStart).
--   @type = 2 -> РАБОЧИЕ дни: полные недели по 5 раб. дней, старт переносится с сб/вс
--                на понедельник, при попадании/перелёте через выходные к остатку
--                прибавляется 2 дня, затем добавляются праздники из dbo.nsHoliday
--                (HDay в интервале [@DatStart, @DatEnd]) по той же 5-дневной схеме.
--   @type = 0 / NULL -> возвращает @DatStart без изменений (срок не назначается).
--   @DatStart IS NULL или @Srok IS NULL -> @DatStart.
--   В nvPretSrok для KodPret=1 у всех строк IdOper 9..14,16 стоит SrokType=2,
--   т.е. все сроки претензионной цепочки — в РАБОЧИХ днях.
--   Календарь выходных: DatePart(weekday,...) = 1 (воскресенье) и 7 (суббота),
--   т.е. подразумевается @@DATEFIRST=7 (us_русский default-настройка сервера);
--   праздники — таблица dbo.nsHoliday (колонка HDay).
--
-- Вызовы из pThp_PretTehSelect2 всегда либо с @type из nvPretSrok.SrokType (=2),
-- либо с явным 2 (для «цветовых» надбавок 1/10/30 рабочих дней).

-- =============================================02.07.2018 Афанасьева
-- Определение срока в рабочих днях.
-- 25.07.2018 А.А.Валуев Исправил прибавление остатка, если попадаем на выходные или перескакиваем через них.
-- select [dbo].[fTHP_SrokRabDay] ('20180427',30,1)
-- =============================================
CREATE FUNCTION [dbo].[fTHP_SrokDay](
	@DatStart SMALLDATETIME,
	@Srok TINYINT, --количество рабочих дней,
    @type tinyint = 0 -- 2 - Поправка на рабочие дни, 1 - Календарные дни
)
RETURNS SMALLDATETIME
AS
BEGIN
	IF @DatStart is null or @Srok is null
		RETURN @DatStart;

	if isnull(@type, 0) = 1 begin
		return dateadd(day, @Srok, @DatStart)
	end else if isnull(@type, 0) = 2 begin
	    DECLARE @DatEnd SMALLDATETIME, @CntWeek TINYINT, @OstWeek TINYINT, @Holidays TINYINT

		select
			@CntWeek = @Srok / 5, --Количество полных недель (по 5 раб. дней).
			@OstWeek = @Srok % 5, --Остаток рабочих дней от полных недель.
			--Переносим начало периода с выходных на понедельник.
			@DatStart = case
							when DatePart(weekday, @DatStart) = 1 then @DatStart + 1 --с воскресенья на пн
							when DatePart(weekday, @DatStart) = 7 then @DatStart + 2 --с сб на пн
							else @DatStart
							end
		--Прибавляем кол-во полных недель.
		select @DatEnd = dateadd(day, @CntWeek * 7, @DatStart)
		--Если после прибавления остатка попадём на выходные или перелетим через них, то добавляем 2 дня.
		if datepart(weekday, @DatEnd) + @OstWeek > 6
			set @OstWeek = @OstWeek + 2
		--Прибавляем остаток.
		select @DatEnd = dateadd(day, @OstWeek, @DatEnd)
		--Прибавляем праздничные дни.
		select @Holidays = count(*) from dbo.nsHoliday where @DatStart <= HDay and @DatEnd >= HDay
		if @Holidays > 0
		BEGIN
			select
				@CntWeek = @Holidays / 5, --Количество полных недель (по 5 раб. дней).
				@OstWeek = @Holidays % 5 --Остаток рабочих дней от полных недель.
			--Прибавляем кол-во полных недель.
			select @DatEnd = DateAdd(day, @CntWeek * 7, @DatEnd)
			--Если после прибавления остатка попадём на выходные или перелетим через них, то добавляем 2 дня.
			if datepart(weekday, @DatEnd) + @OstWeek > 6
				set @OstWeek = @OstWeek + 2
			select @DatEnd = DateAdd(day, @OstWeek, @DatEnd)
		END

	    RETURN @DatEnd
    end

    return @DatStart;
END
