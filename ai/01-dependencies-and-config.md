# 01. Зависимости и конфигурация LLM

**Зависит от:** —
**Блокирует:** 02, 03, 04, 05

## Цель

Подключить Spring AI с OpenAI-compatible provider так, чтобы `rvk-ws` стартовал без AI-настроек,
а AI включался только явной конфигурацией окружения/профиля.

## Gradle dependencies

В `app/build.gradle` добавить:

```gradle
dependencies {
    implementation platform('org.springframework.ai:spring-ai-bom:1.1.3')
    implementation 'org.springframework.ai:spring-ai-starter-model-openai'
    implementation 'io.projectreactor:reactor-core'
}
```

- Spring AI `1.1.3` выбран как совместимый с текущим Spring Boot `3.5.6`.
- После изменения проверить resolution командой `./gradlew :app:dependencies`.
- Если Maven Central недоступен через текущие repositories, добавить репозиторий в общий
  Gradle repository setup проекта, а не в локальный workaround.

## Optional-safe configuration

В базовом `application.properties` не должно быть обязательных `${AI_*}` placeholders, которые
ломают старт приложения. Базовые настройки:

```properties
# === AI chat ===
ai.chat.enabled=${AI_CHAT_ENABLED:false}
ai.chat.tools.enabled=${AI_CHAT_TOOLS_ENABLED:true}
ai.chat.jpql.max-rows=${AI_CHAT_JPQL_MAX_ROWS:200}

ai.chat.title-model=${AI_TITLE_MODEL:}
ai.chat.attachments.max-files=${AI_ATTACHMENTS_MAX_FILES:5}
ai.chat.attachments.max-total-size=${AI_ATTACHMENTS_MAX_TOTAL_SIZE:15MB}
ai.chat.attachments.max-extracted-chars-per-file=${AI_ATTACHMENTS_MAX_EXTRACTED_CHARS_PER_FILE:20000}
ai.chat.attachments.max-extracted-chars-total=${AI_ATTACHMENTS_MAX_EXTRACTED_CHARS_TOTAL:60000}

logging.level.org.springframework.ai=INFO
```

AI-specific Spring properties задаются только когда AI включен:

```properties
spring.ai.model.chat=openai
spring.ai.openai.base-url=${AI_BASE_URL}
spring.ai.openai.api-key=${AI_API_KEY}
spring.ai.openai.chat.options.model=${AI_MODEL}
spring.ai.openai.chat.options.temperature=0.1
spring.ai.openai.chat.options.max-completion-tokens=4096
```

Рекомендуемый implementation pattern:

- `AiChatProperties` хранит app-specific флаги и limits.
- `AiConfig`/`ChatClient` создаются под `@ConditionalOnProperty(name = "ai.chat.enabled", havingValue = "true")`.
- `AiAssistantService` перед вызовом модели проверяет, что AI включен и все provider settings
  заполнены; при неполной настройке возвращает понятную ошибку для UI.
- При `ai.chat.enabled=false` приложение стартует без AI model beans.

## Dev/prod profiles

- dev: minimax m3, OpenAI-compatible endpoint.
- prod: Qwen/Qwen3.6-27B или Qwen/Qwen3.6-35B-A3B через vLLM/SGLang/provider.
- Переключение dev/prod выполняется env-переменными или profile-specific properties без правки кода.
- `AI_API_KEY` не коммитить.

## AiConfig

`ru.fgk.ws.app.ai.config.AiConfig`:

- создает `ChatClient` из `ChatClient.Builder`;
- подключает `SimpleLoggerAdvisor`;
- не зашивает system prompt в bean: prompt задается в `AiAssistantService`;
- при необходимости создает title-specific client/options, если `ai.chat.title-model` отличается от основной модели.

## Критерии готовности

- [ ] `./gradlew :app:dependencies` разрешает Spring AI artifacts.
- [ ] Приложение стартует без `AI_BASE_URL`, `AI_API_KEY`, `AI_MODEL`.
- [ ] При `ai.chat.enabled=false` UI показывает disabled/error state, а не stacktrace.
- [ ] При включенном AI dev/prod переключаются только env/profile settings.
- [ ] В properties нет закоммиченных секретов.
