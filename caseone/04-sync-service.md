# 04. Сервис синхронизации справочников

> **Этап 2.** Требует задач 01–03.

## Цель

Полный постраничный обход справочника Case.one, upsert в локальное зеркало, подсчёт дельты и
пометка исчезнувших записей. Без планировщика — вызывается снаружи (задача 05) или из UI.

## Почему полный обход

У `/api/v2/participants`, `/api/v2/users`, `/api/v2/folders` **нет фильтра по дате изменения**
(проверено по спецификации, см. `00-overview.md`). `minDate`/`maxDate` есть только у
`POST /api/v3/objects/GetObjects`, и это дата создания, и только для дел/объектов.

Значит: тянем всё, а дельту считаем у себя — по `LastChangeDate` каждой записи. Экономия не в
трафике, а в записи в БД: неизменившиеся записи не переписываются.

## `CaseOneSyncService`

`app/src/main/java/ru/fgk/ws/app/legal/caseone/service/CaseOneSyncService.java`

```java
CaseOneSyncResult sync(CaseOneDictionary dictionary, CaseOneSyncTrigger triggeredBy);
List<CaseOneSyncResult> syncAll(CaseOneSyncTrigger triggeredBy);
```

`CaseOneSyncResult` — record со счётчиками: `dictionary`, `syncLogId`, `status`, `pagesRead`,
`itemsRead`, `created`, `updated`, `unchanged`, `markedMissing`, `error`.

## Алгоритм (одинаков для трёх справочников, различается маппером)

1. **Проверка глушилки.** `settings.enabled == false` → `CaseOneDisabledException`.
2. **Защита от параллельного запуска.** Если по этому справочнику уже есть запись журнала в
   статусе `RUNNING` — `CaseOneSyncAlreadyRunningException`. NiFi может прислать повторный
   триггер, пока идёт долгий прогон по контрагентам.
3. **Открыть журнал.** Создать `legal_caseone_sync_log` со `status = RUNNING`; его `id` = `syncRunId`.
4. **Постранично тянуть данные** через `CaseOneApiClient` (`pageSize` из настроек, идти по
   `NextPageUrl`).
5. **Каждую страницу обрабатывать в отдельной транзакции** (`@Transactional(propagation = REQUIRES_NEW)`
   в отдельном bean-е, иначе self-invocation не сработает):
   - собрать id всех записей страницы;
   - загрузить существующие **одним запросом**:
     `dataManager.load(X.class).query("select e from legal_X e where e.id in :ids").parameter("ids", ids).list()`
     — никакого поиска по одной записи (N+1);
   - для каждой записи:
     - нет в БД → создать, `created++`;
     - есть и `source_last_change_date` равен `LastChangeDate` из ответа → обновить только
       `synced_at`, `sync_run_id`, `is_missing = false`; `unchanged++`;
     - есть и дата отличается (или в источнике null) → перезаписать все поля; `updated++`;
   - сохранить пачкой: один `DataManager.save(SaveContext)` на страницу.
6. **Пометка исчезнувших — только при полном успешном обходе:**
   ```sql
   update legal_caseone_X
      set is_missing = true
    where sync_run_id is distinct from :currentRunId
      and is_missing = false
   ```
   Одним UPDATE (native/JPQL через `EntityManager`), результат → `markedMissing`.

   > **Критично:** при ошибке на любой странице этот шаг **пропускается**. Частичный обход,
   > помеченный как полный, пометит `is_missing` весь справочник.

7. **Закрыть журнал:** `SUCCESS` со счётчиками либо `ERROR` с `error_text` (первые ~4000 символов
   стектрейса/сообщения). Закрытие журнала — в отдельной транзакции, чтобы запись сохранилась
   даже при откате рабочей.

Физического удаления нет ни при каком сценарии: API не отдаёт признак удаления, а на записи
могут быть ссылки из будущих карточек.

## Обход дерева папок

`GET /api/v2/folders` не возвращает `ParentId` — родитель известен только из параметра запроса.
Поэтому:

1. корневой запрос `GET /api/v2/folders` (без `parentId`) → `parent_id = null` у всех записей;
2. очередь из папок с `HasChildren = true`;
3. для каждой — `GET /api/v2/folders?parentId={id}`, `parent_id` проставляется из контекста;
4. `Set<UUID> visited` — защита от циклов; повторно посещённую папку пропускать;
5. `pagesRead` считает **все** запросы, включая дочерние.

Если проверка из задачи 02 покажет, что `Children` приходит заполненным рекурсивно — обход
заменяется на разбор вложенности одного ответа, остальной алгоритм не меняется.

## Фоновый запуск из UI

Кнопка «Синхронизировать сейчас» на экранах справочников (задача 06) вызывает тот же
`CaseOneSyncService`, но через `BackgroundJobService`
(`app/src/main/java/ru/fgk/ws/app/common/job/`) с `triggeredBy = UI` — прогон по контрагентам
может идти минутами, блокировать UI нельзя.

## Логирование

- `INFO` на старт и финиш прогона со счётчиками.
- `DEBUG` на каждую страницу (`page`, `items`, накопленные счётчики).
- `WARN` на пропуск записи с битыми данными (например, `Id` не парсится в UUID) — прогон
  продолжается, число пропусков попадает в `error_text` при успешном в остальном обходе.
- Токен и пароль в логи не попадают.

## Проверка

- Первый прогон: `created == itemsRead`, `unchanged == 0`, `markedMissing == 0`.
- Второй прогон сразу следом: `unchanged == itemsRead`, `created == 0`, `updated == 0`.
- Ручное изменение `source_last_change_date` у одной строки в БД → следующий прогон даёт
  `updated == 1`.
- Тесты — задача 07.
