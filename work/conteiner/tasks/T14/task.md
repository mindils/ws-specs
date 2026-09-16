# T14 — Статика `/img/**` без 403

Статус: todo
План: [plan.md](../../plan.md)
Зависимости: нет
Сложность: easy — одна строка в security-конфиге по образцу соседней.
Сложность проверки: medium — нужен поднятый `bootRun` и `curl`, браузерные
сценарии не требуются.
Актуальная проверка: нет

## Коротко

Картинки, которыми общий фрагмент просмотра файлов `DisplayFile` показывает
типы документов и заглушки, лежат в `META-INF/resources/img/filetype/`, но
Spring Security отдаёт на них 403 даже вошедшему пользователю. Разрешаем
`/img/**` явно, после чего иконки doc/xls/html/other видны во всех хостах
`DisplayFile` — в контейнерном разделе и в копиях документов договора.

## Результат и контекст

Дефект зафиксирован в [result.md T04](../T04/result.md), раздел «Ограничения»:
`fetch` из браузера на `/img/filetype/docFileType.png` и `fileNotFound.png`
даёт 403. Причина — `app/src/main/java/ru/fgk/ws/app/security/IframeSecurity.java`
(`extends OidcVaadinWebSecurity`) в `configureCustomSpecifics` разрешает
только `/local-login`; путь `/img/**` в список статики Jmix/Vaadin не входит.
Замечание пользователя 4 в [ui-review-2026-09-16.md](../../input/ui-review-2026-09-16.md).

## Область и изоляция

Меняет только `app/src/main/java/ru/fgk/ws/app/security/IframeSecurity.java`.
Общие ресурсы: порт приложения при проверке. Параллельно с T11, T12, T13.
Проверка — первой в очереди пересмотра (T14 → T11 → T12 → T13 → T15).

## Реализация

В том же вызове `http.authorizeHttpRequests(...)`, где уже есть
`requestMatchers("/local-login").permitAll()`, добавить
`requestMatchers("/img/**").permitAll()`. Комментарий в коде — почему статика
`DisplayFile` требует явного разрешения (каталог `img/` не входит в стандартные
разрешённые пути Vaadin/Jmix). Никаких других изменений security.

## Критерии приёмки

- C1: Без входа `curl -sI http://localhost:<port>/img/filetype/fileNotFound.png`
  отвечает `200` и `Content-Type: image/png`; то же для `docFileType.png`.
- C2: Под пользователем `user` в любом хосте `DisplayFile` файл `.docx`
  показывается иконкой `docFileType.png` без ошибок в консоли браузера.
- C3: `/local-login` и остальная аутентификация работают как прежде;
  `./gradlew :app:test --tests "ru.fgk.ws.app.container.security.*"` зелёный.

## Самопроверка исполнителя

`./gradlew :app:compileJava`, `./gradlew spotlessApply`; `bootRun` в фоне,
дождаться `/actuator/health` = UP, выполнить `curl` из C1, погасить процесс.

## Независимая проверка

C1 через `curl`; C2 в браузере (`playwright-cli`) на любом хосте `DisplayFile`
с загруженным `.docx`; C3 — вход через `/local-login` и тесты security
контейнерного пакета. Порт и процесс `bootRun` — свои, по plan.md.

## Прогресс и продолжение

- [ ] Правка `IframeSecurity`, комментарий.
- [ ] Самопроверка `curl`.
- [ ] Передать результат на независимую проверку.

Ближайший шаг: открыть `IframeSecurity.java`.
Препятствия: нет
