-- Снятие фикстуры независимой проверки T05 (t05-verify-fixture.sql).
--
-- Запуск:
--   docker exec -i docker-rvk-db-1 psql -U root -d postgres -v ON_ERROR_STOP=1 \
--     < specs/work/legal-tech-claim-ui/input/t05-verify-cleanup.sql
BEGIN;

DELETE FROM main.legal_tech_claim_deadlines
WHERE deps_id IN (SELECT id FROM main.legal_tech_claim_deps
                  WHERE repair_uid = '99999999-0005-0000-0000-000000000005');

DELETE FROM main.legal_tech_claim_du
WHERE deps_id IN (SELECT id FROM main.legal_tech_claim_deps
                  WHERE repair_uid = '99999999-0005-0000-0000-000000000005');

DELETE FROM main.legal_tech_claim_case_one
WHERE deps_id IN (SELECT id FROM main.legal_tech_claim_deps
                  WHERE repair_uid = '99999999-0005-0000-0000-000000000005');

DELETE FROM main.legal_tech_claim_deps
WHERE repair_uid = '99999999-0005-0000-0000-000000000005';

DELETE FROM main.legal_tech_claim
WHERE repair_uid = '99999999-0005-0000-0000-000000000005';

DELETE FROM main.sec_role_assignment WHERE username IN ('t05-deps', 't05-du', 't05-adm');
DELETE FROM main.sso_user WHERE username IN ('t05-deps', 't05-du', 't05-adm');

COMMIT;

SELECT (SELECT count(*) FROM main.legal_tech_claim
        WHERE repair_uid = '99999999-0005-0000-0000-000000000005')      AS claims,
       (SELECT count(*) FROM main.legal_tech_claim_deps
        WHERE repair_uid = '99999999-0005-0000-0000-000000000005')      AS deps,
       (SELECT count(*) FROM main.sso_user
        WHERE username IN ('t05-deps', 't05-du', 't05-adm'))            AS users,
       (SELECT count(*) FROM main.sec_role_assignment
        WHERE username IN ('t05-deps', 't05-du', 't05-adm'))            AS assignments;
