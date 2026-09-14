-- Фикстура независимой проверки T04: выборка больше страницы с разными
-- степенями просрочки, устаревшим и отсутствующим расчётом.
--
-- Запуск:
--   docker exec -i docker-rvk-db-1 psql -U root -d postgres -v ON_ERROR_STOP=1 \
--     < specs/work/legal-tech-claim-ui/input/t04-verify-fixture.sql
-- Снятие: t04-verify-cleanup.sql
--
-- 80 отцепок, по одной претензии на каждую. Все даты факта завершения этапов
-- (claim_date, claim_send_date, to_law_date, lawsuit_date, pre_claim_send_date,
-- doc_transfer_date, claim_transfer_date, pre_claim_transfer_date) оставлены
-- пустыми: тогда во view факт = CURRENT_DATE и степень просрочки полностью
-- задаётся датами порогов level1/2/3 из фикстуры.
--
-- Группы по i % 4:
--   1 — расчёт по текущей ревизии; степени 1, 2, 3, нет, 1, нет, 2 по семи
--       этапам (соседние ячейки одной строки — разные степени);
--   2 — расчёт по текущей ревизии; все семь этапов степень 3;
--   3 — расчёт по ревизии 0 (не последняя PUBLISHED) → «требуется пересчёт»,
--       степень 1 только на первом этапе;
--   0 — строки расчёта нет вовсе → «требуется пересчёт», сроки пустые.
BEGIN;

INSERT INTO main.legal_tech_claim
    (repair_uid, wagnum, defect_date, repair_date, railway_code, depo_code, depo_name,
     repair_type, defect_code_1, defect_code_2, defect_code_3, defect_name,
     guarantee_kp_count)
SELECT ('99999999-0001-0000-0000-' || lpad(i::text, 12, '0'))::uuid,
       55510000 + i,
       (current_date - (i * 3))::timestamptz,
       (current_date - (i * 3) - 10)::timestamptz,
       case when i % 2 = 0 then 'ЗС' else 'ВС' end,
       1000 + (i % 5),
       'ВЧДР Проверка ' || (i % 5),
       case when i % 3 = 0 then 1 else 3 end,
       200 + (i % 7), NULL, 0,
       'Технологическая неисправность (проверка ' || i || ')',
       i % 4
FROM generate_series(1, 80) i;

INSERT INTO main.legal_tech_claim_deps
    (repair_uid, claim_index, warranty_repair_cost, downtime_days,
     downtime_penalty_per_day, subject_to_claim, law_registry_num, law_registry_date,
     psr_number)
SELECT ('99999999-0001-0000-0000-' || lpad(i::text, 12, '0'))::uuid,
       1,
       1000.00 * i,
       5,
       100.00,
       (i % 2 = 1),
       'РЕЕСТР-' || (100 + i),
       (current_date - i)::timestamptz,
       'ПСР-' || (500 + i)
FROM generate_series(1, 80) i;

INSERT INTO main.legal_tech_claim_du (deps_id, claim_number, claim_cost)
SELECT d.id,
       'ПР-2026-' || lpad(right(r.wagnum::text, 3), 3, '0'),
       500.00 * (r.wagnum - 55510000)
FROM main.legal_tech_claim_deps d
         JOIN main.legal_tech_claim r ON r.repair_uid = d.repair_uid
WHERE d.repair_uid::text LIKE '99999999-0001-0000-0000-%';

-- Группа 1: степени 1, 2, 3, нет, 1, нет, 2.
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
WHERE d.repair_uid::text LIKE '99999999-0001-0000-0000-%'
  AND (r.wagnum - 55510000) % 4 = 1;

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
WHERE d.repair_uid::text LIKE '99999999-0001-0000-0000-%'
  AND (r.wagnum - 55510000) % 4 = 2;

-- Группа 3: устаревшая ревизия, степень 1 только на первом этапе.
INSERT INTO main.legal_tech_claim_deadlines
    (deps_id, revision_number, calculated_date,
     doc_attach_due_date, doc_attach_level1_date, doc_attach_level2_date, doc_attach_level3_date)
SELECT d.id, 0, now(),
       current_date - 3, current_date, current_date + 10, current_date + 30
FROM main.legal_tech_claim_deps d
         JOIN main.legal_tech_claim r ON r.repair_uid = d.repair_uid
WHERE d.repair_uid::text LIKE '99999999-0001-0000-0000-%'
  AND (r.wagnum - 55510000) % 4 = 3;

-- Группа 0 остаётся без строки расчёта.

COMMIT;

-- Пользователи проверки: ДЭПС, ДЮ и администратор раздела.
BEGIN;

INSERT INTO main.sso_user (id, version, username, first_name, last_name, password, active)
VALUES ('99999999-0002-0000-0000-000000000001', 1, 't04-deps', 'T04', 'ДЭПС', '{noop}t04', true),
       ('99999999-0002-0000-0000-000000000002', 1, 't04-du', 'T04', 'ДЮ', '{noop}t04', true),
       ('99999999-0002-0000-0000-000000000003', 1, 't04-adm', 'T04', 'Админ раздела', '{noop}t04', true);

INSERT INTO main.sec_role_assignment (id, version, username, role_code, role_type)
VALUES ('99999999-0003-0000-0000-000000000001', 1, 't04-deps', 'ui-minimal', 'resource'),
       ('99999999-0003-0000-0000-000000000002', 1, 't04-deps', 'legal-tech-claim-deps', 'resource'),
       ('99999999-0003-0000-0000-000000000003', 1, 't04-du', 'ui-minimal', 'resource'),
       ('99999999-0003-0000-0000-000000000004', 1, 't04-du', 'legal-tech-claim-du', 'resource'),
       ('99999999-0003-0000-0000-000000000005', 1, 't04-adm', 'ui-minimal', 'resource'),
       ('99999999-0003-0000-0000-000000000006', 1, 't04-adm', 'legal-tech-claim-admin', 'resource');

COMMIT;
