# 05. REST-эндпоинты для NiFi

> **Этап 2.** Требует задачи 04.

## Цель

Планировщика внутри приложения нет — расписание держит NiFi. Ему нужны HTTP-ручки, дёргающие
`CaseOneSyncService`, и понятный ответ со статистикой.

## Контроллер

`app/src/main/java/ru/fgk/ws/app/legal/caseone/controller/CaseOneSyncRestController.java`

По образцу `app/src/main/java/ru/fgk/ws/app/diadoc/controller/SyncPacketRestController.java`:

```java
@RestController
@RequestMapping("/api/caseone")
@AnonymousAllowed
public class CaseOneSyncRestController { ... }
```

Constructor injection; вся работа — внутри `systemAuthenticator.withSystem(...)`
(`io.jmix.core.security.SystemAuthenticator`), иначе не будет прав на запись сущностей.

## Пути — плоские, один уровень

Существующий паттерн в `application.properties` использует `/*`, а он покрывает ровно один
сегмент. Поэтому **не** `/api/caseone/sync/participants`, а:

| Метод | Путь | Назначение |
|---|---|---|
| POST | `/api/caseone/syncParticipants` | синхронизация контрагентов |
| POST | `/api/caseone/syncUsers` | синхронизация пользователей |
| POST | `/api/caseone/syncFolders` | синхронизация папок |
| POST | `/api/caseone/syncAll` | все три последовательно |
| GET | `/api/caseone/checkConnection` | проверка авторизации, health-check для NiFi |

## Ответ

```java
public record CaseOneSyncResponse(
    String dictionary,
    String status,
    Long syncLogId,
    int pagesRead,
    int itemsRead,
    int created,
    int updated,
    int unchanged,
    int markedMissing,
    String error) {}
```

`syncAll` отдаёт `List<CaseOneSyncResponse>` — по элементу на справочник.

## Коды ответа

| Код | Когда |
|---|---|
| 200 | прогон завершён успешно |
| 409 | по этому справочнику уже идёт прогон (`CaseOneSyncAlreadyRunningException`) |
| 503 | интеграция выключена (`settings.enabled = false`) |
| 500 | любая другая ошибка; тело с заполненным `error` |

Тело возвращается во всех случаях — NiFi должен видеть причину, а не только код.
Все ошибки логируются через `log.error` с указанием справочника.

## Конфигурация доступа

В `app/src/main/resources/application.properties` дописать паттерн в существующую строку:

```properties
jmix.resource-server.anonymous-url-patterns=/api/diadoc/*,/api/asuvrk/*,/api/health/*,/api/caseone/*
```

Это тот же уровень защиты, что у `/api/diadoc/*` и `/api/asuvrk/*` — осознанное решение
(см. `00-overview.md`, открытые вопросы). Закрывать имеет смысл все `/api/*` разом при общей
ревизии, а не только Case.one.

## Примеры вызова

```bash
curl -sS -X GET  http://localhost:8080/api/caseone/checkConnection | jq
curl -sS -X POST http://localhost:8080/api/caseone/syncUsers        | jq
curl -sS -X POST http://localhost:8080/api/caseone/syncParticipants | jq
curl -sS -X POST http://localhost:8080/api/caseone/syncFolders      | jq
curl -sS -X POST http://localhost:8080/api/caseone/syncAll          | jq
```

## Рекомендация по расписанию NiFi

Регламент (`docs/caseone/Реквизиты и регламент работы сервиса с case one.txt`) говорит про раз
в час — но это про **создание карточек**, не про справочники. Для справочников предложение:

| Справочник | Частота | Почему |
|---|---|---|
| `syncParticipants` | раз в сутки, ночью | самый объёмный, меняется редко |
| `syncUsers` | раз в 2–4 часа | сотни записей, прогон секунды |
| `syncFolders` | раз в 2–4 часа | структура меняется редко, прогон быстрый |

Финальные значения — после замера времени полного прогона (задача 07, шаг 5).
В NiFi выставить таймаут HTTP-запроса заведомо больше времени прогона по контрагентам.
