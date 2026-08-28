# 02. Авторизация и тестовый экран «Проверка API Case.one»

> **Этап 1.** Вторая задача: нажал кнопку — увидел сырой ответ Case.one в текстовом поле.
> Цель — доказать, что связка «настройки → токен → GET справочника» работает.
> **Таблицы-зеркала и сохранение данных в БД здесь не делаются** (это задачи 03–05).

## Результат задачи

Экран «Проверка API Case.one»: выбрал справочник, нажал «Выполнить» — в поле вывода появился
сырой JSON от Case.one плюс HTTP-код, время выполнения и число элементов. Ошибка — тоже
целиком в поле вывода, а не «что-то пошло не так».

Побочный, но важный результат: снятые с живого стенда JSON-ы сохраняются в
`docs/caseone/samples/` и становятся эталоном для маппинга (задача 03) и фикстурами для
тестов (задача 07).

## 1. `CaseOneRestConfiguration`

`app/src/main/java/ru/fgk/ws/app/legal/caseone/config/CaseOneRestConfiguration.java`

Бин `caseOneRestTemplate` через `RestTemplateBuilder`, по образцу
`app/src/main/java/ru/fgk/ws/app/asuvrk/config/AsuVrkApiConfiguration.java`.
Таймауты — из `CaseOneSettings` (`connectTimeoutMs`, `readTimeoutMs`).

Отдельный именованный бин обязателен: он же — точка подмены в тестах через `MockRestServiceServer`.

## 2. `CaseOneTokenService`

`app/src/main/java/ru/fgk/ws/app/legal/caseone/service/CaseOneTokenService.java`

`POST {baseUrl}/api/v2/auth/token`, `Content-Type: application/json`.
Тело: `{"grant_type":"password","username":"…","password":"…"}`
либо `{"grant_type":"refresh_token","refresh_token":"…"}`.

> Именно JSON: на `application/x-www-form-urlencoded` стенд отвечает `HTTP 415`.
> Проверено на `https://railfgk.ru.case.one` 2026-08-20, см. `00-overview.md`.

Ответ (`CaseOneTokenResponse`, snake_case — это OAuth2):
`access_token`, `token_type`, `expires_in`, `refresh_token`.

Кеш токена в памяти:

```java
record TokenState(String accessToken, String refreshToken, Instant expiresAt) {}
private final AtomicReference<TokenState> state = new AtomicReference<>();
```

| Метод | Поведение |
|---|---|
| `getAccessToken()` | если до `expiresAt` осталось < 60 с — обновиться: сперва `grant_type=refresh_token`, при ошибке — `grant_type=password`; вернуть `access_token` |
| `forceLogin()` | принудительный password grant; для кнопки «Проверить подключение» |
| `invalidate()` | сброс состояния; вызывается при 401 от API |

`expiresAt = Instant.now().plusSeconds(expires_in)`.

Ошибка 400 приходит как `{error, error_description}` — разворачивать в `CaseOneAuthException`
с текстом `error_description`, чтобы он дошёл до `lastCheckResult` и до поля вывода на экране.

**Пароль не логировать никогда** — в том числе при ошибке: `error_description` может его
процитировать, маскировать.

## 3. `CaseOneApiClient` — на этом этапе возвращает сырой текст

`app/src/main/java/ru/fgk/ws/app/legal/caseone/service/CaseOneApiClient.java`

Здесь принципиально **не** десериализуем справочники в DTO. Цель задачи — увидеть, что реально
отдаёт стенд, а не то, что мы предполагаем по PDF от февраля 2023.

```java
/** Сырой GET к Public API. Возвращает статус, тело как есть и длительность. */
CaseOneRawResponse get(String path, MultiValueMap<String, String> query);

record CaseOneRawResponse(int status, String body, long durationMs) {}
```

- Подставляет `Authorization: Bearer {token}` из `CaseOneTokenService`.
- На 401 — `invalidate()` и **ровно один** повтор. Второй 401 → исключение.
- Тело ошибки (4xx/5xx) не проглатывается, а возвращается в `body` — на экране оно нужно целиком.
- `path` собирается с `baseUrl` из настроек; двойные слэши убирать.

Из DTO на этом этапе нужен **только** `CaseOneTokenResponse`
(`app/src/main/java/ru/fgk/ws/app/legal/caseone/dto/`). DTO справочников — задача 03.

## 4. Экран `CaseOneApiProbeView`

`app/src/main/java/ru/fgk/ws/app/legal/caseone/view/probe/CaseOneApiProbeView.java`
+ `app/src/main/resources/ru/fgk/ws/app/legal/caseone/view/probe/case-one-api-probe-view.xml`

```java
@Route(value = "legal/caseone-probe", layout = MainView.class)
@ViewController(id = "legal_CaseOneApiProbeView")
@ViewDescriptor(path = "case-one-api-probe-view.xml")
```

### Ввод

| Компонент | Назначение |
|---|---|
| `select` «Запрос» | `Пользователи` → `/api/v2/users`, `Контрагенты` → `/api/v2/participants`, `Папки` → `/api/v2/folders`, `Произвольный GET` |
| `textField` «Путь» | активен только для `Произвольный GET`, напр. `/api/v2/folders/{id}`; для остальных — заполняется автоматически и read-only |
| `integerField` `page` | по умолчанию `1` |
| `integerField` `pageSize` | по умолчанию `5` — специально мало, чтобы ответ читался глазами |
| `textField` `parentId` | опционально, только для папок |
| `button` **«Выполнить»** | основное действие |
| `button` «Очистить» | очистка поля вывода |

### Вывод

- Строка статуса: `HTTP 200 · 342 мс · элементов: 5 · NextPageUrl: есть/нет`.
  Число элементов и `NextPageUrl` берутся лёгким разбором JSON (`Items`, `NextPageUrl`),
  без маппинга в DTO; если разбор не удался — просто не показываем эти два поля.
- `JmixTextArea` (или `codeEditor`, если он есть в проекте) — `readOnly`, моноширинный,
  `height="100%"`, растянут на всю оставшуюся высоту: pretty-printed JSON ответа.
  Pretty-print — через уже имеющийся в контексте `ObjectMapper`
  (`writerWithDefaultPrettyPrinter()`); если тело не парсится как JSON — вывести как есть.
- Ошибка (исключение или非-2xx) — в то же поле вывода целиком: класс исключения, сообщение,
  тело ответа. Плюс короткое `Notification` через `ru.fgk.ws.core.util.DefaultNotification`.

### Поведение

- Если `enabled = false` или `baseUrl`/`username`/`passwordEnc` пустые — кнопка «Выполнить»
  disabled, под ней подсказка со ссылкой на экран настроек.
- Запрос выполняется **не** в UI-потоке: `pageSize` может оказаться большим, а стенд медленным.
  Использовать `BackgroundJobService` (`app/src/main/java/ru/fgk/ws/app/common/job/`) либо
  `BackgroundTask`, кнопка на время выполнения — disabled.
- Кнопка «Скачать ответ» (`.json`) — по желанию; удобно для наполнения `docs/caseone/samples/`,
  но не обязательна: скопировать из текстового поля тоже можно.

## 5. Кнопка «Проверить подключение» на экране настроек

Дописать обработчик в `CaseOneSettingsView` (разметка заведена в задаче 01):
`CaseOneTokenService.forceLogin()` → записать `lastCheckAt` и `lastCheckResult`
(`OK` либо текст ошибки), показать `Notification`.

## 6. Меню

Добавить второй пункт в блок `legal_caseone` в `app/src/main/resources/ru/fgk/ws/app/menu.xml`:

```xml
<item view="legal_CaseOneApiProbeView"
      title="msg://ru.fgk.ws.app.legal.caseone.view.probe/caseOneApiProbeView.title"
      description="msg://ru.fgk.ws.app.legal.caseone.view.probe/caseOneApiProbeView.title"/>
```

## 7. Роль

В `LegalCaseOneAdminRole` дописать `legal_CaseOneApiProbeView` в `@MenuPolicy` и `@ViewPolicy`.
Отдельной роли под тестовый экран не заводим — он административный.

## 8. i18n

В `app/src/main/resources/ru/fgk/ws/app/messages_ru.properties`: заголовок экрана,
подписи полей и кнопок, варианты списка «Запрос», тексты уведомлений
(«Подключение установлено», «Не удалось подключиться: {0}»).

## Что снять со стенда по итогам задачи

Сохранить в `docs/caseone/samples/` (папку завести):

- `users-page1.json`
- `participants-page1.json`
- `folders-root.json`
- `folders-children.json` — ответ с `parentId` любой папки, у которой `HasChildren = true`

Эти файлы — вход для задачи 03 (маппинг колонок) и фикстуры для задачи 07 (тесты).

**Отдельно проверить и записать в `00-overview.md`:**

1. приходит ли `NextPageUrl` заполненным (или всегда `null` — тогда пагинация только по `page`);
2. приходит ли у папок `Children` рекурсивно заполненным — от этого зависит, нужен ли обход
   дерева в задаче 04;
3. совпадает ли хост в `NextPageUrl` с `baseUrl` из настроек (за прокси может отличаться);
4. есть ли в ответах поля, которых нет в спецификации от февраля 2023.

## Проверка

1. `./gradlew :app:test` — зелёный.
2. `bootRun` → «Настройки» заполнены, «Проверить подключение» → `lastCheckResult = OK`.
3. «Проверка API Case.one» → `Пользователи`, `pageSize = 5`, «Выполнить» →
   в поле вывода pretty-printed JSON с пятью пользователями, статус `HTTP 200`.
4. То же для `Контрагенты` и `Папки`.
5. Заведомо неверный путь через `Произвольный GET` → в поле вывода видно `404` и тело ошибки,
   приложение не падает.
6. Повторное нажатие в пределах срока жизни токена → в логе **нет** второго запроса
   `POST /api/v2/auth/token`.
7. В логах нигде не встречается пароль.
8. Тест `CaseOneTokenServiceIT` (`MockRestServiceServer` на `caseOneRestTemplate`):
   password grant → кеш → refresh по истечении → падение обратно на password grant →
   401 даёт ровно один повтор.
