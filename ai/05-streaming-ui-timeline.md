# 05. Чат-вью: таймлайн, стриминг и индикатор «думает»

**Зависит от:** 03, 04
**Блокирует:** 06, 08

## Цель

Сделать один основной экран AI-чата с боковым списком чатов, timeline, composer, потоковой печатью
ответа и thinking row для статусов tools.

## AiChatView

Пакет `ru.fgk.ws.app.ai.view.chat`.

Identifiers:

- class: `AiChatView`
- route: `ai-chat`
- view id: `ai_AiChat.view`
- descriptor: `ai-chat-view.xml`
- base class: `StandardView`

View layout:

- слева sidebar со списком чатов и кнопкой «Новый чат»;
- справа timeline и composer;
- при disabled AI state показывать понятное сообщение и блокировать отправку, но список чатов можно оставить доступным.

## Timeline

Пакет `ru.fgk.ws.app.ai.view.timeline`.

Использовать `JmixVirtualList` + `ComponentRenderer<TimelineItem>`.

`TimelineItem`:

```java
enum Kind { USER, ASSISTANT, ASSISTANT_THINKING }
```

- `USER`: текст пользователя, `white-space: pre-wrap`.
- `ASSISTANT`: markdown через Vaadin `Markdown`.
- `ASSISTANT_THINKING`: shimmer, активный статус, список завершенных tool status snippets.

CSS размещать в теме `app/src/main/frontend/themes/app/`, не в generated frontend.

## Streaming flow

View не сохраняет business state напрямую. Последовательность:

1. View вызывает service/coordinator для отправки сообщения.
2. Coordinator сохраняет `USER` message, создает `ASSISTANT` placeholder и обновляет timeline.
3. View добавляет `ASSISTANT_THINKING` row и блокирует input.
4. `AiAssistantService.stream(...)` возвращает `Flux<String>`.
5. Tool status callback через `ui.access()` обновляет thinking row и `refreshItem`.
6. На первом content token thinking row заменяется/переключается в assistant row.
7. Каждый token добавляется в UI через `ui.access`.
8. On complete coordinator сохраняет итоговый assistant content, обновляет `lastMessageDate`,
   разблокирует input и запускает title generation.
9. On error input разблокируется, placeholder удаляется или помечается ошибкой, пользователю
   показывается локализованное сообщение.

Все UI changes из non-UI thread выполняются только через `ui.access()`.

## Endpoint fallback

Гибрид streaming + tool-calling является обязательным spike из `10`.

Если minimax/Qwen не поддерживает streaming tool-calling:

- сохранить тот же UI;
- временно отключить tools через `ai.chat.tools.enabled=false`, или
- выполнять tool path non-streaming, а простой чат оставить streaming.

Выбранная деградация фиксируется перед реализацией production Diadoc tools.

## UI/UX requirements

- Input disabled while assistant is responding.
- Autoscroll вниз при новых messages/tokens.
- Markdown tables readable.
- Thinking row не должна бесконечно расти: показывать последние 6 completed statuses.
- Все visible strings через `msg://` / `MessageBundle`.

## Критерии готовности

- [ ] View id, route и menu references используют `ai_AiChat.view` / `ai-chat`.
- [ ] Ответ печатается token-by-token.
- [ ] Tool statuses отображаются в thinking row.
- [ ] Disabled AI state отображается без stacktrace.
- [ ] Input блокируется и разблокируется по complete/error.
- [ ] Business сохранение сообщений находится в service/coordinator, не во view.
