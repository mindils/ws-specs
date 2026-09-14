-- Снятие фикстуры независимой проверки T04 (t04-verify-fixture.sql).
--
-- Запуск:
--   docker exec -i docker-rvk-db-1 psql -U root -d postgres -v ON_ERROR_STOP=1 \
--     < specs/work/legal-tech-claim-ui/input/t04-verify-cleanup.sql
BEGIN;

DELETE FROM main.legal_tech_claim_deadlines
WHERE deps_id IN (SELECT id FROM main.legal_tech_claim_deps
                  WHERE repair_uid::text LIKE '99999999-0001-0000-0000-%');

DELETE FROM main.legal_tech_claim_du
WHERE deps_id IN (SELECT id FROM main.legal_tech_claim_deps
                  WHERE repair_uid::text LIKE '99999999-0001-0000-0000-%');

DELETE FROM main.legal_tech_claim_case_one
WHERE deps_id IN (SELECT id FROM main.legal_tech_claim_deps
                  WHERE repair_uid::text LIKE '99999999-0001-0000-0000-%');

DELETE FROM main.legal_tech_claim_deps
WHERE repair_uid::text LIKE '99999999-0001-0000-0000-%';

DELETE FROM main.legal_tech_claim
WHERE repair_uid::text LIKE '99999999-0001-0000-0000-%';

DELETE FROM main.sec_role_assignment WHERE username IN ('t04-deps', 't04-du', 't04-adm');
DELETE FROM main.sso_user WHERE username IN ('t04-deps', 't04-du', 't04-adm');

COMMIT;
