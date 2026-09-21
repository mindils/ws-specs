# T03 — Зеркало rvk-ws: колонка supplement_document, sync, DTO, DOCID_ARR

Статус: todo
План: [plan.md](../../plan.md)
Зависимости: нет
Сложность: easy — одна колонка сквозь entity/changelog/DTO/upsert по образцу
`relatedDocument`, контракт задан планом
Сложность проверки: easy — unit-тесты sync и SQL-сверка
Актуальная проверка: нет

## Коротко

Локальное зеркало `diadoc_packet_doc_link` в rvk-ws получает признак
«документ-дополнение» `supplement_document`, который rvk-diadoc начнёт
присылать в бандле `getPacketForSync` (T05). Признак проходит через
sync-DTO, upsert и DTO документа, чтобы T02 (проверка связанных) и T04
(карточка пакета) могли на него опираться. Заодно enum
`DocumentDataSource` узнаёт значение `DOCID_ARR`, которое источник пишет
давно.

## Результат и контекст

Линк — `app/src/main/java/ru/fgk/ws/app/diadoc/entity/DiadocPacketDocLink.java`
(`mainDocument`, `relatedDocument`, `dataSource`, `originalMessageId`,
soft-delete); changelog `app/src/main/resources/ru/fgk/ws/app/liquibase/
changelog/01-tbl/tbl-diadoc_packet_doc_link.xml` (changeSet 1 `createTable`,
далее индексы и `addColumn`). Бандл — `diadoc/service/SyncPacketBundleDto.java`
(`LinkRow`, Gson `@SerializedName`, строки ~679-750), upsert —
`diadoc/service/SyncPacketUpsertRepository.java` (`LINK_COLUMNS` ~98-105,
`linkValues` ~226). DTO документа — `diadoc/dto/DocumentItemDto.java`
(`related`, `dataSource`), `diadoc/dto/rest/DocumentItemRestDto.java`,
`diadoc/mapper/PacketDocumentMapper.java`. `DocumentDataSource`
(`diadoc/entity/DocumentDataSource.java`) содержит `packet_document`,
`entity_detail`, `merged`; источник пишет `DOCID_ARR`, поэтому
`getDataSource()` для таких линков возвращает `null`.

Контракт (план, «Общие решения»): JSON бандла `links[].supplementDocument`
(Boolean, может отсутствовать у старого источника → `null`/`false`);
`DocumentItemDto`/`DocumentItemRestDto` — поле `supplement` с JSON-именем
`is_supplement`; entity `DiadocPacketDocLink.supplementDocument`
(`Boolean`, колонка `supplement_document BOOLEAN`); `DocumentDataSource.
DOCID_ARR("DOCID_ARR")`.

## Область и изоляция

Меняются: `DiadocPacketDocLink.java`, `DocumentDataSource.java`,
`SyncPacketBundleDto.java`, `SyncPacketUpsertRepository.java`,
`DocumentItemDto.java`, `DocumentItemRestDto.java`,
`PacketDocumentMapper.java`, `tbl-diadoc_packet_doc_link.xml`, ключ
`ru.fgk.ws.app.diadoc.entity/DiadocPacketDocLink.supplementDocument=Документ-дополнение`
в `messages_ru.properties`, тесты `app/src/test/java/ru/fgk/ws/app/diadoc/
service/SyncPacketBundleDtoJsonTest.java`, `SyncPacketServiceTest.java`
(и тест маппера, если есть). Не менять: views, `PacketParserService`,
`DiadocLocalPacketService`. Общие ресурсы — схема `main_f_diadoc_check`,
Gradle daemon; код параллельно с T01/T05, прогон тестов первым в очереди.

## Реализация

1. Entity + changelog: `createTable` дополнить колонкой после
   `related_document`, отдельный changeSet `addColumn` с preConditions
   `not columnExists` (`jmix-create-liquibase-changelog`).
2. `LinkRow.supplementDocument` (`@SerializedName("supplementDocument")`),
   `LINK_COLUMNS` + `linkValues` — по образцу `related_document`;
   отсутствующее поле пишется как `null`.
3. DTO/маппер: поле `supplement` там же, где `related`; JSON-имя
   `is_supplement` в REST-DTO по образцу `is_related`.
4. Тесты: JSON-тест бандла с `supplementDocument=true` и без поля;
   `SyncPacketServiceTest` — upsert пишет колонку и обновляет её при
   повторном sync; unit на `DocumentDataSource.fromId("DOCID_ARR")`.

## Критерии приёмки

- C1: После миграций колонка `supplement_document` есть; повторный прогон
  идемпотентен; существующие replay-фикстуры (`PacketReplayIT`) вставляются
  без правок CSV.
- C2: Sync бандла с `supplementDocument=true` сохраняет `true`; бандл без
  поля — `null`, существующие линки не ломаются.
- C3: `DocumentItemDto.getSupplement()` и REST-JSON `is_supplement`
  проходят через маппер.
- C4: `getDataSource()` для линков с `DOCID_ARR` возвращает enum, а не `null`.

## Самопроверка исполнителя

`./gradlew :app:compileJava`, `spotlessApply`, `./gradlew :app:test --tests
"ru.fgk.ws.app.diadoc.service.SyncPacketBundleDtoJsonTest" --tests
"ru.fgk.ws.app.diadoc.service.SyncPacketServiceTest"`. Полный набор не нужен.

## Независимая проверка

Те же тесты плюс `--tests "ru.fgk.ws.app.it.PacketReplayIT"` и
`"ru.fgk.ws.app.diadoc.view.diadocpacket.DiadocPacketListViewTest"`
(регрессия зеркала и карточки). SQL: `\d main_f_diadoc_check.
diadoc_packet_doc_link` содержит колонку. Негатив: JSON бандла со старой
структурой (без поля) — sync проходит.

## Прогресс и продолжение

- [ ] Entity, changelog, messages
- [ ] Бандл и upsert
- [ ] DTO и маппер, `DOCID_ARR`
- [ ] Тесты
- [ ] Передать результат на независимую проверку.

Ближайший шаг: открыть `DiadocPacketDocLink.java` и changelog линка.
Препятствия: нет
