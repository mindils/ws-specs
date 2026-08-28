# 00. Обзор: модуль «ИИ-чат» в rvk-ws

## Цель

Добавить в `rvk-ws` отдельный модуль ИИ-ассистента с чат-интерфейсом:

- отдельный пункт меню «ИИ»;
- список чатов текущего пользователя и создание нового чата;
- потоковая печать ответа, markdown-ответы и строка «думает» со статусами инструментов;
- автоматическое название чата после первого сообщения и ручное переименование;
- вложения `txt/md/csv/pdf` с извлечением текста;
- ответы на вопросы по Diadoc-данным вида «что подписано, а что нет» через безопасный read-only JPQL tool.

Реализация выполняется внутри модуля `app` как feature-пакет `ru.fgk.ws.app.ai`.
Отдельный Gradle-модуль или addon для v1 не создается.

## Технический стек

| Компонент | Версия / факт |
|-----------|---------------|
| Jmix | 2.7.1 |
| Spring Boot | 3.5.6 |
| Spring Framework | 6.2.11 |
| Vaadin | 24.9.2 |
| ORM | EclipseLink |
| БД | PostgreSQL |
| LLM-библиотека | Spring AI 1.1.3, `spring-ai-starter-model-openai` |
| Push/async | `@Push` и `@EnableAsync` уже включены в `AppApplication` |

## Архитектурные решения

1. **Пакет в `app`, не addon.** Chat UI и Diadoc tools используют сущности `app`, поэтому addon
   был бы избыточным и не видел бы нужные domain classes без рефакторинга.
2. **AI optional.** Базовое приложение должно стартовать без `AI_BASE_URL`, `AI_API_KEY` и
   `AI_MODEL`. При неполной настройке чат показывает disabled/error state, но не ломает старт.
3. **OpenAI-compatible provider.** Один код работает с minimax в dev и Qwen в prod через смену
   `base-url`, `api-key`, `model`.
4. **Отдельный доступ.** AI-чат доступен только через `AiChatUserRole`; роль не добавляется в
   `WsUser` автоматически.
5. **Whitelist JPQL tool.** Для Diadoc v1 используется универсальный read-only JPQL tool, но с
   жестким whitelist-ом entity, обязательными aliases, параметрами, security checks и тестами.
6. **Гибридный UI.** Поток токенов `Flux<String>` обновляет UI через `ui.access()`, а tool status
   updates отображаются отдельной thinking row.

## Целевая структура

```text
app/src/main/java/ru/fgk/ws/app/ai/
├── config/        AiConfig, AiChatProperties
├── entity/        AiChatConversation, AiChatMessage, AiChatAttachment, AiChatMessageType
├── repository/    AiChatConversationRepository
├── service/       AiAssistantService, AiChatMessageService, AiConversationTitleService,
│                  AttachmentTextExtractor
├── tool/          DiadocSchemaTool, DiadocJpqlQueryTool, AiToolStatusPublisher
└── view/
    ├── chat/      AiChatView (+ xml), composer fragment
    └── timeline/ TimelineItem, AiTimelineThinkingRow, AiTimelineMessageRow

app/src/main/resources/ru/fgk/ws/app/ai/
├── view/chat/     ai-chat-view.xml
└── prompts/       system-prompt.st

app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/01-tbl/
└── tbl-ai_chat_conversation.xml, tbl-ai_chat_message.xml, tbl-ai_chat_attachment.xml

app/src/main/java/ru/fgk/ws/app/security/ai/
└── AiChatUserRole.java, AiChatRowLevelRole.java
```

Единые UI identifiers:

- Java view: `AiChatView`
- route: `ai-chat`
- view id: `ai_AiChat.view`
- menu id: `ai`

## Граф задач

```text
01 ─┬─ 02 ─┬─ 03 ─┬─ 04 ─┐
    │      │      │      ├─ 05 ─┬─ 06 ─┬─ 07
    │      │      │      │      │      └─ 09
    │      │      │      │      └─ 08
    │      │      │      │
    └──────┴──────┴──────┴───────────────── 10
```

| № | Файл | Назначение |
|---|------|------------|
| 01 | `01-dependencies-and-config.md` | Spring AI dependencies, optional config, limits |
| 02 | `02-data-model.md` | Chat entities, Liquibase, entity i18n |
| 03 | `03-llm-service-and-memory.md` | Assistant service, history, prompt, message coordinator |
| 04 | `04-diadoc-tools.md` | Whitelist JPQL tool and schema tool |
| 05 | `05-streaming-ui-timeline.md` | Chat view, timeline, streaming, thinking row |
| 06 | `06-chat-list-and-menu.md` | Sidebar list, new chat, menu |
| 07 | `07-title-generation.md` | Auto title and manual rename |
| 08 | `08-file-attachments.md` | File upload and text extraction |
| 09 | `09-security-and-i18n.md` | Resource role, row-level role, full UI i18n |
| 10 | `10-testing-and-verification.md` | Tests, endpoint spike, manual checks |

**Минимальная цепочка рабочего чата без Diadoc tools:** `01 -> 02 -> 03 -> 05 -> 06`.
Diadoc tools можно подключать отдельным этапом после проверки tool-calling endpoint-ов.

## Diadoc entity whitelist

| JPQL-имя | Класс | Роль | Ключевые поля |
|----------|-------|------|---------------|
| `diadoc_DiadocPacket` | `DiadocPacket` | заголовок пакета | `status`, `documentType`, `inn`, `kpp`, `contractorCode`, `mainSignatureType`, `mainSignatureAt` |
| `diadoc_DiadocPacketDoc` | `DiadocPacketDoc` | документ пакета | `signatureStatus`, `signatureTimestamp`, `documentType`, `documentNumber`, `documentDate` |
| `diadoc_DiadocPacketDocLink` | `DiadocPacketDocLink` | связь пакет-документ | `messageId`, `entityId`, `document`, `mainDocument`, `relatedDocument`, `dataSource` |
| `diadoc_DiadocPacketDocOperation` | `DiadocPacketDocOperation` | операции документа | `entityId`, `document`, `entityTypeId`, `lastOperDate` |
| `PacketFlow` | `PacketFlow` | workflow пакета | `status`, `prevStatus`, `signingType`, `signedBy`, `signedDate`, `approvedBy`, `approvedDate`, `rejectionReason` |
| `PacketDocumentFlow` | `PacketDocumentFlow` | workflow документа | `status`, `documentType`, `orderNumber`, `rejectionReason`, `messageId`, `entityId` |

Статусы `DiadocPacketDoc.signatureStatus`: `8002` — подписан, `8015` — отклонен,
`3333` — аннулирован. Описание статусов дублируется в `DiadocSchemaTool` и system prompt.

## Риск-флаги

1. **Startup safety.** Нельзя добавлять обязательные `${AI_*}` placeholders в базовый
   `application.properties`, если они могут сломать старт без AI.
2. **Streaming + tool-calling.** До полноценной интеграции нужно проверить minimax dev endpoint и
   Qwen prod endpoint: поддерживают ли они function/tool calling в streaming mode.
3. **JPQL safety.** Regex-only validation недостаточна; tool должен проверять aliases, whitelist,
   security access и лимиты до выполнения запроса.
4. **Тестовое окружение.** Часть integration/UI тестов зависит от PostgreSQL/test profile, поэтому
   быстрые unit-тесты должны оставаться без сети и без Spring context.

## Правила реализации

- Constructor injection в services; бизнес-логика не во view.
- Новые Jmix entities: `@JmixEntity`, `@Entity`, `@Table`, `Long id + IDENTITY`, `@Version` там,
  где entity редактируется.
- UI-текст только через `msg://` keys.
- Liquibase: `objectQuotingStrategy`, `preConditions`, `remarks`, no foreign keys.
- Security: отдельная role для AI и row-level owner policy.
