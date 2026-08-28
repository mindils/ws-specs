# 07. Тесты и верификация

> **Этап 2.** Тесты этапа 1 (`CaseOneCryptoServiceTest`, `CaseOneTokenServiceIT`)
> написаны в задачах 01–02 — здесь всё остальное плюс сквозная проверка.

## Unit-тесты (без Spring-контекста)

| Тест | Что проверяет |
|---|---|
| `CaseOneCryptoServiceTest` | *(написан в задаче 01)* round-trip `encrypt`/`decrypt`; префикс `enc:`; понятная ошибка при пустом ключе; значение без префикса отвергается |
| `CaseOnePageJsonTest` | десериализация реальных JSON-семплов из `docs/caseone/samples/` в DTO; неизвестные поля не ломают разбор; `NextPageUrl = null` на последней странице |

Образец для JSON-тестов — `app/src/test/java/ru/fgk/ws/app/diadoc/cdidto/*DtoTest.java`.

## Интеграционные тесты

Наследники `app/src/test/java/ru/fgk/ws/app/test_support/BaseIntegrationTest.java`.
HTTP замокан через `MockRestServiceServer`, привязанный к бину `caseOneRestTemplate` — реальный
Case.one в тестах не дёргается.

### `CaseOneTokenServiceIT` *(написан в задаче 02)*
- password grant: один `POST /api/v2/auth/token`, токен закеширован;
- повторный `getAccessToken()` в пределах `expires_in` → нового запроса нет;
- истёкший токен → `grant_type=refresh_token`;
- ошибка refresh → падение обратно на password grant;
- 401 от API → `invalidate()` + ровно один повтор; второй 401 → исключение.

### `CaseOneSyncServiceIT` — ядро задачи
Ответ на три страницы, идём по `NextPageUrl`.

1. **Первый прогон:** `created == itemsRead`, `unchanged == 0`, `markedMissing == 0`,
   журнал в `SUCCESS`.
2. **Повторный прогон с теми же `LastChangeDate`:** `unchanged == itemsRead`, `created == 0`,
   `updated == 0`.
3. **Изменённая запись:** одна запись с новым `LastChangeDate` → `updated == 1`, поля перезаписаны.
4. **Исчезнувшая запись:** её нет в ответе → `is_missing = true`, физически не удалена.
5. **Ошибка на второй странице:** журнал в `ERROR`, `error_text` заполнен, и **ни одна запись
   не помечена `is_missing`** — это главный регресс-тест алгоритма.
6. **Параллельный запуск:** при висящем `RUNNING` второй вызов даёт
   `CaseOneSyncAlreadyRunningException`.

### `CaseOneFolderTreeIT`
Корневой ответ + два дочерних → `parent_id` заполнены корректно; цикл в данных
(папка ссылается на уже посещённую) не приводит к зацикливанию.

### `CaseOneSyncRestControllerTest`
Коды `200` / `409` / `503` / `500` и наличие тела во всех случаях.
Образец — `app/src/test/java/ru/fgk/ws/app/diadoc/controller/SavePacketRestControllerTest.java`.

## Команды

```bash
# точечно по ходу работы
./gradlew :app:test --tests "ru.fgk.ws.app.legal.*"

# полный релевантный scope перед финализацией (обязательно, CLAUDE.md §8)
./gradlew :app:test

# ручная проверка
./gradlew :app:bootRun
```

## Ручная проверка end-to-end

Нужен доступ к стенду Case.one и заполненные настройки.

1. **Настройки.** `bootRun` → меню «Претензионная и судебная работа» → «Case.one» → «Настройки».
   Заполнить URL / логин / пароль, включить `enabled`, сохранить.
   Нажать «Проверить подключение» → зелёное уведомление, `last_check_result = OK`.

2. **Пароль зашифрован.** MCP `rvk-ws`:
   ```sql
   select base_url, username, left(password_enc, 8) as prefix, length(password_enc)
     from main.legal_caseone_settings;
   ```
   Ожидаем `prefix = 'enc:'` и отсутствие исходного пароля в значении.

3. **Health-check.**
   ```bash
   curl -sS http://localhost:8080/api/caseone/checkConnection | jq
   ```
   → 200.

4. **Пользователи (быстрый справочник).**
   ```bash
   curl -sS -X POST http://localhost:8080/api/caseone/syncUsers | jq
   ```
   → 200 со счётчиками, `created == itemsRead`.
   Повторный вызов → тот же `itemsRead`, но `unchanged == itemsRead`, `created == 0`.

5. **Контрагенты — замер объёма.** Это и есть ответ на исходный вопрос «много ли там данных»:
   ```bash
   time curl -sS -X POST http://localhost:8080/api/caseone/syncParticipants | jq
   ```
   Записать `itemsRead`, `pagesRead` и затраченное время — от них зависит расписание в NiFi
   (задача 05) и таймаут HTTP-запроса в NiFi.

6. **Папки — проверка дерева.**
   ```bash
   curl -sS -X POST http://localhost:8080/api/caseone/syncFolders | jq
   ```
   ```sql
   select count(*) filter (where parent_id is null) as roots,
          count(*) filter (where parent_id is not null) as children,
          count(*) as total
     from main.legal_caseone_folder;
   ```
   Дерево должно быть непустым, папка «Претензии» (из `docs/caseone/pret_card_01 - пример карточки case one.json`,
   `Folder.Id = f565ef59-38e7-42be-97a1-ae4b0068f29e`) — на месте.

7. **Дельта и missing.**
   ```sql
   select count(*), count(*) filter (where is_missing) from main.legal_caseone_participant;
   ```
   После двух успешных прогонов подряд `is_missing` должен остаться нулевым.

8. **Журнал.** Экран «Журнал синхронизации» — записи в статусе `SUCCESS` со счётчиками,
   `triggered_by` = `NIFI` для curl-вызовов и `UI` для кнопки на экране.

9. **Конфликт прогонов.** Запустить `syncParticipants` и, не дожидаясь, повторить — второй вызов
   должен вернуть **409**, а не начать второй прогон.

10. **Роли.** Зайти пользователем с `legal-caseone-read` → справочники видны, «Настройки» и
    кнопка «Синхронизировать сейчас» — нет.

## Что зафиксировать по итогам

В `spec/caseone/00-overview.md`, раздел «Открытые вопросы» — дописать фактические цифры:
объём справочника контрагентов, время полного прогона, согласованное расписание NiFi.
