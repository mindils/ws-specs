# Претензии по технологическим неисправностям: экраны, роли, сроки

Состояние: closed
Итог: [summary.md](summary.md)
Дата закрытия: 2026-09-15
Предыдущая работа: [dr-warranty-repair-rename-ui](../dr-warranty-repair-rename-ui/summary.md)
Дата согласования: 2026-09-14

## Цель и границы

Перенос функционала ВагТК «Оплата ремонтов / Претензии / Технологические / по
вагонам» (MSSQL: таблица `dbo.TrkRemPretens`, процедура `pThp_PretTehSelect2`,
форма «Редактирование претензий») в Jmix 3, раздел `legal`.

**Что уже есть** (сделано и независимо проверено в предыдущей работе, лежит в
рабочем дереве ветки `feature/caseone-table`, не закоммичено):

- четыре таблицы модели `dr_warranty_repair`, `_deps`, `_du`, `_case_one`
  (175 колонок), entity `LegalWarrantyRepair*` в пакете
  `ru.fgk.ws.app.legal.warrantyrepair`, роль `legal-warranty-repair`;
- НСИ сроков: производственный календарь `nsi_work_calendar_day`
  (2024-01-01 … 2026-12-31), нормы `nsi_claim_term_norm` (семь норм),
  ревизии `nsi_term_revision` с публикацией; экраны НСИ и роль
  `nsi-claim-term-edit`;
- Java-расчёт семи сроков этапов и порогов просрочки (`ClaimTermCalculator`,
  `WarrantyRepairDeadlineService`), таблица `dr_warranty_repair_deadlines`,
  пересчёт при изменении данных и при публикации ревизии;
- db-view `dr_v_warranty_repair_claim` (104 колонки: поля четырёх таблиц и
  суммы) и entity `VWarrantyRepairClaim` — без блока сроков;
- `./gradlew :app:test` — 1348 passing, 0 failing.

**Требуемый результат этой работы:**

1. Модель переименована в `legal_tech_claim*` на всех слоях (таблицы, view,
   классы, пакет, Jmix-имена, роли, i18n, тесты) — см. «Общие решения».
2. View отдаёт семь сроков, степени просрочки и признак неактуального расчёта,
   а также недостающие колонки старого отчёта; фильтрация, сортировка и count
   по ним выполняются в БД.
3. Три роли: ДЭПС, ДЮ, администратор раздела; сервис создания дополнительной
   претензии по отцепке.
4. Один список претензий и одна карточка с вкладками «Документы»,
   «Допретензионная работа», «Претензия», «Судебная работа», «Сроки»; зоны
   ДЭПС и ДЮ различаются только правами на поля. Один пункт меню.
5. Сквозная проверка под двумя ролями в браузере, гейты зелёные, документы
   спеки обновлены.

**Не входит:** перелив данных из ВагТК и внешнего источника (NiFi), сервис
автозаполнения отцепки, создание и редактирование отцепки в UI, отправка
карточки в Case.one, вкладка «Копии документов», автомат даты комплекта по
реализации деталей (45 дней), восьмой индикатор `Srok_FilOColor`, отчётные
агрегаты `@Col`, наполнение календаря 2027 года ([Q01](questions/Q01.md)).

## Материалы

| Файл | Содержание |
|---|---|
| `specs/dr-warranty-repair/README.md`, `01-old-table.md`, `02-old-procedure.md` | Обзор, старая таблица (129 колонок), процедура (параметры → фильтры, формулы вычисляемых полей) |
| `specs/dr-warranty-repair/03-old-form.md` + четыре `*.png` | Раскладка полей старой формы по вкладкам; скриншоты — первоисточник, текст 03 содержит ошибки (см. «Общие решения», раскладка) |
| `specs/dr-warranty-repair/05-column-mapping.md`, `08-status-and-next-steps.md` | Маппинг старых колонок и исправления черновика |
| `specs/dr-warranty-repair/04-new-model.md` | Устарел: имена `legal_warranty_repair*` со старыми колонками; фактическая модель — entity в коде |
| [report-columns.md](input/report-columns.md) | 154 колонки отчёта «Перечень вагонов» → колонка модели/view, статус, видимость в гриде по умолчанию |
| [pThp_PretTehSelect2.sql](input/pThp_PretTehSelect2.sql), [fTHP_SrokDay.sql](input/fTHP_SrokDay.sql) | Первоисточник алгоритмов; при расхождении с пересказом приоритет у SQL |
| [srok-calc-notes.md](input/srok-calc-notes.md), [nvPretSrok_idoper_9-16.md](input/nvPretSrok_idoper_9-16.md) | Навигация по расчёту сроков и значения норм |
| [calendar-behavior-differences.md](input/calendar-behavior-differences.md) | Согласованные отличия календарного расчёта, карта кода T07/T08 прежней работы, контракт актуальности расчёта, таблица дат факта завершения этапов |
| [Итог предыдущей работы](../dr-warranty-repair-rename-ui/summary.md) | Что реализовано, проверено и где лежит |

Скриншоты формы (кратко, для сессий без просмотра картинок). Шапка: № вагона,
Оперирование, Дата планового ремонта/постройки, Вид планового ремонта, Дорога
ремонта/постройки; Дата браковки, Дорога, Технологическая неисправность
(код + наименование); блок «Наименование контрагента, ответственного за
возмещение затрат» — переключатель: ВРП (код клейма, ВРК, наименование) либо
текстовый контрагент. Вкладка «Документы»: Подлежит/не подлежит; Вызывная
телеграмма (№, дата отправки, ФИО принявшего, дата принятия); Приёмка
рекламационных документов (дата проверки, принята/отклонена, причина
отклонения, примечание); ВУ-41 (номер, дата); Договор на плановый ремонт
(номер, дата); Дата формирования полного комплекта документов; Передача
документов для организации работ (подразделение, дата прикрепления); Передача
в допретензионную работу (подразделение, дата); Передача в претензионную работу
(перевыставление тарифа подлежит/не подлежит, дата передачи); Расчёт
требований (договор номер/дата, контрагент); Простой (суток, штраф за сутки,
сумма); Передислокация в ремонт / из ремонта / Ломаный тариф (номер накладной,
дата раскредитования, сумма платежа / расчётная сумма перевыставленных затрат);
Итого провозные платежи; Сумма ремонта, подлежащая возмещению; ВСЕГО к
возмещению. Вкладка «Допретензионная работа»: Возврат на доработку в ДЭПС
(дата, тех. номер РК в ЕАСД); Дата отправки виновнику; Письмо (дата, номер,
сумма); Рассмотрение письма контрагентом (результат, дата, номер); Передача в
претензионную работу (дата, номер ПСР по ЕАСД); Реестр передачи в ДЮ (дата,
номер). Вкладка «Претензия»: Возврат на доработку в ДЭПС (дата, тех. номер
РК); Рассмотрение претензии филиалом по виновному предприятию (принята/
отклонена, причина); Претензия (№ письма, дата, сумма, дата отправления
виновнику); Рассмотрение претензии виновным предприятием (дата получения,
принята/отклонена, дата ответа, № письма, признано рублей); Отклонение
претензии (дата передачи в судебную работу, причина отклонения); Получение
денежных средств (дата, сумма, № платёжного поручения, основание,
примечание). Вкладка «Судебная работа»: номер искового заявления, дата, номер
дела, сумма в исковых требованиях, результат рассмотрения, сумма к
удовлетворению.

## Общие решения

| Решение | Основание |
|---|---|
| Базовое имя `legal_tech_claim`. Таблицы `legal_tech_claim` (отцепка), `legal_tech_claim_deps`, `_du`, `_case_one`, `_deadlines`; view `legal_v_tech_claim`. Пакет `ru.fgk.ws.app.legal.techclaim`; классы `LegalTechClaim`, `LegalTechClaimDeps`, `LegalTechClaimDu`, `LegalTechClaimCaseOne`, `LegalTechClaimDeadline`, `VLegalTechClaim`; Jmix-имена `legal_TechClaim`, `legal_TechClaimDeps`, `legal_TechClaimDu`, `legal_TechClaimCaseOne`, `legal_TechClaimDeadline`, `legal_VTechClaim`; enum-ы `TechClaim*Enum`; сервисы `TechClaimDeadlineService`, `TechClaimDeadlineRecalculationListener`, `TechClaimDeadlinePublicationHandler`, `TechClaimService`; константы БД `PK_/IDX_/UQ_/FK_LEGAL_TECH_CLAIM*`. Классы `ClaimTerm*` и НСИ `nsi_*` не переименовываются. Имена колонок не меняются | Ответ пользователя 2026-09-14 (вариант «legal_tech_claim*») |
| Переименование на месте: файлы changelog-ов переименовываются, `createTable` создаёт новые имена сразу; `renameTable`/`renameColumn` не добавляются; локальная БД пересоздаётся | Changelog-и нигде, кроме локальной БД, не применялись (решение прежней работы) |
| UI — одна форма: один list view `legal_TechClaim.list` над `VLegalTechClaim`, один detail view `legal_TechClaim.detail` над `LegalTechClaimDeps` с вкладками «Документы», «Допретензионная работа», «Претензия», «Судебная работа», «Сроки». Зоны различаются только правами: ДЭПС правит поля `deps`, видит `du` read-only; ДЮ — наоборот. Один пункт меню в узле `legal` | Ответ пользователя 2026-09-14; так устроена старая форма |
| Отцепка (`legal_tech_claim`) в UI только читается: строки отцепок и претензий приходят загрузкой (сначала из ВагТК, затем из внешнего источника). Конфликты импорта и ручного ведения не обрабатываются | Ответ пользователя 2026-09-14: «данные просто лежат, редактировать не нужно», «после запуска зальём заново» |
| Кнопка «Создать претензию» (ДЭПС и админ) добавляет ещё одну претензию по выбранной отцепке: `claim_index = max(неудалённых)+1`, сразу с парной пустой строкой `_du`; `_case_one` не создаётся | Ответ пользователя 2026-09-14; ответ на вопрос 5 в `06-open-questions.md` |
| Роли (`legal/techclaim/security`): `legal-tech-claim-deps`, `legal-tech-claim-du`, `legal-tech-claim-admin` (переименованная полная роль). Матрица — в [T03](tasks/T03/task.md). `@ViewPolicy` на `legal_TechClaim.list`, `legal_TechClaim.detail` и `@MenuPolicy` на `legal_TechClaim.list` ставятся в T03 во все три роли до появления экранов, чтобы UI-таски роли не трогали | Техническое решение: развязать параллельные таски |
| Read-only чужой зоны — штатное поведение Jmix Flow UI (поле без права MODIFY на атрибут становится read-only). Подтверждается тестом и браузером; если не срабатывает для какого-то компонента — явный `readOnly` по `AccessManager`/`EntityAttributeContext`, без дублирования матрицы прав во view | Техническое решение |
| Detail: `StandardDetailView<LegalTechClaimDeps>`; `du` — отдельный `instanceContainer` с loader-ом `select d from legal_TechClaimDu d where d.deps.id = :depsId` в том же `DataContext`; если строки `du` нет — создаётся в контейнере при открытии. Шапка — `deps.repair` read-only. Каждая вкладка — фрагмент | Техническое решение; образцы `pt-repair-contract-detail-view.xml`, `pt-repair-claim-detail-view.xml` |
| Грид: все колонки отчёта «Перечень вагонов» со статусом ≠ `нет` из `report-columns.md`, по умолчанию видны отмеченные `да`; остальные включаются `gridColumnVisibility` (образец `rp/view/vrpoperwaglist/v-rp-oper-wag-list-view.xml`) | Ответ пользователя 2026-09-14 |
| Фильтры: все параметры `pThp_PretTehSelect2` (период ремонта, период браковки, номер вагона, дорога, депо, виновник, вид ремонта, подлежит/не подлежит, результат, маска номера претензии, реестр ДЮ номер/период, ПСР номер/период передачи, подразделение допретензионной работы, гарантийные КП) + по каждому из семи сроков диапазон дат и степень просрочки + суммы. Только `propertyFilter`/`jpqlFilter` | Ответ пользователя 2026-09-14; правило проекта |
| Сроки и степени: даты сроков и порогов — из таблицы `_deadlines` (Java-расчёт T08), степень вычисляется во view при чтении: факт завершения этапа (таблица в документе отличий), иначе `current_date`; `> порога +30 → 3`, `> +10 → 2`, `>= +1 → 1`, иначе NULL. Признак `deadlines_outdated` = нет строки расчёта или `revision_number` ≠ последней `PUBLISHED` ревизии. Цвета: 1 — жёлтый, 2 — оранжевый, 3 — красный, CSS-классы `legal-tech-claim-overdue-1/2/3` в теме `app`, подсвечивается ячейка срока, текст степени через `msg://` | Q01 предыдущей работы; ответ пользователя «цвета в коде фиксируем» |
| Вкладка «Сроки» в карточке — read-only: семь строк (этап, срок, дата факта, степень) по текущим значениям формы без сохранения через `TechClaimDeadlineService.describe(source, calculation, today)`; сохранение запускает штатный пересчёт слушателями T08 | Техническое решение; `preview(depsId)` — для сохранённого состояния |
| Одна дата «сегодня» для view и Java — `current_date` БД (`ClaimTermDateProvider`) | Решение T08 предыдущей работы |
| Календарь 2027 не заполняется до утверждения постановления Правительства | Ответ пользователя 2026-09-14; [Q01](questions/Q01.md) |
| Колонки отчёта без данных в модели (`pd1..pd5`, `Pak_Pr`, `Prich_OtklPak`, `Or_Pr_*`, `Det_*`, `Tranz_Dob`) не переносятся | Данных нет в модели; см. `report-columns.md` |

Раскладка полей карточки по вкладкам (контракт для T05; имена — Java-поля
entity, они при переименовании не меняются):

- Шапка (read-only, `deps.repair`): `wagnum`, `defectDate`, `railwayMnkd`,
  `categoryOper`, `defectCodeTn`/`defectCode1..3`, `defectName`,
  `lastRepairDate`, `lastRepairType`, `lastRepairDepoName`, `lastRepairVrk`.
  Блок виновника (зона ДЭПС, `deps`): `warrantyIsVrp`, `warrantyDepoCode`,
  `warrantyType`, `warrantyName`, `warrantyRailwayCode`, `warrantyNote`.
- «Документы» (`deps`): `subjectToClaim`; `telegramNumber`,
  `telegramSendDate`, `telegramReceivedBy`, `telegramReceiveDate`;
  `reclamationCheckDate`, `reclamationResult`, `reclamationRejectReason`,
  `reclamationNote`; `vu41Number`, `vu41Date`; `repair.lastRepairContractNum`,
  `repair.lastRepairContractDate` (read-only); `docPackageReadyDate`;
  `docTransferTo`, `docTransferDate`; `preClaimDepartment`,
  `preClaimTransferDate`; `tariffRebillSubject`, `claimTransferDate`;
  `claimContractNum`, `claimContractDate`, `claimContractorName`
  (+ `claimContractorGuid`, `claimContractorInn`); `downtimeDays`,
  `downtimePenaltyPerDay`, сумма штрафа (вычисл.); `invoiceForRepairNum`,
  `invoiceForRepairDateDebit`, `invoiceForRepairCost`; `invoiceAfterRepair*`;
  `brokenTariffInvoiceNum`, `brokenTariffDebitDate`, `brokenTariffCost`,
  `calculatedInvoiceCost`; итоги «Итого провозные платежи», «Сумма ремонта,
  подлежащая возмещению» (`warrantyRepairCost`), «ВСЕГО к возмещению» —
  вычисляемые по формулам view.
- «Допретензионная работа» (`deps`): `reworkReturnDate`,
  `reworkReturnRkNumber`; `preClaimSendDate`; `preClaimDate`,
  `preClaimNumber`, `preClaimCost`; `preClaimResult`, `preClaimReplyDate`,
  `preClaimReplyNumber`; `claimTransferDate`, `psrNumber`; `lawRegistryDate`,
  `lawRegistryNum`.
- «Претензия» (`du`): `reworkReturnDate`, `reworkReturnRkNumber`;
  `branchReviewResult`, `branchReviewRejectReason`; `claimNumber`,
  `claimDate`, `claimCost`, `claimSendDate`; `atFaultReceiveDate`,
  `claimResult`, `atFaultReplyDate`, `atFaultReplyNumber`,
  `atFaultAcceptedCost`; `toLawDate`, `claimRejectReason`; `paymentDate`,
  `paymentCost`, `paymentNumber`, `reimbursementBasis`, `paymentNote`.
- «Судебная работа» (`du`): `lawsuitNumber`, `lawsuitDate`, `caseNumber`,
  `lawsuitCost`, `lawsuitResult`, `lawsuitAcceptCost`; `lawsuitModifiedBy`,
  `lawsuitModifiedDate` read-only.
- «Сроки»: read-only таблица семи этапов.

Две похожие пары, которые в черновике спеки были перепутаны:
`deps.reworkReturn*` — возврат из допретензионной работы (вкладка
«Допретензионная работа»); `du.reworkReturn*` — возврат из претензионной
(вкладка «Претензия»). `du.claimRejectReason` = `Gar_Prich` (причина
отклонения претензии); `deps.reclamationRejectReason` = `Prich_Otkl` (причина
отклонения рекламационных документов).

**Ветка.** `feature/caseone-table`. Всё сделанное лежит незакоммиченным;
перед стартом T01 рекомендуется зафиксировать базовую линию коммитом —
переименование поверх незакоммиченных файлов делает diff нечитаемым.

**Правила проекта, критичные для работы** (`CLAUDE.md`): FK в миграциях не
создаются (`@DdlGeneration(unmappedConstraints = …)`); preConditions в каждом
changeSet; `genericFilter` не используется; весь UI-текст через `msg://`;
иконки — только реальные `VaadinIcon`; в сервисах constructor injection;
`@ViewPolicy` на каждый view в каждой роли, включая detail из диалога;
`CREATE` подразумевает `MODIFY` на редактируемых атрибутах.

## Критерии всей работы

- В `app/src` нет имён `warranty_repair`/`WarrantyRepair`/`warrantyrepair`
  в артефактах этого раздела (кроме колонки `warranty_repair` и enum
  `WarrantyRepairEnum` из `dr`, колонок `warranty_*` виновника и
  `warranty_repair_cost`); в БД созданы `legal_tech_claim*` (175 + 37
  колонок) и view `legal_v_tech_claim`.
- Пользователь с ролью ДЭПС открывает список из меню, видит колонки отчёта,
  фильтрует по параметрам и срокам, создаёт претензию по отцепке, заполняет
  «Документы» и «Допретензионную работу», сохраняет; вкладки «Претензия» и
  «Судебная работа» ему read-only.
- Пользователь с ролью ДЮ открывает ту же претензию, заполняет «Претензию» и
  «Судебную работу», сохраняет; поля ДЭПС ему read-only.
- Семь сроков и степени видны в гриде с подсветкой ячеек и на вкладке
  «Сроки»; фильтры, сортировка и count по ним выполняются в БД на выборке
  больше страницы.
- Изменение исходных дат пересчитывает сроки; смена дня меняет степень при
  следующем чтении; неактуальный расчёт помечен отдельно от неприменимого
  этапа.
- Гейты: инспекция IDE по каждому файлу (для `*-view.xml` — единственный
  статический способ поймать `msg://` и property path), `./gradlew :app:test`
  с `0 failing`, render-проход браузером по каждому view под обеими ролями.

## Таски

Порядок строк — порядок выполнения.

| Таск | Результат | Зависит от |
|---|---|---|
| [T01](tasks/T01/task.md) | Модель переименована в `legal_tech_claim*` на всех слоях; БД пересоздаётся с нуля; тесты зелёные | — |
| [T02](tasks/T02/task.md) | View `legal_v_tech_claim`: сроки, степени, `deadlines_outdated`, недостающие колонки отчёта; фильтрация в БД | T01 |
| [T03](tasks/T03/task.md) | Роли ДЭПС/ДЮ/админ с политиками; `TechClaimService.createClaim`; тесты разграничения | T01 |
| [T04](tasks/T04/task.md) | List view: колонки отчёта, фильтры, подсветка сроков, кнопка «Создать претензию», меню | T02, T03 |
| [T05](tasks/T05/task.md) | Detail view: шапка, пять вкладок, сохранение deps+du, зоны по ролям | T03 |
| [T06](tasks/T06/task.md) | Сквозная проверка под двумя ролями, документы спеки, закрытие гейтов | T04, T05 |

## Параллельность и тестирование

| Таск | Область | Общие ресурсы | Параллельно с | Проверка |
|---|---|---|---|---|
| T01 | `app/.../legal/warrantyrepair/**` → `legal/techclaim/**`, changelog-и `01-tbl/320…324`, `02_view/independent/dr_v_warranty_repair_claim.xml`, тесты раздела, блок ключей в `messages_ru.properties`, документ отличий | БД, build daemon | — (все остальные ждут) | первым |
| T02 | `02_view/independent/legal_v_tech_claim.xml`, `VLegalTechClaim`, `WarrantyRepairClaimViewIT` → `TechClaimViewIT`, блок ключей view | БД | T03 | после T01, до T03 |
| T03 | `legal/techclaim/security/*`, `legal/techclaim/service/TechClaimService`, новый IT, блок ключей ролей/сервиса | БД | T02 | после T02 |
| T04 | `legal/techclaim/view/techclaim/*ListView*` (Java + XML), фрагмент фильтров, `menu.xml`, CSS темы `frontend/themes/app/view/legal/`, блок ключей списка | БД, порт 8080, браузер | T05 (код) | после T05 |
| T05 | `legal/techclaim/view/techclaim/*DetailView*` и фрагменты вкладок (Java + XML), блок ключей карточки | БД, порт 8080, браузер | T04 (код) | после T03 |
| T06 | `specs/dr-warranty-repair/README.md`, документ отличий, `result.md`; код — только исправления найденных дефектов | БД, порт 8080, браузер | — | последним |

Изоляции общих ресурсов нет: одна локальная БД `docker-rvk-db-1`
(`localhost:5432`, схемы `main`/`ws_store`), один порт 8080, один Gradle
daemon, одно рабочее дерево. Поэтому код пишется параллельно только в парах
T02 ∥ T03 и T04 ∥ T05, а полный `:app:test`, `bootRun` и браузерные проходы
идут строго по одному в порядке колонки «Проверка»: T01 → T02 → T03 → T05 →
T04 → T06. Общий файл `messages_ru.properties` правят все таски: перед правкой
перечитать файл, добавлять только свой блок ключей, чужие блоки не
переставлять. `menu.xml` меняет только T04, файлы ролей — только T03.
Ключи `msg://` каждого view лежат в бандле его пакета
(`ru.fgk.ws.app.legal.techclaim.view.techclaim/...`).

## Как выполнять

1. Пользователь фиксирует базовую линию коммитом (рекомендация, не таск).
2. Волна 1: T01 в одной сессии.
3. Волна 2: T02 и T03 в двух сессиях параллельно; проверки — T02, затем T03.
4. Волна 3: T05 и T04 параллельно; проверки — T05, затем T04 (T04 зависит
   от T02 по колонкам сроков, T05 — нет).
5. Волна 4: T06; после его `pass` — `task-close`.

Окружение: `docker info`, `(cd docker && docker compose up -d)`;
`app/src/test/resources/application-test-local.properties` указывает на
`jdbc:postgresql://localhost:5432/postgres?currentSchema=main`. Если
`./gradlew` не тянет дистрибутив — `(cd system && ./change-gradle-to-remote-repo.sh)`.
Пользователи для браузерных проверок: локальный `user`/`user` (вход через
`/local-login`) с назначением нужной роли через администрирование, либо
тестовые пользователи, созданные в IT и удалённые после проверки.

## Открытые решения

- [Q01](questions/Q01.md) — deferred: наполнение календаря 2027 года после
  утверждения постановления Правительства; на постановку тасков не влияет.
- [Q02](questions/Q02.md) — resolved 2026-09-14: остаток спрятанной в
  `git stash` работы вне области T01 (код OIDC в `sso-plagin`, два
  changelog-а, настройки окружения) не восстанавливается по решению
  пользователя; отложенный тест `SsoOidcUserMapperConcurrencyIT` снят из
  набора `app` (T01, [F01](tasks/T01/fixes/F01.md)). На таски этой работы не
  влияет; T09 прежней работы остаётся исторически проверенным, но его кода в
  дереве нет.
