**1. Интерфейс**

_**Форма списка:**_

![image](/uploads/71537fc7cfb50a52793949400c3267b7/image.png){width=524 height=299}

    - Меню навигации по справочникам и путь в иерархии (категории и справочники)
    - Поиск по всем полям (полнотекстовый поиск).
    - Таблица записей.
    - В каждой таблице первая колонка «Действия»:
       • Открыть – открывает запись на просмотр.
       • Редактировать – форма редактирования записи.
       • Копировать – открывает форму редактирования записи с заполненными данными на основании выделенной строки.
       • Закрыть – установка значения колонки «recdateend» записи в бд – текущая дата и время.
       • Удалить - установка значения колонки «lastrec» записи в бд – 0.
    - Справа меню Настройки и действия:
       • Галочками выбираются поля для выгрузки в Excel.
       • Кнопка сброса настроек
       • Шаблон для загрузки – выгрузка данных в файл формата xlsx. В файле первой строкой имена колонок, по которым в дальнейшем из файла загружаются данные в бд. Значения обновляются из файла.
       • Загрузить из Excel – импорт данных из файла в бд.
       • Выгрузить в Excel – экспорт данных в в файл формата xlsx. Без строки с именами колонок в бд. Наименование колонок берутся из интерфейса.
       • Загрузить файлы – кастомная специфическая загрузка из файла Excel (делался фукционал по задаче от Чернышева В., уже может не использоваться).
    - Пагинация. Переключение на следущую и предыдущую страницы, подсчет количества актуальных записей.

_**Форма просмотра записи:**_

Системные вкладки:
- Описание – вывод данных строки таблицы.
- История – таблица истории изменения строки за все время.
Настраиваемы вкладки – настраиваемые вкладки отображения данных связных таблиц.

![image](/uploads/edaf98c3aac6dba16a4d803808c6fe60/image.png){width=524 height=325}

_**Форма редактирования записи:**_

    - Системные поля: Имя пользователя, Дата начала и Дата окончания.
    - Редактирование полей по типам данных.
    - Возможность lookup связных таблиц.

_**Форма конфигурации таблицы:**_

Возможность добавления полей:

    - Отображение названия поля. 
    - Тип ( в последствии тип данных в бд). 
    - Код (системное имя в бд). 
    - Порядок сортировки
    - Размер
    - Является ли поле бизнес ключем.
    - Настройка валидации полей (настройка цепочки применения правил валидации).
    - Настройка связей таблиц.
    - Дополнительные настройки отображения связанных полей
    - Дополнительные параметры таблицы.
    - Настройка виртуальных полей (в бд не хранятся).
    - Настройка дополнительных фильтров для связанных с другой таблицей полей.

_**Форма настройки фильтров по умолчанию:**_

Настройки сохраняются в бд в формате JSON. При открытии формы таблицы настройки фильтров устанавливаются в таблицы.

_**Динамические фильтры:**_

    - Строка и текст. Варианты сравнения: содержит, равно, не равно, входит в список, пустое значение, не пустое значение.
    - Число. Варианты сравнения: равно, не равно, входит в список, пустое значение, не пустое значение, исключая.
    - Булево. Да/Нет.
    - Дата и дата время. Варианты сравнения: равно, не равно, меньше, меньше или равно, больше, больше или равно, в диапазоне, пустое значение, не пустое значение, текущая дата, текущий месяц, следующий месяц, предыдущий месяц, за последние N.

**2. Справочник «Реестр контейнеров».**
```
CREATE TABLE IF NOT EXISTS "MDM_DATA".cont (
        // Номер контейнера (бизнес ключ)
	cont_num varchar(255) NOT NULL,
        // Заводской номер                      
	manuf_num varchar(255) NULL,
        // Изготовитель                         
	manufacturer varchar(255) NULL,
        // Собственник (link -> v_org_passports.org_id)                      
	owner_org_id int8 NULL,
        // Модель (link -> cont_model_char.model)                              
	model varchar(255) NULL,
        // Код типа (link -> v_cont_type_bige.code)                             
	type_code varchar(255) NULL,
        // Наименование типа (link -> code -> v_cont_type_bige)                         
	type_name varchar(255) NULL,
        // Код размера (link -> code -> v_cont_size_big)                         
	size_code varchar(255) NULL,
        // Длина (фут) (link -> code -> v_cont_size_big)                         
	width_f varchar(255) NULL,
        // Максимальная масса брутто (кг.)                           
	max_gross_mass int8 NULL,
        // Собственная масса (кг.)                            
	tare_mass int8 NULL,
        // Полезная нагрузка (кг.)                                 
	payload int8 NULL,
        // Вместимость (л.)                                   
	capacity int8 NULL,
        // Дата следующего освидетельствования                                  
	next_survey_date date NULL,
        // системное поле - уникальный идентификатор в бд (не отображаемое в интерфейсе)                          
	data_id int8 NOT NULL,
        // системное поле - признак удаленной записи (не отображаемое в интерфейсе)                               
	lastrec int8 DEFAULT 1 NOT NULL,
        // системное поле - дата начала действия записи                     
	recdatebegin timestamp DEFAULT now() NOT NULL,
        // системное поле - дата окончания действия записи       
	recdateend timestamp DEFAULT '3000-01-01 00:00:00'::timestamp without time zone NOT NULL,
        // системное поле - дата обновления записи (не отображаемое в интерфейсе)
	recdatenew timestamp DEFAULT now() NOT NULL,
        // системное поле - механизм для типов колонки "последовательность" (не отображаемое в интерфейсе)        
	trans_id int8 NOT NULL,
        // Обобщенная характеристика (link -> gen_char_cont.code)
	gen_char_id int8 NULL,
        // системное поле - имя пользователя изменившего запись                              
	user_name varchar(255) NULL,
        // Дата постройки
	constr_date date NULL,
        // Модернизация крыши                                       
	roof_upgrade bool NULL,
        // Дата модернизации крыши                              
	roof_upgrade_date date NULL,
        // Уникальный идентификатор                         
	CONSTRAINT cont_pkey PRIMARY KEY (data_id)                   
);

// Виртуальные поля
Тенты, кол-во - model.tenty (link -> model -> cont_model_char)
Дуги, кол-во - - model.dugi (link -> model -> cont_model_char)
Тросы, кол-во - model.trosy (link -> model -> cont_model_char)
Вент. отверст., кол-во - model.vent (link -> model -> cont_model_char)

```

_**Связные таблицы со справочником «Реестр контейнеров».**_

1. Организации справочник ФГК (v_org_passports) – связь [один к одному] по полю «org_id».
```
CREATE OR REPLACE VIEW "MDM_DATA".v_org_passports
AS SELECT
    // ОКПО организации
    okpo,
    // Сокращенное наименование организации                                                       
    shname,
    // Признак                                                           
    sign,
    // ИД организации (бизнес ключ)                                                             
    org_id,
    // системное поле - признак удаленной записи (не отображаемое в интерфейсе)                                                         
    1 AS lastrec,
    // системное поле - дата окончания действия записи                                                      
    '3000-01-01 00:00:00'::timestamp without time zone AS recdateend,
    // Наименование организации
    fullname,
    // системное поле - дата начала действия записи                                                         
    CURRENT_TIMESTAMP - '1 day'::interval AS recdatebegin,
    // ИНН организации
    inn                                                               
   FROM "MDM_SHARE".v_org_passports;
```
Шаблон создания view
```
CREATE OR REPLACE VIEW "MDM_SHARE".v_org_passports
AS SELECT org_id,
    shname,
    okpo,
    inn,
    fullname,
    sign
   FROM nsi.org_passports o
  WHERE org_id >= 10000000::numeric;
```
2. Справочник характеристик моделей (cont_model_char) – связь [один к одному] по полю «model».
```
CREATE TABLE TABLE IF NOT EXISTS "MDM_DATA".cont_model_char (
        // ИД характеристики (бизнес ключ)
	id_char int8 NOT NULL,
        // Модель контейнера
	model varchar(255) NULL,
        // Тенты, кол-во
	tenty int8 NULL,
        // Дуги, кол-во
	dugi int8 NULL,
        // Тросы, кол-во
	trosy int8 NULL,
        // системное поле - уникальный идентификатор в бд (не отображаемое в интерфейсе)
	data_id int8 DEFAULT nextval('"MDM_SYS".sq_data_id'::regclass) NOT NULL,
        // системное поле - признак удаленной записи (не отображаемое в интерфейсе) 
	lastrec int8 DEFAULT 1 NOT NULL,
        // системное поле - дата начала действия записи
	recdatebegin timestamp DEFAULT now() NOT NULL,
        // системное поле - дата окончания действия записи
	recdateend timestamp DEFAULT '3000-01-01 00:00:00'::timestamp without time zone NOT NULL,
        // системное поле - дата обновления записи (не отображаемое в интерфейсе)
	recdatenew timestamp DEFAULT now() NOT NULL,
        // системное поле - имя пользователя изменившего запись 
	user_name varchar(255) NULL,
        // системное поле - механизм для типов колонки "последовательность" (не отображаемое в интерфейсе)
	trans_id int8 DEFAULT nextval('"MDM_SYS".sq_trans_id'::regclass) NOT NULL,
        // Вент. отверст., кол-во
	vent int8 NULL,
        // Уникальный идентификатор
	CONSTRAINT cont_model_char_pkey PRIMARY KEY (data_id)
);
```
3. Справочник типов контейнеров (v_cont_type_bige) - связь [один к одному] по полю «code».
```
CREATE OR REPLACE VIEW "MDM_DATA".v_cont_type_bige
AS SELECT
    // Код типа 
    code,
    // системное поле - дата окончания действия записи  
    '3000-01-01 00:00:00'::timestamp without time zone AS recdateend,
    // ИД типа (бизнес ключ)
    cont_type_id,
    // Детальные данные
    detail,
    // системное поле - дата начала действия записи
    now() - '1 day'::interval AS recdatebegin,
    // системное поле - признак удаленной записи (не отображаемое в интерфейсе)
    1 AS lastrec,
    // Наименование типа
    type_name
   FROM "MDM_SHARE".v_cont_type_bige;
```
Шаблон создания view
```
CREATE OR REPLACE VIEW "MDM_SHARE".v_cont_type_bige
AS SELECT cont_type_id,
    type_name,
    detail,
    code,
    kind_id
   FROM nsi_db.cont_type_big;
```
4. Справочник размеров контейнеров (v_cont_size_big) - связь [один к одному] по полю «code».
```
CREATE OR REPLACE VIEW "MDM_DATA".v_cont_size_big
AS SELECT
    // системное поле - признак удаленной записи (не отображаемое в интерфейсе) 
    1 AS lastrec,
    '3000-01-01 00:00:00'::timestamp without time zone AS recdateend,
    // ИД размера
    cont_size_id,
    // системное поле - дата начала действия записи
    CURRENT_TIMESTAMP - '1 day'::interval AS recdatebegin,
    // Код размера
    code,
    // Высота (мм.)
    height,
    // Комментарий
    comments,
    // Ширина (фут)
    width_f
   FROM "MDM_SHARE".v_cont_size_big;
```
Шаблон создания view
```
CREATE OR REPLACE VIEW "MDM_SHARE".v_cont_size_big
AS SELECT cont_size_id,
    height,
    width_f,
    code,
    heighttxt,
    comments
   FROM nsi_db.cont_size_big;
```
5. Обобщенные характеристики контейнеров (gen_char_cont) - связь [один к одному] по полю «char_id».
```
CREATE TABLE TABLE IF NOT EXISTS "MDM_DATA".gen_char_cont (
        // ИД характеристики
	char_id int8 NOT NULL,
        // Наименование характеристики
	char_name varchar(255) NULL,
        // системное поле - уникальный идентификатор в бд (не отображаемое в интерфейсе)
	data_id int8 NOT NULL,
        // системное поле - признак удаленной записи (не отображаемое в интерфейсе)                               
	lastrec int8 DEFAULT 1 NOT NULL,
        // системное поле - дата начала действия записи
	recdatebegin timestamp DEFAULT now() NOT NULL,
        // системное поле - дата окончания действия записи
	recdateend timestamp DEFAULT '3000-01-01 00:00:00'::timestamp without time zone NOT NULL,
        // системное поле - дата обновления записи (не отображаемое в интерфейсе)
	recdatenew timestamp DEFAULT now() NOT NULL,
        // системное поле - механизм для типов колонки "последовательность" (не отображаемое в интерфейсе)
	trans_id int8 NOT NULL,
        // Наименование характеристики (в множ. ч.)
	char_name_pf varchar(255) NULL,
        // Уникальный идентификатор
	CONSTRAINT gen_char_cont_pkey PRIMARY KEY (data_id)
);
```
5. Прикрепленные файлы (cont_file) - ссылается на реестр контейнеров.
```
CREATE TABLE IF NOT EXISTS "MDM_DATA".cont_file (
        // ИД файла (бизнес ключ)
	file_id int8 NOT NULL,
        // Номер контейнера (link -> cont.cont_num)
	cont_num varchar(255) NULL,
        // Вид файла (link -> eri_file_type.file_type_id)
	file_type int8 NULL,
        // Комментарий
	"comment" varchar(255) NULL,
        // Файл (link -> data_file.file_id [file_name])
	file int8 NULL,
        // системное поле - уникальный идентификатор в бд (не отображаемое в интерфейсе)
	data_id int8 NOT NULL,
        // системное поле - признак удаленной записи (не отображаемое в интерфейсе)
	lastrec int8 DEFAULT 1 NOT NULL,
        // системное поле - дата начала действия записи
	recdatebegin timestamp DEFAULT now() NOT NULL,
        // системное поле - дата окончания действия записи 
	recdateend timestamp DEFAULT '3000-01-01 00:00:00'::timestamp without time zone NOT NULL,
        // системное поле - дата обновления записи (не отображаемое в интерфейсе)
	recdatenew timestamp DEFAULT now() NOT NULL,
        // системное поле - механизм для типов колонки "последовательность" (не отображаемое в интерфейсе)
	trans_id int8 NOT NULL,
        // Имя файла
	file_name varchar(255) NULL,
        // системное поле - имя пользователя изменившего запись
	user_name varchar(255) NULL,
        // Уникальный идентификатор
	CONSTRAINT cont_file_pkey PRIMARY KEY (data_id)
);

// Связанная системная таблица файлов
CREATE TABLE IF NOT EXISTS "MDM_SYS".data_file (
        // Уникальный идентификатор
	id int4 DEFAULT nextval('"MDM_SYS".sq_data_file'::regclass) NOT NULL,
        // Идентификатор пользователя
	user_id int4 NOT NULL,
        // Не знаю для чего поле, много NULL значений
	note varchar(4000) NULL,
        // Имя файла
	file_name varchar(255) NOT NULL,
        // Тип файла в формате mime пример: "application/pdf"
	mime_type varchar(255) NULL,
        // Двоичные данные файла. Старые данные тут хранятся новые в S3 хранилище
	file_content bytea NULL,
        // системное поле - дата обновления записи
	recdatenew timestamp NOT NULL,
        // системное поле - дата начала действия записи 
	recdatebegin timestamp NOT NULL,
        // системное поле - дата окончания действия записи 
	recdateend timestamp NOT NULL,
        // Идентификатор файла для связи с справочниками
	file_id int4 NOT NULL,
        // Тип файла (не знаю зачем поле) - много NULL значений
	file_type varchar(1000) NULL,
        // не знаю зачем поле - много NULL значений
	file_link varchar(1000) NULL,
        // Размер файла
	file_size int4 NULL,
        // не знаю чаем поле - много NULL значений
	flesign int4 NULL,
        // Уникальный идентификатор в S3 хранилище
	s3_uuid varchar NULL
);
CREATE SEQUENCE "MDM_SYS".sq_data_file
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 9223372036854775807
	START 1
	CACHE 1
	NO CYCLE;
```
6. Справочник видов прикрепляемых файлов (eri_file_type) - ссылается на Прикрепленные файлы.
```
CREATE TABLE IF NOT EXISTS "MDM_DATA".eri_file_type (
        // ИД вида (бизнес ключ)
	file_type_id int8 NOT NULL,
        // Наименование вида
	file_type_name varchar(255) NULL,
        // системное поле - уникальный идентификатор в бд (не отображаемое в интерфейсе)
	data_id int8 NOT NULL,
        // системное поле - признак удаленной записи (не отображаемое в интерфейсе)
	lastrec int8 DEFAULT 1 NOT NULL,
        // системное поле - дата начала действия записи
	recdatebegin timestamp DEFAULT now() NOT NULL,
        // системное поле - дата окончания действия записи
	recdateend timestamp DEFAULT '3000-01-01 00:00:00'::timestamp without time zone NOT NULL,
        // системное поле - дата обновления записи (не отображаемое в интерфейсе)
	recdatenew timestamp DEFAULT now() NOT NULL,
        // системное поле - механизм для типов колонки "последовательность" (не отображаемое в интерфейсе)
	trans_id int8 NOT NULL,
        // Уникальный идентификатор
	CONSTRAINT eri_file_type_pkey PRIMARY KEY (data_id)
);
```

**Таблицы (вкладки в интерфейсе в форме карточки) для справочника "Реестр контейнеров"**

1. Характеристики контейнеров (cont_prop) - связь один ко многим по полю "cont_num"
```
CREATE TABLE IF NOT EXISTS "MDM_DATA".cont_prop (
        // ИД характеристики (бизнес ключ)
	prop_id int8 NOT NULL,
        // Номер контейнера (link -> cont_num -> cont)
	cont_num varchar(255) NULL,
        // Наименование характеристики (link -> prop_type_id -> cont_prop_type)
	prop_type_id int8 NULL,
        // Значение характеристики
	prop_value varchar(2000) NULL,
        // Примечание
	"comment" varchar(255) NULL,
        // системное поле - уникальный идентификатор в бд (не отображаемое в интерфейсе)
	data_id int8 NOT NULL,
        // системное поле - признак удаленной записи (не отображаемое в интерфейсе)
	lastrec int8 DEFAULT 1 NOT NULL,
        // системное поле - дата начала действия записи
	recdatebegin timestamp DEFAULT now() NOT NULL,
        // системное поле - дата окончания действия записи
	recdateend timestamp DEFAULT '3000-01-01 00:00:00'::timestamp without time zone NOT NULL,
        // системное поле - дата обновления записи (не отображаемое в интерфейсе)
	recdatenew timestamp DEFAULT now() NOT NULL,
        // системное поле - механизм для типов колонки "последовательность" (не отображаемое в интерфейсе)
	trans_id int8 NOT NULL,
        // Уникальный идентификатор
	CONSTRAINT cont_prop_pkey PRIMARY KEY (data_id)
);
// Связана с "Справочник характеристик контейнеров" (cont_prop_type) один к одному по полю "prop_type_id"
CREATE TABLE IF NOT EXISTS "MDM_DATA".cont_prop_type (
        // ИД характеристики (бизнес ключ)
	prop_type_id int8 NOT NULL,
        // Наименование характеристики
	prop_type_name varchar(255) NULL,
        // Наименование группы
	prop_group_name varchar(255) NULL,
        // Наименование подгруппы
	prop_subgroup_name varchar(255) NULL,
        // системное поле - уникальный идентификатор в бд (не отображаемое в интерфейсе)
	data_id int8 NOT NULL,
        // системное поле - признак удаленной записи (не отображаемое в интерфейсе)
	lastrec int8 DEFAULT 1 NOT NULL,
        // системное поле - дата начала действия записи
	recdatebegin timestamp DEFAULT now() NOT NULL,
        // системное поле - дата окончания действия записи
	recdateend timestamp DEFAULT '3000-01-01 00:00:00'::timestamp without time zone NOT NULL,
        // системное поле - дата обновления записи (не отображаемое в интерфейсе)
	recdatenew timestamp DEFAULT now() NOT NULL,
        // системное поле - механизм для типов колонки "последовательность" (не отображаемое в интерфейсе)
	trans_id int8 NOT NULL,
        // Комментарий
	"comment" varchar(255) NULL,
        // Наименование характеристики (лат.)
	prop_type_name_lat varchar(255) NULL,
        // Уникальный идентификатор
	CONSTRAINT cont_prop_type_pkey PRIMARY KEY (data_id)
);
```

3. Операции (v_dislocation_cont) - связь один ко многим по полю "cont_num"
```
CREATE OR REPLACE VIEW "MDM_DATA".v_dislocation_cont
AS SELECT
    // Дата операции 
    date_op,
    // Дорога назначения
    rw_to_name,
    // Грузополучатель
    gp_name,
    // Дата получения
    recdate,
    // Дорога дислокации
    rw_disl_name,
    // Источник
    source_name,
    // Груз
    fr_name,
    // Номер контейнера (link -> cont_num -> cont) 
    cont_num,
    // Номер вагона
    wagnum,
    // системное поле - дата начала действия записи
    CURRENT_TIMESTAMP - '1 day'::interval AS recdatebegin,
    // Станция дислокации
    st_name_disl,
    // системное поле - дата окончания действия записи
    '3000-01-01 00:00:00'::timestamp without time zone AS recdateend,
    // ИД записи (Бизнес ключ)
    id_rec,
    // Груженый
    pr_gruj,
    // Номер накладной
    nom_nak,
    // системное поле - признак удаленной записи (не отображаемое в интерфейсе)
    1 AS lastrec,
    // НРП
    nrp,
    // Станция назначения
    st_name_to,
    // Вес груза (кг.)
    mas_grz,
    // Грузоотправитель
    gotpr_name,
    // Наименование операции
    oper_name
   FROM "MDM_SHARE".v_dislocation_cont;
```
Шаблон создания view
```
CREATE OR REPLACE VIEW "MDM_SHARE".v_dislocation_cont
AS SELECT d.dwh_pk_id AS id_rec,
    d.cont_num,
    d.wagnum,
    d.operdate AS date_op,
    nvl(op.name, opw.object_vname) AS oper_name,
    NULL::text AS nrp,
        CASE
            WHEN d.pogrfag::numeric = 1::numeric THEN 'Да'::text
            ELSE 'Нет'::text
        END AS pr_gruj,
    s_disl.st_name AS st_name_disl,
    s_disl.rw_short_name AS rw_disl_name,
    s_to.st_name AS st_name_to,
    s_to.rw_short_name AS rw_to_name,
    fr.fr_name,
    d.weightnet AS mas_grz,
    d.invnumber AS nom_nak,
    gotpr.shname AS gotpr_name,
    gp.shname AS gp_name,
    d.recdatenew AS recdate,
        CASE
            WHEN d.src_id::numeric = 1::numeric THEN 'Дислокация контейнеров'::text
            ELSE 'Дислокация вагонов'::text
        END AS source_name,
    s_snd.st_name AS st_name_snd,
    s_snd.rw_short_name AS rw_snd_name,
    d.lastrec,
    d.lastrec_all_src
   FROM etran.cont_dislocation_history d
     LEFT JOIN nsi.container_oper op ON d.oper_kmd::text = op.code::text AND op.recdatebegin <= d.operdate AND op.recdateend > d.operdate
     LEFT JOIN nsi.wag_oper_kinds opw ON d.oper_vmd::text = opw.object_kod::text AND opw.date_nd <= d.operdate AND opw.date_kd > d.operdate AND opw.cor_tip::text <> 'D'::text
     LEFT JOIN nsi.stations s_disl ON s_disl.st_id = d.st_id::numeric
     LEFT JOIN nsi.stations s_to ON s_to.st_id = d.rsv_st_id::numeric
     LEFT JOIN nsi.freights fr ON fr.fr_id = d.fr_id::numeric
     LEFT JOIN nsi.org_passports gotpr ON gotpr.org_id = d.snd_org_id::numeric
     LEFT JOIN nsi.org_passports gp ON gp.org_id = d.rsv_org_id::numeric
     LEFT JOIN nsi.stations s_snd ON s_snd.st_id = d.snd_st_id::numeric;
```
4. Накладные (v_inv_cont) - связь один ко многим по полю "cont_num"
```
CREATE OR REPLACE VIEW "MDM_DATA".v_inv_cont
AS SELECT
    // Груз 
    fr_name,
    // Дата приемки
    date_priem,
    // Грузополучатель
    rsv_name,
    // Состояние накладной
    doc_state,
    // системное поле - признак удаленной записи (не отображаемое в интерфейсе)
    1 AS lastrec,
    // Дата прибытия
    date_arrival,
    // Грузоотправитель
    snd_name,
    // Дорога назначения
    rsv_rw_name,
    // системное поле - дата начала действия записи
    CURRENT_TIMESTAMP - '1 day'::interval AS recdatebegin,
    // Плательщик
    payername,
    // Номер накладной
    invnumber,
    // Номер контейнера (link -> cont_num -> cont)
    contnum,
    // Дорога отправления
    snd_rw_name,
    // Дата создания
    date_create,
    // Станция отправления
    snd_st_name,
    // Станция назначения
    rsv_st_name,
    // системное поле - дата окончания действия записи
    '3000-01-01 00:00:00'::timestamp without time zone AS recdateend,
    // Дата раскредитования
    date_raskr,
    // ИД накладной (бизнес ключ)
    doc_id
   FROM "MDM_SHARE".v_inv_cont;
```
Шаблон создания view
```
CREATE OR REPLACE VIEW "MDM_SHARE".v_inv_cont
AS SELECT cont.invcont_id,
    cont.contnum,
    tiq.invnumberq AS invnumber,
    tiq.doc_id,
    tiq.date_create,
    tiq.date_priem,
    tiq.date_arrival,
    tiq.date_raskr,
    ds.name AS doc_state,
    s.rw_name,
    s.rw_short_name AS snd_rw_name,
    s.st_name AS snd_st_name,
    tiq.snd_name,
    s_to.rw_name AS rsv_rw_name,
    s_to.st_name AS rsv_st_name,
    tiq.rsv_name,
    ( SELECT max(tid.payername::text) AS max
           FROM etran.t_inv_distances tid
          WHERE tid.doc_id = tiq.doc_id AND tid.ordernumber = 1::numeric) AS payername,
    f.fr_name,
    'этран'::text AS source_name
   FROM etran.t_inv_query tiq,
    etran.t_inv_cont cont,
    etran.doc_state ds,
    nsi.stations s,
    nsi.stations s_to,
    nsi.freights f
  WHERE ds.state = tiq.state AND s.st_id = tiq.snd_st_id AND s_to.st_id = tiq.rsv_st_id AND cont.doc_id = tiq.doc_id AND f.fr_id = tiq.fr_id;
```
4. Ремонты (cont_repair) - связь один ко многим по полю "cont_num" (УЖЕ ЕСТЬ В РВК!)
```
CREATE TABLE IF NOT EXISTS "MDM_DATA".cont_repair (
        // ИД записи (бизнес ключ)
	row_id int8 NOT NULL,
        // Номер контейнера (link -> cont_num -> cont)
	cont_num varchar(255) NULL,
        // Вид ремонта (link -> cont_repair_type.repair_type_id)
	repair_type int8 NULL,
        // Исполнитель (link -> v_org_passports_full.org_id [shname])
	org_id int8 NULL,
        // системное поле - уникальный идентификатор в бд (не отображаемое в интерфейсе)
	data_id int8 NOT NULL,
        // системное поле - признак удаленной записи (не отображаемое в интерфейсе)
	lastrec int8 DEFAULT 1 NOT NULL,
        // системное поле - дата начала действия записи
	recdatebegin timestamp DEFAULT now() NOT NULL,
        // системное поле - дата окончания действия записи
	recdateend timestamp DEFAULT '3000-01-01 00:00:00'::timestamp without time zone NOT NULL,
        // системное поле - дата обновления записи (не отображаемое в интерфейсе)
	recdatenew timestamp DEFAULT now() NOT NULL,
        // системное поле - механизм для типов колонки "последовательность" (не отображаемое в интерфейсе)
	trans_id int8 NOT NULL,
        // Дата следующего планового ремонта
	date_next date NULL,
        // Дата окончания ремонта
	date_end date NULL,
        // Дата начала ремонта
	date_begin date NULL,
        // Дата браковки
	reject_date date NULL,
        // Неисправность (link -> cont_defect.defect_id [defect_name])
	cont_defect int8 NULL,
        // Причина неисправности (link -> cont_defect_reason.defect_reason_id)
	defect_reason_id int8 NULL,
        // Ремонт выполнен по гарантии (link -> warranty_cond.cond_id [cond_id])
	rep_by_warr int8 NULL,
        // Договор на ремонт (link -> eri_contract.contract_id [contract_num])
	rep_contract int8 NULL,
        // На ремонт действует гарантия (link -> warranty_cond.cond_id [cond_id])
	warr_on_rep int8 NULL,
        // Стоимость ремонта без НДС
	rep_cost float8 NULL,
        // Дата получения ответа
	manuf_answ_date date NULL,
        // Дата уведомления завода
	manuf_notif_date date NULL,
        // Комментарий
	"comment" varchar(255) NULL,
        // системное поле - имя пользователя изменившего запись
	user_name varchar(255) NULL,
        // Дата повторного уведомления завода
	manuf_re_notif_date date NULL,
        // Станция ремонта
	rep_st int8 NULL,
        // Станция браковки (link -> v_clp_nsi_station.st_id [st_name])
	reject_st int8 NULL,
        // Станция ремонта по инструкции (link -> v_clp_nsi_station.st_id [st_name])
	rep_st_instr int8 NULL,
        // Дата отправления в ремонт
	depart_date date NULL,
        // Дата возврата из ремонта
	return_date date NULL,
        // Модернизация крыши
	roof_upgrade bool NULL,
        // Стоимость ремонта с НДС
	cost_with_vat float8 NULL,
        // Дата представления документов
	docs_submission_date date NULL,
        // Дата проверки документов
	docs_verification_date date NULL,
        // Результат проверки документов
	docs_verification_result varchar(255) NULL,
        // Причина отклонения документов
	rejection_reason varchar(255) NULL,
        // НДС (%)
	vat int8 NULL,
        // НДС (руб.)
	vat_rub float8 NULL,
        // Уникальный идентификатор
	CONSTRAINT cont_repair_pkey PRIMARY KEY (data_id)
);
CREATE SEQUENCE "MDM_SYS".sq_data_id
	INCREMENT BY 1
	MINVALUE 1
	MAXVALUE 9223372036854775807
	START 1
	CACHE 1
	NO CYCLE;

// Связанные таблицы:
// Справочник видов ремонтов контейнеров (cont_repair_type) связь по полю "repair_type_id":
CREATE IF NOT EXISTS TABLE "MDM_DATA".cont_repair_type (
        // ИД вида (бизнес ключ)
	repair_type_id int8 NOT NULL,
        // Наименование вида
	repair_type_name varchar(255) NULL,
        // системное поле - уникальный идентификатор в бд (не отображаемое в интерфейсе)
	data_id int8 NOT NULL,
        // системное поле - признак удаленной записи (не отображаемое в интерфейсе)
	lastrec int8 DEFAULT 1 NOT NULL,
        // системное поле - дата начала действия записи
	recdatebegin timestamp DEFAULT now() NOT NULL,
        // системное поле - дата окончания действия записи
	recdateend timestamp DEFAULT '3000-01-01 00:00:00'::timestamp without time zone NOT NULL,
        // системное поле - дата обновления записи (не отображаемое в интерфейсе)
	recdatenew timestamp DEFAULT now() NOT NULL,
        // системное поле - механизм для типов колонки "последовательность" (не отображаемое в интерфейсе)
	trans_id int8 NOT NULL,
        // Уникальный идентификатор
	CONSTRAINT cont_repair_type_pkey PRIMARY KEY (data_id)
);

// Организации все (v_org_passports_full) связь по полю "repair_type_id":
CREATE OR REPLACE VIEW "MDM_DATA".v_org_passports_full
AS SELECT
    // ИД организации (бизнес ключ) 
    org_id,
    // ИНН
    inn,
    // системное поле - дата начала действия записи
    CURRENT_TIMESTAMP - '1 day'::interval AS recdatebegin,
    // Наименование
    fullname,
    // ОКПО
    okpo,
    // системное поле - признак удаленной записи (не отображаемое в интерфейсе)
    1 AS lastrec,
    // Признак организации
    sign,
    // системное поле - дата окончания действия записи
    '3000-01-01 00:00:00'::timestamp without time zone AS recdateend,
    // Наименование (сокр.)
    shname
   FROM "MDM_SHARE".v_org_passports_full;

// Шаблон создания view
CREATE OR REPLACE VIEW "MDM_SHARE".v_org_passports_full
AS SELECT o.org_id,
        CASE
            WHEN o.org_id < 10000000::numeric THEN o.shname::text || ' (Этран)'::text
            ELSE o.shname::text || ' (ФГК)'::text
        END::character varying(500) AS shname,
    o.okpo,
    o.inn,
        CASE
            WHEN o.org_id < 10000000::numeric THEN o.fullname::text || ' (Этран)'::text
            ELSE o.fullname::text || ' (ФГК)'::text
        END::character varying(1024) AS fullname,
    o.sign
   FROM nsi.org_passports o
UNION ALL
 SELECT remontnie_predpriyatiya.org_id::numeric(10,0) AS org_id,
    ((remontnie_predpriyatiya.org_name_short::text || ' (ФГК без договора)'::text))::character varying(500) AS shname,
    remontnie_predpriyatiya.okpo::character varying(12) AS okpo,
    remontnie_predpriyatiya.inn::character varying(13) AS inn,
    ((remontnie_predpriyatiya.org_name::text || ' (ФГК без договора)'::text))::character varying(1024) AS fullname,
    '-1'::character varying(11) AS sign
   FROM "MDM_DATA".remontnie_predpriyatiya
  WHERE remontnie_predpriyatiya.lastrec = 1;

// Справочник неисправностей контейнеров (cont_defect) связь по полю "defect_id"
CREATE TABLE IF NOT EXISTS "MDM_DATA".cont_defect (
        // ИД неисправности (бизнес ключ)
	defect_id int8 NOT NULL,
        // Наименование неисправности
	defect_name varchar(255) NULL,
        // системное поле - уникальный идентификатор в бд (не отображаемое в интерфейсе)
	data_id int8 DEFAULT nextval('"MDM_SYS".sq_data_id'::regclass) NOT NULL,
        // системное поле - признак удаленной записи (не отображаемое в интерфейсе)
	lastrec int8 DEFAULT 1 NOT NULL,
        // системное поле - имя пользователя изменившего запись
	user_name varchar(255) NULL,
        // системное поле - дата начала действия записи
	recdatebegin timestamp DEFAULT now() NOT NULL,
        // системное поле - дата окончания действия записи
	recdateend timestamp DEFAULT '3000-01-01 00:00:00'::timestamp without time zone NOT NULL,
        // системное поле - дата обновления записи (не отображаемое в интерфейсе)
	recdatenew timestamp DEFAULT now() NOT NULL,
        // системное поле - механизм для типов колонки "последовательность" (не отображаемое в интерфейсе)
	trans_id int8 DEFAULT nextval('"MDM_SYS".sq_trans_id'::regclass) NOT NULL,
        // Причина неисправности (link -> cont_defect_reason.defect_reason_id [defect_reason_name])
	defect_reason int8 NULL,
        // Уникальный идентификатор
	CONSTRAINT cont_defect_pkey PRIMARY KEY (data_id)
);

// Справочник причин неисправностей контейнеров (cont_defect_reason) связь по полю "defect_reason_id"
CREATE TABLE IF NOT EXISTS "MDM_DATA".cont_defect_reason (
        // ИД причины неисправности (бизнес ключ)
	defect_reason_id int8 NOT NULL,
        // Наименование причины неисправности
	defect_reason_name varchar(255) NULL,
	user_name varchar(255) NULL,
        // системное поле - уникальный идентификатор в бд (не отображаемое в интерфейсе)
	data_id int8 DEFAULT nextval('"MDM_SYS".sq_data_id'::regclass) NOT NULL,
        // системное поле - признак удаленной записи (не отображаемое в интерфейсе)
	lastrec int8 DEFAULT 1 NOT NULL,
        // системное поле - дата начала действия записи
	recdatebegin timestamp DEFAULT now() NOT NULL,
        // системное поле - дата окончания действия записи
	recdateend timestamp DEFAULT '3000-01-01 00:00:00'::timestamp without time zone NOT NULL,
        // системное поле - дата обновления записи (не отображаемое в интерфейсе)
	recdatenew timestamp DEFAULT now() NOT NULL,
        // системное поле - механизм для типов колонки "последовательность" (не отображаемое в интерфейсе)
	trans_id int8 DEFAULT nextval('"MDM_SYS".sq_trans_id'::regclass) NOT NULL,
        // Уникальный идентификатор
	CONSTRAINT cont_defect_reason_pkey PRIMARY KEY (data_id)
);

// Гарантийные условия (warranty_cond) связь по полю "cond_id"
CREATE TABLE IF NOT EXISTS "MDM_DATA".warranty_cond (
        // ИД (бизнес ключ)
	cond_id int8 NOT NULL,
        // Гарантия к договору (link -> eri_contract.contract_id [contract_num])
	contract_id int8 NULL,
        // Вид гарантии (link -> warranty_type.warr_type_id [warr_type_name])
	warr_type int8 NULL,
        // Продолжительность гарантии (мес.)
	warr_duration int8 NULL,
        // Начало гарантии (link -> eri_act_type.act_type_id [act_type_name])
	warr_begin int8 NULL,
        // системное поле - имя пользователя изменившего запись
	user_name varchar(255) NULL,
        // системное поле - уникальный идентификатор в бд (не отображаемое в интерфейсе)
	data_id int8 DEFAULT nextval('"MDM_SYS".sq_data_id'::regclass) NOT NULL,
        // системное поле - признак удаленной записи (не отображаемое в интерфейсе)
	lastrec int8 DEFAULT 1 NOT NULL,
        // системное поле - дата начала действия записи
	recdatebegin timestamp DEFAULT now() NOT NULL,
        // системное поле - дата окончания действия записи
	recdateend timestamp DEFAULT '3000-01-01 00:00:00'::timestamp without time zone NOT NULL,
        // системное поле - дата обновления записи (не отображаемое в интерфейсе)
	recdatenew timestamp DEFAULT now() NOT NULL,
        // системное поле - механизм для типов колонки "последовательность" (не отображаемое в интерфейсе)
	trans_id int8 DEFAULT nextval('"MDM_SYS".sq_trans_id'::regclass) NOT NULL,
        // Продление гарантии после ремонта
	ext_warr_duration bool NULL,
        // Осмотр за N сут. до окончания гарантии
	insp_in_days int8 NULL,
        // Штраф
	penalty float8 NULL,
        // Гарантия на контейнеры типа (link -> gen_char_cont.char_id [char_name])
	cont_type int8 NULL,
        // Уникальный идентификатор
	CONSTRAINT warranty_cond_pkey PRIMARY KEY (data_id)
);
// Справочник типов актов (eri_act_type) связь по полю "act_type_id" с таблицей (warranty_cond)
CREATE TABLE IF NOT EXISTS "MDM_DATA".eri_act_type (
        // ИД типа (бизнес ключ)
	act_type_id int8 NOT NULL,
        // Наименование типа
	act_type_name varchar(255) NULL,
        // Признак включения в ЕРИ по акту
	incl_sign int8 NULL,
        // системное поле - уникальный идентификатор в бд (не отображаемое в интерфейсе)
	data_id int8 NOT NULL,
        // системное поле - признак удаленной записи (не отображаемое в интерфейсе)
	lastrec int8 DEFAULT 1 NOT NULL,
        // системное поле - дата начала действия записи
	recdatebegin timestamp DEFAULT now() NOT NULL,
        // системное поле - дата окончания действия записи
	recdateend timestamp DEFAULT '3000-01-01 00:00:00'::timestamp without time zone NOT NULL,
        // системное поле - дата обновления записи (не отображаемое в интерфейсе)
	recdatenew timestamp DEFAULT now() NOT NULL,
        // системное поле - механизм для типов колонки "последовательность" (не отображаемое в интерфейсе)
	trans_id int8 NOT NULL,
        // системное поле - имя пользователя изменившего запись
	user_name varchar(255) NULL,
        // Уникальный идентификатор
	CONSTRAINT eri_act_type_pkey PRIMARY KEY (data_id)
);
// Договоры (eri_contract) связь по полю "contract_id" с таблицей (warranty_cond) и (cont_repair)
CREATE TABLE IF NOT EXISTS "MDM_DATA".eri_contract (
        // ИД договора (бизнес ключ)
	contract_id int8 NOT NULL,
        // Номер договора
	contract_num varchar(255) NULL,
        // Тип договора (link -> eri_contract_type.contract_type_id [contract_type_name])
	contract_type int8 NULL,
        // Дата начала действия
	date_begin date NULL,
        // Дата окончания действия
	date_end date NULL,
        // Дата подписания
	date_sign date NULL,
        // Контрагент (link -> v_org_passports.org_id [fullname])
	org_id int8 NULL,
        // системное поле - уникальный идентификатор в бд (не отображаемое в интерфейсе)
	data_id int8 NOT NULL,
        // системное поле - признак удаленной записи (не отображаемое в интерфейсе)
	lastrec int8 DEFAULT 1 NOT NULL,
        // системное поле - дата начала действия записи
	recdatebegin timestamp DEFAULT now() NOT NULL,
        // системное поле - дата окончания действия записи
	recdateend timestamp DEFAULT '3000-01-01 00:00:00'::timestamp without time zone NOT NULL,
        // системное поле - дата обновления записи (не отображаемое в интерфейсе)
	recdatenew timestamp DEFAULT now() NOT NULL,
        // системное поле - механизм для типов колонки "последовательность" (не отображаемое в интерфейсе)
	trans_id int8 NOT NULL,
        // системное поле - имя пользователя изменившего запись
	user_name varchar(255) NULL,
        // Уникальный идентификатор
	CONSTRAINT eri_contract_pkey PRIMARY KEY (data_id)
);
// Справочник типов договоров (eri_contract_type) связь по полю "contract_type_id" с таблицей (eri_contract)
CREATE TABLE IF NOT EXISTS "MDM_DATA".eri_contract_type (
        // ИД типа (бизнес ключ)
	contract_type_id int8 NOT NULL,
        // Наименование типа
	contract_type_name varchar(255) NULL,
        // системное поле - уникальный идентификатор в бд (не отображаемое в интерфейсе)
	data_id int8 NOT NULL,
        // системное поле - признак удаленной записи (не отображаемое в интерфейсе)
	lastrec int8 DEFAULT 1 NOT NULL,
        // системное поле - дата начала действия записи
	recdatebegin timestamp DEFAULT now() NOT NULL,
        // системное поле - дата окончания действия записи
	recdateend timestamp DEFAULT '3000-01-01 00:00:00'::timestamp without time zone NOT NULL,
        // системное поле - дата обновления записи (не отображаемое в интерфейсе)
	recdatenew timestamp DEFAULT now() NOT NULL,
        // системное поле - механизм для типов колонки "последовательность" (не отображаемое в интерфейсе)
	trans_id int8 NOT NULL,
        // системное поле - имя пользователя изменившего запись
	user_name varchar(255) NULL,
        // Уникальный идентификатор
	CONSTRAINT eri_contract_type_pkey PRIMARY KEY (data_id)
);

// Станции (v_clp_nsi_station) связь по полю "st_id" с таблицей (cont_repair)
CREATE OR REPLACE VIEW "MDM_DATA".v_clp_nsi_station
AS SELECT
    // Наименование станции 
    st_name,
    // Код дороги
    rw_code,
    // системное поле - дата окончания действия записи
    '3000-01-01 00:00:00'::timestamp without time zone AS recdateend,
    // Наименование страны
    cn_name,
    // Station
    station,
    // ИД дороги
    rw_id,
    // Main_st_id
    main_st_id,
    // Dtr_short_name
    dtr_short_name,
    // Ид отделения
    dp_id,
    // Наименование региона
    rg_name,
    // Код станции
    st_code,
    // Sign
    sign,
    // Ид станции (бизнес ключ)
    st_id,
    // ИД страны
    cn_id,
    // Branch_id
    branch_id,
    // системное поле - признак удаленной записи (не отображаемое в интерфейсе)
    1 AS lastrec,
    // Сокр. наименование дороги
    rw_short_name,
    // Roadid
    roadid,
    // Rw_name
    rw_name,
    // системное поле - дата начала действия записи
    CURRENT_TIMESTAMP - '1 day'::interval AS recdatebegin,
    // Dtr_id
    dtr_id,
    // Наименование отделения
    dp_name
   FROM "MDM_SHARE".v_clp_nsi_station;

// Шаблон создания view
CREATE OR REPLACE VIEW "MDM_SHARE".v_clp_nsi_station
AS SELECT st_id,
    st_code,
    station,
    rw_code,
    rw_short_name,
    (((((st_name::text || ' ('::text) || st_code::text) || ') '::text) || rw_short_name::text))::character varying(40) AS st_name,
    dp_id,
    branch_id,
    rw_id,
    cn_id,
    rg_name,
    dp_name,
    main_st_id,
    cn_name,
    dtr_id,
    dtr_short_name,
    sign,
    roadid,
    rw_name
   FROM nsi.stations;
```

5. Освидетельствования (cont_survey) - связь один ко многим по полю "cont_num"
```
CREATE TABLE IF NOT EXISTS "MDM_DATA".cont_survey (
        // Номер контейнера (link -> cont.cont_num [cont_num])
	cont_num varchar(255) NULL,
        // Дата начала освидетельствования
	date_begin timestamp NULL,
        // Дата окончания освидетельствования
	date_end timestamp NULL,
        // Дата следующего освидетельствования
	date_next timestamp NULL,
        // Исполнитель (link -> v_org_passports_full.org_id [shname])
	org_id int8 NULL,
        // ИД записи (бизнес ключ)
	row_id int8 NOT NULL,
        // Акт освидетельствования (link -> data_file.file_id [file_name])
	survey_act int8 NULL,
        // Вид освидетельствования (link -> cont_survey_type.survey_type_id [survey_type_name])
	survey_type int8 NULL,
        // системное поле - уникальный идентификатор в бд (не отображаемое в интерфейсе)
	data_id int8 NOT NULL,
        // системное поле - признак удаленной записи (не отображаемое в интерфейсе)
	lastrec int8 DEFAULT 1 NOT NULL,
        // системное поле - дата начала действия записи
	recdatebegin timestamp DEFAULT now() NOT NULL,
        // системное поле - дата окончания действия записи
	recdateend timestamp DEFAULT '3000-01-01 00:00:00'::timestamp without time zone NOT NULL,
        // системное поле - дата обновления записи (не отображаемое в интерфейсе)
	recdatenew timestamp DEFAULT now() NOT NULL,
        // системное поле - механизм для типов колонки "последовательность" (не отображаемое в интерфейсе)
	trans_id int8 NOT NULL,
        // Уникальный идентификатор
	CONSTRAINT cont_survey_pkey PRIMARY KEY (data_id)
);
// Справочник видов освидетельствований контейнеров (cont_survey_type) связь по полю "survey_type_id " с таблицей (cont_survey)
CREATE TABLE IF NOT EXISTS "MDM_DATA".cont_survey_type (
        // ИД вида (бизнес ключ)
	survey_type_id int8 NOT NULL,
        // Наименование вида
	survey_type_name varchar(255) NULL,
        // системное поле - уникальный идентификатор в бд (не отображаемое в интерфейсе)
	data_id int8 NOT NULL,
        // системное поле - признак удаленной записи (не отображаемое в интерфейсе)
	lastrec int8 DEFAULT 1 NOT NULL,
        // системное поле - дата начала действия записи
	recdatebegin timestamp DEFAULT now() NOT NULL,
        // системное поле - дата окончания действия записи
	recdateend timestamp DEFAULT '3000-01-01 00:00:00'::timestamp without time zone NOT NULL,
        // системное поле - дата обновления записи (не отображаемое в интерфейсе)
	recdatenew timestamp DEFAULT now() NOT NULL,
        // системное поле - механизм для типов колонки "последовательность" (не отображаемое в интерфейсе)
	trans_id int8 NOT NULL,
        // Уникальный идентификатор
	CONSTRAINT cont_survey_type_pkey PRIMARY KEY (data_id)
);
```

6. Акты (eri_act) - связь один ко многим по полю "cont_num"
```
CREATE TABLE IF NOT EXISTS "MDM_DATA".eri_act (
        // ИД акта (бизнес ключ)
	act_id int8 NOT NULL,
        // Номер договора (link -> eri_contract.contract_id [contract_num])
	contract_num int8 NULL,
        // Номер акта 
	act_num varchar(255) NULL,
        // Тип акта (link -> eri_act_type.act_type_id [act_type_name])
	act_type int8 NULL,
        // Дата подписания
	date_sign date NULL,
        // системное поле - уникальный идентификатор в бд (не отображаемое в интерфейсе)
	data_id int8 NOT NULL,
        // системное поле - признак удаленной записи (не отображаемое в интерфейсе)
	lastrec int8 DEFAULT 1 NOT NULL,
        // системное поле - дата начала действия записи
	recdatebegin timestamp DEFAULT now() NOT NULL,
        // системное поле - дата окончания действия записи
	recdateend timestamp DEFAULT '3000-01-01 00:00:00'::timestamp without time zone NOT NULL,
        // системное поле - дата обновления записи (не отображаемое в интерфейсе)
	recdatenew timestamp DEFAULT now() NOT NULL,
        // системное поле - механизм для типов колонки "последовательность" (не отображаемое в интерфейсе)
	trans_id int8 NOT NULL,
        // Комментарий
	"comment" varchar(255) NULL,
        // Список контейнеров (link -> cont.сont_num [сont_num]) - один ко многим (link -> eri_act__one_to_many__cont_list.id [link_id])
	cont_list varchar(255) NULL,
	act_doc int8 NULL,
        // системное поле - имя пользователя изменившего запись
	user_name varchar(255) NULL,
        // Уникальный идентификатор
	CONSTRAINT eri_act_pkey PRIMARY KEY (data_id)
);
// Таблица связи один ко многим поля "cont_list"
CREATE TABLE IF NOT EXISTS "MDM_DATA".eri_act__one_to_many__cont_list (
	id int8 NOT NULL,
	link_id varchar(255) NULL
);
```

                                        **Сводные данные по таблицам**
| Table                                                               | Count table | View -> source                                                                                                                                                             | Count view  |
|---------------------------------------------------------------------|-------------|----------------------------------------------------------------------------------------------------------------------------------------------------------------------------|-------------|
| Реестр контейнеров (cont)                                           | 24 252      | Организации (v_org_passports) -> nsi.org_passports                                                                                                                         | 28 336      |
| Справочник характеристик моделей (cont_model_char)                  | 11          | Справочник типов контейнеров (v_cont_type_bige) -> nsi_db.cont_type_big                                                                                                    | 274         |
| Обобщенные характеристики контейнеров (gen_char_cont)               | 12          | Справочник размеров контейнеров (v_cont_size_big) -> nsi_db.cont_size_big                                                                                                  | 80          |
| Прикрепленные файлы (cont_file)                                     | 51 981      | Операции (v_dislocation_cont) -> etran.cont_dislocation_history join nsi.container_oper join nsi.wag_oper_kinds join nsi.stations join nsi.freights join nsi.org_passports | 186 132 647 |
| Cистемная таблица файлов (data_file)                                | 27 999      | Накладные (v_inv_cont) -> etran.t_inv_distances, etran.t_inv_query, etran.t_inv_cont, etran.doc_state, nsi.stations, nsi.freights                                          | 2 895 648   |
| Справочник видов прикрепляемых файлов (eri_file_type)               | 22          | Организации все (v_org_passports_full) -> nsi.org_passports UNION ALL "MDM_DATA".remontnie_predpriyatiya                                                                   | 710 865     |
| Характеристики контейнеров (cont_prop)                              | 6 585       | Станции (v_clp_nsi_station) -> nsi.stations                                                                                                                                | 48 373      |
| Справочник характеристик контейнеров (cont_prop_type)               | 77          |                                                                                                                                                                            |             |
| Ремонты (cont_repair)                                               | 147 057     |                                                                                                                                                                            |             |
| Справочник видов ремонтов контейнеров (cont_repair_type)            | 6           |                                                                                                                                                                            |             |
| Справочник неисправностей контейнеров (cont_defect)                 | 98          |                                                                                                                                                                            |             |
| Справочник причин неисправностей контейнеров (cont_defect_reason)   | 4           |                                                                                                                                                                            |             |
| Гарантийные условия (warranty_cond)                                 | 7           |                                                                                                                                                                            |             |
| Справочник типов актов (eri_act_type)                               | 19          |                                                                                                                                                                            |             |
| Договоры (eri_contract)                                             | 57          |                                                                                                                                                                            |             |
| Справочник типов договоров (eri_contract_type)                      | 14          |                                                                                                                                                                            |             |
| Освидетельствования (cont_survey)                                   | 158         |                                                                                                                                                                            |             |
| Справочник видов освидетельствований контейнеров (cont_survey_type) | 5           |                                                                                                                                                                            |             |
| Акты (eri_act)                                                      | 819         |                                                                                                                                                                            |             |
| Таблица связи один ко многим (eri_act__one_to_many__cont_list)      | 101 412     |                                                                                                                                                                            |             |
