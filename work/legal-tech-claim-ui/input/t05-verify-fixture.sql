-- Фикстура независимой проверки T05 (карточка претензии).
--
-- Запуск:
--   docker exec -i docker-rvk-db-1 psql -U root -d postgres -v ON_ERROR_STOP=1 \
--     < specs/work/legal-tech-claim-ui/input/t05-verify-fixture.sql
-- Снятие: t05-verify-cleanup.sql
--
-- Одна отцепка с заполненной шапкой и три претензии по ней:
--   claim_index = 1 — парная строка ДЮ есть (основной сценарий C1-C5);
--   claim_index = 2 — строки ДЮ нет (подстановка строки и сообщение под ролями
--                     без права CREATE);
--   claim_index = 3 — дата комплекта 2026-12-30: срок уходит за конец
--                     наполненного календаря (2026-12-31) → ошибка расчёта, C6.
-- Плюс три пользователя проверки: ДЭПС, ДЮ и администратор раздела.
BEGIN;

INSERT INTO main.legal_tech_claim
    (repair_uid, wagnum, defect_date, repair_date, railway_code, railway_mnkd, depo_code,
     depo_name, repair_type, defect_code_tn, defect_code_1, defect_code_2, defect_code_3,
     defect_name, category_oper, last_repair_date, last_repair_type, last_repair_depo,
     last_repair_depo_name, last_repair_vrk, last_repair_contract_num, last_repair_contract_date,
     lease_contract_num)
VALUES ('99999999-0005-0000-0000-000000000005', 55500505, current_date - 120, current_date - 100,
        'ЗС', 'Западно-Сибирская', 1234, 'ВЧДР Проверка T05', 3, 205, 205, NULL, 0,
        'Технологическая неисправность (проверка T05)', 'ВГК', current_date - 500, 1, 4321,
        'ВЧДР Плановый', 'ВРК1', 'ДГ-2025/555', current_date - 520, NULL);

INSERT INTO main.legal_tech_claim_deps
    (repair_uid, claim_index, subject_to_claim, warranty_is_vrp, warranty_depo_code,
     warranty_type, warranty_railway_code, warranty_note, doc_package_ready_date,
     pre_claim_department, downtime_days, downtime_penalty_per_day, invoice_for_repair_cost,
     warranty_repair_cost)
SELECT '99999999-0005-0000-0000-000000000005', i, true, true, 4321, 'ВРК1', 'ЗС',
       'Проверка T05', current_date - 60, 'ДЭПС', 7, 1500.00, 5000.00, 50000.00
FROM generate_series(1, 2) i;

-- Претензия 3: дата комплекта за пределами наполненного календаря.
INSERT INTO main.legal_tech_claim_deps
    (repair_uid, claim_index, subject_to_claim, warranty_is_vrp, warranty_depo_code,
     warranty_type, warranty_railway_code, doc_package_ready_date, pre_claim_department)
VALUES ('99999999-0005-0000-0000-000000000005', 3, true, true, 4321, 'ВРК1', 'ЗС',
        DATE '2026-12-30', 'ДЭПС');

-- Парная строка ДЮ есть только у первой претензии.
INSERT INTO main.legal_tech_claim_du (deps_id, claim_number, claim_date, claim_cost)
SELECT id, 'ПРОВЕРКА-T05-1', current_date - 30, 40000.00
FROM main.legal_tech_claim_deps
WHERE repair_uid = '99999999-0005-0000-0000-000000000005' AND claim_index = 1;

COMMIT;

-- Пользователи проверки: ДЭПС, ДЮ и администратор раздела.
BEGIN;

INSERT INTO main.sso_user (id, version, username, first_name, last_name, password, active)
VALUES ('99999999-0006-0000-0000-000000000001', 1, 't05-deps', 'T05', 'ДЭПС', '{noop}t05', true),
       ('99999999-0006-0000-0000-000000000002', 1, 't05-du', 'T05', 'ДЮ', '{noop}t05', true),
       ('99999999-0006-0000-0000-000000000003', 1, 't05-adm', 'T05', 'Админ раздела', '{noop}t05', true);

INSERT INTO main.sec_role_assignment (id, version, username, role_code, role_type)
VALUES ('99999999-0007-0000-0000-000000000001', 1, 't05-deps', 'ui-minimal', 'resource'),
       ('99999999-0007-0000-0000-000000000002', 1, 't05-deps', 'legal-tech-claim-deps', 'resource'),
       ('99999999-0007-0000-0000-000000000003', 1, 't05-du', 'ui-minimal', 'resource'),
       ('99999999-0007-0000-0000-000000000004', 1, 't05-du', 'legal-tech-claim-du', 'resource'),
       ('99999999-0007-0000-0000-000000000005', 1, 't05-adm', 'ui-minimal', 'resource'),
       ('99999999-0007-0000-0000-000000000006', 1, 't05-adm', 'legal-tech-claim-admin', 'resource');

COMMIT;

SELECT id, claim_index, doc_package_ready_date
FROM main.legal_tech_claim_deps
WHERE repair_uid = '99999999-0005-0000-0000-000000000005'
ORDER BY claim_index;
