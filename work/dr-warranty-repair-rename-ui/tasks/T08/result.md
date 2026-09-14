# Результат T08

Таск: [task.md](task.md)
Итерация: 1
Обновлено: 2026-09-12

Ветка: `feature/caseone-table`, база — коммит `f2b96adc2 «step 1»`.
Изменения T08 **не закоммичены** — проверять по рабочему дереву. В дереве также
лежат незакоммиченные наработки T01 (переименования), T02
(`VWarrantyRepairClaim`, `dr_v_warranty_repair_claim`) и T07 (НСИ календаря);
к T08 они не относятся, кроме того, что T08 на них опирается.

## Что реализовано

Семь сроков претензии и пороги просрочки считаются на Java по полному
календарю T07 и сохраняются в отдельной таблице `main.dr_warranty_repair_deadlines`
— одна строка на претензию. SQL-функций нет, ежедневная запись цвета не ведётся.

- **Чистый расчёт** `ClaimTermCalculator` принимает снимок исходных полей,
  снимок календаря и карту норм; зависимостей от Spring, entity и базы нет,
  поэтому проверяется обычным unit-тестом.
- **Условия назначения** выписаны из полной процедуры
  [pThp_PretTehSelect2](../../input/pThp_PretTehSelect2.sql), а не из
  комментариев: порядок пяти веток `Srok_PassPP`, ограничения по аренде и
  договору планового ремонта, исключение ДКФ, NULL-семантика сравнений,
  приоритеты `coalesce`, отдельный UPDATE судебного возврата.
- **Сохранение и пересчёт** — `WarrantyRepairDeadlineService` плюс слушатели
  `EntityChangedEvent` до коммита: ошибка расчёта откатывает исходное изменение.
- **Публикация ревизии** НСИ из T07 завершена: перед переключением версии
  выполняется полный пересчёт, при ошибке публикация откатывается целиком.
- **Документ отличий** дополнен разделом «Расчёт сроков (T08)»: карта кода и
  тестов, контракт актуальности для T02, таблица дат факта, порядок пересчёта,
  обязательный вызов после прямого импорта, практика границы календаря.

### Сопоставление старых полей с новыми (после T01)

| Старое | Новое | Старое | Новое |
|---|---|---|---|
| `Dat_Pass` | `deps.doc_package_ready_date` | `Dat_Send` | `du.claim_send_date` |
| `PassDoc_Date` | `deps.doc_transfer_date` | `ResultId` (`r.Result`) | `du.claim_result` |
| `FilG_Get` | `deps.pre_claim_transfer_date` | `Gar_Send` | `du.at_fault_reply_date` |
| `FilG_Name` | `deps.pre_claim_department` | `Sud_PassDt` | `du.to_law_date` |
| `Send_PD` (сырое) | `deps.claim_transfer_date` | `Sud_Dat` | `du.lawsuit_date` |
| `DatPret` | `du.claim_date` | `Pret_Vozvrat_Dt` | `du.rework_return_date` |
| `DoPret_Send` | `deps.pre_claim_send_date` | `Nomer_KT` | `repair.lease_contract_num` |
| `DoPret_Result` | `deps.pre_claim_result` | `DogNomer` | `repair.last_repair_contract_num` |
| `DoPret_Otvet_Dat` | `deps.pre_claim_reply_date` | `NoPret` / `NoPretId` | `deps.subject_to_claim` (инвертировано) |

Эффективное `Send_PD` = `coalesce(deps.claim_transfer_date, du.claim_date)` —
как `isnull(r.Send_PD, r.DatPret)` в исходном SELECT процедуры (строка 309).
`isnull(NoPretId, 0) = 0` стало `subject_to_claim <> false`: незаполненный
признак означает «подлежит претензии».

## Изменения и решения

### Новые файлы

| Область | Файлы |
|---|---|
| Entity и enum | `app/src/main/java/ru/fgk/ws/app/legal/warrantyrepair/entity/`: `WarrantyRepairDeadline`, `ClaimTermOverdueLevelEnum` |
| Расчёт | `app/src/main/java/ru/fgk/ws/app/legal/warrantyrepair/service/`: `ClaimTermCalculator`, `ClaimTermSource`, `ClaimTermStage`, `ClaimTermStageResult`, `ClaimTermCalculation`, `ClaimTermNormValue`, `ClaimTermStageStatus`, `ClaimTermReferenceContext`, `ClaimTermDateProvider` |
| Сервис и пересчёт | там же: `WarrantyRepairDeadlineService`, `WarrantyRepairDeadlineRecalculationListener`, `WarrantyRepairDeadlinePublicationHandler` |
| Схема | `app/.../liquibase/changelog/01-tbl/324-dr_warranty_repair_deadlines.xml` |
| Тесты | `app/src/test/java/ru/fgk/ws/app/legal/warrantyrepair/service/ClaimTermCalculatorTest.java`, `app/src/test/java/ru/fgk/ws/app/it/WarrantyRepairDeadlineIT.java` |

Изменены: `LegalWarrantyRepairRole` (+ READ на `WarrantyRepairDeadline`),
`messages_ru.properties` (+42 ключа: entity, 28 дат, три константы enum),
`specs/.../input/calendar-behavior-differences.md` (раздел «Расчёт сроков»).

### Существенные решения

- **Пороги сохраняются, степень — нет.** В таблице лежат срок и три даты
  порогов (+1/+10/+30 рабочих дней). Степень получается сравнением даты факта
  (иначе даты БД) с порогами при чтении, поэтому смена дня не требует записи.
  Это же позволяет db-view T02 фильтровать по степени в SQL.
- **Актуальность через номер ревизии.** В строке хранится `revision_number`
  ревизии НСИ. Расчёт актуален, когда строка есть И номер совпадает с последней
  опубликованной ревизией; иначе претензия остаётся в гриде с признаком
  «требуется пересчёт». Контракт для T02 записан в документе отличий.
- **Номер публикуемой ревизии передаётся явно.** В момент вызова обработчика
  публикуемая ревизия ещё в статусе `PUBLISHING`, а «последняя опубликованная»
  — прежняя. Расчёт, проштампованный ею, сразу считался бы устаревшим, поэтому
  у сервиса есть отдельный `recalculateAllForRevision(long)`.
- **Пересчёт — `@EventListener`, а не `@TransactionalEventListener`.** Нужен
  путь до коммита: иначе ошибка расчёта не откатывала бы исходное изменение.
  Проверено тестом `calculationErrorRollsBackSourceChange`.
- **Технический путь записи под системной аутентификацией.** Сервис работает
  через `UnconstrainedDataManager` внутри `systemAuthenticator.withSystem(...)`:
  расчёт пишется уже ПОСЛЕ того, как исходное изменение прошло проверку прав
  ДЭПС/ДЮ, и не зависит от того, дана ли пользователю роль на чтение НСИ.
  Пользователю таблица доступна только на чтение (`READ` + `VIEW`).
- **`@Version` на строке расчёта.** Конкурирующие пересчёты одной претензии
  сериализуются: устаревшая запись отвергается `OptimisticLockException`, а не
  затирает свежий расчёт. Первую вставку разводит уникальный индекс по `deps_id`.
- **Норма отделена от entity** (`ClaimTermNormValue`): расчёт не зависит от
  метамодели Jmix, а неполная норма отсекается при преобразовании, а не внутри
  расчёта. Побочный эффект — unit-тест без Spring и без enhancement entity.
- **Календарь и нормы — один раз на прогон** (`ClaimTermReferenceContext`).
  Массовый пересчёт идёт пачками по 500 претензий, но контекст НСИ грузится
  один раз, поэтому в одном прогоне не смешиваются дни разных версий.
- **Единая дата «сегодня»** — `select current_date` базы (`ClaimTermDateProvider`).
  Java-предпросмотр для detail-форм и db-view гридов обязаны брать одну дату,
  иначе около полуночи и при другом часовом поясе сервера подсветка разойдётся.
- **Круговая зависимость бинов разорвана на стороне T08.** `TermReferenceRevisionService`
  (T07) получает список обработчиков публикации, обработчику нужен сервис
  расчёта, а сервису — ревизии. Обработчик берёт сервис через `ObjectProvider`;
  код T07 не тронут.
- Автоподмена `Dat_Pass` по реализации деталей (45 рабочих дней), восьмой
  индикатор `Srok_FilOColor` и отчётные агрегаты `@Col` не переносились —
  по постановке.

### Схема

`main.dr_warranty_repair_deadlines`: 37 колонок — `id`, `version`, `deps_id`
(уникален), `revision_number`, `calculated_date`, 7 × 4 даты этапов, аудит.
Индексы: `pk_dr_warranty_repair_deadlines`, уникальный
`uq_dr_warranty_repair_deadlines_deps`, `idx_dr_warranty_repair_deadlines_revision`.

## Предварительные проверки

Все команды выполнены в этой сессии, БД — `docker-rvk-db-1` (PostgreSQL 16) на
`localhost:5432`.

| Команда или сценарий | Результат |
|---|---|
| `docker info`, `(cd docker && docker compose ps)` | инфраструктура поднята: `docker-rvk-db-1`, Keycloak, MinIO, Temporal |
| `./gradlew :app:compileJava` | без ошибок |
| `./gradlew spotlessCheckAll` | чисто |
| Механические проверки (`jmix-ide-static-analysis`): package-строка, 0-байтовые файлы, парсинг XML, сырой `Dialog`, политики роли | чисто по файлам таска. 0-байтовые `diadoc/view/packetdocument/*.xml` — закоммиченные ранее, вне T08 (наблюдение T07) |
| Сверка i18n скриптом: 37 полей entity, 3 константы enum | ключ есть у каждого, осиротевших ключей нет |
| `./gradlew :app:test --tests "…ClaimTermCalculatorTest"` | **40 passing** |
| `./gradlew :app:test --tests "…WarrantyRepairDeadlineIT"` | **14 passing** |
| `./gradlew :app:test` | **1347 passing, 12 pending, 1 failing** — единственный отказ `SsoOidcUserMapperConcurrencyIT#concurrentLoginsOfTheSameUserDoNotFail`, это таск T09 (решение Q03), к T08 отношения не имеет |
| Состав таблицы и индексы в БД (`psql`) | 37 колонок, уникальный индекс по `deps_id`, индекс по `revision_number` |
| Гейт 3 | не применим: views в таске нет, привязку detail проверяют T04/T05 |

### Что закрывают тесты

`ClaimTermCalculatorTest` (40 проверок, без Spring):

- **назначение сроков** — прикрепление комплекта без условия `NoPret`; аренда
  без договора планового ремонта для передачи в допретензионную работу, включая
  пустую строку договора; исключение ДКФ и NULL-подразделение; эффективное
  `Send_PD` с запасным `DatPret`; `isnull(ResultId, 2) in (2, 3)` для иска;
  «не подлежит претензии» оставляет один срок из семи; пустой успешный расчёт;
- **пять веток `Srok_PassPP`** — каждая даёт свою дату; ответ с признанием
  требования отсекается общим WHERE; отсутствие признаков передачи;
- **судебная передача** — база `isnull(Gar_Send, Dat_Send + 14)`; возврат
  претензии переопределяет срок, в том числе когда первый UPDATE его не
  назначал; возврат раньше передачи и возврат при пустом `Send_PD` не
  переопределяют; признанная претензия срока не получает;
- **пороги и степень** — значения +1/+10/+30; включающий первый порог и
  исключающие второй и третий; смена степени в выходной; завершённый этап
  замораживает просрочку; открытый сравнивается с текущей датой; порядок
  `coalesce` даты факта;
- **календарь и нормы** — рабочая суббота, подряд идущие праздники, переход
  через год, выход за границы календаря, отсутствующая норма, календарный тип
  отсчёта.

`WarrantyRepairDeadlineIT` (14 проверок, реальная БД): сохранение претензии
создаёт расчёт; предварительный расчёт совпадает с сохранённым; строка
существует при шести неприменимых этапах; изменение ДЮ и изменение отцепки
пересчитывают сроки (отцепка — все свои претензии); ставший неприменимым этап
очищает все четыре даты; ошибка расчёта откатывает изменение исходных данных;
удаление претензии убирает расчёт; массовый пересчёт повторяем и не плодит
строк; прямой импорт SQL-ом восстанавливается `recalculateAll()`; публикация
ревизии пересчитывает и штампует новый номер; ошибка при публикации не
оставляет смеси старых и новых расчётов; конкурентная перезапись отклоняется
контролем версии; пользователю расчёт доступен только на чтение.

## Для независимой проверки

Инфраструктура:

```bash
docker info
(cd docker && docker compose up -d)
```

Локальный datasource тестов — `app/src/test/resources/application-test-local.properties`
(`jdbc:postgresql://localhost:5432/postgres?currentSchema=main`).

```bash
./gradlew :app:compileJava
./gradlew spotlessCheckAll
./gradlew :app:test --tests "ru.fgk.ws.app.legal.warrantyrepair.service.ClaimTermCalculatorTest"
./gradlew :app:test --tests "ru.fgk.ws.app.it.WarrantyRepairDeadlineIT"
./gradlew :app:test
```

Схема без приложения:

```bash
docker exec docker-rvk-db-1 psql -U root -d postgres -c \
  "select count(*) from information_schema.columns
   where table_schema='main' and table_name='dr_warranty_repair_deadlines';"   -- 37

docker exec docker-rvk-db-1 psql -U root -d postgres -c \
  "select indexname, indexdef from pg_indexes
   where schemaname='main' and tablename='dr_warranty_repair_deadlines';"
```

Сверка с первоисточником: условия этапов — `../../input/srok-calc-notes.md`
(навигация) и `../../input/pThp_PretTehSelect2.sql` строки ~1030–1181 (полный
текст, первичен); нормы — `../../input/nvPretSrok_idoper_9-16.md`.

Проверка вручную через приложение в этом таске не требуется: экранов нет.
Если нужен ручной сценарий, претензию можно завести из интеграционного теста —
он же и убирает данные в `@AfterEach`.

## Ограничения и связанные изменения

- **Старая MSSQL-процедура не запускалась.** Совпадение с ВагТК обосновано
  разбором её кода и тестами на искусственном календаре. Пройденным гейтом
  сравнение с ВагТК не объявляется — это прямо записано в документе отличий.
- **Граница календаря 2026-12-31 видна пользователю.** Претензия, у которой
  срок или порог +30 рабочих дней уходит в 2027 год, не сохраняется:
  `WorkCalendarGapException` откатывает транзакцию. Поведение согласовано в
  T07, но администратору придётся дозаполнить календарь до конца 2026 года.
  Проверено тестом `calculationErrorRollsBackSourceChange`.
- **Gate 1 выполнен без IDE-инспекции**: Jmix-осведомлённого MCP в среде нет,
  использован откат — `compileJava`, `spotlessCheckAll` и механические
  проверки. Новых `*-view.xml` в таске нет, поэтому основной класс дефектов,
  который ловит только инспекция, здесь не возникает.
- **Затронут код T07 (косвенно).** `TermReferenceRevisionService#publish`
  теперь реально пересчитывает сроки: появилась первая реализация
  `TermReferencePublicationHandler`. Сами файлы T07 не менялись, его тесты
  зелёные. Тест T07 `publishWithoutChangesKeepsCurrentRevision` и протокол
  ревизий проверялись повторно в полном прогоне.
- **Для T02.** Таблица `main.dr_warranty_repair_deadlines` и контракт
  актуальности готовы; блокировка T02 снята. Присоединять LEFT JOIN по
  `deps_id` (уникален — число строк не растёт). Признак «требуется пересчёт»
  — `deadlines.deps_id is null or deadlines.revision_number <> (последняя
  опубликованная ревизия)`. Имена колонок и формулы степеней просрочки — в
  разделе «Расчёт сроков» документа отличий.
- **Для T03.** Рабочим ролям ДЭПС и ДЮ нужен `READ` + `VIEW` на
  `WarrantyRepairDeadline`, а также `READ` на `NsiWorkCalendarDay`,
  `NsiClaimTermNorm`, `NsiTermRevision` (требование T07). Права на запись
  расчёта не выдавать: строки пишет только сервис.
- **Для T04/T05.** Предварительный расчёт для detail-форм —
  `WarrantyRepairDeadlineService#preview(depsId)`: возвращает все семь этапов,
  включая неприменимые, с датой факта и степенью просрочки по дате БД.
- **Для интеграции (NiFi и перелив из ВагТК).** Прямой импорт обязан
  завершаться вызовом `WarrantyRepairDeadlineService#recalculateAll()` —
  контракт записан в документе отличий и покрыт тестом.
