# Маппинг: старая ЕРК (MDM) → контейнерный раздел РВК

Откуда и куда загружаются данные. Старые объекты — схемы `"MDM_DATA"`,
`"MDM_SHARE"`, `"MDM_SYS"` (DDL — `specs/tasks/container/index.md`), новые —
таблицы `cnt_*` в основной схеме РВК (changelog-и
`app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/01-tbl/tbl-cnt_*.xml`,
entity — `app/src/main/java/ru/fgk/ws/app/container/entity/`).

Как загружать — механизм (staging + SQL или Java-мигратор), сроки, риски — в
[input/research.md](input/research.md). Файлы — [legacy-files.md](legacy-files.md).

## Общие правила

### Какие строки берём

Каждая таблица MDM хранит версии: правка закрывает строку
(`recdateend = now()`) и вставляет новую с тем же бизнес-ключом; «Удалить» —
`lastrec = 0`; «Закрыть» — `recdateend` в прошлом.

- Берём **одну действующую версию** на бизнес-ключ:
  `lastrec = 1 and recdateend > now()`. Если на ключ их несколько — последнюю по
  `recdatebegin`, остальные в отчёт.
- `lastrec = 0` (удалённые) и закрытые версии не переносим.
- View `"MDM_SHARE".*` (типы, размеры) версий не имеют — берём все строки.

### Ключи

| Что | Правило |
|---|---|
| Таблицы с числовым бизнес-ключом | старый ключ → `id` (решение прошлой работы, Q02): пользователи знают записи по номерам (786063, 385331…) |
| Контейнер | `id` новый (IDENTITY): `data_id` меняется с каждой версией, постоянного числового ключа нет. Естественный ключ — `cont_num` |
| Ссылка детей на контейнер | старый `cont_num` → `upper(trim(cont_num))` → `cnt_container.id` |
| Ссылки на справочники | старый ключ = новый `id`, перекодировки нет |
| Организации | `org_id` → `VOrgPassport.id` (`nsi_v_org_passport.id` = `ws_store.ora_assb_org_passport_current.org_id`) как есть; не найден — ссылка `NULL` + отчёт |
| Станции | `st_id` → `VStation.id` (`nsi_v_station.st_id`) как есть; не найдена — `NULL` + отчёт |
| После загрузки | `setval` IDENTITY каждой таблицы выше `max(id)`, иначе ввод из UI упрётся в занятый ключ |

### Системные колонки

| Старое | Новое |
|---|---|
| `data_id`, `trans_id`, `recdatenew`, `lastrec`, `recdateend` | не переносятся |
| `user_name`, `recdatebegin` | `created_by = 'erk'`, `created_date` = дата загрузки; `last_modified_*` = `NULL` (другой вариант — `user_name`/`recdatebegin` первой и последней версии; решает пользователь) |
| — | `version = 1`, `deleted_by`/`deleted_date` = `NULL` |

Загрузка пишет в БД напрямую (SQL/JDBC), не через `DataManager`: так
EntityLog не получает сотни тысяч записей «создано», а listener номера
контейнера не участвует — нормализацию делает сам перенос.

### Порядок

1. Справочники (13 таблиц).
2. `cnt_contract` → `cnt_warranty`.
3. `cnt_container`.
4. `cnt_container_property`, `cnt_repair`, `cnt_survey`, `cnt_act` →
   `cnt_act_container`, `cnt_container_file`.
5. Ссылки на файлы (`FileRef`) — после записей, см. legacy-files.md.
6. `setval` и сверка.

## Справочники

| Старый объект | Новая таблица | Колонки: старое → новое |
|---|---|---|
| `MDM_DATA.cont_model_char` | `cnt_model` | `id_char` → `id`; `model` → `model`; `tenty`, `dugi`, `trosy`, `vent` → те же |
| `MDM_SHARE.v_cont_type_bige` (`nsi_db.cont_type_big`) | `cnt_container_type` | `cont_type_id` → `id`; `code`; `type_name`; `detail`; `kind_id` |
| `MDM_SHARE.v_cont_size_big` (`nsi_db.cont_size_big`) | `cnt_container_size` | `cont_size_id` → `id`; `code`; `height`; `heighttxt` → `height_txt`; `width_f`; `comments` |
| `MDM_DATA.gen_char_cont` | `cnt_general_characteristic` | `char_id` → `id`; `char_name`; `char_name_pf` |
| `MDM_DATA.cont_prop_type` | `cnt_property_type` | `prop_type_id` → `id`; `prop_type_name`; `prop_group_name`; `prop_subgroup_name`; `comment`; `prop_type_name_lat` |
| `MDM_DATA.eri_file_type` | `cnt_file_type` | `file_type_id` → `id`; `file_type_name` |
| `MDM_DATA.cont_survey_type` | `cnt_survey_type` | `survey_type_id` → `id`; `survey_type_name` |
| `MDM_DATA.cont_repair_type` | `cnt_repair_type` | `repair_type_id` → `id`; `repair_type_name` |
| `MDM_DATA.cont_defect_reason` | `cnt_defect_reason` | `defect_reason_id` → `id`; `defect_reason_name` |
| `MDM_DATA.cont_defect` | `cnt_defect` | `defect_id` → `id`; `defect_name`; `defect_reason` → `defect_reason_id` |
| `MDM_DATA.eri_act_type` | `cnt_act_type` | `act_type_id` → `id`; `act_type_name`; `incl_sign` |
| `MDM_DATA.eri_contract_type` | `cnt_contract_type` | `contract_type_id` → `id`; `contract_type_name` |
| `MDM_DATA.warranty_type` | `cnt_warranty_type` | `warr_type_id` → `id`; `warr_type_name`. DDL старой таблицы не получен: лишние колонки — `addColumn` в `cnt_warranty_type` |

Готовые SELECT-ы выгрузки справочников — в
`specs/work/conteiner/questions/Q02.md`.

## Договоры и гарантии

### `MDM_DATA.eri_contract` → `cnt_contract`

| Старое | Новое | Преобразование |
|---|---|---|
| `contract_id` | `id` | как есть |
| `contract_num` | `contract_num` | как есть |
| `contract_type` | `contract_type_id` | = `eri_contract_type.contract_type_id` |
| `date_begin`, `date_end`, `date_sign` | те же | date |
| `org_id` | `org_id` | → `VOrgPassport` |

### `MDM_DATA.warranty_cond` → `cnt_warranty`

| Старое | Новое | Преобразование |
|---|---|---|
| `cond_id` | `id` | как есть (385331, 786974, 786975 должны открываться под своими номерами) |
| `contract_id` | `contract_id` | = `eri_contract.contract_id` |
| `warr_type` | `warr_type_id` | = `warranty_type.warr_type_id` |
| `warr_duration` | `warr_duration` | int8 → integer (мес.) |
| `warr_begin` | `warr_begin_id` | = `eri_act_type.act_type_id` |
| `ext_warr_duration` | `ext_warr_duration` | boolean |
| `insp_in_days` | `insp_in_days` | int8 → integer |
| `penalty` | `penalty` | float8 → numeric(19,2), `round(x::numeric, 2)` |
| `cont_type` | `cont_type_id` | = `gen_char_cont.char_id` |

## Реестр контейнеров

### `MDM_DATA.cont` → `cnt_container`

| Старое | Новое | Преобразование |
|---|---|---|
| — | `id` | новый IDENTITY; карта `upper(trim(cont_num)) → id` сохраняется на время загрузки |
| `cont_num` | `cont_num` | `upper(trim(cont_num))`; уникальный индекс — дубли после нормализации в отчёт, грузится одна запись |
| `manuf_num` | `manuf_num` | как есть |
| `manufacturer` | `manufacturer` | как есть |
| `owner_org_id` | `owner_org_id` | → `VOrgPassport` (старый `v_org_passports` берёт только `org_id >= 10000000` — проверить, что такие есть в `nsi_v_org_passport`) |
| `model` (текст) | `model_id` | `cnt_model.id`, где `cnt_model.model = cont.model`; не найдено — `NULL` + отчёт |
| `type_code` | `type_id` | `cnt_container_type.id`, где `code = cont.type_code`; код должен быть уникален |
| `type_name` | — | не хранится: подпись `type` = `typeName` |
| `size_code` | `size_id` | `cnt_container_size.id`, где `code = cont.size_code` |
| `width_f` | — | не хранится: `size.widthF` |
| `max_gross_mass`, `tare_mass`, `payload`, `capacity` | те же | bigint |
| `next_survey_date` | `next_survey_date` | date |
| `gen_char_id` | `gen_char_id` | = `gen_char_cont.char_id` |
| `constr_date` | `constr_date` | date |
| `roof_upgrade`, `roof_upgrade_date` | те же | boolean, date |

Виртуальные поля старой формы (тенты, дуги, тросы, вент. отверстия) не
переносятся: в РВК это `model.tenty` и т.д.

## Вкладки контейнера

### `MDM_DATA.cont_prop` → `cnt_container_property`

| Старое | Новое | Преобразование |
|---|---|---|
| `prop_id` | `id` | как есть |
| `cont_num` | `container_id` | через карту номеров; не найден — строка в отчёт, не грузится (`container_id` NOT NULL) |
| `prop_type_id` | `prop_type_id` | = `cont_prop_type.prop_type_id` |
| `prop_value` | `prop_value` | varchar(2000) |
| `comment` | `comment` | как есть |

### `MDM_DATA.cont_file` → `cnt_container_file`

| Старое | Новое | Преобразование |
|---|---|---|
| `file_id` | `id` | как есть |
| `cont_num` | `container_id` | через карту номеров |
| `file_type` | `file_type_id` | = `eri_file_type.file_type_id` |
| `comment` | `comment` | как есть |
| `file_name` | `file_name` | ручное «Имя файла» — как есть |
| `file` | `file` | `data_file.file_id` → `FileRef` на старое хранилище, см. legacy-files.md |

### `MDM_DATA.cont_repair` → `cnt_repair`

| Старое | Новое | Преобразование |
|---|---|---|
| `row_id` | `id` | как есть |
| `cont_num` | `container_id` | через карту номеров |
| `repair_type` | `repair_type_id` | = `cont_repair_type.repair_type_id` |
| `org_id` | `org_id` | → `VOrgPassport`. Старый `v_org_passports_full` включает `remontnie_predpriyatiya` — таких в РВК нет: `NULL` + отчёт |
| `date_begin`, `date_end`, `date_next`, `reject_date`, `depart_date`, `return_date` | те же | date |
| `manuf_notif_date`, `manuf_re_notif_date`, `manuf_answ_date` | те же | date |
| `docs_submission_date`, `docs_verification_date` | те же | date |
| `docs_verification_result`, `rejection_reason`, `comment` | те же | varchar(255) |
| `cont_defect` | `defect_id` | = `cont_defect.defect_id` |
| `defect_reason_id` | `defect_reason_id` | = `cont_defect_reason.defect_reason_id` |
| `rep_by_warr` | `rep_by_warr_id` | = `warranty_cond.cond_id` |
| `warr_on_rep` | `warr_on_rep_id` | = `warranty_cond.cond_id` |
| `rep_contract` | `rep_contract_id` | = `eri_contract.contract_id` |
| `rep_st`, `reject_st`, `rep_st_instr` | `rep_st_id`, `reject_st_id`, `rep_st_instr_id` | → `VStation` по `st_id` |
| `rep_cost`, `cost_with_vat`, `vat_rub` | те же | float8 → numeric(19,2), `round(x::numeric, 2)` |
| `vat` | `vat` | int8 → integer (%) |
| `roof_upgrade` | `roof_upgrade` | boolean |
| — | `document` | в старом DDL источника нет — остаётся `NULL`, пока не найдено, откуда файл ремонта |

### `MDM_DATA.cont_survey` → `cnt_survey`

| Старое | Новое | Преобразование |
|---|---|---|
| `row_id` | `id` | как есть |
| `cont_num` | `container_id` | через карту номеров |
| `survey_type` | `survey_type_id` | = `cont_survey_type.survey_type_id` |
| `date_begin`, `date_end`, `date_next` | те же | timestamp → date (время отбрасывается) |
| `org_id` | `org_id` | → `VOrgPassport` (тот же риск, что у ремонтов) |
| `survey_act` | `survey_act` | `data_file.file_id` → `FileRef`, см. legacy-files.md |

### `MDM_DATA.eri_act` → `cnt_act`

| Старое | Новое | Преобразование |
|---|---|---|
| `act_id` | `id` | как есть |
| `contract_num` (int8, это `contract_id`) | `contract_id` | = `eri_contract.contract_id` |
| `act_num` | `act_num` | как есть |
| `act_type` | `act_type_id` | = `eri_act_type.act_type_id` |
| `date_sign` | `date_sign` | date |
| `comment` | `comment` | как есть |
| `act_doc` | `act_doc` | предположительно `data_file.file_id` → `FileRef`; проверить на данных |
| `cont_list` | — | раскрывается в `cnt_act_container`, ниже |

### `eri_act.cont_list` + `MDM_DATA.eri_act__one_to_many__cont_list` → `cnt_act_container`

| Старое | Новое | Преобразование |
|---|---|---|
| `eri_act.act_id` | `act_id` | акт, чей `cont_list` = `eri_act__one_to_many__cont_list.id` (связь проверить на данных) |
| `eri_act__one_to_many__cont_list.link_id` (номер контейнера) | `container_id` | через карту номеров |
| — | `id` | новый IDENTITY |

Пара `(act_id, container_id)` уникальна — дубли схлопываются.

## Что не переносится

| Объект | Почему |
|---|---|
| `v_dislocation_cont`, `v_inv_cont` | view над данными ЭТРАН, не данные ЕРК; вкладки отложены (Q01 прошлой работы) |
| `v_org_passports`, `v_org_passports_full`, `v_clp_nsi_station` | в РВК есть свои `VOrgPassport`, `VStation` |
| `remontnie_predpriyatiya` | нет аналога в РВК; ссылки на них — в отчёт |
| `MDM_SYS.data_file` как таблица | содержимое остаётся в старом хранилище или копируется в S3 РВК, см. legacy-files.md |
| Версии записей (история) | в РВК история — EntityLog с момента загрузки |
| `type_name`, `width_f` контейнера | вычисляются из справочников |

## Сверка после загрузки

- Число строк в каждой `cnt_*` = числу действующих строк источника минус отчёт
  об отброшенных.
- Отчёт о потерянных ссылках: `cont_num` детей без контейнера; `model`,
  `type_code`, `size_code` без справочника; `org_id` вне `VOrgPassport`;
  `st_id` вне `VStation`; дубли `cont_num` после нормализации.
- `cnt_warranty` 385331, 786974, 786975 ссылаются на договоры «ФГК-47-15» и
  «ФГК-79-9»; примеры ИД файлов из инструкции (786063, 786006, 786011)
  открываются.
- Новая запись из UI получает `id` больше максимального загруженного.
- Повторный запуск не дублирует строки (`on conflict (id) do nothing` / по
  `cont_num` для контейнера).
