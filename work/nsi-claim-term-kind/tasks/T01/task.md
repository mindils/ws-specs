# T01 — Вид претензии текстом, колонка «Дата окончания», строки «повр»

Статус: todo
План: [plan.md](../../plan.md)
Зависимости: нет
Сложность: easy — одна область `nsi`, образцы enum и changelog-ов в проекте,
контракт расчёта не меняется
Сложность проверки: easy — SQL-сверка 16 строк, один экран НСИ в браузере,
существующие тесты как регрессия
Актуальная проверка: нет

## Коротко

Справочник «Нормы сроков претензионных этапов» приводится к виду старого
экрана ВагТК: вид претензии показывается словами «техн» / «повр» вместо
числа, появляется справочная колонка «Дата окончания», подписи колонок
повторяют скриншот, а девять строк вида «повр» загружаются миграцией рядом
с уже имеющимися семью строками «техн». Расчёт сроков претензий не
меняется и по-прежнему использует только нормы «техн».

## Результат и контекст

Сейчас `NsiClaimTermNorm.claimKind` — `Integer` с константой
`CLAIM_KIND_WARRANTY = 1`; экран показывает число, колонки `Finish` нет,
строк `KodPret = 3` нет. Скриншот и выгрузка — раздел «Материалы» плана,
решения по enum, колонке, сиду и подписям — раздел «Общие решения» плана
(контракт, менять нельзя). Потребители `claimKind`:
`ClaimTermNormService`, `ClaimTermNormNotFoundException`,
`ClaimTermCalculator`, `TechClaimDeadlineService`, тесты
`NsiClaimTermEditRoleIT`, `WorkCalendarReferenceDataIT`.

## Область и изоляция

Меняются: `app/src/main/java/ru/fgk/ws/app/nsi/entity/NsiClaimTermNorm.java`,
новый `.../nsi/entity/ClaimKindEnum.java`, `.../nsi/service/*` (константа
вида), `.../legal/techclaim/service/ClaimTermCalculator.java` и
`TechClaimDeadlineService.java` (только замена константы), XML
`app/src/main/resources/ru/fgk/ws/app/nsi/view/claimtermnorm/*.xml`,
changelog-и `01-tbl/331-nsi_claim_term_norm.xml` и
`04-data/331-nsi_claim_term_norm.xml`, блоки ключей `ru.fgk.ws.app.nsi.entity/*`
и `ru.fgk.ws.app.nsi.view.claimtermnorm/*` в `messages_ru.properties`,
тесты из раздела выше. Не менять: алгоритм расчёта, `ClaimTermStage`,
календарь, ревизии, роли, экраны раздела `legal`. Общие ресурсы — БД
`localhost:5432`, порт 8080, Gradle daemon; таск единственный, проверки
последовательно после самопроверки. В рабочем дереве лежит незакоммиченный
код закрытых работ — чужие файлы не откатывать.

## Реализация

1. `ClaimKindEnum implements EnumClass<Integer>`: `TECH(1)`, `DAMAGE(3)`;
   образец `ru.fgk.ws.app.pt.entity.PtClaimType`. В `NsiClaimTermNorm`
   поле `claimKind` остаётся `Integer`-колонкой `claim_kind` с
   getter/setter через enum по образцу `dayType`; умолчание `TECH`.
   Константу `CLAIM_KIND_WARRANTY` убрать, потребителей перевести на
   `ClaimKindEnum.TECH.getId()` (или на enum в сигнатурах, если это не
   расширяет правку за пределы области). Скилы `jmix-create-enum`,
   `jmix-create-entity`.
2. Поле `finishNote` (`finish_note VARCHAR(500)`, `@Comment` по образцу
   `startNote`). В `01-tbl/331` дополнить `createTable` и добавить changeSet
   `addColumn` с preConditions `columnExists` (`jmix-create-liquibase-changelog`).
3. В `04-data/331` новый changeSet `author="nsi"` с девятью строками
   `claim_kind = 3` из `input/nvPretSrok_full.sql` (`name`, `term_days`,
   `day_type = 'WORKING'`, `stage_order = Ord`, `start_note`, `finish_note`;
   пустые строки выгрузки — `NULL`), тот же `ON CONFLICT (claim_kind,
   operation_code) DO NOTHING`. Отдельным changeSet-ом дописать `finish_note`
   существующим строкам не нужно: у «техн» он пуст.
4. Экраны: в list `claimKind` показывать текстом enum, фильтр `claimKind` —
   `propertyFilter` с выбором enum; в detail `comboBox` для `claimKind`,
   `textArea` для `finishNote`. Подписи — по плану через `msg://`
   (`jmix-add-i18n-keys`): ключи атрибутов entity и enum в блоке
   `ru.fgk.ws.app.nsi.entity`. Сортировка списка `claimKind, stageOrder,
   operationCode` остаётся.
5. Тесты (`jmix-create-test`): в `WorkCalendarReferenceDataIT` (или рядом)
   проверка 16 строк по видам и идемпотентности; `NsiClaimTermEditRoleIT`
   переводится на enum; `ClaimTermCalculatorTest` не должен измениться по
   ожиданиям.
6. `./gradlew spotlessApply`.

## Критерии приёмки

- C1: на пустой БД после миграций `select claim_kind, count(*) from
  nsi_claim_term_norm group by 1` даёт `1 → 7`, `3 → 9`; повторный запуск
  приложения и ручная правка `term_days` одной строки с последующим запуском
  не создают дублей и не возвращают старое значение.
- C2: список норм показывает «техн» / «повр» текстом, фильтр по виду
  работает, карточка даёт выбор вида из списка, поле «Дата окончания»
  сохраняется; подписи колонок: «Причина отцепки», «Наименование операции»,
  «Нормативный срок (дней)», «Тип дней», «Порядок этапа», «Дата начала»,
  «Дата окончания».
- C3: `ClaimTermCalculatorTest`, `TechClaimDeadlineIT`, `TechClaimViewIT`
  зелёные без изменения ожиданий; наличие строк «повр» не меняет ни одного
  срока претензии.
- C4: правка нормы открывает черновик ревизии, «Опубликовать изменения»
  пересчитывает сроки (регрессия ревизий, `NsiClaimTermEditRoleIT`).
- C5: в `messages_ru.properties` нет сырых `msg://` и неиспользуемых ключей
  экрана норм; `spotlessCheckAll` и `:app:compileJava` зелёные.

## Самопроверка исполнителя

`./gradlew :app:compileJava spotlessApply`, затем
`./gradlew :app:test --tests "ru.fgk.ws.app.it.NsiClaimTermEditRoleIT" --tests
"ru.fgk.ws.app.it.WorkCalendarReferenceDataIT" --tests
"ru.fgk.ws.app.legal.techclaim.service.ClaimTermCalculatorTest"` на БД из
Docker Compose; SQL-сверка C1 через MCP `mcp__rvk-ws__query` или `psql`.
Один smoke: открыть список норм в браузере (или `TechClaimDetailViewUiTest`
как проверку поднятия реестра view) и убедиться, что вид претензии показан
текстом. Полный `:app:test` и render-проход оставить проверяющему; точные
команды записать в `result.md`.

## Независимая проверка

1. `docker compose up -d`, пересоздать схему `main` или убедиться, что
   `addColumn` и новый changeSet применились; SQL по C1, включая
   идемпотентность (второй старт приложения, правка одной строки).
2. Полный `./gradlew :app:test` — `0 failing`.
3. `bootRun` в фоне, `/actuator/health` = UP, `playwright-cli` под
   `user`/`user` с ролью `nsi-claim-term-edit`: список норм, фильтр по виду,
   создание и правка нормы с «Датой окончания», подписи по C2, отсутствие
   сырых `msg://` и error overlay; после правки — экран ревизий показывает
   черновик, публикация проходит (C4).
4. Негативный сценарий: попытка создать вторую норму с тем же видом и кодом
   операции отклоняется уникальным ограничением с понятным сообщением, не
   500.
5. Погасить `bootRun`; отчёт в `checks/001.md` с commit и признаком
   незакоммиченных изменений.

## Прогресс и продолжение

- [ ] Enum, entity, потребители константы
- [ ] Changelog-и: `finish_note`, сид строк «повр»
- [ ] Экраны и ключи i18n
- [ ] Тесты и самопроверка
- [ ] Передать результат на независимую проверку.

Ближайший шаг: создать `ClaimKindEnum` и перевести `NsiClaimTermNorm.claimKind`.
Препятствия: нет
