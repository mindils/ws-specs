# 07. Автогенерация названия чата и переименование

**Зависит от:** 03, 06

## Цель

После первого успешного ответа ассистента заменить default title на краткое название, а также
дать пользователю ручное переименование.

## AiConversationTitleService

Пакет `ru.fgk.ws.app.ai.service`.

Поведение:

- если `ai.chat.enabled=false` или provider settings неполные, сразу использовать fallback;
- если задан `ai.chat.title-model`, использовать эту модель через title-specific options;
- если title model не задана, использовать основную модель;
- temperature `0.0`, небольшой лимит ответа;
- нормализовать результат: убрать кавычки, точки в конце, переводы строк, ограничить длину.

Fallback:

- взять первые 40-60 символов первого user message;
- убрать переносы строк;
- если user message пустой, оставить localized default title.

## Trigger

Title generation запускается из service/coordinator после первого успешного assistant response:

1. проверить `titleGenerated == false`;
2. собрать context из первого user message или первых 2-3 messages;
3. сгенерировать или fallback title;
4. сохранить `title`, `titleGenerated=true`;
5. обновить sidebar через `ui.access()`.

Автогенерация не должна выполняться в UI thread.

## Ручное переименование

В `AiChatView` добавить действие «Переименовать»:

- dialog input через Jmix `dialogs.createInputDialog(...)`;
- сохранить `title`;
- выставить `titleGenerated=true`, чтобы AI больше не перезаписывал ручное название;
- обновить sidebar.

## Критерии готовности

- [ ] Первый успешный диалог получает осмысленное название.
- [ ] AI disabled/unavailable не ломает flow и использует fallback.
- [ ] Ручное название не перезаписывается автогенерацией.
- [ ] Все visible labels/messages локализованы.
