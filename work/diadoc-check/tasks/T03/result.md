# Результат T03

Таск: [task.md](task.md)
Итерация: 1
Обновлено: 2026-09-21

## Что реализовано

Локальное зеркало линков пакета знает признак документа-дополнения. В
`diadoc_packet_doc_link` появилась колонка `supplement_document BOOLEAN`
(nullable), entity — атрибут `DiadocPacketDocLink.supplementDocument`.
Признак проходит весь путь перекачки: `links[].supplementDocument` в бандле
`getPacketForSync` → `SyncPacketBundleDto.LinkRow` → `LINK_COLUMNS`/
`linkValues` upsert-а → колонка зеркала. Бандл источника без этого поля
(rvk-diadoc до T05) синхронизируется как раньше, колонка остаётся `null`.

Второй путь — DTO документа для REST-карточки: `DocumentItemRestDto.supplement`
читается из JSON-ключа `is_supplement` и переносится маппером в
`DocumentItemDto.supplement`.

`DocumentDataSource` получил значение `DOCID_ARR("DOCID_ARR")` — ровно ту
строку, которую пишет `PacketAssemblyService` в rvk-diadoc
(`DATA_SOURCE_DOCID_ARR`), поэтому `DiadocPacketDocLink.getDataSource()` для
таких линков больше не возвращает `null`.

Реализация завершена, блокеров нет.

## Изменения и решения

- `diadoc/entity/DiadocPacketDocLink.java` — `supplementDocument` после
  `relatedDocument`.
- `liquibase/changelog/01-tbl/tbl-diadoc_packet_doc_link.xml` — колонка в
  `createTable` (changeSet 1) и отдельный changeSet 9 `addColumn` с
  preConditions `not columnExists` для уже развёрнутых БД.
- `diadoc/entity/DocumentDataSource.java` — константа `DOCID_ARR`.
- `diadoc/service/SyncPacketBundleDto.java` — `LinkRow.supplementDocument`
  (`@SerializedName("supplementDocument")`) с геттером/сеттером.
- `diadoc/service/SyncPacketUpsertRepository.java` — `supplement_document` в
  `LINK_COLUMNS` и значение в `linkValues` (позиция совпадает).
- `diadoc/dto/DocumentItemDto.java`, `diadoc/dto/rest/DocumentItemRestDto.java`,
  `diadoc/mapper/PacketDocumentMapper.java` — поле `supplement` рядом с
  `related`.
- `messages_ru.properties` — `DiadocPacketDocLink.supplementDocument=Документ-дополнение`
  и `DocumentDataSource.DOCID_ARR=Перечень пакета`.
- Тесты: `SyncPacketBundleDtoJsonTest` (+2), `SyncPacketServiceTest` (+1),
  новые `diadoc/entity/DocumentDataSourceTest`, `diadoc/mapper/PacketDocumentMapperTest`.

Существенные локальные решения:

- Колонка nullable, без `defaultValueBoolean`: rvk-ws только зеркалит источник,
  а «поля нет в бандле» и «источник прислал false» различимы только через
  `null`. В rvk-diadoc по плану у колонки свой `default false` — это его
  сторона контракта.
- В `DocumentItemRestDto` имя ключа проставлено Gson-аннотацией
  `@SerializedName("is_supplement")`, а не `@JsonProperty`: ответ удалённого
  сервиса Jmix RestDS разбирает через `EntitySerialization` (Gson) —
  `RemoteServiceInvoker.getResultObject` → `entitySerialization.objectFromJson`.
  Jackson на этом пути не участвует.
- Ключ `DocumentDataSource.DOCID_ARR` в `messages_ru.properties` добавлен, хотя
  таск перечисляет только ключ линка: иначе новое значение enum показывалось бы
  в UI как имя константы. Подпись «Перечень пакета» — по смыслу `docid_arr`
  (документ объявлен в перечне пакета, собран из другого сообщения);
  существующие подписи этого enum такие же короткие («Ок», «Синх. док.»).
- Проверка колонки после повторного sync в тесте читается `JdbcTemplate`-ом:
  тесты идут в одной транзакции, и после второго JDBC-upsert-а кеш EclipseLink
  может вернуть прежний экземпляр линка.

## Предварительные проверки

| Команда или сценарий | Результат |
|---|---|
| `./gradlew :app:compileJava :app:compileTestJava` | успешно |
| `./gradlew spotlessApply` | успешно |
| `./gradlew :app:test --tests "…SyncPacketBundleDtoJsonTest" --tests "…SyncPacketServiceTest" --tests "…entity.DocumentDataSourceTest" --tests "…mapper.PacketDocumentMapperTest"` | 33 passing, 0 failing |
| SQL-сверка колонки в `main_f_diadoc_check` (после прогона миграций тестами) | `supplement_document boolean` есть в `diadoc_packet_doc_link` |
| Сверка значения `DOCID_ARR` с источником | `rvk-diadoc/.../PacketAssemblyService.java:32` — `DATA_SOURCE_DOCID_ARR = "DOCID_ARR"` |

Не запускалось, оставлено проверяющему: полный `./gradlew :app:test`,
`PacketReplayIT`, `DiadocPacketListViewTest`, `spotlessCheckAll`, повторный
прогон миграций на существующей схеме (идемпотентность changeSet 9), браузерный
проход. IDE-инспекция (`get_file_problems`) в этой сессии недоступна;
изменённый XML — только changelog, он реально накатился при прогоне тестов.

## Для независимой проверки

Окружение: `docker compose` в `docker/` поднят, схема `main_f_diadoc_check` на
`localhost:5432` (`root`/`root`),
`app/src/test/resources/application-test-local.properties` указывает на неё.
Приложение в этой сессии не поднималось; порт 8082 свободен.

```bash
./gradlew :app:compileJava
./gradlew spotlessCheckAll
./gradlew :app:test \
  --tests "ru.fgk.ws.app.diadoc.service.SyncPacketBundleDtoJsonTest" \
  --tests "ru.fgk.ws.app.diadoc.service.SyncPacketServiceTest" \
  --tests "ru.fgk.ws.app.diadoc.entity.DocumentDataSourceTest" \
  --tests "ru.fgk.ws.app.diadoc.mapper.PacketDocumentMapperTest" \
  --tests "ru.fgk.ws.app.it.PacketReplayIT" \
  --tests "ru.fgk.ws.app.diadoc.view.diadocpacket.DiadocPacketListViewTest"
```

SQL-сверка (C1):

```sql
select column_name, data_type, is_nullable
from information_schema.columns
where table_schema = 'main_f_diadoc_check'
  and table_name = 'diadoc_packet_doc_link'
order by ordinal_position;
```

Негатив (C2) закрыт тестами `linkSupplementDocumentStaysNullWhenSourceOmitsField`
(бандл старой структуры разбирается, признак `null`) и существующим
`syncWithoutDeletedFieldsOnLinksAndOperationsWorks`; повторный прогон
`SyncPacketServiceTest` заодно проверяет идемпотентность миграций — схема уже
содержит колонку, changeSet 9 должен уйти в `MARK_RAN` без ошибок.
Replay-фикстуры CSV не правились: `PacketReplayFixtures` сопоставляет колонки
файла с колонками таблицы и пропускает отсутствующие, новая колонка просто
остаётся `null`.

Общие ресурсы (раздел таска «Область и изоляция»): схема `main_f_diadoc_check`,
Gradle daemon — занимать по одному; во время этой сессии параллельно шли T01 и
T05 (код, без прогонов в том же окне).

## Ограничения и связанные изменения

- Замечено вне области таска: `DocumentItemRestDto.related` не имеет
  `@SerializedName("is_related")`, хотя серверный DTO rvk-diadoc отдаёт ключ
  именно так (`processing/dto/DocumentItemDto.java:54`). По пути RestDS это
  поле всегда приходит `null`. То же у `originMessageId`
  (`origin_message_id`) и `torDocumentId` (`tor_document_id`). Карточка пакета
  сейчас берёт признак связанного из зеркала (`DiadocPacketDocLink`), поэтому
  дефект ничего видимого не ломает; чинить его в T03 — менять поведение
  существующего пути вне поручения. Стоит учесть в T04.
- `./gradlew spotlessApply` форматирует весь проект: если параллельная сессия
  T01 держала в рабочем дереве неотформатированные файлы, они могли быть
  приведены к стилю этим прогоном. Поведение это не меняет.
