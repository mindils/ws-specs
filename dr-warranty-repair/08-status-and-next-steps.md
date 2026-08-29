# Что сделано и что дальше

## Этап 1 — модель данных: сделано

Реализована структура таблиц. Формы, сервисы и интеграция с Case.one — этап 2,
он начинается **после ответов на вопросы** из
[06-open-questions.md](06-open-questions.md) (см. ниже, какой вопрос что
блокирует).

### Таблицы

Схема `main`, префикс `legal_` (как у существующей `legal_caseone_settings`).
Всего 197 колонок, у каждой — комментарий в БД.

| Таблица | Назначение | PK | Колонок |
|---|---|---|---|
| `legal_warranty_repair` | отцепка (вагон + дата браковки), автозаполнение из ЕО/ВагТК и НСИ | `repair_uid` uuid | 49 |
| `legal_warranty_repair_deps` | претензия, поля пользователей ДЭПС | `id` bigint identity | 76 |
| `legal_warranty_repair_du` | претензионная и судебная работа, поля ДЮ | `id`, 1:1 с претензией | 34 |
| `legal_warranty_repair_case_one` | карточка Case.one и результат отправки | `id`, 1:1 с претензией | 16 |
| `legal_caseone_ref` | кэш справочников Case.one (контрагенты, пользователи, каталоги) | `id` uuid из Case.one | 22 |

```
legal_warranty_repair (1) ──< (N) legal_warranty_repair_deps      [repair_uid + claim_index]
legal_warranty_repair_deps (1) ─── (0..1) legal_warranty_repair_du        [deps_id UNIQUE]
legal_warranty_repair_deps (1) ─── (0..1) legal_warranty_repair_case_one  [deps_id UNIQUE]
```

Внешние ключи в миграциях не создаются (правило проекта), на entity —
`@DdlGeneration(unmappedConstraints = ...)`. Индекс претензии уникален в
пределах отцепки среди неудалённых строк: частичный уникальный индекс
`UQ_LEGAL_WARRANTY_REPAIR_DEPS_CLAIM (repair_uid, claim_index) WHERE deleted_date IS NULL`.

### Файлы

Liquibase — `app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/01-tbl/`:

- `320-legal_warranty_repair.xml`
- `321-legal_warranty_repair_deps.xml` (+ частичный уникальный индекс отдельным `<sql>`-changeSet)
- `322-legal_warranty_repair_du.xml`
- `323-legal_warranty_repair_case_one.xml`
- `tbl-legal_caseone_ref.xml`

Java — `app/src/main/java/ru/fgk/ws/app/legal/`:

- `warrantyrepair/entity/` — `LegalWarrantyRepair`, `LegalWarrantyRepairDeps`,
  `LegalWarrantyRepairDu`, `LegalWarrantyRepairCaseOne` и 7 enum-ов
  (`WarrantyRepairTypeEnum`, `WarrantyPlanRepairTypeEnum`,
  `WarrantyClaimResultEnum`, `WarrantyReclamationResultEnum`,
  `WarrantyBranchReviewResultEnum`, `WarrantyReimbursementBasisEnum`,
  `WarrantyCaseOneStatusEnum`);
- `warrantyrepair/security/LegalWarrantyRepairRole.java` — роль
  `legal-warranty-repair`: полный доступ к четырём сущностям, чтение
  `legal_caseone_ref`. `@ViewPolicy`/`@MenuPolicy` пока нет — экранов нет;
- `caseone/entity/` — `CaseOneRef`, `CaseOneRefType`, `CaseOneParticipantType`.

i18n — 234 ключа в `app/src/main/resources/ru/fgk/ws/app/messages_ru.properties`
(наименования сущностей, все атрибуты, все значения enum-ов).

### Принятые решения

- `repair_uid` — обычный UUID, генерируется при заливке данных; формулы MD5 нет.
- Enum-ы хранятся кодом (`int2`), в Java — поле `Integer` + аксессор enum-типа
  (паттерн `ru.fgk.ws.app.dt.entity.DtOperRepair`).
- Даты, у которых в старых данных есть время (`Neispr_dt`, `Dat_Rem`,
  `Dat_Prib`, `VladStart_dt`, `Dat_Korr`), — `timestamp`, а не `date`, иначе
  перенос не lossless.
- Денежные `numeric(8,2)` расширены до `DECIMAL(12,2)`.
- Пользователи старой системы переносятся как ФИО в `varchar(255)`, а не кодами.
- Переносится всё, что несёт данные: добавлены `uncoupling_tr_count` (`Kol_TR`),
  `at_fault_reply_number` (`Gar_SendNom`), `psr_material_number`/`_date`,
  `agent_sng_percent`/`_cost`, аудит расчёта перевыставления, служебное
  `deps.src_id_zap` (старый `IdZap`) и soft delete под `Korr_pr = 1`.
- Справочники Case.one **не зеркалируются**: у Case.one нет ни выборки по дате
  изменения, ни признака удаления. В `legal_caseone_ref` оседает только то, что
  выбрали или явно загрузили; в претензии хранится снимок (идентификатор +
  наименование + ИНН), а не внешний ключ.
- `KAgPret_GUID` лежит в `deps.claim_contractor_guid` рядом с наименованием: это
  выбор пользователя ДЭПС в блоке «Расчёт требований», а не результат отправки.

### Исправления против первоначального черновика

Сверено по `Таблица_претензий_с_колонками.xlsx` (строка 12 — имена колонок
процедуры под русскими заголовками формы) и по логике расчёта сроков в
процедуре. Подробности — в [05-column-mapping.md](05-column-mapping.md).

| Колонка | Было | Стало |
|---|---|---|
| `Prich_Otkl` | причина отклонения претензии (ДЮ) | причина отклонения **рекламационных документов** (ДЭПС) |
| `Rekl_Prich` | причина отклонения | **примечание** к приёмке рекламационных документов |
| `Gar_Prich` | примечание виновника | **причина отклонения претензии** (ДЮ) |
| `NomPret`, `DatPret`, `Stoim`, `Dat_Send`, `Result` | зона ДЭПС | зона **ДЮ**, блок «Претензионная работа → Претензия» |
| `Gar_SendNom` | «не переносится» | `du.at_fault_reply_number` — «номер ответа» виновного предприятия |
| `DoPret_Vozvrat_*` / `Pret_Vozvrat_*` | перепутаны в `03-old-form.md` | `DoPret_*` — возврат из допретензионной (ДЭПС), `Pret_*` — из претензионной (ДЮ) |

### Как проверено

- `./gradlew :app:compileJava` и `./gradlew spotlessCheckAll` — зелёные.
- Миграции применены к настоящей PostgreSQL 16: созданы 5 таблиц, проверены
  комментарии, типы, PK, UNIQUE и частичный индекс.
- Контекст Spring/Jmix поднимается с новыми сущностями; из контекстных тестов
  прошли 50 из 51.
- Сверка entity ↔ changelog: 197/197 колонок совпадают по имени и типу, лишних
  и недостающих нет.
- Полнота переноса: из 129 колонок `TrkRemPretens` перенесены 127; не
  переносятся `Prost` (простой — отдельный функционал) и `KodPret` (раздел
  зафиксирован).

Полный `./gradlew :app:test` падает на существующем changeset
`02_view/g1v68/01-dr_v_wag_oper_repair_1c.xml` — ему нужна таблица внешней схемы
`ws_store`, которой в чистой базе нет. К изменениям этой задачи отношения не
имеет, но прогнать полный гейт нужно на контуре с заполненной `ws_store`.

---

## Этап 2 — интерфейсы

Начинать **после ответов на вопросы** из
[06-open-questions.md](06-open-questions.md). Часть работ от ответов не зависит
и может идти параллельно.

### Что блокирует какой вопрос

| Вопрос из `06-open-questions.md` | Что нельзя делать без ответа |
|---|---|
| 1. Правило заполнения `warranty_repair` (ФГК/ВРК1) | сервис автозаполнения `legal_warranty_repair` |
| 2. Уникальность `(wagnum, defect_date)` | перелив данных; при подтверждении — сделать индекс уникальным |
| 3. Совпадает ли `PSRMatNom` с `psr_number` | состав полей вкладки «Допретензионная работа»; при совпадении — убрать лишнюю пару колонок |
| 4. Откуда брать договор аренды | автозаполнение виновника по арендованному вагону |
| 5. Момент создания `_du` и `_case_one` | detail view: создавать записи сразу с претензией или лениво |
| 6. Какие вычисляемые поля нужны | состав грида и формы: `Srok_*` с подсветкой, `Straf_Summ`, `Tarif_Sum`, «ВСЕГО к возмещению», `Nedopl_money`, `DatEndPret` |
| 7. Резолвинг контрагентов Case.one после перелива | наполнение `legal_caseone_ref` по перенесённым `KAgPret_GUID` |
| 8. Разделение прав ДЭПС и ДЮ | роли и доступность полей на форме |

### Состав работ

1. **List view «Гарантийные ремонты»** — грид претензий с данными отцепки.
   Фильтры по аналогии с параметрами `pThp_PretTehSelect2`: период ремонта,
   период браковки, номер вагона, дорога, ВРП, виновник, вид ремонта, результат,
   «подлежит/не подлежит», реестр ДЮ, ПСР. Только `propertyFilter` и
   `jpqlFilter`, `genericFilter` не использовать. Скил `jmix-create-list-view`.
2. **Detail view претензии** — заголовок из `legal_warranty_repair` (только для
   чтения) и вкладки: «Документы», «Допретензионная работа» (ДЭПС),
   «Претензия», «Судебная работа» (ДЮ), «Копии документов». Разнесение полей по
   вкладкам — в [03-old-form.md](03-old-form.md). Скилы
   `jmix-create-detail-view`, `jmix-create-fragment` (вкладки удобно вынести во
   фрагменты).
3. **Роли ДЭПС и ДЮ** — разделить `LegalWarrantyRepairRole` на две по итогам
   вопроса 8, добавить `@ViewPolicy` и `@MenuPolicy`, запись в `menu.xml`.
   Скил `jmix-create-resource-role`.
4. **Выбор из справочников Case.one** — сервис живой загрузки из Public API
   (поиск контрагента по ИНН/наименованию, список пользователей, дерево
   каталогов), запись выбранного в `legal_caseone_ref` и снимка в претензию.
   Полного зеркала не делать.
5. **Сервис автозаполнения** `legal_warranty_repair` из ЕО/ВагТК и НСИ — состав
   источников в [05-column-mapping.md](05-column-mapping.md), раздел «Данные из
   других таблиц старой системы». Скилы `jmix-create-service`,
   `jmix-run-background-code` (если запуск по расписанию).
6. **Вычисляемые поля** — по итогам вопроса 6, в сервисе или как `@JmixProperty`
   на entity.
7. **Вкладка «Копии документов»** — сервис поверх Диадок и архивов фото, ничего
   не хранит в этих таблицах, см. [07-documents.md](07-documents.md).
8. **Отправка карточки в Case.one** — по кнопке «Отправить», результат в
   `legal_warranty_repair_case_one`. Понадобится карта соответствия «реквизит →
   UUID поля карточки Case.one»: ключи `Fields` свои на каждом стенде, держать
   их в БД, а не в коде. Пример карточки —
   `docs/caseone/pret_card_01 - пример карточки case one.json`.
9. **Перелив данных из ВагТК** — алгоритм в
   [05-column-mapping.md](05-column-mapping.md), раздел «Алгоритм переноса».
   Идемпотентность по `deps.src_id_zap`.

### Обязательные гейты этапа 2

1. Инспекция IDE по каждому `*-view.xml` — только она ловит нерезолвящиеся
   `msg://`, неверные property paths и отсутствующие data containers;
   запасное — `./gradlew :app:compileJava` плюс `jmix-ide-static-analysis`.
2. `./gradlew :app:test` — контекст поднимается, реестр view не отравлен.
3. Render-проход браузером по каждому новому view: нет error overlay, серверных
   исключений и сырых `msg://`.
