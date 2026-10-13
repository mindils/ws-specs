# Ссылки на файлы старого хранилища ЕРК

Что сделать в РВК, чтобы перенесённые записи открывали файлы прямо из старого
хранилища ЕРК, без копирования, а при пересохранении записи файл переезжал в
хранилище РВК. Маппинг колонок — [mapping.md](mapping.md).

## Как сейчас

**ЕРК.** Запись ссылается на `"MDM_SYS".data_file.file_id`: `cont_file.file`,
`cont_survey.survey_act`, `eri_act.act_doc` (предположительно). Содержимое
лежит в одном из двух мест:

- старые файлы — `data_file.file_content` (`bytea`) в БД ЕРК;
- новые файлы — объект в S3 ЕРК, ключ `data_file.s3_uuid`.

`data_file` хранит версии (`recdatebegin`/`recdateend`), поэтому у одного
`file_id` может быть несколько строк; первичный ключ строки — `data_file.id`.

**РВК.**

- В разделе контейнеров четыре колонки `FileRef` (`varchar(1024)`):
  `cnt_container_file.file`, `cnt_survey.survey_act`, `cnt_act.act_doc`,
  `cnt_repair.document`.
- Значение — строка `<хранилище>://<путь>?name=<имя файла>`. Новые файлы
  пишутся через `fileStorageUploadField fileStorageName="cnt-file"`
  (`container-file-detail-view.xml:59` и ещё три формы) в MinIO РВК
  (`jmix.awsfs.*`, бакет `rvk`, папка `cnt_file`). Получается
  `s3://cnt_file/…?name=…`.
- Всё чтение берёт хранилище **по имени из самого `FileRef`**:
  - `DisplayFile`:
    `fileStorageLocator.getByName(file.getStorageName()).openStream(file)`
    (`common/view/displayfile/DisplayFile.java:149`, `:227`);
  - скачивание: `Downloader.download(FileRef)` во фрагменте файлов и формах.

Вывод: достаточно зарегистрировать ещё одно хранилище с именем, например
`erk`, и записать в перенесённые записи `FileRef` с этим именем. Просмотр,
скачивание и поле загрузки заработают без правок экранов.

## Что сделать

### 1. Хранилище `erk` (только чтение)

Класс `storage/ErkFileStorage implements io.jmix.core.FileStorage`,
`getStorageName()` = `"erk"`.

Формат ссылки (кладёт перенос в колонку `FileRef`):

| Где лежит файл | `FileRef` |
|---|---|
| S3 ЕРК | `erk://s3/<s3_uuid>?name=<file_name>` |
| `bytea` в БД ЕРК | `erk://db/<data_file.id>?name=<file_name>` |

Источник — тот, что известен на момент переноса. Ссылка привязана к
конкретной строке `data_file.id`, а не к `file_id`, поэтому при чтении не
нужно заново выбирать действующую версию. `name` — `data_file.file_name` с
расширением: по нему `DisplayFile` выбирает просмотр (PDF, картинка, XML).

Методы:

| Метод | Поведение |
|---|---|
| `openStream(ref)` | `s3/…` — `GetObject` из бакета ЕРК; `db/…` — `select file_content from "MDM_SYS".data_file where id = ?` через отдельный read-only `DataSource` |
| `fileExists(ref)` | `HeadObject` / `select 1 … where id = ?` |
| `saveStream(…)` | `UnsupportedOperationException`: в старое хранилище ничего не пишем |
| `removeFile(ref)` | ничего не делает: старые файлы не удаляем, даже когда запись в РВК удалена или файл заменён |

Регистрация — обычный `@Component`: `FileStorageLocatorImpl` подбирает все
бины `FileStorage` по `getStorageName()`.

**Ловушка.** Не делать `erk` вторым бином `AwsFileStorage`:
`FileStorageFoldersConfiguration.fileStorages` берёт
`applicationContext.getBean(AwsFileStorage.class)` и с двумя такими бинами
упадёт на старте (`NoUniqueBeanDefinitionException`). S3 ЕРК читать своим
`S3Client`. AWS SDK v2 (`software.amazon.awssdk:s3`) приходит с `jmix-awsfs`
только в scope `runtime`, поэтому для компиляции его нужно добавить в
`app/build.gradle` явно — `implementation`, версия из BOM.

Настройки — в `application-<профиль>.properties`, не в общем
`application.properties`:

```properties
rvk.erk-storage.enabled=true
rvk.erk-storage.s3.endpoint-url=https://<minio ЕРК>/
rvk.erk-storage.s3.bucket=<бакет ЕРК>
rvk.erk-storage.s3.access-key=<read-only ключ>
rvk.erk-storage.s3.secret-access-key=<секрет>
rvk.erk-storage.s3.region=us-east-1
rvk.erk-storage.s3.use-path-style-bucket-addressing=true
# только если остаются файлы в bytea (см. п. 4)
rvk.erk-storage.datasource.url=jdbc:postgresql://<хост ЕРК>/<бд>
rvk.erk-storage.datasource.username=<read-only пользователь>
rvk.erk-storage.datasource.password=<пароль>
```

При `enabled=false` (локально, тесты) бин есть, но `openStream` бросает
понятное исключение «Файл в старом хранилище ЕРК недоступен», а `fileExists`
возвращает `false`.

### 2. Поведение при недоступной ЕРК

`DisplayFile.createDownloadHandler` открывает поток лениво, внутри
`DownloadHandler`. Ошибка `erk` всплывёт при отрисовке iframe, а не в коде
экрана. Сделать:

- в `ErkFileStorage.openStream` — исключение с текстом для пользователя и
  запись в лог с `FileRef`;
- в `DisplayFile` перед показом файла из `erk` — `fileExists`. Если `false`,
  вместо iframe текст «Файл в старом хранилище недоступен» (ключ в
  `messages_ru.properties`). Для файлов `s3` поведение не меняется.

### 3. Переезд файла в хранилище РВК при пересохранении

**Замена файла** работает сама. Поле загрузки пишет новый файл в `cnt-file`
(`fileStorageName="cnt-file"`), в колонке оказывается `s3://cnt_file/…`.
Старый объект остаётся в ЕРК (`removeFile` ничего не делает).

**Пересохранение без замены файла** — слушатель
`container/listener/ContainerLegacyFileListener` на
`EntitySavingEvent` четырёх entity: `ContainerFile.file`,
`ContainerSurvey.surveyAct`, `ContainerAct.actDoc`, `ContainerRepair.document`.
Логика:

```text
ref = значение атрибута
если ref != null и ref.storageName == "erk":
    in  = fileStorageLocator.getByName("erk").openStream(ref)
    new = fileStorageLocator.getByName("cnt-file").saveStream(ref.fileName, in)
    атрибут = new                // s3://cnt_file/…?name=<то же имя>
```

Отдельный слушатель, а не `ContainerSavingListener`: у того другая задача
(номер контейнера) и одна entity.

Что важно знать:

- **«Пересохранение» — это сохранение с изменениями.** `DataContext`
  отправляет в БД только изменённые записи: открыть карточку и нажать «OK»
  без правок — событие не придёт, файл останется в ЕРК. Переезд происходит,
  когда пользователь поменял в записи любое поле.
- **ЕРК недоступна в момент сохранения.** Решение: не ронять сохранение,
  оставить `erk://…`, записать предупреждение в лог. Попытка повторится при
  следующем сохранении или в фоновом переносе (п. 4).
- **Время сохранения.** Копирование идёт внутри транзакции сохранения. Лимит
  загрузки в РВК — 50 МБ (`spring.servlet.multipart.max-file-size`), файлы
  ЕРК того же порядка — секунды. Если транзакция откатится, в `cnt_file`
  останется объект без ссылки — допустимо.
- **История.** EntityLog запишет смену `FileRef` (`erk://…` → `s3://…`) от
  имени пользователя, который сохранял. Для истории это честно: файл
  действительно переехал при его сохранении.
- **Копирование записи** (`EntityCopySupport`) уже очищает `FileRef` — не
  меняется.
- **Перенос данных** пишет в БД мимо `DataManager`, поэтому слушатель при
  загрузке не срабатывает — так и нужно.

### 4. Фоновый перенос остатка (чтобы отключить ЕРК)

Пока хоть одна ссылка `erk://` жива, ЕРК (её S3, а для `db/` и БД) нельзя
выключать. Нужна разовая задача — кнопка администратора или
`@Authenticated`-сервис по skill `jmix-run-background-code`:

- выбрать записи четырёх entity с `FileRef like 'erk://%'` пачками;
- для каждой скопировать содержимое так же, как в п. 3;
- обновить колонку прямым `update` (мимо `DataManager` — не плодить EntityLog
  и не трогать `version`);
- отчёт: сколько перенесено, сколько не нашлось.

Совет по `bytea`: файлы из `data_file.file_content` копировать в S3 РВК
**сразу при переносе данных**, а не ссылаться на них. Тогда РВК не нужно
держать подключение к БД ЕРК ради чтения файлов — достаточно S3 ЕРК. Ссылками
`erk://db/…` пользоваться, только если копирование `bytea` при переносе
почему-то невозможно.

### 5. Права и безопасность

- Учётки ЕРК (S3 и БД) — только на чтение; секреты по профилям, не в
  общем `application.properties`.
- Новые роли не нужны: доступ к файлу определяется доступом к записи, как
  сейчас.

## Проверка

- Unit: `ErkFileStorage` разбирает `erk://s3/…` и `erk://db/…`; `saveStream`
  бросает исключение; `removeFile` ничего не делает; при `enabled=false`
  `fileExists = false`.
- IT: запись `ContainerFile` с `erk://…` и подменённым `ErkFileStorage` →
  правка комментария → в БД `s3://cnt_file/…`, имя файла то же, содержимое
  совпадает. При ошибке `erk` сохранение проходит, ссылка остаётся `erk://…`.
- UI: вкладка «Файлы» и формы освидетельствования, акта, ремонта показывают
  PDF и картинку из `erk`; при недоступной ЕРК — текст вместо пустого iframe.
- После фонового переноса: `select count(*) … where file like 'erk://%'` = 0
  во всех четырёх таблицах.

## Что нужно узнать до реализации

1. Эндпоинт и бакет S3 ЕРК, совпадает ли MinIO с РВК (`minio01.main.vgk`),
   и является ли `s3_uuid` полным ключом объекта или к нему добавляется
   префикс.
2. Сколько файлов контейнерного раздела в `bytea`, а сколько в S3, и их общий
   объём (SELECT 5 в [input/research.md](input/research.md)).
3. Есть ли сетевой доступ от серверов РВК к S3 ЕРК (и к БД, если остаются
   `db/`).
4. Расширение в `data_file.file_name` есть всегда? Если нет — брать его из
   `mime_type` при формировании `name`.
