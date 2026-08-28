# 09. Безопасность и i18n

**Зависит от:** 02, 06

## Цель

Ограничить доступ к AI-чату отдельной ролью, обеспечить видимость только своих чатов и добавить
все message keys для UI/entities/enums.

## Resource role

`ru.fgk.ws.app.security.ai.AiChatUserRole`.

Решение v1: не добавлять AI-доступ в `WsUser`. Назначение `AiChatUserRole` пользователям является
отдельным rollout-действием.

Policies:

- `@MenuPolicy(menuIds = "ai")`;
- `@ViewPolicy(viewIds = "ai_AiChat.view")`;
- CRUD + attribute MODIFY на:
  - `AiChatConversation`;
  - `AiChatMessage`;
  - `AiChatAttachment`;
- READ + attribute VIEW на все 6 Diadoc entity:
  - `DiadocPacket`;
  - `DiadocPacketDoc`;
  - `DiadocPacketDocLink`;
  - `DiadocPacketDocOperation`;
  - `PacketFlow`;
  - `PacketDocumentFlow`.

Не полагаться на `DiadocShowPacketDocumentsRole`: она не покрывает весь whitelist AI tool.

## Row-level role

`ru.fgk.ws.app.security.ai.AiChatRowLevelRole`.

Policies:

- `AiChatConversation`: `{E}.createdBy = :current_user_username`;
- `AiChatMessage`: через owner conversation, например `{E}.conversation.createdBy = :current_user_username`;
- `AiChatAttachment`: через message/conversation owner.

Row-level роль должна ограничивать как UI список, так и service/DataManager доступ.

## Programmatic safety

Diadoc JPQL tool дополнительно применяет `AccessManager` / `LoadValuesAccessContext` из задачи `04`.
Это не заменяет roles, а является вторым safety layer перед выполнением generated JPQL.

## i18n

Файл: `app/src/main/resources/ru/fgk/ws/app/messages_ru.properties`.

Добавить keys:

- menu: `ru.fgk.ws.app.ai/menu.ai.title=ИИ`;
- view title: `ru.fgk.ws.app.ai.view.chat/aiChatView.title=Чат с ИИ`;
- buttons/actions: новый чат, отправить, переименовать, удалить вложение, повторить;
- states/errors: AI не настроен, ошибка ответа, ошибка файла, превышен лимит, думает;
- entity/attribute names из `02`;
- enum values `AiChatMessageType`.

В Java использовать `Messages`/`MessageBundle`; в XML использовать `msg://`. Не добавлять
visible hardcoded strings.

## Критерии готовности

- [ ] AI доступен только пользователям с `AiChatUserRole`.
- [ ] Role содержит policies для `ai` menu и `ai_AiChat.view`.
- [ ] Role содержит READ/VIEW на все 6 Diadoc whitelist entities.
- [ ] Row-level скрывает чужие conversations, messages и attachments.
- [ ] Все visible UI strings локализованы в `messages_ru.properties`.
