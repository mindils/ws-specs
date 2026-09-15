# Результат T01

Таск: [task.md](task.md)
Итерация: 1
Обновлено: 2026-09-15

## Что реализовано

Справочник норм сроков претензионных этапов приведён к виду старого экрана
ВагТК. Вид претензии стал перечислением `ClaimKindEnum` (`TECH(1)` — «техн»,
`DAMAGE(3)` — «повр»): в списке и карточке он выводится текстом, в карточке
выбирается из выпадающего списка, фильтр отбирает строки по виду. Добавлено
справочное поле «Дата окончания» (`finishNote` / `finish_note VARCHAR(500)`) —
колонка списка и поле карточки. Миграция наполнения загрузила девять норм
`claim_kind = 3` рядом с прежними семью `claim_kind = 1`; в таблице 16 строк.
Подписи колонок переписаны по скриншоту. Расчёт сроков не изменён: он
по-прежнему читает только нормы `TECH`, строки «повр» на сроки не влияют.
Работа завершена, блокеров нет.

## Изменения и решения

- `nsi/entity/ClaimKindEnum.java` — новый `EnumClass<Integer>` по образцу
  `pt/entity/PtClaimType`.
- `nsi/entity/NsiClaimTermNorm.java` — колонка `claim_kind` осталась `Integer`,
  доступ через enum-геттер/сеттер по образцу `dayType`; умолчание
  `ClaimKindEnum.TECH`; добавлено поле `finishNote`; константа
  `CLAIM_KIND_WARRANTY` убрана.
- Вид претензии переведён в сигнатуры сервисов, а не только в место вызова:
  `ClaimTermNormService.loadNorms/requireNorm` и
  `ClaimTermNormNotFoundException` принимают `ClaimKindEnum`, в JPQL уходит
  `claimKind.getId()`. Оба файла входят в область таска, а типизированная
  сигнатура исключает случайную передачу произвольного числа. Потребители
  `ClaimTermCalculator` и `TechClaimDeadlineService` изменены только в этой
  строке.
- `liquibase/changelog/01-tbl/331` — `finish_note` добавлен в `createTable` и
  отдельным changeSet `3` с preConditions `columnExists` для существующих БД.
- `liquibase/changelog/04-data/331` — новый changeSet `2` с девятью строками
  `claim_kind = 3` и тем же `ON CONFLICT (claim_kind, operation_code) DO
  NOTHING`. Пустые `Start`/`Finish` выгрузки записаны как `NULL`.
- Экраны: в карточке `integerField` вида претензии заменён на `comboBox`,
  добавлен `textArea` для `finishNote`; в списке добавлена колонка
  `finishNote`. `propertyFilter` по `claimKind` остался прежним — после смены
  типа он сам стал выбором из списка.
- i18n (`messages_ru.properties`, блок `ru.fgk.ws.app.nsi.entity`): подписи
  `claimKind` → «Причина отцепки», `name` → «Наименование операции»,
  `termDays` → «Нормативный срок (дней)», `startNote` → «Дата начала», новый
  `finishNote` → «Дата окончания», новый блок `ClaimKindEnum` с «техн» и
  «повр». Прочие ключи и чужие блоки не тронуты; в `app` есть только
  `messages_ru.properties`.
- Тесты: `NsiClaimTermEditRoleIT` и `WorkCalendarReferenceDataIT` переведены на
  enum; в `WorkCalendarReferenceDataIT` добавлены проверки девяти строк «повр»
  с «Датой окончания» и разбивки 16 = 7 + 9, повторный прогон наполнения теперь
  проверяет сохранность правки и в строках «повр», а `restoreSeed` чистит обе
  группы норм (раньше удалял только `claim_kind = 1`, и правка строки «повр»
  пережила бы прогон).
- Сверх перечисленных в таске тестов заведён
  `nsi/view/claimtermnorm/NsiClaimTermNormViewsUiTest` — он же служит smoke
  главного критерия вместо занятого браузера (см. ниже). Проверяет открытие
  обоих view, подписи колонок по C2, тип атрибута в метамодели и подписи
  «техн»/«повр», отбор фильтром девяти строк «повр», состав выпадающего списка
  и сохранение «Даты окончания». `ClaimTermCalculatorTest` не изменён.

## Предварительные проверки

| Команда или сценарий | Результат |
|---|---|
| `./gradlew :app:compileJava` | успешно |
| `./gradlew spotlessApply` и `./gradlew spotlessCheckAll` | успешно |
| `./gradlew :app:test --tests "ru.fgk.ws.app.it.NsiClaimTermEditRoleIT" --tests "ru.fgk.ws.app.it.WorkCalendarReferenceDataIT" --tests "ru.fgk.ws.app.legal.techclaim.service.ClaimTermCalculatorTest" --tests "ru.fgk.ws.app.nsi.view.claimtermnorm.NsiClaimTermNormViewsUiTest" --tests "ru.fgk.ws.app.it.TechClaimDeadlineIT"` | 74 passing, 0 failing |
| SQL C1 на локальной БД: `select claim_kind, count(*) from main.nsi_claim_term_norm group by 1` | `1 → 7`, `3 → 9`; после прогона тестов те же значения |
| Applied changeSet-ы: `select id, author, filename, exectype from main.databasechangelog where filename like '%331-nsi_claim_term_norm%'` | `01-tbl` id 2 EXECUTED, id 1 RERAN, id 3 EXECUTED; `04-data` id 1 и id 2 EXECUTED |
| Smoke главного критерия: `NsiClaimTermNormViewsUiTest` — оба view открываются, вид претензии показан текстом | успешно |

Не запускалось, оставлено проверяющему: полный `./gradlew :app:test`;
пересоздание схемы `main` с нуля и проверка C1 на пустой БД; браузерный
render-проход под ролью `nsi-claim-term-edit` (подписи, фильтр, создание и
правка нормы, отсутствие сырых `msg://` и error overlay); регрессия ревизий
через UI (черновик и публикация, C4); негативный сценарий дубля нормы в
интерфейсе; `TechClaimViewIT`.

## Для независимой проверки

- Окружение: `docker info`, `(cd docker && docker compose up -d)`;
  `app/src/test/resources/application-test-local.properties` уже содержит
  `jdbc:postgresql://localhost:5432/postgres?currentSchema=main`
  (пользователь/пароль `root`). Проверенное состояние кода: коммит `5bdd59347`
  плюс незакоммиченные изменения рабочего дерева — файлы НСИ и раздела
  `legal` не закоммичены с прежних работ, изменения этого таска лежат поверх
  них.
- Полный набор: `./gradlew :app:test`.
- SQL C1: `docker exec docker-rvk-db-1 psql -U root -d postgres -c "select
  claim_kind, count(*) from main.nsi_claim_term_norm group by 1 order by 1;"`.
  Для проверки на пустой БД схему `main` нужно пересоздать до старта
  приложения.
- UI: `./gradlew :app:bootRun`, дождаться `/actuator/health` = UP, вход
  `user`/`user` через `/local-login`, роль `nsi-claim-term-edit` назначается
  через администрирование. Экран — «Справочники → Сроки претензий: календарь и
  нормы», маршрут `/nsi-claim-term-norms`.
- Изоляция общих ресурсов: во время этой сессии порт 8080 и файловые блокировки
  HSQLDB (`app/.jmix/hsqldb/vagtk.lck`, `vagtkprod.lck`) занимал посторонний
  экземпляр приложения (pid 3377206, запущен до сессии). Своего `bootRun`
  сессия не поднимала и чужой процесс не гасила. Перед браузерным проходом
  проверяющему нужно убедиться, что ресурс свободен: `ss -lptn | grep 8080`.

## Ограничения и связанные изменения

- Браузерный render-проход не выполнялся: `render not browser-verified`.
  Причина — занятый порт 8080 и блокировки HSQLDB, изоляции для них в плане
  нет. Вместо него сделан smoke на уровне UI-теста, который открывает оба view
  и проверяет подписи, фильтр и сохранение.
- Строки `DAMAGE` остаются справочными: расчёт сроков их не читает, отдельного
  раздела претензий по повреждениям в приложении нет (граница плана).
- Доказательства закрытой работы `legal-tech-claim-ui` затронуты только в части
  НСИ норм: сигнатуры `ClaimTermNormService` и текст подписей изменились,
  ожидания расчёта — нет.
