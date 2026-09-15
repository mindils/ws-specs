# T09 — История на Jmix EntityLog

Статус: done
План: [plan.md](../../plan.md)
Зависимости: [T01](../T01/task.md)
Сложность: medium — стандартный аддон Jmix, но в проекте не использовался;
нужен фрагмент и seed конфигурации.
Сложность проверки: medium — интеграционные тесты журнала и ручная проверка
фрагмента в браузере.
Актуальная проверка: [checks/001.md](checks/001.md)

## Коротко

Включаем журнал изменений Jmix Audit (EntityLog) для всех контейнерных entity
и делаем переиспользуемый фрагмент «История записи». Карточка контейнера
(T03) и другие формы покажут во вкладке «История», кто, когда и какие атрибуты
менял. Собственная таблица снимков не создаётся — решение пользователя.

## Результат и контекст

В проекте подключены `io.jmix.audit:jmix-audit-starter` и
`jmix-audit-flowui-starter`, таблицы `audit_entity_log`, `audit_logged_entity`,
`audit_logged_attr` создаются changelog-ом аддона, но ни одна entity не
настроена и экран `entityLog.view` в меню не выведен. Контракт — раздел
«История (EntityLog)» в [contracts.md](../../contracts.md).

## Область и изоляция

Меняет: `container/view/fragment/entitylog/` (Java + XML),
`liquibase/changelog/04-data/cnt_entity_log.xml`, `menu.xml` (пункт
`entityLog.view` в `other_menu`), при необходимости `application.properties`
(`jmix.audit.*`), messages, тесты. Политики READ на `audit_EntityLog` и
`audit_EntityLogAttr` добавляются в `ContainerReadRole` (если T02 ещё не done —
записать требование в contracts.md, раздел «Роли», T02 применит).

Общие ресурсы: БД. Параллельно с T02, T10. Проверки после T02.

## Реализация

- Skills: `jmix-create-fragment`, `jmix-create-liquibase-changelog`,
  `jmix-verify-api-symbol`, `jmix-configure-fetch-plan`, `jmix-add-i18n-keys`,
  `jmix-create-test`.
- Проверить по документации Jmix Audit (Context7 или jar
  `io.jmix.audit:jmix-audit:3.0.1`): entity `LoggedEntity` (`name`, `auto`,
  `manual`, `attributes`), `LoggedAttribute` (`entity`, `name`),
  `EntityLogItem` (`entity`, `entityRef.longEntityId`, `eventTs`, `username`,
  `type` CREATE/MODIFY/DELETE/RESTORE, `attributes`), `EntityLogAttr` (`name`,
  `value`, `oldValue`), свойство `jmix.audit.enabled`, кэш `EntityLog.invalidateCache()`.
- Seed конфигурации: changeSet-ы с preConditions «нет `audit_logged_entity`
  с таким `name`», INSERT для каждой `cnt_*` entity (`auto` = true, `manual`
  = true) и всех её атрибутов (кроме технических id/version/аудита, если
  документация рекомендует). Проверить формат id таблиц аддона (UUID).
- Фрагмент `EntityLogFragment`: свойства `entityName`, `entityId`; loader по
  `audit_EntityLog` с параметрами; грид дата/пользователь/тип; ниже грид
  атрибутов выбранной записи. Все подписи через `msg://`.
- Пункт `entityLog.view` в `other_menu` рядом с Entity Inspector.

## Критерии приёмки

- C1: После создания, изменения и soft delete контейнера через `DataManager`
  в `audit_entity_log` появляются три записи типов CREATE, MODIFY, DELETE с
  атрибутами (в MODIFY — старое и новое значение изменённого поля).
- C2: То же для одного справочника и одного ремонта (все `cnt_*` настроены).
- C3: Фрагмент по `entityName` и `entityId` показывает записи только этого
  экземпляра, новее сверху, с атрибутами выбранной записи.
- C4: Изменение подписи справочника после записи журнала не меняет старые
  записи.
- C5: Повторное применение миграций не дублирует `audit_logged_entity`.

## Самопроверка исполнителя

`compileJava`; интеграционный тест C1–C2 (`BaseIT`, очистка созданных данных и
записей журнала в `@AfterEach`); фрагмент проверить встраиванием в любой
существующий тестовый view или UI-тестом открытия. Полный `:app:test` не
запускать.

## Независимая проверка

Гейты по plan.md, `./gradlew :app:test`. Через SQL убедиться в настройке всех
22 entity в `audit_logged_entity`. В браузере открыть `entityLog.view` под
администратором и увидеть записи по `cnt_Container`. Если T03 уже done —
проверить вкладку «История» карточки; иначе зафиксировать проверку фрагмента
через тестовый хост.

## Прогресс и продолжение

- [x] Проверить API аддона и наличие таблиц.
- [x] Seed конфигурации и свойство (`jmix.audit.enabled` уже `true` по
  умолчанию, `application.properties` не менялся).
- [x] Фрагмент, меню, тесты.
- [x] Передать результат на независимую проверку.
- [x] Независимая проверка пройдена успешно ([checks/001.md](checks/001.md)).

Реализация завершена, см. [result.md](result.md). Состав журналируемых атрибутов
уточнён в [contracts.md](../../contracts.md): хранимые несистемные атрибуты;
вычисляемые `@JmixProperty`-подписи не журналируются.

Ближайший шаг: выполнение зависимого таска T03 ([tasks/T03/task.md](../T03/task.md))
или параллельного T10 ([tasks/T10/task.md](../T10/task.md)) исполнителем `task-execute`.
Препятствия: нет.
