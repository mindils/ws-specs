# Результат T04

Таск: [task.md](task.md)
Итерация: 2
Обновлено: 2026-09-21

## Что реализовано

Карточка пакета Диадок больше не хранит состав документов в локальном
состоянии экрана. При открытии `DiadocPacketDetailView.setupView` вызывает
`DiadocProcessingSettingsService.resolveForPacket(packet)` и ставит галочку
«Показать связанные документы» в значение `showRelatedDocuments` контрагента
(умолчания, если контрагента нет), а видимость самой галочки определяет
specific-политика `DiadocSettingsEditEnabled` — переключать состав может
только администратор настроек Диадок. Отбор вынесен в статический
`DiadocPacketDetailView.filterDocuments(List, boolean)`: при снятой галочке
скрываются только связанные документы без признака дополнения
(`relatedDocument && !supplementDocument`), СЧФ-дополнение видно всегда. В
колонке `relatedIcon` дополнение помечается `vaadin:paperclip` с подсказкой
«Дополнение к ФПУ-26: <originalMessageId>», обычный связанный документ —
прежней `vaadin:link`.

На «Пакетах по ремонту деталей» и «Пакетах ВУ-23» добавлен фильтр «Результат
контроля» — `jpqlFilter` с `multiSelectComboBox` по `packCheckedCode`: четыре
значения `PackCheckedCodeEnum` с их обычными подписями плюс синтетическое
«Не проверялся» (`-1`), которое динамически подключает ветку `is null`, как
это сделано у `diadocStatusFilter`. На `pt-repair-packets` значение фильтра
сохраняется в `ViewSettings` рядом с остальными (ключ `packCheckedCodes`).

Кнопка «Текст ошибки» на ВУ-23 больше не сравнивает `Integer` с enum:
`enabledRule` включает её для `VIOLATION`, `WARNING` и `WARNING_ECP` при
непустом `packCheckedText`.

## Изменения и решения

- `diadoc/view/diadocpacket/DiadocPacketDetailView.java` — инъекция
  `DiadocProcessingSettingsService`, `applyShowRelatedSettings()` в
  `setupView()` до `loadDocumentItemsAsync()`, статический `filterDocuments`,
  renderer `relatedIcon` с ветками related/supplement.
- `diadoc/view/diadocpacket/diadoc-packet-detail-view.xml` — у
  `packetDocumentDc` вместо `fetchPlan="_base"` явный fetch plan с
  `contractor`. Причина найдена браузерным прогоном: ссылка `contractor`
  джойнится по `contractor_code → code`, а не по первичному ключу, и её
  ленивая подгрузка в EclipseLink уходит в
  `select e from nsi_DiadocContractor e where e.id = :entityId` со `String` в
  параметре `Long` — `IllegalArgumentException` и «Непредвиденная ошибка» при
  открытии карточки. С контрагентом в fetch plan карточка открывается, а
  контракт T01 (`resolveForPacket`) остаётся без изменений. Это же место
  касается T02 — см. «Ограничения».
- `pt/view/ptrepairpacket/PtRepairPacketListView.java` + XML — фильтр
  `packCheckedCodeFilter`, сохранение в `ViewSettings`; сериализация набора
  Integer вынесена в общие `serializeIntegers`/`parseIntegerSet` (их уже
  использовал фильтр статуса Диадок).
- `dr/view/drdiadocoperrepairpacket/DrDiadocOperRepairPacketVu23ListView.java`
  + XML — тот же фильтр (условие уходит в `JmixDataRepositoryContext` делегата
  `findAllByPacketDocumentType` и применяется) и исправленный `enabledRule`
  кнопки «Текст ошибки».
- `messages_ru.properties` — `diadoc.view.diadocpacket/supplementIcon.tooltip`,
  `packCheckedCodeFilter.label` и `packCheckedCode.notChecked` в блоках обоих
  списков. Дополнительно добавлен отсутствовавший ключ
  `dr.view.drdiadocoperrepairpacket/torId`: колонка «ID документа» на ВУ-23
  показывала сырой `msg://torId` (критерий C4, экран в области таска).
- Тесты: `diadoc/view/diadocpacket/DiadocPacketDocumentFilterTest` (unit на
  отбор состава), `pt/view/ptrepairpacket/PtRepairPacketListViewFilterTest` и
  `dr/view/drdiadocoperrepairpacket/DrDiadocOperRepairPacketVu23ListViewTest`
  (`BaseUiTest`: фильтр сужает строки, «Не проверялся» ловит `is null`,
  сброс возвращает строки; для ВУ-23 ещё и доступность кнопки «Текст ошибки»).

Локальное решение в UI-тестах: программная установка значения фильтра меняет
условие, но не перезагружает данные (`SingleFilterComponentBase.apply()`
срабатывает только на изменение от клиента), поэтому тесты после `setValue`
вызывают `filter.apply()`.

## Предварительные проверки

| Команда или сценарий | Результат |
|---|---|
| `./gradlew :app:compileJava` | BUILD SUCCESSFUL |
| `./gradlew spotlessApply`, `./gradlew spotlessCheckAll` | без замечаний |
| `./gradlew :app:test --tests "ru.fgk.ws.app.diadoc.view.*" --tests "ru.fgk.ws.app.pt.view.*" --tests "ru.fgk.ws.app.dr.view.*"` | 16 passing, 0 failing |
| Сверка `msg://` изменённых XML с `messages_ru.properties` скриптом | нерезолвящихся ключей не осталось (найденный `torId` добавлен) |
| Браузер (Playwright CLI, `bootRun` на 8082, вход `admin`/`admin`): `pt-repair-packets` — выпадающий список фильтра показывает «Норма/Нарушение/Предупреждение/Предупреждение ЭЦП/Не проверялся», выбор «Нарушение» перезагружает грид без ошибок | пройдено |
| Браузер: `dr-diadoc-oper-repair-packet-vu23s` — те же пять значений, выбор «Не проверялся» без ошибок сервера | пройдено |
| Браузер: карточка пакета `30a02e6d-9065-4176-bc5d-c05fe658bd34` (13 линков, 3 связанных, одному временно проставлен `supplement_document=true`) — галочка видна и отмечена при умолчании `true`; после выключения флага на экране «Настройки Диадок по умолчанию» карточка открывается с `13 → 11` строками (скрыты 2 связанных, дополнение осталось) и снятой галочкой; включение галочки возвращает 13 строк; у дополнения подсказка «Дополнение к ФПУ-26: 5fac2c79-…» | пройдено |

Не запускалось, оставлено проверяющему: полный `./gradlew :app:test`,
регрессии по остальным экранам, проверка под ролями `ws-user` и
`diadoc-settings-admin` (скрытие галочки у обычного пользователя), фильтр по
результату контроля на реальных данных с разными значениями
`packCheckedCode`, сохранение фильтра в `ViewSettings` между открытиями
экрана, показ текста ошибки в диалоге кнопки «Текст ошибки».

## Для независимой проверки

Окружение: Docker Compose поднят, схема `main_f_diadoc_check`
(`localhost:5432`, `root`/`root`), порт 8082 (`application-local.properties`
worktree). Порт, схема и Gradle daemon общие с T02 — занимать по очереди.

Команды:

```bash
./gradlew :app:test --tests "ru.fgk.ws.app.diadoc.view.*" \
                    --tests "ru.fgk.ws.app.pt.view.*" \
                    --tests "ru.fgk.ws.app.dr.view.*"
./gradlew :app:bootRun    # порт 8082, не завершается сам
```

Вход в браузер — `http://localhost:8082/local-login`. В схеме worktree есть
только пользователь `admin` (пароль `admin`, `{noop}` в `sso_user`); учётной
записи `user`/`user` из корневого CLAUDE.md здесь нет. Пользователей с ролями
`ws-user` и `diadoc-settings-admin` нужно завести самостоятельно (T01
заводил `user_plain_t01` и `admin_diadoc_t01` и удалял после проверки).

Данные для карточки: пакет `30a02e6d-9065-4176-bc5d-c05fe658bd34` имеет 13
линков, из них 3 со `related_document=true`; чтобы получить дополнение —
`update main_f_diadoc_check.diadoc_packet_doc_link set
supplement_document=true where id='1126585a-8a5b-4f0e-58f4-1d753065b909';`
(после проверки вернуть в `null`). Карточка открывается не по прямому URL, а
со списка «Пакеты документов Диадок»: у пакета `operations_first_at` —
январь 2026, поэтому нужен URL с расширенным фильтром
`http://localhost:8082/diadoc-packet?operationsFirstAtFrom=greater-or-equal_2026-01-01T00-00-00`,
далее фильтр «ИД сообщения», выбор строки и кнопка «Просмотр».

Значение `showRelatedDocuments` менять через экран «Настройки Диадок по
умолчанию» (`/diadoc/settings`), а не SQL-апдейтом: строка `diadoc_settings`
попадает в кеш EclipseLink, и правка мимо приложения не подхватывается.

Состояние БД после самопроверки восстановлено: `supplement_document` снят,
`diadoc_settings.show_related_documents=true`, тестовых пользователей не
заводилось.

## Итерация 2 — исправление F01

Карточка пакета больше не полагается на поле ввода для переключения состава:
чекбокс `showRelatedCheckbox` заменён кнопкой `showRelatedButton` в компактной
строке над гридом (`hbox` с `justifyContent="END"`, кнопка `small, tertiary`).
Состояние держит поле контроллера `boolean showRelated`, которое
`applyShowRelatedSettings()` инициализирует из
`resolveForPacket(packet).showRelatedDocuments()`; нажатие инвертирует поле,
перерисовывает грид и меняет подпись и иконку кнопки: при скрытых связанных —
«Показать связанные документы» + `VaadinIcon.LINK`, при показанных — «Скрыть
связанные документы» + `VaadinIcon.UNLINK`. Видимость кнопки по-прежнему
определяет `DiadocSettingsEditEnabled`. Настройку контрагента кнопка не пишет
(решение [Q02](../../questions/Q02.md)).

`refreshEditedEntity()` перезагружает пакет с fetch plan контейнера
(`packetDocumentDc.getFetchPlan()`), а не с планом по умолчанию, — item
контейнера теперь всегда соответствует плану, объявленному в XML.

### Воспроизведение F01.2

Причина подтверждена: под пользователем с ролями `ws-user` +
`diadoc-show-packet-documents` + `diadoc-settings-admin` (без
`system-full-access`) карточка открывается в режиме «только чтение» —
`vaadin-text-area` «Причина отклонения» приходит с `readonly=true`, а кнопки
«Принять»/«Отклонить» неактивны. Именно это блокировало прежний чекбокс:
`ReadOnlyViewsSupport` переводит в read-only все `HasValueAndElement` экрана.
Новая кнопка в том же режиме активна (`disabled=false`) и переключает состав.
Иной причины, кроме read-only, не нашлось.

### Изменённые файлы (итерация 2)

- `diadoc/view/diadocpacket/DiadocPacketDetailView.java` — поле `showRelated`,
  `showRelatedButton` вместо `showRelatedCheckbox`, `onShowRelatedButtonClick`,
  `updateShowRelatedButton()`, fetch plan в `refreshEditedEntity()`; убраны
  ставшие лишними импорты `AbstractField` и `JmixCheckbox`.
- `diadoc/view/diadocpacket/diadoc-packet-detail-view.xml` — `hbox`
  `showRelatedBox` с кнопкой вместо `checkbox`.
- `messages_ru.properties` — `showRelatedButton.show` /
  `showRelatedButton.hide` вместо `showRelatedCheckbox.label`.
- `DiadocPacketDocumentFilterTest` — формулировка комментария (тесты и
  проверяемый статический `filterDocuments(List, boolean)` не менялись).
- `security/diadoc/DiadocSettingsAdminRole.java` — только javadoc: роль
  открывает кнопку, а не галочку. Файл лежит вне области T04 («роли» отданы
  T01), но комментарий описывал удалённый элемент; поведение не затронуто.

### Проверки итерации 2

| Команда или сценарий | Результат |
|---|---|
| `./gradlew :app:compileJava`, `./gradlew spotlessApply`, `./gradlew spotlessCheckAll` | BUILD SUCCESSFUL, без замечаний |
| `./gradlew :app:test --tests "ru.fgk.ws.app.diadoc.view.*" --tests "ru.fgk.ws.app.it.DiadocProcessingSettingsIT"` | 19 passing, 1 pending (`contractorName_resolvesByInnKpp` с `@Disabled` из прошлых итераций), 0 failing |
| Сверка `msg://` изменённого XML с `messages_ru.properties`; атрибуты `hbox`/`button` — по `layout.xsd` из `jmix-flowui-3.0.0` | нерезолвящихся ключей и неизвестных атрибутов нет |
| `VaadinIcon.LINK` / `VaadinIcon.UNLINK` — по байткоду `vaadin-icons-flow` | константы существуют |
| Браузер, `admin`: карточка `30a02e6d-…` — кнопка «Скрыть связанные документы» (`vaadin:unlink`), грид 13 строк; клик → 10 строк и «Показать связанные документы» (`vaadin:link`); повторный клик → снова 13 | пройдено |
| Браузер, `t04_sadm` (`ws-user` + `diadoc-show-packet-documents` + `diadoc-settings-admin`): карточка read-only, кнопка видна и активна, 13 → 10 → 13 | пройдено |
| Браузер, `t04_plain` (без `diadoc-settings-admin`): кнопки нет; при `showRelatedDocuments=false` в умолчаниях — 10 строк, при `true` — 13 | пройдено |
| Снимок кнопки над гридом | [fix-f01-show-related-button.png](fix-f01-show-related-button.png) |

Состояние окружения восстановлено: `diadoc_settings.show_related_documents`
возвращён в `true` через экран «Настройки Диадок по умолчанию», пользователи
`t04_sadm` и `t04_plain` с назначениями ролей удалены, `bootRun` остановлен,
порт 8082 свободен.

### Для независимой проверки (итерация 2)

Карточка открывается и прямым URL
`http://localhost:8082/diadoc-packet/30a02e6d-9065-4176-bc5d-c05fe658bd34`
(`@Route("diadoc-packet/:id")`) — через список идти не обязательно. Уход с
открытой карточки браузер сопровождает подтверждением
(`beforeunload`), его надо принять.

Пользователи для ролевых сценариев (после проверки удалить):

```sql
set search_path to main_f_diadoc_check;
insert into sso_user (id, version, username, password, active)
values (gen_random_uuid(), 1, 't04_sadm', '{noop}t04', true),
       (gen_random_uuid(), 1, 't04_plain', '{noop}t04', true);
insert into sec_role_assignment (id, username, role_code, role_type)
values (gen_random_uuid(), 't04_sadm', 'ui-minimal', 'resource'),
       (gen_random_uuid(), 't04_sadm', 'ws-user', 'resource'),
       (gen_random_uuid(), 't04_sadm', 'diadoc-show-packet-documents', 'resource'),
       (gen_random_uuid(), 't04_sadm', 'diadoc-settings-admin', 'resource'),
       (gen_random_uuid(), 't04_plain', 'ui-minimal', 'resource'),
       (gen_random_uuid(), 't04_plain', 'ws-user', 'resource'),
       (gen_random_uuid(), 't04_plain', 'diadoc-show-packet-documents', 'resource');
```

Роль `diadoc-show-packet-documents` обязательна: без неё карточка закрыта, а
UPDATE на `DiadocPacket` она не даёт — именно этот набор и воспроизводит
read-only режим.

### Что оставлено проверяющему (итерация 2)

- Успешный путь кнопки «Обработать повторно». Приложение `rvk-diadoc` на
  `localhost:8081` не поднято, и нажатие завершается «Ошибка обработки:
  Cannot access 'rvkdiadoc' REST API» — то есть до `refreshEditedEntity()`
  дело не доходит. Прежнего текста про `parameter entityId` больше нет ни в
  одном сценарии: `resolveForPacket` вообще не обращается к ссылке
  `contractor` после [T01/F01](../../T01/fixes/F01.md). Порт 8081 и
  `rvk-diadoc` не входят в общие ресурсы T04, изоляции для них план не задаёт,
  поэтому сессия их не занимала — проверку успешного пути нужно сделать при
  поднятом `rvk-diadoc`.
- Показ СЧФ-дополнения со скрепкой: флаг `supplement_document` в схеме сейчас
  не проставлен ни у одной связи, ветка renderer-а этим исправлением не
  менялась и проверялась в итерации 1.
- Полный `./gradlew :app:test`, фильтры по результату контроля и кнопка «Текст
  ошибки» на ВУ-23 — как и в итерации 1.

## Ограничения и связанные изменения

- `DiadocProcessingSettingsService.resolveForPacket(packet)` работает только
  на пакете, загруженном вместе с `contractor`: сама ссылка не поддерживает
  ленивую подгрузку (джойн по неключевой колонке). В T04 это закрыто fetch
  plan-ом карточки, но тот же вызов есть в T02 (`process`) — стоит проверить,
  что пакет туда приходит с загруженным контрагентом, иначе обработка упадёт
  на том же исключении. Сервис T01 не менялся: правка его контракта — за
  пределами области T04.
- Под ролью `ws-user` скрытие галочки в браузере не проверялось (нет такого
  пользователя в схеме) — проверено только, что видимость управляется
  `DiadocSettingsEditEnabled`, а `admin` с полным доступом её видит.
- В XML у `showRelatedCheckbox` остался атрибут `value="true"`; фактическое
  значение всегда перезаписывается в `setupView`, атрибут влияет только на
  момент до первого показа.
