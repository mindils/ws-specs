# Результат T03

Таск: [task.md](task.md)
Итерация: 2
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

Итерация 2 закрывает все четыре замечания проверки 001
([F01](fixes/F01.md)): поиск в `entityComboBox` по подстроке и без учёта
регистра, понятное сообщение о дубле номера, понятное сообщение при запрете
удаления по ссылкам и выключенные кнопки создания, правки и копирования у роли
на чтение. Остальное поведение итерации 1 не менялось.

Проверка 001 подтвердила C2, C4, C5, C7 и C9. Самопроверкой итерации 2
дополнительно подтверждены C1 (поиск в lookup-полях), C3 (сообщение о дубле),
C6 (отказ удаления с понятным текстом и удаление после снятия детей) и C8 в
части кнопок роли read.

Блокеров нет.

## Итерация 2 — исправление F01

**F01.1 — поиск по подстроке.** Все девять `<itemsQuery>` дескрипторов T03
получили `escapeValueForLike="true"` и
`searchStringFormat="(?i)%${inputString}%"`, а их JPQL — форму
`e.<поле> like :searchString escape '\'` вместо `lower(...) like lower(...)`.
Это рабочий паттерн проекта (`da/view/claimdepostation/`, ещё девять
дескрипторов): без `searchStringFormat` Jmix подставляет введённый текст без
подстановочных знаков, и `like` работает как строгое равенство.
`(?i)` включает регистронезависимое сравнение на стороне Jmix, поэтому
`lower()` в запросе больше не нужен, а `escapeValueForLike` экранирует `%` и
`_` во введённом тексте.

**F01.2 — сообщение о дубле номера.** Ключ переименован в
`databaseUniqueConstraintViolation.IDX_CNT_CONTAINER_CONT_NUM` (верхний
регистр). Обоснование — в разделе «Изменения и решения»; регрессию закрывает
новый тест `ContainerDuplicateNumberMessageIT`.

**F01.3 — сообщение при запрете удаления.** Добавлен
`ru.fgk.ws.app.common.exception.DeletePolicyExceptionHandler`
(`AbstractUiExceptionHandler` на `io.jmix.core.DeletePolicyException`): он
подставляет подписи entity из метамодели вместо технических имён и текста
«Unable to delete». Обработчик общий для приложения, а не только для
контейнерного раздела, — см. «Ограничения и связанные изменения». Текст
сообщения закрыт тестом `DeletePolicyExceptionHandlerIT`.

**F01.4 — кнопки у роли read.** «Копировать» в реестре и «Создать» /
«Изменить» на вкладках — обычные `<button>`, а не `Action`, поэтому Jmix не
выключает их по правам. Доступность считается явно через
`AccessManager` + `CrudEntityContext` (паттерн проекта, см.
`ai/tool/DiadocJpqlQueryTool`): «Копировать» и «Создать» требуют
`isCreatePermitted()`, «Изменить» — `isUpdatePermitted()`. Проверка
выполняется в `BeforeShowEvent` карточки и в
`@Subscribe(target = Target.HOST_CONTROLLER)` фрагментов. Кнопка «Скачать»
остаётся доступной: чтение файла роли на чтение разрешено.

Изменённые файлы итерации 2: три дескриптора
(`container-detail-view.xml`, `container-property-detail-view.xml`,
`container-file-detail-view.xml`), три контроллера (`ContainerListView`,
`ContainerPropertyFragment`, `ContainerFileFragment`),
`messages_ru.properties` (ключ дубля переименован, добавлены три ключа
обработчика), новый `common/exception/DeletePolicyExceptionHandler.java`,
новые тесты `ContainerDuplicateNumberMessageIT` и
`DeletePolicyExceptionHandlerIT`.

## Изменения и решения

Новые файлы (пара `XML + контроллер` в каждом каталоге):

- `container/view/container/` — `ContainerListView`, `ContainerDetailView`,
  `container-list-view.xml`, `container-detail-view.xml`.
- `container/view/containerproperty/`, `container/view/containerfile/` —
  detail-формы характеристики и файла (открываются только диалогом).
- `container/view/fragment/containerproperty/`,
  `container/view/fragment/containerfile/` — вкладки «Характеристики» и «Файлы».
- `common/exception/DeletePolicyExceptionHandler.java` — общий обработчик
  отказа удаления (итерация 2).
- Тесты `container/ContainerChildRecordsIT.java`,
  `container/view/ContainerRegistryViewsUiTest.java`,
  `container/ContainerDuplicateNumberMessageIT.java` (итерация 2) и
  `common/exception/DeletePolicyExceptionHandlerIT.java` (итерация 2) в
  `app/src/test/java/ru/fgk/ws/app/`.

Изменены добавлением строк: `application.properties`
(`rvk.storage-folders.cnt-file=cnt_file`), `ru/fgk/ws/app/menu.xml` (пункт
`cnt_Container.list` внутри существующего раздела `container`),
`ru/fgk/ws/app/messages_ru.properties` (27 ключей экранов и вкладок, сообщение
о дубле номера и три ключа обработчика удаления),
`container/security/ContainerReadRole.java` и `ContainerEditRole.java` (метод
`containerScreens()` и READ на `VOrgPassport`). В `contracts.md` дописан
раздел «Уточнено при реализации T03» внутри «Карточка контейнера и вкладки».

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
  `databaseUniqueConstraintViolation.IDX_CNT_CONTAINER_CONT_NUM` в ВЕРХНЕМ
  регистре. В итерации 1 ключ был записан в нижнем и не находился — регистр
  задаёт не PostgreSQL, а Jmix: `JpaDataStore#resolveConstraintName`
  заканчивается `toUpperCase()`, поэтому до
  `UniqueConstraintViolationHandler` имя доходит в верхнем регистре, как бы
  его ни вернула БД. Соседний ключ `...IDX_DIADOC_DOCUMENT_TYPE_UNQ` записан
  верно. Расхождение закрыто тестом `ContainerDuplicateNumberMessageIT`: он
  берёт имя ограничения из настоящего исключения и требует, чтобы ключ с этим
  именем существовал.
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

Итерация 2 (итерация 1 — ниже отдельной строкой):

| Команда или сценарий | Результат |
|---|---|
| `./gradlew :app:compileJava :app:compileTestJava` | успешно |
| `./gradlew spotlessApply` | применено, изменений после — нет |
| Механические проверки `jmix-ide-static-analysis` по изменённым файлам | чисто: package-строки, нет 0-байтовых файлов и BOM, все XML раздела разбираются парсером, все 9 `itemsQuery` T03 содержат `:searchString`, `searchStringFormat` и `escapeValueForLike`, ручные `:containerId` загружаются явно, сырого `com.vaadin...dialog.Dialog` нет |
| `./gradlew :app:test --tests "ru.fgk.ws.app.container.*" --tests "ru.fgk.ws.app.common.exception.*"` | 34 passing, 0 failing (было 31; добавились `ContainerDuplicateNumberMessageIT` и два теста `DeletePolicyExceptionHandlerIT`) |
| F01.1 в браузере, поле «Модель» (`V03-MODEL-ALPHA`, `v03-model-beta`, `V03_50%-MODEL`) | `model` → все три; `ALPHA` → `V03-MODEL-ALPHA`; `beta` → `v03-model-beta`; `50%` → только `V03_50%-MODEL` (спецсимвол экранирован); `НЕТТАКОГО` → пусто |
| F01.1 в браузере, остальные поля | «Собственник»: `смоук` и `99030` → `T03-ORG-VERIFY` (поиск идёт и по `name`, и по `okpo`); «Тип»: `ерсальн` → «Универсальный контейнер»; «Размер»: `HC`/`hc`/`0HC` → `40HC`; «Обобщённая характеристика»: `тоннаж`/`ТОННАЖ` → «Крупнотоннажный»; в диалоге характеристики «Наименование характеристики»: `ериал` → «Материал пола» |
| F01.2 в браузере | при повторе `fgku9990001` показано «Контейнер с таким номером уже существует», URL остался `/containers/new` |
| F01.3 в браузере | удаление контейнера с характеристикой дало «Удаление невозможно. Нельзя удалить запись «Контейнер»: на неё ссылаются записи «Характеристика контейнера». Сначала удалите связанные записи.»; запись не удалена; после мягкого удаления характеристики контейнер удалился (`deleted_date` проставлен, список `1 строка` → `0 строк`) |
| F01.4 в браузере | под `user_read` «Копировать» в реестре и «Создать»/«Изменить» на обеих вкладках `disabled`, «Скачать» активна; под `user_edit` все они работают как раньше |
| Серверный лог и браузерная консоль за время smoke | ни одного `Unhandled exception`; единственный серверный ERROR — ожидаемый `duplicate key ... idx_cnt_container_cont_num` из сценария F01.2; в браузере один ERROR — `ERR_NAME_NOT_RESOLVED` на аватар `info.main.vgk` (корпоративный адрес, к T03 не относится) |

Итерация 1: `compileJava`, механические проверки, резолв всех `msg://`,
`./gradlew :app:test --tests "ru.fgk.ws.app.container.*"` (31 passing) и
браузерный smoke создания контейнера, вкладок, загрузки PDF, истории и копии.

Не запускалось, оставлено проверяющему: полный `./gradlew :app:test`; полный
браузерный проход C1–C8 целиком; экспорт с фильтром и прямой URL под ролями;
замена и скачивание файла; вкладка «История» после правок итерации 2; поиск в
`itemsQuery` собственника на реальном объёме организаций (локальная
`nsi_v_org_passport` пуста, проверка шла на одной сеяной записи).

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
`@ViewPolicy`, но контейнер там не предустановлен.

Справочники и организация после самопроверки удалены (`cnt_container` = 0
строк, `nsi_v_org_passport` = 0 строк). Для C2 и F01.1 их нужно завести
заново. Тот же набор, что использовала самопроверка (каждый `INSERT` —
отдельной командой: в psql несколько операторов идут одной транзакцией, и
ошибка последнего откатывает все предыдущие):

```sql
insert into main_rvk_ws.cnt_model (version, model, tenty, dugi, trosy, vent) values
  (1,'V03-MODEL-ALPHA',2,3,4,5),(1,'v03-model-beta',6,7,8,9),(1,'V03_50%-MODEL',1,1,1,1);
insert into main_rvk_ws.cnt_container_size (version, code, height, height_txt, width_f) values (1,'40HC',2896,'2896 мм','40');
insert into main_rvk_ws.cnt_container_type (version, code, type_name) values (1,'GP','Универсальный контейнер');
insert into main_rvk_ws.cnt_general_characteristic (version, char_name, char_name_pf) values (1,'Крупнотоннажный','Крупнотоннажные');
insert into main_rvk_ws.cnt_file_type (version, file_type_name) values (1,'Документ к ремонту');
insert into main_rvk_ws.cnt_property_type (version, prop_type_name) values (1,'Материал пола');
insert into ws_store.ora_assb_org_passport_current (dwh_pk_id, org_id, recdatenew, okpo, name, shortname)
  values (990301, 990301, now(), '99030199', 'Акционерное общество «Смоук Ф01»', 'T03-ORG-VERIFY');
```

Модель `V03_50%-MODEL` нужна именно для проверки экранирования `%` из раздела
«Повторная проверка» в `F01.md`: ввод `50%` должен находить только её.
Столбец `dwh_pk_id` у `ora_assb_org_passport_current` объявлен `not null`, без
него вставка организации падает.

Тестовый PDF для C5 можно взять любой; smoke использовал сгенерированный файл
во временном каталоге сессии, в репозиторий он не попал.

## Ограничения и связанные изменения

- Локальная `main.nsi_v_org_passport` пуста; поиск собственника проверен на
  одной сеяной записи (по `shortname` и по `okpo`), на реальном объёме
  организаций — нет.
- **Обработчик `DeletePolicyException` общий для приложения.** Он лежит в
  `common/exception/`, то есть вне области T03, объявленной в плане: сделать
  его контейнерным значило бы поставить общее по смыслу поведение в
  контейнерный пакет. Поведение не меняется — удаление как отклонялось, так и
  отклоняется; меняется только текст диалога во всех доменах, где настроен
  `DeletePolicy.DENY`. Это затрагивает формулировку доказательства C2 в
  [T02/checks/001.md](../T02/checks/001.md), где отказ удаления показан
  английским текстом `DeletePolicyException: Unable to delete
  cnt_CntDefectReason…`: сам отказ сохранился, поэтому `done` у T02 остаётся в
  силе, но при следующей проверке T02 ожидаемый текст будет русским.
- **Тот же дефект поиска остался в `cnt-defect-detail-view.xml` (T02).** Его
  `itemsQuery` по причине неисправности тоже без `searchStringFormat` и
  `escapeValueForLike`, поэтому там поиск по-прежнему по полному значению.
  Замечание F01.1 перечисляет только поля T03, а файл принадлежит области T02,
  поэтому здесь он не менялся — это материал для отдельного исправления T02.
- Вкладки «Ремонты», «Освидетельствования» и «Акты» не создавались: по таску их
  делают T07 и T04. В `container-detail-view.xml` на их месте стоят
  комментарии с указанием таска, невидимых вкладок в `tabSheet` нет.
- Статическая проверка Gate 1 в обеих итерациях выполнена откатом на
  `compileJava` плюс механические проверки: Jmix-осведомлённой IDE-инспекции
  (`get_file_problems`) в сессии не было. Тринадцать `*.java`/`*.xml` T03
  стоит переинспектировать в сессии, где инспекция доступна.
- T02 и T09 затронуты только добавлением строк (роли, меню, messages, фрагмент
  `EntityLogFragment` впервые встроен в реальную карточку). Их доказательства
  остаются в силе: прежние экраны и тесты не менялись, `./gradlew :app:test
  --tests "ru.fgk.ws.app.container.*"` проходит целиком.
- В `main_rvk_ws.audit_entity_log` накопились записи прошлых прогонов тестов по
  `cnt_*`; бизнес-таблицы контейнеров после самопроверки пусты.
