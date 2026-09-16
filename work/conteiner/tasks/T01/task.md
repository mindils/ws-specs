# T01 — Модель, миграции, инварианты

Статус: done — итерация 2 принята проверкой [checks/002.md](checks/002.md)
План: [plan.md](../../plan.md)
Зависимости: нет
Сложность: medium — 22 entity по образцам проекта, но новый домен, listener
нормализации и проверка DENY с soft delete.
Сложность проверки: medium — интеграционные тесты с живой БД, без UI.
Актуальная проверка: [checks/002.md](checks/002.md)

## Коротко

Создаём persistence-основу контейнерного раздела: 9 основных и 13 справочных
entity, changelog-и таблиц, soft delete, запреты удаления при ссылках,
нормализацию и уникальность номера контейнера, утилиту копирования. Экранов в
этом таске нет; результат виден через `DataManager` и интеграционные тесты.

## Результат и контекст

Контейнерных таблиц в РВК нет. Состав полей — раздел «Матрица модели» в
[contracts.md](../../contracts.md), старый DDL — [issue.md](../../input/issue.md).
Решения: `Long id` IDENTITY, `@Version`, аудит, soft delete, FK только как
`@DdlGeneration`, обязательность только в UI (в БД NOT NULL лишь `cont_num`,
ссылки на контейнер в дочерних таблицах и обе ссылки `cnt_act_container`).
Операции, накладные и история снимков не создаются.

Рабочая копия содержит изменения других задач (`application.properties`,
changelog `020-dr_diadoc_wag_oper_repair_contract.xml`): не включать и не
откатывать.

## Область и изоляция

Меняет: `app/src/main/java/ru/fgk/ws/app/container/{entity,listener,service}`,
`app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/01-tbl/tbl-cnt_*.xml`,
entity-ключи в `app/src/main/resources/ru/fgk/ws/app/messages_ru.properties`,
тесты в `app/src/test/java/ru/fgk/ws/app/container/` или `it/`. Не трогать
`migration/ws_store`, существующие НСИ-entity, чужие changelog-и — с
единственным именованным исключением по [Q03](../../questions/Q03.md):
`app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/01-tbl/tbl-pt_repair_packet.xml`.

Общие ресурсы: PostgreSQL (схема worktree), gradle daemon. Первый таск — других
параллельных нет.

## Реализация

- Skills: `jmix-create-entity`, `jmix-create-liquibase-changelog`,
  `jmix-add-entity-event-listener`, `jmix-add-i18n-keys`, `jmix-create-test`,
  `jmix-verify-api-symbol`, `jmix-ide-static-analysis`.
- Образцы: `nsi/entity/NsiWsRepairDepo.java` (аудит),
  `diadoc/entity/DiadocPacket.java` (soft delete),
  `da/entity/DaContractAgentCopiesDocument.java` (FileRef, `@DdlGeneration`,
  `@Index`), changelog `01-tbl/110-da_contract_agent_copies_document.xml`.
- Все правила именования, аннотаций, индексов и типов — по разделу «Единые
  правила модели» contracts.md. Отклонения фактических имён записать в матрицу.
- `@OnDeleteInverse(DeletePolicy.DENY)` на ссылках на контейнер, справочники,
  договор, гарантию, вид акта. Проверить по документации Jmix, что DENY при
  soft delete учитывает только неудалённые ссылающиеся записи; результат
  проверки и принятое решение записать в contracts.md (раздел «Единые правила
  модели»). Если удалённые дети продолжают блокировать — добавить сервисную
  проверку и снять DENY там, где он мешает.
- Listener `EntitySavingEvent` для `Container`: trim + верхний регистр номера;
  пустой номер после trim — ошибка валидации. Уникальный индекс в changelog.
- `container/service/EntityCopySupport` по описанию contracts.md.
- Типы PK ссылок: `VOrgPassport.id` — `Long`, `VStation.id` — `Integer`;
  проверить перед объявлением `@JoinColumn`.
- Messages: подписи entity и всех атрибутов на русском (полностью
  квалифицированные ключи в `messages_ru.properties`).
- Все созданные файлы проверить на непустоту.
- Итерация 2 ([Q03](../../questions/Q03.md)): в
  `01-tbl/tbl-pt_repair_packet.xml` добавить `PACK_CHECKED_CODE` типа `INT` с
  remarks из changeSet `16` в основной `createTable` (changeSet `1`) и
  отдельный `addColumn` со следующим свободным id в конце файла, с
  `preConditions onFail="MARK_RAN"` →
  `<not><columnExists tableName="pt_repair_packet" columnName="pack_checked_code"/></not>`.
  ChangeSet `17` не удалять: на старых базах он всё ещё переименовывает
  `status`. Перед проверкой снять ручную колонку из схемы worktree
  (`alter table <схема>.pt_repair_packet drop column pack_checked_code`) или
  развернуть новую пустую схему — иначе правка не проверена.

## Критерии приёмки

- C1: Все таблицы и поля матрицы созданы; миграции проходят на чистой схеме и
  повторно (идемпотентно); в модели нет старых технических полей.
- C2: Создание/изменение/удаление через `DataManager` каждой основной entity и
  одного справочника работает; после `remove` запись имеет `deleted_date`, не
  возвращается загрузкой, а строка остаётся в таблице.
- C3: Номер ` fgku1234567 ` сохраняется как `FGKU1234567` при сохранении через
  `DataManager`; второй контейнер с тем же номером отклоняется; удалённый
  контейнер тоже блокирует повтор номера.
- C4: Удаление контейнера с действующей характеристикой/ремонтом/связью акта
  отклоняется; после удаления дочерних записей — проходит. Аналогично для
  справочника, договора и гарантии, на которые ссылаются.
- C5: `EntityCopySupport` даёт новую entity без id/version/аудита/FileRef/
  номера, с остальными атрибутами и ссылками.
- C6: Ссылка на `VStation`/`VOrgPassport` сохраняется и читается с fetch plan
  `_instance_name`.

## Самопроверка исполнителя

`./gradlew :app:compileJava`; новые интеграционные тесты класса(ов) из этого
таска (`./gradlew :app:test --tests "ru.fgk.ws.app.container.*"` — фактические
имена записать в result.md); один smoke: миграции применяются на схеме worktree
при старте тестов. Полный `:app:test` не запускать.

## Независимая проверка

Инфраструктура по plan.md, затем `./gradlew :app:compileJava`, целевые тесты
из result.md, `./gradlew :app:test`. Через SQL осмотреть схему: наличие
таблиц, индексов, unique-индексов, отсутствие FK. Повторить C3–C4 отдельным
сценарием, включая удалённый контейнер и повтор номера. Проверить messages: у
каждого атрибута есть русская подпись (нет сырых ключей в Entity Inspector).

Итерация 2 — только миграционная часть (C1): развернуть **пустую** схему с
нуля, убедиться, что контекст поднимается и `jmix_Liquibase` не падает, что
`pack_checked_code` есть в `pt_repair_packet`, что повторный прогон
идемпотентен, а на схеме `main` changeSet `1` и новый `addColumn` получили
MARK_RAN; плюс `./gradlew :app:test`. Критерии C2–C6 подтверждены отчётом
[checks/001.md](checks/001.md) на неизменившемся коде entity, listener и
messages и не переигрываются, если правка не выходит за пределы
`tbl-pt_repair_packet.xml`.

## Прогресс и продолжение

- [x] Сверить матрицу с проектом, проверить типы PK НСИ и DENY при soft delete.
      `VOrgPassport.id` — `Long`, `VStation.id` — `Integer`. DENY считает
      ссылающиеся записи обычным JPQL, а soft-deletable entity получает критерий
      `deletedDate is null`, поэтому удалённые дети не блокируют родителя —
      сервисная проверка не нужна. Записано в contracts.md.
- [x] Entity (22), changelog-и (22), messages (319 ключей).
- [x] Listener номера, `EntityCopySupport`, тесты (13 зелёных, прогон повторён).
- [x] Независимая проверка итерации 1 — [checks/001.md](checks/001.md) (pass).
- [x] Итерация 2: правка `tbl-pt_repair_packet.xml` по
      [Q03](../../questions/Q03.md) — `PACK_CHECKED_CODE INT` с remarks в
      `createTable` changeSet `1` и новый changeSet `23` (author `dr`) с
      `addColumn` и preConditions; changeSet `17` не тронут.
- [x] Проверено на пустой схеме `main_t01i2` (контекст поднимается, колонка
      приходит из `createTable`, changeSet `23` MARK_RAN, повторный прогон
      идемпотентен) и на `main_rvk_ws` после снятия ручной колонки (changeSet
      `1` RERAN, changeSet `23` EXECUTED). Временная схема удалена, значения
      тестовых строк восстановлены.
- [x] Независимая проверка итерации 2 — [checks/002.md](checks/002.md) (pass).
      Таск закрыт.

Ближайший шаг: выполнение `task-close` для закрытия всей работы и подготовки summary.md.
Препятствия: нет.
