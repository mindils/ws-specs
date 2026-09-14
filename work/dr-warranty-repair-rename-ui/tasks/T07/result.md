# Результат T07

Таск: [task.md](task.md)
Итерация: 1
Обновлено: 2026-09-12

Ветка: `feature/caseone-table`, база — коммит `f2b96adc2 «step 1»`.
Изменения T07 **не закоммичены** — проверять по рабочему дереву.
В дереве также лежат незакоммиченные изменения T01 и наработки T02
(`VWarrantyRepairClaim`, `dr_v_warranty_repair_claim`); к T07 они не относятся.

## Что реализовано

Проверен реальный источник календаря и выбран **ровно один путь: собственная
НСИ в схеме `main`**. Производственного календаря нет ни в `main`, ни в
`ws_store`, ни в миграциях, ни в коде; отсутствие календаря в корпоративной
`ws_store` подтверждено пользователем. Внешняя схема не менялась.

Заведены три справочника и календарная арифметика:

- `main.nsi_work_calendar_day` — производственный календарь, **1096 строк**,
  сплошной диапазон 2024-01-01 … 2026-12-31, каждый день диапазона имеет
  однозначный признак `working` и вид дня. Отсутствующая дата отличается от
  нерабочей: расчёт за границей диапазона бросает `WorkCalendarGapException`
  с недостающей датой и фактическим покрытием, а не подставляет пятидневку.
- `main.nsi_claim_term_norm` — семь норм `KodPret=1` (16→2, 9→12, 10→10,
  11→19, 12→14, 13→4, 14→14, все рабочие дни), уникальность по виду претензии
  и коду операции. Неизвестная норма — исключение, а не ноль дней.
- `main.nsi_term_revision` — ревизии согласованного набора и контракт явной
  публикации для T08.

Ведение — экраны НСИ под административной ролью; рабочим ролям ДЭПС и ДЮ
чтение добавляет T03. Все три гейта пройдены, render-проход выполнен QA-агентом
(`PASS`) после исправления найденного им дефекта.

### Проверка источника: что именно выполнялось

БД rvk-ws поднята из `docker/docker-compose.yml` (`docker-rvk-db-1`,
`localhost:5432`, схемы `main` 191 таблица / 95 views, `ws_store` 76 таблиц /
8 views). Выполненные SELECT-ы (через `docker exec docker-rvk-db-1 psql -U root
-d postgres`):

```sql
-- 1. Объекты с календарными именами: найден только main.qrtz_calendars (Quartz).
select table_schema, table_name, table_type from information_schema.tables
where table_schema in ('main','ws_store','public')
  and (lower(table_name) ~ 'calend|holid|kalend|prazdn|work_?day|weekend|vyhod|prod_?cal|day');

-- 2. Колонки с признаками рабочего дня: только qrtz_calendars/qrtz_triggers.
select table_schema, table_name, column_name, data_type from information_schema.columns
where table_schema in ('main','ws_store','public')
  and (lower(column_name) ~ 'holid|hday|calend|work_?day|is_?work|weekend|day_?type|prazd');

-- 3. Комментарии объектов и колонок: 0 строк.
select n.nspname, c.relname, d.description from pg_description d
join pg_class c on c.oid = d.objoid join pg_namespace n on n.oid = c.relnamespace
where n.nspname in ('main','ws_store') and d.objsubid = 0
  and (d.description ilike '%календар%' or d.description ilike '%праздн%'
       or d.description ilike '%выходн%' or d.description ilike '%рабоч%дн%');

-- 4. Полный каталог ws_store (84 объекта) просмотрен вручную: аналога nsHoliday нет.
select table_name, table_type from information_schema.tables where table_schema='ws_store' order by 1;

-- 5. Небольшие таблицы ws_store с датами — кандидаты в календарь: подходящих нет.
select table_schema, table_name,
       count(*) filter (where data_type in ('date','timestamp without time zone')) dt_cols,
       count(*) all_cols
from information_schema.columns where table_schema='ws_store'
group by 1,2 having count(*) <= 6 order by 3 desc;
```

Дополнительно: `migration/ws_store` (все changelog-и), исходники `app`, `core`,
`sso-plagin` и соседний `../rvk-diadoc` — совпадений по `holiday|nsHoliday|
календар|праздн|workingday|work_day|isWorkingDay` нет.

**Граница проверки.** Корпоративная `devx.main.vgk` из этой среды не
резолвится (`getent hosts devx.main.vgk` — пусто), SQL MCP `mcp__rvk-ws__query`
не подключён. Локальная БД построена миграциями проекта, поэтому сама по себе
она не доказывает состав корпоративной `ws_store`. Пробел закрыт ответом
пользователя 2026-09-12 на прямой вопрос: календаря в корпоративной `ws_store`
нет, делаем свою НСИ. Вывод «календаря нет» не сделан по одному отсутствию в
миграциях.

### Наполнение и его источник

Источник — открытый производственный календарь РФ `xmlcalendar.ru` (сводка
постановлений Правительства РФ о переносах выходных):
`https://xmlcalendar.ru/data/ru/<год>/calendar.xml`, снято 2026-09-12; источник
согласован с пользователем. Разметка источника: `t=1` — нерабочий (праздник
`h` либо перенос `f`), `t=2` — сокращённый рабочий, `t=3` — рабочий день по
переносу; неперечисленные дни — обычная пятидневка. Каждый день года записан
явно, вместе с пояснением и ссылкой на источник в самой строке.

Контрольная сверка с официальным календарём по числу рабочих дней сошлась:
**2024 — 248, 2025 — 247, 2026 — 247** (закреплено тестом). Переносы взяты из
данных: рабочие субботы 27.04.2024, 02.11.2024, 28.12.2024, 01.11.2025.

**2027 год не заполнен намеренно**: постановление о переносах на 2027 год на
`xmlcalendar.ru` отсутствует (HTTP 404 на `.../ru/2027/calendar.xml`), а
выдавать будущую пятидневку за утверждённый календарь запрещено постановкой.
Следствие для T08: сроки, отсчёт которых (включая пороги +30 рабочих дней)
уходит в 2027 год, вернут ошибку данных с указанием недостающей даты, пока
администратор не дозаполнит календарь. Это ожидаемое поведение, а не пробел
реализации.

## Изменения и решения

### Новые файлы

| Область | Файлы |
|---|---|
| Entity и enum | `app/src/main/java/ru/fgk/ws/app/nsi/entity/`: `NsiWorkCalendarDay`, `NsiClaimTermNorm`, `NsiTermRevision`, `WorkCalendarDayKindEnum`, `ClaimTermDayTypeEnum`, `TermRevisionStatusEnum` |
| Сервисы | `app/src/main/java/ru/fgk/ws/app/nsi/service/`: `WorkCalendarService`, `WorkCalendarSnapshot`, `WorkCalendarCoverage`, `WorkCalendarGapException`, `ClaimTermNormService`, `ClaimTermNormNotFoundException`, `TermReferenceRevisionService`, `TermReferencePublicationHandler`, `TermReferenceDataChangeListener` |
| Схема | `liquibase/changelog/01-tbl/330-nsi_work_calendar_day.xml`, `331-nsi_claim_term_norm.xml`, `332-nsi_term_revision.xml` |
| Наполнение | `liquibase/changelog/04-data/330-nsi_work_calendar_day.xml` (1096 дней), `331-nsi_claim_term_norm.xml` (7 норм), `332-nsi_term_revision.xml` (ревизия 1) |
| Views | `nsi/view/workcalendarday/` (list + detail), `nsi/view/claimtermnorm/` (list + detail), `nsi/view/termrevision/` (list) — Java и XML |
| Роль | `app/src/main/java/ru/fgk/ws/app/nsi/security/NsiClaimTermEditRole.java` (`nsi-claim-term-edit`) |
| Тесты | `app/src/test/java/ru/fgk/ws/app/nsi/service/WorkCalendarSnapshotTest.java`, `app/src/test/java/ru/fgk/ws/app/it/WorkCalendarReferenceDataIT.java`, `NsiClaimTermEditRoleIT.java` |

Изменены: `app/src/main/resources/ru/fgk/ws/app/menu.xml` (группа
«Сроки претензий: календарь и нормы» с тремя пунктами внутри «Справочники»),
`messages_ru.properties` (+77 ключей: entity, атрибуты, три enum, заголовки и
подписи пяти views, сообщения слушателя),
`specs/.../input/calendar-behavior-differences.md` (раздел «Реализация
календаря»).

### Существенные решения

- **Календарь хранит каждый день, а не исключения.** Только так «нет строки»
  означает «за границей наполнения», а не «выходной». Полнота диапазона
  проверяется `WorkCalendarCoverage#isContinuous` и показывается администратору
  строкой над гридом календаря.
- **Признак `working` — единственный источник истины для расчёта**; вид дня
  (`WorkCalendarDayKindEnum`) и пояснение — для пользователя и для проверки
  переносов. Сокращённый предпраздничный день остаётся рабочим.
- **Отсчёт вынесен в `WorkCalendarSnapshot`, а не в T08**: постановка T07
  требует проверять рабочую субботу, подряд идущие праздники и отсутствующий
  день. T08 строит на этом назначение семи сроков и ветки `CASE`. Снимок
  загружается пакетно одним запросом — расчёт не ходит в базу за каждым днём
  (предпосылка C5 таска T08).
- **Идемпотентность наполнения — на уровне SQL**: `INSERT … ON CONFLICT DO
  NOTHING` по `calendar_date` и по `(claim_kind, operation_code)`. Повторный
  прогон не создаёт дублей и не затирает правки администратора; тест выполняет
  **ровно тот SQL, который лежит в changelog** (читает CDATA из ресурса).
- **Ревизия 1 записана сразу как `PUBLISHED`**: наполнение Liquibase идёт мимо
  Jmix, событий изменения entity не возникает, черновик не открывается.
- **Публикация транзакционная и «всё или ничего»**: исключение обработчика
  откатывает её целиком, черновик остаётся черновиком. Отдельного статуса
  `FAILED` нет намеренно — он был бы откачен вместе с транзакцией.
- **Конкурентные правки** разводит уникальный индекс по `revision_number`:
  две одновременные попытки открыть черновик дают отказ одной, а не два
  расходящихся черновика.
- Пороги 1/10/30 и палитра в НСИ не заводились — по решению плана они в коде.

### Найдено и исправлено render-проходом

QA-агент вернул `FAIL`: кнопки «Создать»/«Изменить» на обоих справочниках
падали с `NoSuchViewException: View 'NsiWorkCalendarDay.detail' is not defined`.
Стандартные `list_create`/`list_edit` ищут detail по имени entity, а id
контроллеров заданы с модульным префиксом `nsi_`. Исправлено явным
`<property name="viewId" value="nsi_NsiWorkCalendarDay.detail"/>` (и
`nsi_NsiClaimTermNorm.detail`) на обоих actions — так же, как это сделано в
`dr`- и `diadoc`-экранах проекта. Повторный проход — `PASS`.

Дефект показателен: `compileJava` и зелёный `:app:test` его не видели.

## Предварительные проверки

| Команда или сценарий | Результат |
|---|---|
| `docker info`, `(cd docker && docker compose ps)` | инфраструктура поднята: `docker-rvk-db-1` (PostgreSQL 16 на `localhost:5432`), Keycloak, MinIO, Temporal |
| Пять SELECT-ов проверки источника (см. выше) | календаря нет ни в `main`, ни в `ws_store` |
| `getent hosts devx.main.vgk` | не резолвится — корпоративная БД недоступна |
| `curl https://xmlcalendar.ru/data/ru/{2024,2025,2026}/calendar.xml` | 200; `2027` — 404 |
| `./gradlew :app:compileJava` | без ошибок |
| Механические проверки дескрипторов (`jmix-ide-static-analysis`) | чисто: package-строка, 0-байтовые файлы, BOM/пролог XML, `itemsQuery`, `= :`-параметры, сырой `Dialog`, `genericFilter`; все XML парсятся |
| Сверка всех `msg://` новых views, menu.xml и Java с `messages_ru.properties` | 26 ключей — все резолвятся |
| `./gradlew spotlessCheckAll` | чисто |
| `./gradlew :app:test` | **1293 passing, 12 pending, 1 failing** — единственный отказ `SsoOidcUserMapperConcurrencyIT#concurrentLoginsOfTheSameUserDoNotFail` (`OptimisticLockException` на `ru.fgk.sso.entity.User`), это таск T09, к T07 отношения не имеет |
| `./gradlew :app:test --tests "…WorkCalendarSnapshotTest" --tests "…WorkCalendarReferenceDataIT" --tests "…NsiClaimTermEditRoleIT"` | **25 passing**, повторно после правки XML |
| Render-проход QA-агента (Herdr + agy, playwright-cli) | сначала `FAIL` (`NoSuchViewException`), после исправления — `PASS`: три list view и два detail view открываются, данные в гридах, фильтры работают, диалоги создания и редактирования открываются и закрываются, сырых `msg://` нет |

### Что закрывают тесты

`WorkCalendarSnapshotTest` (10 проверок, без Spring) — четыре примера документа
отличий (старт в выходной, подряд идущие праздники, рабочая суббота, обычная
неделя), `N = 0`, отрицательное `N`, переход через год, выход за границы
календаря и различие «нет строки» / «нерабочий день».

`WorkCalendarReferenceDataIT` (12 проверок) — сплошное покрытие 1096 дней без
`null`-статусов, совпадение числа рабочих дней с официальным календарём по трём
годам, рабочие субботы и переносы из данных, отсутствующая дата как ошибка,
уникальность даты и нормы, семь норм с их значениями, повторный прогон обоих
changelog-ов наполнения без дублей и без затирания правок, неизвестная норма
как ошибка, протокол ревизий (начальная опубликована, правка открывает
черновик, публикация переключает версию, публиковать нечего).

`NsiClaimTermEditRoleIT` (3 проверки) — административная роль читает и ведёт
календарь и нормы; пользователь без неё не получает данных справочника и не
может писать (`AccessDeniedException` на сохранении).

## Для независимой проверки

Инфраструктура:

```bash
docker info
(cd docker && docker compose up -d)
```

Локальный datasource тестов — `app/src/test/resources/application-test-local.properties`
(`jdbc:postgresql://localhost:5432/postgres?currentSchema=main`). Гейты:

```bash
./gradlew :app:compileJava
./gradlew :app:test --tests "ru.fgk.ws.app.nsi.service.WorkCalendarSnapshotTest"
./gradlew :app:test --tests "ru.fgk.ws.app.it.WorkCalendarReferenceDataIT"
./gradlew :app:test --tests "ru.fgk.ws.app.it.NsiClaimTermEditRoleIT"
./gradlew :app:test
./gradlew spotlessCheckAll
```

Проверка данных в БД без приложения:

```bash
docker exec docker-rvk-db-1 psql -U root -d postgres -c \
  "select count(*), min(calendar_date), max(calendar_date) from main.nsi_work_calendar_day;"
docker exec docker-rvk-db-1 psql -U root -d postgres -c \
  "select operation_code, term_days, day_type from main.nsi_claim_term_norm order by stage_order;"
```

UI: `./gradlew :app:bootRun` (в фоне, дождаться `/actuator/health` = UP, затем
погасить — гейтом не считается), адрес `http://localhost:8080`. Вход — через
Keycloak либо локальную авторизацию `/local-login`; учётные данные тестового
пользователя даёт владелец среды, в рабочих документах они не хранятся.
Сценарии:

1. Меню «Справочники» → «Сроки претензий: календарь и нормы» →
   «Производственный календарь» (`/nsi-work-calendar-days`): над гридом строка
   о покрытии с датами 2024-01-01 и 2026-12-31; грид не пуст; фильтры «Дата с»
   / «Дата по» применяются; «Создать» и «Изменить» открывают диалог с полями
   Дата, Рабочий день, Вид дня, Пояснение, Источник данных.
2. «Нормы сроков претензионных этапов» (`/nsi-claim-term-norms`): 7 строк,
   коды операций 9-14 и 16, «Изменить» открывает диалог.
3. «Ревизии календаря и норм» (`/nsi-term-revisions`): строка состояния и
   кнопка «Опубликовать изменения»; на неизменённом наборе нажатие даёт
   уведомление «Публиковать нечего» без исключения. После правки любого дня
   календаря строка состояния сообщает о неопубликованных изменениях, а
   публикация создаёт ревизию 2 в состоянии «Опубликована».

Ни на одном экране не должно быть сырых `msg://`, error overlay и серверных
исключений в логе.

## Ограничения и связанные изменения

- **Календарь заполнен по 2026-12-31 включительно; 2027 год отсутствует
  намеренно** (постановление не опубликовано). Расчёты T08, выходящие за эту
  границу, будут возвращать ошибку данных. Дозаполнение — отдельным
  changelog-ом `04-data` или через административный экран, когда переносы на
  2027 год будут утверждены.
- **Gate 1 выполнен без IDE-инспекции**: Jmix-осведомлённого MCP
  (`get_file_problems`) в среде нет, использован откат — `compileJava` плюс
  механические проверки дескрипторов и сплошная сверка `msg://` по бандлу.
  Долг: переинспектировать новые `*-view.xml` в сессии, где инспекция доступна.
  Частично компенсировано render-проходом QA (Gate 3 `PASS`).
- **`TermReferencePublicationHandler` пока без реализаций**: публикация
  фиксирует согласованный набор, но ничего не пересчитывает. Это ожидаемо —
  связку завершает T08. Тест публикации проверяет протокол, а не пересчёт.
- Для T08: календарь и нормы читаются пакетно (`WorkCalendarService#loadSnapshot`,
  `ClaimTermNormService#loadNorms`); `WorkCalendarSnapshot#addWorkingDays`
  реализует согласованное правило (исходный день не считается, `N = 0` даёт
  исходную дату); ревизию для штампа расчёта даёт
  `TermReferenceRevisionService#findPublishedRevision`.
- Для T03: рабочим ролям ДЭПС и ДЮ нужны `READ` на `NsiWorkCalendarDay`,
  `NsiClaimTermNorm` и `NsiTermRevision`; `NsiClaimTermEditRole` не наследовать.
- Доказательств других тасков T07 не затрагивает: изменения лежат в новых
  файлах `nsi`, плюс добавления в `menu.xml` и `messages_ru.properties`.
  Существующие таблицы, entity и views не менялись.
- Наблюдение вне таска: в репозитории закоммичены два 0-байтовых дескриптора —
  `app/src/main/resources/ru/fgk/ws/app/diadoc/view/packetdocument/packet-document-detail-view.xml`
  и `packet-document-list-view.xml` (коммит `0c510be9f`). Сейчас они безвредны,
  так как ни один `@ViewDescriptor` на них не ссылается, но это ровно тот файл,
  что отравляет реестр views при первой же ссылке. Не трогал — вне T07.
