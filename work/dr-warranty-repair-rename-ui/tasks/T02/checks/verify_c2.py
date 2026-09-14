#!/usr/bin/env python3
"""C2: каждое поле VWarrantyRepairClaim <-> колонка view того же типа, лишних колонок нет."""
import re, subprocess, sys

ENTITY = "app/src/main/java/ru/fgk/ws/app/legal/warrantyrepair/entity/VWarrantyRepairClaim.java"
VIEW = "dr_v_warranty_repair_claim"

EXPECTED = {  # java-тип -> допустимые типы PostgreSQL
    "Long": {"bigint"},
    "Integer": {"smallint", "integer", "numeric"},
    "BigDecimal": {"numeric"},
    "String": {"character varying", "text"},
    "Boolean": {"boolean"},
    "UUID": {"uuid"},
    "LocalDate": {"date"},
    "LocalDateTime": {"timestamp without time zone"},
}

src = open(ENTITY, encoding="utf-8").read()
fields = {
    col: jtype
    for col, jtype in re.findall(
        r'@Column\(name = "(\w+)"[^)]*\)\s*(?:@Id\s*)?private (\w+) \w+;', src)
}

rows = subprocess.run(
    ["docker", "exec", "-e", "PGPASSWORD=root", "docker-rvk-db-1", "psql", "-U", "root",
     "-d", "postgres", "-At", "-F", "|", "-c",
     f"select column_name, data_type from information_schema.columns "
     f"where table_schema='main' and table_name='{VIEW}' order by ordinal_position;"],
    capture_output=True, text=True, check=True).stdout.strip().split("\n")
view = dict(r.split("|") for r in rows)

errors = []
for col in view:
    if col not in fields:
        errors.append(f"колонка view без поля entity: {col}")
for col, jtype in fields.items():
    if col not in view:
        errors.append(f"поле entity без колонки view: {col}")
    elif view[col] not in EXPECTED[jtype]:
        errors.append(f"{col}: entity {jtype} <-> view {view[col]}")

print(f"полей entity: {len(fields)}, колонок view: {len(view)}")
if errors:
    print("C2: ОШИБКИ")
    print("\n".join("  - " + e for e in errors))
    sys.exit(1)
print("C2: OK")
