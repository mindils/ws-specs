-- Временные данные для smoke-проверки карточки претензии T05.
-- Снимаются t05-smoke-cleanup.sql.
--
-- Запуск: docker exec -i docker-rvk-db-1 psql -U root -d postgres -v ON_ERROR_STOP=1 \
--           < specs/work/legal-tech-claim-ui/input/t05-smoke-fixture.sql
--
-- Отцепка с заполненной шапкой и две претензии по ней: у первой есть парная
-- строка ДЮ, у второй её нет (проверка подстановки строки при открытии).
-- Расчёт сроков не вставляется: он появится при первом сохранении карточки.
BEGIN;

INSERT INTO main.legal_tech_claim
    (repair_uid, wagnum, defect_date, repair_date, railway_code, railway_mnkd, depo_code,
     depo_name, repair_type, defect_code_tn, defect_code_1, defect_code_2, defect_code_3,
     defect_name, category_oper, last_repair_date, last_repair_type, last_repair_depo,
     last_repair_depo_name, last_repair_vrk, last_repair_contract_num, last_repair_contract_date,
     lease_contract_num)
VALUES ('99999999-0000-0000-0000-0000000c1a05', 55500501, current_date - 120, current_date - 100,
        'ЗС', 'Западно-Сибирская', 1234, 'ВЧДР Смоук T05', 3, 205, 205, NULL, 0,
        'Технологическая неисправность (smoke T05)', 'ВГК', current_date - 500, 1, 4321,
        'ВЧДР Плановый', 'ВРК1', 'ДГ-2025/777', current_date - 520, NULL);

INSERT INTO main.legal_tech_claim_deps
    (repair_uid, claim_index, subject_to_claim, warranty_is_vrp, warranty_depo_code,
     warranty_type, warranty_railway_code, warranty_note, doc_package_ready_date,
     pre_claim_department, downtime_days, downtime_penalty_per_day, invoice_for_repair_cost,
     warranty_repair_cost)
SELECT '99999999-0000-0000-0000-0000000c1a05', i, true, true, 4321, 'ВРК1', 'ЗС',
       'Смоук T05', current_date - 60, 'ДЭПС', 7, 1500.00, 5000.00, 50000.00
FROM generate_series(1, 2) i;

-- Парная строка ДЮ есть только у первой претензии.
INSERT INTO main.legal_tech_claim_du (deps_id, claim_number, claim_date, claim_cost)
SELECT id, 'СМОУК-T05-1', current_date - 30, 40000.00
FROM main.legal_tech_claim_deps
WHERE repair_uid = '99999999-0000-0000-0000-0000000c1a05' AND claim_index = 1;

COMMIT;

SELECT id, claim_index FROM main.legal_tech_claim_deps
WHERE repair_uid = '99999999-0000-0000-0000-0000000c1a05' ORDER BY claim_index;
