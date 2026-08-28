# 04. Инструменты доступа к данным Diadoc

**Зависит от:** 03
**Блокирует:** 05

## Цель

Дать AI безопасный read-only доступ к ограниченному набору Diadoc entities через Whitelist JPQL
tool, чтобы отвечать на вопросы о подписании и статусах документов.

## DiadocSchemaTool

Пакет `ru.fgk.ws.app.ai.tool`.

`@Tool`-метод возвращает описание ровно 6 разрешенных JPQL entity:

| JPQL-имя | Назначение | Ключевые поля |
|----------|------------|---------------|
| `diadoc_DiadocPacket` | заголовок пакета | `id`, `status`, `documentType`, `inn`, `kpp`, `contractorCode`, `mainSignatureType`, `mainSignatureAt` |
| `diadoc_DiadocPacketDoc` | документ пакета | `entityId`, `messageId`, `signatureStatus`, `signatureTimestamp`, `documentType`, `documentNumber`, `documentDate` |
| `diadoc_DiadocPacketDocLink` | связь пакет-документ | `messageId`, `entityId`, `document`, `mainDocument`, `relatedDocument`, `dataSource` |
| `diadoc_DiadocPacketDocOperation` | операции документа | `entityId`, `document`, `entityTypeId`, `lastOperDate` |
| `PacketFlow` | workflow пакета | `id`, `status`, `prevStatus`, `signingType`, `signedBy`, `signedDate`, `approvedBy`, `approvedDate`, `rejectionReason` |
| `PacketDocumentFlow` | workflow документа | `id`, `messageId`, `entityId`, `status`, `documentType`, `orderNumber`, `rejectionReason` |

Schema text должен явно объяснять:

- использовать JPQL entity names, не table names;
- использовать Java attribute names, не DB column names;
- `DiadocPacket.id` соответствует `message_id`;
- `DiadocPacketDoc.entityId` соответствует document entity id;
- связь пакет-документ строится через `DiadocPacketDocLink.messageId/entityId/document`;
- `signatureStatus`: `8002` подписан, `8015` отклонен, `3333` аннулирован.

## DiadocJpqlQueryTool

Целевой контракт:

```java
QueryExecutionResult executeJpql(String jpqlQuery,
                                 JpqlParameters parameters,
                                 List<String> selectAliases,
                                 Integer offset,
                                 Integer limit,
                                 ToolContext toolContext)
```

`QueryExecutionResult` должен содержать:

- `success`;
- `rows` как list/map по aliases;
- `rowCount`;
- `hasMore`;
- `offset`;
- `limit`;
- `errorMessage`.

## Валидация

До выполнения запроса обязательно отклонять:

- `UPDATE`, `DELETE`, `INSERT`, `MERGE`, `DROP`, `ALTER`, `CREATE`, `TRUNCATE`, `CALL`;
- `SELECT *`;
- запросы без `AS` aliases для всех selected expressions;
- пустой или несовпадающий `selectAliases`;
- aliases из reserved words (`user`, `order`, `group`, `select`, `where`, `count`, `date`, `position` и т.п.);
- любые entity вне whitelist;
- joins к entity вне whitelist;
- limit больше `ai.chat.jpql.max-rows`.

Validator не должен быть только regex. Использовать Jmix/EclipseLink capabilities там, где это
практично: `QueryTransformerFactory`, metadata, `LoadValuesAccessContext`.

## Выполнение и security

- Выполнять только через security-aware `DataManager.loadValues(...)`.
- Перед выполнением применить `AccessManager` / `LoadValuesAccessContext`; если access denied,
  вернуть tool error, а не обходить через `UnconstrainedDataManager`.
- Передавать только named parameters, referenced в JPQL; лишние параметры игнорировать или
  отклонять предсказуемо.
- Использовать `offset` и `limit + 1`, чтобы вернуть `hasMore`.
- Tool может вернуть технические ids модели, но system prompt запрещает показывать их пользователю,
  если они не нужны для ответа.

## Статусы UI

`AiToolStatusPublisher` берет callback из `ToolContext`:

- `update(toolContext, "Выполняю запрос к данным Diadoc...")`;
- `complete(toolContext, "Запрос к данным Diadoc", "найдено N строк")`;
- при ошибке complete со snippet ошибки.

## Fallback

Если endpoint не поддерживает tool-calling:

- `ai.chat.tools.enabled=false` отключает tools без изменения UI;
- assistant отвечает, что прямой доступ к Diadoc-данным сейчас недоступен;
- non-streaming tool execution допустим как временная деградация, если это подтверждено spike-ом.

## Критерии готовности

- [ ] Schema tool описывает все 6 entity и статусы.
- [ ] JPQL tool требует aliases и `selectAliases`.
- [ ] Validator отклоняет write/DDL, `SELECT *`, unknown entities, missing/reserved aliases.
- [ ] `AccessManager` / `LoadValuesAccessContext` применяется до `DataManager.loadValues`.
- [ ] Limit, offset и `hasMore` работают.
- [ ] Tool status updates попадают в thinking row.
- [ ] Все critical cases покрыты unit-тестами из `10`.
