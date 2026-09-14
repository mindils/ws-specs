# Итог работы `dr-warranty-repair-rename-ui`

Закрыта: 2026-09-14, как пересмотренная. Продолжение —
[legal-tech-claim-ui](../legal-tech-claim-ui/plan.md).

## Что сделано и проверено (`done`)

Всё лежит в рабочем дереве ветки `feature/caseone-table` (HEAD `f2b96adc2`),
**не закоммичено**.

| Таск | Результат | Где |
|---|---|---|
| T01 | Таблицы `dr_warranty_repair`, `_deps`, `_du`, `_case_one` (175 колонок), колонки по правкам `09-update.md`, индекс `(wagnum, defect_date)` уникальный | `01-tbl/320…323-dr_warranty_repair*.xml`, `ru.fgk.ws.app.legal.warrantyrepair.entity.*` |
| T07 | Производственный календарь `nsi_work_calendar_day` (2024–2026, 1096 дней, xmlcalendar.ru), нормы `nsi_claim_term_norm` (7 норм `KodPret=1`), ревизии `nsi_term_revision` с публикацией; пять views НСИ; роль `nsi-claim-term-edit` | `ru.fgk.ws.app.nsi.*`, `01-tbl/330…332`, `04-data/330…332` |
| T08 | Java-расчёт семи сроков и порогов +1/+10/+30 (`ClaimTermCalculator`), сохранение в `dr_warranty_repair_deadlines` (37 колонок), пересчёт слушателями до коммита, при публикации ревизии и `recalculateAll()` | `ru.fgk.ws.app.legal.warrantyrepair.service.*`, `01-tbl/324` |
| T09 | Гонка конкурентной синхронизации OIDC-пользователя устранена (повтор при конфликте версий + striped-замки); тестовый контур `sso-plagin` починен | `sso-plagin/.../SsoSynchronizingOidcUserMapper.java` |

Гейт 2 на момент закрытия: `./gradlew :app:test` — 1348 passing, 12
pending, 0 failing.

## Состояние после закрытия (2026-09-14)

T09 остаётся исторически проверенным, но его кода в рабочем дереве нет:
правки `sso-plagin` (`SsoSynchronizingOidcUserMapper` с повтором при
конфликте версий и striped-замками, тесты аддона, `sso-plagin.gradle`)
лежат в `stash@{1}` («sso-oplimistic-log-with-auth») и отложены
пользователем вместе со всей работой по OIDC. Тест
`app/src/test/java/ru/fgk/ws/app/sso/SsoOidcUserMapperConcurrencyIT.java`
(коммит `dd71c094f`) снят из дерева, чтобы не краснить `:app:test`;
возврат — `git checkout dd71c094f -- <путь>` вместе с `git stash pop
"stash@{1}"`. Основание: [Q02](../legal-tech-claim-ui/questions/Q02.md)
новой работы. Гейт «1348 passing, 0 failing» относится к состоянию на
момент закрытия, когда код T09 был в дереве.

## Частично сделано (не проверялось независимо)

- T02: view `dr_v_warranty_repair_claim` (104 колонки: поля четырёх таблиц и
  суммы) и entity `VWarrantyRepairClaim`, тест `WarrantyRepairClaimViewIT`.
  Блока сроков нет — дорабатывается в T02 новой работы.

## Не начато

T03 (роли), T04/T05 (экраны), T06 (сквозная проверка) — заменены тасками
T03–T06 новой работы с другой постановкой (одна форма вместо двух).

## Решения, пересмотренные в новой работе

| Было здесь | Стало |
|---|---|
| Таблицы `dr_warranty_repair*`, код `legal.warrantyrepair` | Всё `legal_tech_claim*` / `legal.techclaim` (T01 новой работы) |
| Две пары list+detail (ДЭПС и ДЮ), два пункта меню | Одна форма с вкладками, права по зонам, один пункт меню |
| Календарь 2027 — «дозаполнит администратор» | Отложено до утверждения постановления ([Q01](../legal-tech-claim-ui/questions/Q01.md)) |

Сохранённые решения: полный собственный календарь, Java-расчёт сроков с
хранением дат порогов и степенью при чтении, суммы в db-view, `_du`
создаётся вместе с претензией, `_case_one` — только при отправке.

## Материалы для следующих сессий

- Первоисточники и разборы: `input/` (скопированы в новую работу).
- Документ отличий календарного расчёта с картой кода T07/T08:
  `input/calendar-behavior-differences.md` (актуальная копия ведётся в новой
  работе).
- Скрипты проверок переименования: `tasks/T01/checks/*.py`; фикстуры view:
  `tasks/T02/checks/fixtures_c3_c5.sql`.
