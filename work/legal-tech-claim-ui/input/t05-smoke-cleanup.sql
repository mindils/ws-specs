-- Снятие временных данных t05-smoke-fixture.sql.
BEGIN;
DELETE FROM main.legal_tech_claim_deadlines WHERE deps_id IN
    (SELECT id FROM main.legal_tech_claim_deps WHERE repair_uid = '99999999-0000-0000-0000-0000000c1a05');
DELETE FROM main.legal_tech_claim_du WHERE deps_id IN
    (SELECT id FROM main.legal_tech_claim_deps WHERE repair_uid = '99999999-0000-0000-0000-0000000c1a05');
DELETE FROM main.legal_tech_claim_deps WHERE repair_uid = '99999999-0000-0000-0000-0000000c1a05';
DELETE FROM main.legal_tech_claim WHERE repair_uid = '99999999-0000-0000-0000-0000000c1a05';
COMMIT;
