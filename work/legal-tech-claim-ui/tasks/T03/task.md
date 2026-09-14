# T03 — Роли ДЭПС, ДЮ, администратор и сервис создания претензии

Статус: done
План: [plan.md](../../plan.md)
Зависимости: [T01](../T01/task.md)
Сложность: medium — роли по образцам проекта плюс небольшой транзакционный
сервис; контракт прав зафиксирован в плане
Сложность проверки: medium — полный `:app:test` и IT на разграничение под
разными пользователями; браузер не нужен
Актуальная проверка: [checks/001.md](checks/001.md)

## Коротко

Зоны ДЭПС и ДЮ в одной карточке разделяются правами, поэтому нужны две
рабочие роли и одна административная. Кроме того, ДЭПС должен уметь завести
дополнительную претензию по уже загруженной отцепке. Таск создаёт роли с
политиками на сущности, view и меню и сервис `TechClaimService.createClaim`,
покрывая оба тестами.

## Результат и контекст

Сейчас одна полная роль `LegalTechClaimAdminRole` (`legal-tech-claim-admin`,
после T01) без `@ViewPolicy`/`@MenuPolicy`. Отцепки и первые претензии
приходят загрузкой; в старой таблице у отцепки бывает несколько претензий
(`Index_Pret`), уникальность — частичный индекс
`(repair_uid, claim_index) WHERE deleted_date IS NULL`.

Матрица прав (`R` — READ + атрибуты VIEW, `RW` — READ/UPDATE + MODIFY,
`C` — CREATE):

| Сущность | `legal-tech-claim-deps` | `legal-tech-claim-du` | `legal-tech-claim-admin` |
|---|---|---|---|
| `LegalTechClaim` (отцепка) | R | R | ALL |
| `LegalTechClaimDeps` | C, RW | R | ALL |
| `LegalTechClaimDu` | R | RW | ALL |
| `LegalTechClaimCaseOne` | R | R | ALL |
| `LegalTechClaimDeadline` | R | R | R |
| `VLegalTechClaim` | R | R | R |
| `NsiWorkCalendarDay`, `NsiClaimTermNorm`, `NsiTermRevision` | R | R | R |
| `CaseOneRef` | R | R | R |

Всем трём: `@ViewPolicy(viewIds = {"legal_TechClaim.list", "legal_TechClaim.detail"})`
и `@MenuPolicy(menuIds = "legal_TechClaim.list")` — id фиксированы планом,
экраны появятся в T04/T05 и обязаны использовать именно их. Роль
`nsi-claim-term-edit` рабочим ролям не даётся.

Сервис `ru.fgk.ws.app.legal.techclaim.service.TechClaimService`:

- `LegalTechClaimDeps createClaim(UUID repairUid)` — в одной `@Transactional`:
  проверить право CREATE на `LegalTechClaimDeps` у текущего пользователя
  (`AccessManager`/`CrudEntityContext`), вычислить `claim_index = max по
  неудалённым претензиям отцепки + 1` (нет — 1), создать `deps` через
  пользовательский `DataManager` (права и аудит пользователя), парную пустую
  `du` — под `SystemAuthenticator.withSystem` через `UnconstrainedDataManager`
  (паттерн `TechClaimDeadlineService`), `case_one` не создавать. Вернуть
  сохранённую `deps`. Штатные слушатели пересчёта T08 создадут строку
  расчёта сами — второй вызов не добавлять.
- Конкурентное создание двух претензий одной отцепки разводит частичный
  уникальный индекс: повторить вычисление индекса один раз при нарушении
  уникальности, иначе пробросить исключение.

## Область и изоляция

Меняет: `legal/techclaim/security/` (три класса ролей), новый
`legal/techclaim/service/TechClaimService.java`, новый IT
`app/src/test/java/ru/fgk/ws/app/it/TechClaimSecurityIT.java`, блок ключей
(если сервис даёт пользователю сообщения). Не трогать: view, entity,
changelog-и, `menu.xml`. Общие ресурсы: БД, Gradle daemon. Параллельно с T02
(правило общего `messages_ru.properties` — из плана). Проверка — после T02.

## Реализация

Скилы `jmix-create-resource-role`, `jmix-create-service`, `jmix-create-test`.
Образцы: `app/security/PtContractWriteRole.java` (`@ViewPolicy`,
`@MenuPolicy`), `nsi/security/NsiClaimTermEditRole.java`, текущая
`LegalTechClaimAdminRole`. Constructor injection; `saveWithoutReload` там,
где результат не нужен. Помнить: `CREATE` без `MODIFY` даёт read-only форму
создания.

## Критерии приёмки

- C1: три роли регистрируются, контекст поднимается; политики соответствуют
  матрице (проверка через `ResourceRoleRepository` в IT).
- C2: пользователь только с ролью ДЭПС читает `du`, но `dataManager.save`
  изменённой `du` отвергается (`AccessDeniedException`); `deps` сохраняет.
- C3: пользователь только с ролью ДЮ читает `deps`, но сохранить изменённую
  `deps` не может; `du` сохраняет; создать `deps` не может.
- C4: обе роли читают `VLegalTechClaim`, `LegalTechClaimDeadline` и НСИ
  сроков; писать в `LegalTechClaimDeadline` и НСИ не могут.
- C5: `createClaim` под пользователем ДЭПС: первая дополнительная претензия
  получает `claim_index = max+1`, парная `du` с верным `deps_id` создана,
  `case_one` нет, строка расчёта создана слушателем; после мягкого удаления
  претензии индекс переиспользуется без нарушения индекса. Под ролью ДЮ —
  `AccessDeniedException`, ничего не создано.
- C6: `./gradlew :app:test` — `0 failing`.

## Самопроверка исполнителя

```bash
./gradlew :app:compileJava spotlessApply
./gradlew :app:test --tests "ru.fgk.ws.app.it.TechClaimSecurityIT"
```

Полный прогон не запускать. В `result.md` — точные команды и как в IT
создаются пользователи с ролями (образец — `NsiClaimTermEditRoleIT`).

## Независимая проверка

`./gradlew :app:test` целиком; повторный прогон `TechClaimSecurityIT` с
`--rerun-tasks`; SQL-контроль после IT: в таблицах раздела не осталось
тестовых строк. Негативные сценарии C2/C3/C5 (роль ДЮ) обязательны.
Регрессия: `TechClaimDeadlineIT` (сервис расчёта работает под новыми ролями),
`NsiClaimTermEditRoleIT`.

## Прогресс и продолжение

- [x] Создать `LegalTechClaimDepsRole`, `LegalTechClaimDuRole`; дополнить
      админскую роль (view/menu, НСИ, view-entity).
- [x] `TechClaimService.createClaim`.
- [x] `TechClaimSecurityIT` (C1–C5) и unit-тест распознавания конфликта
      индекса `TechClaimServiceTest`.
- [x] Самопроверка, `result.md`.
- [x] Передать результат на независимую проверку.

Ближайший шаг: независимая проверка по разделу «Независимая проверка» —
полный `./gradlew :app:test` (C6) и регрессии `TechClaimDeadlineIT`,
`NsiClaimTermEditRoleIT`; проверка идёт после проверки T02.
Препятствия: нет.
