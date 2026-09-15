# Итог: Претензии по технологическим неисправностям: экраны, роли, сроки

Закрыто: 2026-09-15
План: [plan.md](plan.md)
Предыдущая работа: [dr-warranty-repair-rename-ui](../dr-warranty-repair-rename-ui/summary.md)

## Что сделано

Раздел ВагТК «Оплата ремонтов / Претензии / Технологические / по вагонам»
работает в Jmix под именем `legal_tech_claim`. Пользователь с ролью ДЭПС
открывает из меню единственный список претензий, фильтрует его параметрами
старой процедуры `pThp_PretTehSelect2` плюс диапазонами и степенями просрочки
по семи срокам этапов, заводит кнопкой дополнительную претензию по выбранной
отцепке и ведёт вкладки «Документы» и «Допретензионная работа». Пользователь
с ролью ДЮ открывает ту же карточку, видит зону ДЭПС read-only и заполняет
вкладки «Претензия» и «Судебная работа». Роль администратора раздела даёт обе
зоны. Сроки, степени просрочки и признак неактуального расчёта видны в гриде
с подсветкой ячеек (жёлтый / оранжевый / красный) и на read-only вкладке
«Сроки», которая пересчитывает значения по текущему состоянию формы ещё до
сохранения. Фильтрация, сортировка и `count` по срокам идут в БД.

Относительно предыдущей работы: модель, entity, роли, сервисы, таблицы,
view и ключи i18n переименованы из `dr_warranty_repair*` / `LegalWarrantyRepair*`
/ пакета `warrantyrepair` в `legal_tech_claim*` / `LegalTechClaim*` / пакет
`legal.techclaim` (имена колонок не менялись); db-view дополнена сроками,
степенями, `deadlines_outdated` и недостающими колонками отчёта «Перечень
вагонов»; появились три роли, сервис создания претензии, список и карточка.

## Решения и точки реализации

Имена и модель — раздел «Общие решения» плана. Переименование сделано на
месте: changelog-и переименованы, `createTable` создаёт новые имена сразу,
`renameTable`/`renameColumn` не добавлялись, локальная БД пересоздаётся.

- Entity и enum-ы: `app/src/main/java/ru/fgk/ws/app/legal/techclaim/entity/`
  (`LegalTechClaim`, `_Deps`, `_Du`, `_CaseOne`, `_Deadline`, `VLegalTechClaim`,
  `TechClaim*Enum`, `ClaimTermOverdueLevelEnum`).
- Сервисы: `.../techclaim/service/` — `ClaimTermCalculator`,
  `TechClaimDeadlineService` (в том числе `describe(...)` для вкладки «Сроки»
  без сохранения), `TechClaimDeadlineRecalculationListener`,
  `TechClaimDeadlinePublicationHandler`, `TechClaimService.createClaim`,
  `TechClaimAmountCalculator`.
- Роли: `.../techclaim/security/` — `LegalTechClaimDepsRole`,
  `LegalTechClaimDuRole`, `LegalTechClaimAdminRole`. Зоны различаются только
  правами на атрибуты; read-only чужой зоны — штатное поведение Flow UI.
  Матрица прав — в [T03](tasks/T03/task.md).
- UI: `legal_TechClaim.list` (`LegalTechClaimListView` +
  `legal-tech-claim-list-view.xml`) над `VLegalTechClaim`;
  `legal_TechClaim.detail` (`LegalTechClaimDetailView` +
  `legal-tech-claim-detail-view.xml`) над `LegalTechClaimDeps`, строка `du` —
  отдельный `instanceContainer` в том же `DataContext`, вкладки — пять
  фрагментов в `view/techclaim/fragment/`. Пункт меню — `menu.xml:93`. Цвета
  подсветки — `frontend/themes/app/view/legal/legal-tech-claim.css`, классы
  `legal-tech-claim-overdue-1/2/3`.
- Схема: `liquibase/changelog/01-tbl/320…324-legal_tech_claim*.xml` и
  `02_view/independent/legal_v_tech_claim.xml`. Актуальное определение view —
  changeSet 2 этого файла; changeSet 1 оставлен как история и менять надо
  второй.
- Контракт сроков: даты — из `legal_tech_claim_deadlines` (Java-расчёт),
  степень считается во view от даты фактического завершения этапа, иначе от
  `current_date` БД; `deadlines_outdated` — нет строки расчёта или
  `revision_number` ≠ последней `PUBLISHED` ревизии. Подробности и таблица
  дат факта — [calendar-behavior-differences.md](input/calendar-behavior-differences.md).

## Подтверждение

Все шесть тасков `done` с актуальными независимыми проверками:
[T01/002](tasks/T01/checks/002.md), [T02/001](tasks/T02/checks/001.md),
[T03/001](tasks/T03/checks/001.md), [T04/001](tasks/T04/checks/001.md),
[T05/001](tasks/T05/checks/001.md). Итоговая интеграционная проверка —
[T06/001](tasks/T06/checks/001.md), `pass` по всем критериям C1–C6: сквозной
проход ДЭПС → ДЮ в браузере под тремя ролями, совпадение сроков между списком,
вкладкой «Сроки» и таблицей расчёта, восемь фильтров со счётчиками, равными
контрольным `count(*)` по db-view на выборке 69 строк при странице 50,
пересчёт всех претензий при публикации ревизии и отказ публикации при неполном
календаре без смеси расчётов. `./gradlew :app:test` — 1390 тестов, 0 failures,
0 errors, 12 skipped; `spotlessCheckAll` и `:app:compileJava` зелёные.

Gate 1 в исходном виде не выполнялся: JetBrains MCP не был подключён ни у
исполнителей, ни у проверяющих. Замена — `compileJava`, `spotlessCheckAll` и
render-проход всех view раздела под обеими ролями (ни одного сырого `msg://`,
ни одного error overlay, ноль строк `ERROR` в журнале). Непроверенных
критериев это не оставило.

Работа лежит незакоммиченной в рабочем дереве ветки `feature/caseone-table`
поверх коммита `5bdd59347`.

## Ограничения и отложенное

- [Q01](questions/Q01.md) — deferred: производственный календарь заполнен по
  2026-12-31. Наполнять 2027 год после утверждения постановления
  Правительства; до этого расчёт сроков, уходящий за 2026 год, отказывается с
  сообщением о недостающем дне (поведение проверено).
- [Q02](questions/Q02.md) — resolved: код OIDC из `stash` не восстанавливается,
  тест `SsoOidcUserMapperConcurrencyIT` снят из набора `app`
  ([F01](tasks/T01/fixes/F01.md)). T09 прежней работы остаётся исторически
  проверенным, но его кода в дереве нет.
- Вне объёма (перелив данных из ВагТК и NiFi, автозаполнение и редактирование
  отцепки, отправка в Case.one, вкладка «Копии документов», автомат даты
  комплекта по реализации деталей, индикатор `Srok_FilOColor`, агрегаты `@Col`)
  — как записано в плане. Отцепка в UI только читается.
- Экспорт грида в Excel подключён штатным действием, но на 137 колонках не
  проверялся.
- Путь «Сохранить» из диалога несохранённых изменений (`navigateWithSave`) не
  перехватывает ошибку календаря — она дойдёт до штатного обработчика Vaadin.
- Строка `du`, заведённая при открытии карточки, сохраняется даже пустой — это
  согласованное поведение «пара строк создаётся вместе с претензией».
- Роль ДЮ не имеет `CREATE` на `LegalTechClaimDu`; для загруженных и созданных
  сервисом претензий парная строка уже есть.
- Колонки типа `timestamp` выводятся в гриде с временем, как в остальных гридах
  проекта.
- Связанное изменение вне области работы: в
  `app/.../nsi/view/termrevision/NsiTermRevisionListView.java` и ключ
  `notification.publishFailed` добавлен понятный текст отказа публикации
  ревизии вместо «Непредвиденной ошибки» ([T06](tasks/T06/result.md)). Экран
  принадлежит закрытой работе `dr-warranty-repair-rename-ui` (T07); её
  исторический итог не переписывался, транзакционное поведение публикации не
  менялось — изменился только текст уведомления, и оно подтверждено проверкой
  T06. Отдельная работа по этому поводу не нужна.

## Для следующей доработки

Точки входа: список `legal_TechClaim.list`, карточка `legal_TechClaim.detail`
и её пять фрагментов; расчёт сроков — `ClaimTermCalculator` и
`TechClaimDeadlineService`; права — три роли в `legal/techclaim/security`.

Правила, которые стоит сохранить: колонки таблиц не переименовываются;
определение db-view правится в changeSet 2 файла `legal_v_tech_claim.xml`;
`@ViewPolicy` на оба view и `@MenuPolicy` на список должны оставаться во всех
трёх ролях; новое поле карточки требует права `MODIFY` в роли своей зоны,
иначе поле молча станет read-only; «сегодня» для view и Java — один
`current_date` БД (`ClaimTermDateProvider`).

Полезные регрессионные сценарии: `TechClaimDeadlineIT` (пересчёт и негативная
публикация), `TechClaimViewIT` (колонки и степени db-view), `TechClaimSecurityIT`
(разграничение зон), `TechClaimServiceTest` (индекс претензии при конфликте),
`TechClaimDetailViewUiTest`. Фикстуры сквозного прохода и их снятие —
[fixtures_e2e.sql](tasks/T06/checks/fixtures_e2e.sql) и
[fixtures_e2e_cleanup.sql](tasks/T06/checks/fixtures_e2e_cleanup.sql).

Итог описывает состояние на 2026-09-15; будущий планировщик сверяет его с
актуальным кодом.
