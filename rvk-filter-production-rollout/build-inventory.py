#!/usr/bin/env python3
"""Rebuild the source inventory and page queues; writes only this specification directory."""
from pathlib import Path
from collections import Counter
import fnmatch
import json
import re
import xml.etree.ElementTree as ET

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[1]
FILTERS = {"propertyFilter", "jpqlFilter", "genericFilter"}
GRIDS = {"dataGrid", "treeDataGrid", "grid"}
CONTROLS = {"textField", "textArea", "datePicker", "dateTimePicker", "entityPicker",
            "entityComboBox", "entityMultiSelectComboBox", "comboBox", "multiSelectComboBox",
            "checkbox", "select", "integerField", "numberField", "listPicker"}
PILOT = ["nsi_NvPartType.list", "RejectReason.list", "nsi_VDepo.list"]
# User scope, 2026-09-07: never reactivate rollout to other views when regenerating.
ACTIVE_RVK_VIEWS = frozenset([*PILOT, "DiadocDocumentType.list"])
# Reviewed custom filtering paths, not a guess based on the name of an input field.
CUSTOM_EXISTING = {
    "UserActivityStats.list", "diadoc_DiadocVagTkImport.list", "NvProcessingSettings.list",
    "WnWagArchiveSpecsDto.list", "WnWagLastOper62Dto.list", "wn_VWagOperArchive",
    "wn_VWagEquipmentArchiveFind.list", "ReportWagOperRepairDto.list",
    "dr_ReportTR2PriceAnalyzeDtoListView.list", "dr_ReportOperRepairDocFlowDto.list",
    "UncouplingCountView", "pt_Pt1cStorageReport.list", "pt_PtPart.list",
    "ReportAllocationOperRepair.list", "rp_VRpOperDefect.list", "rp_VRpOperBalance.list",
}
SPECIAL_EXCLUSIONS = {
    "DocumentUpdateView": "Форма запуска обновления документов; входные идентификаторы являются командой, а не фильтром списка.",
    "diadoc_DiadocManualSync.view": "Форма запуска синхронизации; не менять параметры команды на фильтр результатов.",
    "diadoc_DiadocVagTkImportDocumentsCompare.list": "Сопоставление двух подготовленных наборов документов; отдельный фильтр может скрыть одну сторону сравнения.",
    "diadoc_DiadocVagTkImportResultDialog.list": "Результат разового импорта; в этом этапе не добавлять сохранённые пресеты.",
    "PtDetailPasteView": "Редактирование/проверка вставленного набора деталей перед командой; не скрывать строки операции.",
    "ScreenTablesView": "Служебный обзор экранов и прав; выбор пользователя/экрана задаёт контекст диагностики.",
    "da_VRepairAbdpvArchClaim.detail": "Карточка ремонта с дочерними данными, не самостоятельный список.",
    "pt_RepairClaim.detail": "Редактируемая composition претензии; фильтр не должен скрывать сохраняемые строки.",
    "nsi_NvReceiptCost.list": "Составной редактор периодов и цен с KeyValue pivot; в этом этапе оставить подбор периода и редактируемые строки.",
}


def local(element):
    return element.tag.split("}")[-1]


def compact(text):
    return " ".join((text or "").split())


def rel(path):
    return str(path.relative_to(ROOT))


def link(path, label=None):
    return f"[{label or Path(path).name}](../../{path})"


def clean_java(text):
    return re.sub(r"/\*.*?\*/", "", text, flags=re.S)


def annotation_strings(source, annotation, attribute):
    values = []
    for match in re.finditer(r"@" + annotation + r"\s*\((.*?)\)", source, re.S):
        arg = re.search(attribute + r"\s*=\s*(\{.*?\}|\"[^\"]*\")", match[1], re.S)
        if arg:
            values.extend(re.findall(r'"([^\"]*)"', arg[1]))
    return values


java = {}
controllers = {}
roles = {}
for module in ("app", "core", "sso-plagin"):
    for path in (ROOT / module).rglob("*.java"):
        if "/src/main/java/" not in str(path):
            continue
        raw = path.read_text()
        source = clean_java(raw)
        package = re.search(r"^package\s+([\w.]+);", source, re.M)
        declaration = re.search(r"public\s+(?:abstract\s+)?(?:class|interface|enum)\s+(\w+)([^\{]*)\{", source)
        if not package or not declaration:
            continue
        fqn = package[1] + "." + declaration[1]
        record = {"path": rel(path), "source": source, "raw": raw, "package": package[1],
                  "name": declaration[1], "declaration": declaration[0]}
        java[fqn] = record
        if "@ResourceRole(" in source:
            extends = re.search(r"extends\s+([\w\s,]+)", declaration[2])
            roles[declaration[1]] = {"path": rel(path),
                "views": annotation_strings(source, "ViewPolicy", "viewIds"),
                "parents": [] if not extends else re.findall(r"\w+", extends[1])}
        descriptor = re.search(r'@ViewDescriptor\(\s*(?:(?:path|value)\s*=\s*)?"([^\"]+)"', source)
        view = re.search(r'@ViewController\(\s*(?:id\s*=\s*)?"([^\"]+)"', source)
        if descriptor and view:
            key = descriptor[1].lstrip("/")
            if "/" not in key:
                key = package[1].replace(".", "/") + "/" + key
            controllers[key] = dict(record, view_id=view[1])


def role_views(name, visited=None):
    visited = set() if visited is None else visited
    if name in visited or name not in roles:
        return []
    visited.add(name)
    role = roles[name]
    return role["views"] + [v for p in role["parents"] for v in role_views(p, visited)]


messages = {}
for path in (ROOT / "app/src/main/resources").rglob("messages_ru.properties"):
    for line in path.read_text().splitlines():
        if line.strip() and not line.lstrip().startswith(("#", "!")) and "=" in line:
            key, value = line.split("=", 1)
            messages[key.strip()] = value.strip()


def caption(value, package):
    if not value.startswith("msg://"):
        return value
    key = value[6:].lstrip("/")
    return messages.get(key, messages.get(package + "/" + key, value))


def property_info(entity, property_path):
    """Resolve source fields conservatively; unresolved getters/inheritance remain explicit."""
    current = java.get(entity)
    parts = property_path.split(".")
    for index, part in enumerate(parts):
        if not current:
            return {"type": "unresolved", "association": None}
        field = re.search(r"(?:private|protected|public)\s+(?:final\s+)?([\w.]+)(?:<[^;=]+>)?\s+" + re.escape(part) + r"\s*[;=]", current["source"])
        if not field:
            return {"type": "unresolved", "association": None}
        typ = field[1]
        imp = re.search(r"import\s+([\w.]+\." + re.escape(typ) + r");", current["source"])
        fqn = imp[1] if imp else current["package"] + "." + typ
        target = java.get(fqn)
        if index == len(parts) - 1:
            return {"type": fqn if target else typ,
                    "association": bool(target and "@JmixEntity" in target["source"])}
        current = target
    return {"type": "unresolved", "association": None}


rows = []
descriptor_count = 0
parse_errors = []
for module in ("app", "core", "sso-plagin"):
    for path in sorted((ROOT / module).rglob("*.xml")):
        if "/src/main/resources/" not in str(path) or "/view/" not in str(path):
            continue
        try:
            root = ET.parse(path).getroot()
        except ET.ParseError as error:
            parse_errors.append({"path": rel(path), "error": str(error)})
            continue
        if local(root) not in ("view", "fragment"):
            continue
        descriptor_count += 1
        layout = next((x for x in root if local(x) in ("layout", "content")), None)
        if layout is None:
            continue
        elements = list(layout.iter())
        filters = [x for x in elements if local(x) in FILTERS]
        grids = [x for x in elements if local(x) in GRIDS]
        resource = str(path).split("/src/main/resources/", 1)[1]
        controller = controllers.get(resource)
        view_id = controller["view_id"] if controller else "fragment:" + resource
        # Include non-list views with command/report fields as explicit exclusions.
        input_fields = [x for x in elements if local(x) in CONTROLS and x.get("id") and not x.get("property")]
        if not filters and not grids and not input_fields:
            continue
        source = controller["source"] if controller else ""
        raw = controller["raw"] if controller else ""
        declarations = controller["declaration"] if controller else ""
        data = next((x for x in root if local(x) == "data"), None)
        loaders = []
        entities = {}
        if data is not None:
            for collection in data.iter():
                if local(collection) in ("collection", "keyValueCollection"):
                    entities[collection.get("id", "?")] = collection.get("class", "property-bound/KeyValue")
                    for loader in collection:
                        if local(loader) != "loader":
                            continue
                        query = next((x for x in loader if local(x) == "query"), None)
                        loaders.append({"id": loader.get("id", "?"), "container": collection.get("id", "?"),
                            "entity": collection.get("class", "property-bound/KeyValue"),
                            "query": compact(query.text if query is not None else ""),
                            "attributes": dict(loader.attrib)})
        loader_entities = {x["id"]: x["entity"] for x in loaders}
        field_specs = []
        for field in filters:
            attrs = dict(field.attrib)
            attrs["tag"] = local(field)
            attrs["condition"] = compact(" ".join(x.text or "" for x in field.iter() if local(x) in ("where", "join")))
            attrs["editor"] = [dict(x.attrib, tag=local(x)) for x in field if local(x) not in ("condition", "properties")]
            if field.get("property"):
                attrs["property_info"] = property_info(loader_entities.get(field.get("dataLoader"), ""), field.get("property"))
            if local(field) == "genericFilter":
                attrs["catalog"] = [dict(x.attrib) for x in field.iter() if local(x) == "properties"]
            field_specs.append(attrs)
        is_detail = "extends StandardDetailView" in declarations
        is_existing = bool(filters) or view_id in CUSTOM_EXISTING
        reason = SPECIAL_EXCLUSIONS.get(view_id)
        if not is_existing and not reason:
            if local(root) == "fragment":
                reason = "Переиспользуемый фрагмент без существующего фильтра; самостоятельного списка/ключа view нет."
            elif is_detail:
                reason = "Карточка с редактируемыми/связанными данными; не добавлять фильтр автоматически по наличию грида."
            elif not grids:
                reason = "Форма параметров/команды без собственного списка; параметры не являются фильтром таблицы."
        category = "excluded" if reason else "existing" if is_existing else "additional"
        delegate = bool(re.search(r"[Ll]oad(?:FromRepository)?Delegate|PreLoad|setLoadDelegate", source))
        dynamic = bool(re.search(r"setCondition\(|setQuery\(|AbstractParams\.createFromFields|setParameter\(", source))
        association = any(x.get("property_info", {}).get("association") for x in field_specs)
        unknown_type = any(x.get("property_info", {}).get("type") == "unresolved" for x in field_specs)
        generic = any(x["tag"] == "genericFilter" for x in field_specs)
        jpql = any(x["tag"] == "jpqlFilter" for x in field_specs)
        rest = any("@Store(" in java.get(e, {}).get("source", "") for e in entities.values())
        feature_path = resource.split("ru/fgk/ws/app/", 1)[-1]
        feature = feature_path.split("/", 1)[0]
        if feature == "view":
            package = controller["package"] if controller else ""
            feature = "legacy"
        dependencies = {"F02", "F04", "F05", "F06", "F07", "F08"}
        if view_id not in PILOT:
            dependencies.add("F03")
        flags = []
        for yes, text in [(generic, "genericFilter: каталог/операции/AND-OR"), (jpql, "JPQL: типы/joins"),
            (association, "ссылка на entity"), (unknown_type, "тип через metadata"),
            (delegate, "delegate/PreLoad"), (dynamic, "динамические параметры/условия"),
            (rest, "REST/custom Store"), (any(local(x) == "treeDataGrid" for x in grids), "дерево"),
            (view_id in CUSTOM_EXISTING, "нестандартные фильтры")]:
            if yes:
                flags.append(text)
        if category == "excluded":
            wave = None
        elif category == "additional":
            wave = 8
        elif view_id in PILOT:
            wave = 1
        elif view_id in CUSTOM_EXISTING and view_id != "NvProcessingSettings.list":
            wave = 8
        elif is_detail or not loaders or delegate or rest:
            wave = 7
        elif not (generic or jpql or association or unknown_type or dynamic):
            wave = 2
        elif feature in ("nsi", "asuvrk") or view_id in ("User.list", "DrContractCdiWorkGroup.list"):
            wave = 3
        elif feature in ("drcontract", "rs", "da") or view_id in ("DrContractCdi.list", "pt_RepairContract.list"):
            wave = 4
        elif feature in ("repair", "wagons") or view_id in ("wn_VWagEquipmentArchive.list", "PtUkvArchive.list"):
            wave = 5
        elif feature in ("dr", "dt"):
            wave = 6
        else:
            wave = 7
        evidence = [{"line": n, "text": line.strip()} for n, line in enumerate(raw.splitlines(), 1)
                    if re.search(r"set(?:Typed)?Value\(|setParameter\(|setCondition\(|setQuery\(|[Ll]oad(?:FromRepository)?Delegate|PreLoad|AbstractParams\.createFromFields|@Subscribe|@Install", line)]
        package = controller["package"] if controller else resource.rsplit("/", 1)[0].replace("/", ".")
        primary_grid = next((g for g in grids if any(l["container"] == g.get("dataContainer") for l in loaders)), grids[0] if grids else None)
        proposed_fields = []
        if primary_grid is not None:
            for column in primary_grid.iter():
                if local(column) == "column" and column.get("property"):
                    prop = column.get("property")
                    if prop not in [f["property"] for f in proposed_fields]:
                        proposed_fields.append({"property": prop, **property_info(entities.get(primary_grid.get("dataContainer"), ""), prop)})
        row = {"view_id": view_id, "title": caption(root.get("title", view_id), package),
            "xml": rel(path), "controller": controller["path"] if controller else None,
            "category": category, "wave": wave, "exclusion_reason": reason,
            "feature": feature, "filters": field_specs, "input_fields": [dict(x.attrib, tag=local(x)) for x in input_fields],
            "grids": [dict(x.attrib, tag=local(x)) for x in grids], "loaders": loaders,
            "entities": entities, "flags": flags, "dependencies": sorted(dependencies),
            "roles": [r["path"] for name, r in roles.items() if any(fnmatch.fnmatchcase(view_id, pat) for pat in role_views(name))],
            "java_evidence": evidence, "proposed_primary_grid": primary_grid.get("id") if primary_grid is not None else None,
            "proposed_fields": proposed_fields}
        rows.append(row)


def sort_key(row):
    return (row["wave"] or 99, PILOT.index(row["view_id"]) if row["view_id"] in PILOT else 99, row["view_id"])


rows.sort(key=sort_key)
for category, prefix in [("existing", "M"), ("additional", "N"), ("excluded", "X")]:
    for number, row in enumerate((r for r in rows if r["category"] == category), 1):
        row["task_id"] = f"{prefix}{number:03d}"

stats = {"descriptors_scanned": descriptor_count, "categories": dict(Counter(r["category"] for r in rows)),
    "standard_filter_views": sum(bool(r["filters"]) for r in rows),
    "filter_elements": dict(Counter(f["tag"] for r in rows for f in r["filters"]))}
(HERE / "page-inventory.json").write_text(json.dumps({"schema_version": 1, "snapshot_date": "2026-09-05",
    "scope": "app/core/sso-plagin main-source view and fragment descriptors", "statistics": stats,
    "parse_errors": parse_errors, "pages": rows}, ensure_ascii=False, indent=2) + "\n")

wave_titles = {1: "Пилот", 2: "Простые скалярные списки", 3: "Справочники со сложной фильтрацией",
    4: "Договоры, уведомления, претензии", 5: "Вагоны и архивы ремонтов", 6: "Документооборот, контроль, выгрузки DR/DT",
    7: "Пакеты, делегаты и специальные контексты", 8: "Нестандартный поиск, отчёты и дополнительные списки"}


def render_page(row):
    fs = []
    for f in row["filters"]:
        if f["tag"] == "genericFilter":
            fs.append("genericFilter `" + f.get("id", "без id") + "` — каталог " + compact(json.dumps(f.get("catalog", []), ensure_ascii=False)))
        else:
            value = f.get("property", f.get("id", "JPQL без id"))
            fs.append("`" + value + "` " + f.get("operation", "JPQL(" + f.get("parameterClass", "тип не задан") + ")"))
    inputs = ", ".join("`" + f["id"] + "`" for f in row["input_fields"])
    default_lines = [e for e in row["java_evidence"] if re.search(r"set(?:Typed)?Value\(|setParameter\(|setQuery\(|setCondition\(", e["text"])]
    roles_text = ", ".join(link(p) for p in row["roles"]) or "Прямая ViewPolicy в исходниках не найдена; проверить назначенные runtime-роли и путь открытия."
    target = ("- Целевой каталог: сохранить все перечисленные операции/поля, generic include/exclude и доменные фильтры; параметры представления не переносить." if row["category"] == "existing" else
        "- Целевой каталог для `" + str(row["proposed_primary_grid"]) + "`: " + (", ".join("`" + f["property"] + "`" for f in row["proposed_fields"]) or "колонки динамические; получить property paths из конфигурации грида в адаптере F04") + ". Только доступные для чтения и поддержанные источником поля; вычисляемые значения фильтрует явный provider. Дочерние гриды не подключать автоматически.")
    return "\n".join([
        f"### {row['task_id']}. {row['title']} — `{row['view_id']}`",
        "", ("- [ ] Проверить уже подключённую страницу; актуальные результаты — в журнале реализации."
               if row["view_id"] in ACTIVE_RVK_VIEWS else
               "- [ ] **Отложено в [backlog](13-pages-backlog.md)**; не выполнять в текущей задаче."),
        "- Источники: " + link(row["xml"], "XML") + ("; " + link(row["controller"], "контроллер") if row["controller"] else "") + ".",
        "- Загрузчики: " + ("; ".join("`" + l["id"] + "` → `" + l["entity"] + "`" for l in row["loaders"]) or "Нет query loader; требуется адаптер/контекст владельца.") + ".",
        "- Текущие фильтры: " + ("; ".join(fs) or "Стандартных property/jpql/genericFilter нет.") + ".",
        "- Прочие поля ввода для проверки: " + (inputs or "не обнаружены вне property binding") + ".",
        "- Особенности: " + ("; ".join(row["flags"]) or "обычный список; проверить начальные параметры и пагинацию") + ".",
        target,
        "- Зависимости: " + ", ".join(row["dependencies"]) + "; [общая приёмка страницы](11-acceptance.md#page).",
        "- Места изменения значений (кандидаты, включая renderers): " + (", ".join(link(row["controller"], "строка " + str(e["line"])) + " `" + e["text"].replace("`", "'") + "`" for e in default_lines[:6]) or "См. XML, lifecycle и контекст открытия; наличие значений из Java не установлено простым поиском.") + (" Остальные места перечислены в JSON." if len(default_lines) > 6 else ""),
        "- Роли (включая наследование исходных resource roles): " + roles_text,
        "- Сравнение: одинаковые ID, количество и порядок при каждой операции выше; проверить сброс/повторное открытие, пагинацию и экспорт. Сохранять ограничения родителя, выбранного пакета/периода/пользователя.",
        "- Старый режим: " + ("сохранить XML, actions, URL/settings bindings и Java-обработчики; включать только через переключатель из F08." if row["category"] == "existing" else "исходный список без нового фильтра; сохранять его базовые ограничения, отдельную пустую гармошку не создавать."),
        "",
    ])


def render_queue(category, filename, title):
    selected = [r for r in rows if r["category"] == category]
    lines = [f"# {title}", "", "[К плану](README.md) · [Полный реестр](page-inventory.json)", "",
        f"Карточек исходного аудита: **{len(selected)}**. Остальные страницы отложены в [backlog](13-pages-backlog.md).",
        "Текущий объём: только уже подключённые M001–M003 и N002. Порядок волн ниже — справочный, не указание продолжать внедрение.",
        "Статусы подключённых страниц сверять с журналом; остальные отложены. JSON хранит исходники, обработчики, условия, поля и ограничения загрузчика.",
        "", "**Порядок волны 8:** сначала оставшиеся задачи M из документа 09, затем задачи N из документа 10. Зависимости F02–F08 означают приёмку соответствующего пути, а не завершение всех необязательных возможностей аддона.",
        "", "Поля вне property binding перечислены как кандидаты для проверки, а не как разрешение переносить настройки отображения/параметры команд в фильтр.", ""]
    for wave in sorted({r["wave"] for r in selected}):
        lines += [f"## Волна {wave}. {wave_titles[wave]}", ""]
        lines += [render_page(r) for r in selected if r["wave"] == wave]
    if category == "additional":
        lines += ["## Исключения из автоматического добавления", "", "Каждый исключённый экран остаётся в реестре. Для редактируемых composition не добавлять query loader ради фильтра.", "", "| ID | Экран | Причина |", "|---|---|---|"]
        for row in rows:
            if row["category"] == "excluded":
                lines.append(f"| {row['task_id']} | {link(row['xml'], row['view_id'])} | {row['exclusion_reason']} |")
    (HERE / filename).write_text("\n".join(lines) + "\n")


render_queue("existing", "09-existing-pages.md", "F09. Перевод страниц с существующей фильтрацией")
render_queue("additional", "10-additional-pages.md", "F10. Добавление фильтра на остальные списки")
print(json.dumps(stats, ensure_ascii=False))
print("Unresolved controllers:", [r["xml"] for r in rows if not r["controller"] and not r["view_id"].startswith("fragment:")])
