-- Фикстура сквозной проверки T06 (ДЭПС → ДЮ, фильтры, смена дня, публикация
-- ревизии). Все объекты помечены префиксом repair_uid '99999999-0060-%' и
-- именами пользователей 't06-*', поэтому снимаются одним скриптом
-- fixtures_e2e_cleanup.sql.
--
-- Запуск:
--   docker exec -i docker-rvk-db-1 psql -U root -d postgres -v ON_ERROR_STOP=1 \
--     < specs/work/legal-tech-claim-ui/tasks/T06/checks/fixtures_e2e.sql
-- Снятие:
--   docker exec -i docker-rvk-db-1 psql -U root -d postgres -v ON_ERROR_STOP=1 \
--     < specs/work/legal-tech-claim-ui/tasks/T06/checks/fixtures_e2e_cleanup.sql
--
-- Состав:
--   A. Отцепка сценария (uid …0001) с заполненной шапкой и одной претензией
--      (claim_index = 1) со строкой ДЮ. По ней ДЭПС создаёт вторую претензию.
--   B. 64 отцепки по одной претензии для страницы > 50 строк. Группы по i % 4:
--        1 — расчёт по текущей ревизии, степени 1, 2, 3, нет, 1, нет, 2;
--        2 — расчёт по текущей ревизии, все семь этапов степень 3;
--        3 — расчёт по ревизии 0 (не последняя PUBLISHED) → «требуется
--            пересчёт», степень 1 только на первом этапе;
--        0 — строки расчёта нет вовсе → «требуется пересчёт», сроки пустые.
--      Даты факта завершения этапов у этих претензий пустые, поэтому степень
--      полностью задаётся порогами фикстуры относительно current_date.
--   C. Пара «смена дня» (uid …0201 и …0202): строки различаются ровно на один
--      день по всем порогам. Чтение «сегодня» у …0201 совпадает с тем, что
--      покажет …0202 завтра; часы в системе переводить не нужно.
--   D. Претензия с неприменимыми этапами (uid …0301): расчёт по текущей
--      ревизии есть (то есть «Требуется пересчёт» = нет), но назначен только
--      первый этап, остальные шесть — NULL. Отличает неприменимый этап от
--      неактуального расчёта.
--   E. Пользователи t06-deps, t06-du, t06-adm с ролями раздела.
--
-- Скрипт выполняется в транзакциях; при ошибке ничего не остаётся.

-- A. Отцепка сценария ДЭПС → ДЮ.
BEGIN;

INSERT INTO main.legal_tech_claim
    (repair_uid, wagnum, defect_date, repair_date, railway_code, railway_mnkd, depo_code,
     depo_name, repair_type, defect_code_tn, defect_code_1, defect_code_2, defect_code_3,
     defect_name, category_oper, last_repair_date, last_repair_type, last_repair_depo,
     last_repair_depo_name, last_repair_vrk, last_repair_contract_num, last_repair_contract_date,
     lease_contract_num)
VALUES ('99999999-0060-0000-0000-000000000001', 55600601, current_date - 120, current_date - 100,
        'ЗС', 'Западно-Сибирская', 1234, 'ВЧДР Сквозная проверка T06', 3, 205, 205, NULL, 0,
        'Технологическая неисправность (сквозная проверка T06)', 'ВГК', current_date - 500, 1,
        4321, 'ВЧДР Плановый', 'ВРК1', 'ДГ-2025/606', current_date - 520, NULL);

INSERT INTO main.legal_tech_claim_deps
    (repair_uid, claim_index, subject_to_claim, warranty_is_vrp, warranty_depo_code,
     warranty_type, warranty_railway_code, warranty_note, doc_package_ready_date,
     pre_claim_department, downtime_days, downtime_penalty_per_day, invoice_for_repair_cost,
     warranty_repair_cost)
VALUES ('99999999-0060-0000-0000-000000000001', 1, true, true, 4321, 'ВРК1', 'ЗС',
        'Сквозная проверка T06', current_date - 60, 'ДЭПС', 7, 1500.00, 5000.00, 50000.00);

INSERT INTO main.legal_tech_claim_du (deps_id, claim_number, claim_date, claim_cost)
SELECT id, 'ПРЕТ-T06-1', current_date - 30, 40000.00
FROM main.legal_tech_claim_deps
WHERE repair_uid = '99999999-0060-0000-0000-000000000001' AND claim_index = 1;

COMMIT;

-- B. Выборка больше страницы: 64 отцепки по одной претензии.
BEGIN;

INSERT INTO main.legal_tech_claim
    (repair_uid, wagnum, defect_date, repair_date, railway_code, depo_code, depo_name,
     repair_type, defect_code_1, defect_code_2, defect_code_3, defect_name,
     guarantee_kp_count)
SELECT ('99999999-0060-0000-0000-' || lpad((100 + i)::text, 12, '0'))::uuid,
       55610000 + i,
       (current_date - (i * 3))::timestamptz,
       (current_date - (i * 3) - 10)::timestamptz,
       case when i % 2 = 0 then 'ЗС' else 'ВС' end,
       1000 + (i % 5),
       'ВЧДР Проверка T06 ' || (i % 5),
       case when i % 3 = 0 then 1 else 3 end,
       200 + (i % 7), NULL, 0,
       'Технологическая неисправность (T06 ' || i || ')',
       i % 4
FROM generate_series(1, 64) i;

INSERT INTO main.legal_tech_claim_deps
    (repair_uid, claim_index, warranty_repair_cost, downtime_days,
     downtime_penalty_per_day, subject_to_claim, law_registry_num, law_registry_date,
     psr_number)
SELECT ('99999999-0060-0000-0000-' || lpad((100 + i)::text, 12, '0'))::uuid,
       1,
       1000.00 * i,
       5,
       100.00,
       (i % 2 = 1),
       'РЕЕСТР-T06-' || (100 + i),
       (current_date - i)::timestamptz,
       'ПСР-T06-' || (500 + i)
FROM generate_series(1, 64) i;

INSERT INTO main.legal_tech_claim_du (deps_id, claim_number, claim_cost)
SELECT d.id,
       'ПР-T06-' || lpad(right(r.wagnum::text, 3), 3, '0'),
       500.00 * (r.wagnum - 55610000)
FROM main.legal_tech_claim_deps d
         JOIN main.legal_tech_claim r ON r.repair_uid = d.repair_uid
WHERE d.repair_uid::text LIKE '99999999-0060-0000-0000-0000000001%';

-- Группа 1: степени 1, 2, 3, нет, 1, нет, 2 по семи этапам одной строки.
INSERT INTO main.legal_tech_claim_deadlines
    (deps_id, revision_number, calculated_date,
     doc_attach_due_date, doc_attach_level1_date, doc_attach_level2_date, doc_attach_level3_date,
     pre_claim_transfer_due_date, pre_claim_transfer_level1_date,
     pre_claim_transfer_level2_date, pre_claim_transfer_level3_date,
     pre_claim_letter_due_date, pre_claim_letter_level1_date,
     pre_claim_letter_level2_date, pre_claim_letter_level3_date,
     claim_transfer_due_date, claim_transfer_level1_date,
     claim_transfer_level2_date, claim_transfer_level3_date,
     claim_submit_due_date, claim_submit_level1_date,
     claim_submit_level2_date, claim_submit_level3_date,
     law_transfer_due_date, law_transfer_level1_date,
     law_transfer_level2_date, law_transfer_level3_date,
     lawsuit_submit_due_date, lawsuit_submit_level1_date,
     lawsuit_submit_level2_date, lawsuit_submit_level3_date)
SELECT d.id, 1, now(),
       current_date - 1, current_date, current_date + 10, current_date + 30,
       current_date - 25, current_date - 20, current_date - 1, current_date + 20,
       current_date - 60, current_date - 55, current_date - 40, current_date - 1,
       current_date + 20, current_date + 21, current_date + 30, current_date + 50,
       current_date - 2, current_date, current_date + 10, current_date + 30,
       current_date + 40, current_date + 41, current_date + 50, current_date + 70,
       current_date - 30, current_date - 25, current_date - 1, current_date + 25
FROM main.legal_tech_claim_deps d
         JOIN main.legal_tech_claim r ON r.repair_uid = d.repair_uid
WHERE d.repair_uid::text LIKE '99999999-0060-0000-0000-0000000001%'
  AND (r.wagnum - 55610000) % 4 = 1;

-- Группа 2: все семь этапов степень 3.
INSERT INTO main.legal_tech_claim_deadlines
    (deps_id, revision_number, calculated_date,
     doc_attach_due_date, doc_attach_level1_date, doc_attach_level2_date, doc_attach_level3_date,
     pre_claim_transfer_due_date, pre_claim_transfer_level1_date,
     pre_claim_transfer_level2_date, pre_claim_transfer_level3_date,
     pre_claim_letter_due_date, pre_claim_letter_level1_date,
     pre_claim_letter_level2_date, pre_claim_letter_level3_date,
     claim_transfer_due_date, claim_transfer_level1_date,
     claim_transfer_level2_date, claim_transfer_level3_date,
     claim_submit_due_date, claim_submit_level1_date,
     claim_submit_level2_date, claim_submit_level3_date,
     law_transfer_due_date, law_transfer_level1_date,
     law_transfer_level2_date, law_transfer_level3_date,
     lawsuit_submit_due_date, lawsuit_submit_level1_date,
     lawsuit_submit_level2_date, lawsuit_submit_level3_date)
SELECT d.id, 1, now(),
       current_date - 90, current_date - 85, current_date - 70, current_date - 40,
       current_date - 90, current_date - 85, current_date - 70, current_date - 40,
       current_date - 90, current_date - 85, current_date - 70, current_date - 40,
       current_date - 90, current_date - 85, current_date - 70, current_date - 40,
       current_date - 90, current_date - 85, current_date - 70, current_date - 40,
       current_date - 90, current_date - 85, current_date - 70, current_date - 40,
       current_date - 90, current_date - 85, current_date - 70, current_date - 40
FROM main.legal_tech_claim_deps d
         JOIN main.legal_tech_claim r ON r.repair_uid = d.repair_uid
WHERE d.repair_uid::text LIKE '99999999-0060-0000-0000-0000000001%'
  AND (r.wagnum - 55610000) % 4 = 2;

-- Группа 3: устаревшая ревизия, степень 1 только на первом этапе.
INSERT INTO main.legal_tech_claim_deadlines
    (deps_id, revision_number, calculated_date,
     doc_attach_due_date, doc_attach_level1_date, doc_attach_level2_date, doc_attach_level3_date)
SELECT d.id, 0, now(),
       current_date - 3, current_date, current_date + 10, current_date + 30
FROM main.legal_tech_claim_deps d
         JOIN main.legal_tech_claim r ON r.repair_uid = d.repair_uid
WHERE d.repair_uid::text LIKE '99999999-0060-0000-0000-0000000001%'
  AND (r.wagnum - 55610000) % 4 = 3;

-- Группа 0 остаётся без строки расчёта.

COMMIT;

-- C. Пара «смена дня»: пороги различаются ровно на один день.
BEGIN;

INSERT INTO main.legal_tech_claim
    (repair_uid, wagnum, defect_date, repair_date, railway_code, depo_code, depo_name,
     repair_type, defect_code_1, defect_code_3, defect_name)
VALUES ('99999999-0060-0000-0000-000000000201', 55620001, current_date - 40, current_date - 30,
        'ЗС', 1001, 'ВЧДР Смена дня (сегодня)', 3, 205, 0,
        'Технологическая неисправность (смена дня, сегодня)'),
       ('99999999-0060-0000-0000-000000000202', 55620002, current_date - 40, current_date - 30,
        'ЗС', 1001, 'ВЧДР Смена дня (завтра)', 3, 205, 0,
        'Технологическая неисправность (смена дня, завтра)');

INSERT INTO main.legal_tech_claim_deps
    (repair_uid, claim_index, subject_to_claim, warranty_repair_cost, psr_number)
VALUES ('99999999-0060-0000-0000-000000000201', 1, true, 11000.00, 'ПСР-T06-СЕГОДНЯ'),
       ('99999999-0060-0000-0000-000000000202', 1, true, 11000.00, 'ПСР-T06-ЗАВТРА');

INSERT INTO main.legal_tech_claim_du (deps_id, claim_number)
SELECT id, 'ПР-T06-' || right(repair_uid::text, 3)
FROM main.legal_tech_claim_deps
WHERE repair_uid IN ('99999999-0060-0000-0000-000000000201',
                     '99999999-0060-0000-0000-000000000202');

-- …0201: пороги сдвинуты на день назад относительно …0202.
-- Первый этап: level1 = current_date → степень 1 у …0201, нет у …0202.
-- Второй этап: level2 = current_date - 1 → степень 2 у …0201, 1 у …0202.
-- Третий этап: level3 = current_date - 1 → степень 3 у …0201, 2 у …0202.
INSERT INTO main.legal_tech_claim_deadlines
    (deps_id, revision_number, calculated_date,
     doc_attach_due_date, doc_attach_level1_date, doc_attach_level2_date, doc_attach_level3_date,
     pre_claim_transfer_due_date, pre_claim_transfer_level1_date,
     pre_claim_transfer_level2_date, pre_claim_transfer_level3_date,
     pre_claim_letter_due_date, pre_claim_letter_level1_date,
     pre_claim_letter_level2_date, pre_claim_letter_level3_date)
SELECT d.id, 1, now(),
       current_date - 2, current_date, current_date + 9, current_date + 29,
       current_date - 12, current_date - 11, current_date - 1, current_date + 19,
       current_date - 32, current_date - 31, current_date - 21, current_date - 1
FROM main.legal_tech_claim_deps d
WHERE d.repair_uid = '99999999-0060-0000-0000-000000000201';

INSERT INTO main.legal_tech_claim_deadlines
    (deps_id, revision_number, calculated_date,
     doc_attach_due_date, doc_attach_level1_date, doc_attach_level2_date, doc_attach_level3_date,
     pre_claim_transfer_due_date, pre_claim_transfer_level1_date,
     pre_claim_transfer_level2_date, pre_claim_transfer_level3_date,
     pre_claim_letter_due_date, pre_claim_letter_level1_date,
     pre_claim_letter_level2_date, pre_claim_letter_level3_date)
SELECT d.id, 1, now(),
       current_date - 1, current_date + 1, current_date + 10, current_date + 30,
       current_date - 11, current_date - 10, current_date, current_date + 20,
       current_date - 31, current_date - 30, current_date - 20, current_date
FROM main.legal_tech_claim_deps d
WHERE d.repair_uid = '99999999-0060-0000-0000-000000000202';

COMMIT;

-- D. Неприменимые этапы при актуальном расчёте.
BEGIN;

INSERT INTO main.legal_tech_claim
    (repair_uid, wagnum, defect_date, repair_date, railway_code, depo_code, depo_name,
     repair_type, defect_code_1, defect_code_3, defect_name)
VALUES ('99999999-0060-0000-0000-000000000301', 55630001, current_date - 20, current_date - 15,
        'ВС', 1002, 'ВЧДР Неприменимые этапы', 3, 206, 0,
        'Технологическая неисправность (неприменимые этапы)');

INSERT INTO main.legal_tech_claim_deps
    (repair_uid, claim_index, subject_to_claim, warranty_repair_cost, psr_number)
VALUES ('99999999-0060-0000-0000-000000000301', 1, true, 12000.00, 'ПСР-T06-НЕПРИМ');

INSERT INTO main.legal_tech_claim_du (deps_id, claim_number)
SELECT id, 'ПР-T06-301'
FROM main.legal_tech_claim_deps
WHERE repair_uid = '99999999-0060-0000-0000-000000000301';

-- Расчёт по текущей ревизии есть (deadlines_outdated = false), назначен только
-- первый этап: остальные шесть групп дат NULL — неприменимые, а не «нет расчёта».
INSERT INTO main.legal_tech_claim_deadlines
    (deps_id, revision_number, calculated_date,
     doc_attach_due_date, doc_attach_level1_date, doc_attach_level2_date, doc_attach_level3_date)
SELECT d.id, 1, now(),
       current_date + 5, current_date + 6, current_date + 15, current_date + 35
FROM main.legal_tech_claim_deps d
WHERE d.repair_uid = '99999999-0060-0000-0000-000000000301';

COMMIT;

-- E. Пользователи сквозной проверки.
BEGIN;

INSERT INTO main.sso_user (id, version, username, first_name, last_name, password, active)
VALUES ('99999999-0061-0000-0000-000000000001', 1, 't06-deps', 'T06', 'ДЭПС', '{noop}t06', true),
       ('99999999-0061-0000-0000-000000000002', 1, 't06-du', 'T06', 'ДЮ', '{noop}t06', true),
       ('99999999-0061-0000-0000-000000000003', 1, 't06-adm', 'T06', 'Админ раздела', '{noop}t06', true);

INSERT INTO main.sec_role_assignment (id, version, username, role_code, role_type)
VALUES ('99999999-0062-0000-0000-000000000001', 1, 't06-deps', 'ui-minimal', 'resource'),
       ('99999999-0062-0000-0000-000000000002', 1, 't06-deps', 'legal-tech-claim-deps', 'resource'),
       ('99999999-0062-0000-0000-000000000003', 1, 't06-du', 'ui-minimal', 'resource'),
       ('99999999-0062-0000-0000-000000000004', 1, 't06-du', 'legal-tech-claim-du', 'resource'),
       ('99999999-0062-0000-0000-000000000005', 1, 't06-adm', 'ui-minimal', 'resource'),
       ('99999999-0062-0000-0000-000000000006', 1, 't06-adm', 'legal-tech-claim-admin', 'resource'),
       ('99999999-0062-0000-0000-000000000007', 1, 't06-adm', 'nsi-claim-term-edit', 'resource');

COMMIT;

-- Контрольная выдача: id претензий сценария и число строк фикстуры.
SELECT d.id, r.wagnum, d.claim_index, r.repair_uid
FROM main.legal_tech_claim_deps d
         JOIN main.legal_tech_claim r ON r.repair_uid = d.repair_uid
WHERE d.repair_uid IN ('99999999-0060-0000-0000-000000000001',
                       '99999999-0060-0000-0000-000000000201',
                       '99999999-0060-0000-0000-000000000202',
                       '99999999-0060-0000-0000-000000000301')
ORDER BY r.wagnum, d.claim_index;

SELECT count(*) AS claims_total
FROM main.legal_tech_claim_deps
WHERE repair_uid::text LIKE '99999999-0060-0000-0000-%';
