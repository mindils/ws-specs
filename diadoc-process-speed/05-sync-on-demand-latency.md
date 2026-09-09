# Task 05 (P2): Синхронный REST-вызов rvk-diadoc внутри processPacket

## Проблема

`DiadocLocalPacketService.loadOrSync` (`diadoc/service/DiadocLocalPacketService.java:125-137`):
если пакета нет в локальном зеркале (NiFi ещё не донёс), наработка не отказывается, а
синхронно тянет пакет из источника:

```text
loadOrSync → SyncPacketService.sync (SyncPacketService.java:26-42)
  → PacketDocumentRemoteService.getPacketForSync
    (@RemoteService store="rvkdiadoc", PacketDocumentRemoteService.java:10-11 — Jmix REST DataStore)
  → SyncPacketPersistenceService.save (чанки по 500 строк, SyncPacketUpsertRepository.java:39)
```

Всё это выполняется внутри HTTP-запроса `/api/diadoc/processPacket`, в таймауте которого
NiFi считает ответ.

## Почему тормозит

Латентность = сетевой вызов rvk-diadoc (сборка всего среза пакета на той стороне) +
запись чанков + повторное чтение. Для пакета с тысячами строк это секунды-десятки секунд
до начала собственно наработки. Плюс: источник может быть недоступен/медлит — пользовательский
запрос стоит, ждёт, получает 500.

Сама синхронизация спроектирована аккуратно (идемпотентный upsert, батч 500, сортировка
по PK, advisory-лок на messageId в `SyncPacketPersistenceService.java:75`) — проблема не
в ней, а в том, что она в критическом пути первого обращения.

## Фикс

Варианты (обсудить с интеграцией):

1. **Не менять поведение, ограничить риск** — оставить sync-on-demand как страховку, но:
   - зафиксировать и явный таймаут REST-вызова rvkdiadoc, и явный таймаут/async-режим
     со стороны NiFi; при таймауте NiFi ретраит — второй заход идёт уже из зеркала.
   - добавить логирование длительности sync отдельной метрикой, чтобы видеть, сколько
     запросов реально платят эту цену (если их единицы — задачу закрыть «как есть»).
2. **Убрать implicit sync из API**: `/api/diadoc/processPacket` работает только с зеркалом
   (`parseLocalPacket`), при отсутствии пакета возвращает различимый исход
   (`PACKET_NOT_FOUND` уже есть), а синхронизацию гарантирует NiFi/отдельный сервис.
   Требует изменения контракта с NiFi (см. `specs/diadoc-processpacket-team-message.md`).

Рекомендация: начать с п.1 (метрика + таймауты), решение о п.2 — только с согласия
владельца интеграции.

## Проверка

- Логирование: в логах видна длительность `sync` отдельно от наработки.
- Тест: `DiadocManualSyncServiceTest` (мок `parseLocalPacket`) и контроллерные тесты
  `PacketParserRestControllerTest` — поведение при пустом зеркале не сломать.
- `./gradlew :app:test`.
