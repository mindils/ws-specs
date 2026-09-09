# Backlog: подключение RVK Filter к остальным страницам

[К текущей задаче](README.md) · [Реестр исходного аудита](page-inventory.json)

**Отложено решением пользователя 2026-09-07. Не входит в текущее задание.**
На страницах rvk-ws, где RVK Filter ещё не подключён, фильтр сейчас не добавлять. Этот backlog выполняется только по отдельной будущей задаче.

Текущая задача — проверить и довести аддон и уже подключённые страницы: M001 `nsi_NvPartType.list`, M002 `RejectReason.list`, M003 `nsi_VDepo.list`, N002 `DiadocDocumentType.list`. Их доработка и исправление регрессий остаются в текущем объёме. Административные list/detail views аддона также остаются в нём.

## Отложенный объём

Из исходных 95 карточек M и 45 карточек N четыре уже подключены. Остальные **136 страниц** перенесены сюда: **92 M** (M004–M095) и **44 N** (N001, N003–N045). Ни одна не считается выполненной или отменённой; статус — отложено.

Вместе с добавлением отложены волны массового внедрения, рецепт перевода следующих страниц и их индивидуальная приёмка. Функциональные требования к самому аддону (F02–F07) не объявляются выполненными и не отменяются этим переносом. Специальные возможности, нужные только будущей странице, проверяются до её будущего подключения.

## Список страниц

| ID | Страница | viewId | Подробная карточка |
|---|---|---|---|
| M004 | Договоры на ТР-2 с ЦДИ | `DrContractCdi.list` | [M004: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M005 | Пакеты ремонтов ТР-1 | `DrDiadocOperRepairTr1.list` | [M005: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M006 | Справочник работ по замене деталей | `DrTrWork.list` | [M006: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M007 | Неисправности вагонов | `NsiNvDefectGroup.list` | [M007: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M008 | Группы деталей | `VrkDetailGroup.list` | [M008: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M009 | Прототипы деталей | `VrkDetailPrototype.list` | [M009: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M010 | Передача документов в ДЮ | `dt_VOperRepair.list` | [M010: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M011 | Словари текстовых валидаций | `nsi_NvValidationDictionary.list` | [M011: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M012 | Дороги | `nsi_VRailway.list` | [M012: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M013 | Списки деталей | `pt_PtList.list` | [M013: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M014 | Договоры на ремонт деталей | `pt_RepairContract.list` | [M014: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M015 | Списки ремонтов | `rp_RepairList.list` | [M015: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M016 | Списки вагонов | `wn_WnList.list` | [M016: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M017 | Dr contract cdi work groups | `DrContractCdiWorkGroup.list` | [M017: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M018 | Архив обработки ремонтов | `ImportedPacketArch.list` | [M018: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M019 | Пользователи АСУ РВК | `User.list` | [M019: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M020 | Подразделения АО "ФГК" | `nsi_Department.list` | [M020: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M021 | Рассылка по выпуску | `nsi_NsiNoticeMail.list` | [M021: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M022 | Страны | `nsi_VCountry.list` | [M022: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M023 | msg://VDepartmentListView.title | `nsi_VDepartment.list` | [M023: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M024 | Станции | `nsi_VStation.list` | [M024: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M025 | Список подрядчиков | `v_depo_contractor.list` | [M025: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M026 | Договоры по ремонту вагонов | `VDrContract.list` | [M026: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M027 | Справочник предприятий | `da_ClaimDepo.list` | [M027: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M028 | Справочник реквизитов предприятий ремонта для заявок на ТР | `da_ClaimDepoVisa.list` | [M028: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M029 | Claim depo stations | `da_ClaimStation.list` | [M029: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M030 | Агентские договоры на выполнение ТР | `da_ContractAgent.list` | [M030: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M031 | Заявки по РФ | `da_RepairClaimRf.list` | [M031: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M032 | Остаток в ТР по СНГ | `da_VOperBalanceSng.list` | [M032: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M033 | msg://departmentsVisaListView.title | `nsi_DepartmentsVisa.list` | [M033: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M034 | Договоры аренды | `rs_VTabContract.list` | [M034: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M035 | История УКВ | `PtUkvArchive.list` | [M035: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M036 | Ремонты | `VRepairAbdpvArch.list` | [M036: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M037 | Замена деталей по 4624 | `VRepairDetailLink.list` | [M037: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M038 | Архив реестра вагонов | `WagArchiveView` | [M038: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M039 | Добавить к списку | `rp_RepairLists.list` | [M039: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M040 | Архив комплектаций | `wn_VWagEquipmentArchive.list` | [M040: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M041 | Таблица паспортов | `wn_VWagPassport.list` | [M041: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M042 | Расчетный остаток пробега для вагонов, ремонтируемых по единичному критерию | `wn_VWagPassportCalculatedRun.list` | [M042: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M043 | Таблица дислокации | `wn_VWagPassportDislocation.list` | [M043: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M044 | Добавить к списку | `wn_WnLists.list` | [M044: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M045 | Экспорт документов по ТР-2 | `dr_ExportFiles.list` | [M045: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M046 | Экспорт документов по ТР-1 | `dr_ExportTr1Files.list` | [M046: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M047 | Контроль сроков оплаты | `dr_PlanRepairControlDate.list` | [M047: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M048 | Экспорт документов по плановым ремонтам | `dr_PlannedExportFiles.list` | [M048: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M049 | Технологические ремонты | `dr_TechOperRepairContract.list` | [M049: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M050 | Оплата ТР по вагонам | `dr_VOperRepairDocFlow.list` | [M050: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M051 | Оплата ТР по вагонам | `dr_VOperRepairDocFlowFull.list` | [M051: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M052 | Вагоны ТР не в оплате | `dr_VOperRepairDocFlowNo.list` | [M052: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M053 | Оплата ТР-1 по вагонам | `dr_VTr1RepairDocFlow.list` | [M053: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M054 | Простой в ТР по вагонам | `dr_VWagOperRepairContract.list` | [M054: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M055 | Список нормативов расчета неустойки | `dt_OperRepairNorms.list` | [M055: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M056 | Акт приемки исполненных обязательств | `DrContractOperRepairUser` | [M056: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M057 | Акт приемки исполненных обязательств | `DrContractPlanRepairUserView.detail` | [M057: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M058 | Настройки обработки | `NvProcessingSettings.list` | [M058: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M059 | Учет ремонта деталей | `PtRepairClaimItem.list` | [M059: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M060 | Пакеты по ремонту деталей | `PtRepairPacket.list` | [M060: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M061 | Очередь запросов по деталям в ЕО | `RequestInform.list` | [M061: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M062 | Справочник работ по ремонту деталей | `VNvPartRepairWork.list` | [M062: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M063 | Фоновая задача | `common_BackgroundJobTask.detail` | [M063: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M064 | Журнал рассылки по выпуску из НРП | `da_NsiMailSendLog.list` | [M064: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M065 | Заявки на ремонт | `da_RepairClaim.list` | [M065: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M066 | Архив рассылки по выпуску из НРП | `da_RepairNoticeArchive.list` | [M066: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M067 | Пакеты документов Диадок | `diadoc_DiadocPacket.list` | [M067: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M068 | Подписание | `diadoc_DiadocSigning.list` | [M068: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M069 | Пакеты МХ-1 | `dr_DiadocOperRepairPacket.list` | [M069: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M070 | Пакеты Хранение и Ремпригодность | `dr_DiadocOperRepairPacketMaintainability.list` | [M070: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M071 | Пакеты рекламаций | `dr_DiadocOperRepairPacketReclamation.list` | [M071: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M072 | Пакеты ВУ-23 | `dr_DiadocOperRepairPacketVu23.list` | [M072: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M073 | Diadoc wag oper repair contracts | `dr_DiadocWagOperRepairContract.list` | [M073: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M074 | Акты по ТР-1 | `dr_Tr1ActsListView` | [M074: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M075 | Остатки деталей по 1С | `pt_1cBalance.list` | [M075: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M076 | Добавить к списку | `pt_PtLists.list` | [M076: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M077 | Экспорт документов по ремонту деталей | `pt_PtRepairPacketExportFiles.list` | [M077: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M078 | Заявки на ремонт деталей | `pt_RepairClaim.list` | [M078: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M079 | Комплектация вагонов | `wn_VWagEquipmentList.list` | [M079: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M080 | История перевозочных документов | `wn_VWagInvoiceArchive` | [M080: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M081 | Отчет Распределение вагонов в ТР | `ReportAllocationOperRepair.list` | [M081: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M082 | Допретензионная работа | `ReportWagOperRepairDto.list` | [M082: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M083 | Количество предыдущих отцепок | `UncouplingCountView` | [M083: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M084 | Статистика экранов | `UserActivityStats.list` | [M084: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M085 | Выгрузка на прошлую дату | `WnWagArchiveSpecsDto.list` | [M085: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M086 | Последний выпуск по списку | `WnWagLastOper62Dto.list` | [M086: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M087 | Добавление пакетов из ВакТк | `diadoc_DiadocVagTkImport.list` | [M087: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M088 | Справка по документообороту | `dr_ReportOperRepairDocFlowDto.list` | [M088: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M089 | Анализ стоимости ТР-2 | `dr_ReportTR2PriceAnalyzeDtoListView.list` | [M089: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M090 | Отчет по срокам хранения в 1С | `pt_Pt1cStorageReport.list` | [M090: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M091 | Реестр деталей | `pt_PtPart.list` | [M091: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M092 | Остаток вагонов в ТР | `rp_VRpOperBalance.list` | [M092: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M093 | Отцепка вагонов в текущий ремонт | `rp_VRpOperDefect.list` | [M093: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M094 | Поиск по номеру детали | `wn_VWagEquipmentArchiveFind.list` | [M094: исходные файлы, поля и зависимости](09-existing-pages.md) |
| M095 | История операций | `wn_VWagOperArchive` | [M095: исходные файлы, поля и зависимости](09-existing-pages.md) |
| N001 | Организации диадок | `DiadocContractor.list` | [N001: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N003 | Настройки подписания | `DiadocSignSettingsDocType.list` | [N003: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N004 | Периоды (Договоры ТР-2 на ЦДИ) | `DrContractCdiPeriod.list` | [N004: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N005 | Работы ТР-2 на ЦДИ | `DrContractCdiWork.list` | [N005: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N006 | Работы ТР-2 на ЦДИ | `DrContractCdiWorkPrice.list` | [N006: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N007 | Рассчеты на возмещение затрат | `DrRefund.list` | [N007: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N008 | Стоимость ТР-1 по РФ | `DrTr1Cost.list` | [N008: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N009 | Сбор за подачу/уборку ТР | `DrTrSupplyOutPeriod.list` | [N009: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N010 | Ставки НДC | `NsiNds.list` | [N010: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N011 | Перечень вагонов | `ReportTr2WagonListView` | [N011: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N012 | Автосцепка | `VCouplerType.list` | [N012: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N013 | Регионы | `VNvRegion.list` | [N013: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N014 | Перечень вагонов | `VRpOperWagListView` | [N014: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N015 | Контрагенты | `VrkContractor.list` | [N015: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N016 | Виды документов | `VrkDocumentType.list` | [N016: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N017 | Модернизации | `VrkModernization.list` | [N017: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N018 | Виды ремонтов | `VrkRepairType.list` | [N018: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N019 | Типы вагонов | `VrkWagonType.list` | [N019: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N020 | Группы работ | `VrkWorkGroup.list` | [N020: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N021 | Документы из АСУ ВРК | `WagOperRepairFileListView` | [N021: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N022 | Конструктор примечаний | `WnNotesHead.list` | [N022: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N023 | История диалогов | `ai_AiConversation.list` | [N023: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N024 | Мои фоновые задачи | `common_BackgroundJobTask.list` | [N024: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N025 | Мои загрузки | `common_ExportTask.list` | [N025: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N026 | Заявки для отправки | `da_RepairClaimNoSend.list` | [N026: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N027 | Планируется к рассылке | `da_RepairClaimRfNoSend.list` | [N027: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N028 | Планируется к рассылке по выпуску из НРП | `da_RepairNoticeNoSend.list` | [N028: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N029 | Исходящие пакеты Диадок | `diadoc_DiadocOutboundPacket.list` | [N029: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N030 | Все пакеты по ремонту | `dr_RepairPacketRow.list` | [N030: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N031 | История перемещения детали по МХ | `dr_VPartMovementHistory.list` | [N031: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N032 | Состояние букс | `nsi_NsiVNvWsBox.list` | [N032: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N033 | Состояние КП | `nsi_NsiVNvWsCondition.list` | [N033: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N034 | Диапазоны толщины обода | `nsi_NsiVNvWsRim.list` | [N034: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N035 | Текстовые варианты для DIADOC | `nsi_NvPartTypeDiadocDictionary.list` | [N035: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N036 | Филиалы пользователя | `nsi_UserDepartmentLink.list` | [N036: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N037 | Поглощающие аппараты | `nsi_VAbsorberType.list` | [N037: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N038 | Авторегулятор рычажной передачи | `nsi_VAutoregulator.list` | [N038: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N039 | Материал кузова | `nsi_VBodyMaterial.list` | [N039: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N040 | Тип оси КП | `nsi_VNvAxleType.list` | [N040: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N041 | Габарит вагона | `nsi_VWagSize.list` | [N041: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N042 | Перечень вагонов из Распределения в ТР | `rp_VRepairAbdpvAllocation.list` | [N042: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N043 | rp_VRpOperBalanceWag.list | `rp_VRpOperBalanceWag.list` | [N043: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N044 | Договоры аренды вагона | `rs_VContractWag.list` | [N044: исходные файлы, поля и зависимости](10-additional-pages.md) |
| N045 | Перечень вагонов для справки Отцепка вагонов в ТР | `v_rp_oper_defect_wags.list` | [N045: исходные файлы, поля и зависимости](10-additional-pages.md) |

## Как вернуться к backlog

1. Получить отдельное задание на конкретную страницу или волну; порядок первоначального аудита сохранён в F09/F10 как справочная информация.
2. Сверить карточку с актуальными исходниками: снимок 2026-09-05 не является текущим статусом кода.
3. До добавления обеспечить нужные операции/типизацию/providers, сохранение базовых ограничений, режимы и права.
4. Выполнить проверки F11 для выбранной страницы; отметка backlog не заменяет проверку данных и браузера.

61 исключение X001–X061 сохранено в F10 и не включено в эти 136 задач. Composition, служебные и прочие исключённые views не подключаются автоматически.
