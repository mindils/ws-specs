# F02. XML и публичный API, удобные для разработчика

[К плану](README.md) · Репозиторий исполнения: `rvk-filter` · Статус: **в работе** — F02.1/F02.3 реализованы; F02.2: operation, typed JPQL/IN и configurationKey реализованы, остальные расширения открыты; F02.4 частично; [журнал](12-implementation-log.md).

Цель: обычный фильтр объявляется без контроллера, сложный использует явное расширение. Статус расширений F02.2 указан ниже; F02.3 реализован.

Сверка 2026-09-08: `parameterClass`, `hasInExpression`, `configurationKey` уже были в коммите 63088c5. В текущем продолжении добавлены фиксированный `operation`, редактор списков `valueList` и корневые Studio metadata. `allowedOperations`, references и option providers ещё не поддержаны. См. [отчёт](15-addon-operations-verification.md). Текущий поддержанный контракт описан в [xml-api.md аддона](../../../rvk-filter/docs/xml-api.md).

## F02.1. Согласованный XML-контракт — до пилота

- [x] Сохранить `http://fgk.ru/schema/rvk-filter`, `<flt:rvkFilter>`, существующий `<flt:filters>` и рабочие property/jpql declarations.
- [x] `id` обязателен у сохраняющего компонента и определения поля: это стабильные ключи пресетов. Переименование — управляемая миграция, не неявное вычисление нового id по подписи.
- [x] По умолчанию брать label/type/enum options из Jmix metadata, явно указанные значения имеют приоритет. Путь через точку проверять целиком; caption конечного свойства локализовать.
- [x] Корневые атрибуты размера/видимости и дочерние элементы либо реально применять, либо отклонять с понятным сообщением; не объявлять неподдерживаемые атрибуты в XSD.
- [x] Диагностика содержит view, component id, field id, имя ошибочного атрибута/элемента и допустимые значения. Проверять неизвестные атрибуты, повторные singleton-элементы, пустые обязательные значения, duplicate field/option IDs и неверный order.
- [x] Boolean-синтаксис согласовать с xs:boolean: true/false/1/0; любое другое непустое значение — ошибка. Пустая обязательная строка — ошибка, необязательная обрабатывается по документированному default.
- [x] Строковый поиск остаётся по `searchProperty`, с contains/equals/startsWith; для нестрокового — equals. При отсутствии searchProperty скрывать поле поиска, оставляя панель условий.

## F02.2. Расширения условий — перед зависящими страницами

Реализовано: `operation` (фиксированный выбор разработчика), `parameterClass`, `hasInExpression`, `configurationKey`. Остальные строки таблицы описывают целевой API.

| Конструкция | Целевое поведение |
|---|---|
| `operation` у propertyFilter | Имена операций как в стандартном Jmix XML, например EQUAL/CONTAINS/IN_LIST/IS_SET. Без атрибута сохранить прежний выбор по типу |
| `allowedOperations` | Список разрешённых пользователю операций для данного поля; сервер использует тот же whitelist |
| entity property без type | Автоматический single entity picker по metadata; множественный выбор задаётся явно |
| `itemsContainer` | Использовать существующий контейнер view для небольшого списка вариантов |
| `itemsQuery` | Для большого справочника использовать штатную форму itemsQuery/query с параметром `:searchString`; загрузка по страницам и под правами пользователя |
| JPQL `parameterClass` | Явный Java-тип одного значения; устраняет преобразование Integer/UUID/enum/даты в String или BigDecimal |
| JPQL `hasInExpression` | Параметр — типизированная коллекция; нужен существующему diadocStatusFilter |
| Java option provider / condition provider | Расширение для удалённого/вычисляемого справочника и доменного условия, без app-specific кода в аддоне |
| Явный ключ конфигурации | Дополнительный `configurationKey` для устойчивых ключей во фрагментах; default обычного view остаётся `<viewId>.<componentId>` |

Один источник options на поле: enum metadata, статические option, itemsContainer, itemsQuery или Java provider. Явные option могут ограничить набор enum; конфликт нескольких явных источников — ошибка, не скрытый приоритет.

Тип JPQL-значения не выводить из вида контрола: entity selector для `...id = ?` должен передавать тип id, а не целую entity. Для такого отображения предусмотреть `optionValueProperty` с явным значением `id`; обычный propertyFilter по entity использует entity-семантику Jmix. Ассоциации из других stores обслуживаются provider-адаптером, а не произвольным JPQL к удалённой БД.

## F02.3. Значения по умолчанию

- [x] Простой `defaultValue` сохранить для text/select/boolean/одного числа, но преобразовывать в каноническое типизированное состояние, не в StringNode для любого типа.
- [x] Структурный `<flt:defaultValue>` использовать для нескольких значений и границ диапазона; у диапазона задаются mode/from/to/exact, у списка — повторные value. Атрибут и вложенное значение одновременно запрещены.
- [x] Даты сохранять в ISO; относительные режимы — как режим, а не вычисленная когда-то календарная дата. Диапазон по умолчанию для отчёта вычисляет приложение, если его бизнес-правило не является общим режимом.
- [x] XML/Java defaults и default preset применяются по одному lifecycle-контракту F04. removable=false означает запрет удаления контрола из панели, а не security constraint.

## F02.4. XSD, Studio, документация

Частично реализовано 2026-09-05: import layout, проверка всей схемы аддона с тремя неизменёнными используемыми определениями из JAR Jmix 3.0.0 и обоих XML-примеров. Полная `layout.xsd` не принимается JDK XSD 1.0 (`cos-all-limited.1.2`, validator types); полная XSD/Studio-интеграция и реальные example views ещё не проверены. Поэтому пункты ниже целиком не закрыты.

- [ ] Добавить корректный import layout schema и resolver/catalog для стандартной проверки с **разрешённой версией Jmix**, без зависимости от случайного latest/snapshot XSD.
- [ ] Проверить схему стандартным валидатором и загрузку примеров в реальном Jmix view. Отдельно реализовать Studio metadata: компонент, loader reference, property path и источники options.
- [ ] Поставлять полные примеры: простой список, диапазон/default, reference picker, JPQL Boolean/Date/IN, Java provider, фрагмент со стабильным ключом. В каждом есть data containers/loaders, entity fixture и локализованные подписи.
- [ ] Обновить XSD, loader, builders, docs/xml-api.md, docs/java-api.md, docs/examples и тесты одним изменением контракта.

Пример ниже использует **существующий** короткий синтаксис; его сохранить как базовый сценарий:

```xml
<flt:rvkFilter id="filter" dataLoader="itemsDl" searchProperty="name" width="100%">
    <flt:filters>
        <flt:propertyFilter id="name" property="name" defaultVisible="true"/>
    </flt:filters>
</flt:rvkFilter>
```

Полный view обязан объявить namespace flt, itemsDl и metadata entity. Фрагмент выше не является самостоятельным XML-дескриптором.

## Приёмка

Все корректные примеры открываются; неверный property/loader/msg/operation/options/default ловится с контекстом поля. Старый корректный XML совместим; отрицательные тесты проверяют поведение loader, а не только повторяют helper parsing. Пилотные XML проходят IDE-инспекцию либо документированный fallback. [Штатная интеграция компонента в XML и Studio](https://docs.jmix.io/jmix/flow-ui/vc/creating-components/integrating-into-jmix-ui.html).
