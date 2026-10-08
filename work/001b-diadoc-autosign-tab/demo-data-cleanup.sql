-- Удаляет синтетические пакеты из demo-data.sql (локальная БД).
set search_path = main;

delete from diadoc_packet_document_flow where message_id::text like 'a5170000-%';
delete from diadoc_packet_flow where message_id::text like 'a5170000-%';
delete from packet_check where message_id::text like 'a5170000-%';
delete from diadoc_packet_doc_link where message_id::text like 'a5170000-%';
delete from diadoc_packet_doc where message_id::text like 'a5170000-%';
delete from diadoc_packet where message_id::text like 'a5170000-%';
delete from nsi_nv_processing_settings
 where code in ('Diadoc.AutoApproval.VU23', 'Diadoc.AutoApproval.MX1');
