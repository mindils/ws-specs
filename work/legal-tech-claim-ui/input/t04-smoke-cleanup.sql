-- Снятие временных данных t04-smoke-fixture.sql (вместе с претензиями,
-- созданными кнопкой «Создать претензию» по той же отцепке).
BEGIN;
DELETE FROM main.legal_tech_claim_deadlines WHERE deps_id IN
    (SELECT id FROM main.legal_tech_claim_deps WHERE repair_uid = '99999999-0000-0000-0000-0000000c1a04');
DELETE FROM main.legal_tech_claim_du WHERE deps_id IN
    (SELECT id FROM main.legal_tech_claim_deps WHERE repair_uid = '99999999-0000-0000-0000-0000000c1a04');
DELETE FROM main.legal_tech_claim_deps WHERE repair_uid = '99999999-0000-0000-0000-0000000c1a04';
DELETE FROM main.legal_tech_claim WHERE repair_uid = '99999999-0000-0000-0000-0000000c1a04';
DELETE FROM main.sec_role_assignment WHERE id = '99999999-0000-0000-0000-0000000c1a04';
COMMIT;
