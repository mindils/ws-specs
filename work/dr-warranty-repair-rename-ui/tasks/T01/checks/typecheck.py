#!/usr/bin/env python3
"""C4: сверка типов колонок БД (созданных changelog-ом) с типами полей entity."""
import re, os
ENT = '/home/mindils/data/dev/fgk/rvk-ws/app/src/main/java/ru/fgk/ws/app/legal/warrantyrepair/entity'
MAP = {
    'dr_warranty_repair': 'LegalWarrantyRepair.java',
    'dr_warranty_repair_deps': 'LegalWarrantyRepairDeps.java',
    'dr_warranty_repair_du': 'LegalWarrantyRepairDu.java',
    'dr_warranty_repair_case_one': 'LegalWarrantyRepairCaseOne.java',
}
# допустимые пары «тип PostgreSQL -> java-тип поля»
OK = {
    # ссылочные поля @JoinColumn объявлены типом entity, а не типом FK-колонки
    'uuid': {'UUID', 'LegalWarrantyRepair'},
    'numeric': {'Integer', 'BigDecimal', 'Long'},
    'timestamp without time zone': {'LocalDateTime'},
    'timestamp with time zone': {'OffsetDateTime'},
    'date': {'LocalDate'},
    'character varying': {'String'},
    'integer': {'Integer'},
    'smallint': {'Integer'},
    'bigint': {'Long', 'LegalWarrantyRepairDeps'},
    'boolean': {'Boolean'},
    'text': {'String'},
}
db = {}
for line in open('/tmp/claude-1000/-home-mindils-data-dev-fgk-rvk-ws/62aa5f43-0ff9-4ba1-83a8-b23298250856/scratchpad/dbcols.txt', encoding='utf-8'):
    t, c, dt, ln, pr, sc = line.rstrip('\n').split('|')
    db[(t, c)] = (dt, int(ln), int(pr), int(sc))

bad = []
seen = set()
for table, java in MAP.items():
    s = open(os.path.join(ENT, java), encoding='utf-8').read()
    # (аннотация @Column/@JoinColumn ... ) + следующее объявление поля
    for m in re.finditer(
            r'@(?:Column|JoinColumn)\(([^)]*)\)[^;]*?private\s+([\w<>]+)\s+(\w+);', s, re.S):
        attrs, jtype, jname = m.groups()
        cm = re.search(r'name = "([a-z_0-9]+)"', attrs)
        if not cm:
            continue
        col = cm.group(1)
        key = (table, col)
        seen.add(key)
        if key not in db:
            bad.append(f'{table}.{col}: нет в БД (поле {jname})')
            continue
        dt, ln, pr, sc = db[key]
        allowed = OK.get(dt)
        if allowed is None:
            bad.append(f'{table}.{col}: неизвестный тип БД {dt}')
        elif jtype not in allowed:
            bad.append(f'{table}.{col}: БД {dt} vs java {jtype} ({jname})')
        lm = re.search(r'length = (\d+)', attrs)
        if dt == 'character varying':
            want = int(lm.group(1)) if lm else 255
            if ln != want:
                bad.append(f'{table}.{col}: длина БД {ln} vs entity {want}')
        pm = re.search(r'precision = (\d+), scale = (\d+)', attrs)
        if pm and dt == 'numeric':
            if (pr, sc) != (int(pm.group(1)), int(pm.group(2))):
                bad.append(f'{table}.{col}: precision/scale БД {pr},{sc} vs entity {pm.groups()}')

missing = sorted(set(db) - seen)
print('Сверено колонок:', len(seen), 'из', len(db))
if missing:
    print('Нет соответствия в entity:', missing)
print('C4 типы:', 'OK' if not bad and not missing else 'ПРОБЛЕМЫ:\n  ' + '\n  '.join(bad))
