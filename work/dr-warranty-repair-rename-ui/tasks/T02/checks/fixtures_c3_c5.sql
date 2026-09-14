-- Фикстуры и проверка критериев C3, C4, C5 таска T02.
-- Данные полностью удаляются в конце скрипта (всё выполняется в одной транзакции с rollback).
set search_path to main;

begin;


insert into dr_warranty_repair (repair_uid, wagnum, defect_date, repair_date, depo_name)
values ('aaaaaaaa-0000-4000-8000-0000000cafe2', 55500001, timestamp '2025-02-01', timestamp '2025-03-15', 'ТЕСТ ДЕПО T02');

-- P1: полная претензия с _du и _case_one
insert into dr_warranty_repair_deps
  (repair_uid, claim_index, downtime_days, downtime_penalty_per_day,
   invoice_for_repair_cost, invoice_after_repair_cost, calculated_invoice_cost, broken_tariff_cost,
   warranty_repair_cost)
values ('aaaaaaaa-0000-4000-8000-0000000cafe2', 1, 7, 1500.00,
        12000.50, 8000.25, 3000.0000, 999.99, 50000.00);

-- P2: без _du и без _case_one, суммы перевыставления пустые
insert into dr_warranty_repair_deps (repair_uid, claim_index, warranty_repair_cost)
values ('aaaaaaaa-0000-4000-8000-0000000cafe2', 2, 1000.00);

-- P3: удалённая претензия
insert into dr_warranty_repair_deps (repair_uid, claim_index, warranty_repair_cost, deleted_date)
values ('aaaaaaaa-0000-4000-8000-0000000cafe2', 3, 333.00, now());

-- P4: результат претензии не проставлен, сработает ветка pre_claim_result = 1
insert into dr_warranty_repair_deps (repair_uid, claim_index, pre_claim_result, pre_claim_cost)
values ('aaaaaaaa-0000-4000-8000-0000000cafe2', 4, 1, 5000.00);

-- P5: претензия отклонена полностью; перевыставление через broken_tariff_cost (calculated пуст)
insert into dr_warranty_repair_deps
  (repair_uid, claim_index, invoice_for_repair_cost, broken_tariff_cost)
values ('aaaaaaaa-0000-4000-8000-0000000cafe2', 5, 100.00, 50.00);

-- P6: претензия признана полностью, есть частичная оплата
insert into dr_warranty_repair_deps (repair_uid, claim_index) 
values ('aaaaaaaa-0000-4000-8000-0000000cafe2', 6);

insert into dr_warranty_repair_du (deps_id, claim_cost, claim_result, at_fault_accepted_cost, payment_cost)
select id, 83500.75, 3, 60000.00, 45000.00 from dr_warranty_repair_deps where claim_index = 1
  and repair_uid = 'aaaaaaaa-0000-4000-8000-0000000cafe2';
insert into dr_warranty_repair_du (deps_id, claim_cost)
select id, 7777.77 from dr_warranty_repair_deps where claim_index = 4
  and repair_uid = 'aaaaaaaa-0000-4000-8000-0000000cafe2';
insert into dr_warranty_repair_du (deps_id, claim_cost, claim_result)
select id, 2500.00, 2 from dr_warranty_repair_deps where claim_index = 5
  and repair_uid = 'aaaaaaaa-0000-4000-8000-0000000cafe2';
insert into dr_warranty_repair_du (deps_id, claim_cost, claim_result, payment_cost)
select id, 9000.00, 1, 3000.00 from dr_warranty_repair_deps where claim_index = 6
  and repair_uid = 'aaaaaaaa-0000-4000-8000-0000000cafe2';

insert into dr_warranty_repair_case_one (deps_id, case_one_status)
select id, 1 from dr_warranty_repair_deps where claim_index = 1
  and repair_uid = 'aaaaaaaa-0000-4000-8000-0000000cafe2';

\echo '=== C3/C5: вычисляемые колонки ==='
select claim_index,
       downtime_penalty_cost, tariff_rebill_total_calc, total_reimbursement,
       underpaid_cost, rejected_cost, in_review_cost, claim_deadline_date,
       case_one_status
from dr_v_warranty_repair_claim
where repair_uid = 'aaaaaaaa-0000-4000-8000-0000000cafe2'
order by claim_index;

\echo '=== C4: удалённая претензия (claim_index = 3) не должна присутствовать ==='
select count(*) as deleted_rows_visible
from dr_v_warranty_repair_claim
where repair_uid = 'aaaaaaaa-0000-4000-8000-0000000cafe2' and claim_index = 3;

\echo '=== C5: одна строка на претензию, внешние джойны не размножают и не теряют ==='
select count(*) as visible_claims
from dr_v_warranty_repair_claim
where repair_uid = 'aaaaaaaa-0000-4000-8000-0000000cafe2';

rollback;
