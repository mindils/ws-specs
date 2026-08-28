# Case.one — интеграция. Обзор

## Зачем

В `rvk-ws` нет блока для работы юристов. Заводим домен «Претензионная и судебная работа» и
первую интеграцию в нём — с внешней системой **Case.one** (претензионно-судебное
делопроизводство).

Конечная цель интеграции — автоматическое создание карточек претензий (ПСР) в Case.one с
прикреплением документов. **Этот этап — только фундамент:**

1. отдельный доменный пакет и меню под весь блок юристов;
2. форма настроек подключения к Case.one (URL, логин, пароль);
3. рабочая авторизация в Public API Case.one;
4. локальные таблицы-зеркала трёх справочников: `participants`, `users`, `folders`;
5. REST-эндпоинты, которые будет дёргать NiFi по расписанию.

Работа с карточками (`/api/v2/objects`) и документами (`/api/v3/documents`) — вне этого этапа,
но модель настроек и HTTP-клиент должны их выдержать без переделки.

## Исходные материалы

| Файл | Что там |
|---|---|
| `docs/caseone/Public API Case.One.pdf` | полная спецификация Public API, 455 стр., действует с 16.02.2023 |
| `docs/caseone/public-api-extract.txt` | текст, извлечённый из PDF — искать грепом вместо парсинга PDF |
| `docs/caseone/Какие функции мы используем при взаимодействии с Case one по API.txt` | скоуп: что реально используется |
| `docs/caseone/Реквизиты и регламент работы сервиса с case one.txt` | регламент: карточки создаются раз в час; обязательные поля карточки |
| `docs/caseone/pret_card_01 - пример карточки case one.json` | реальный ответ `GET /api/v2/objects/{id}` — пригодится на следующем этапе |
| `docs/caseone/Руководство администратора Case.onе.pdf` | админский справочник |

`public-api-extract.txt` размечен маркерами `--- PAGE N ---`, номера совпадают со страницами PDF.
Полезные страницы: авторизация 10–12, папки 132–136, участники 342–381, пользователи 419–428,
объекты (следующий этап) 15–109, документы 307–341.

## Факты по API, влияющие на решения

### Авторизация — `POST /api/v2/auth/token` (стр. 10)

Password grant, но тело — **`application/json`**, а не `application/x-www-form-urlencoded`.

> **Проверено на стенде `https://railfgk.ru.case.one` 2026-08-20.** На форму сервис отвечает
> `HTTP 415 Unsupported Media Type` (ASP.NET Core ProblemDetails). Предположение про
> form-urlencoded в первой редакции этой спеки было неверным: PDF описывает только модель
> `CaseDotStar.Shell.Models.TokenRequest`, Content-Type в нём не указан.
> Рабочее тело: `{"grant_type":"password","username":"…","password":"…"}`,
> обновление: `{"grant_type":"refresh_token","refresh_token":"…"}`.

Поля тела:

| Параметр | Обяз. | Описание |
|---|---|---|
| `grant_type` | да | `password` / `refresh_token` |
| `username` | нет | логин |
| `password` | нет | пароль |
| `refresh_token` | нет | для обновления токена |

Ответ: `access_token`, `token_type`, `expires_in` (сек, 0…2147483647), `refresh_token`.
Ошибка 400 → `{error, error_description}`. Далее — заголовок `Authorization: Bearer {access_token}`.

Есть также `POST /api/v2/auth/wintoken` (Windows-аутентификация) — нам не нужен.

### `GET /api/v2/participants` — контрагенты (стр. 377–381)

Query: `Type`, `Name`, `Phone`, `Email`, `INN`, `LastName`, `FirstName`, `KPP`, `page` (с 1), `pageSize`.
Ответ — `Page[Participant]`: `Items[]` + `NextPageUrl` (null на последней странице).

`Participant`: `Name`, `Type` (физлицо/компания), `ClientId`,
`PersonInfo{LastName, FirstName, MiddleName, Company{Id,...}, JobTitle, DateOfBirth, SSN}`,
`CompanyInfo{Name, IdNumber(ИНН), KPP, OGRN, OKPO, LegalForm{Id, Name}}`,
`ContactInfo{Email, Phone(400), Site(2000), Address}`,
`Id($uuid)`, `CreationDate`, `LastChangeDate`, `Url`.

### `GET /api/v2/users` — пользователи (стр. 425–428)

Query: `IsClient` (null/true/false), `IsLocked` (null/true/false), `page`, `pageSize`.
Ответ — `Page[User]`: `Items[]` + `NextPageUrl`.

`User`: `Name`, `Email`, `ExternalId`, `FirstName`, `LastName`, `MiddleName`, `Initials`(3),
`IsClient`, `IsLocked`, `WorkingStatus{Id, Name, SysName}`, `Id($uuid)`, `CreationDate`,
`LastChangeDate`, `Url`.

### `GET /api/v2/folders` — папки (стр. 133–136)

Query: `objectClassId`, `parentId`, `name`, `page`, `pageSize`.
Ответ — `Page[FolderListItem]`: `Items[]` + `NextPageUrl`.

`FolderListItem`: `Id`, `HasChildren`, `IsExpanded`, `Children` (список подпапок), `Rights`
(массив строк), `Name`, `ObjectClass{Name, Section, Icon, IsSystem, SysName, Id, ...}`,
`CreationDate`, `LastChangeDate`, `Url`.

> **Важно:** поля `ParentId` в ответе **нет** — родитель известен только из параметра запроса
> `parentId`. Поэтому обход папок рекурсивный: корневой `GET /api/v2/folders`, затем для каждой
> папки с `HasChildren=true` — `GET /api/v2/folders?parentId={id}`. Если на стенде корневой ответ
> уже приходит с рекурсивно заполненным `Children` — обход не нужен. Проверяется на живом API,
> см. задачу 02.

### Инкрементальной выборки нет

Ни у одного из трёх справочников нет фильтра по дате изменения. `minDate`/`maxDate` есть только
у `POST /api/v3/objects/GetObjects`, и это дата **создания**, и только для дел/объектов.

**Следствие:** забирать можно только всё. Дельта считается на нашей стороне — у каждой записи
есть `LastChangeDate`, сравниваем с сохранённым значением и пишем в БД только изменившиеся.
Объём: пользователи и папки — сотни записей; контрагенты — потенциально десятки тысяч,
реальный размер меряется на стенде на первом прогоне (счётчик страниц пишется в журнал
синхронизации).

Удалений API тоже не отдаёт → физически ничего не удаляем, помечаем `is_missing = true` записи,
не встретившиеся в **успешно завершившемся** полном обходе.

## Принятые решения

| Решение | Выбор | Почему |
|---|---|---|
| Пакет / меню | `ru.fgk.ws.app.legal`, интеграция — `ru.fgk.ws.app.legal.caseone`; меню `id="legal"` | под весь блок юристов, а не только под Case.one |
| Настройки | сущность в БД + форма в UI, пароль шифруется | менять без рестарта, пароль не лежит открытым |
| Шифрование | Spring Security `TextEncryptor`, ключ из env `CASEONE_SECRET_KEY` | `spring-security-crypto` уже на classpath |
| PK зеркал | `UUID` = `Id` из Case.one, без суррогатного ключа | идемпотентный upsert без lookup-а; связи хранятся как UUID |
| Защита REST для NiFi | `@AnonymousAllowed` + `jmix.resource-server.anonymous-url-patterns` | единообразно с `/api/diadoc/*` и `/api/asuvrk/*` |
| Планировщик | нет, снаружи дёргает NiFi | так решено заказчиком |

Отклонение от `CLAUDE.md` (там дефолт — `Long id` + `IDENTITY`): для таблиц-зеркал берём UUID
источника как PK. Это осознанное исключение, обычные таблицы (`legal_caseone_settings`,
`legal_caseone_sync_log`) остаются на `Long` + `IDENTITY`.

## Задачи

### Этап 1 — «работает / не работает»

Цель этапа: убедиться на живом стенде, что авторизация и чтение справочников работают.
Никаких таблиц-зеркал и сохранения данных в БД.

| № | Файл | Содержание |
|---|---|---|
| 01 | `01-settings-screen.md` | доменный пакет `legal`, меню, сущность настроек, шифрование пароля, **экран настроек** (URL / логин / пароль) |
| 02 | `02-api-probe-screen.md` | RestTemplate, токен-сервис, `CaseOneApiClient` с сырым ответом, **тестовый экран**: кнопка → JSON в текстовом поле |

Порядок строго 01 → 02.

**Что этап должен дать на выходе, кроме кода:** снятые с живого стенда JSON-ы в
`docs/caseone/samples/` и ответы на четыре вопроса из `02-api-probe-screen.md`
(заполнен ли `NextPageUrl`, приходит ли `Children` у папок рекурсивно, совпадает ли хост в
`NextPageUrl` с `baseUrl`, есть ли поля сверх спецификации 2023 года). От них зависят задачи 03–04.

### Этап 2 — зеркала и синхронизация

Начинается после того, как этап 1 подтверждён на стенде. Планировать детально имеет смысл
только с реальными JSON-ами на руках.

| № | Файл | Содержание |
|---|---|---|
| 03 | `03-dictionaries-model.md` | DTO справочников, три таблицы-зеркала + журнал, Liquibase |
| 04 | `04-sync-service.md` | алгоритм синхронизации, upsert, обход дерева папок, пометка missing |
| 05 | `05-rest-endpoints.md` | эндпоинты для NiFi |
| 06 | `06-dictionary-views-and-roles.md` | экраны справочников и журнала, роль на чтение |
| 07 | `07-testing-and-verification.md` | тесты и ручная проверка |

Порядок: 03 → 04 → 05, задача 06 закрывается по мере готовности 03–05, задача 07 — в конце.

## Что показал стенд (`https://railfgk.ru.case.one`, 2026-08-20)

Ответы на четыре вопроса из задачи 02. Образцы — в `docs/caseone/samples/`.

| Вопрос | Ответ |
|---|---|
| `NextPageUrl` заполнен? | **Да**, у всех трёх справочников: `…/api/v2/users?page=2&pageSize=5`. На последней странице — `null`. |
| `Children` у папок приходят рекурсивно? | **Да**, всё дерево приходит одним корневым запросом. Обход по `parentId` в задаче 04 **не нужен**. |
| Хост в `NextPageUrl` совпадает с `baseUrl`? | **Да**, `https://railfgk.ru.case.one`, прокси не подменяет. |
| Есть ли поля сверх спецификации 2023? | **Да, и часть полей переименована** — см. таблицу ниже. |

### Расхождения ответов стенда со спецификацией от февраля 2023

Это напрямую влияет на маппинг в задаче 03 — ориентироваться нужно на образцы, не на PDF.

| Справочник | В PDF | На стенде |
|---|---|---|
| `users` | — | добавилось `LastLoginDate` |
| `participants` | `PersonInfo` | **`IndividualInfo`** |
| `participants` | `ClientId` | **`LEDESClientId`** |
| `participants` | `ContactInfo{Email, Phone, …}` | добавились `EmailMain`, `PhoneMain` |
| `participants` | `LegalForm{Id, Name}` | `LegalForm{Id, CreationDate, LastChangeDate, Url}` — **без `Name`**, название тянуть отдельным запросом по `Url` (`/api/v2/legalForms/{id}`) |
| `folders` | `HasChildren` | **`IsLeaf`** (смысл инвертирован) |
| `folders` | `Children` | **`Items`** |
| `folders` | `IsExpanded` | **`Opened`** |
| `folders` | `Rights` | **`Permissions`** |

> **`IsLeaf` доверять нельзя.** На стенде он равен `false` у всех узлов, включая заведомо
> бездетные: запрос `?parentId={id}` для такого узла возвращает `Items: []`. Признак наличия
> детей — непустой вложенный `Items`, а не `IsLeaf`.

Значения `Type` у контрагента приходят строкой: `"Company"` (в выборке физлиц не встретилось —
проверить на большей выборке перед задачей 03).

## Открытые вопросы (не блокируют этап)

- **Ротация ключа шифрования.** При смене `CASEONE_SECRET_KEY` пароль в БД надо перевводить.
  Пока приемлемо; при необходимости — версионирование ключа в префиксе (`enc1:`, `enc2:`).
- **Защита эндпоинтов.** Сейчас анонимно, как у остальных `/api/*`. Закрывать имеет смысл все
  разом при общей ревизии `anonymous-url-patterns`, а не только Case.one.
- **Частота синхронизации в NiFi.** Регламент говорит про раз в час для создания карточек.
  Для справочников это избыточно — предложение: контрагенты раз в сутки ночью, пользователи и
  папки раз в 2–4 часа. Уточнить после замера времени полного прогона (см. задачу 07).
