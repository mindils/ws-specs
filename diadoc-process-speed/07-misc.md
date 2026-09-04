# Task 07 (P3): Мелочи CPU-пути построчного разбора

Точечные находки, каждая по отдельности не «тормозит», но все они в построчных циклах
разбора больших пакетов (РДВ/МХ — тысячи строк).

## 1. `Pattern.compile` внутри метода

`dr/service/DiadocDetailAttributeResolverService.java:307` — регулярка компилируется
на каждый вызов; метод вызывается построчно из `fillDetailIdentity`/`resolveAxleType`
в разборе строк МХ (`DrOperRepairParserService.java:336-346`, `DrRdvContentService.java:210`).

Фикс: выкомпилированные `private static final Pattern` по константам regex (в проекте
это норма: `LocalPacketReportFactory.java:25`, `AbstractCdiPacketParserService.java:38` —
случай в `DiadocDetailAttributeResolverService` выбивается). Если regex собираются
динамически из справочника — завести `Map<String, Pattern>` с `computeIfAbsent`.

## 2. Линейный поиск по спискам классификации работ

`dr/service/RepairWorkClassificationService.java:72-104` — на каждую строку работ
`stream().anyMatch/filter` по списку кодов (`:73, 85, 100`). Списки кэшированы, но
выборка линейна: при больших РДВ — O(N_строк × M_кодов).

Фикс: индексировать справочник в `Set<String>`/`Map<...>` при загрузке кэша; семантика
(первое совпадение, порядок) — сохранить, где она значима.

## Проверка

Профилирование не требуется — правки локальны; достаточно:

- точечные тесты сервиса (если есть) или `--tests "*RepairWorkClassification*"`,
  `--tests "*DetailAttributeResolver*"`;
- `./gradlew :app:test` (полный прогон перед финализацией).
