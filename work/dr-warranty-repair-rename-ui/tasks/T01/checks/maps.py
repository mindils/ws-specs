#!/usr/bin/env python3
"""T01: переименование таблиц/колонок гарантийных ремонтов."""
import re, sys, os

ROOT = '/home/mindils/data/dev/fgk/rvk-ws'
CL = os.path.join(ROOT, 'app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/01-tbl')
ENT = os.path.join(ROOT, 'app/src/main/java/ru/fgk/ws/app/legal/warrantyrepair/entity')
MSG = os.path.join(ROOT, 'app/src/main/resources/ru/fgk/ws/app/messages_ru.properties')

# (snake_old, snake_new, camel_old, camel_new)
T1 = [
    ('operation_type', 'category_oper', 'operationType', 'categoryOper'),
    ('acquisition_date', 'own_start', 'acquisitionDate', 'ownStart'),
    ('vrp_code', 'depo_code', 'vrpCode', 'depoCode'),
    ('vrp_name', 'depo_name', 'vrpName', 'depoName'),
    ('vrk', 'vrk_code', 'vrk', 'vrkCode'),
    ('damage_code_1', 'defect_code_1', 'damageCode1', 'defectCode1'),
    ('damage_code_2', 'defect_code_2', 'damageCode2', 'defectCode2'),
    ('damage_code_3', 'defect_code_3', 'damageCode3', 'defectCode3'),
    ('damage_code_tn', 'defect_code_tn', 'damageCodeTn', 'defectCodeTn'),
    ('damage_name', 'defect_name', 'damageName', 'defectName'),
    ('damage_note', 'defect_note', 'damageNote', 'defectNote'),
    ('repair_accept_date', 'repair_arrival_date', 'repairAcceptDate', 'repairArrivalDate'),
    ('inventory_date', 'insert_vagtk_date', 'inventoryDate', 'insertVagtkDate'),
    ('repair_depo_per_act', 'depo_act_code', 'repairDepoPerAct', 'depoActCode'),
    ('next_repair_date', 'last_repair_date', 'nextRepairDate', 'lastRepairDate'),
    ('next_repair_type', 'last_repair_type', 'nextRepairType', 'lastRepairType'),
    ('next_repair_vrp', 'last_repair_depo', 'nextRepairVrp', 'lastRepairDepo'),
    ('next_repair_vrp_name', 'last_repair_depo_name', 'nextRepairVrpName', 'lastRepairDepoName'),
    ('next_repair_vrk', 'last_repair_vrk', 'nextRepairVrk', 'lastRepairVrk'),
    ('plan_repair_contract_num', 'last_repair_contract_num', 'planRepairContractNum', 'lastRepairContractNum'),
    ('plan_repair_contract_date', 'last_repair_contract_date', 'planRepairContractDate', 'lastRepairContractDate'),
    ('last_tr_damage_code', 'last_tr_defect_code', 'lastTrDamageCode', 'lastTrDefectCode'),
]

T2 = [
    ('at_fault_is_vrp', 'warranty_is_vrp', 'atFaultIsVrp', 'warrantyIsVrp'),
    ('at_fault_vrp_code', 'warranty_depo_code', 'atFaultVrpCode', 'warrantyDepoCode'),
    ('at_fault_railway_code', 'warranty_railway_code', 'atFaultRailwayCode', 'warrantyRailwayCode'),
    ('at_fault_type', 'warranty_type', 'atFaultType', 'warrantyType'),
    ('at_fault_name', 'warranty_name', 'atFaultName', 'warrantyName'),
    ('at_fault_note', 'warranty_note', 'atFaultNote', 'warrantyNote'),
    ('dislocation_in_waybill_num', 'invoice_for_repair_num', 'dislocationInWaybillNum', 'invoiceForRepairNum'),
    ('dislocation_in_debit_date', 'invoice_for_repair_date_debit', 'dislocationInDebitDate', 'invoiceForRepairDateDebit'),
    ('dislocation_in_amount', 'invoice_for_repair_cost', 'dislocationInAmount', 'invoiceForRepairCost'),
    ('dislocation_out_waybill_num', 'invoice_after_repair_num', 'dislocationOutWaybillNum', 'invoiceAfterRepairNum'),
    ('dislocation_out_debit_date', 'invoice_after_repair_date_debit', 'dislocationOutDebitDate', 'invoiceAfterRepairDateDebit'),
    ('dislocation_out_amount', 'invoice_after_repair_cost', 'dislocationOutAmount', 'invoiceAfterRepairCost'),
    ('broken_tariff_waybill_num', 'broken_tariff_invoice_num', 'brokenTariffWaybillNum', 'brokenTariffInvoiceNum'),
    ('broken_tariff_amount', 'broken_tariff_cost', 'brokenTariffAmount', 'brokenTariffCost'),
    ('reimbursable_repair_cost', 'warranty_repair_cost', 'reimbursableRepairCost', 'warrantyRepairCost'),
    ('rebill_calc_amount', 'calculated_invoice_cost', 'rebillCalcAmount', 'calculatedInvoiceCost'),
    ('pre_claim_amount', 'pre_claim_cost', 'preClaimAmount', 'preClaimCost'),
]

T3 = [
    ('claim_amount', 'claim_cost', 'claimAmount', 'claimCost'),
    ('lawsuit_amount', 'lawsuit_cost', 'lawsuitAmount', 'lawsuitCost'),
    ('lawsuit_accept_amount', 'lawsuit_accept_cost', 'lawsuitAcceptAmount', 'lawsuitAcceptCost'),
    ('at_fault_accepted_amount', 'at_fault_accepted_cost', 'atFaultAcceptedAmount', 'atFaultAcceptedCost'),
    ('payment_amount', 'payment_cost', 'paymentAmount', 'paymentCost'),
]

T4 = []

