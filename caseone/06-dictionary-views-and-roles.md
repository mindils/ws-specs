# 06. Экраны справочников, роль на чтение, локализация

> **Этап 2.** Экран настроек и тестовый экран сделаны в задачах 01–02 — здесь только
> экраны справочников и журнала.

## Экраны

Все — в `ru/fgk/ws/app/legal/caseone/view/...`, пара «XML-дескриптор + Java-контроллер»,
`@ViewController` + `@ViewDescriptor`, `layout = MainView.class`.

| Экран | ID | Тип |
|---|---|---|
| Контрагенты | `legal_CaseOneParticipant.list` / `.detail` | list + detail |
| Пользователи | `legal_CaseOneUser.list` / `.detail` | list + detail |
| Папки | `legal_CaseOneFolder.list` / `.detail` | list + detail |
| Журнал синхронизации | `legal_CaseOneSyncLog.list` / `.detail` | list + detail |

### Правила для list-view

- **`propertyFilter`, не `genericFilter`** — `genericFilter` запрещён в новом коде
  (`CLAUDE.md` §5). В legacy-экранах он есть, ориентироваться на них в этой части нельзя.
- `simplePagination` + `readOnly="true"` у лоадера.
- Никаких `create` / `edit` / `remove` — зеркала редактировать нельзя, данные приходят из
  Case.one. Только `read` (detail открывается в режиме просмотра) и экспорт, если нужен.
- Полезные колонки по умолчанию:
  - контрагенты: `name`, `participantType`, `inn`, `kpp`, `email`, `phone`,
    `sourceLastChangeDate`, `isMissing`;
  - пользователи: `name`, `email`, `externalId`, `workingStatusName`, `isClient`, `isLocked`,
    `sourceLastChangeDate`, `isMissing`;
  - папки: `name`, `objectClassName`, `objectClassSection`, `hasChildren`,
    `sourceLastChangeDate`, `isMissing`;
  - журнал: `dictionary`, `startedAt`, `finishedAt`, `status`, `itemsRead`, `created`, `updated`,
    `unchanged`, `markedMissing`, `triggeredBy`.
- Фильтр «показывать исчезнувшие» — `propertyFilter` по `isMissing` с дефолтом `false`,
  чтобы в обычном режиме мусор не мешал.
- Журнал синхронизации — сортировка по `startedAt desc`.

### Кнопка «Синхронизировать сейчас»

На list-view контрагентов, пользователей и папок. Запускает `CaseOneSyncService` с
`triggeredBy = UI` через `BackgroundJobService`
(`app/src/main/java/ru/fgk/ws/app/common/job/`) — прогон по контрагентам идёт минутами,
блокировать UI нельзя. По завершении — `Notification` со счётчиками и перезагрузка контейнера.

Кнопка видна только по роли `legal-caseone-admin`.

### Fetch plans

Зеркала плоские, связей нет → достаточно `_base`. Специально ничего не донастраивать,
но не забыть `readOnly="true"` у лоадеров.

## Роли

`app/src/main/java/ru/fgk/ws/app/legal/security/`, по образцу
`app/src/main/java/ru/fgk/ws/app/security/DrContractReadRole.java`.

### `LegalCaseOneAdminRole` — код `legal-caseone-admin` (дополняется)

Роль заведена в задачах 01–02 (настройки + тестовый экран). Здесь к ней **дописываются**:

- `@MenuPolicy` + `@ViewPolicy` на экраны справочников и журнала;
- `@EntityPolicy` READ на три зеркала и журнал.

Атрибут `passwordEnc` по-прежнему доступен только этой роли.

### `LegalCaseOneReadRole` — код `legal-caseone-read`

- `@MenuPolicy` + `@ViewPolicy` на экраны справочников и журнала (без настроек);
- `@EntityPolicy(READ)` + `@EntityAttributePolicy(VIEW)` на `CaseOneParticipant`, `CaseOneUser`,
  `CaseOneFolder`, `CaseOneSyncLog`;
- на `CaseOneSettings` прав нет вообще.

`scope = "UI"` — как у остальных ролей проекта.

## i18n

Всё — в `app/src/main/resources/ru/fgk/ws/app/messages_ru.properties` (в модуле `app` других
locale-файлов нет). Хардкод-строк в UI быть не должно.

Что покрыть:
- пункты меню: `ru.fgk.ws.app.legal/menu.legal`, `ru.fgk.ws.app.legal/menu.caseone`;
- заголовки всех экранов;
- названия сущностей и **всех** атрибутов
  (`ru.fgk.ws.app.legal.caseone.entity/CaseOneParticipant.inn=ИНН` и т. д.);
- значения enum-ов `CaseOneDictionary`, `CaseOneSyncStatus`, `CaseOneParticipantType`,
  `CaseOneSyncTrigger`;
- подписи кнопок: «Сохранить», «Проверить подключение», «Синхронизировать сейчас»;
- тексты уведомлений: «Подключение установлено», «Не удалось подключиться: {0}»,
  «Синхронизация завершена: создано {0}, обновлено {1}, без изменений {2}»,
  «Синхронизация уже выполняется».

## Меню

Дописать четыре пункта в блок `legal_caseone` в `app/src/main/resources/ru/fgk/ws/app/menu.xml`
(контейнеры и первые два пункта заведены в задачах 01–02).

## Проверка

- `./gradlew :app:bootRun` → под ролью `legal-caseone-read` виден раздел со справочниками,
  но **не** виден пункт «Настройки»; под `legal-caseone-admin` виден весь раздел.
- В XML-дескрипторах нет `<genericFilter>`: `grep -rn "genericFilter" app/src/main/resources/ru/fgk/ws/app/legal/`
  ничего не находит.
- Нет хардкод-строк: все `title`/`text` в новых XML начинаются с `msg://`.
