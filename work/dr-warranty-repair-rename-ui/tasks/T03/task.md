# T03 — Роли ДЭПС и ДЮ

Статус: todo
План: ../../plan.md
Зависимости: [T01](../T01/task.md), [T02](../T02/task.md)
Актуальная проверка: нет

## Результат и контекст

Сейчас заведена одна роль `LegalWarrantyRepairRole` (`legal-warranty-repair`)
с полным доступом к четырём сущностям и чтением `legal_caseone_ref`.
`@ViewPolicy`/`@MenuPolicy` в ней нет — экранов не было.

Ответ пользователя на вопрос 8 в `06-open-questions.md`: «права для депс и дю
будут разные». Форма тоже разделена на две (решение плана).

Результат: две роли, ограничивающие запись своей зоной, плюс существующая
полная роль остаётся админской.

## Реализация

Скил `jmix-create-resource-role`. Файлы —
`app/src/main/java/ru/fgk/ws/app/legal/warrantyrepair/security/`.

`LegalWarrantyRepairDepsRole` (`legal-warranty-repair-deps`, зона ДЭПС):

- `LegalWarrantyRepairDeps` — CREATE, READ, UPDATE; атрибуты — MODIFY;
- `LegalWarrantyRepair` — READ (отцепка заполняется автоматически);
- `LegalWarrantyRepairDu` — READ (зона ДЮ видна, но не редактируется);
- `LegalWarrantyRepairCaseOne` — READ;
- `VWarrantyRepairClaim` — READ;
- `CaseOneRef` — READ (выбор контрагента в блоке «Расчёт требований»).

`LegalWarrantyRepairDuRole` (`legal-warranty-repair-du`, зона ДЮ):

- `LegalWarrantyRepairDu` — CREATE, READ, UPDATE; атрибуты — MODIFY;
- `LegalWarrantyRepairDeps` — READ;
- `LegalWarrantyRepair` — READ;
- `LegalWarrantyRepairCaseOne` — READ;
- `VWarrantyRepairClaim` — READ.

`LegalWarrantyRepairRole` оставить как полную (админскую), добавив в неё
`VWarrantyRepairClaim` и все view из T04/T05.

Обеим рабочим ролям добавить READ на календарь и нормы T07 и только
чтение результатов сроков T08. Редактирование календаря/норм и публикация
с массовым пересчётом доступны административной роли НСИ из T07;
не наследуются ролями ДЭПС/ДЮ. Техническую таблицу сроков нельзя менять
напрямую даже через пользовательский DataManager: её заполняет внутренний
путь сервиса T08 после проверки прав на исходную претензию.
Проверить, что этот путь работает у обеих ограниченных ролей, не требуя
выдать им UPDATE на всю чужую зону или техническую таблицу.

`@ViewPolicy` и `@MenuPolicy` для конкретных view добавляются в T04 и T05 —
в этом таске завести классы ролей и политики на сущности. Если T04/T05
выполняются позже, оставить в их чеклистах явный пункт «добавить `@ViewPolicy`
в свою роль».

Помнить правило: `CREATE` подразумевает `MODIFY` на редактируемых атрибутах,
иначе форма создания получится read-only.

## Критерии приёмки

- C1: обе роли регистрируются, видны в UI администрирования ролей,
  контекст поднимается.
- C2: пользователь только с ролью ДЭПС не может изменить
  `LegalWarrantyRepairDu` (проверяется тестом на `DataManager`), но читает её.
- C3: пользователь только с ролью ДЮ не может изменить
  `LegalWarrantyRepairDeps`, но читает её.
- C4: обе роли читают `VWarrantyRepairClaim`.
- C5: обе роли читают нормы/календарь и свои сроки, не редактируют НСИ и
  технические результаты. Сохранение разрешённых исходных полей вызывает
  успешный пересчёт; изменение чужих полей остаётся запрещено.

## Проверка

```bash
./gradlew :app:compileJava
./gradlew :app:test
```

Интеграционный тест на ограничения (C2, C3) — наследник
`app/src/test/java/ru/fgk/ws/app/it/BaseIT`, без собственных
`@TestConfiguration` (Spring кеширует контексты по ключу конфигурации),
созданные данные убрать в `@AfterEach`. Скил `jmix-create-test`.

Точные команды записать в `result.md`.

## Прогресс и продолжение

- [ ] Создать `LegalWarrantyRepairDepsRole` и `LegalWarrantyRepairDuRole`.
- [ ] Дополнить `LegalWarrantyRepairRole` доступом к `VWarrantyRepairClaim`.
- [ ] Тест на разграничение записи между зонами.
- [ ] Проверить чтение календаря/норм и защищённый пересчёт T08 для обеих ролей.
- [ ] Передать результат на независимую проверку.

Ближайший шаг: посмотреть существующие роли проекта (`*/security/`) и
скопировать оттуда форму записи политик.
Препятствия: нет.
