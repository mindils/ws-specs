-- Синтетические пакеты для показа вкладки «Автоподписание». Только локальная БД (docker-rvk-db-1).
-- Все messageId и entityId начинаются с a5170000-; удаление — demo-data-cleanup.sql.
set search_path = main;

-- Автосогласование: ВУ-23 включено, МХ-1 выключено.
delete from nsi_nv_processing_settings
 where code in ('Diadoc.AutoApproval.VU23', 'Diadoc.AutoApproval.MX1');
insert into nsi_nv_processing_settings (id, code, name, val)
values ((select coalesce(max(id), 0) + 1 from nsi_nv_processing_settings),
        'Diadoc.AutoApproval.VU23', 'Автосогласование ВУ-23', '1');
insert into nsi_nv_processing_settings (id, code, name, val)
values ((select coalesce(max(id), 0) + 1 from nsi_nv_processing_settings),
        'Diadoc.AutoApproval.MX1', 'Автосогласование МХ-1', '0');

-- Пакеты: NN — вариант.
-- 01 нарушение (наработка processPacket), 02 предупреждение, 03 подписанные/отклонённые документы,
-- 04 можно, 05 автосогласован, 06 отправлен вручную, 07 МХ-1 — автосогласование выключено.
insert into diadoc_packet (message_id, status, document_type, contractor_code, depo, wagnum,
                           document_date, root_packet, violations, violations_calculated_at,
                           created_date)
select ('a5170000-0000-0000-0000-0000000000' || nn)::uuid,
       'complete',
       case when nn = '07' then 'removed_parts' else 'vu23' end,
       'AUTOSIGN_DEMO',
       'Демо-депо автоподписания ' || nn,
       '500000' || nn,
       now(),
       true,
       '[]'::jsonb,
       now(),
       now()
  from unnest(array['01', '02', '03', '04', '05', '06', '07']) as nn;

-- Свой документ у каждого пакета: entityId a5170000-0000-0000-0000-0000000001NN.
insert into diadoc_packet_doc (entity_id, message_id, entity_type, document_type, document_number,
                               document_date, created_date)
select ('a5170000-0000-0000-0000-0000000001' || nn)::uuid,
       ('a5170000-0000-0000-0000-0000000000' || nn)::uuid,
       'Attachment',
       case when nn = '07' then 'MX_1' else 'VU_23' end,
       'ДЕМО-' || nn,
       now(),
       now()
  from unnest(array['01', '02', '03', '04', '05', '06', '07']) as nn;

insert into diadoc_packet_doc_link (id, message_id, entity_id, main_document, related_document,
                                    supplement_document, original_message_id)
select gen_random_uuid(),
       ('a5170000-0000-0000-0000-0000000000' || nn)::uuid,
       ('a5170000-0000-0000-0000-0000000001' || nn)::uuid,
       true, false, false,
       ('a5170000-0000-0000-0000-0000000000' || nn)::uuid
  from unnest(array['01', '02', '03', '04', '05', '06', '07']) as nn;

-- 03: свой документ подписан в Диадоке, второй документ пакета — отклонён.
update diadoc_packet_doc set signature_status = '8002'
 where entity_id = 'a5170000-0000-0000-0000-000000000103';
insert into diadoc_packet_doc (entity_id, message_id, entity_type, document_type, document_number,
                               signature_status, document_date, created_date)
values ('a5170000-0000-0000-0000-000000000203', 'a5170000-0000-0000-0000-000000000003',
        'Attachment', 'VU_36', 'ДЕМО-03-2', '8015', now(), now());
insert into diadoc_packet_doc_link (id, message_id, entity_id, main_document, related_document,
                                    supplement_document, original_message_id)
values (gen_random_uuid(), 'a5170000-0000-0000-0000-000000000003',
        'a5170000-0000-0000-0000-000000000203', false, false, false,
        'a5170000-0000-0000-0000-000000000003');

-- Строки проверки (наработка) для 02–07; 01 нарабатывается через /api/diadoc/processPacket.
insert into packet_check (source_type, source_key, packet_type, status, items, checked_at)
select 'DIADOC',
       ('a5170000-0000-0000-0000-0000000000' || nn)::uuid,
       case when nn = '07' then 'removed_parts' else 'vu23' end,
       case when nn = '02' then 2 else 0 end,
       case when nn = '02' then
         '[{"code": "BUSINESS_VU23", "source": "BUSINESS", "severity": "WARNING",
            "message": "Дата ремонта в ВУ-23 отличается от даты в ВУ-36 больше чем на сутки"}]'::jsonb
       else '[]'::jsonb end,
       now()
  from unnest(array['02', '03', '04', '05', '06', '07']) as nn;

-- 05: пакет уже автосогласован (так /api/diadoc/approve записывает флоу).
-- 06: пакет отправил на согласование пользователь.
insert into diadoc_packet_flow (message_id, status, signing_type, approved_by, approved_date,
                                created_date, source)
values ('a5170000-0000-0000-0000-000000000005', 'TO_SIGN', 'SIGN', 'Автомат', now() - interval '2 hour',
        now() - interval '2 hour', 'LOCAL'),
       ('a5170000-0000-0000-0000-000000000006', 'PENDING_SIGN', 'SIGN', 'user', now() - interval '1 day',
        now() - interval '1 day', 'LOCAL');
insert into diadoc_packet_document_flow (id, entity_id, message_id, status)
values (gen_random_uuid(), 'a5170000-0000-0000-0000-000000000105',
        'a5170000-0000-0000-0000-000000000005', 'NEW'),
       (gen_random_uuid(), 'a5170000-0000-0000-0000-000000000106',
        'a5170000-0000-0000-0000-000000000006', 'PENDING_SIGN');
