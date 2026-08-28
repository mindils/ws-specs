# 10. Тестирование и проверка

**Зависит от:** все задачи 01-09

## Цель

Проверить критичную безопасность JPQL tool, optional AI startup, основные service сценарии и
сквозной UI flow.

## Fast unit tests

Без сети, без реального LLM, желательно без Spring context.

### JPQL validator

Проверить, что validator:

- отклоняет `UPDATE`, `DELETE`, `INSERT`, DDL;
- отклоняет `SELECT *`;
- отклоняет entity вне whitelist;
- отклоняет joins к entity вне whitelist;
- отклоняет query без `AS` aliases;
- отклоняет missing/extra mismatch в `selectAliases`;
- отклоняет reserved aliases;
- принимает валидный `SELECT` по whitelisted Diadoc entities;
- clamps/rejects limit больше `ai.chat.jpql.max-rows`;
- корректно считает `offset`, `limit`, `hasMore`.

### Schema tool

- содержит все 6 JPQL entity names;
- содержит key fields и связь `DiadocPacketDocLink.document`;
- содержит mapping `8002`, `8015`, `3333`.

### AttachmentTextExtractor

- извлекает txt/md/csv;
- извлекает простой тестовый pdf;
- обрезает по per-file и total limits;
- возвращает controlled error для unsupported/too large/broken file.

### Title service

- fallback при disabled AI;
- fallback при exception модели;
- sanitize title убирает кавычки/переносы/точку и ограничивает длину.

## Integration tests

Запускать там, где доступна тестовая PostgreSQL/profile инфраструктура.

- CRUD `AiChatConversation`, `AiChatMessage`, `AiChatAttachment` через `DataManager`.
- Row-level visibility под двумя пользователями.
- `DataManager.loadValues` + `AccessManager` для разрешенного и запрещенного JPQL.
- Optional startup: context стартует при `ai.chat.enabled=false` без `AI_*`.

Использовать проектный `AuthenticatedAsAdmin`/`SystemAuthenticator` pattern; не ставить
`@Transactional` на tests.

## UI tests

Где практично:

- `AiChatView` открывается;
- «Новый чат» создает conversation;
- disabled AI state отображается;
- input блокируется/разблокируется;
- thinking row рендерит active/completed statuses;
- assistant row рендерит markdown.

## Endpoint spike

Перед production включением Diadoc tools вручную или отдельными gated tests проверить:

1. minimax: простой streaming response.
2. minimax: tool-calling без streaming.
3. minimax: streaming + tool-calling.
4. Qwen: простой streaming response.
5. Qwen: tool-calling без streaming.
6. Qwen: streaming + tool-calling.
7. fallback при `ai.chat.tools.enabled=false`.

Если streaming + tool-calling не поддержан, зафиксировать выбранную деградацию в `05`.

## Manual smoke сценарий

1. `./gradlew :app:bootRun` без AI env: приложение стартует, AI экран показывает disabled state.
2. Запустить с AI env/profile: меню «ИИ» открывает чат.
3. «Новый чат» -> обычный вопрос -> потоковая печать ответа.
4. Вопрос по Diadoc -> thinking row со статусом JPQL tool -> markdown answer.
5. Приложить txt/csv/pdf -> содержимое учитывается в ответе.
6. Первое сообщение -> auto title; ручное rename не перезаписывается.
7. Другой пользователь не видит чужие чаты.

## Команды

```bash
./gradlew :app:dependencies
./gradlew :app:test --tests "ru.fgk.ws.app.ai.*"
./gradlew :app:test
./gradlew :app:bootRun
```

Если AI endpoint/key недоступны, AI integration/spike checks пропускаются или выполняются локально
по отдельной инструкции; это фиксируется в финальном отчете реализации.

## Критерии готовности

- [ ] Fast unit tests покрывают JPQL validator и schema tool.
- [ ] `./gradlew :app:test` проходит в доступном окружении.
- [ ] Optional startup без AI env проверен.
- [ ] Endpoint spike выполнен или явно отложен с причиной.
- [ ] Manual smoke сценарий пройден.
