# Исследование: перенос контейнеров из старой ЕРК (MDM) в РВК

Дата: 2026-10-13. Черновик: решения по открытым вопросам ещё не приняты.

## Задача

Раздел «Контейнеры» в РВК сделан (работа [conteiner](../../conteiner/summary.md),
код в `main`, пакет `ru.fgk.ws.app.container`) и сдан с пустыми данными. Нужно:

1. Описать новую структуру и маппинг «старая таблица/колонка → новая».
2. Оценить перенос данных из старой ЕРК (PostgreSQL, схемы `"MDM_DATA"`,
   `"MDM_SHARE"`, `"MDM_SYS"`) в таблицы `cnt_*`, включая файлы.
3. Оценить обратный перенос из `cnt_*` в старые таблицы.

Не входит: вкладки «Операции» и «Накладные» (`v_dislocation_cont`,
`v_inv_cont` — это view над внешними данными ЭТРАН, а не данные ЕРК;
отложены в [Q01](../../conteiner/questions/Q01.md)), перенос НСИ организаций и
станций (используются существующие `VOrgPassport`, `VStation`),
`remontnie_predpriyatiya`.

Источник старой структуры — [specs/tasks/container/index.md](../../../tasks/container/index.md)
(DDL и количество строк) и `specs/work/conteiner/input/issue.md`.

## Что узнали

### Новая структура (факт кода)

22 таблицы `cnt_*`, changelog-и `app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/01-tbl/tbl-cnt_*.xml`,
полная матрица — [contracts.md](../../conteiner/contracts.md#матрица-модели).
Общее у всех таблиц:

- `id bigint` IDENTITY `startWith=1` (`tbl-cnt_container.xml:16`), `version`,
  аудит `created_by/created_date/last_modified_by/last_modified_date`,
  мягкое удаление `deleted_by/deleted_date`.
- Ссылки — `<ref>_id` без FK в БД; на ссылках `@OnDeleteInverse(DENY)`.
- Уникальные индексы: `cnt_container(cont_num)`, `cnt_act_container(act_id, container_id)`.
- Номер контейнера нормализуется (trim + верхний регистр) в
  `container/listener/ContainerSavingListener` — только на пути `DataManager`.
- Файлы — `FileRef` (`varchar(1024)`), хранилище по умолчанию `s3`
  (MinIO `minio01.main.vgk`, бакет `rvk`, `application.properties:75-81`),
  папка `cnt_file` (`rvk.storage-folders.cnt-file`). Значение колонки —
  `s3://cnt_file/<ключ>?name=<имя>`; запись через
  `storage/AwsFileStorageWithFolder.saveStream(path, ...)`.
- Организации: `nsi_v_org_passport` = `ws_store.ora_assb_org_passport_current.org_id`
  (`02_view/g1v77/01-nsi_v_org_passport.xml`), `Long id`.
  Станции: `nsi_v_station.st_id`, `Integer id`.
- История — Jmix EntityLog (`04-data/cnt_entity_log.xml`), своей таблицы версий нет.

Решение прошлой работы ([Q02](../../conteiner/questions/Q02.md)): старые
числовые бизнес-ключи сохраняются как новые `id`. Там же готовые SELECT-ы и
постановка загрузки справочников.

### Как устроены старые данные

- Каждая таблица MDM — версионная (SCD2): правка закрывает строку
  (`recdateend = now()`) и вставляет новую с тем же бизнес-ключом и новым
  `data_id`. «Удалить» = `lastrec = 0`, «Закрыть» = `recdateend = now()`.
  Значит, числа из сводки (24 252 контейнера, 147 057 ремонтов, 51 981 файл)
  включают историю; действующих строк меньше. **Догадка**, проверить SELECT-ом
  ниже: действующая версия = `lastrec = 1 and recdateend > now()`.
- У контейнера нет числового бизнес-ключа — только `cont_num`; `data_id`
  меняется с каждой версией. Дети (`cont_prop`, `cont_file`, `cont_repair`,
  `cont_survey`, состав актов) ссылаются на контейнер по `cont_num`.
- Бизнес-ключи остальных таблиц (`row_id`, `prop_id`, `file_id`, `act_id`,
  `cond_id`) похожи на значения общей последовательности `"MDM_SYS".sq_data_id`
  (примеры из инструкции: 786063, 385331, 786974) — уникальны между таблицами.
- Контейнер хранит денормализованные текстовые ключи: `model` (текст модели),
  `type_code`, `type_name`, `size_code`, `width_f`.
- Файлы: `cont_file.file`, `cont_survey.survey_act`, (видимо) `eri_act.act_doc`
  → `"MDM_SYS".data_file.file_id`. Содержимое — либо `file_content bytea`
  (старые), либо объект в S3 по `s3_uuid` (новые). `data_file` общая для всех
  справочников MDM (27 999 строк всего).
- Новая `cnt_repair.document` (FileRef) в старом DDL источника не имеет —
  взята со скриншота списка ремонтов (колонка «файл (PDF)»).
- Подключения к БД ЕРК в проекте нет (поиск `MDM_DATA`/`MDM_SHARE` по коду
  пуст); есть образец второго источника — `VagtkprodStoreConfiguration`.

### Маппинг: справочники

Действующие строки: `lastrec = 1 and recdateend > now()`; view `MDM_SHARE` —
без фильтра.

| Старый объект | Новая таблица | Колонки (старое → новое) |
|---|---|---|
| `cont_model_char` | `cnt_model` | `id_char`→`id`, `model`, `tenty`, `dugi`, `trosy`, `vent` |
| `MDM_SHARE.v_cont_type_bige` (`nsi_db.cont_type_big`) | `cnt_container_type` | `cont_type_id`→`id`, `code`, `type_name`, `detail`, `kind_id` |
| `MDM_SHARE.v_cont_size_big` (`nsi_db.cont_size_big`) | `cnt_container_size` | `cont_size_id`→`id`, `code`, `height`, `heighttxt`→`height_txt`, `width_f`, `comments` |
| `gen_char_cont` | `cnt_general_characteristic` | `char_id`→`id`, `char_name`, `char_name_pf` |
| `cont_prop_type` | `cnt_property_type` | `prop_type_id`→`id`, `prop_type_name`, `prop_group_name`, `prop_subgroup_name`, `comment`, `prop_type_name_lat` |
| `eri_file_type` | `cnt_file_type` | `file_type_id`→`id`, `file_type_name` |
| `cont_survey_type` | `cnt_survey_type` | `survey_type_id`→`id`, `survey_type_name` |
| `cont_repair_type` | `cnt_repair_type` | `repair_type_id`→`id`, `repair_type_name` |
| `cont_defect_reason` | `cnt_defect_reason` | `defect_reason_id`→`id`, `defect_reason_name` |
| `cont_defect` | `cnt_defect` | `defect_id`→`id`, `defect_name`, `defect_reason`→`defect_reason_id` |
| `eri_act_type` | `cnt_act_type` | `act_type_id`→`id`, `act_type_name`, `incl_sign` |
| `eri_contract_type` | `cnt_contract_type` | `contract_type_id`→`id`, `contract_type_name` |
| `warranty_type` | `cnt_warranty_type` | `warr_type_id`→`id`, `warr_type_name`; DDL старой таблицы не получен |

### Маппинг: основные таблицы

| Старое | Новое | Как |
|---|---|---|
| **`cont`** | **`cnt_container`** | `id` — новый IDENTITY (стабильного числового ключа нет) |
| `cont_num` | `cont_num` | `upper(trim())`; проверить дубли после нормализации |
| `manuf_num`, `manufacturer` | те же | как есть |
| `owner_org_id` | `owner_org_id` | как есть, если `org_id` есть в `nsi_v_org_passport` (старый `v_org_passports` берёт `org_id >= 10000000`) |
| `model` (текст) | `model_id` | `cnt_model.id where model = cont.model` — поиск по тексту |
| `type_code` | `type_id` | `cnt_container_type.id where code = cont.type_code`; проверить уникальность `code` |
| `type_name` | — | виртуальное (`type` → `typeName`) |
| `size_code` | `size_id` | `cnt_container_size.id where code = cont.size_code` |
| `width_f` | — | виртуальное (`size.widthF`) |
| `max_gross_mass`, `tare_mass`, `payload`, `capacity` | те же | bigint → bigint |
| `next_survey_date`, `constr_date`, `roof_upgrade`, `roof_upgrade_date` | те же | как есть |
| `gen_char_id` | `gen_char_id` | = `gen_char_cont.char_id` |
| **`cont_prop`** | **`cnt_container_property`** | `prop_id`→`id`; `cont_num`→`container_id`; `prop_type_id`, `prop_value`, `comment` |
| **`cont_file`** | **`cnt_container_file`** | `file_id`→`id`; `cont_num`→`container_id`; `file_type`→`file_type_id`; `comment`; `file_name`; `file` → загрузка содержимого `data_file` в S3 → `file` (FileRef) |
| **`cont_repair`** | **`cnt_repair`** | `row_id`→`id`; `cont_num`→`container_id`; `repair_type`→`repair_type_id`; `org_id` (риск: `v_org_passports_full` включает `remontnie_predpriyatiya`, их в `VOrgPassport` нет); 11 дат как есть; `cont_defect`→`defect_id`; `defect_reason_id`; `rep_by_warr`→`rep_by_warr_id`; `warr_on_rep`→`warr_on_rep_id`; `rep_contract`→`rep_contract_id`; `rep_st`/`reject_st`/`rep_st_instr` → `*_id` (`st_id`); `rep_cost`, `cost_with_vat`, `vat_rub` float8 → `numeric(19,2)` с округлением; `vat` int8 → integer; `comment`, `docs_verification_result`, `rejection_reason`, `roof_upgrade` как есть; `document` — источника нет |
| **`cont_survey`** | **`cnt_survey`** | `row_id`→`id`; `cont_num`→`container_id`; `survey_type`→`survey_type_id`; `date_begin/end/next` timestamp → date (время отбрасывается); `org_id`; `survey_act` → файл → FileRef |
| **`eri_contract`** | **`cnt_contract`** | `contract_id`→`id`; `contract_num`; `contract_type`→`contract_type_id`; `date_begin/end/sign`; `org_id` |
| **`warranty_cond`** | **`cnt_warranty`** | `cond_id`→`id`; `contract_id`; `warr_type`→`warr_type_id`; `warr_duration`, `insp_in_days` int8→integer; `warr_begin`→`warr_begin_id`; `ext_warr_duration`; `penalty` float8→numeric; `cont_type`→`cont_type_id` |
| **`eri_act`** | **`cnt_act`** | `act_id`→`id`; `contract_num` (это `contract_id`) → `contract_id`; `act_num`; `act_type`→`act_type_id`; `date_sign`; `comment`; `act_doc` → файл → FileRef |
| **`eri_act.cont_list` + `eri_act__one_to_many__cont_list`** | **`cnt_act_container`** | пары (акт, `link_id` = `cont_num`) → `container_id`; `id` новый; без дублей. Как `cont_list` связан с `…cont_list.id`, проверить на данных |

Системные колонки: `data_id`, `trans_id`, `recdatenew` не переносятся;
`lastrec = 0` и закрытые версии не переносятся (см. открытые вопросы);
`version = 1`; `created_*`/`last_modified_*` — по решению (варианты: `'erk'` +
`now()` либо `user_name`/`recdatebegin` первой и последней версии).

### SELECT-ы для разведки в старой БД

```sql
-- 1. Сколько действующих, закрытых, удалённых контейнеров; дубли номера
select count(*) filter (where lastrec = 1 and recdateend > now()) as active,
       count(*) filter (where lastrec = 1 and recdateend <= now()) as closed_or_hist,
       count(*) filter (where lastrec = 0) as deleted,
       count(distinct upper(trim(cont_num))) as distinct_num
  from "MDM_DATA".cont;
select upper(trim(cont_num)), count(*) from "MDM_DATA".cont
 where lastrec = 1 and recdateend > now() group by 1 having count(*) > 1;

-- 2. То же для ремонтов, файлов, характеристик, освидетельствований, актов
--    (по row_id / file_id / prop_id / act_id)

-- 3. Текстовые ключи контейнера, которых нет в справочниках
select c.model, count(*) from "MDM_DATA".cont c
  left join "MDM_DATA".cont_model_char m on m.model = c.model and m.lastrec = 1 and m.recdateend > now()
 where c.lastrec = 1 and c.recdateend > now() and c.model is not null and m.model is null group by 1;
-- аналогично type_code ↔ v_cont_type_bige.code, size_code ↔ v_cont_size_big.code;
-- и уникальность: select code, count(*) from "MDM_SHARE".v_cont_type_bige group by 1 having count(*) > 1;

-- 4. Организации ремонтов и освидетельствований, которых нет в nsi.org_passports
select count(*), count(distinct r.org_id) from "MDM_DATA".cont_repair r
 where r.lastrec = 1 and r.recdateend > now() and r.org_id is not null
   and not exists (select 1 from nsi.org_passports o where o.org_id = r.org_id);

-- 5. Файлы: сколько, где лежат, сколько весят, нет ли нескольких версий одного file_id
select count(*), count(distinct file_id),
       count(*) filter (where file_content is not null) as in_db,
       count(*) filter (where s3_uuid is not null) as in_s3,
       pg_size_pretty(sum(coalesce(file_size, octet_length(file_content)))::bigint)
  from "MDM_SYS".data_file
 where file_id in (select file from "MDM_DATA".cont_file
                   union select survey_act from "MDM_DATA".cont_survey
                   union select act_doc from "MDM_DATA".eri_act);

-- 6. Где старый S3: эндпоинт и бакет (из настроек приложения ЕРК)

-- 7. Состав актов
select a.act_id, a.cont_list, count(l.*) from "MDM_DATA".eri_act a
  left join "MDM_DATA".eri_act__one_to_many__cont_list l on l.id::text = a.cont_list
 where a.lastrec = 1 and a.recdateend > now() group by 1, 2 limit 20;
```

В РВК (`mcp__rvk-ws__query`): есть ли `id >= 10000000` в
`nsi_v_org_passport` и совпадают ли `st_id` станций.

## Варианты

### Перенос старое → новое

Объём небольшой (десятки тысяч строк, ~28 тыс. файлов): разовый прогон —
минуты. Сложность не в объёме, а в доступе и грязных данных.

**А. CSV + Liquibase `loadData`** (постановка из Q02).
Подходит только для справочников, договоров и гарантий (десятки строк). Для
контейнеров/ремонтов CSV на десятки МБ в changelog и файлы так не перенести.

**Б. Staging в БД РВК + SQL-функция.** Таблицы MDM доставляются в БД РВК
(ETL в `ws_store`, `postgres_fdw`/`dblink` или разовый `pg_dump` в схему
`erk_stage`), перенос — `insert … select` с маппингом в одной функции
(`03_fn/cnt_f_import_erk.xml`), файлы — отдельной Java-задачей, которая читает
`data_file` из staging и пишет в `FileStorage`.
Плюсы: маппинг — обычный SQL, проверяется запросами; не идёт через
`DataManager` (нет 250 тыс. записей EntityLog); повторяемо.
Риски: нужно, чтобы кто-то доставил таблицы; нормализацию номера SQL делает
сам, listener не участвует.

**В. Java-мигратор с прямым подключением к ЕРК.** Второй `DataSource` по
образцу `VagtkprodStoreConfiguration`, сервис читает старые таблицы JDBC,
пишет батчами в `cnt_*` (JDBC, не `DataManager`), файлы — из `bytea` или
старого S3 в `AwsFileStorageWithFolder`. Запуск — админ-кнопкой или
`@Authenticated`-задачей.
Плюсы: всё в одном месте, включая файлы; то же подключение пригодится для
обратного переноса.
Риски: сетевой доступ и учётка от серверов РВК к БД и S3 ЕРК; код живёт в
приложении (удалить после переезда).

Общее для Б и В:
- Порядок: справочники → договоры → гарантии → контейнеры → характеристики,
  ремонты, освидетельствования, акты и состав → файлы.
- Старые ключи → `id`; после загрузки `setval` IDENTITY каждой таблицы выше
  `max(id)`.
- Контейнер: карта `upper(trim(cont_num)) → новый id`, через неё все дети.
- Идемпотентность: `insert … on conflict (id) do update` / пропуск
  существующих; для контейнера — по `cont_num`.
- Загрузка до начала ввода в РВК, иначе старые ИД столкнутся с уже
  выданными (см. Q02).
- Сверка после загрузки: количество строк, потерянные ссылки
  (`org_id`, `st_id`, model/type/size), файлы, которые не нашлись.

Ориентир объёма: справочники — час (SQL из Q02 готов); основные таблицы с
маппингом и сверкой — 2–3 дня; файлы — 1–2 дня в зависимости от того, где они
лежат. Итого порядка недели вместе с разбором грязных данных.

### Обратный перенос новое → старое

Сложность зависит от сценария:

- **Разовая выгрузка назад** (откат): средне. Для каждой записи `cnt_*` —
  строка MDM: `data_id`/`trans_id` из `"MDM_SYS".sq_data_id`/`sq_trans_id`,
  `lastrec = 1`, `recdatebegin = now()`, `recdateend = '3000-01-01'`;
  денормализованные `model`, `type_code`, `type_name`, `size_code`, `width_f`
  восстанавливаются из ссылок; `cont_num` — ключ для детей; файлы — обратно в
  `data_file`/старый S3.
- **Постоянная синхронизация РВК → ЕРК** (ЕРК живёт как витрина для других
  систем): выше среднего. Нужно отслеживать изменения
  (`last_modified_date`/`deleted_date` или EntityLog), эмулировать версии
  MDM (закрыть старую строку, вставить новую; мягкое удаление → `lastrec = 0`),
  писать файлы в старое хранилище, повторять при сбоях.
- **Двусторонняя одновременная работа**: не советую — конфликты правок и ключей
  (обе стороны раздают ИД; IDENTITY РВК и `sq_data_id` ЕРК пересекутся без
  разнесения диапазонов).

Чего в новой структуре нет и что назад не восстановится: история версий MDM
(в РВК — EntityLog), состояние «закрыта» (`recdateend` в прошлом), `user_name`
на каждой версии.

Что сделать в прямом переносе, чтобы обратный был дешёвым: сохранить старые
ключи как `id` (уже решено), `cont_num` как естественный ключ, не терять
соответствие файла старому `file_id` (например, `id` записи = старый
`file_id`, уже так), не склеивать и не нормализовать данные без следа
(кроме номера контейнера — отчёт о склеенных).

## Решение

Не принято. Совет: прямой перенос вариантом **В** (если нужен обратный
перенос или файлы лежат в старом S3/`bytea`, недоступных из БД РВК), иначе
**Б**; справочники — SQL из Q02 тем же механизмом, а не отдельным `loadData`.

## Открытые вопросы

1. Обратный перенос: разовый откат, постоянная синхронизация на время
   параллельной работы или ЕРК после переезда только для чтения?
2. Доступ: можно ли со стороны РВК подключиться к БД ЕРК и её S3 (или кто
   доставит таблицы в БД РВК)?
3. Что переносим: только действующие записи или также закрытые (`recdateend`
   в прошлом) и историю версий?
4. Заполнение аудита: `'erk'` + дата загрузки или `user_name`/`recdatebegin`
   из старых версий?
5. Откуда в старой системе файл ремонта (`cnt_repair.document`)?
6. Ремонты с исполнителем из `remontnie_predpriyatiya`: терять ссылку,
   заводить организацию или переносить текстом в комментарий?
7. Результаты SELECT-ов разведки (раздел выше).

## Дальше

`/rt-plan 002-container-erk-migration` — после ответов на 1–3 и разведки:
работа делится на независимые части (справочники, основные таблицы, файлы,
обратный перенос), её проще вести группами.
