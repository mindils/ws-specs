# Task 06 (P2): Полный delete+insert без diff при переобработке

## Проблема

Повторная обработка пакета (корректировки, ретраи NiFi, ручной reprocess из
`PacketReprocessService`) безусловно пересоздаёт весь наработанный контракт:

- `DrTr2PacketCleaner.java:28-38` — нативное удаление всех дочерних строк и шапки
  контракта по `repair_uid`, затем полная вставка заново
  (`recreateContract` в `AbstractDrRepairPacketParserService.java:357`);
- `DrPlanRepairParserService.java:73-81` — удаление детей + `dataManager.remove(contract)`;
- `Vu23PacketParserService.java:254-255` — `removePacket` / `savePacket`.

## Почему тормозит

Каждый reprocess — десятки-сотни delete + insert под advisory-локом (task 04), раздувание
таблицы (мертвые кортежи → autovacuum, seq-scan дороже), инвалидация всего, что связано
с контрактом. Для корректировочных пакетов (МХ, REMOVED_PARTS — их несколько на ремонт)
переобработка — штатный, а не редкий сценарий.

При этом это самый рискованный из всех tasks: delete+insert — осознанная модель
«пакет — источник истины, состояние пересоздаётся целиком», она гарантирует идемпотентность
и отсутствие «осевших» строк.

## Фикс

Не торопиться с diff-логикой. Дешёвые шаги раньше неё:

1. **Измерить частоту**: сколько вызовов `processPacket` приходят по уже наработанному
   ремонту (по `imported_packet_arch` / логам). Если reprocess редок — задачу закрыть как
   «принято», эффект дают tasks 01-04.
2. Если частотна — **early skip идентичного пакета**: сравнить с уже наработанным
   (например, по `operationsFirstAt`/hash состава документов — часть проверки
   `StalePacketCheckService` уже есть) и пропускать полную перестановку при идентичности.
3. Diff-перестановка (update изменённых строк вместо delete+insert) — только при
   подтверждённой необходимости и с отдельным дизайн-документом: слишком велик риск
   рассинхрона, который current-модель гарантирует.

## Проверка

- IT ре-обработки: `DrOperRepairTr2ParserServiceIT.parsePacket_reprocess_doesNotDuplicate*`,
  `DrPlanRepairParserServiceIT.parsePacket_reprocess_updatesInPlaceNotDuplicated` —
  семантика «повтор не плодит дубли» должна сохраниться при любом варианте фикса.
- `./gradlew :app:test`.
