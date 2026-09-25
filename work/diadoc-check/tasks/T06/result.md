# Результат T06

Таск: [task.md](task.md)
Итерация: 1
Обновлено: 2026-09-21

## Что реализовано

Сквозной сценарий пройден целиком на живых приложениях: `rvk-diadoc` (ветка
`f/schf-supplement`, порт 8081, БД `localhost:5436`) и `rvk-ws` (worktree,
порт 8082, схема `main_f_diadoc_check`). Кода в рамках T06 не менялось:
расхождений, требующих правки, не нашлось.

Подтверждено на данных -26:

- СЧФ привязывается документом-дополнением к обоим пакетам с её ФПУ-26 — и в
  источнике, и в зеркале rvk-ws, вместе с `supplement_document=true`;
- `violations` пакета-корректировки (5 × `CROSS_PACKET_REFERENCE`) доезжают в
  зеркало без потерь;
- `process` при включённых настройках контрагента пишет эти нарушения
  по-русски в результат контроля и даёт `ok=false`; при выключенных — прежний
  ответ;
- галочка «Показать связанные документы» видна только администратору
  настроек, у `ws-user` состав документов определяет настройка, а
  СЧФ-дополнение видно всегда и помечено скрепкой;
- фильтр «Результат контроля» работает на обоих списках, кнопка «Текст
  ошибки» на ВУ-23 активна при нарушении и показывает текст длиннее 255
  символов.

Единственное отступление — критерий C4 в части «полный `:app:test` зелёный»:
в worktree он даёт 90 падений, все до единого унаследованные от базового
коммита (см. «Ограничения» и [Q01](../../questions/Q01.md)).

## Изменения и решения

Файлы проекта не менялись. Изменения в документах работы: этот `result.md`,
прогресс в `task.md`, вопрос `questions/Q01.md`, снимки экрана в
`tasks/T06/*.png`.

Решения по ходу сценария:

1. **Идентификаторы C и СЧФ в постановке перепутаны** — то же расхождение, что
   уже отметил T05. Фактически сообщение C = `b17c632e-9013-4db3-8c3b-868a9826b062`,
   entity СЧФ = `fe79c311-9419-4cad-8473-bad0e713d818`. Сценарий выполнен по
   фактическим данным.
2. **Tombstone C.** При порядке обработки C → A → B своя строка `diadoc_packet`
   у сообщения C не появляется вовсе: обработка СЧФ сразу находит ФПУ-26 в
   `diadoc_entity_detail` сообщения A, каноническим пакетом становится A, и
   линк пишется прямо в A. Итог — ни живого пакета, ни живых линков C, что и
   требуется («C поглощён»); `deleted_date` проверять не на чем. Это ровно то
   поведение, которое T05 описал в своём пункте 3.
3. **Ремонта для вагона -26 в rvk-ws нет.** Пакет B — ТР-2 по вагону 62143110,
   а `ws_store` (внешний источник, только чтение) данных по этому вагону не
   содержит, поэтому `process` сначала отвечал `REPAIR_NOT_FOUND` и до проверок
   нарушений не доходил — они по замыслу идут после успешного разбора. Чтобы
   шаг 4 проверял то, ради чего он написан, в `ws_store` добавлены две
   фикстурные строки ремонта (SQL ниже). Это подготовка данных сценария, а не
   правка кода; после проверки строки удалены.
4. **Фикстур replay не дополнял.** Раздел «Область» разрешал добавить
   линк-дополнение в `packet_doc_link.csv` «при необходимости». Необходимости
   нет: запись флага в зеркало закрыта
   `SyncPacketServiceTest.syncStoresAndOverwritesSupplementDocumentFlag`,
   отбор на карточке — `DiadocPacketDocumentFilterTest`, а исключение
   дополнения из проверки связанных документов —
   `DiadocViolationCheckReplayIT` («дополнение и документ без признака
   связанного в проверку не входят»). Добавление строки в общую фикстуру
   сдвинуло бы состав документов у всех сценариев `PacketReplayIT` без выигрыша
   в покрытии.
5. **Схема БД пересоздана перед регрессом.** В `main_f_diadoc_check` накопились
   остатки прошлых прогонов; чтобы падения полного набора нельзя было списать
   на грязную схему, схема была пересоздана (`DROP SCHEMA … CASCADE` +
   `CREATE SCHEMA`, как делает `system/worktree-setup.sh --recreate`), и набор
   прогнан заново. Результат тот же — 90 падений, см. ниже.

## Предварительные проверки

Шаги сценария выполнены полностью, включая браузерные: оставлять их
проверяющему не понадобилось.

| Команда или сценарий | Результат |
|---|---|
| Шаг 1. `POST /api/v2/documents/process` для C, A, B (8081) | HTTP 200 на все три; в БД 5436 у A и B линк на `fe79c311-…` c `related_document=t`, `supplement_document=t`, `original_message_id` = C; живого пакета и живых линков C нет; у B `violations` — 5 × `CROSS_PACKET_REFERENCE` по TorID `D0075387308`, `D0075418330`, `D0075439821`, `D0075440781`, `D0075456469` |
| Шаг 2. `POST /api/diadoc/syncPacket` для A и B (8082) | `{"result":"synced","items":8,…}` и `{"result":"synced","items":10,…}`; в `main_f_diadoc_check.diadoc_packet_doc_link` 18 строк, полностью совпадающих с источником, включая оба `supplement_document=t`; `diadoc_packet.violations` у B — массив из 5 элементов, у A пусто |
| Шаг 3. Экран «Настройки Диадок по контрагентам» под ролью `diadoc-settings-admin` | Строка CDI заведена через UI; новая строка предзаполнена умолчаниями (`showRelatedDocuments` уже отмечен); после сохранения в БД `t,t,t,t` |
| Шаг 4. `GET /api/diadoc/processPacket?messageId=<B>` при включённых проверках | `ok=false`, `errorType=CHECK_FAILED`; в `message` пять русских строк «Документ TorID … перечислен в пакете, но вложен в другое сообщение: 14bf2bcd-…» и строка «В системе есть подписанные документы: МХ-3Х/5460 (…), РДВ/РДВ.xml (…), ФПУ 26/62143110 (…), Прочее/ВУ-36.pdf (…), ВУ-22/ВУ-22.xml (…)» |
| Шаг 4. То же для A (пакет-владелец) | `ok=false` по прежним, не связанным с работой проверкам (договор не найден в справочнике, МХ-3 деталь не на складе); ни одной строки нарушений зеркала и связанных документов — новых нарушений пакет-владелец не получает |
| Шаг 4. То же для B при снятых четырёх флагах | В `message` осталась только прежняя строка про договор; строки нарушений и связанных документов исчезли |
| Шаг 4 (негатив). То же для B до заведения строки контрагента (умолчания `true,false,false,false`) | Строк `CROSS_PACKET_REFERENCE` нет; строка «В системе есть подписанные документы …» есть — `showRelatedDocuments` в умолчаниях включён и по решению плана управляет обеими сторонами |
| Шаг 5. Карточки A и B под `admin` | Обе показывают СЧФ `1895353/06001911/0034` с подсказкой «Дополнение к ФПУ-26: b17c632e-…»; галочка «Показать связанные документы» присутствует; снимок `packet-a-supplement.png` |
| Шаг 5. Карточка B под `ws-user` при `showRelatedDocuments=false` | Галочки нет вовсе; в гриде 5 строк — 4 своих документа B и СЧФ-дополнение; пять связанных документов из A скрыты; снимок `packet-b-wsuser.png` |
| Шаг 5. Та же карточка под `admin` с включённой галочкой | Связанные документы из A появляются (МХ-3Х, РДВ, ФПУ 26, ВУ-36 …) |
| Шаг 6. `pt-repair-packets`, фильтр «Результат контроля» | Пять значений в списке; «Нарушение» → 4 строки, «Норма» → 1, «Не проверялся» → 0 — совпадает с `select pack_checked_code, count(*) from pt_repair_packet`; снимок `pt-filter.png` |
| Шаг 6. `dr-diadoc-oper-repair-packet-vu23s`, фильтр и кнопка «Текст ошибки» | Те же пять значений; «Нарушение» → 1 строка; на выбранной строке кнопка активна и показывает весь текст отметки (308 символов, то есть прежний `varchar(255)` его бы обрезал); снимок `vu23-error-text.png` |
| Шаг 7. `./gradlew :app:test` (rvk-ws, схема пересоздана) | 1446 passing, 12 pending, **90 failing** — все унаследованы от базового коммита, новых нет (разбор ниже) |
| Шаг 7. `./gradlew spotlessCheckAll` (rvk-ws) | BUILD SUCCESSFUL |
| Шаг 7. `./gradlew test` (rvk-diadoc) | 411 passing, 0 failing, BUILD SUCCESSFUL |
| Шаг 7. `./gradlew spotlessApply` (rvk-diadoc) | BUILD SUCCESSFUL, `git status --short` пуст |
| Контроль регресса: тот же `:app:test` на базовом коммите `631acb2e0` в отдельном worktree и схеме `main_t06_base` | 1399 passing, **100 failing**; пофамильная разница множеств: новых падений 0, починено 10 (`PacketReplayIT` 7, `RemDetPacketReplayIT` 3) |

Не запускалось, оставлено проверяющему: ничего сверх перечисленного; повтор
сценария и тех же наборов — по разделу «Независимая проверка» таска.

## Для независимой проверки

Состояние кода: рабочее дерево rvk-ws на ветке `f/diadoc-check`, коммит
`631acb2e0` плюс незакоммиченные изменения тасков T01-T04; rvk-diadoc —
ветка `f/schf-supplement`, коммит `b27af3a`, дерево чистое. Схема
`main_f_diadoc_check` после прогонов содержит только то, что оставили тесты:
данные сценария удалены вместе с пересозданием схемы, поэтому подготовку ниже
нужно выполнить заново.

Приложения после проверки погашены, порты 8081 и 8082 свободны.

### Подготовка окружения

```bash
docker info && (cd docker && docker compose ps)                  # rvk-ws
(cd /home/mindils/data/dev/fgk/rvk-diadoc/envs/dev && docker compose ps)
```

Контрагент CDI в rvk-ws (таблица справочника пуста в свежей схеме):

```sql
insert into main_f_diadoc_check.nsi_diadoc_contractor (code, name, inn, kpp)
select 'CDI', 'АО "ЦДИ"', '7708503727', '770845098'
where not exists (select 1 from main_f_diadoc_check.nsi_diadoc_contractor where code='CDI');
```

Пользователи для браузера. `admin` / `admin` уже есть с `system-full-access`;
роль настроек и второго пользователя завести так:

```sql
insert into main_f_diadoc_check.sso_user (id, version, username, password, active, first_name, last_name)
select gen_random_uuid(), 1, 'wsuser', '{noop}wsuser', true, 'WS', 'User'
where not exists (select 1 from main_f_diadoc_check.sso_user where username='wsuser');

insert into main_f_diadoc_check.sec_role_assignment (id, version, create_ts, created_by, username, role_code, role_type)
select gen_random_uuid(), 1, now(), 'system', v.u, v.r, 'resource'
from (values ('wsuser','ws-user'), ('wsuser','ui-minimal'), ('admin','diadoc-settings-admin')) as v(u, r)
where not exists (select 1 from main_f_diadoc_check.sec_role_assignment a where a.username = v.u and a.role_code = v.r);
```

Без `ui-minimal` вход `wsuser` через `/local-login` отклоняется («Ошибка
входа», в логе `Denied access to [ui.loginToUi]`).

Ремонт для вагона -26 (иначе `process` пакета B отвечает `REPAIR_NOT_FOUND` и
до проверок нарушений не доходит). `ws_store` общая для всех рабочих копий,
поэтому строки после проверки удалить:

```sql
insert into ws_store.ora_v_wag_rem_new
  (remont_id, remont_id_viv, wagnum, rwagnum, repair_type, repair_type_name, torep_date, repfinish,
   depo_neispr, depo, repstart, last_repair, ksoob, repair_type_in, repfinish_ind, depo_in,
   depo_name_in, repair_uid)
select 90000026, 90000027, 62143110, 62143110, 4, 'Текущий отцепочный ремонт',
   timestamp '2026-06-28 00:00:00', timestamp '2026-06-29 00:00:00',
   4100, 4100, timestamp '2026-06-28 06:00:00', 1, 5353, 4,
   timestamp '2026-06-29 00:00:00', 4100, 'ВЧДЭ-1 Челябинск', '2ad11626-0000-4000-8000-000000000026'::uuid
where not exists (select 1 from ws_store.ora_v_wag_rem_new where repair_uid='2ad11626-0000-4000-8000-000000000026');

insert into ws_store.dr_wag_oper_repair_contract
  (id_dr_wag_repair, wagnum, defect_date, repair_uid, repair_date, depo, repair_type, doc_status,
   recdatenew, repair_cost, warranty_repair, not_update)
select 90000026, 62143110, timestamp '2026-06-28 00:00:00',
   '2ad11626-0000-4000-8000-000000000026'::uuid, timestamp '2026-06-29 00:00:00', 4100, 3, 1,
   timestamp '2026-06-30 10:00:00', 9250.27, 0, 0
where not exists (select 1 from ws_store.dr_wag_oper_repair_contract where repair_uid='2ad11626-0000-4000-8000-000000000026');

-- проверка: должен вернуться 2ad11626-…
set search_path to main_f_diadoc_check, public;
select * from f_diadoc_connection_tr2(62143110::numeric, timestamp '2026-06-28',
       timestamp '2026-06-29', null, null, 4100::smallint, 72, 72);
```

Уборка после проверки:

```sql
delete from ws_store.dr_wag_oper_repair_contract where repair_uid='2ad11626-0000-4000-8000-000000000026';
delete from ws_store.ora_v_wag_rem_new           where repair_uid='2ad11626-0000-4000-8000-000000000026';
```

### Запуск приложений

```bash
(cd /home/mindils/data/dev/fgk/rvk-diadoc && ./gradlew bootRun)   # профиль dev, порт 8081
./gradlew :app:bootRun                                            # профили dev+local, порт 8082
curl -s http://localhost:8081/actuator/health
curl -s http://localhost:8082/actuator/health
```

Данные -26 в БД 5436 уже наработаны прогонами rvk-diadoc; чтобы повторить шаг 1
с чистого листа, перед обработкой снести производные строки (исходные
`diadoc_entity_detail` не трогать):

```sql
delete from public.diadoc_packet_doc_link where message_id in
  ('14bf2bcd-9a45-483d-a0b5-f76f001d9138','be5aa61d-e5a0-4448-b5cb-9417a6d54c05','b17c632e-9013-4db3-8c3b-868a9826b062');
delete from public.diadoc_packet          where message_id in
  ('14bf2bcd-9a45-483d-a0b5-f76f001d9138','be5aa61d-e5a0-4448-b5cb-9417a6d54c05','b17c632e-9013-4db3-8c3b-868a9826b062');
```

### Шаги 1-4

```bash
for m in b17c632e-9013-4db3-8c3b-868a9826b062 \
         14bf2bcd-9a45-483d-a0b5-f76f001d9138 \
         be5aa61d-e5a0-4448-b5cb-9417a6d54c05; do
  curl -s -X POST http://localhost:8081/api/v2/documents/process \
       -H 'Content-Type: application/json' -d "{\"messageId\": \"$m\"}" -o /dev/null -w "$m %{http_code}\n"
done

curl -s -X POST "http://localhost:8082/api/diadoc/syncPacket?messageId=14bf2bcd-9a45-483d-a0b5-f76f001d9138"
curl -s -X POST "http://localhost:8082/api/diadoc/syncPacket?messageId=be5aa61d-e5a0-4448-b5cb-9417a6d54c05"

curl -s "http://localhost:8082/api/diadoc/processPacket?messageId=be5aa61d-e5a0-4448-b5cb-9417a6d54c05"
curl -s "http://localhost:8082/api/diadoc/processPacket?messageId=14bf2bcd-9a45-483d-a0b5-f76f001d9138"
```

Сверка линков (одинаковый запрос к обеим БД, во второй схема
`main_f_diadoc_check.`):

```sql
select message_id, entity_id, related_document, supplement_document,
       data_source, original_message_id, deleted_date
from diadoc_packet_doc_link
where message_id in ('14bf2bcd-9a45-483d-a0b5-f76f001d9138',
                     'be5aa61d-e5a0-4448-b5cb-9417a6d54c05',
                     'b17c632e-9013-4db3-8c3b-868a9826b062')
order by message_id, entity_id;
```

Настройки контрагента (шаг 3) — через UI: `http://localhost:8082/local-login`,
`admin`/`admin`, меню «Диадок → Настройки Диадок по контрагентам», «Создать»,
контрагент «АО "ЦДИ"», отметить три проверки (`showRelatedDocuments` уже
отмечен из умолчаний), OK. Выключение — открыть строку двойным щелчком и снять
все четыре флажка.

### Шаги 5-6 в браузере

- `http://localhost:8082/diadoc-packet/14bf2bcd-9a45-483d-a0b5-f76f001d9138` и
  `…/be5aa61d-e5a0-4448-b5cb-9417a6d54c05` под `admin`: в гриде документов
  строка «Счет-фактура 1895353/06001911/0034» со скрепкой и подсказкой
  «Дополнение к ФПУ-26: b17c632e-…». Грид виртуализован — в карточке A СЧФ
  идёт восьмой строкой, до неё нужно долистать.
- Та же карточка B под `wsuser`/`wsuser` при `showRelatedDocuments=false`:
  галочки «Показать связанные документы» нет, документов пять (четыре своих
  и СЧФ), связанных из A не видно.
- `http://localhost:8082/pt-repair-packets`: фильтр «Дата с» по умолчанию
  01.06.2026 и отсекает фикстурные строки — поставить 01.01.2025, затем
  «Результат контроля» = «Нарушение».
- `http://localhost:8082/dr-diadoc-oper-repair-packet-vu23s`: пакетов ВУ-23 в
  свежей схеме нет. Строку для проверки фильтра и кнопки «Текст ошибки» можно
  завести так, а после проверки удалить:

```sql
insert into main_f_diadoc_check.dr_diadoc_oper_repair_packet
  (message_id, packet_type, diadoc_type, wagnum, depo, pack_checked_code, pack_checked_text,
   act_number, act_date, dateotc, dateout, tor_pack_id, pack_first_get_date, pack_last_get_date)
values ('99999999-0000-0000-0000-000000000923', 10, 'vu23', 62143110, 'ВЧДЭ-1 Челябинск, 4100', 1,
  repeat('Документ TorID D0075387308 перечислен в пакете, но вложен в другое сообщение. ', 4),
  'T06-VU23', date '2026-06-29', timestamp '2026-06-28', timestamp '2026-06-29', 'D0075461062',
  timestamp '2026-09-20 10:00:00', timestamp '2026-09-20 10:00:00');
```

Фильтр «Дата поступления с» на этом экране по умолчанию — сегодняшняя дата
минус десять дней; для строки выше подходит `01.09.2026`.

### Шаг 7

```bash
./gradlew :app:test            # rvk-ws
./gradlew spotlessCheckAll     # rvk-ws
(cd /home/mindils/data/dev/fgk/rvk-diadoc && ./gradlew test && ./gradlew spotlessApply && git status --short)
```

Про 90 падений `:app:test` — раздел «Ограничения» и [Q01](../../questions/Q01.md).
Если нужно повторить сравнение с базой: `git worktree add <dir> 631acb2e0
--detach`, скопировать в него `application-local.properties`,
`application-dev.properties`, `app/src/test/resources/application-test-local.properties`
(в двух первых подменить схему и порт), `migration/ws_store/liquibase.properties`,
создать пустой файл `.use-public-repos`, выполнить
`(cd system && ./change-gradle-to-remote-repo.sh)` и прогнать `:app:test`.

### Общие ресурсы

Заняты по очереди и освобождены: БД 5436 и порт 8081 (rvk-diadoc), схема
`main_f_diadoc_check`, порт 8082 и Gradle daemon (rvk-ws), браузер, а также
две строки в общей `ws_store` (удалены). Схема `main_f_diadoc_check` была
пересоздана — если в соседней сессии на неё кто-то рассчитывал, данных там
больше нет.

## Ограничения и связанные изменения

- **C4 выполнен не буквально.** `:app:test` в worktree даёт 90 падений; все
  они есть и на базовом коммите (там их 100), новых нет, десять починены этой
  работой. Причина — жёсткая схема `main` в SQL полутора десятков
  интеграционных тестов (`DrOperRepairTr2ParserServiceIT`, `TechClaimDeadlineIT`,
  `WorkCalendarReferenceDataIT`, `MhDetailOriginServiceIT`,
  `DiadocPacketCorrectionIT` и другие) при подключении к `main_f_diadoc_check`:
  подготовка и уборка данных уходят в чужую схему. Тот же дефект уже чинился
  точечно в `PacketReplayFixtures` (F01 к T03). Правка остальных — вне области
  T06; решение вынесено в [Q01](../../questions/Q01.md).
- **Шаг 4 опирается на фикстурный ремонт.** Данных по вагону 62143110 в
  `ws_store` нет и взять их неоткуда — это внешний источник. Две строки ремонта
  заведены вручную (SQL выше). Сам объект проверки при этом настоящий: пакет B
  из -26 со своими линками и своими `violations`; фикстурой подменена только
  недостающая привязка к ремонту.
- **Негативный сценарий уточняет постановку.** «Process пакета контрагента без
  строки настроек при умолчаниях `false` — новых нарушений нет» выполняется для
  трёх проверок зеркала, но не для связанных документов: в умолчаниях
  `showRelatedDocuments=true`, а эта же настройка по решению плана включает
  проверку связанных. Поэтому строка «В системе есть подписанные документы …»
  при умолчаниях появляется. Это соответствует решениям плана, не дефект.
- **Доказательства других тасков не затронуты:** кода T01-T05 не менялось,
  их `pass` остаются в силе.
