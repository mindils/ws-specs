# F10. Добавление фильтра на остальные списки

[К плану](README.md) · [Полный реестр](page-inventory.json)

Всего задач: **45**. Порядок фиксирован: номер волны, затем viewId; пилот имеет отдельный порядок.
Статусы страниц — не начато. Номера строк относятся к снимку 2026-09-05; JSON хранит полный набор найденных обработчиков, условий, полей и ограничений загрузчика.

**Порядок волны 8:** сначала оставшиеся задачи M из документа 09, затем задачи N из документа 10. Зависимости F02–F08 означают приёмку соответствующего пути, а не завершение всех необязательных возможностей аддона.

Поля вне property binding перечислены как кандидаты для проверки, а не как разрешение переносить настройки отображения/параметры команд в фильтр.

## Волна 8. Нестандартный поиск, отчёты и дополнительные списки

### N001. Организации диадок — `DiadocContractor.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/diadoc/diadoc-contractor-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/diadoc/DiadocContractorListView.java).
- Загрузчики: `diadocContractorsDl` → `ru.fgk.ws.app.nsi.entity.DiadocContractor`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `diadocContractorDataGrid`: `name`, `inn`, `kpp`, `code`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N002. Типы документов — `DiadocDocumentType.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/diadoc/diadoc-document-type-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/diadoc/DiadocDocumentTypeListView.java).
- Загрузчики: `diadocDocumentTypesDl` → `ru.fgk.ws.app.nsi.entity.DiadocDocumentType`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `diadocDocumentTypesDataGrid`: `name`, `code`, `sortOrder`, `vrkDownloadUrl`, `vrkLoadingName`, `vrkLoadingIdLabel`, `usageType`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N003. Настройки подписания — `DiadocSignSettingsDocType.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/diadoc/view/settings/diadoc-sign-settings-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/diadoc/view/settings/DiadocSignSettingsListView.java).
- Загрузчики: `diadocSignSettingsDl` → `ru.fgk.ws.app.diadoc.entity.DiadocSignSettings`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `diadocSignSettingsDataGrid`: `contractor`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N004. Периоды (Договоры ТР-2 на ЦДИ) — `DrContractCdiPeriod.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/view/drcontractcdiperiod/dr-contract-cdi-period-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/view/drcontractcdiperiod/DrContractCdiPeriodListView.java).
- Загрузчики: `drContractCdiPeriodsDl` → `ru.fgk.ws.app.drcontract.entity.DrContractCdiPeriod`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `drContractCdiPeriodsDataGrid`: `periodType`, `dateBegin`, `dateEnd`, `contract`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N005. Работы ТР-2 на ЦДИ — `DrContractCdiWork.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/view/drcontractcdiwork/dr-contract-cdi-work-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/view/drcontractcdiwork/DrContractCdiWorkListView.java).
- Загрузчики: `drContractCdiWorksDl` → `ru.fgk.ws.app.drcontract.entity.DrContractCdiWork`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: динамические параметры/условия.
- Целевой каталог для `drContractCdiWorksDataGrid`: `workCode`, `workName`, `group`, `partName`, `partType`, `partWork`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 36](../../app/src/main/java/ru/fgk/ws/app/view/drcontractcdiwork/DrContractCdiWorkListView.java) `drContractCdiWorksDl.setParameter("contractId", contractId);`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N006. Работы ТР-2 на ЦДИ — `DrContractCdiWorkPrice.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/drcontract/view/dr-contract-cdi-work-price-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/drcontract/view/DrContractCdiWorkPriceListView.java).
- Загрузчики: `drContractCdiWorkPricesDl` → `ru.fgk.ws.app.drcontract.entity.DrContractCdiWorkPrice`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `drContractCdiWorkPricesDataGrid`: `period`, `work`, `region.regionName`, `railway.rwCode`, `railway.rwShortName`, `price`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N007. Рассчеты на возмещение затрат — `DrRefund.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/drrefund/dr-refund-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/drrefund/DrRefundListView.java).
- Загрузчики: `drRefundsDl` → `ru.fgk.ws.app.dr.entity.DrRefund`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: динамические параметры/условия.
- Целевой каталог для `drRefundsDataGrid`: `name`, `totalAmount`, `createdBy`, `createdDate`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 54](../../app/src/main/java/ru/fgk/ws/app/dr/view/drrefund/DrRefundListView.java) `drRefundsDl.setParameter("repairUid", repairUid);`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N008. Стоимость ТР-1 по РФ — `DrTr1Cost.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/drtr1cost/dr-tr1-cost-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/drtr1cost/DrTr1CostListView.java).
- Загрузчики: `drTr1CostsDl` → `ru.fgk.ws.app.nsi.entity.DrTr1Cost`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `drTr1CostsDataGrid`: `id`, `dateBegin`, `dateEnd`, `repairCost`, `addSupplyOut`, `lastModifiedDate`, `lastModifiedBy`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 36](../../app/src/main/java/ru/fgk/ws/app/nsi/view/drtr1cost/DrTr1CostListView.java) `(checkbox, drtr1cost) -> checkbox.setValue(drtr1cost.getAddSupplyOut()));`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N009. Сбор за подачу/уборку ТР — `DrTrSupplyOutPeriod.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/drtrsupplyoutcost/dr-tr-supply-out-period-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/drtrsupplyoutcost/DrTrSupplyOutPeriodListView.java).
- Загрузчики: `drTrSupplyOutPeriodsDl` → `ru.fgk.ws.app.nsi.entity.DrTrSupplyOutPeriod`; `drTrSupplyOutCostDl` → `ru.fgk.ws.app.nsi.entity.DrTrSupplyOutCost`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: динамические параметры/условия.
- Целевой каталог для `drTrSupplyOutPeriodsDataGrid`: `id`, `dateBegin`, `dateEnd`, `lastModifiedDate`, `lastModifiedBy`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 109](../../app/src/main/java/ru/fgk/ws/app/nsi/view/drtrsupplyoutcost/DrTrSupplyOutPeriodListView.java) `drTrSupplyOutCostDl.setParameter("period", event.getItem());`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N010. Ставки НДC — `NsiNds.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/nsinds/nsi-nds-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/nsinds/NsiNdsListView.java).
- Загрузчики: `nsiNdsDl` → `ru.fgk.ws.app.nsi.entity.NsiNds`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `nsiNdsDataGrid`: `id`, `dateBegin`, `dateEnd`, `value`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N011. Перечень вагонов — `ReportTr2WagonListView`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/reporttr2wagonlist/report-tr2-wagon-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/reporttr2wagonlist/ReportTr2WagonListView.java).
- Загрузчики: `TR2PriceAnalyzeWagonsDtoDl` → `ru.fgk.ws.app.repair.entity.dto.TR2PriceAnalyzeWagonsDto`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: delegate/PreLoad.
- Целевой каталог для `reportTR2PriceAnalyzeWagonsDataGrid`: `wagonNumber`, `wagonKind`, `repairDate`, `road`, `cdiVrkOther`, `vrp`, `station`, `repairType`, `reason`, `faultCode`, `kitState`, `packageState`, `reissued`, `rentNumber`, `rentCounterparty`, `avrSumExcludingVat`, `removedMx1`, `installedMx3`, `separateContractsRepairCost`, `totalRepairCosts`, `kpReplacement`, `deliveryRemovalCostsExcludingVat`, `reclamationDocsCostsExcludingVat`, `contractorPartsKpKrInstallationCosts`, `srTrUrCosts`, `kroCosts`, `clearedAvgRepairCostWithoutDeliveryReclamationKro`, `otherWorks`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N012. Автосцепка — `VCouplerType.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/vcouplertype/v-coupler-type-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/vcouplertype/VCouplerTypeListView.java).
- Загрузчики: `vCouplerTypesDl` → `ru.fgk.ws.app.nsi.entity.VCouplerType`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `vCouplerTypesDataGrid`: `id`, `name`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N013. Регионы — `VNvRegion.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/vnvregion/v-nv-region-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/vnvregion/VNvRegionListView.java).
- Загрузчики: `vNvRegionsDl` → `ru.fgk.ws.app.nsi.entity.VNvRegion`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `vNvRegionsDataGrid`: `id`, `regionName`, `regionSname`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [PtContractWriteRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractWriteRole.java), [PtContractReadRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtContractReadRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N014. Перечень вагонов — `VRpOperWagListView`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/rp/view/vrpoperwaglist/v-rp-oper-wag-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/rp/view/vrpoperwaglist/VRpOperWagListView.java).
- Загрузчики: `nvOwnTypeDl` → `ru.fgk.ws.app.nsi.entity.NvOwnType`; `vRpOperWagsDl` → `property-bound/KeyValue`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: delegate/PreLoad.
- Целевой каталог для `vRpOperWagsDataGrid`: `wagnum`, `categoryUse`, `defectDate`, `repairType52`, `defectReason`, `defectDepoCode`, `defectStationId`, `arrivalDate`, `repairDate`, `repairType62`, `defectUnit1`, `defectUnit2`, `repairLiability`, `warrantyRepair`, `ownStart`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N015. Контрагенты — `VrkContractor.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/asuvrk/view/vrkcontractor/vrk-contractor-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/asuvrk/view/vrkcontractor/VrkContractorListView.java).
- Загрузчики: `vrkContractorsDl` → `ru.fgk.ws.app.asuvrk.entity.VrkContractor`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `vrkContractorsDataGrid`: `id`, `name`, `depo`, `rwCode`, `stCode`, `vkrCentralOrgCode`, `deleted`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N016. Виды документов — `VrkDocumentType.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/asuvrk/view/vrkdocumenttype/vrk-document-type-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/asuvrk/view/vrkdocumenttype/VrkDocumentTypeListView.java).
- Загрузчики: `vrkDocumentTypesDl` → `ru.fgk.ws.app.asuvrk.entity.VrkDocumentType`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `vrkDocumentTypesDataGrid`: `id`, `name`, `vrkDocumentTypeMatching.documentType.name`, `vrkDocumentTypeMatching.documentType.vrkDownloadUrl`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N017. Модернизации — `VrkModernization.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/asuvrk/view/vrkmodernization/vrk-modernization-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/asuvrk/view/vrkmodernization/VrkModernizationListView.java).
- Загрузчики: `vrkModernizationsDl` → `ru.fgk.ws.app.asuvrk.entity.VrkModernization`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `vrkModernizationsDataGrid`: `id`, `number`, `name`, `projectName`, `deleted`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N018. Виды ремонтов — `VrkRepairType.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/asuvrk/view/vrkrepairtype/vrk-repair-type-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/asuvrk/view/vrkrepairtype/VrkRepairTypeListView.java).
- Загрузчики: `vrkRepairTypesDl` → `ru.fgk.ws.app.asuvrk.entity.VrkRepairType`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `vrkRepairTypesDataGrid`: `id`, `name`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N019. Типы вагонов — `VrkWagonType.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/asuvrk/view/vrkwagontype/vrk-wagon-type-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/asuvrk/view/vrkwagontype/VrkWagonTypeListView.java).
- Загрузчики: `vrkWagonTypesDl` → `ru.fgk.ws.app.asuvrk.entity.VrkWagonType`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `vrkWagonTypesDataGrid`: `id`, `rod`, `name`, `deleted`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N020. Группы работ — `VrkWorkGroup.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/asuvrk/view/vrkworkgroup/vrk-work-group-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/asuvrk/view/vrkworkgroup/VrkWorkGroupListView.java).
- Загрузчики: `vrkWorkGroupsDl` → `ru.fgk.ws.app.asuvrk.entity.VrkWorkGroup`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `vrkWorkGroupsDataGrid`: `id`, `name`, `deleted`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N021. Документы из АСУ ВРК — `WagOperRepairFileListView`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/wagoperrepairfile/wag-oper-repair-file-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/wagoperrepairfile/WagOperRepairFileListView.java).
- Загрузчики: `drFileDl` → `ru.fgk.ws.app.dr.entity.DrFile`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: динамические параметры/условия.
- Целевой каталог для `drFileDataGrid`: `source`, `docType.vrkLoadingName`, `comment`, `status`, `errorText`, `filename`, `fileType`, `fileAttach`, `asuVrkFileId`, `repairUid`, `actId`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 52](../../app/src/main/java/ru/fgk/ws/app/dr/view/wagoperrepairfile/WagOperRepairFileListView.java) `drFileDl.setParameter("repairUid", repairUid);`, [строка 56](../../app/src/main/java/ru/fgk/ws/app/dr/view/wagoperrepairfile/WagOperRepairFileListView.java) `drFileDl.setParameter("actId", actId);`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N022. Конструктор примечаний — `WnNotesHead.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/wagons/view/wn-notes-head-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/wagons/view/WnNotesHeadListView.java).
- Загрузчики: `wnNotesHeadsDl` → `ru.fgk.ws.app.wagons.entity.WnNotesHead`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `wnNotesHeadsDataGrid`: `title`, `patternClass`, `note`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N023. История диалогов — `ai_AiConversation.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/ai/view/conversation/ai-conversation-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/ai/view/conversation/AiConversationListView.java).
- Загрузчики: `conversationsDl` → `ru.fgk.ws.app.ai.entity.AiChatConversation`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `conversationsDataGrid`: `title`, `lastMessageDate`, `createdDate`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [AiChatUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/ai/AiChatUserRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N024. Мои фоновые задачи — `common_BackgroundJobTask.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/common/view/backgroundjob/background-job-task-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/common/view/backgroundjob/BackgroundJobTaskListView.java).
- Загрузчики: `jobsDl` → `ru.fgk.ws.app.common.entity.BackgroundJobTask`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: динамические параметры/условия.
- Целевой каталог для `jobsDataGrid`: `jobName`, `description`, `status`, `createdDate`, `fileName`, `errorMessage`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 76](../../app/src/main/java/ru/fgk/ws/app/common/view/backgroundjob/BackgroundJobTaskListView.java) `jobsDl.setParameter("minDate", minDate);`, [строка 77](../../app/src/main/java/ru/fgk/ws/app/common/view/backgroundjob/BackgroundJobTaskListView.java) `jobsDl.setParameter("currentUser", username);`
- Роли (включая наследование исходных resource roles): [BackgroundJobsRole.java](../../app/src/main/java/ru/fgk/ws/app/security/BackgroundJobsRole.java), [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N025. Мои загрузки — `common_ExportTask.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/common/view/exporttask/export-task-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/common/view/exporttask/ExportTaskListView.java).
- Загрузчики: `exportTasksDl` → `ru.fgk.ws.app.common.entity.ExportTask`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: динамические параметры/условия.
- Целевой каталог для `exportTasksDataGrid`: `description`, `status`, `createdDate`, `fileName`, `errorMessage`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 71](../../app/src/main/java/ru/fgk/ws/app/common/view/exporttask/ExportTaskListView.java) `exportTasksDl.setParameter("minDate", minDate);`, [строка 72](../../app/src/main/java/ru/fgk/ws/app/common/view/exporttask/ExportTaskListView.java) `exportTasksDl.setParameter("currentUser", username);`
- Роли (включая наследование исходных resource roles): [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [AsyncExportRole.java](../../app/src/main/java/ru/fgk/ws/app/security/AsyncExportRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N026. Заявки для отправки — `da_RepairClaimNoSend.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/da/view/repairclaim/repair-claim-no-send-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/da/view/repairclaim/RepairClaimNoSendListView.java).
- Загрузчики: `repairClaimsDl` → `ru.fgk.ws.app.da.entity.RepairClaim`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: delegate/PreLoad.
- Целевой каталог для `repairClaimsDataGrid`: `wagnum`, `buildDate`, `dislocationRw.rwCode`, `dislocationRw.rwShortName`, `dislocationStation`, `lifeEndDate`, `repairType`, `isLoad`, `damageCode`, `damageName`, `defectDate`, `nextRepairDate`, `nextRepairType`, `kmReserve`, `sendStatus`, `sendDate`, `id`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java), [DaRepairClaimRole.java](../../app/src/main/java/ru/fgk/ws/app/da/security/DaRepairClaimRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N027. Планируется к рассылке — `da_RepairClaimRfNoSend.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/da/view/repairclaim/repair-claim-rf-no-send-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/da/view/repairclaim/RepairClaimRfNoSendListView.java).
- Загрузчики: `repairClaimsDl` → `ru.fgk.ws.app.da.entity.RepairClaim`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: delegate/PreLoad.
- Целевой каталог для `repairClaimsDataGrid`: `wagnum`, `defectDate`, `repairType`, `isLoad`, `damageCode`, `damageName`, `nextRepairDate`, `nextRepairType`, `kmReserve`, `buildDate`, `lifeEndDate`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N028. Планируется к рассылке по выпуску из НРП — `da_RepairNoticeNoSend.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/da/view/notice/repair-notice-no-send-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/da/view/notice/RepairNoticeNoSendListView.java).
- Загрузчики: Нет query loader; требуется адаптер/контекст владельца..
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `repairItemsDataGrid`: `wagnum`, `repairType`, `rwName`, `repairStationName`, `categoryUseMnem`, `model`, `renterName`, `repairLiability`, `sendAfterRepairLiability`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N029. Исходящие пакеты Диадок — `diadoc_DiadocOutboundPacket.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/diadoc/view/outbound/diadoc-outbound-packet-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/diadoc/view/outbound/DiadocOutboundPacketListView.java).
- Загрузчики: `outboundPacketsDl` → `ru.fgk.ws.app.diadoc.entity.DiadocOutboundPacket`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `outboundPacketsDataGrid`: `id`, `documentType`, `status`, `approvedBy`, `approvedDate`, `signedBy`, `signedDate`, `sentDate`, `messageId`, `errorCode`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 224](../../app/src/main/java/ru/fgk/ws/app/diadoc/view/outbound/DiadocOutboundPacketListView.java) `xmlArea.setValue(sb.toString());`
- Роли (включая наследование исходных resource roles): [PtModulReadRole.java](../../app/src/main/java/ru/fgk/ws/app/security/PtModulReadRole.java), [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N030. Все пакеты по ремонту — `dr_RepairPacketRow.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/repairallpackets/repair-all-packets-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/repairallpackets/RepairAllPacketsListView.java).
- Загрузчики: `repairPacketRowsDl` → `ru.fgk.ws.app.dr.entity.RepairPacketRow`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: delegate/PreLoad.
- Целевой каталог для `repairPacketRowsDataGrid`: `insertDate`, `service`, `docCount`, `packStatus`, `signDate`, `accountingTransferDate`, `actNumber`, `actDate`, `actCost`, `rdvCost`, `billingStatementNumber`, `billingStatementDate`, `billingStatementCost`, `defectActCost`, `mh1Num`, `mh1Date`, `mh1Cost`, `mh3Num`, `mh3Date`, `mh3Cost`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N031. История перемещения детали по МХ — `dr_VPartMovementHistory.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/dr/view/drpartmovementhistory/v-part-movement-history-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/dr/view/drpartmovementhistory/VPartMovementHistoryListView.java).
- Загрузчики: `vPartMovementHistoryDl` → `ru.fgk.ws.app.dr.entity.VPartMovementHistory`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: динамические параметры/условия.
- Целевой каталог для `vPartMovementHistoriesDataGrid`: `packetType`, `isMh3`, `mhNum`, `mhDate`, `depo.depoFillName`, `depo.vrkCode`, `depo.railway`, `repair.wagnum`, `repair.repairType`, `repair.repairDate`, `detailName`, `wsRim`, `wsRimValue`, `condition`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 43](../../app/src/main/java/ru/fgk/ws/app/dr/view/drpartmovementhistory/VPartMovementHistoryListView.java) `vPartMovementHistoryDl.setParameter("detailUid", detailUid);`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N032. Состояние букс — `nsi_NsiVNvWsBox.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/vnvwsbox/v-nv-ws-box-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/vnvwsbox/VNvWsBoxListView.java).
- Загрузчики: `vNvWsBoxesDl` → `ru.fgk.ws.app.nsi.entity.VNvWsBox`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `vNvWsBoxesDataGrid`: `id`, `info`, `name`, `usedDrContract`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N033. Состояние КП — `nsi_NsiVNvWsCondition.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/vnvwscondition/v-nv-ws-condition-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/vnvwscondition/VNvWsConditionListView.java).
- Загрузчики: `vNvWsConditionsDl` → `ru.fgk.ws.app.nsi.entity.VNvWsCondition`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `vNvWsConditionsDataGrid`: `id`, `info`, `name`, `usedDrContract`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N034. Диапазоны толщины обода — `nsi_NsiVNvWsRim.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/vnvwsrim/v-nv-ws-rim-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/vnvwsrim/VNvWsRimListView.java).
- Загрузчики: `vNvWsRimsDl` → `ru.fgk.ws.app.nsi.entity.VNvWsRim`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `vNvWsRimsDataGrid`: `id`, `info`, `name`, `rimMax`, `rimMin`, `usedDrContract`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N035. Текстовые варианты для DIADOC — `nsi_NvPartTypeDiadocDictionary.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/nvparttypediadicdictionary/nv-part-type-diadoc-dictionary-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/nvparttypediadicdictionary/NvPartTypeDiadocDictionaryListView.java).
- Загрузчики: `dictionaryDl` → `ru.fgk.ws.app.nsi.entity.NvPartTypeDiadocDictionary`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: динамические параметры/условия.
- Целевой каталог для `dictionaryDataGrid`: `partType`, `val`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 31](../../app/src/main/java/ru/fgk/ws/app/nsi/view/nvparttypediadicdictionary/NvPartTypeDiadocDictionaryListView.java) `dictionaryDl.setParameter("partType", partType);`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N036. Филиалы пользователя — `nsi_UserDepartmentLink.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/userdepartmentlink/user-department-link-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/userdepartmentlink/UserDepartmentLinkListView.java).
- Загрузчики: `userDepartmentLinksDl` → `ru.fgk.ws.app.nsi.entity.UserDepartmentLink`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: динамические параметры/условия.
- Целевой каталог для `userDepartmentLinksDataGrid`: `department`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 70](../../app/src/main/java/ru/fgk/ws/app/nsi/view/userdepartmentlink/UserDepartmentLinkListView.java) `userDepartmentLinksDl.setParameter("user", user);`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N037. Поглощающие аппараты — `nsi_VAbsorberType.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/vabsorbertype/v-absorber-type-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/vabsorbertype/VAbsorberTypeListView.java).
- Загрузчики: `vAbsorberTypeDl` → `ru.fgk.ws.app.nsi.entity.VAbsorberType`; `absorberType1cDictionaryDl` → `ru.fgk.ws.app.nsi.entity.VAbsorberType1cDictionary`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: динамические параметры/условия.
- Целевой каталог для `vAbsorberTypeDataGrid`: `id`, `absorberClass`, `absorberModel`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 53](../../app/src/main/java/ru/fgk/ws/app/nsi/view/vabsorbertype/VAbsorberTypeListView.java) `absorberType1cDictionaryDl.setParameter("absorberType", absorberType);`
- Роли (включая наследование исходных resource roles): [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N038. Авторегулятор рычажной передачи — `nsi_VAutoregulator.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/vautoregulator/v-autoregulator-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/vautoregulator/VAutoregulatorListView.java).
- Загрузчики: `vAutoregulatorsDl` → `ru.fgk.ws.app.nsi.entity.VAutoregulator`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `vAutoregulatorsDataGrid`: `id`, `mnem`, `name`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N039. Материал кузова — `nsi_VBodyMaterial.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/vbodymaterial/v-body-material-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/vbodymaterial/VBodyMaterialListView.java).
- Загрузчики: `vBodyMaterialsDl` → `ru.fgk.ws.app.nsi.entity.VBodyMaterial`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `vBodyMaterialsDataGrid`: `id`, `name`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N040. Тип оси КП — `nsi_VNvAxleType.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/vnvaxletype/v-nv-axle-type-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/vnvaxletype/VNvAxleTypeListView.java).
- Загрузчики: `vNvAxleTypesDl` → `ru.fgk.ws.app.nsi.entity.VNvAxleType`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `vNvAxleTypesDataGrid`: `id`, `type`, `usedDrContract`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N041. Габарит вагона — `nsi_VWagSize.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/vwagsize/v-wag-size-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/nsi/view/vwagsize/VWagSizeListView.java).
- Загрузчики: `vWagSizesDl` → `ru.fgk.ws.app.nsi.entity.VWagSize`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `vWagSizesDataGrid`: `id`, `name`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [WsUserRole.java](../../app/src/main/java/ru/fgk/ws/app/security/WsUserRole.java), [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N042. Перечень вагонов из Распределения в ТР — `rp_VRepairAbdpvAllocation.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/view/vrepairabdpvarch/v-repair-abdpv-allocation-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/view/vrepairabdpvarch/VRepairAbdpvAllocationListView.java).
- Загрузчики: `vRepairAbdpvArchesDl` → `ru.fgk.ws.app.wagons.entity.VRepairAbdpvArch`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: динамические параметры/условия.
- Целевой каталог для `vRepairAbdpvArchesDataGrid`: `wagnum`, `yearDateBuild`, `yearSrokSl`, `tip`, `model`, `depoLastRepair.vrkCode`, `depoLastRepair.depoFillName`, `dateLastRepair`, `lastOperRepairDepo.vrkCode`, `lastOperRepairDepo.depoFillName`, `lastOperRepairRepairDate`, `lastOperRepairType`, `lastOperRepairDefectCodes`, `defectDepoCode.railway.rwShortName`, `defectDepoCode.depoFillName`, `repairType52`, `defectReason`, `defectCodes`, `defectCode1.dmShortname`, `defectDate`, `repairDateStart`, `repairDate`, `repairLiability`, `warrantyRepair`, `kodPlRem`, `datePlRem`, `mileage`, `lastOperRepairProbeg`, `remainingMileage`, `rwagnumDisl.dislocationStation.rwCode`, `rwagnumDisl.dislocationStation.rwShortName`, `rwagnumDisl.dislocationStation.stCode`, `rwagnumDisl.dislocationStation.stName`, `rwagnumDisl.isLoadShort`, `rwagnumDisl.destinationStation.rwCode`, `rwagnumDisl.destinationStation.rwShortName`, `rwagnumDisl.destinationStation.stCode`, `rwagnumDisl.destinationStation.stName`, `rwagnumDisl.parkSign`, `useCategory.categoryUseName`, `operCategory`, `ownershipType.ownTypeName`, `wagPassport.wagContractActual.renterName`, `wagPassport.wagContractActual.contractNumber`, `wagPassport.wagContractActual.contractorName`, `ownershipDateStart`, `wheelsetArchiveByDefect.wheelset1RimMin`, `wheelsetArchiveByDefect.wheelset2RimMin`, `wheelsetArchiveByDefect.wheelset3RimMin`, `wheelsetArchiveByDefect.wheelset4RimMin`, `shortLivedByDefectWheelsets`, `shortLivedByDefectBolsters`, `shortLivedByDefectFrames`, `depoWarrantyLiability.vrkCode`, `depoWarrantyLiability.depoFillName`, `wheelsetArchiveByDefect.wheelset1Depo.vrkCode`, `wheelsetArchiveByDefect.wheelset1Depo.depoFillName`, `wheelsetArchiveByDefect.wheelset1Date`, `wheelsetArchiveByDefect.wheelset2Depo.vrkCode`, `wheelsetArchiveByDefect.wheelset2Depo.depoFillName`, `wheelsetArchiveByDefect.wheelset2Date`, `wheelsetArchiveByDefect.wheelset3Depo.vrkCode`, `wheelsetArchiveByDefect.wheelset3Depo.depoFillName`, `wheelsetArchiveByDefect.wheelset3Date`, `wheelsetArchiveByDefect.wheelset4Depo.vrkCode`, `wheelsetArchiveByDefect.wheelset4Depo.depoFillName`, `wheelsetArchiveByDefect.wheelset4Date`, `repairInvoice.forRepairInvoiceNumber`, `repairInvoice.forRepairRace.documentState`, `repairInvoice.forRepairRace.sendSt.rwShortName`, `repairInvoice.forRepairRace.sendSt.stName`, `repairInvoice.forRepairRace.receiveSt.rwShortName`, `repairInvoice.forRepairRace.receiveSt.stName`, `repairInvoice.forRepairRace.consigneeOkpo`, `repairInvoice.forRepairRace.consigneeName`, `repairInvoice.forRepairRace.invoiceDateCreate`, `repairInvoice.forRepairRace.datePriem`, `repairInvoice.forRepairRace.dateArrival`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 74](../../app/src/main/java/ru/fgk/ws/app/view/vrepairabdpvarch/VRepairAbdpvAllocationListView.java) `vRepairAbdpvArchesDl.setParameter("allocationOperRepairList", allocationOperRepairList);`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N043. rp_VRpOperBalanceWag.list — `rp_VRpOperBalanceWag.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/rp/view/reportrpoperbalance/vrpoperbalancewag/v-rp-oper-balance-wag-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/rp/view/reportrpoperbalance/vrpoperbalancewag/VRpOperBalanceWagListView.java).
- Загрузчики: Нет query loader; требуется адаптер/контекст владельца..
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: обычный список; проверить начальные параметры и пагинацию.
- Целевой каталог для `vRpOperWagsDataGrid`: `defectDate`, `repairDepoCode`, `repairStationId`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N044. Договоры аренды вагона — `rs_VContractWag.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/rs/view/vcontractwag/v-contract-wag-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/rs/view/vcontractwag/VContractWagListView.java).
- Загрузчики: `vContractWagsDl` → `ru.fgk.ws.app.rs.entity.VContractWag`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: динамические параметры/условия.
- Целевой каталог для `vContractWagsDataGrid`: `contract.contractor`, `contract.contractNum`, `contract.contractDate`, `contract.contractType`, `dateStart`, `dateEnd`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 44](../../app/src/main/java/ru/fgk/ws/app/rs/view/vcontractwag/VContractWagListView.java) `vContractWagsDl.setParameter("wagIds", wagIds);`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

### N045. Перечень вагонов для справки Отцепка вагонов в ТР — `v_rp_oper_defect_wags.list`

- [ ] Перевести и принять страницу; сейчас **не начато**.
- Источники: [XML](../../app/src/main/resources/ru/fgk/ws/app/rp/view/reportrpoperdefectlist/vrpoperdefectwags/v-rp-oper-defect-wags-list-view.xml); [контроллер](../../app/src/main/java/ru/fgk/ws/app/rp/view/reportrpoperdefectlist/vrpoperdefectwags/VRpOperDefectWagsListView.java).
- Загрузчики: `vRepairAbdpvArchesDl` → `ru.fgk.ws.app.wagons.entity.VRepairAbdpvArchForDefectWagList`.
- Текущие фильтры: Стандартных property/jpql/genericFilter нет..
- Прочие поля ввода для проверки: не обнаружены вне property binding.
- Особенности: динамические параметры/условия.
- Целевой каталог для `vRpOperDefectWagsDataGrid`: `vRepairAbdpvArch.wagnum`, `vRepairAbdpvArch.useCategory.mnem`, `vRepairAbdpvArch.defectDate`, `vRepairAbdpvArch.repairType52`, `vRepairAbdpvArch.defectReason`, `vRepairAbdpvArch.defectDepoCode.depoFillName`, `vRepairAbdpvArch.defectDepoCode.railway.rwShortName`, `vRepairAbdpvArch.defectStation.fillName`, `vRepairAbdpvArch.dateArrival2RepairStation`, `vRepairAbdpvArch.repairDate`, `vRepairAbdpvArch.repairType62`, `vRepairAbdpvArch.repairDetail.depoRepair.vrkCode`, `vRepairAbdpvArch.repairDetail.depoRepair.depoFillName`, `vRepairAbdpvArch.defectCodes`, `vRepairAbdpvArch.defectCode1.dmName`, `vRepairAbdpvArch.defectUnit1`, `vRepairAbdpvArch.defectUnit2`, `vRepairAbdpvArch.repairLiability`, `vRepairAbdpvArch.warrantyRepair`, `vRepairAbdpvArch.ownershipType.ownTypeName`, `vRepairAbdpvArch.ownershipDateStart`. Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.
- Зависимости: F02, F03, F04, F05, F06, F07, F08; [общая приёмка страницы](11-acceptance.md#page).
- Места изменения значений (кандидаты, включая renderers): [строка 140](../../app/src/main/java/ru/fgk/ws/app/rp/view/reportrpoperdefectlist/vrpoperdefectwags/VRpOperDefectWagsListView.java) `vRepairAbdpvArchesDl.setParameter(`, [строка 142](../../app/src/main/java/ru/fgk/ws/app/rp/view/reportrpoperdefectlist/vrpoperdefectwags/VRpOperDefectWagsListView.java) `vRepairAbdpvArchesDl.setParameter("reportName", reportName);`
- Роли (включая наследование исходных resource roles): [FullAccessRole.java](../../app/src/main/java/ru/fgk/ws/app/security/FullAccessRole.java)
- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.
- Старый режим: исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать.

## Исключения из автоматического добавления

Каждый исключённый экран остаётся в реестре. Для редактируемых composition не добавлять query loader ради фильтра.

| ID | Экран | Причина |
|---|---|---|
| X001 | [DiadocSignSettings.detail](../../app/src/main/resources/ru/fgk/ws/app/diadoc/view/settings/diadoc-sign-settings-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X002 | [DocumentUpdateView](../../app/src/main/resources/ru/fgk/ws/app/diadoc/view/documentupdate/document-update-view.xml) | Форма запуска обновления документов; входные идентификаторы являются командой, а не фильтром списка. |
| X003 | [DrBackgroundExportSettingsView](../../app/src/main/resources/ru/fgk/ws/app/dr/view/drexportfiles/dr-background-export-settings-view.xml) | Форма параметров/команды без собственного списка; параметры не являются фильтром таблицы. |
| X004 | [DrBackgroundExportTr1SettingsView](../../app/src/main/resources/ru/fgk/ws/app/dr/view/drexporttr1files/dr-background-export-tr1-settings-view.xml) | Форма параметров/команды без собственного списка; параметры не являются фильтром таблицы. |
| X005 | [DrContractCdi.detail](../../app/src/main/resources/ru/fgk/ws/app/view/drcontractcdi/dr-contract-cdi-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X006 | [DrContractCdiWork.detail](../../app/src/main/resources/ru/fgk/ws/app/drcontract/view/dr-contract-cdi-work-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X007 | [DrContractCdiWorkGroup.detail](../../app/src/main/resources/ru/fgk/ws/app/view/drcontractcdiworkgroup/dr-contract-cdi-work-group-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X008 | [DrRefund.detail](../../app/src/main/resources/ru/fgk/ws/app/dr/view/drrefund/dr-refund-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X009 | [DrRefundCost.detail](../../app/src/main/resources/ru/fgk/ws/app/dr/view/drrefundcost/dr-refund-cost-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X010 | [NvProcessingSettings.detail](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/nvprocessingsettings/nv-processing-settings-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X011 | [PlanRepairControlDateDetail](../../app/src/main/resources/ru/fgk/ws/app/view/planrepaircontroldatedetail/plan-repair-control-date-detail.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X012 | [PtDetailPasteView](../../app/src/main/resources/ru/fgk/ws/app/pt/view/ptdetailpaste/pt-detail-paste-view.xml) | Редактирование/проверка вставленного набора деталей перед командой; не скрывать строки операции. |
| X013 | [PtRepairPacketExportFilesSettingsView](../../app/src/main/resources/ru/fgk/ws/app/pt/view/ptrepairpacketexportfiles/pt-repair-packet-export-files-settings-view.xml) | Форма параметров/команды без собственного списка; параметры не являются фильтром таблицы. |
| X014 | [RegistryUnloadView](../../app/src/main/resources/ru/fgk/ws/app/pt/view/ptrepairpacket/registry-unload-view.xml) | Форма параметров/команды без собственного списка; параметры не являются фильтром таблицы. |
| X015 | [ScreenTablesView](../../app/src/main/resources/ru/fgk/ws/app/view/screentablesview/screen-tables-view.xml) | Служебный обзор экранов и прав; выбор пользователя/экрана задаёт контекст диагностики. |
| X016 | [TransferToLawDepartmentView](../../app/src/main/resources/ru/fgk/ws/app/dr/view/vwagoperrepaircontract/transfer-to-law-department-view.xml) | Форма параметров/команды без собственного списка; параметры не являются фильтром таблицы. |
| X017 | [VDrContract.detail](../../app/src/main/resources/ru/fgk/ws/app/drcontract/view/v-dr-contract-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X018 | [VDrContractReport](../../app/src/main/resources/ru/fgk/ws/app/drcontract/view/v-dr-contract-detail-report-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X019 | [WnNotesDTO.detail](../../app/src/main/resources/ru/fgk/ws/app/wagons/view/wn-notes-dto-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X020 | [da_ClaimDepo.detail](../../app/src/main/resources/ru/fgk/ws/app/da/view/claimdepo/claim-depo-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X021 | [da_ContractAgent.detail](../../app/src/main/resources/ru/fgk/ws/app/da/view/dacontractagent/da-contract-agent-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X022 | [da_VRepairAbdpvArchClaim.detail](../../app/src/main/resources/ru/fgk/ws/app/da/view/repairclaim/v-repair-abdpv-arch-claim-detail-view.xml) | Карточка ремонта с дочерними данными, не самостоятельный список. |
| X023 | [diadoc_DiadocManualSync.view](../../app/src/main/resources/ru/fgk/ws/app/diadoc/view/manualsync/diadoc-manual-sync-view.xml) | Форма запуска синхронизации; не менять параметры команды на фильтр результатов. |
| X024 | [diadoc_DiadocPacket.detail](../../app/src/main/resources/ru/fgk/ws/app/diadoc/view/diadocpacket/diadoc-packet-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X025 | [diadoc_DiadocSigning.detail](../../app/src/main/resources/ru/fgk/ws/app/diadoc/view/signing/diadoc-signing-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X026 | [diadoc_DiadocVagTkImportDocumentsCompare.list](../../app/src/main/resources/ru/fgk/ws/app/diadoc/view/vagtkimport/diadoc-vagtk-import-documents-compare-view.xml) | Сопоставление двух подготовленных наборов документов; отдельный фильтр может скрыть одну сторону сравнения. |
| X027 | [diadoc_DiadocVagTkImportResultDialog.list](../../app/src/main/resources/ru/fgk/ws/app/diadoc/view/vagtkimport/diadoc-vagtk-import-result-dialog-view.xml) | Результат разового импорта; в этом этапе не добавлять сохранённые пресеты. |
| X028 | [diadoc_SambaExport](../../app/src/main/resources/ru/fgk/ws/app/diadoc/view/sambaexport/diadoc-samba-export-view.xml) | Форма параметров/команды без собственного списка; параметры не являются фильтром таблицы. |
| X029 | [dr_DiadocOperRepairPacket.detail](../../app/src/main/resources/ru/fgk/ws/app/dr/view/drdiadocoperrepairpacket/dr-diadoc-oper-repair-packet-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X030 | [dr_DiadocOperRepairPacketMaintainability.detail](../../app/src/main/resources/ru/fgk/ws/app/dr/view/drdiadocoperrepairpacket/dr-diadoc-oper-repair-packet-maintainability-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X031 | [dr_DiadocOperRepairPacketVu23.detail](../../app/src/main/resources/ru/fgk/ws/app/dr/view/drdiadocoperrepairpacket/dr-diadoc-oper-repair-packet-vu23-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X032 | [dr_DiadocOperRepairTr1.detail](../../app/src/main/resources/ru/fgk/ws/app/dr/view/drdiadocoperrepairtr1/dr-diadoc-oper-repair-tr1-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X033 | [dr_DiadocWagOperRepairContract.detail](../../app/src/main/resources/ru/fgk/ws/app/asuvrk/view/diadocwagoperrepaircontract/diadoc-wag-oper-repair-contract-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X034 | [dr_DiadocWagPlanRepairContract.detail](../../app/src/main/resources/ru/fgk/ws/app/asuvrk/view/diadocwagplanrepaircontract/diadocwagplanrepaircontract/diadoc-wag-plan-repair-contract-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X035 | [dr_VWagOperRepairContract.detail](../../app/src/main/resources/ru/fgk/ws/app/dr/view/vwagoperrepaircontract/v-wag-oper-repair-contract-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X036 | [dr_WagOperRepairContractUser.detail](../../app/src/main/resources/ru/fgk/ws/app/dr/view/wagoperrepaircontractuser/wag-oper-repair-contract-user-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X037 | [dt_OperRepairNormsDefect.detail](../../app/src/main/resources/ru/fgk/ws/app/dt/view/dtoperrepairnormsdefect/dt-oper-repair-norms-defect-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X038 | [dt_OperRepairNormsModel.detail](../../app/src/main/resources/ru/fgk/ws/app/dt/view/dtoperrepairnormsmodel/dt-oper-repair-norms-model-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X039 | [fragment:ru/fgk/ws/app/da/view/fragment/da-contract-agent-copies-document-fg.xml](../../app/src/main/resources/ru/fgk/ws/app/da/view/fragment/da-contract-agent-copies-document-fg.xml) | Переиспользуемый фрагмент без существующего фильтра; самостоятельного списка/ключа view нет. |
| X040 | [fragment:ru/fgk/ws/app/drcontract/view/fragment/drcontractcopiesdocumentfg/dr-contract-copies-document-fg.xml](../../app/src/main/resources/ru/fgk/ws/app/drcontract/view/fragment/drcontractcopiesdocumentfg/dr-contract-copies-document-fg.xml) | Переиспользуемый фрагмент без существующего фильтра; самостоятельного списка/ключа view нет. |
| X041 | [fragment:ru/fgk/ws/app/dt/view/dtoperrepairnorms/fragment/dt-downtime-calculation-fragment.xml](../../app/src/main/resources/ru/fgk/ws/app/dt/view/dtoperrepairnorms/fragment/dt-downtime-calculation-fragment.xml) | Переиспользуемый фрагмент без существующего фильтра; самостоятельного списка/ключа view нет. |
| X042 | [fragment:ru/fgk/ws/app/dt/view/dtoperrepairnorms/fragment/dt-downtime-fragment.xml](../../app/src/main/resources/ru/fgk/ws/app/dt/view/dtoperrepairnorms/fragment/dt-downtime-fragment.xml) | Переиспользуемый фрагмент без существующего фильтра; самостоятельного списка/ключа view нет. |
| X043 | [fragment:ru/fgk/ws/app/dt/view/dtoperrepairnorms/fragment/dt-non-downtime-wagons-fragment.xml](../../app/src/main/resources/ru/fgk/ws/app/dt/view/dtoperrepairnorms/fragment/dt-non-downtime-wagons-fragment.xml) | Переиспользуемый фрагмент без существующего фильтра; самостоятельного списка/ключа view нет. |
| X044 | [legal_CaseOneApiProbeView](../../app/src/main/resources/ru/fgk/ws/app/legal/caseone/view/probe/case-one-api-probe-view.xml) | Форма параметров/команды без собственного списка; параметры не являются фильтром таблицы. |
| X045 | [nsi_Department.detail](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/department/department-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X046 | [nsi_NsiNoticeMail.detail](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/noticemail/notice-mail-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X047 | [nsi_NvReceiptCost.list](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/nvreceiptcost/nv-receipt-cost-list-view.xml) | Составной редактор периодов и цен с KeyValue pivot; в этом этапе оставить подбор периода и редактируемые строки. |
| X048 | [nsi_NvReceiptCostPeriod.detail](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/nvreceiptcost/nv-receipt-cost-period-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X049 | [nsi_NvReceiptCostWsPivot.detail](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/nvreceiptcost/nv-receipt-cost-ws-pivot-detail-view.xml) | Форма параметров/команды без собственного списка; параметры не являются фильтром таблицы. |
| X050 | [nsi_NvValidationDictionary.detail](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/nvvalidationdictionary/nv-validation-dictionary-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X051 | [nsi_VDepartment.detail](../../app/src/main/resources/ru/fgk/ws/app/nsi/view/vdepartment/v-department-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X052 | [pt_PtRepairPacket.detail](../../app/src/main/resources/ru/fgk/ws/app/pt/view/ptrepairpacket/pt-repair-packet-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X053 | [pt_PtRepairPacketMoving.detail](../../app/src/main/resources/ru/fgk/ws/app/pt/view/ptrepairpacketmoving/pt-repair-packet-moving-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X054 | [pt_RepairClaim.detail](../../app/src/main/resources/ru/fgk/ws/app/pt/view/ptrepairclaim/pt-repair-claim-detail-view.xml) | Редактируемая composition претензии; фильтр не должен скрывать сохраняемые строки. |
| X055 | [pt_RepairContract.detail](../../app/src/main/resources/ru/fgk/ws/app/pt/view/ptrepaircontract/pt-repair-contract-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X056 | [rp_VRepairAbdpvArch.detail](../../app/src/main/resources/ru/fgk/ws/app/repair/view/vrepairabdpvarch/v-repair-abdpv-arch-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X057 | [rs_VContract.detail](../../app/src/main/resources/ru/fgk/ws/app/rs/view/vcontract/v-contract-detail-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X058 | [vOperRepairDocFlowFullListViewRegistryUnloadView](../../app/src/main/resources/ru/fgk/ws/app/dr/view/voperrepairdocflow/voperrepairdocflow-registry-unload-view.xml) | Форма параметров/команды без собственного списка; параметры не являются фильтром таблицы. |
| X059 | [wn_VWagEquipment](../../app/src/main/resources/ru/fgk/ws/app/wagons/view/vwagpassport/v-wag-equipment-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X060 | [wn_VWagRegisterArchive](../../app/src/main/resources/ru/fgk/ws/app/wagons/view/vwagpassport/v-wag-register-archive-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
| X061 | [wn_VWagRepairArchive](../../app/src/main/resources/ru/fgk/ws/app/wagons/view/vwagpassport/v-wag-repair-archive-view.xml) | Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида. |
