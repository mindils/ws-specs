# 03. Сервис ассистента, история и системный промпт

**Зависит от:** 01, 02
**Блокирует:** 04, 05, 07

## Цель

Реализовать service/coordinator слой для вызова LLM, сборки истории, сохранения сообщений и
передачи статусов инструментов в UI.

## AiAssistantService

Пакет `ru.fgk.ws.app.ai.service`.

Ответственность:

- проверить, что AI включен и provider settings доступны;
- собрать system prompt, историю диалога и текущее user message;
- зарегистрировать tools, если `ai.chat.tools.enabled=true`;
- вернуть `Flux<String>` для потокового ответа;
- пробросить `ToolContext` со status callback.

Пример целевого контракта:

```java
Flux<String> stream(AiChatConversation conversation,
                    String userMessageWithAttachments,
                    Consumer<AiUiStatusUpdate> statusCallback)
```

Если AI отключен или не настроен, service не должен падать startup-time ошибкой. Он должен вернуть
контролируемую ошибку/exception, которую UI покажет как понятное сообщение.

## AiChatMessageService / coordinator

Сохранение сообщений не размазывать по view controller. Один service/coordinator должен:

- создать и сохранить `USER` message;
- создать `ASSISTANT` placeholder;
- обновлять итоговый assistant content после завершения stream;
- обновлять `conversation.lastMessageDate`;
- удалять или помечать placeholder при ошибке;
- запускать title generation после первого успешного assistant response.

View отвечает за UI orchestration, но не за business rules сохранения.

## История диалога

Для v1 допустим ручной `buildHistory(conversation)` через `DataManager`:

- загрузить сообщения conversation с сортировкой `createdDate ASC, id ASC`;
- добавить первым `SystemMessage`;
- преобразовать `USER` в `UserMessage`, `ASSISTANT` в `AssistantMessage`;
- `SYSTEM`/`TOOL` messages не отдавать модели как обычный пользовательский текст, если они нужны
  только для внутреннего аудита.

`JmixChatMemoryRepository` можно добавить позже, если он реально упростит интеграцию со Spring AI.
Для v1 он не является обязательным решением.

## Security context для tools

Асинхронный/Reactive код должен выполнять Diadoc queries под текущим пользователем:

- использовать security-aware `DataManager`, не `UnconstrainedDataManager`;
- не терять authentication context при переходе из UI thread в reactive/tool execution;
- если выбран `BackgroundTask`, передавать/восстанавливать user context стандартным Jmix способом;
- покрыть этот риск интеграционным тестом или ручной проверкой из `10`.

## Системный промпт

Файл: `app/src/main/resources/ru/fgk/ws/app/ai/prompts/system-prompt.st`.

Содержание:

- роль: ассистент по электронному документообороту Диадок в `rvk-ws`;
- язык ответа: русский;
- при вопросах о статусах/подписании использовать tools, не выдумывать данные;
- JPQL правила: entity names, attribute names, `SELECT` only, mandatory aliases, no `SELECT *`,
  no hidden technical ids in final answer;
- краткие markdown-ответы, таблицы для списков;
- расшифровка `signatureStatus`: `8002`, `8015`, `3333`;
- если tools отключены или недоступны, честно сообщать ограничение.

## AiUiStatusUpdate

DTO/record, не entity:

```java
public record AiUiStatusUpdate(String message, String resultSnippet) {
    public boolean isCompleted() {
        return resultSnippet != null && !resultSnippet.isBlank();
    }
}
```

## Endpoint spike

Перед полноценным включением Diadoc tools проверить на minimax и Qwen:

- обычный streaming response;
- tool-calling без streaming;
- tool-calling вместе со streaming;
- поведение при tool error.

Результат spike фиксируется в задаче `10`.

## Критерии готовности

- [ ] AI disabled state обрабатывается без падения приложения.
- [ ] История строится из сохраненных messages в правильном порядке.
- [ ] `stream(...)` возвращает `Flux<String>`.
- [ ] Tools подключаются только при `ai.chat.tools.enabled=true`.
- [ ] Сохранение user/assistant messages и `lastMessageDate` централизовано в service/coordinator.
- [ ] System prompt загружается из resource file.
