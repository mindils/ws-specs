-- Временные данные для проверки списка претензий T04.
-- Снимаются t04-smoke-cleanup.sql.
--
-- Запуск: docker exec -i docker-rvk-db-1 psql -U root -d postgres -v ON_ERROR_STOP=1 \
--           < specs/work/legal-tech-claim-ui/input/t04-smoke-fixture.sql
--
-- Даёт три претензии одной отцепки: у первой степени просрочки 1, 2 и 3 на трёх
-- соседних этапах (соседние ячейки одной строки), у второй расчёт по
-- несуществующей ревизии («требуется пересчёт»), у третьей расчёта нет вовсе.
-- Для критерия C3 нужна выборка больше страницы — размножьте отцепки.
BEGIN;

INSERT INTO main.legal_tech_claim
    (repair_uid, wagnum, defect_date, repair_date, railway_code, depo_code, depo_name,
     repair_type, defect_code_1, defect_code_2, defect_code_3, defect_name)
VALUES ('99999999-0000-0000-0000-0000000c1a04', 55500401, current_date - 90, current_date - 80,
        'ЗС', 1234, 'ВЧДР Смоук', 3, 205, NULL, 0, 'Технологическая неисправность (smoke)');

INSERT INTO main.legal_tech_claim_deps (repair_uid, claim_index, warranty_repair_cost,
                                        downtime_days, downtime_penalty_per_day, subject_to_claim)
SELECT '99999999-0000-0000-0000-0000000c1a04', i, 50000.00 * i, 7, 1500.00, true
FROM generate_series(1, 3) i;

-- У претензии 1 дата претензии пуста намеренно: иначе этапы «прикрепление комплекта» и
-- «передача в допретензионную работу» считаются завершёнными и степени просрочки не видно.
INSERT INTO main.legal_tech_claim_du (deps_id, claim_number, claim_date, claim_cost, claim_result)
SELECT id, 'СМОУК-' || claim_index,
       case when claim_index = 1 then null else current_date - 30 end, 40000.00, 1
FROM main.legal_tech_claim_deps
WHERE repair_uid = '99999999-0000-0000-0000-0000000c1a04';

-- Претензия 1: степени 1, 2 и 3 на трёх разных этапах — соседние ячейки красятся независимо.
INSERT INTO main.legal_tech_claim_deadlines
    (deps_id, revision_number, calculated_date,
     doc_attach_due_date, doc_attach_level1_date, doc_attach_level2_date, doc_attach_level3_date,
     pre_claim_transfer_due_date, pre_claim_transfer_level1_date,
     pre_claim_transfer_level2_date, pre_claim_transfer_level3_date,
     pre_claim_letter_due_date, pre_claim_letter_level1_date,
     pre_claim_letter_level2_date, pre_claim_letter_level3_date,
     claim_submit_due_date, claim_submit_level1_date,
     claim_submit_level2_date, claim_submit_level3_date)
SELECT id, 1, now(),
       current_date - 1, current_date, current_date + 10, current_date + 30,
       current_date - 15, current_date - 12, current_date - 1, current_date + 15,
       current_date - 45, current_date - 40, current_date - 30, current_date - 1,
       current_date + 5, current_date + 6, current_date + 15, current_date + 35
FROM main.legal_tech_claim_deps
WHERE repair_uid = '99999999-0000-0000-0000-0000000c1a04' AND claim_index = 1;

-- Претензия 2: расчёт по несуществующей ревизии — признак «требуется пересчёт».
INSERT INTO main.legal_tech_claim_deadlines
    (deps_id, revision_number, calculated_date,
     claim_submit_due_date, claim_submit_level1_date,
     claim_submit_level2_date, claim_submit_level3_date)
SELECT id, 0, now(),
       current_date - 5, current_date, current_date + 10, current_date + 30
FROM main.legal_tech_claim_deps
WHERE repair_uid = '99999999-0000-0000-0000-0000000c1a04' AND claim_index = 2;

-- Претензия 3 остаётся без расчёта вовсе.

-- Роль пользователю при необходимости; на локальной БД у `user` уже есть
-- system-full-access, ui-minimal и dr-contract-read, но пароль у него не задан,
-- поэтому вход выполняется под admin/admin.
-- INSERT INTO main.sec_role_assignment (id, username, role_code, role_type)
-- VALUES ('99999999-0000-0000-0000-0000000c1a04', 'user', 'legal-tech-claim-deps', 'resource');

COMMIT;
