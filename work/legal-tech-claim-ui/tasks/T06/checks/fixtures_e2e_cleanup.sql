-- Снятие фикстуры сквозной проверки T06 (fixtures_e2e.sql).
--
-- Снимает и строки, созданные в браузере кнопкой «Создать претензию»: они
-- принадлежат отцепкам с тем же префиксом repair_uid.
--
-- Запуск:
--   docker exec -i docker-rvk-db-1 psql -U root -d postgres -v ON_ERROR_STOP=1 \
--     < specs/work/legal-tech-claim-ui/tasks/T06/checks/fixtures_e2e_cleanup.sql
BEGIN;

DELETE FROM main.legal_tech_claim_deadlines
WHERE deps_id IN (SELECT id FROM main.legal_tech_claim_deps
                  WHERE repair_uid::text LIKE '99999999-0060-0000-0000-%');

DELETE FROM main.legal_tech_claim_du
WHERE deps_id IN (SELECT id FROM main.legal_tech_claim_deps
                  WHERE repair_uid::text LIKE '99999999-0060-0000-0000-%');

DELETE FROM main.legal_tech_claim_case_one
WHERE deps_id IN (SELECT id FROM main.legal_tech_claim_deps
                  WHERE repair_uid::text LIKE '99999999-0060-0000-0000-%');

DELETE FROM main.legal_tech_claim_deps
WHERE repair_uid::text LIKE '99999999-0060-0000-0000-%';

DELETE FROM main.legal_tech_claim
WHERE repair_uid::text LIKE '99999999-0060-0000-0000-%';

DELETE FROM main.sec_role_assignment WHERE username IN ('t06-deps', 't06-du', 't06-adm');
DELETE FROM main.sso_user WHERE username IN ('t06-deps', 't06-du', 't06-adm');

COMMIT;

-- Контроль: все четыре таблицы раздела и пользователи проверки должны дать нули.
SELECT (SELECT count(*) FROM main.legal_tech_claim)                   AS tech_claim,
       (SELECT count(*) FROM main.legal_tech_claim_deps)              AS deps,
       (SELECT count(*) FROM main.legal_tech_claim_du)                AS du,
       (SELECT count(*) FROM main.legal_tech_claim_case_one)          AS case_one,
       (SELECT count(*) FROM main.legal_tech_claim_deadlines)         AS deadlines,
       (SELECT count(*) FROM main.sso_user
        WHERE username IN ('t06-deps', 't06-du', 't06-adm'))          AS users,
       (SELECT count(*) FROM main.sec_role_assignment
        WHERE username IN ('t06-deps', 't06-du', 't06-adm'))          AS assignments;
