# 02. Модель данных чата

**Зависит от:** 01
**Блокирует:** 03, 06, 08, 09

## Цель

Создать Jmix entities для хранения чатов, сообщений и вложений, Liquibase changelog-и и базовые
entity/enum i18n keys.

## Общие правила

- Пакет: `ru.fgk.ws.app.ai.entity`.
- Для обычных таблиц использовать `Long id` + `@GeneratedValue(strategy = GenerationType.IDENTITY)`.
- Каждая entity: `@JmixEntity`, `@Entity(name = "ai_...")`, `@Table`.
- Для редактируемых entities добавить `@Version Integer version`.
- Из Lombok использовать только `@Getter`/`@Setter`.
- Collections и composition children не инициализировать `ArrayList`; использовать
  `NotInstantiatedList`.

## AiChatConversation

Таблица `ai_chat_conversation`, entity name `ai_AiChatConversation`.

| Поле | Тип | Примечание |
|------|-----|------------|
| `id` | `Long` | `@Id`, `IDENTITY` |
| `version` | `Integer` | `@Version` |
| `title` | `String` | `@InstanceName`, default title из messages |
| `titleGenerated` | `Boolean` | `false` для нового чата |
| `lastMessageDate` | `OffsetDateTime` | сортировка списка чатов |
| `messages` | `List<AiChatMessage>` | `@OneToMany(mappedBy="conversation")`, `@Composition`, `@OrderBy("createdDate ASC")`, `NotInstantiatedList` |
| `createdBy` | `String` | `@CreatedBy`, owner для row-level |
| `createdDate` | `OffsetDateTime` | `@CreatedDate` |
| `lastModifiedBy` | `String` | `@LastModifiedBy` |
| `lastModifiedDate` | `OffsetDateTime` | `@LastModifiedDate` |
| `deletedBy` | `String` | `@DeletedBy` |
| `deletedDate` | `OffsetDateTime` | `@DeletedDate` |

Индексы: `created_by`, `last_message_date`, `created_date`.

## AiChatMessage

Таблица `ai_chat_message`, entity name `ai_AiChatMessage`.

| Поле | Тип | Примечание |
|------|-----|------------|
| `id` | `Long` | `@Id`, `IDENTITY` |
| `version` | `Integer` | `@Version` |
| `conversation` | `AiChatConversation` | `@ManyToOne(fetch = LAZY, optional = false)`, `@JoinColumn(name="conversation_id")`, `@OnDeleteInverse(DeletePolicy.CASCADE)` |
| `type` | `String` | enum id `AiChatMessageType` |
| `content` | `String` | `@Lob`, CLOB |
| `attachments` | `List<AiChatAttachment>` | `@OneToMany(mappedBy="message")`, `@Composition`, `NotInstantiatedList` |
| `createdDate` | `OffsetDateTime` | `@CreatedDate` |

Индексы: `conversation_id`, `(conversation_id, created_date)`, `type`.

## AiChatAttachment

Таблица `ai_chat_attachment`, entity name `ai_AiChatAttachment`.

| Поле | Тип | Примечание |
|------|-----|------------|
| `id` | `Long` | `@Id`, `IDENTITY` |
| `message` | `AiChatMessage` | `@ManyToOne(fetch = LAZY, optional = false)`, `@JoinColumn(name="message_id")`, `@OnDeleteInverse(DeletePolicy.CASCADE)` |
| `file` | `FileRef` | ссылка на файл в default Jmix `FileStorage`, без привязки к localfs |
| `fileName` | `String` | исходное имя |
| `contentType` | `String` | MIME/type |
| `fileSize` | `Long` | размер файла для лимитов и UI |
| `extractedText` | `String` | `@Lob`, CLOB, может быть null |
| `createdDate` | `OffsetDateTime` | `@CreatedDate` |

Индекс: `message_id`.

## AiChatMessageType

Enum в `ru.fgk.ws.app.ai.entity`, реализует `EnumClass<String>`:

```java
USER("USER"), ASSISTANT("ASSISTANT"), SYSTEM("SYSTEM"), TOOL("TOOL")
```

В `AiChatMessage` хранить `String type`; getter/setter `getMessageType()` /
`setMessageType()` выполняют конвертацию через `fromId()`.

## Liquibase

Файлы в `app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/01-tbl/`:

- `tbl-ai_chat_conversation.xml`
- `tbl-ai_chat_message.xml`
- `tbl-ai_chat_attachment.xml`

Требования:

- `objectQuotingStrategy="QUOTE_ONLY_RESERVED_WORDS"` в каждом changelog.
- `createTable` changeSet с `runOnChange="true"` и `preConditions onFail="MARK_RAN"`.
- `BIGINT` id с `autoIncrement="true"` и `startWith="1"`.
- `VERSION` как `INT`.
- `OffsetDateTime` как `${offsetDateTime.type}`.
- Большой текст как `CLOB`.
- Все таблицы и колонки с `remarks`.
- Индексы отдельными changeSet-ами с `indexExists` preCondition.
- Не использовать `<addForeignKeyConstraint>`.

## i18n

Добавить в `messages_ru.properties`:

- entity names и attributes для трех entities;
- enum name и все enum values;
- default title, например `ru.fgk.ws.app.ai.entity/AiChatConversation.defaultTitle=Новый чат`.

## Критерии готовности

- [ ] Entities компилируются и доступны в Jmix metadata.
- [ ] Composition lifecycle описан на Java-уровне; foreign keys в БД не создаются.
- [ ] Liquibase повторно применим и содержит актуальную структуру таблиц.
- [ ] Базовые entity/enum i18n keys добавлены.
