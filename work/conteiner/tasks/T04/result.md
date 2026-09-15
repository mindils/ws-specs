# Результат T04

Таск: [task.md](task.md)
Итерация: 1
Обновлено: 2026-09-15

## Что реализовано

Страница «Освидетельствования контейнеров» и вкладка «Освидетельствования» в
карточке контейнера. Запись одна, форма одна: созданное из списка видно во
вкладке своего контейнера и наоборот; из вкладки контейнер предустановлен и
read-only, из списка его выбирают по части номера или через lookup на реестр и
там же переносят запись на другой контейнер. Вид, три календарные даты,
исполнитель и файл акта заполняются вручную; акт виден в просмотре рядом с
формой и скачивается кнопкой. Дата следующего освидетельствования в реестре не
меняется ни при одной операции — ни кода, ни listener-а на это нет.

Блокеров нет.

## Изменения и решения

Новые файлы (пара `XML + контроллер` в каждом каталоге):

- `container/view/containersurvey/` — `ContainerSurveyListView`,
  `ContainerSurveyDetailView`, `container-survey-list-view.xml`,
  `container-survey-detail-view.xml`.
- `container/view/fragment/containersurvey/` — `ContainerSurveyFragment` и
  `container-survey-fragment.xml` (вкладка карточки).
- Тесты `container/ContainerSurveyIT.java` и
  `container/view/ContainerSurveyViewsUiTest.java` в
  `app/src/test/java/ru/fgk/ws/app/`.

Изменены добавлением строк: `container/view/container/container-detail-view.xml`
(вкладка `surveysTab` на месте комментария T04),
`container/view/container/ContainerDetailView.java` (поле фрагмента и
`surveysFragment.refresh()` в `AfterSaveEvent`), `ru/fgk/ws/app/menu.xml` (пункт
`cnt_ContainerSurvey.list` в разделе «Контейнеры»),
`ru/fgk/ws/app/messages_ru.properties` (20 ключей экранов, вкладки и фрагмента),
`container/security/ContainerReadRole.java` и `ContainerEditRole.java` (метод
`surveyScreens()` с view- и menu-политиками),
`container/security/ContainerRolesTest.java` (проверка этих политик у обеих
основных ролей и их отсутствия у роли НСИ). Существенные решения записаны в
`contracts.md`, раздел «Уточнено при реализации T04».

Существенные решения:

- **`propertyFilter` по `container.contNum` нуждается в явном
  `parameterName`.** По умолчанию имя параметра выводится из пути свойства и
  начинается с `container_`, а этот префикс `dataLoadCoordinator` считает
  ссылкой на data container: он ищет контейнер `contNum…`, не находит и роняет
  открытие списка (`IllegalArgumentException: Container 'contNum…' not found`).
  Дефект поймал UI-тест на первом прогоне; в фильтре стоит
  `parameterName="containerContNumFilter"`. То же ждёт список ремонтов в T07 —
  отмечено в `contracts.md`.
- **Левая половина формы — `scroller`.** В `split` форма выше доступной высоты
  выезжает за его пределы и накрывает панель кнопок: «Загрузить» оказывается
  под «OK» и не нажимается (поймано в браузере). Внутри `scroller` с
  `scrollBarsDirection="VERTICAL"` форма прокручивается, кнопки остаются
  доступны.
- **Read-only контейнер задаёт точка входа, а не форма.** Фрагмент вкладки
  открывает диалог с `.withViewConfigurer(view ->
  view.setContainerReadOnly(true))`; конфигурер отрабатывает до
  `BeforeShowEvent`, поэтому флаг успевает примениться. Из списка поле остаётся
  редактируемым — иначе нельзя было бы перенести запись на другой контейнер
  (критерий C3).
- **Просмотр и скачивание акта — в форме, а не во вкладке и списке.** У
  освидетельствования один файл, привязанный к записи, а форма общая для обеих
  точек входа: один `DisplayFile` справа от полей и одна кнопка «Скачать акт»
  закрывают просмотр для обоих сценариев. Просмотр обновляется по
  `ItemPropertyChangeEvent` атрибута `surveyAct`, поэтому замена и очистка
  файла видны сразу, до сохранения.
- **Копия без файла — поведение `EntityCopySupport`**, отдельного кода не
  потребовалось: `FileRef`-атрибуты утилита не переносит, чтобы две записи не
  делили один объект в хранилище.
- **Колонки «Контейнер» во вкладке нет**: у всех строк вкладки он один и тот
  же. В самостоятельном списке колонка и фильтр по номеру есть.

## Предварительные проверки

| Команда или сценарий | Результат |
|---|---|
| `./gradlew :app:compileJava :app:compileTestJava` | успешно |
| `./gradlew spotlessApply`, затем `spotlessCheck` | успешно, изменений после нет |
| Механические проверки `jmix-ide-static-analysis` по изменённым файлам | чисто: все четыре XML разбираются парсером, все `msg://` новых экранов резолвятся в `messages_ru.properties`, неиспользуемых новых ключей нет, `package` совпадает с каталогом, 0-байтовых файлов нет |
| `./gradlew :app:test --tests "ru.fgk.ws.app.container.ContainerSurveyIT" --tests "ru.fgk.ws.app.container.view.ContainerSurveyViewsUiTest" --tests "ru.fgk.ws.app.container.security.ContainerRolesTest"` | 11 passing, 0 failing |
| `./gradlew :app:test --tests "ru.fgk.ws.app.container.*" --tests "ru.fgk.ws.app.common.exception.*"` (после правки XML) | 51 passing, 0 failing (было 45 у T06 + 6 новых) |
| Браузерный smoke под `user_edit`: создать из списка | контейнер найден по подстроке `26100`, вид по `РМРС`, исполнитель по `смоук` (регистр не важен); после «OK» в БД одна строка `cnt_survey` с `date_begin=2026-02-01`, `date_end=2026-02-03`, `date_next=2031-02-01`, `org_id`, непустым `survey_act` |
| Браузерный smoke: загрузка и просмотр акта | PDF ушёл в MinIO, просмотр переключился с заглушки на `iframe`, «Скачать акт» стала активной |
| Браузерный smoke: открыть из вкладки | вкладка «Освидетельствования» карточки `containers/632` показывает ровно эту запись («1 строка»), поля совпадают со списком |
| Браузерный smoke: создание из вкладки | диалог открывается с предустановленным `FGKU5026100`, у поля «Контейнер» атрибут `readonly`; «Отмена» ничего не записала (`cnt_survey` = 1 строка) |
| Дата реестра после smoke | `FGKU5026100` = 2027-03-15, `FGKU5026200` = 2028-11-01 — как заведены |

Не запускалось, оставлено проверяющему: полный `./gradlew :app:test`; полный
браузерный проход C1–C5, в том числе роли `user_read` и `user_nsi`, экспорт в
Excel с фильтром, копирование записи, замена и повторное скачивание акта,
перенос записи на другой контейнер из списка с проверкой обеих вкладок, мягкое
удаление, фильтры списка по датам и исполнителю.

## Для независимой проверки

Worktree `../worktrees/rvk-ws/cyan-fennel/rvk-ws`, ветка `f/container`, схема
`main_rvk_ws` в общем Docker PostgreSQL, порт приложения 8082 — параметры лежат
в `app/src/main/resources/application-local.properties` (файл не отслеживается
git, создан `system/worktree-setup.sh`). Требования к MinIO те же, что у T03:
строки `jmix.awsfs.*` в том же файле и существующий бакет `rvk-dev` (команда
создания — в `../T03/result.md`).

```bash
docker info && (cd docker && docker compose ps)
cd ../worktrees/rvk-ws/cyan-fennel/rvk-ws
./gradlew :app:test
./gradlew :app:bootRun            # порт 8082, ждать ответа на http://localhost:8082/
```

Пользователи для UI: `user_edit` / `edit123` (роль `container-edit`),
`user_read` / `read123` (роль `container-read`), `user_nsi` (роль
`container-nsi-edit`); вход через `/local-login`. Пользователя `user` в схеме
`main_rvk_ws` нет. Важно: `playwright-cli close` стирает данные сессии, после
чего адрес приложения редиректит на недоступный снаружи Keycloak — входить
нужно заново через `/local-login`.

Адреса: список — `http://localhost:8082/container-surveys` (меню «Контейнеры →
Освидетельствования контейнеров»), форма — `/container-surveys/:id`, вкладка —
в карточке `/containers/:id`, появляется только у сохранённого контейнера.

Данные после самопроверки удалены физически (`cnt_survey`, `cnt_survey_type`,
`cnt_container` и сеяная организация — 0 строк). Тот же набор, что использовала
самопроверка (каждый `INSERT` — отдельной командой: в psql несколько операторов
идут одной транзакцией, и ошибка последнего откатывает предыдущие):

```sql
insert into main_rvk_ws.cnt_container (version, cont_num, next_survey_date) values (1,'FGKU5026100','2027-03-15');
insert into main_rvk_ws.cnt_container (version, cont_num, next_survey_date) values (1,'FGKU5026200','2028-11-01');
insert into main_rvk_ws.cnt_survey_type (version, survey_type_name) values (1,'Периодическое освидетельствование РМРС');
insert into ws_store.ora_assb_org_passport_current (dwh_pk_id, org_id, recdatenew, okpo, name, shortname)
  values (990401, 990401, now(), '99040199', 'Акционерное общество «Смоук T04»', 'T04-ORG-SMOKE');
```

Два контейнера нужны для сценария переноса записи (C3): проверять дату
следующего освидетельствования стоит запросом к БД, а не по форме —
`select cont_num, next_survey_date from main_rvk_ws.cnt_container`. Тестовый PDF
для акта подойдёт любой; smoke использовал сгенерированный файл во временном
каталоге сессии, в репозиторий он не попал.

## Ограничения и связанные изменения

- **Заглушка «файл не загружен» показывает битую картинку — дефект не T04.**
  У записи без акта просмотр выводит заголовок «Акт освидетельствования не
  загружен» и иконку `img/filetype/fileNotFound.png`, а все адреса
  `/img/filetype/*.png` отдают 403 даже вошедшему пользователю (проверено
  `fetch` из браузера: `docFileType.png` и `fileNotFound.png` — оба 403). Это
  общий для приложения фрагмент `common/view/displayfile/DisplayFile` и общая
  настройка статики в `app/security`, то есть то же самое во вкладке «Файлы»
  T03 и в копиях документов договора. Правка лежит вне области T04, поэтому
  здесь не делалась; текст заголовка отрисовывается, просмотр настоящего PDF
  работает.
- Локальная `main.nsi_v_org_passport` пуста; поиск исполнителя проверен на
  одной сеяной записи, на реальном объёме организаций — нет.
- Gate 1 выполнен откатом на `compileJava` плюс механические проверки:
  Jmix-осведомлённой IDE-инспекции (`get_file_problems`) в сессии не было.
  Четыре новых `*.xml` и три новых `*.java` стоит переинспектировать в сессии,
  где инспекция доступна.
- T03 затронут добавлением вкладки в `container-detail-view.xml` и вызова
  `surveysFragment.refresh()` в `ContainerDetailView`. Прежнее поведение
  карточки не менялось, `:app:test` по контейнерному пакету проходит целиком,
  поэтому `done` у T03 остаётся в силе; вкладка «Освидетельствования» — новый
  элемент карточки, которого прежняя проверка T03 не видела.
- T02 затронут добавлением строк в роли и в `ContainerRolesTest`; прежние
  проверки роли не меняются.
- T07 предупреждён двумя находками в `contracts.md`: `parameterName` для
  фильтра по номеру контейнера и `scroller` для формы с просмотром файла.
