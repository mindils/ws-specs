# F01. Аудит готовности rvk-filter

[К плану](README.md)

Дата: 2026-09-05. Снимки: `rvk-ws` — `9b0a52b3b`, `rvk-filter` — `54bf5d7`.
Проверка и спецификации выполнены; перечисленные исправления **ещё не реализованы**.

## Вывод

Аддон уже имеет работающую основу: конфигурация полей из XML/Java, поиск, диапазоны дат/чисел, enum-опции, draft/applied state, сборка Jmix Condition, личные/общие пресеты, сервисные проверки владельца, четыре PostgreSQL changeset и ресурсы frontend в JAR. Production-код не импортирует классы `rvk-ws`/`rvk-diadoc`.

Пилот допустим после задач F02, F04–F08 в объёме пилотных страниц и PostgreSQL/security/UI-проверок F11. Массовое внедрение сейчас преждевременно: отсутствуют необходимые типы условий, полный CRUD пресетов и безопасное сосуществование со старым фильтром.

## Методика и фактически выполненные проверки

| Проверка | Результат | Предел доказательства |
|---|---|---|
| `./gradlew --no-daemon clean test :rvk-filter:jar` в аддоне | BUILD SUCCESSFUL; 226 test cases, 224 прошли, 2 skipped | Контекст и тесты используют HSQLDB; PostgreSQL и браузер не покрыты |
| PostgreSQL-тесты уникальности имён | Два метода помечены `@Disabled` | Нельзя считать ограничения проверенными по зелёному test |
| `node --check` всех production JS | Все 7 файлов прошли | Не проверяет импорт Lit, события и отображение в браузере |
| XML parsing | Оба changelog, XSD и два example XML well-formed | Это не XSD-валидация и не открытие view |
| Java SchemaFactory для XSD | `src-resolve.4.2`, строка 72: `layout:baseComponent`, нет import namespace | Самостоятельная XSD-валидация не работает; Jmix использует свой loader, отказ view этим не установлен |
| JAR | 7 JS, `rvk-filter.xsd`, 2 Liquibase XML упакованы | Production frontend build приложения ещё не проверен |
| IDE MCP | Открыт только `/home/mindils/data/dev/edu/jmix-test-mcp`; запрос для rvk-filter отклонён | **IDE semantic inspection not verified** |
| Браузер приложения с аддоном | Не выполнялся, зависимость в app ещё не подключена | **render not browser-verified** |
| Локальная PostgreSQL | Docker PostgreSQL 16.11 запущен; SELECT системных каталогов | Проверена только локальная БД, не production |

Повторять сборку только для изменённого кода/новых вопросов; создание этих Markdown/JSON не является изменением приложения и не требует приписывать ему пройденный `:app:test`.

**Перепроверка 2026-09-05** (независимый повтор тех же команд, а не пересказ строк выше): сборка аддона снова BUILD SUCCESSFUL — 226 тестов, 224 прошли, 2 skipped по XML-отчётам `build/test-results`; в JAR те же 7 JS, `rvk-filter.xsd` и 2 changelog; `node --check` — 7/7; в контейнере `docker-rvk-db-1` (PostgreSQL 16.11) `rvk_filter_config` по-прежнему отсутствует, `main.flowui_filter_configuration` существует с перечисленными ниже колонками и 0 строк; `build-inventory.py` воспроизводит `page-inventory.json` и F09/F10 побайтово; строчные ссылки находок A01–A20 совпадают с текущими файлами аддона и приложения. Проверены и версии: приложение — Jmix plugin 3.0.0 / BOM 3.0.1, аддон — BOM 3.0.0, обе линии на Vaadin 25.1.x и Lit 3, тема приложения — `jmix-lumo` (231 использование `--lumo-*`, `--aura-*` не используется).

## Находки

P0 — блокирует первый production-пилот. P1 — блокирует соответствующие страницы очереди. P2 — улучшение универсальности/сопровождения. «По коду» означает подтверждённую ветку реализации, но не браузерный воспроизводящий тест.

| ID | Приоритет / подтверждение | Факт и последствие | Задача / источник |
|---|---|---|---|
| A01 | P0, по коду | `doReset()` записывает defaultState в draft/applied, но ставит загрузчику только baseCondition. Непустой default в панели не соответствует выборке | F04; [RvkFilter.java](../../../rvk-filter/rvk-filter/src/main/java/ru/fgk/component/rvkfilter/RvkFilter.java), строки 665–674 |
| A02 | P0, по коду | `handleSaveRequested()` всегда передаёт `id=null`. Обновление существующего пресета из стандартной панели недоступно, хотя сервис его поддерживает | F05; тот же файл, 1264–1281 |
| A03 | P0, по коду | UI показывает действие default для общего пресета менеджеру, а `handleMakeDefaultRequested()` всегда вызывает `setDefaultForMe()`, запрещающий общие пресеты | F05; RvkFilter.java:1311 и [сервис](../../../rvk-filter/rvk-filter/src/main/java/ru/fgk/component/rvkfilter/service/RvkFilterConfigServiceImpl.java) |
| A04 | P0, по коду и документации Jmix | Row-level роль содержит только JPQL policy чтения; resource role даёт ALL/MODIFY. Сервис защищён, но защита прямых CREATE/UPDATE/DELETE через DataManager не реализована | F05; [row-level роль](../../../rvk-filter/rvk-filter/src/main/java/ru/fgk/component/rvkfilter/security/RvkFilterConfigRowLevelRole.java), [user role](../../../rvk-filter/rvk-filter/src/main/java/ru/fgk/component/rvkfilter/security/RvkFilterUserRole.java). Эксплуатационный тест обхода не запускался |
| A05 | P0, по коду | `schemaVersion` передаётся в DTO, но `parseState()` получает только payload. Некорректный JSON превращается в empty, неизвестные поля отбрасываются молча | F05/F06; [FilterState.java](../../../rvk-filter/rvk-filter/src/main/java/ru/fgk/component/rvkfilter/model/FilterState.java) и RvkFilter.java:1140,1474 |
| A06 | P0, по коду | Нет `@Version`, нет уникального ограничения default на component/owner. Сброс предыдущих defaults обычной выборкой не защищает две одновременные транзакции | F06; [entity](../../../rvk-filter/rvk-filter/src/main/java/ru/fgk/component/rvkfilter/entity/RvkFilterConfig.java), сервис |
| A07 | P0, по коду | Неверный автоматический default логируется, но пользователь может видеть выбранный пресет без применённых условий | F04/F07; RvkFilter.java:1140–1194 |
| A08 | P0, по коду | `_handleApply()` объявляет успех сразу после отправки события; сервер ещё может отклонить значение/загрузку | F07; [rvk-filter.js](../../../rvk-filter/rvk-filter/src/main/resources/META-INF/frontend/src/component/rvk-filter/rvk-filter.js), 318–325 |
| A09 | P0 для переключения, по коду | baseCondition захватывается при `setDataLoader`; публичного безопасного suspend/resume и управления вкладом нескольких фильтров нет. Скрытая старая панель продолжит менять loader/PreLoad | F04/F08; RvkFilter.java:494,609 и контроллеры в реестре |
| A10 | P1, подтверждено исходниками | Конечный property path с range.class отвергается. Нет entity/user picker и динамического источника options | F03; [RvkFilterConfigurer.java](../../../rvk-filter/rvk-filter/src/main/java/ru/fgk/component/rvkfilter/RvkFilterConfigurer.java) |
| A11 | P1, подтверждено исходниками | JPQL: BOOLEAN только включает where при true, TEXT/SINGLE_SELECT передают String, NUMBER — BigDecimal. Date, enum, UUID/entity id, IN-list нужны страницам и не типизируются | F03; [FilterConditionBuilder.java](../../../rvk-filter/rvk-filter/src/main/java/ru/fgk/component/rvkfilter/condition/FilterConditionBuilder.java) |
| A12 | P1, подтверждено исходниками | Property TEXT всегда CONTAINS; нет полного набора операторов и дерева пользовательских AND/OR. GenericFilter на 21 странице шире нового каталога | F03; тот же builder, [модель полей](../../../rvk-filter/rvk-filter/src/main/java/ru/fgk/component/rvkfilter/model/FilterFieldDefinition.java) |
| A13 | P1, подтверждено исходниками | defaultValue из XML строится как строковый JSON-узел; число ожидает объект с operator/value, диапазон — mode/from/to, multiSelect — массив | F02/F04; RvkFilter.java:1203 и [FilterValue.java](../../../rvk-filter/rvk-filter/src/main/java/ru/fgk/component/rvkfilter/model/FilterValue.java) |
| A14 | P1, по коду | XML Boolean.parseBoolean молча превращает опечатку в false и не соответствует xs:boolean для `1`; неизвестные атрибуты/лишние элементы частично игнорируются. Integer.parseInt выдаёт нетематическую ошибку | F02; [RvkFilterXmlSupport.java](../../../rvk-filter/rvk-filter/src/main/java/ru/fgk/component/rvkfilter/xml/RvkFilterXmlSupport.java), [loader](../../../rvk-filter/rvk-filter/src/main/java/ru/fgk/component/rvkfilter/xml/RvkFilterLoader.java) |
| A15 | P1, стандартный валидатор | XSD ссылается на внешний layout namespace без import; StudioUiKit/StudioComponent metadata в production-коде не найдены. `full-view.xml` не объявляет itemsDl | F02; [XSD](../../../rvk-filter/rvk-filter/src/main/resources/rvk-filter.xsd), [пример](../../../rvk-filter/docs/examples/full-view.xml). Документационный пример Jmix тоже использует сокращённую схему: не выдавать это за доказанный runtime-дефект |
| A16 | P1, по коду | UNIQUE-ошибка PostgreSQL не покрыта catch SecurityException/IllegalArgumentException/UnsupportedOperationException в UI; длинные имена не валидируются до БД | F05/F06; сервис и RvkFilter.java:1280 |
| A17 | P1, по коду приложения | REST builder сериализует LogicalCondition/PropertyCondition, прочие типы только логирует. Нельзя передать JpqlCondition в REST и считать фильтрацию выполненной | F04; [RestFilterBuilder.java](../../app/src/main/java/ru/fgk/ws/app/storage/RestFilterBuilder.java), 199–224 |
| A18 | P1, по коду приложения | Некоторые delegates строят бизнес-параметры из UI и игнорируют LoadContext.condition. Установка condition сама по себе не изменяет отчёт | F04; [VRpOperBalanceListView.java](../../app/src/main/java/ru/fgk/ws/app/rp/view/reportrpoperbalance/vrpoperbalance/VRpOperBalanceListView.java), 189–200 |
| A19 | P1/P2, по коду | Много hardcoded RU строк в Lit; тема ориентирована на Lumo с fallback. Русский Lumo app соответствует текущей ориентации, другие locale/темы не проверены | F07; JS и [styles.js](../../../rvk-filter/rvk-filter/src/main/resources/META-INF/frontend/src/component/rvk-filter/styles.js) |
| A20 | P1, по миграциям | createTable/индексы имеют preConditions, но нет QUOTE_ONLY_RESERVED_WORDS, author=diadoc, runOnChange на DDL. Существующую таблицу этим способом нельзя обновить добавлением поля в createTable | F06; [001-rvk-filter-config.xml](../../../rvk-filter/rvk-filter/src/main/resources/ru/fgk/component/rvkfilter/liquibase/changelog/001-rvk-filter-config.xml) |

JPQL row-level policies применяются к чтению; predicate policies поддерживают READ/CREATE/UPDATE/DELETE. Это основа требования A04, а не утверждение о проверенной SQL-инъекции. [Официальная документация Jmix 3](https://docs.jmix.io/jmix/security/row-level-roles.html).

## Проверка локальной БД

SELECT из information_schema/pg_indexes: `rvk_filter_config` отсутствует во всех доступных схемах. Есть `main.flowui_filter_configuration`: id UUID, component_id, configuration_id, username, root_condition TEXT, sys_tenant_id, name, default_for_all. Индекс — PK по id. Группировка по component_id вернула 0 строк.

Следовательно, структуру нового хранения сейчас можно проверить только по entity/changelog; её фактическое развёртывание и PostgreSQL CRUD — обязательный будущий тест F06. Содержимое production не проверялось, старые production-конфигурации удалять нельзя.

## Полнота инвентаризации

Просмотрены main-source XML views/fragments в app/core/sso-plagin, Java-контроллеры, source resource roles и меню app. Распределение по модулям: `app` — 283 файла под `/view/`, из них 268 с корнем `view`, 12 fragment, `main-view.xml` с корнем `mainView` (кандидатом не является) и 2 пустых файла; `core` — один fragment; `sso-plagin` — ни одного. Все 201 разобранная карточка относится к `app`. Реестр: [page-inventory.json](page-inventory.json). Помимо 79 стандартных фильтрованных страниц найдены 16 страниц с собственными фильтрами: всего 95 задач перевода. 45 дополнительных списков и 61 явное исключение разобраны отдельно. Всего корректно разобран 281 view/fragment descriptor; экраны без таблиц и входных полей не являются кандидатами.

Два старых XML в `diadoc/view/packetdocument` пусты: `packet-document-list-view.xml`, `packet-document-detail-view.xml`. Контроллеров, ссылающихся на эти имена, в app не найдено. Они перечислены в `parse_errors` реестра, не скрыты счётчиком и не исправлялись в задаче документации. Не утверждать, что они сейчас ломают registry без активного controller.

Найденные `.setValue()` могут относиться к renderer, а входные поля — к настройкам отображения. Поэтому реестр помечает их кандидатами для анализа, сохраняет строки исходников и не объявляет автоматически фильтрами. Runtime-роли из БД и metadata inherited/getter-only properties требуют проверки при реализации страницы.
