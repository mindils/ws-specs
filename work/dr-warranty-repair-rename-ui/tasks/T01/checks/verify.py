#!/usr/bin/env python3
"""Проверка критериев C1, C2, C4, C6 таска T01."""
import re, os, sys, subprocess, glob
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from maps import T1, T2, T3, T4, ROOT, CL, ENT, MSG

TABLES = [
    ('320-dr_warranty_repair.xml', 'LegalWarrantyRepair.java', 'LegalWarrantyRepair', 'dr_warranty_repair', T1),
    ('321-dr_warranty_repair_deps.xml', 'LegalWarrantyRepairDeps.java', 'LegalWarrantyRepairDeps', 'dr_warranty_repair_deps', T2),
    ('322-dr_warranty_repair_du.xml', 'LegalWarrantyRepairDu.java', 'LegalWarrantyRepairDu', 'dr_warranty_repair_du', T3),
    ('323-dr_warranty_repair_case_one.xml', 'LegalWarrantyRepairCaseOne.java', 'LegalWarrantyRepairCaseOne', 'dr_warranty_repair_case_one', T4),
]
KEY = 'ru.fgk.ws.app.legal.warrantyrepair.entity/'
fail = []

def tok(text, name):
    return re.search(r'(?<![0-9A-Za-z_])' + re.escape(name) + r'(?![0-9A-Za-z_])', text)

src = subprocess.run(['grep','-rniI','-e','legal_warranty_repair','app/src'],
                     cwd=ROOT, capture_output=True, text=True).stdout
print('C1 legal_warranty_repair в app/src:', 'НЕТ ВХОЖДЕНИЙ' if not src.strip() else 'НАЙДЕНО:\n'+src)
if src.strip():
    fail.append('C1')

# C2: старых имён нет во всём app/src; новые есть в changelog+entity+i18n
# Область поиска старых имён — артефакты гарантийных ремонтов: четыре changelog-а,
# пакет warrantyrepair и блок ключей ...warrantyrepair... в messages_ru.properties.
# Те же имена (damage_name, next_repair_date, vrk, ...) законно живут в других
# фичах (da, wagons, repair, asuvrk, dr) и к этому таску отношения не имеют.
scope_files = sorted(glob.glob(os.path.join(CL, '32?-dr_warranty_repair*.xml')))
for dp, dn, fn in os.walk(os.path.join(ROOT, 'app/src/main/java/ru/fgk/ws/app/legal/warrantyrepair')):
    scope_files += [os.path.join(dp, f) for f in fn]
all_src = ''
for f in scope_files:
    all_src += open(f, encoding='utf-8').read()
all_src += '\n'.join(l for l in open(MSG, encoding='utf-8') if 'warrantyrepair' in l)
print('Область проверки старых имён:', len(scope_files) + 1, 'файлов')

msg = open(MSG, encoding='utf-8').read()
c2_bad = []
for xml, java, cls, table, rmap in TABLES:
    x = open(os.path.join(CL, xml), encoding='utf-8').read()
    j = open(os.path.join(ENT, java), encoding='utf-8').read()
    for so, sn, co, cn in rmap:
        if so != 'vrk' and tok(all_src, so):
            c2_bad.append(f'{cls}: старое имя колонки {so} ещё встречается в app/src')
        if tok(all_src, co):
            c2_bad.append(f'{cls}: старое имя поля {co} ещё встречается в app/src')
        if not tok(x, sn):
            c2_bad.append(f'{cls}: нового имени {sn} нет в {xml}')
        if not tok(j, sn):
            c2_bad.append(f'{cls}: нового имени колонки {sn} нет в {java}')
        if not tok(j, cn):
            c2_bad.append(f'{cls}: нового поля {cn} нет в {java}')
        if f'{KEY}{cls}.{cn}=' not in msg:
            c2_bad.append(f'{cls}: нет i18n-ключа {KEY}{cls}.{cn}')
print('\nC2:', 'OK' if not c2_bad else 'ПРОБЛЕМЫ:\n  ' + '\n  '.join(c2_bad))
if c2_bad:
    fail.append('C2')

# C4: сверка entity <-> changelog
import xml.etree.ElementTree as ET
NS = '{http://www.liquibase.org/xml/ns/dbchangelog}'
c4_bad = []
total = 0
for xml, java, cls, table, rmap in TABLES:
    t = ET.parse(os.path.join(CL, xml))
    ct = [e for e in t.getroot().iter(NS + 'createTable') if e.get('tableName') == table]
    assert len(ct) == 1, xml
    xcols = [c.get('name') for c in ct[0].findall(NS + 'column')]
    total += len(xcols)
    j = open(os.path.join(ENT, java), encoding='utf-8').read()
    jcols = re.findall(r'@(?:Column|JoinColumn)\(\s*name = "([a-z_0-9]+)"', j)
    if sorted(xcols) != sorted(jcols):
        c4_bad.append(f'{table}: только в changelog {sorted(set(xcols)-set(jcols))}; '
                      f'только в entity {sorted(set(jcols)-set(xcols))}')
    print(f'  {table}: changelog {len(xcols)} колонок, entity {len(jcols)} @Column/@JoinColumn')
print('C4 сверка имён entity<->changelog:', 'OK' if not c4_bad else 'ПРОБЛЕМЫ:\n  ' + '\n  '.join(c4_bad))
print('Всего колонок в четырёх createTable:', total)
if c4_bad:
    fail.append('C4')

# C6: осиротевшие i18n-ключи и поля без ключа
c6_bad = []
keys = set(re.findall(r'^(' + re.escape(KEY) + r'[A-Za-z0-9_.]+)=', msg, re.M))
for xml, java, cls, table, rmap in TABLES:
    j = open(os.path.join(ENT, java), encoding='utf-8').read()
    fields = re.findall(r'^  private [\w<>, .]+ (\w+);', j, re.M)
    for f in fields:
        k = f'{KEY}{cls}.{f}'
        if k not in keys:
            c6_bad.append(f'нет ключа для поля {cls}.{f}')
    for k in sorted(keys):
        if k.startswith(f'{KEY}{cls}.'):
            attr = k[len(KEY) + len(cls) + 1:]
            if attr not in fields:
                c6_bad.append(f'осиротевший ключ {k}')
print('\nC6:', 'OK' if not c6_bad else 'ПРОБЛЕМЫ:\n  ' + '\n  '.join(c6_bad))
if c6_bad:
    fail.append('C6')

print('\nИТОГ:', 'все статические критерии OK' if not fail else 'провалены: ' + ', '.join(fail))
