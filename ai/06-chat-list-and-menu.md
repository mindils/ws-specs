# 06. Список чатов, создание нового чата и пункт меню

**Зависит от:** 02, 05
**Блокирует:** 07, 09

## Цель

Добавить отдельный пункт меню «ИИ», sidebar со списком чатов текущего пользователя и создание
нового чата.

## Sidebar

Sidebar является частью `AiChatView`:

- кнопка «Новый чат» сверху;
- список чатов с `title`;
- выбор чата загружает messages в timeline;
- после создания, переименования и нового сообщения список обновляется.

Отдельный list view для v1 не нужен.

## Загрузка данных

Использовать `AiChatConversationRepository` или service над `DataManager`.

Список:

- полагается на row-level role из `09`;
- дополнительно может фильтровать по текущему пользователю для ясности, но не должен обходить security;
- сортировка: `lastMessageDate desc nulls last, createdDate desc`;
- fetch plan должен быть минимальным, без загрузки всех messages.

## Menu

В `app/src/main/resources/ru/fgk/ws/app/menu.xml` добавить:

```xml
<menu id="ai" title="msg://ru.fgk.ws.app.ai/menu.ai.title">
  <item view="ai_AiChat.view"
        title="msg://ru.fgk.ws.app.ai.view.chat/aiChatView.title"
        description="msg://ru.fgk.ws.app.ai.view.chat/aiChatView.title"/>
</menu>
```

Security policy для menu/view описана в `09`.

## Создание нового чата

Выбранный вариант для v1: создавать conversation сразу.

- `title` = localized default title из `messages_ru.properties`;
- `titleGenerated=false`;
- `lastMessageDate=null`;
- conversation сразу появляется в списке;
- после первого assistant response задача `07` генерирует осмысленное название.

## Критерии готовности

- [ ] Пункт меню `ai` открывает `ai_AiChat.view`.
- [ ] Sidebar показывает только доступные текущему пользователю чаты.
- [ ] «Новый чат» создает и выбирает пустой conversation.
- [ ] Список сортируется по последней активности.
- [ ] Список обновляется после создания, переименования и нового сообщения.
