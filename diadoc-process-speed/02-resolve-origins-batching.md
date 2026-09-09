# Task 02 (P1): N+1 в `MhDetailOriginService.resolveOrigins`

## Проблема

`app/src/main/java/ru/fgk/ws/app/dr/service/MhDetailOriginService.java:106-160` — цикл
`for (DiadocWagOperRepairContractMh row : numberedRows)`, и на каждую номерную строку МХ-3
выполняются отдельные обращения к БД:

| Обращение | Строка | Что делает |
|-----------|--------|-----------|
| `mh1cBalanceValidator.validate(row, ...)` | `:120-121` | → `Mh1cBalanceValidator.validate` (`dr/validation/Mh1cBalanceValidator.java:55-60`) → `Pt1cBalanceLookup.findAllByDetailUidHash` (`pt/service/Pt1cBalanceLookup.java:28`) — запрос к `v_pt_1c_balance` (поверх `ws_store.pt_1c_balance`) на каждую строку, кэша нет |
| `findDonor(row.getDetailUid(), ...)` | `:132-133`, метод `:254-282` | отдельный запрос на строку |
| `loadOperPacket` / `loadPlanPacket` | `:147` / `:154`, методы `:285-303` | PK-load пакета донора на строку |
| `loadOperPayment` / `loadPlanPayment` | `:151` / `:158`, методы `:305-324` | запрос к view платёжки на строку |

Итого до 4-5 round-trip на каждую строку: пакет с десятками номерных деталей — сотни
запросов. Запросы к остаткам дополнительно бьют по неиндексированной таблице
`ws_store.pt_1c_balance` (см. task 03) — каждый round-trip сам по себе дорог.

Всё это происходит внутри транзакции записи под advisory-локом ремонта
(`AbstractDrRepairPacketParserService.java:327, 393`) — время N+1 напрямую удерживает лок
(task 04).

## Фикс

Сохранить семантику построчного резолвинга, убрать построчность обращений:

1. До цикла собрать наборы: все `detailUidHash` номерных строк; все `detailUid` для поиска
   доноров.
2. Загрузить батчами:
   - остатки: один запрос `Pt1cBalanceLookup` c `detailUidHash in :hashes` (добавить метод
     в lookup), сгруппировать в `Map<String, List<Pt1cBalance>>`;
   - доноры: один запрос `DiadocWagOperRepairContractMh` c `detailUid in :uids and isMh3 = false`
     с последующим выбором донора в памяти по тем же правилам, что сейчас в
     `findDonor` (`mhDate < mhDate строки`, исключение своего ремонта);
   - пакеты и платёжки доноров: после сбора `donorRepairUid`/`donorRepairUidPlan` —
     по одному `in`-запросу на каждый вид.
3. Внутри цикла — только работа с map'ами.

Порядок/детерминизм: выбор «последнего подходящего донора» при нескольких кандидатах
сохранить идентичным текущему (`findDonor` берёт `setMaxResults(1)` с сортировкой —
перенести сортировку в in-memory компаратор или в один запрос с `distinct on`).

## Проверка

- Существующие IT: `DiadocPacketCorrectionIT`, `DrOperRepairTr2ParserServiceIT`
  (`parsePacket_reprocess_*`), `DrPlanRepairParserServiceIT` — поведение происхождения
  деталей не должно измениться.
- Новый/расширенный IT: пакет с N строками МХ-3, засечь число запросов (EclipseLink
  logging SQL в тестовом профиле) — должно быть O(1) вместо O(N).
- `./gradlew :app:test`.
