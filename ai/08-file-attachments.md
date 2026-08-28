# 08. Вложения файлов и извлечение текста

**Зависит от:** 02, 05

## Цель

Позволить приложить к сообщению текстовые файлы и PDF, извлечь текст и передать его модели как
часть user context.

## Scope v1

Поддерживаемые форматы:

- `.txt`
- `.md`
- `.csv`
- `.pdf`

Вне v1: Excel/xlsx, OCR, изображения, мультимодальные запросы.

## UI composer

Composer fragment в `ru.fgk.ws.app.ai.view.chat`:

- `JmixUpload` для одного или нескольких файлов;
- карточки выбранных файлов: имя, размер, удалить;
- отправка message вместе с текущим набором attachments;
- input validation до отправки.

Лимиты v1:

- максимум 5 файлов;
- суммарный размер 15 MB;
- extracted text максимум 20k chars на файл;
- extracted text максимум 60k chars суммарно на сообщение.

Лимиты берутся из `ai.chat.attachments.*` properties из `01`.

## Storage

Использовать Jmix `FileStorage` abstraction / default storage.

- Не закладываться на localfs: в окружении может быть S3/MinIO/default storage.
- В `AiChatAttachment` хранить `FileRef`, `fileName`, `contentType`, `fileSize`, `extractedText`.
- Если файл сохранен, но extraction failed, attachment остается с понятной ошибкой для UI/logs.

## AttachmentTextExtractor

Пакет `ru.fgk.ws.app.ai.service`.

- `txt/md/csv`: читать как UTF-8 text.
- `pdf`: PDFBox 3.x, `Loader.loadPDF(...)` + `PDFTextStripper`.
- Нормализовать whitespace только минимально, не ломая таблицы CSV.
- Обрезать текст по configured limits.
- Ошибки unsupported type, too large, extraction failure возвращать как контролируемые validation
  errors, а не как падение всего чата.

## Подстановка в prompt

`AiChatMessageService` или `AiAssistantService` добавляет к user message блоки:

```text
[Вложение: fileName]
extracted text...
```

Для нескольких файлов блоки идут последовательно. Если часть вложений не извлечена, модель получает
только успешные extracted texts, а UI показывает ошибку по проблемным файлам.

## Критерии готовности

- [ ] Можно приложить `txt/md/csv/pdf`.
- [ ] Используется default `FileStorage`, без localfs assumptions.
- [ ] Text extraction и truncation работают по configured limits.
- [ ] Attachment content учитывается в ответе.
- [ ] Ошибки типов/размера/extraction показаны пользователю локализованно.
