# Результат T03

Таск: [task.md](task.md)
Итерация: 1
Обновлено: 2026-09-15

## Что реализовано

Реестр контейнеров и карточка контейнера с вкладками. Редактор заводит контейнер
на пустом реестре, сохраняет его, после чего в карточке появляются вкладки
«Характеристики», «Файлы» и «История»; из вкладок диалогами создаются и правятся
характеристики и вложения, PDF виден в просмотре рядом с гридом. Реестр даёт
фильтры, пагинацию, настройку колонок, сохранение настроек, асинхронный экспорт
в Excel и действия создать / изменить / копировать / удалить; он же работает
lookup-ом для форм ремонта и освидетельствования (T04, T07). Контракт
подключения вкладок записан в `contracts.md`.

Подтверждено самопроверкой: C1 (создание на пустом реестре, пункт меню,
сохранение), C3 (нормализация номера), C4 частично (создание файла из вкладки с
предустановленным контейнером, грид обновился после SAVE), C5 частично (PDF
загружен в `cnt_file`, отрисован в просмотре), C6 частично (копия открывается
без номера и без вкладок), C7 (вкладка «История» показала CREATE по
контейнеру), C9 (контракт в `contracts.md`).

Реализованы, но в браузере не проходились и остаются проверяющему: C2 (значения
из модели и размера при смене lookup — нужны наполненные справочники), остаток
C4 (отмена диалога, характеристики), остаток C5 (замена файла, скачивание),
остаток C6 (отказ удаления контейнера с детьми и удаление после их снятия), C8
(роли read/edit в UI и экспорт с фильтром).

Блокеров нет.

## Изменения и решения

Новые файлы (пара `XML + контроллер` в каждом каталоге):

- `container/view/container/` — `ContainerListView`, `ContainerDetailView`,
  `container-list-view.xml`, `container-detail-view.xml`.
- `container/view/containerproperty/`, `container/view/containerfile/` —
  detail-формы характеристики и файла (открываются только диалогом).
- `container/view/fragment/containerproperty/`,
  `container/view/fragment/containerfile/` — вкладки «Характеристики» и «Файлы».
- Тесты `app/src/test/java/ru/fgk/ws/app/container/ContainerChildRecordsIT.java`
  и `app/src/test/java/ru/fgk/ws/app/container/view/ContainerRegistryViewsUiTest.java`.

Изменены добавлением строк: `application.properties`
(`rvk.storage-folders.cnt-file=cnt_file`), `ru/fgk/ws/app/menu.xml` (пункт
`cnt_Container.list` внутри существующего раздела `container`),
`ru/fgk/ws/app/messages_ru.properties` (27 ключей экранов и вкладок плюс
сообщение о дубле номера), `container/security/ContainerReadRole.java` и
`ContainerEditRole.java` (метод `containerScreens()` и READ на `VOrgPassport`).
В `contracts.md` дописан раздел «Уточнено при реализации T03» внутри «Карточка
контейнера и вкладки».

Существенные решения:

- **Дочерний диалог сохраняет сам, без `withParentDataContext`.** Постановка
  предлагала родительский data context, но тогда запись попадает в БД только
  вместе с карточкой, а перезагрузка лоадера фрагмента (тоже из постановки) её
  теряет. Диалог пишет запись сразу, фрагмент перечитывает лоадер после
  `StandardOutcome.SAVE`; отмена не меняет ничего. Отклонение записано в
  `contracts.md`.
- **Вкладки не показываются до первого сохранения**, вместо них подсказка
  `tabsHint`. `JmixTabSheet` не реализует `HasEnabled`, поэтому «выключить»
  его нельзя; прятать уместнее и по правилу таска «невидимых или неработающих
  вкладок не показывать». Чтобы вкладки стали доступны без закрытия формы, в
  карточке есть отдельная кнопка «Сохранить» (`detail_save`) рядом с обычными
  «OK» и «Отмена».
- **Отдельного виртуального поля «наименование типа» нет.** `@InstanceName` у
  `CntContainerType` — это `typeName`, поэтому и колонка `type`, и
  `entityComboBox` показывают ровно название; дублирующее read-only поле было бы
  тем же текстом дважды. Виртуальные read-only поля оставлены там, где подпись
  ссылки другая: `model.tenty/dugi/trosy/vent` и `size.widthF`.
- **Понятное сообщение о дубле номера** — ключ
  `databaseUniqueConstraintViolation.idx_cnt_container_cont_num` в нижнем
  регистре: `UniqueConstraintViolationHandler` берёт имя ограничения как его
  вернул PostgreSQL, а PostgreSQL складывает незакавыченные идентификаторы в
  нижний регистр (проверено `pg_indexes`). Существующий ключ
  `...IDX_DIADOC_DOCUMENT_TYPE_UNQ` по этой же причине не срабатывает; чужой
  ключ не трогал.
- **Фильтры реестра — по путям свойств** (`owner.shortname`, `model.model`,
  `type.typeName`, `size.code`), а не по самим ссылкам: `propertyFilter` по
  ссылке рисует `entityPicker` с lookup-ом, а lookup-view для `VOrgPassport` по
  постановке не создаётся.
- **Копирование открывается диалогом.** `EntityCopySupport` отдаёт готовый
  экземпляр, а навигация в Jmix передать его не умеет — только
  `DialogWindows.detail(...).newEntity(copy)`.
- **READ на `VOrgPassport` добавлен в обе контейнерные роли**: без него у ролей
  `container-read`/`container-edit` не читается собственник в реестре и карточке.

## Предварительные проверки

| Команда или сценарий | Результат |
|---|---|
| `./gradlew :app:compileJava :app:compileTestJava` | успешно |
| `./gradlew spotlessApply` | применено, изменений после — нет |
| Механические проверки `jmix-ide-static-analysis` по новым файлам | чисто: package-строки, нет 0-байтовых файлов и BOM, все 9 `itemsQuery` содержат `:searchString`, все ручные `:containerId` загружаются явно, сырого `com.vaadin...dialog.Dialog` нет |
| Резолв всех `msg://` новых дескрипторов по `messages_ru.properties` (скрипт) | 0 нерезолвящихся ключей |
| `./gradlew :app:test --tests "ru.fgk.ws.app.container.*"` | 31 passing, 0 failing (в т.ч. новые `ContainerChildRecordsIT` и `ContainerRegistryViewsUiTest`) |
| Браузерный smoke на `bootRun` порт 8082 под `user_edit` | реестр открылся из меню; контейнер с номером ` fgku5026002 ` сохранён как `FGKU5026002`; после «Сохранить» появились три вкладки; файл создан из вкладки с предустановленным read-only контейнером, PDF загружен в `s3://cnt_file/...` и отрисовался в просмотре; «История» показала «Создание»; «Копировать» открыло карточку без номера, с изготовителем и без вкладок |
| Серверные исключения и error overlay за время smoke | только `ERR_NAME_NOT_RESOLVED` на аватар `info.main.vgk` (корпоративный адрес, к T03 не относится) |

Не запускалось, оставлено проверяющему: полный `./gradlew :app:test`; полный
браузерный проход C1–C8; сценарии под ролями `container-read` и
`container-edit`, включая прямой URL и экспорт с фильтром; отмена диалогов;
замена и скачивание файла; вкладка «Характеристики» в браузере; отказ удаления
контейнера с детьми и удаление после их снятия; поведение lookup-полей модели,
типа и размера на наполненных справочниках (C2).

## Для независимой проверки

Worktree `../worktrees/rvk-ws/cyan-fennel/rvk-ws`, ветка `f/container`, схема
`main_rvk_ws` в общем Docker PostgreSQL, порт приложения 8082 — параметры уже
лежат в `app/src/main/resources/application-local.properties` (файл не
отслеживается git, создан `system/worktree-setup.sh`).

```bash
docker info && (cd docker && docker compose ps)
cd ../worktrees/rvk-ws/cyan-fennel/rvk-ws
./gradlew :app:test
./gradlew :app:bootRun            # порт 8082, ждать /actuator/health
```

Подготовка окружения, без которой C5 не проверить:

- В `application-local.properties` этого worktree добавлены четыре строки
  `jmix.awsfs.*`, переводящие хранилище на MinIO из `docker/docker-compose.yml`
  (по умолчанию `application.properties` указывает на корпоративный
  `minio01.main.vgk`, недоступный вне сети). Значения — те же, что в
  `docker/docker-compose.yml` и `application-test-local.properties`.
- Бакета `rvk-dev` в локальном MinIO не было, загрузка падала с
  `NoSuchBucketException`. Бакет создан командой
  `(cd docker && docker compose run --rm --entrypoint sh createbuckets -c "mc alias set myminio http://minio:9000 <user> <password> && mc mb --ignore-existing myminio/rvk-dev")`;
  учётные данные берутся из `docker/docker-compose.yml`. Штатный сервис
  `createbuckets` на текущей версии образа `minio/mc` падает на `mc config host
  add` и бакет не создаёт.

Пользователи для UI: `user_edit` / `edit123` (роль `container-edit`),
`user_read` / `read123` (роль `container-read`), `user_nsi` (роль
`container-nsi-edit`) — заведены при проверке T02, вход через `/local-login`.
Пользователя `user` в схеме `main_rvk_ws` нет.

Сценарии UI: адрес `http://localhost:8082/containers`, пункт меню «Контейнеры →
Реестр контейнеров». Карточка — `/containers/:id`; вкладки появляются только
после сохранения описания (кнопка «Сохранить»). Формы характеристики и файла
открываются только из вкладок карточки, прямые адреса
`/container-properties/:id` и `/container-files/:id` существуют ради
`@ViewPolicy`, но контейнер там не предустановлен. Для C2 нужны хотя бы по
одной записи в справочниках моделей, типов и размеров (реестр и справочники
пусты: `cnt_container` = 0 строк после уборки smoke-данных).

Тестовый PDF для C5 можно взять любой; smoke использовал сгенерированный файл
во временном каталоге сессии, в репозиторий он не попал.

## Ограничения и связанные изменения

- Локальная `main.nsi_v_org_passport` пуста, поэтому выпадающий список
  собственника в браузере пуст фактически, а не из-за дефекта формы. Запрос
  `itemsQuery` по `shortname`/`name`/`okpo` на данных не проверялся.
- Вкладки «Ремонты», «Освидетельствования» и «Акты» не создавались: по таску их
  делают T07 и T04. В `container-detail-view.xml` на их месте стоят
  комментарии с указанием таска, невидимых вкладок в `tabSheet` нет.
- Статическая проверка Gate 1 выполнена откатом на `compileJava` плюс
  механические проверки: Jmix-осведомлённой IDE-инспекции
  (`get_file_problems`) в этой сессии не было. Двенадцать новых
  `*.java`/`*.xml` стоит переинспектировать в сессии, где инспекция доступна.
- T02 и T09 затронуты только добавлением строк (роли, меню, messages, фрагмент
  `EntityLogFragment` впервые встроен в реальную карточку). Их доказательства
  остаются в силе: прежние экраны и тесты не менялись, `./gradlew :app:test
  --tests "ru.fgk.ws.app.container.*"` проходит целиком.
- В `main_rvk_ws.audit_entity_log` накопились записи прошлых прогонов тестов по
  `cnt_*`; бизнес-таблицы контейнеров после самопроверки пусты.
