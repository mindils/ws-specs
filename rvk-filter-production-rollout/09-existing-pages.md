# F09. Перевод страниц с существующей фильтрацией

> Объём изменён 2026-09-07: этот документ — подробный каталог исходного аудита. Добавление на остальные страницы перенесено в [отложенный backlog](13-pages-backlog.md). В текущей задаче проверяются только M001–M003 и N002, где RVK Filter уже подключён. Порядок волн ниже не является указанием продолжать массовое внедрение.

[К плану](README.md) · [Полный реестр](page-inventory.json)

Всего задач: **95**. Порядок фиксирован: номер волны, затем viewId; пилот имеет отдельный порядок.
Статусы остальных страниц — отложено; четыре подключённые страницы проверяются в текущей задаче. Номера строк относятся к снимку 2026-09-05; JSON хранит полный набор найденных обработчиков, условий, полей и ограничений загрузчика.

**Порядок волны 8:** сначала оставшиеся задачи M из документа 09, затем задачи N из документа 10. Зависимости F02–F08 означают приёмку соответствующего пути, а не завершение всех необязательных возможностей аддона.

Поля вне property binding перечислены как кандидаты для проверки, а не как разрешение переносить настройки отображения/параметры команд в фильтр.

## Волна 1. Пилот

### M001. Типы деталей — `nsi_NvPartType.list`

- [ ] Полная production-приёмка остаётся открытой. **Действующая страница проверена 2026-09-07:** RVK, переключение режимов и серверный flag F08.2 реализованы; Gate 2 зелёный, сценарии Gate 3 выполнены. Результаты и оставшиеся условия — [отчёт](14-current-pages-verification.md).
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/nvparttype/nv-part-type-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/nvparttype/NvPartTypeListView.java).
- Загрузчики: `nvPartTypesDl` → `ru.fgk.ws.app.nsi.entity.NvPartType`.
- Текущие фильтры: `name` CONTAINS.
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M002. Причины отклонения — `RejectReason.list`

- [ ] Полная production-приёмка остаётся открытой. **Действующая страница проверена 2026-09-07:** RVK, переключение режимов и серверный flag F08.2 реализованы; Gate 2 зелёный, сценарии Gate 3 выполнены. Результаты и оставшиеся условия — [отчёт](14-current-pages-verification.md).
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/rejectreason/reject-reason-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/rejectreason/RejectReasonListView.java).
- Загрузчики: `rejectReasonDl` → `ru.fgk.ws.app.nsi.entity.RejectReason`.
- Текущие фильтры: `message` CONTAINS.
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 35](../../app/src/main/java/ru/fgk/ws/app/nsi/view/rejectreason/RejectReasonListView.java) `(checkbox, rejectReason) -> checkbox.setValue(rejectReason.getNonPayment()));`, [строка 46](../../app/src/main/java/ru/fgk/ws/app/nsi/view/rejectreason/RejectReasonListView.java) `(checkbox, rejectReason) -> checkbox.setValue(rejectReason.getViolationDamage()));`, [строка 57](../../app/src/main/java/ru/fgk/ws/app/nsi/view/rejectreason/RejectReasonListView.java) `(checkbox, rejectReason) -> checkbox.setValue(rejectReason.getViolationOperRepair()));`, [строка 68](../../app/src/main/java/ru/fgk/ws/app/nsi/view/rejectreason/RejectReasonListView.java) `(checkbox, rejectReason) -> checkbox.setValue(rejectReason.getViolationTech()));`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M003. Депо — `nsi_VDepo.list`

- [ ] Полная production-приёмка остаётся открытой. **Действующая страница проверена 2026-09-07:** RVK, переключение режимов и серверный flag F08.2 реализованы; Gate 2 зелёный, сценарии Gate 3 выполнены. Результаты и оставшиеся условия — [отчёт](14-current-pages-verification.md).
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/vdepo/v-depo-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/vdepo/VDepoListView.java).
- Загрузчики: `vDepoDl` → `ru.fgk.ws.app.nsi.entity.VDepo`.
- Текущие фильтры: `id` EQUAL; `shortName` CONTAINS.
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [PtContractWriteRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractWriteRole.java), [PtContractReadRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractReadRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

## Волна 2. Простые скалярные списки

### M004. Договоры на ТР-2 с ЦДИ — `DrContractCdi.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/drcontract/view/dr-contract-cdi-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/drcontract/view/DrContractCdiListView.java).
- Загрузчики: `drContractCdiDl` → `ru.fgk.ws.app.drcontract.entity.DrContractCdi`.
- Текущие фильтры: `dateBegin` GREATER_OR_EQUAL; `dateEnd` LESS_OR_EQUAL; `contractNum` CONTAINS.
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 31](../../app/src/main/java/ru/fgk/ws/app/drcontract/view/DrContractCdiListView.java) `dateBeginId.setValue(LocalDate.of(LocalDate.now().getYear(), 1, 1));`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M005. Пакеты ремонтов ТР-1 — `DrDiadocOperRepairTr1.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/drdiadocoperrepairtr1/dr-diadoc-oper-repair-tr1-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/drdiadocoperrepairtr1/DrDiadocOperRepairTr1ListView.java).
- Загрузчики: `drDiadocOperRepairTr1sDl` → `ru.fgk.ws.app.dr.entity.DrDiadocOperRepairTr1`.
- Текущие фильтры: `repairDate` GREATER_OR_EQUAL; `repairDate` LESS_OR_EQUAL; `rwCode` EQUAL; `avrNumber` EQUAL; `packetId` EQUAL.
- Прочие поля ввода для проверки: `reportDateFromDatePicker`, `reportDateToDatePicker`, `vRailwaysComboBox`.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 99](../../app/src/main/java/ru/fgk/ws/app/dr/view/drdiadocoperrepairtr1/DrDiadocOperRepairTr1ListView.java) `rwCodeFilter.setValue(event.getValue() == null ? null : event.getValue().getRwCode());`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M006. Справочник работ по замене деталей — `DrTrWork.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/drtrworkreplacement/dr-tr-work-replacement-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/drtrworkreplacement/DrTrWorkReplacementListView.java).
- Загрузчики: `drTrWorksDl` → `ru.fgk.ws.app.nsi.entity.DrTrWorkReplacement`.
- Текущие фильтры: `code` EQUAL; `name` CONTAINS.
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M007. Неисправности вагонов — `NsiNvDefectGroup.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/nsinvdefectgroup/nsi-nv-defect-group-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/nsinvdefectgroup/NsiNvDefectGroupListView.java).
- Загрузчики: `nsiNvDefectGroupDl` → `ru.fgk.ws.app.nsi.entity.NsiNvDefectGroup`.
- Текущие фильтры: `defectCode` EQUAL; `vDamageType.dmName` EQUAL; `reason` EQUAL; `node` EQUAL.
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M008. Группы деталей — `VrkDetailGroup.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/asuvrk/view/vrkdetailgroup/vrk-detail-group-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/asuvrk/view/vrkdetailgroup/VrkDetailGroupListView.java).
- Загрузчики: `vrkDetailGroupsDl` → `ru.fgk.ws.app.asuvrk.entity.VrkDetailGroup`.
- Текущие фильтры: `name` CONTAINS.
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M009. Прототипы деталей — `VrkDetailPrototype.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/asuvrk/view/vrkdetailprototype/vrk-detail-prototype-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/asuvrk/view/vrkdetailprototype/VrkDetailPrototypeListView.java).
- Загрузчики: `vrkDetailPrototypesDl` → `ru.fgk.ws.app.asuvrk.entity.VrkDetailPrototype`.
- Текущие фильтры: `id` EQUAL; `name` CONTAINS; `vrkDetailGroupInfo.name` CONTAINS.
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M010. Передача документов в ДЮ — `dt_VOperRepair.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dt/view/dtvoperrepair/v-oper-repair-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dt/view/dtvoperrepair/VOperRepairListView.java).
- Загрузчики: `dtVOperRepairsDl` → `ru.fgk.ws.app.dt.entity.DtVOperRepair`.
- Текущие фильтры: `psrDate` GREATER_OR_EQUAL; `psrDate` LESS_OR_EQUAL.
- Прочие поля ввода для проверки: `psrDateFromDatePicker`, `psrDateToDatePicker`.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 82](../../app/src/main/java/ru/fgk/ws/app/dt/view/dtvoperrepair/VOperRepairListView.java) `psrDateFromDatePicker.setValue(prevMonth.withDayOfMonth(1));`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [DepsRole.java](../../app/src/main/java/ru/fgk/ws/app/dr/security/DepsRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M011. Словари текстовых валидаций — `nsi_NvValidationDictionary.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/nvvalidationdictionary/nv-validation-dictionary-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/nvvalidationdictionary/NvValidationDictionaryListView.java).
- Загрузчики: `nvValidationDictionaryDl` → `ru.fgk.ws.app.nsi.entity.NvValidationDictionary`.
- Текущие фильтры: `alias` CONTAINS.
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M012. Дороги — `nsi_VRailway.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/vrailway/v-railway-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/vrailway/VRailwayListView.java).
- Загрузчики: `vRailwaysDl` → `ru.fgk.ws.app.nsi.entity.VRailway`.
- Текущие фильтры: `rwCode` CONTAINS; `rwName` CONTAINS.
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M013. Списки деталей — `pt_PtList.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/pt/view/ptlist/pt-list-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptlist/PtListListView.java).
- Загрузчики: `ptListsDl` → `ru.fgk.ws.app.pt.entity.PtList`; `?` → `ru.fgk.ws.app.pt.entity.PtListItem`.
- Текущие фильтры: `createdBy` CONTAINS; `name` CONTAINS.
- Прочие поля ввода для проверки: `createdByFilter`, `nameFilter`.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 369](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptlist/PtListListView.java) `listItemField.setValue(value);`
- Роли (включая наследование исходных resource roles): [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [PtContractWriteRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractWriteRole.java), [PtContractReadRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractReadRole.java), [WnBaseRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WnBaseRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M014. Договоры на ремонт деталей — `pt_RepairContract.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/pt/view/ptrepaircontract/pt-repair-contract-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptrepaircontract/PtRepairContractListView.java).
- Загрузчики: `ptRepairContractsDl` → `ru.fgk.ws.app.pt.entity.PtRepairContract`.
- Текущие фильтры: `dateStart` GREATER_OR_EQUAL; `dateEndWork` LESS_OR_EQUAL; `number` CONTAINS; `vrkCode` EQUAL.
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M015. Списки ремонтов — `rp_RepairList.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/repair/view/repairlist/repair-list-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/repair/view/repairlist/RepairListListView.java).
- Загрузчики: `repairListsDl` → `ru.fgk.ws.app.repair.entity.RepairList`.
- Текущие фильтры: `createdBy` CONTAINS; `name` CONTAINS.
- Прочие поля ввода для проверки: `createdByFilter`, `nameFilter`.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [DrOperFileRole.java](../../app/src/main/java/ru/fgk/ws/app/dr/security/DrOperFileRole.java), [DrPlannedRepairAcceptanceRole.java](../../app/src/main/java/ru/fgk/ws/app/dr/security/DrPlannedRepairAcceptanceRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M016. Списки вагонов — `wn_WnList.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/wagons/view/wnlist/wn-list-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/wagons/view/wnlist/WnListListView.java).
- Загрузчики: `wnListsDl` → `ru.fgk.ws.app.wagons.entity.WnList`.
- Текущие фильтры: `createdBy` CONTAINS; `name` CONTAINS.
- Прочие поля ввода для проверки: `createdByFilter`, `nameFilter`.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 169](../../app/src/main/java/ru/fgk/ws/app/wagons/view/wnlist/WnListListView.java) `listItemField.setValue(value);`
- Роли (включая наследование исходных resource roles): [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [PtContractWriteRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractWriteRole.java), [PtContractReadRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractReadRole.java), [WnBaseRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WnBaseRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

## Волна 3. Справочники со сложной фильтрацией

### M017. Dr contract cdi work groups — `DrContractCdiWorkGroup.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/view/drcontractcdiworkgroup/dr-contract-cdi-work-group-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/view/drcontractcdiworkgroup/DrContractCdiWorkGroupListView.java).
- Загрузчики: `drContractCdiWorkGroupsDl` → `ru.fgk.ws.app.drcontract.entity.DrContractCdiWorkGroup`.
- Текущие фильтры: genericFilter `genericFilter` — каталог [{"include": ".*"}].
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: genericFilter: каталог/операции/AND-OR.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M018. Архив обработки ремонтов — `ImportedPacketArch.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/asuvrk/view/importedpacketarch/imported-packet-arch-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/asuvrk/view/importedpacketarch/ImportedPacketArchListView.java).
- Загрузчики: `importedPacketArchDl` → `ru.fgk.ws.app.dr.entity.ImportedPacketArch`.
- Текущие фильтры: `sourceType` EQUAL; `repairType` EQUAL; `wagNum` EQUAL; `actNum` EQUAL; `depo.vrkCode` EQUAL; `packCheckedCode` EQUAL; `status` EQUAL; `xmlHash` EQUAL.
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: динамические параметры/условия.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 156](../../app/src/main/java/ru/fgk/ws/app/asuvrk/view/importedpacketarch/ImportedPacketArchListView.java) `this.importedPacketArchDl.setParameter("repairUid", repairUid);`, [строка 160](../../app/src/main/java/ru/fgk/ws/app/asuvrk/view/importedpacketarch/ImportedPacketArchListView.java) `this.importedPacketArchDl.setParameter("actId", actId);`, [строка 345](../../app/src/main/java/ru/fgk/ws/app/asuvrk/view/importedpacketarch/ImportedPacketArchListView.java) `importedPacketArchDl.setParameter("repairDateStart", startDate.atStartOfDay());`, [строка 352](../../app/src/main/java/ru/fgk/ws/app/asuvrk/view/importedpacketarch/ImportedPacketArchListView.java) `importedPacketArchDl.setParameter("repairDateEnd", endDate.atTime(LocalTime.MAX));`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M019. Пользователи АСУ РВК — `User.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/view/user/user-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/view/user/UserListView.java).
- Загрузчики: `usersDl` → `ru.fgk.sso.entity.User`.
- Текущие фильтры: genericFilter `genericFilter` — каталог [{"include": ".*"}]; `username` CONTAINS.
- Прочие поля ввода для проверки: `rolesComboBox`.
- Особенности: genericFilter: каталог/операции/AND-OR; динамические параметры/условия.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 256](../../app/src/main/java/ru/fgk/ws/app/view/user/UserListView.java) `usersDl.setParameter("roleCode", roleCode);`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M020. Подразделения АО "ФГК" — `nsi_Department.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/department/department-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/department/DepartmentListView.java).
- Загрузчики: `departmentsDl` → `ru.fgk.ws.app.nsi.entity.Department`.
- Текущие фильтры: genericFilter `genericFilter` — каталог [{"include": ".*"}].
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: genericFilter: каталог/операции/AND-OR.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M021. Рассылка по выпуску — `nsi_NsiNoticeMail.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/noticemail/notice-mail-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/noticemail/NoticeMailListView.java).
- Загрузчики: `noticeMailDl` → `ru.fgk.ws.app.nsi.entity.NsiNoticeMail`; `vRailwaysDl` → `ru.fgk.ws.app.nsi.entity.VRailway`.
- Текущие фильтры: `railwayFilter` JPQL(ru.fgk.ws.app.nsi.entity.VRailway); `email` CONTAINS; `fio` CONTAINS; `activeFilter` JPQL(java.lang.Boolean); `shortFormat` EQUAL.
- Прочие поля ввода для проверки: `railwayComboBox`, `activeCheckbox`.
- Особенности: JPQL: типы/joins.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M022. Страны — `nsi_VCountry.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/vcountry/v-country-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/vcountry/VCountryListView.java).
- Загрузчики: `vCountriesDl` → `ru.fgk.ws.app.nsi.entity.VCountry`.
- Текущие фильтры: genericFilter `genericFilter` — каталог [{"include": ".*"}].
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: genericFilter: каталог/операции/AND-OR; динамические параметры/условия.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 18](../../app/src/main/java/ru/fgk/ws/app/nsi/view/vcountry/VCountryListView.java) `vCountriesDl.setParameter("sign", "1");`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M023. msg://VDepartmentListView.title — `nsi_VDepartment.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/vdepartment/v-department-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/vdepartment/VDepartmentListView.java).
- Загрузчики: `vDepartmentsDl` → `ru.fgk.ws.app.nsi.entity.VDepartment`.
- Текущие фильтры: genericFilter `genericFilter` — каталог [{"include": ".*"}].
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: genericFilter: каталог/операции/AND-OR.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M024. Станции — `nsi_VStation.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/vstation/v-station-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/vstation/VStationListView.java).
- Загрузчики: `vStationsDl` → `ru.fgk.ws.app.nsi.entity.VStation`.
- Текущие фильтры: genericFilter `genericFilter` — каталог [{"include": ".*"}].
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: genericFilter: каталог/операции/AND-OR.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M025. Список подрядчиков — `v_depo_contractor.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/vdepocontractor/v-depo-contractor-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/vdepocontractor/VDepoContractorListView.java).
- Загрузчики: `vDepoContractorsDl` → `ru.fgk.ws.app.nsi.entity.VDepoContractor`.
- Текущие фильтры: `depoRepair.shortName` CONTAINS; `depoActName` CONTAINS; `depoMhName` CONTAINS; `currentDateFilter` JPQL(java.time.LocalDate).
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: JPQL: типы/joins.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 28](../../app/src/main/java/ru/fgk/ws/app/nsi/view/vdepocontractor/VDepoContractorListView.java) `currentDateFilter.setValue(LocalDate.now());`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

## Волна 4. Договоры, уведомления, претензии

### M026. Договоры по ремонту вагонов — `VDrContract.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/drcontract/view/v-dr-contract-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/drcontract/view/VDrContractListView.java).
- Загрузчики: `vDrContractsDl` → `ru.fgk.ws.app.drcontract.entity.VDrContract`.
- Текущие фильтры: `dateEndWork` GREATER_OR_EQUAL; `dateBegin` LESS_OR_EQUAL; `vrkCode` EQUAL; `repairType` EQUAL; `vDrContractDepo.depo` EQUAL; `contractNumber` CONTAINS.
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: тип через metadata.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 116](../../app/src/main/java/ru/fgk/ws/app/drcontract/view/VDrContractListView.java) `dateEndWorkId.setValue(LocalDate.of(LocalDate.now().getYear(), 1, 1));`
- Роли (включая наследование исходных resource roles): [DrContractWriteRole.java](../../app/src/main/java/ru/fgk/ws/app/security/DrContractWriteRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [DrContractReadRole.java](../../app/src/main/java/ru/fgk/ws/app/security/DrContractReadRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M027. Справочник предприятий — `da_ClaimDepo.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/da/view/claimdepo/claim-depo-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/da/view/claimdepo/ClaimDepoListView.java).
- Загрузчики: `claimDepoDl` → `ru.fgk.ws.app.da.entity.ClaimDepo`.
- Текущие фильтры: genericFilter `genericFilter` — каталог [{"include": ".*"}]; `depo.shortName` CONTAINS; `depo.vrkCode` EQUAL; `depo.railway` EQUAL.
- Прочие поля ввода для проверки: `vRailwaysComboBox`.
- Особенности: genericFilter: каталог/операции/AND-OR; ссылка на entity.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M028. Справочник реквизитов предприятий ремонта для заявок на ТР — `da_ClaimDepoVisa.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/da/view/claimdepovisa/claim-depo-visa-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/da/view/claimdepovisa/ClaimDepoVisaListView.java).
- Загрузчики: `claimDepoVisasDl` → `ru.fgk.ws.app.da.entity.ClaimDepoVisa`.
- Текущие фильтры: genericFilter `genericFilter` — каталог [{"include": ".*"}].
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: genericFilter: каталог/операции/AND-OR.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M029. Claim depo stations — `da_ClaimStation.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/da/view/claimdepostation/claim-depo-station-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/da/view/claimdepostation/ClaimDepoStationListView.java).
- Загрузчики: `claimDepoStationsDl` → `ru.fgk.ws.app.da.entity.ClaimDepoStation`.
- Текущие фильтры: genericFilter `genericFilter` — каталог [{"include": ".*"}].
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: genericFilter: каталог/операции/AND-OR.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M030. Агентские договоры на выполнение ТР — `da_ContractAgent.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/da/view/dacontractagent/da-contract-agent-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/da/view/dacontractagent/DaContractAgentListView.java).
- Загрузчики: `daContractAgentsDl` → `ru.fgk.ws.app.da.entity.DaContractAgent`.
- Текущие фильтры: `dateActionContract` JPQL(java.time.LocalDate); `contractI` JPQL(ru.fgk.ws.app.nsi.entity.VCountry).
- Прочие поля ввода для проверки: `vCountriesComboBox`.
- Особенности: JPQL: типы/joins.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 31](../../app/src/main/java/ru/fgk/ws/app/da/view/dacontractagent/DaContractAgentListView.java) `dateActionContract.setValue(LocalDate.of(`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [DaContractEditRole.java](../../app/src/main/java/ru/fgk/ws/app/da/security/DaContractEditRole.java), [DaContractReadRole.java](../../app/src/main/java/ru/fgk/ws/app/da/security/DaContractReadRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M031. Заявки по РФ — `da_RepairClaimRf.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/da/view/repairclaim/repair-claim-rf-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/da/view/repairclaim/RepairClaimRfListView.java).
- Загрузчики: `repairClaimsDl` → `ru.fgk.ws.app.da.entity.RepairClaim`.
- Текущие фильтры: `sendDate` GREATER_OR_EQUAL; `sendDate` LESS_OR_EQUAL; `dislocationRw` EQUAL; `sendStatus` EQUAL.
- Прочие поля ввода для проверки: `reportDateFromDatePicker`, `reportDateToDatePicker`, `vRailwaysComboBox`, `sendStatusSelect`.
- Особенности: ссылка на entity.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 149](../../app/src/main/java/ru/fgk/ws/app/da/view/repairclaim/RepairClaimRfListView.java) `reportDateFromDatePicker.setValue(LocalDateTime.now().toLocalDate().minusDays(10));`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M032. Остаток в ТР по СНГ — `da_VOperBalanceSng.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/da/view/voperbalancesng/v-oper-balance-sng-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/da/view/voperbalancesng/VOperBalanceSngListView.java).
- Загрузчики: `vOperBalanceSngsDl` → `ru.fgk.ws.app.da.entity.VOperBalanceSng`; `vCountriesDl` → `ru.fgk.ws.app.nsi.entity.VCountry`.
- Текущие фильтры: `claimDate` IS_SET; `country` IN_LIST; `wnListFilter` JPQL(ru.fgk.ws.app.wagons.entity.WnList).
- Прочие поля ввода для проверки: `repairLiabilityFilter`, `countryComboBox`.
- Особенности: JPQL: типы/joins; ссылка на entity; динамические параметры/условия.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 113](../../app/src/main/java/ru/fgk/ws/app/da/view/voperbalancesng/VOperBalanceSngListView.java) `vOperBalanceSngsDl.setParameter("applyLiabilityFilter", true);`, [строка 137](../../app/src/main/java/ru/fgk/ws/app/da/view/voperbalancesng/VOperBalanceSngListView.java) `vCountriesDl.setParameter("sign", "1");`, [строка 144](../../app/src/main/java/ru/fgk/ws/app/da/view/voperbalancesng/VOperBalanceSngListView.java) `vOperBalanceSngsDl.setParameter("applyLiabilityFilter", repairLiabilityFilter.getValue());`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M033. msg://departmentsVisaListView.title — `nsi_DepartmentsVisa.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/da/view/departmentsvisa/departments-visa-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/da/view/departmentsvisa/DepartmentsVisaListView.java).
- Загрузчики: `departmentsVisasDl` → `ru.fgk.ws.app.nsi.entity.DepartmentsVisa`.
- Текущие фильтры: genericFilter `genericFilter` — каталог [{"include": ".*"}].
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: genericFilter: каталог/операции/AND-OR.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M034. Договоры аренды — `rs_VTabContract.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/rs/view/vtabcontract/v-tab-contract-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/rs/view/vtabcontract/VTabContractListView.java).
- Загрузчики: `vTabContractsDl` → `ru.fgk.ws.app.rs.entity.VTabContract`; `vContractorsDl` → `ru.fgk.ws.app.rs.entity.VContractor`.
- Текущие фильтры: `contractNum` CONTAINS; `contractor` EQUAL.
- Прочие поля ввода для проверки: `numFilter`, `contractorComboBox`, `contractsOnCurrentDateFilter`.
- Особенности: ссылка на entity; динамические параметры/условия.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 62](../../app/src/main/java/ru/fgk/ws/app/rs/view/vtabcontract/VTabContractListView.java) `vTabContractsDl.setParameter("current_date", timeSource.currentTimestamp());`, [строка 70](../../app/src/main/java/ru/fgk/ws/app/rs/view/vtabcontract/VTabContractListView.java) `vTabContractsDl.setParameter("current_date", timeSource.currentTimestamp());`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

## Волна 5. Вагоны и архивы ремонтов

### M035. История УКВ — `PtUkvArchive.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/view/ptukvarchive/pt-ukv-archive-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/view/ptukvarchive/PtUkvArchiveListView.java).
- Загрузчики: `ptUkvArchivesDl` → `ru.fgk.ws.app.pt.entity.PtUkvArchive`.
- Текущие фильтры: `recdatebegin` GREATER_OR_EQUAL; `recdateend` LESS_OR_EQUAL.
- Прочие поля ввода для проверки: `reportDateFromDatePicker`, `reportDateToDatePicker`.
- Особенности: динамические параметры/условия.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 38](../../app/src/main/java/ru/fgk/ws/app/view/ptukvarchive/PtUkvArchiveListView.java) `ptUkvArchivesDl.setParameter("pDetailUid", pDetailUid);`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M036. Ремонты — `VRepairAbdpvArch.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/repair/view/vrepairabdpvarch/v-repair-abdpv-arch-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/repair/view/vrepairabdpvarch/VRepairAbdpvArchListView.java).
- Загрузчики: `vRepairAbdpvArchDl` → `ru.fgk.ws.app.wagons.entity.VRepairAbdpvArch`.
- Текущие фильтры: `jpqlFilterVrk` JPQL(ru.fgk.ws.app.nsi.entity.VrkEnum); `jpqlFilterRailways` JPQL(java.lang.Integer); `jpqlFilterWnList` JPQL(ru.fgk.ws.app.wagons.entity.WnList); `jpqlFilterRepairList` JPQL(ru.fgk.ws.app.repair.entity.RepairList).
- Прочие поля ввода для проверки: `vRailwaysComboBox`, `checkboxDefectDate`, `filterDefectDateBegin`, `filterDefectDateEnd`, `checkboxRepairDate`, `filterRepairDateBegin`, `filterRepairDateEnd`, `checkboxFrozen`.
- Особенности: JPQL: типы/joins; динамические параметры/условия.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 132](../../app/src/main/java/ru/fgk/ws/app/repair/view/vrepairabdpvarch/VRepairAbdpvArchListView.java) `filterRepairDateBegin.setValue(filtersDateBegin);`, [строка 133](../../app/src/main/java/ru/fgk/ws/app/repair/view/vrepairabdpvarch/VRepairAbdpvArchListView.java) `filterRepairDateEnd.setValue(filtersDateEnd);`, [строка 134](../../app/src/main/java/ru/fgk/ws/app/repair/view/vrepairabdpvarch/VRepairAbdpvArchListView.java) `filterDefectDateBegin.setValue(filtersDateBegin);`, [строка 135](../../app/src/main/java/ru/fgk/ws/app/repair/view/vrepairabdpvarch/VRepairAbdpvArchListView.java) `filterDefectDateEnd.setValue(filtersDateEnd);`, [строка 140](../../app/src/main/java/ru/fgk/ws/app/repair/view/vrepairabdpvarch/VRepairAbdpvArchListView.java) `checkboxFrozen.setValue(true);`, [строка 163](../../app/src/main/java/ru/fgk/ws/app/repair/view/vrepairabdpvarch/VRepairAbdpvArchListView.java) `checkboxGroupRepairType.setValue(repairTypeCheckboxValues.keySet());` Остальные места перечислены в JSON.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M037. Замена деталей по 4624 — `VRepairDetailLink.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/repair/view/vrepairabdpvarch/v-repair-detail-link-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/repair/view/vrepairabdpvarch/VRepairDetailLinkListView.java).
- Загрузчики: `vRepairDetailLinksDl` → `ru.fgk.ws.app.repair.entity.VRepairDetailLink`.
- Текущие фильтры: genericFilter `genericFilter` — каталог [{"include": ".*"}]; `repair.defectDate` GREATER_OR_EQUAL; `repair.defectDate` LESS_OR_EQUAL; `repair.repairDate` GREATER_OR_EQUAL; `repair.repairDate` LESS_OR_EQUAL; `removedFlag` EQUAL; `JPQL без id` JPQL(ru.fgk.ws.app.wagons.entity.WnList).
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: genericFilter: каталог/операции/AND-OR; JPQL: типы/joins.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 39](../../app/src/main/java/ru/fgk/ws/app/repair/view/vrepairabdpvarch/VRepairDetailLinkListView.java) `filterRepairDateBegin.setValue(filtersDateBegin);`, [строка 40](../../app/src/main/java/ru/fgk/ws/app/repair/view/vrepairabdpvarch/VRepairDetailLinkListView.java) `filterRepairDateEnd.setValue(filtersDateEnd);`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M038. Архив реестра вагонов — `WagArchiveView`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/wagons/view/wagarchive/wag-archive-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/wagons/view/wagarchive/WagArchiveView.java).
- Загрузчики: `vWagRegisterArchiveScreenDataDl` → `ru.fgk.ws.app.wagons.entity.VWagRegisterArchiveScreenData`.
- Текущие фильтры: `wagnumFilter` JPQL(ru.fgk.ws.app.wagons.entity.WnList); `dateBegin` GREATER_OR_EQUAL; `dateBegin` LESS_OR_EQUAL; `dateOut` GREATER_OR_EQUAL; `dateOut` LESS_OR_EQUAL.
- Прочие поля ввода для проверки: `dateBeginFromDatePicker`, `dateBeginToDatePicker`, `dateOutFromDatePicker`, `dateOutToDatePicker`.
- Особенности: JPQL: типы/joins.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M039. Добавить к списку — `rp_RepairLists.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/repair/view/repairlist/repair-lists-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/repair/view/repairlist/RepairListsView.java).
- Загрузчики: `repairListsDl` → `ru.fgk.ws.app.repair.entity.RepairList`.
- Текущие фильтры: `name` CONTAINS.
- Прочие поля ввода для проверки: `nameFilter`.
- Особенности: динамические параметры/условия.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 57](../../app/src/main/java/ru/fgk/ws/app/repair/view/repairlist/RepairListsView.java) `repairListsDl.setParameter("author", currentAuthentication.getUser().getUsername());`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [DrOperFileRole.java](../../app/src/main/java/ru/fgk/ws/app/dr/security/DrOperFileRole.java), [DrPlannedRepairAcceptanceRole.java](../../app/src/main/java/ru/fgk/ws/app/dr/security/DrPlannedRepairAcceptanceRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M040. Архив комплектаций — `wn_VWagEquipmentArchive.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/view/vwagequipmentarchive/v-wag-equipment-archive-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/view/vwagequipmentarchive/VWagEquipmentArchiveListView.java).
- Загрузчики: `vWagEquipmentArchivesDl` → `ru.fgk.ws.app.wagons.entity.VWagEquipmentArchive`.
- Текущие фильтры: genericFilter `genericFilter` — каталог [{"include": ".*"}]; `nextEquipmentDate` GREATER_OR_EQUAL; `repairDate` LESS; `repairDate` LESS_OR_EQUAL; `jpqlFilter` JPQL(ru.fgk.ws.app.wagons.entity.WnList).
- Прочие поля ввода для проверки: `checkboxFilterNextEquipmentDate`, `checkboxFilterRepairDate`, `showColumnCheck`.
- Особенности: genericFilter: каталог/операции/AND-OR; JPQL: типы/joins.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 87](../../app/src/main/java/ru/fgk/ws/app/view/vwagequipmentarchive/VWagEquipmentArchiveListView.java) `showColumnCheck.setValue(false);`, [строка 93](../../app/src/main/java/ru/fgk/ws/app/view/vwagequipmentarchive/VWagEquipmentArchiveListView.java) `filterNextEquipmentDate.setValue(filtersDateBegin);`, [строка 94](../../app/src/main/java/ru/fgk/ws/app/view/vwagequipmentarchive/VWagEquipmentArchiveListView.java) `filterRepairDateBegin.setValue(filtersDateBegin);`, [строка 95](../../app/src/main/java/ru/fgk/ws/app/view/vwagequipmentarchive/VWagEquipmentArchiveListView.java) `filterRepairDateEnd.setValue(filtersDateEnd);`, [строка 138](../../app/src/main/java/ru/fgk/ws/app/view/vwagequipmentarchive/VWagEquipmentArchiveListView.java) `filterRepairDateBegin.setValue(value);`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M041. Таблица паспортов — `wn_VWagPassport.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/wagons/view/vwagpassport/v-wag-passport-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/wagons/view/vwagpassport/VWagPassportListView.java).
- Загрузчики: `vWagPassportsDl` → `ru.fgk.ws.app.wagons.entity.VWagPassport`.
- Текущие фильтры: genericFilter `genericFilter` — каталог [{"include": ".*"}]; `JPQL без id` JPQL(ru.fgk.ws.app.wagons.entity.WnList); `regDate` GREATER_OR_EQUAL; `regDate` LESS_OR_EQUAL; `categoryUse` EQUAL; `ownType` EQUAL; `JPQL без id` JPQL(ru.fgk.ws.app.wagons.entity.WnList).
- Прочие поля ввода для проверки: `nvCategoryUsesComboBox`, `nvOwnTypesComboBox`.
- Особенности: genericFilter: каталог/операции/AND-OR; JPQL: типы/joins; тип через metadata.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [PtContractWriteRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractWriteRole.java), [PtContractReadRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractReadRole.java), [WnBaseRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WnBaseRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M042. Расчетный остаток пробега для вагонов, ремонтируемых по единичному критерию — `wn_VWagPassportCalculatedRun.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/wagons/view/vwagpassport/v-wag-passport-calculated-run-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/wagons/view/vwagpassport/VWagPassportCalculatedRunListView.java).
- Загрузчики: `vWagPassportsDl` → `ru.fgk.ws.app.wagons.entity.VWagCalculatedRun`.
- Текущие фильтры: `runRemainingFilter` JPQL(java.lang.Integer); `JPQL без id` JPQL(ru.fgk.ws.app.wagons.entity.WnList).
- Прочие поля ввода для проверки: `showColumnCheck`.
- Особенности: JPQL: типы/joins.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [PtContractWriteRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractWriteRole.java), [PtContractReadRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractReadRole.java), [WnBaseRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WnBaseRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M043. Таблица дислокации — `wn_VWagPassportDislocation.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/wagons/view/vwagpassport/v-wag-passport-dislocation-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/wagons/view/vwagpassport/VWagPassportDislocationListView.java).
- Загрузчики: `vWagPassportsDl` → `ru.fgk.ws.app.wagons.entity.VWagPassport`; `wnNotesHeadsDl` → `ru.fgk.ws.app.wagons.entity.WnNotesHead`.
- Текущие фильтры: genericFilter `genericFilter` — каталог [{"include": ".*"}]; `JPQL без id` JPQL(ru.fgk.ws.app.wagons.entity.WnList).
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: genericFilter: каталог/операции/AND-OR; JPQL: типы/joins.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [PtContractWriteRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractWriteRole.java), [PtContractReadRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractReadRole.java), [WnBaseRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WnBaseRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M044. Добавить к списку — `wn_WnLists.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/wagons/view/wnlist/wn-lists-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/wagons/view/wnlist/WnListsView.java).
- Загрузчики: `wnListsDl` → `ru.fgk.ws.app.wagons.entity.WnList`.
- Текущие фильтры: `name` CONTAINS.
- Прочие поля ввода для проверки: `nameFilter`.
- Особенности: динамические параметры/условия.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 63](../../app/src/main/java/ru/fgk/ws/app/wagons/view/wnlist/WnListsView.java) `wnListsDl.setParameter("author", currentAuthentication.getUser().getUsername());`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

## Волна 6. Документооборот, контроль, выгрузки DR/DT

### M045. Экспорт документов по ТР-2 — `dr_ExportFiles.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/drexportfiles/dr-export-files-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/drexportfiles/DrExportFilesListView.java).
- Загрузчики: `vOperRepairDocFlowDl` → `ru.fgk.ws.app.dr.entity.VOperRepairDocFlow`.
- Текущие фильтры: `accountingTransferDate` GREATER_OR_EQUAL; `accountingTransferDate` LESS_OR_EQUAL; `diadocWagOperRepairContract.contractNumber` EQUAL; `repairType` EQUAL; `repairDepo.vrkCode` IN_LIST; `repairDateBeginFilter` JPQL(java.time.LocalDate); `repairDateEndFilter` JPQL(java.time.LocalDate); `repairRailway` EQUAL; `repairDepo` EQUAL; `jpqlFilterWnList` JPQL(ru.fgk.ws.app.wagons.entity.WnList); `jpqlFilterRepairList` JPQL(ru.fgk.ws.app.repair.entity.RepairList); `diadocWagOperRepairContract.messageId` EQUAL; `warrantyRepair` EQUAL; `repairCostFilter` JPQL(java.lang.Boolean); `docStatusFilter` JPQL(java.lang.Boolean).
- Прочие поля ввода для проверки: `accountingTransferDateBeginDatePicker`, `accountingTransferDateEndDatePicker`, `repairTypeSelect`, `vrkEnumComboBox`, `repairDateBeginDatePicker`, `repairDateEndDatePicker`, `repairCostCheckbox`, `docStatusCheckbox`.
- Особенности: JPQL: типы/joins; ссылка на entity.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 149](../../app/src/main/java/ru/fgk/ws/app/dr/view/drexportfiles/DrExportFilesListView.java) `accountingTransferDateBeginDatePicker.setValue(endDate.withDayOfMonth(1));`, [строка 150](../../app/src/main/java/ru/fgk/ws/app/dr/view/drexportfiles/DrExportFilesListView.java) `accountingTransferDateEndDatePicker.setValue(endDate);`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [DrOperFileRole.java](../../app/src/main/java/ru/fgk/ws/app/dr/security/DrOperFileRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M046. Экспорт документов по ТР-1 — `dr_ExportTr1Files.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/drexporttr1files/dr-export-tr1-files-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/drexporttr1files/DrExportTr1FilesListView.java).
- Загрузчики: `drExportTr1FilesDl` → `ru.fgk.ws.app.dr.entity.DrDiadocOperRepairTr1`.
- Текущие фильтры: `avrDate` GREATER_OR_EQUAL; `avrDate` LESS_OR_EQUAL; `contractNumber` EQUAL; `depo.vrkCode` IN_LIST; `depo.railway` EQUAL.
- Прочие поля ввода для проверки: `avrDateBeginPicker`, `avrDateEndPicker`, `vrkEnumComboBox`.
- Особенности: ссылка на entity.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M047. Контроль сроков оплаты — `dr_PlanRepairControlDate.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/planrepaircontroldate/plan-repair-control-date-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/planrepaircontroldate/PlanRepairControlDateListView.java).
- Загрузчики: `vWagPlanRepairContractsDl` → `ru.fgk.ws.app.dr.entity.VWagPlanRepairContract`.
- Текущие фильтры: `repairDate` GREATER_OR_EQUAL; `repairDate` LESS_OR_EQUAL; `drWagPlanRepairContractUser.accountingTransferDate` GREATER_OR_EQUAL; `drWagPlanRepairContractUser.accountingTransferDate` LESS_OR_EQUAL; `JPQL без id` JPQL(ru.fgk.ws.app.wagons.entity.WnList); `vRepair.repairDepoCode.vrkCode` IN_LIST.
- Прочие поля ввода для проверки: `reportDateBeginDatePicker`, `reportDateEndDatePicker`, `bughDateBeginDatePicker`, `bughDateEndDatePicker`, `vrkEnumComboBox`.
- Особенности: JPQL: типы/joins.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M048. Экспорт документов по плановым ремонтам — `dr_PlannedExportFiles.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/drplannedexportfiles/dr-planned-export-files-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/drplannedexportfiles/DrPlannedExportFilestListView.java).
- Загрузчики: `vWagPlanRepairContractsDl` → `ru.fgk.ws.app.dr.entity.VWagPlanRepairContract`.
- Текущие фильтры: `drWagPlanRepairContractUser.accountingTransferDate` GREATER_OR_EQUAL; `drWagPlanRepairContractUser.accountingTransferDate` LESS_OR_EQUAL; `diadocWagPlanRepairContract.contractNumber` EQUAL; `vRepair.repairType62` EQUAL; `vRepair.repairDepoCode.vrkCode` IN_LIST; `repairDateBeginFilter` JPQL(java.time.LocalDate); `repairDateEndFilter` JPQL(java.time.LocalDate); `vRepair.repairDepoCode.railway` EQUAL; `vRepair.repairDepoCode` EQUAL; `jpqlFilterWnList` JPQL(ru.fgk.ws.app.wagons.entity.WnList); `jpqlFilterRepairList` JPQL(ru.fgk.ws.app.repair.entity.RepairList); `diadocWagPlanRepairContract.messageId` EQUAL; `repairCostFilter` JPQL(java.lang.Boolean); `docStatusFilter` JPQL(java.lang.Boolean).
- Прочие поля ввода для проверки: `accountingTransferDateBeginDatePicker`, `accountingTransferDateEndDatePicker`, `repairTypeSelect`, `vrkEnumComboBox`, `repairDateBeginDatePicker`, `repairDateEndDatePicker`, `repairCostCheckbox`, `docStatusCheckbox`.
- Особенности: JPQL: типы/joins; ссылка на entity.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 185](../../app/src/main/java/ru/fgk/ws/app/dr/view/drplannedexportfiles/DrPlannedExportFilestListView.java) `accountingTransferDateBeginDatePicker.setValue(endDate.withDayOfMonth(1));`, [строка 186](../../app/src/main/java/ru/fgk/ws/app/dr/view/drplannedexportfiles/DrPlannedExportFilestListView.java) `accountingTransferDateEndDatePicker.setValue(endDate);`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [DrPlannedRepairAcceptanceRole.java](../../app/src/main/java/ru/fgk/ws/app/dr/security/DrPlannedRepairAcceptanceRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M049. Технологические ремонты — `dr_TechOperRepairContract.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/techoperrepaircontract/tech-oper-repair-contract-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/techoperrepaircontract/TechOperRepairContractListView.java).
- Загрузчики: `techOperRepairContractsDl` → `ru.fgk.ws.app.dr.entity.VWagOperRepairContract`.
- Текущие фильтры: genericFilter `genericFilter` — каталог [{"include": ".*"}].
- Прочие поля ввода для проверки: `repairDateFromDatePicker`, `repairDateToDatePicker`.
- Особенности: genericFilter: каталог/операции/AND-OR; динамические параметры/условия.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 97](../../app/src/main/java/ru/fgk/ws/app/dr/view/techoperrepaircontract/TechOperRepairContractListView.java) `techOperRepairContractsDl.setParameter("techDefectReason", DefectLiability.TECHN);`, [строка 101](../../app/src/main/java/ru/fgk/ws/app/dr/view/techoperrepaircontract/TechOperRepairContractListView.java) `techOperRepairContractsDl.setParameter("repairDateFrom", from.atStartOfDay());`, [строка 108](../../app/src/main/java/ru/fgk/ws/app/dr/view/techoperrepaircontract/TechOperRepairContractListView.java) `techOperRepairContractsDl.setParameter("repairDateTo", to.plusDays(1).atStartOfDay());`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M050. Оплата ТР по вагонам — `dr_VOperRepairDocFlow.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/voperrepairdocflow/v-oper-repair-doc-flow-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/voperrepairdocflow/VOperRepairDocFlowListView.java).
- Загрузчики: `reportOperRepairDocFlowShortDl` → `ru.fgk.ws.app.dr.entity.VOperRepairDocFlow`.
- Текущие фильтры: `reportDate` GREATER_OR_EQUAL; `reportDate` LESS_OR_EQUAL.
- Прочие поля ввода для проверки: `reportDateBeginDatePicker`, `reportDateEndDatePicker`.
- Особенности: динамические параметры/условия.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 74](../../app/src/main/java/ru/fgk/ws/app/dr/view/voperrepairdocflow/VOperRepairDocFlowListView.java) `reportDateEndDatePicker.setValue(endDate);`, [строка 75](../../app/src/main/java/ru/fgk/ws/app/dr/view/voperrepairdocflow/VOperRepairDocFlowListView.java) `reportDateBeginDatePicker.setValue(endDate.withDayOfMonth(1));`, [строка 95](../../app/src/main/java/ru/fgk/ws/app/dr/view/voperrepairdocflow/VOperRepairDocFlowListView.java) `this.reportDateBeginDatePicker.setValue(this.outParams.getDateBegin());`, [строка 96](../../app/src/main/java/ru/fgk/ws/app/dr/view/voperrepairdocflow/VOperRepairDocFlowListView.java) `this.reportDateEndDatePicker.setValue(this.outParams.getDateEnd());`, [строка 98](../../app/src/main/java/ru/fgk/ws/app/dr/view/voperrepairdocflow/VOperRepairDocFlowListView.java) `this.reportOperRepairDocFlowShortDl.setParameter("prCountry", outParams.getPrCountry());`, [строка 99](../../app/src/main/java/ru/fgk/ws/app/dr/view/voperrepairdocflow/VOperRepairDocFlowListView.java) `this.reportOperRepairDocFlowShortDl.setParameter("prVrk", outParams.getPrVrk());` Остальные места перечислены в JSON.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M051. Оплата ТР по вагонам — `dr_VOperRepairDocFlowFull.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/voperrepairdocflow/v-oper-repair-doc-flow-full-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/voperrepairdocflow/VOperRepairDocFlowFullListView.java).
- Загрузчики: `reportOperRepairDocFlowFullDl` → `ru.fgk.ws.app.dr.entity.VOperRepairDocFlow`.
- Текущие фильтры: `reportDate` GREATER_OR_EQUAL; `reportDate` LESS_OR_EQUAL; `repairType` EQUAL; `defectReason` EQUAL; `warrantyRepair` EQUAL; `JPQL без id` JPQL(ru.fgk.ws.app.wagons.entity.WnList); `prCountry` EQUAL; `repairDepo.vrkCode` IN_LIST; `repairRailway` EQUAL; `repairDepo` EQUAL; `diadocWagOperRepairContract.contract` EQUAL; `stateSf` EQUAL; `stateForpay` EQUAL; `stateDoc` EQUAL; `stateChecked` EQUAL; `stateAccepted` EQUAL; `stateDbn` EQUAL; `state1c` EQUAL; `stateBad` EQUAL.
- Прочие поля ввода для проверки: `reportDateBeginDatePicker`, `reportDateEndDatePicker`, `repairTypeSelect`, `prcountrySelect`, `vrkEnumComboBox`, `stateSfCombo`, `stateForpayCombo`, `stateDocCombo`, `stateCheckedCombo`, `stateAcceptCombo`, `stateDbnCombo`, `state1cCombo`, `stateBadCombo`.
- Особенности: JPQL: типы/joins; ссылка на entity.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 119](../../app/src/main/java/ru/fgk/ws/app/dr/view/voperrepairdocflow/VOperRepairDocFlowFullListView.java) `reportDateEndDatePicker.setValue(endDate);`, [строка 120](../../app/src/main/java/ru/fgk/ws/app/dr/view/voperrepairdocflow/VOperRepairDocFlowFullListView.java) `reportDateBeginDatePicker.setValue(endDate.withDayOfMonth(1));`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M052. Вагоны ТР не в оплате — `dr_VOperRepairDocFlowNo.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/voperrepairdocflowno/v-oper-repair-doc-flow-no-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/voperrepairdocflowno/VOperRepairDocFlowNoListView.java).
- Загрузчики: `vDepoDl` → `ru.fgk.ws.app.nsi.entity.VDepo`; `vRailwaysDl` → `ru.fgk.ws.app.nsi.entity.VRailway`; `vOperRepairDocFlowNoesDl` → `ru.fgk.ws.app.dr.entity.VOperRepairDocFlowNo`.
- Текущие фильтры: `reportDate` GREATER_OR_EQUAL; `reportDate` LESS_OR_EQUAL; `repairTypeAbs` EQUAL; `defectReason` EQUAL; `warrantyRepair` EQUAL; `wagnum` EQUAL; `prCountry` EQUAL; `repairDepo.vrkCode` IN_LIST; `repairDepo.railway` EQUAL; `repairDepo` EQUAL.
- Прочие поля ввода для проверки: `reportDateBeginDatePicker`, `reportDateEndDatePicker`, `repairTypeSelect`, `warrantyRepairSelect`, `wagNumFiltr`, `prcountrySelect`, `vrkEnumComboBox`, `railwaySelect`, `depoSelect`.
- Особенности: ссылка на entity; тип через metadata.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 92](../../app/src/main/java/ru/fgk/ws/app/dr/view/voperrepairdocflowno/VOperRepairDocFlowNoListView.java) `reportDateEndDatePicker.setValue(endDate);`, [строка 93](../../app/src/main/java/ru/fgk/ws/app/dr/view/voperrepairdocflowno/VOperRepairDocFlowNoListView.java) `reportDateBeginDatePicker.setValue(endDate.withDayOfMonth(1));`, [строка 134](../../app/src/main/java/ru/fgk/ws/app/dr/view/voperrepairdocflowno/VOperRepairDocFlowNoListView.java) `this.reportDateBeginDatePicker.setValue(dateBegin);`, [строка 135](../../app/src/main/java/ru/fgk/ws/app/dr/view/voperrepairdocflowno/VOperRepairDocFlowNoListView.java) `this.reportDateEndDatePicker.setValue(dateEnd);`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M053. Оплата ТР-1 по вагонам — `dr_VTr1RepairDocFlow.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/voperrepairdocflow/v-tr1-repair-doc-flow-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/voperrepairdocflow/VTr1RepairDocFlowListView.java).
- Загрузчики: `reportOperRepairDocFlowFullDl` → `ru.fgk.ws.app.dr.entity.VOperRepairDocFlowWithHist`.
- Текущие фильтры: `reportDate` GREATER_OR_EQUAL; `reportDate` LESS_OR_EQUAL; `JPQL без id` JPQL(ru.fgk.ws.app.wagons.entity.WnList); `repairDepo.vrkCode` IN_LIST; `repairRailway` EQUAL; `repairDepo` EQUAL.
- Прочие поля ввода для проверки: `reportDateBeginDatePicker`, `reportDateEndDatePicker`, `vrkEnumComboBox`, `downtimeCb`, `checkCb`, `accCb`, `req1cCb`.
- Особенности: JPQL: типы/joins; ссылка на entity.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 131](../../app/src/main/java/ru/fgk/ws/app/dr/view/voperrepairdocflow/VTr1RepairDocFlowListView.java) `reportDateEndDatePicker.setValue(endDate);`, [строка 132](../../app/src/main/java/ru/fgk/ws/app/dr/view/voperrepairdocflow/VTr1RepairDocFlowListView.java) `reportDateBeginDatePicker.setValue(endDate.withDayOfMonth(1));`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M054. Простой в ТР по вагонам — `dr_VWagOperRepairContract.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/vwagoperrepaircontract/v-wag-oper-repair-contract-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/vwagoperrepaircontract/VWagOperRepairContractListView.java).
- Загрузчики: `vWagOperRepairContractsDl` → `ru.fgk.ws.app.dr.entity.VWagOperRepairContract`.
- Текущие фильтры: `reportDate` GREATER_OR_EQUAL; `reportDate` LESS_OR_EQUAL; `repairAbdpvArch.repairType62` EQUAL; `operRepair.subjectToClaim` EQUAL; `warrantyRepair` EQUAL; `JPQL без id` JPQL(ru.fgk.ws.app.nsi.entity.VrkEnum); `JPQL без id` JPQL(java.lang.Integer); `JPQL без id` JPQL(ru.fgk.ws.app.wagons.entity.WnList); `operRepair.claimNumber` EQUAL.
- Прочие поля ввода для проверки: `reportDateFromDatePicker`, `reportDateToDatePicker`, `repairType62Select`, `subjectToClaimSelect`, `vrkSelect`, `vRailwaysComboBox`.
- Особенности: JPQL: типы/joins; динамические параметры/условия.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 132](../../app/src/main/java/ru/fgk/ws/app/dr/view/vwagoperrepaircontract/VWagOperRepairContractListView.java) `vWagOperRepairContractsDl.setParameter("operRepairPreClaimList", operRepairPreClaimList);`, [строка 176](../../app/src/main/java/ru/fgk/ws/app/dr/view/vwagoperrepaircontract/VWagOperRepairContractListView.java) `reportDateFromDatePicker.setValue(prevMonth.withDayOfMonth(1));`, [строка 177](../../app/src/main/java/ru/fgk/ws/app/dr/view/vwagoperrepaircontract/VWagOperRepairContractListView.java) `reportDateToDatePicker.setValue(prevMonth.withDayOfMonth(prevMonth.lengthOfMonth()));`, [строка 178](../../app/src/main/java/ru/fgk/ws/app/dr/view/vwagoperrepaircontract/VWagOperRepairContractListView.java) `subjectToClaimFilter.setValue(true);`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [DepsRole.java](../../app/src/main/java/ru/fgk/ws/app/dr/security/DepsRole.java), [LawRole.java](../../app/src/main/java/ru/fgk/ws/app/dr/security/LawRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M055. Список нормативов расчета неустойки — `dt_OperRepairNorms.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dt/view/dtoperrepairnorms/dt-oper-repair-norms-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dt/view/dtoperrepairnorms/DtOperRepairNormsListView.java).
- Загрузчики: `repairNormsDl` → `ru.fgk.ws.app.dt.entity.DtOperRepairNorms`.
- Текущие фильтры: `normActiveDateFilter` JPQL(java.time.LocalDate); `repairType` EQUAL.
- Прочие поля ввода для проверки: `counterAgentFilter`.
- Особенности: JPQL: типы/joins; динамические параметры/условия.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 84](../../app/src/main/java/ru/fgk/ws/app/dt/view/dtoperrepairnorms/DtOperRepairNormsListView.java) `normActiveDateFilter.setValue(normActiveDate);`, [строка 106](../../app/src/main/java/ru/fgk/ws/app/dt/view/dtoperrepairnorms/DtOperRepairNormsListView.java) `repairNormsDl.setParameter("vrkCode", counterAgent.getVrk().getId());`, [строка 108](../../app/src/main/java/ru/fgk/ws/app/dt/view/dtoperrepairnorms/DtOperRepairNormsListView.java) `repairNormsDl.setParameter("depo", counterAgent.getDepo());`, [строка 110](../../app/src/main/java/ru/fgk/ws/app/dt/view/dtoperrepairnorms/DtOperRepairNormsListView.java) `repairNormsDl.setParameter("railway", counterAgent.getRailway());`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

## Волна 7. Пакеты, делегаты и специальные контексты

### M056. Акт приемки исполненных обязательств — `DrContractOperRepairUser`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/dr-contract-oper-repair-user-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/DrContractOperRepairUserView.java).
- Загрузчики: `vWagOperRepairContractActsDl` → `ru.fgk.ws.app.dr.entity.VWagOperRepairContractAct`.
- Текущие фильтры: `wagnum` EQUAL.
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: динамические параметры/условия.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 173](../../app/src/main/java/ru/fgk/ws/app/dr/view/DrContractOperRepairUserView.java) `vWagOperRepairContractActsDl.setParameter("drcontractId", getEditedEntity().getId());`, [строка 174](../../app/src/main/java/ru/fgk/ws/app/dr/view/DrContractOperRepairUserView.java) `vWagOperRepairContractActsDl.setParameter("actDateBegin", actDateBegin);`, [строка 175](../../app/src/main/java/ru/fgk/ws/app/dr/view/DrContractOperRepairUserView.java) `vWagOperRepairContractActsDl.setParameter("actDateEnd", actDateEnd);`, [строка 176](../../app/src/main/java/ru/fgk/ws/app/dr/view/DrContractOperRepairUserView.java) `vWagOperRepairContractActsDl.setParameter("date1CBegin", date1CBegin);`, [строка 177](../../app/src/main/java/ru/fgk/ws/app/dr/view/DrContractOperRepairUserView.java) `vWagOperRepairContractActsDl.setParameter("date1CEnd", date1CEnd);`, [строка 179](../../app/src/main/java/ru/fgk/ws/app/dr/view/DrContractOperRepairUserView.java) `vWagOperRepairContractActsDl.setParameter("warrantyRepair", warrantyRepair);` Остальные места перечислены в JSON.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M057. Акт приемки исполненных обязательств — `DrContractPlanRepairUserView.detail`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/dr-contract-plan-repair-user-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/DrContractPlanRepairUserView.java).
- Загрузчики: `vWagPlanRepairContractActsDl` → `ru.fgk.ws.app.dr.entity.VWagPlanRepairContractAct`.
- Текущие фильтры: `wagnum` EQUAL.
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: динамические параметры/условия.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 167](../../app/src/main/java/ru/fgk/ws/app/dr/view/DrContractPlanRepairUserView.java) `vWagPlanRepairContractActsDl.setParameter("drcontractId", getEditedEntity().getId());`, [строка 168](../../app/src/main/java/ru/fgk/ws/app/dr/view/DrContractPlanRepairUserView.java) `vWagPlanRepairContractActsDl.setParameter("actDateBegin", actDateBegin);`, [строка 169](../../app/src/main/java/ru/fgk/ws/app/dr/view/DrContractPlanRepairUserView.java) `vWagPlanRepairContractActsDl.setParameter("actDateEnd", actDateEnd);`, [строка 170](../../app/src/main/java/ru/fgk/ws/app/dr/view/DrContractPlanRepairUserView.java) `vWagPlanRepairContractActsDl.setParameter("date1CBegin", date1CBegin);`, [строка 171](../../app/src/main/java/ru/fgk/ws/app/dr/view/DrContractPlanRepairUserView.java) `vWagPlanRepairContractActsDl.setParameter("date1CEnd", date1CEnd);`, [строка 172](../../app/src/main/java/ru/fgk/ws/app/dr/view/DrContractPlanRepairUserView.java) `vWagPlanRepairContractActsDl.setParameter("nullableActsInclude", nullableActsInclude);` Остальные места перечислены в JSON.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M058. Настройки обработки — `NvProcessingSettings.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/nvprocessingsettings/nv-processing-settings-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/nvprocessingsettings/NvProcessingSettingsListView.java).
- Загрузчики: `nvProcessingSettingsDl` → `ru.fgk.ws.app.asuvrk.entity.NvProcessingSettings`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: `nameFilterField`, `codeFilterField`.
- Особенности: delegate/PreLoad; дерево; нестандартные фильтры.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M059. Учет ремонта деталей — `PtRepairClaimItem.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/pt/view/ptrepairclaimitem/pt-repair-claim-item-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptrepairclaimitem/PtRepairClaimItemListView.java).
- Загрузчики: `ptRepairClaimItemsDl` → `ru.fgk.ws.app.pt.entity.PtRepairClaimItem`; `vRailwayDl` → `ru.fgk.ws.app.nsi.entity.VRailway`; `contractDl` → `ru.fgk.ws.app.pt.entity.PtRepairContract`; `depoDl` → `ru.fgk.ws.app.nsi.entity.VDepo`; `partTypeDl` → `ru.fgk.ws.app.nsi.entity.NvPartType`.
- Текущие фильтры: `dateFromFilter` JPQL(java.time.LocalDate); `dateToFilter` JPQL(java.time.LocalDate); `fixDetailFactory` EQUAL; `fixDetailNumber` EQUAL; `fixDetailYear` EQUAL; `fixDetailUid` IN_LIST; `claim.depoRepair.railway` EQUAL; `partType` IN_LIST; `claim.depoRepair` EQUAL; `claim.contract` EQUAL.
- Прочие поля ввода для проверки: `ptNumberFactoryFilter`, `ptNumberNumberFilter`, `ptNumberYearFilter`, `repairRwComboBox`, `vrkComboBox`, `contractComboBox`, `checkboxFrosen`.
- Особенности: JPQL: типы/joins; ссылка на entity.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 135](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptrepairclaimitem/PtRepairClaimItemListView.java) `checkboxFrosen.setValue(true);`, [строка 140](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptrepairclaimitem/PtRepairClaimItemListView.java) `dateFromFilter.setValue(timeSource.now().toLocalDate().withDayOfMonth(1).minusMonths(1));`, [строка 141](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptrepairclaimitem/PtRepairClaimItemListView.java) `dateToFilter.setValue(timeSource.now().toLocalDate());`, [строка 171](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptrepairclaimitem/PtRepairClaimItemListView.java) `partTypeFilter.setValue(new ArrayList<>());`, [строка 181](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptrepairclaimitem/PtRepairClaimItemListView.java) `partTypeFilter.setValue(nvPartTypes);`, [строка 207](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptrepairclaimitem/PtRepairClaimItemListView.java) `detailFactoryFilter.setValue(ptNumberFactoryFilter.getTypedValue());` Остальные места перечислены в JSON.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M060. Пакеты по ремонту деталей — `PtRepairPacket.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/pt/view/ptrepairpacket/pt-repair-packet-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptrepairpacket/PtRepairPacketListView.java).
- Загрузчики: `ptRepairPacketsDl` → `ru.fgk.ws.app.pt.entity.PtRepairPacket`; `nvPartTypesDl` → `ru.fgk.ws.app.nsi.entity.NvPartType`.
- Текущие фильтры: `date` GREATER_OR_EQUAL; `date` LESS_OR_EQUAL; `contract` EQUAL; `depo.railway` EQUAL; `diadocStatusFilter` JPQL(java.lang.Integer); `accountingTransferFilter` JPQL(java.lang.Boolean); `id` EQUAL; `torId` EQUAL.
- Прочие поля ввода для проверки: `reportDateFromDatePicker`, `reportDateToDatePicker`, `diadocStatusFilterField`, `accountingTransferFilterField`, `entityIdField`.
- Особенности: JPQL: типы/joins; ссылка на entity; delegate/PreLoad; динамические параметры/условия.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 148](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptrepairpacket/PtRepairPacketListView.java) `sendDateFromFilter.setValue(dateFrom);`, [строка 179](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptrepairpacket/PtRepairPacketListView.java) `query.setCondition(customConditions);`, [строка 186](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptrepairpacket/PtRepairPacketListView.java) `query.setCondition(combinedCondition);`, [строка 341](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptrepairpacket/PtRepairPacketListView.java) `diadocStatusFilter.setCondition(`, [строка 378](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptrepairpacket/PtRepairPacketListView.java) `.ifPresent(value -> railwayFilter.setValue(loadRailway(value)));`, [строка 383](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptrepairpacket/PtRepairPacketListView.java) `.ifPresent(value -> diadocStatusFilter.setValue(parseDiadocStatuses(value)));` Остальные места перечислены в JSON.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M061. Очередь запросов по деталям в ЕО — `RequestInform.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/pt/view/requestinform/request-inform-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/pt/view/requestinform/RequestInformListView.java).
- Загрузчики: `requestInformsDl` → `ru.fgk.ws.app.pt.entity.RequestInform`; `requestInformStatisticsDl` → `property-bound/KeyValue`.
- Текущие фильтры: genericFilter `genericFilter` — каталог [{"include": ".*"}]; `status` IN_LIST; `detailNumber` EQUAL; `requestCode` EQUAL; `insUser` EQUAL.
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: genericFilter: каталог/операции/AND-OR; тип через metadata; динамические параметры/условия.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 71](../../app/src/main/java/ru/fgk/ws/app/pt/view/requestinform/RequestInformListView.java) `requestInformStatisticsDl.setParameter("nullDate", null);`, [строка 72](../../app/src/main/java/ru/fgk/ws/app/pt/view/requestinform/RequestInformListView.java) `requestInformStatisticsDl.setParameter("today", LocalDate.now());`, [строка 73](../../app/src/main/java/ru/fgk/ws/app/pt/view/requestinform/RequestInformListView.java) `requestInformStatisticsDl.setParameter("yesterday", LocalDate.now().minusDays(1));`, [строка 89](../../app/src/main/java/ru/fgk/ws/app/pt/view/requestinform/RequestInformListView.java) `statusFilter.setValue(RequestInformStatusFilter.QUEUED);`
- Роли (включая наследование исходных resource roles): [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [PtContractWriteRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractWriteRole.java), [PtContractReadRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractReadRole.java), [WnBaseRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WnBaseRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M062. Справочник работ по ремонту деталей — `VNvPartRepairWork.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/view/vnvpartrepairwork/v-nv-part-repair-work-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/view/vnvpartrepairwork/VNvPartRepairWorkListView.java).
- Загрузчики: `vNvPartRepairWorksDl` → `ru.fgk.ws.app.pt.entity.VNvPartRepairWork`.
- Текущие фильтры: `workCode` EQUAL; `workName` CONTAINS; `partType` EQUAL; `wsForm` EQUAL; `wsRepair` EQUAL.
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: ссылка на entity.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [PtContractWriteRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractWriteRole.java), [PtContractReadRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractReadRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M063. Фоновая задача — `common_BackgroundJobTask.detail`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/common/view/backgroundjob/background-job-task-detail-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/common/view/backgroundjob/BackgroundJobTaskDetailView.java).
- Загрузчики: `logsDl` → `ru.fgk.ws.app.common.entity.BackgroundJobLog`.
- Текущие фильтры: `level` EQUAL.
- Прочие поля ввода для проверки: `progressField`.
- Особенности: динамические параметры/условия.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 261](../../app/src/main/java/ru/fgk/ws/app/common/view/backgroundjob/BackgroundJobTaskDetailView.java) `progressField.setValue(current + " / " + total);`, [строка 263](../../app/src/main/java/ru/fgk/ws/app/common/view/backgroundjob/BackgroundJobTaskDetailView.java) `progressField.setValue(String.valueOf(current));`, [строка 265](../../app/src/main/java/ru/fgk/ws/app/common/view/backgroundjob/BackgroundJobTaskDetailView.java) `progressField.setValue("");`, [строка 283](../../app/src/main/java/ru/fgk/ws/app/common/view/backgroundjob/BackgroundJobTaskDetailView.java) `logsDl.setParameter("taskId", taskId);`, [строка 284](../../app/src/main/java/ru/fgk/ws/app/common/view/backgroundjob/BackgroundJobTaskDetailView.java) `logsDl.setParameter("currentUser", getCurrentUsername());`, [строка 366](../../app/src/main/java/ru/fgk/ws/app/common/view/backgroundjob/BackgroundJobTaskDetailView.java) `logLevelFilter.setValue(currentLevel == targetLevel ? null : targetLevel);`
- Роли (включая наследование исходных resource roles): [BackgroundJobsRole.java](../../app/src/main/java/ru/fgk/ws/app/security/BackgroundJobsRole.java), [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [DrOperFileRole.java](../../app/src/main/java/ru/fgk/ws/app/dr/security/DrOperFileRole.java), [DrPlannedRepairAcceptanceRole.java](../../app/src/main/java/ru/fgk/ws/app/dr/security/DrPlannedRepairAcceptanceRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M064. Журнал рассылки по выпуску из НРП — `da_NsiMailSendLog.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/da/view/notice/nsi-mail-send-log-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/da/view/notice/NsiMailSendLogListView.java).
- Загрузчики: `nsiMailSendLogDl` → `ru.fgk.ws.app.da.notice.entity.NsiMailSendLog`.
- Текущие фильтры: `noticeMail.email` CONTAINS; `status` EQUAL.
- Прочие поля ввода для проверки: `dateFromPicker`, `dateToPicker`, `onlyErrorsCheckbox`.
- Особенности: delegate/PreLoad; динамические параметры/условия.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 108](../../app/src/main/java/ru/fgk/ws/app/da/view/notice/NsiMailSendLogListView.java) `dateFromPicker.setValue(LocalDate.now().minusDays(1));`, [строка 184](../../app/src/main/java/ru/fgk/ws/app/da/view/notice/NsiMailSendLogListView.java) `query.setCondition(combined);`, [строка 232](../../app/src/main/java/ru/fgk/ws/app/da/view/notice/NsiMailSendLogListView.java) `textArea.setValue(errorMessage);`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M065. Заявки на ремонт — `da_RepairClaim.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/da/view/repairclaim/repair-claim-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/da/view/repairclaim/RepairClaimListView.java).
- Загрузчики: `repairClaimsDl` → `ru.fgk.ws.app.da.entity.RepairClaim`; `vCountriesDl` → `ru.fgk.ws.app.nsi.entity.VCountry`.
- Текущие фильтры: genericFilter `genericFilter` — каталог [{"include": ".*"}]; `sendDateFromFilter` JPQL(java.time.LocalDate); `sendDateToFilter` JPQL(java.time.LocalDate); `country` EQUAL; `sendStatus` EQUAL; `JPQL без id` JPQL(ru.fgk.ws.app.wagons.entity.WnList).
- Прочие поля ввода для проверки: `sendDateFromDatePicker`, `sendDateToDatePicker`, `countryComboBox`.
- Особенности: genericFilter: каталог/операции/AND-OR; JPQL: типы/joins; ссылка на entity; delegate/PreLoad.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 95](../../app/src/main/java/ru/fgk/ws/app/da/view/repairclaim/RepairClaimListView.java) `sendDateFromFilter.setValue(now.minusDays(DATE_FROM_FILTER_MINUS_DAYS));`, [строка 96](../../app/src/main/java/ru/fgk/ws/app/da/view/repairclaim/RepairClaimListView.java) `sendDateToFilter.setValue(now);`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [DaRepairClaimRole.java](../../app/src/main/java/ru/fgk/ws/app/da/security/DaRepairClaimRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M066. Архив рассылки по выпуску из НРП — `da_RepairNoticeArchive.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/da/view/notice/repair-notice-archive-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/da/view/notice/RepairNoticeArchiveListView.java).
- Загрузчики: `archiveDl` → `ru.fgk.ws.app.da.notice.entity.VRepairNoticeArchive`; `railwaysDl` → `ru.fgk.ws.app.nsi.entity.VRailway`.
- Текущие фильтры: `railway` EQUAL; `wnListFilter` JPQL(ru.fgk.ws.app.wagons.entity.WnList).
- Прочие поля ввода для проверки: `sendDateFromPicker`, `sendDateToPicker`.
- Особенности: JPQL: типы/joins; ссылка на entity; delegate/PreLoad; динамические параметры/условия.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 66](../../app/src/main/java/ru/fgk/ws/app/da/view/notice/RepairNoticeArchiveListView.java) `sendDateFromPicker.setValue(LocalDate.now().minusDays(1));`, [строка 90](../../app/src/main/java/ru/fgk/ws/app/da/view/notice/RepairNoticeArchiveListView.java) `query.setCondition(combined);`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M067. Пакеты документов Диадок — `diadoc_DiadocPacket.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/diadoc/view/diadocpacket/diadoc-packet-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/diadoc/view/diadocpacket/DiadocPacketListView.java).
- Загрузчики: `packetDocumentsDl` → `ru.fgk.ws.app.diadoc.entity.DiadocPacket`.
- Текущие фильтры: `id` EQUAL; `operationsFirstAt` GREATER_OR_EQUAL; `operationsFirstAt` LESS_OR_EQUAL; `depoCode` EQUAL; `JPQL без id` JPQL(java.lang.Integer); `wagnum` EQUAL; `documentType` EQUAL.
- Прочие поля ввода для проверки: `entityIdField`, `torIdField`, `operationsFirstAtFromDatePicker`, `operationsFirstAtToDatePicker`, `vDepoEntityPicker`, `contractorFilterSelect`, `mainSignatureTypeFilterField`.
- Особенности: JPQL: типы/joins; delegate/PreLoad; динамические параметры/условия.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 148](../../app/src/main/java/ru/fgk/ws/app/diadoc/view/diadocpacket/DiadocPacketListView.java) `depoCodeFilter.setValue(depoCode);`, [строка 160](../../app/src/main/java/ru/fgk/ws/app/diadoc/view/diadocpacket/DiadocPacketListView.java) `vDepoEntityPicker.setValue(vDepo);`, [строка 219](../../app/src/main/java/ru/fgk/ws/app/diadoc/view/diadocpacket/DiadocPacketListView.java) `query.setCondition(customConditions);`, [строка 226](../../app/src/main/java/ru/fgk/ws/app/diadoc/view/diadocpacket/DiadocPacketListView.java) `query.setCondition(combinedCondition);`
- Роли (включая наследование исходных resource roles): [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [DiadocShowPacketDocumentsRole.java](../../app/src/main/java/ru/fgk/ws/app/security/diadoc/DiadocShowPacketDocumentsRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M068. Подписание — `diadoc_DiadocSigning.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/diadoc/view/signing/diadoc-signing-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/diadoc/view/signing/DiadocSigningListView.java).
- Загрузчики: `packetFlowsDl` → `ru.fgk.ws.app.diadoc.entity.PacketFlow`; `contractorsDl` → `ru.fgk.ws.app.nsi.entity.DiadocContractor`; `depoDl` → `ru.fgk.ws.app.nsi.entity.VDepo`; `vRailwayDl` → `ru.fgk.ws.app.nsi.entity.VRailway`.
- Текущие фильтры: `source` EQUAL; `packetDocument.documentType` IN_LIST; `status` IN_LIST; `packetDocument.mainSignatureType` EQUAL; `packetDocument.contractor.id` IN_LIST; `packetDocument.depoRef` IN_LIST; `packetDocument.depoRef.railway` IN_LIST.
- Прочие поля ввода для проверки: `packetTypeComboBox`, `contractorComboBox`.
- Особенности: ссылка на entity; delegate/PreLoad.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [DiadocPtSignRole.java](../../app/src/main/java/ru/fgk/ws/app/security/diadoc/DiadocPtSignRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M069. Пакеты МХ-1 — `dr_DiadocOperRepairPacket.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/drdiadocoperrepairpacket/dr-diadoc-oper-repair-packet-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/drdiadocoperrepairpacket/DrDiadocOperRepairPacketListView.java).
- Загрузчики: `drDiadocOperRepairPacketsDl` → `ru.fgk.ws.app.dr.entity.DrDiadocOperRepairPacket`.
- Текущие фильтры: `packFirstGetDate` GREATER_OR_EQUAL; `packFirstGetDate` LESS_OR_EQUAL; `JPQL без id` JPQL(ru.fgk.ws.app.wagons.entity.WnList); `JPQL без id` JPQL(ru.fgk.ws.app.nsi.entity.VRailway); `acceptStatusFilter` JPQL(ru.fgk.ws.app.pt.entity.AcceptStatus); `torId` EQUAL.
- Прочие поля ввода для проверки: `reportDateBeginDatePicker`, `reportDateEndDatePicker`.
- Особенности: JPQL: типы/joins; delegate/PreLoad.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 102](../../app/src/main/java/ru/fgk/ws/app/dr/view/drdiadocoperrepairpacket/DrDiadocOperRepairPacketListView.java) `reportDateEndFilter.setValue(timeSource.now().toLocalDate());`, [строка 103](../../app/src/main/java/ru/fgk/ws/app/dr/view/drdiadocoperrepairpacket/DrDiadocOperRepairPacketListView.java) `reportDateBeginFilter.setValue(timeSource.now().minusDays(10).toLocalDate());`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M070. Пакеты Хранение и Ремпригодность — `dr_DiadocOperRepairPacketMaintainability.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/drdiadocoperrepairpacket/dr-diadoc-oper-repair-packet-maintainability-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/drdiadocoperrepairpacket/DrDiadocOperRepairPacketMaintainabilityListView.java).
- Загрузчики: `drDiadocOperRepairPacketsDl` → `ru.fgk.ws.app.dr.entity.DrDiadocOperRepairPacket`.
- Текущие фильтры: `packetDocumentType` IN_LIST; `packFirstGetDate` GREATER_OR_EQUAL; `packFirstGetDate` LESS_OR_EQUAL; `JPQL без id` JPQL(ru.fgk.ws.app.wagons.entity.WnList); `JPQL без id` JPQL(ru.fgk.ws.app.nsi.entity.VRailway); `acceptStatusFilter` JPQL(ru.fgk.ws.app.pt.entity.AcceptStatus); `torId` EQUAL.
- Прочие поля ввода для проверки: `packetTypeFilterPicker`, `reportDateBeginDatePicker`, `reportDateEndDatePicker`.
- Особенности: JPQL: типы/joins; delegate/PreLoad.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 112](../../app/src/main/java/ru/fgk/ws/app/dr/view/drdiadocoperrepairpacket/DrDiadocOperRepairPacketMaintainabilityListView.java) `reportDateEndFilter.setValue(timeSource.now().plusDays(1).minusSeconds(1).toLocalDateTime());`, [строка 113](../../app/src/main/java/ru/fgk/ws/app/dr/view/drdiadocoperrepairpacket/DrDiadocOperRepairPacketMaintainabilityListView.java) `reportDateBeginFilter.setValue(timeSource.now().minusDays(10).toLocalDate());`, [строка 115](../../app/src/main/java/ru/fgk/ws/app/dr/view/drdiadocoperrepairpacket/DrDiadocOperRepairPacketMaintainabilityListView.java) `packetTypeFilterPicker.setValue(MaintainabilityOrPartsPacketType.ALL);`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M071. Пакеты рекламаций — `dr_DiadocOperRepairPacketReclamation.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/drdiadocoperrepairpacket/dr-diadoc-oper-repair-packet-reclamation-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/drdiadocoperrepairpacket/DrDiadocOperRepairPacketReclamationListView.java).
- Загрузчики: `drDiadocOperRepairPacketsDl` → `ru.fgk.ws.app.dr.entity.DrDiadocOperRepairPacket`.
- Текущие фильтры: `dateout` GREATER_OR_EQUAL; `dateout` LESS_OR_EQUAL; `operationsFirstAt` GREATER_OR_EQUAL; `operationsFirstAt` LESS_OR_EQUAL; `depo.railway` EQUAL; `wagnumFilter` JPQL(ru.fgk.ws.app.wagons.entity.WnList); `torId` EQUAL.
- Прочие поля ввода для проверки: `reportDateFromDatePicker`, `reportDateToDatePicker`, `packFirstGetDateFromPicker`, `packFirstGetDateToPicker`.
- Особенности: JPQL: типы/joins; ссылка на entity; delegate/PreLoad.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 158](../../app/src/main/java/ru/fgk/ws/app/dr/view/drdiadocoperrepairpacket/DrDiadocOperRepairPacketReclamationListView.java) `packFirstGetDateFromFilter.setValue(timeSource.now().toLocalDate().minusDays(10));`, [строка 360](../../app/src/main/java/ru/fgk/ws/app/dr/view/drdiadocoperrepairpacket/DrDiadocOperRepairPacketReclamationListView.java) `textArea.setValue(selected.getPackCheckedText());`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M072. Пакеты ВУ-23 — `dr_DiadocOperRepairPacketVu23.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/drdiadocoperrepairpacket/dr-diadoc-oper-repair-packet-vu23-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/drdiadocoperrepairpacket/DrDiadocOperRepairPacketVu23ListView.java).
- Загрузчики: `drDiadocOperRepairPacketsDl` → `ru.fgk.ws.app.dr.entity.DrDiadocOperRepairPacket`.
- Текущие фильтры: `packFirstGetDate` GREATER_OR_EQUAL; `packFirstGetDate` LESS_OR_EQUAL; `JPQL без id` JPQL(ru.fgk.ws.app.wagons.entity.WnList); `JPQL без id` JPQL(ru.fgk.ws.app.nsi.entity.VRailway); `acceptStatusFilter` JPQL(ru.fgk.ws.app.pt.entity.AcceptStatus); `torId` EQUAL.
- Прочие поля ввода для проверки: `reportDateBeginDatePicker`, `reportDateEndDatePicker`.
- Особенности: JPQL: типы/joins; delegate/PreLoad.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 129](../../app/src/main/java/ru/fgk/ws/app/dr/view/drdiadocoperrepairpacket/DrDiadocOperRepairPacketVu23ListView.java) `reportDateEndFilter.setValue(timeSource.now().toLocalDate());`, [строка 130](../../app/src/main/java/ru/fgk/ws/app/dr/view/drdiadocoperrepairpacket/DrDiadocOperRepairPacketVu23ListView.java) `reportDateBeginFilter.setValue(timeSource.now().minusDays(10).toLocalDate());`, [строка 174](../../app/src/main/java/ru/fgk/ws/app/dr/view/drdiadocoperrepairpacket/DrDiadocOperRepairPacketVu23ListView.java) `textArea.setValue(selected.getPackCheckedText());`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M073. Diadoc wag oper repair contracts — `dr_DiadocWagOperRepairContract.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/diadoc/view/diadoc-wag-oper-repair-contract-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/diadoc/view/DiadocWagOperRepairContractListView.java).
- Загрузчики: `diadocWagOperRepairContractsDl` → `ru.fgk.ws.app.dr.entity.DiadocWagOperRepairContract`.
- Текущие фильтры: genericFilter `genericFilter` — каталог [{"include": ".*"}].
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: genericFilter: каталог/операции/AND-OR.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M074. Акты по ТР-1 — `dr_Tr1ActsListView`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/vwagoperrepaircontract/vwagoperrepaircontract/tr1-acts-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/vwagoperrepaircontract/vwagoperrepaircontract/Tr1ActsListView.java).
- Загрузчики: `vWagOperRepairContractTr1ActsDl` → `ru.fgk.ws.app.dr.entity.VDrWagOperRepairContractTr1Acts`.
- Текущие фильтры: `actDate` GREATER_OR_EQUAL; `actDate` LESS_OR_EQUAL.
- Прочие поля ввода для проверки: `reportDateBeginDatePicker`, `reportDateEndDatePicker`.
- Особенности: delegate/PreLoad.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M075. Остатки деталей по 1С — `pt_1cBalance.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/pt/view/pt1cbalance/pt1c-balance-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/pt/view/pt1cbalance/Pt1cBalanceListView.java).
- Загрузчики: `pt1cBalancesDl` → `ru.fgk.ws.app.pt.entity.Pt1cBalance`; `vRailwayDl` → `ru.fgk.ws.app.nsi.entity.VRailway`; `depoDl` → `ru.fgk.ws.app.nsi.entity.VDepo`; `partTypeDl` → `ru.fgk.ws.app.nsi.entity.NvPartType`.
- Текущие фильтры: genericFilter `genericFilter` — каталог [{"include": ".*"}]; `depo` EQUAL; `detailFactory` EQUAL; `detailNumber` EQUAL; `detailYear` EQUAL; `detailUid` IN_LIST; `depo.railway` EQUAL; `partType` IN_LIST; `JPQL без id` JPQL(ru.fgk.ws.app.pt.entity.PtList).
- Прочие поля ввода для проверки: `vrkComboBox`, `ptNumberFactoryFilter`, `ptNumberNumberFilter`, `ptNumberYearFilter`, `repairRwComboBox`.
- Особенности: genericFilter: каталог/операции/AND-OR; JPQL: типы/joins; ссылка на entity; динамические параметры/условия.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 120](../../app/src/main/java/ru/fgk/ws/app/pt/view/pt1cbalance/Pt1cBalanceListView.java) `pt1cBalancesDl.setQuery("select e from pt_1cBalance e where " + cellQuery.where());`, [строка 140](../../app/src/main/java/ru/fgk/ws/app/pt/view/pt1cbalance/Pt1cBalanceListView.java) `partTypeFilter.setValue(new ArrayList<>());`, [строка 150](../../app/src/main/java/ru/fgk/ws/app/pt/view/pt1cbalance/Pt1cBalanceListView.java) `partTypeFilter.setValue(nvPartTypes);`, [строка 181](../../app/src/main/java/ru/fgk/ws/app/pt/view/pt1cbalance/Pt1cBalanceListView.java) `detailFactoryFilter.setValue(ptNumberFactoryFilter.getTypedValue());`, [строка 192](../../app/src/main/java/ru/fgk/ws/app/pt/view/pt1cbalance/Pt1cBalanceListView.java) `detailNumberFilter.setValue(ptNumberNumberFilter.getTypedValue());`, [строка 203](../../app/src/main/java/ru/fgk/ws/app/pt/view/pt1cbalance/Pt1cBalanceListView.java) `detailYearFilter.setValue(ptNumberYearFilter.getTypedValue());` Остальные места перечислены в JSON.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M076. Добавить к списку — `pt_PtLists.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/pt/view/ptlist/pt-lists-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptlist/PtListsView.java).
- Загрузчики: `ptListsDl` → `ru.fgk.ws.app.pt.entity.PtList`.
- Текущие фильтры: `name` CONTAINS.
- Прочие поля ввода для проверки: `nameFilter`.
- Особенности: динамические параметры/условия.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 56](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptlist/PtListsView.java) `ptListsDl.setParameter("author", currentAuthentication.getUser().getUsername());`
- Роли (включая наследование исходных resource roles): [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [PtContractWriteRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractWriteRole.java), [PtContractReadRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractReadRole.java), [WnBaseRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WnBaseRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M077. Экспорт документов по ремонту деталей — `pt_PtRepairPacketExportFiles.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/pt/view/ptrepairpacketexportfiles/pt-repair-packet-export-files-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptrepairpacketexportfiles/PtRepairPacketExportFilesListView.java).
- Загрузчики: `ptRepairPacketsDl` → `ru.fgk.ws.app.pt.entity.PtRepairPacket`.
- Текущие фильтры: `fpu26ActDate` GREATER_OR_EQUAL; `fpu26ActDate` LESS_OR_EQUAL; `contract.number` EQUAL; `ptRepairPacketUserData.accountingTransferDate` GREATER_OR_EQUAL; `ptRepairPacketUserData.accountingTransferDate` LESS_OR_EQUAL; `fpu26ActNumberFilter` JPQL(java.lang.Boolean).
- Прочие поля ввода для проверки: `fpu26ActDateFromDatePicker`, `fpu26ActDateToDatePicker`, `transferToAccountingDateFromPicker`, `transferToAccountingDateToPicker`, `fpu26ActNumberCheckbox`.
- Особенности: JPQL: типы/joins.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M078. Заявки на ремонт деталей — `pt_RepairClaim.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/pt/view/ptrepairclaim/pt-repair-claim-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptrepairclaim/PtRepairClaimListView.java).
- Загрузчики: `ptRepairClaimsDl` → `ru.fgk.ws.app.pt.entity.PtRepairClaim`; `vRailwayDl` → `ru.fgk.ws.app.nsi.entity.VRailway`; `contractDl` → `ru.fgk.ws.app.pt.entity.PtRepairContract`.
- Текущие фильтры: genericFilter `genericFilter` — каталог [{"include": ".*"}]; `dateFromFilter` JPQL(java.time.LocalDate); `dateToFilter` JPQL(java.time.LocalDate); `depoRepair.railway` EQUAL; `claimType` EQUAL; `contract` EQUAL.
- Прочие поля ввода для проверки: `repairRwComboBox`, `contractComboBox`.
- Особенности: genericFilter: каталог/операции/AND-OR; JPQL: типы/joins; ссылка на entity.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 83](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptrepairclaim/PtRepairClaimListView.java) `claimTypeFilter.setValue(DEFAULT_CLAIM_TYPE);`, [строка 84](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptrepairclaim/PtRepairClaimListView.java) `dateFromFilter.setValue(timeSource.now().toLocalDate().withDayOfMonth(1).minusMonths(1));`, [строка 85](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptrepairclaim/PtRepairClaimListView.java) `dateToFilter.setValue(timeSource.now().toLocalDate());`, [строка 130](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptrepairclaim/PtRepairClaimListView.java) `claimTypeFilter.setValue(DEFAULT_CLAIM_TYPE);`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M079. Комплектация вагонов — `wn_VWagEquipmentList.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/wagons/view/vwagequipmentlist/v-wag-equipment-list-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/wagons/view/vwagequipmentlist/VWagEquipmentListListView.java).
- Загрузчики: `vWagEquipmentListsDl` → `ru.fgk.ws.app.wagons.entity.VWagEquipmentList`.
- Текущие фильтры: genericFilter `genericFilter` — каталог [{"include": ".*"}]; `jpqlFilter` JPQL(ru.fgk.ws.app.wagons.entity.WnList).
- Прочие поля ввода для проверки: `showColumnCheck`.
- Особенности: genericFilter: каталог/операции/AND-OR; JPQL: типы/joins; delegate/PreLoad; динамические параметры/условия.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 72](../../app/src/main/java/ru/fgk/ws/app/wagons/view/vwagequipmentlist/VWagEquipmentListListView.java) `showColumnCheck.setValue(false);`, [строка 88](../../app/src/main/java/ru/fgk/ws/app/wagons/view/vwagequipmentlist/VWagEquipmentListListView.java) `event.getLoadContext().getQuery().setParameter(WN_LIST_ID_PARAMETER, 0);`
- Роли (включая наследование исходных resource roles): [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [PtContractWriteRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractWriteRole.java), [PtContractReadRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractReadRole.java), [WnBaseRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WnBaseRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M080. История перевозочных документов — `wn_VWagInvoiceArchive`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/wagons/view/vwagpassport/v-wag-invoice-archive-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/wagons/view/vwagpassport/VWagInvoiceArchiveView.java).
- Загрузчики: `vWagInvoiceArchiveDl` → `ru.fgk.ws.app.wagons.entity.VWagInvoiceArchive`.
- Текущие фильтры: `dateRaskrFilter` GREATER_OR_EQUAL; `invoiceDateCreateFilter` LESS_OR_EQUAL.
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: динамические параметры/условия.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 83](../../app/src/main/java/ru/fgk/ws/app/wagons/view/vwagpassport/VWagInvoiceArchiveView.java) `vWagInvoiceArchiveDl.setParameter("wagnum", wagnum);`, [строка 88](../../app/src/main/java/ru/fgk/ws/app/wagons/view/vwagpassport/VWagInvoiceArchiveView.java) `filterDateBegin.setValue(LocalDate.now().withDayOfYear(1));`, [строка 89](../../app/src/main/java/ru/fgk/ws/app/wagons/view/vwagpassport/VWagInvoiceArchiveView.java) `filterDateEnd.setValue(LocalDate.now());`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

## Волна 8. Нестандартный поиск, отчёты и дополнительные списки

### M081. Отчет Распределение вагонов в ТР — `ReportAllocationOperRepair.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/rp/view/report-allocation-oper-repair-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/rp/view/ReportAllocationOperRepairListView.java).
- Загрузчики: `reportAllocationOperRepairDtoDl` → `ru.fgk.ws.app.rp.entity.ReportAllocationOperRepairDto`; `nvCategoryUsesDl` → `ru.fgk.ws.app.nsi.entity.NvCategoryUse`; `nvOwnTypesDl` → `ru.fgk.ws.app.nsi.entity.NvOwnType`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: `datePicker`, `rodFilterField`, `ownerTypeFilterField`, `liabilityFgkField`, `liabilityVRK1Field`, `isRepairOtherFilterField`, `checkboxIsLoadShow`.
- Особенности: delegate/PreLoad; динамические параметры/условия; нестандартные фильтры.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 129](../../app/src/main/java/ru/fgk/ws/app/rp/view/ReportAllocationOperRepairListView.java) `liabilityFgkField.setValue(true);`, [строка 130](../../app/src/main/java/ru/fgk/ws/app/rp/view/ReportAllocationOperRepairListView.java) `liabilityVRK1Field.setValue(true);`, [строка 135](../../app/src/main/java/ru/fgk/ws/app/rp/view/ReportAllocationOperRepairListView.java) `datePicker.setValue(currentDate);`, [строка 136](../../app/src/main/java/ru/fgk/ws/app/rp/view/ReportAllocationOperRepairListView.java) `dateSelectMode.setValue(1);`, [строка 137](../../app/src/main/java/ru/fgk/ws/app/rp/view/ReportAllocationOperRepairListView.java) `checkboxIsLoadShow.setValue(false);`, [строка 138](../../app/src/main/java/ru/fgk/ws/app/rp/view/ReportAllocationOperRepairListView.java) `isRepairOtherFilterField.setValue(true);` Остальные места перечислены в JSON.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M082. Допретензионная работа — `ReportWagOperRepairDto.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dt/view/reportwagoperrepairdto/report-wag-oper-repair-dto-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dt/view/reportwagoperrepairdto/ReportWagOperRepairDtoListView.java).
- Загрузчики: `reportWagOperRepairDtoDl` → `ru.fgk.ws.app.dt.entity.ReportWagOperRepairDto`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: `dateFromPicker`, `dateToPicker`, `waitingDays`, `repairType62Select`, `vrkSelect`.
- Особенности: delegate/PreLoad; нестандартные фильтры.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 222](../../app/src/main/java/ru/fgk/ws/app/dt/view/reportwagoperrepairdto/ReportWagOperRepairDtoListView.java) `dateFromPicker.setValue(prevMonth.withDayOfMonth(1));`, [строка 223](../../app/src/main/java/ru/fgk/ws/app/dt/view/reportwagoperrepairdto/ReportWagOperRepairDtoListView.java) `dateToPicker.setValue(prevMonth.withDayOfMonth(prevMonth.lengthOfMonth()));`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M083. Количество предыдущих отцепок — `UncouplingCountView`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/uncouplingcount/uncoupling-count-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/uncouplingcount/UncouplingCountView.java).
- Загрузчики: `uncouplingCountsDl` → `ru.fgk.ws.app.dr.entity.UncouplingCount`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: `uncouplingCountsDateFromPicker`, `uncouplingCountsDateToPicker`.
- Особенности: delegate/PreLoad; нестандартные фильтры.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 78](../../app/src/main/java/ru/fgk/ws/app/dr/view/uncouplingcount/UncouplingCountView.java) `uncouplingCountsDateFromPicker.setValue(prevMonth.withDayOfMonth(1));`, [строка 79](../../app/src/main/java/ru/fgk/ws/app/dr/view/uncouplingcount/UncouplingCountView.java) `uncouplingCountsDateToPicker.setValue(prevMonth.withDayOfMonth(prevMonth.lengthOfMonth()));`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [DrPlannedRepairAcceptanceRole.java](../../app/src/main/java/ru/fgk/ws/app/dr/security/DrPlannedRepairAcceptanceRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M084. Статистика экранов — `UserActivityStats.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/common/view/useractivitystats/user-activity-stats-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/common/view/useractivitystats/UserActivityStatsListView.java).
- Загрузчики: `userActivityStatsDl` → `ru.fgk.ws.app.common.entity.UserActivityStatsDto`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: `dateStartField`, `dateEndField`.
- Особенности: delegate/PreLoad; нестандартные фильтры.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 69](../../app/src/main/java/ru/fgk/ws/app/common/view/useractivitystats/UserActivityStatsListView.java) `dateStartField.setValue(LocalDate.now().minusMonths(3));`, [строка 72](../../app/src/main/java/ru/fgk/ws/app/common/view/useractivitystats/UserActivityStatsListView.java) `dateEndField.setValue(LocalDate.now());`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M085. Выгрузка на прошлую дату — `WnWagArchiveSpecsDto.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/wagons/view/wnwagarchivespecs/wn-wag-archive-specs-dto-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/wagons/view/wnwagarchivespecs/WnWagArchiveSpecsDtoListView.java).
- Загрузчики: `wnWagArchiveSpecsDtoDl` → `ru.fgk.ws.app.wagons.entity.WnWagArchiveSpecsDto`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: `dateBuildFilter`, `wnListFilter`.
- Особенности: delegate/PreLoad; нестандартные фильтры.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 76](../../app/src/main/java/ru/fgk/ws/app/wagons/view/wnwagarchivespecs/WnWagArchiveSpecsDtoListView.java) `dateBuildFilter.setValue(LocalDate.now());`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M086. Последний выпуск по списку — `WnWagLastOper62Dto.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/wagons/view/wnwaglastoper62dto/wn-wag-last-oper62-dto-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/wagons/view/wnwaglastoper62dto/WnWagLastOper62DtoListView.java).
- Загрузчики: `wnWagLastOper62DtoDl` → `ru.fgk.ws.app.wagons.entity.WnWagLastOper62Dto`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: `wnListFilter`, `vrkEnumComboBox`, `repairTypeFilter`.
- Особенности: delegate/PreLoad; нестандартные фильтры.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M087. Добавление пакетов из ВакТк — `diadoc_DiadocVagTkImport.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/diadoc/view/vagtkimport/diadoc-vagtk-import-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/diadoc/view/vagtkimport/DiadocVagTkImportView.java).
- Загрузчики: `rowsDl` → `ru.fgk.ws.app.diadoc.dto.DiadocVagTkImportRow`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: `apprFioFilter`, `sourceFilter`, `serviceTypeFilter`, `signingTypeFilter`, `signStageFilter`, `severityFilter`.
- Особенности: delegate/PreLoad; нестандартные фильтры.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [DiadocPtSignRole.java](../../app/src/main/java/ru/fgk/ws/app/security/diadoc/DiadocPtSignRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M088. Справка по документообороту — `dr_ReportOperRepairDocFlowDto.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/reportoperrepairdocflowdto/report-oper-repair-doc-flow-dto-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/reportoperrepairdocflowdto/ReportOperRepairDocFlowDtoListView.java).
- Загрузчики: `reportOperRepairDocFlowDtoDl` → `ru.fgk.ws.app.dr.entity.ReportOperRepairDocFlowDto`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: `dateFromPicker`, `dateToPicker`, `repairTypeSelect`, `warrantyRepairFgkField`, `warrantyRepairVRK1Field`, `tfEuroRate`, `cbShowDefReason`.
- Особенности: delegate/PreLoad; динамические параметры/условия; нестандартные фильтры.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 145](../../app/src/main/java/ru/fgk/ws/app/dr/view/reportoperrepairdocflowdto/ReportOperRepairDocFlowDtoListView.java) `dateToPicker.setValue(endDate);`, [строка 146](../../app/src/main/java/ru/fgk/ws/app/dr/view/reportoperrepairdocflowdto/ReportOperRepairDocFlowDtoListView.java) `dateFromPicker.setValue(endDate.withDayOfMonth(1));`, [строка 148](../../app/src/main/java/ru/fgk/ws/app/dr/view/reportoperrepairdocflowdto/ReportOperRepairDocFlowDtoListView.java) `radioViewGrouping.setValue(1);`, [строка 149](../../app/src/main/java/ru/fgk/ws/app/dr/view/reportoperrepairdocflowdto/ReportOperRepairDocFlowDtoListView.java) `repairTypeSelect.setValue(0);`, [строка 150](../../app/src/main/java/ru/fgk/ws/app/dr/view/reportoperrepairdocflowdto/ReportOperRepairDocFlowDtoListView.java) `radioViewCompleted.setValue(0);`, [строка 151](../../app/src/main/java/ru/fgk/ws/app/dr/view/reportoperrepairdocflowdto/ReportOperRepairDocFlowDtoListView.java) `radioContractorGrouping.setValue(0);` Остальные места перечислены в JSON.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M089. Анализ стоимости ТР-2 — `dr_ReportTR2PriceAnalyzeDtoListView.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/reporttr2priceanalyzedto/report-tr2-price-analyze-dto-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/reporttr2priceanalyzedto/ReportTR2PriceAnalyzeDtoListView.java).
- Загрузчики: `reportTR2PriceAnalyzeDtoDl` → `ru.fgk.ws.app.repair.entity.dto.TR2PriceAnalyzeDto`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: `dateFromPicker`, `dateToPicker`, `docTypes`, `vrkEnumComboBox`, `mhCostFromReferenceFilter`, `warrantyRepairFilter`.
- Особенности: delegate/PreLoad; нестандартные фильтры.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 101](../../app/src/main/java/ru/fgk/ws/app/dr/view/reporttr2priceanalyzedto/ReportTR2PriceAnalyzeDtoListView.java) `dateToPicker.setValue(endDate);`, [строка 102](../../app/src/main/java/ru/fgk/ws/app/dr/view/reporttr2priceanalyzedto/ReportTR2PriceAnalyzeDtoListView.java) `dateFromPicker.setValue(endDate.withDayOfMonth(1));`, [строка 103](../../app/src/main/java/ru/fgk/ws/app/dr/view/reporttr2priceanalyzedto/ReportTR2PriceAnalyzeDtoListView.java) `docTypes.setValue(TR2PriceAnalyzeDocTypeEnum.PRESENTED_DOCS);`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M090. Отчет по срокам хранения в 1С — `pt_Pt1cStorageReport.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/pt/view/pt1cstoragereport/pt1c-storage-report-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/pt/view/pt1cstoragereport/Pt1cStorageReportListView.java).
- Загрузчики: `pt1cStorageReportRowsDl` → `ru.fgk.ws.app.pt.entity.Pt1cStorageReportRow`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: `showComparisonField`, `comparisonDateField`.
- Особенности: delegate/PreLoad; дерево; нестандартные фильтры.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M091. Реестр деталей — `pt_PtPart.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/pt/view/ptpart/pt-part-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/pt/view/ptpart/PtPartListView.java).
- Загрузчики: `ptPartsDl` → `ru.fgk.ws.app.pt.entity.PtPart`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: `partListsFilter`.
- Особенности: delegate/PreLoad; нестандартные фильтры.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [PtContractWriteRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractWriteRole.java), [PtContractReadRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractReadRole.java), [WnBaseRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WnBaseRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M092. Остаток вагонов в ТР — `rp_VRpOperBalance.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/rp/view/reportrpoperbalance/vrpoperbalance/v-rp-oper-balance-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/rp/view/reportrpoperbalance/vrpoperbalance/VRpOperBalanceListView.java).
- Загрузчики: `vRpOperBalancesDl` → `ru.fgk.ws.app.rp.entity.VRpOperBalance`; `nvCategoryUsesDl` → `ru.fgk.ws.app.nsi.entity.NvCategoryUse`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: `reportDateField`, `liabilityFgkField`, `liabilityVRK1Field`, `contractField`, `categoryUseField`, `showLoadField`, `showAverageTimeRepairField`.
- Особенности: delegate/PreLoad; динамические параметры/условия; дерево; нестандартные фильтры.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 134](../../app/src/main/java/ru/fgk/ws/app/rp/view/reportrpoperbalance/vrpoperbalance/VRpOperBalanceListView.java) `reportDateField.setValue(reportDate);`, [строка 141](../../app/src/main/java/ru/fgk/ws/app/rp/view/reportrpoperbalance/vrpoperbalance/VRpOperBalanceListView.java) `repairTypeField.setValue(0);`, [строка 143](../../app/src/main/java/ru/fgk/ws/app/rp/view/reportrpoperbalance/vrpoperbalance/VRpOperBalanceListView.java) `liabilityFgkField.setValue(true);`, [строка 144](../../app/src/main/java/ru/fgk/ws/app/rp/view/reportrpoperbalance/vrpoperbalance/VRpOperBalanceListView.java) `liabilityVRK1Field.setValue(true);`, [строка 326](../../app/src/main/java/ru/fgk/ws/app/rp/view/reportrpoperbalance/vrpoperbalance/VRpOperBalanceListView.java) `reportDateField.setValue(`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M093. Отцепка вагонов в текущий ремонт — `rp_VRpOperDefect.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/rp/view/reportrpoperdefectlist/vrpoperdefect/v-rp-oper-defect-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/rp/view/reportrpoperdefectlist/vrpoperdefect/VRpOperDefectListView.java).
- Загрузчики: `vRpOperDefectsDl` → `ru.fgk.ws.app.rp.entity.VRpOperDefect`; `nvCategoryUsesDl` → `ru.fgk.ws.app.nsi.entity.NvCategoryUse`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: `startField`, `endField`, `warrantyRepairFgkField`, `warrantyRepairVRK1Field`, `contractField`, `categoryUseField`, `singlyRentField`.
- Особенности: delegate/PreLoad; дерево; нестандартные фильтры.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 138](../../app/src/main/java/ru/fgk/ws/app/rp/view/reportrpoperdefectlist/vrpoperdefect/VRpOperDefectListView.java) `endField.setValue(endDate);`, [строка 139](../../app/src/main/java/ru/fgk/ws/app/rp/view/reportrpoperdefectlist/vrpoperdefect/VRpOperDefectListView.java) `startField.setValue(endDate.withDayOfMonth(1));`, [строка 149](../../app/src/main/java/ru/fgk/ws/app/rp/view/reportrpoperdefectlist/vrpoperdefect/VRpOperDefectListView.java) `repairTypeField.setValue(0);`, [строка 151](../../app/src/main/java/ru/fgk/ws/app/rp/view/reportrpoperdefectlist/vrpoperdefect/VRpOperDefectListView.java) `singlyRentField.setValue(true);`, [строка 298](../../app/src/main/java/ru/fgk/ws/app/rp/view/reportrpoperdefectlist/vrpoperdefect/VRpOperDefectListView.java) `startField.setValue(userDate.withDayOfMonth(1));`, [строка 299](../../app/src/main/java/ru/fgk/ws/app/rp/view/reportrpoperdefectlist/vrpoperdefect/VRpOperDefectListView.java) `endField.setValue(userDate.withDayOfMonth(userDate.lengthOfMonth()));`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M094. Поиск по номеру детали — `wn_VWagEquipmentArchiveFind.list`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/view/vwagequipmentarchive/v-wag-equipment-archive-find-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/view/vwagequipmentarchive/VWagEquipmentArchiveFindView.java).
- Загрузчики: `nvPartTypesDl` → `ru.fgk.ws.app.nsi.entity.NvPartType`; `vWagEqWheelsetDl` → `ru.fgk.ws.app.wagons.entity.VWagEqWheelsetArchList`; `vWagEqBogieDl` → `ru.fgk.ws.app.wagons.entity.VWagEqBogieArchList`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: `detailFactory`, `detailNumber`, `detailYear`, `equipmentDate`.
- Особенности: динамические параметры/условия; нестандартные фильтры.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 96](../../app/src/main/java/ru/fgk/ws/app/view/vwagequipmentarchive/VWagEquipmentArchiveFindView.java) `checkboxDetailType.setValue(nvPartTypesDc.getMutableItems().getFirst());`, [строка 100](../../app/src/main/java/ru/fgk/ws/app/view/vwagequipmentarchive/VWagEquipmentArchiveFindView.java) `checkboxDetailType.setValue(partType);`, [строка 101](../../app/src/main/java/ru/fgk/ws/app/view/vwagequipmentarchive/VWagEquipmentArchiveFindView.java) `detailNumber.setValue(number);`, [строка 102](../../app/src/main/java/ru/fgk/ws/app/view/vwagequipmentarchive/VWagEquipmentArchiveFindView.java) `detailFactory.setValue(factory);`, [строка 103](../../app/src/main/java/ru/fgk/ws/app/view/vwagequipmentarchive/VWagEquipmentArchiveFindView.java) `detailYear.setValue(year);`, [строка 170](../../app/src/main/java/ru/fgk/ws/app/view/vwagequipmentarchive/VWagEquipmentArchiveFindView.java) `vWagEqWheelsetDl.setParameter("p_detailNumber", detailNumber.getValue());` Остальные места перечислены в JSON.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

### M095. История операций — `wn_VWagOperArchive`

- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/wagons/view/vwagpassport/v-wag-oper-archive-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/wagons/view/vwagpassport/VWagOperArchiveView.java).
- Загрузчики: `wnVWagOperArchiveDl` → `ru.fgk.ws.app.wagons.entity.VWagOperArchive`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: `startField`, `endField`.
- Особенности: delegate/PreLoad; нестандартные фильтры.
- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 56](../../app/src/main/java/ru/fgk/ws/app/wagons/view/vwagpassport/VWagOperArchiveView.java) `startField.setValue(YearMonth.now().atDay(1).minusMonths(1));`, [строка 57](../../app/src/main/java/ru/fgk/ws/app/wagons/view/vwagpassport/VWagOperArchiveView.java) `endField.setValue(LocalDate.now());`
- Роли (включая наследование исходных resource roles): [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [PtContractWriteRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractWriteRole.java), [PtContractReadRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractReadRole.java), [WnBaseRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WnBaseRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08.

