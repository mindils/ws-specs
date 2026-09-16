# T03 — rvkFilter на 13 справочниках контейнеров

Статус: todo
План: [../../plan.md](../../plan.md)
Зависимости: нет
Сложность: easy — один повторяемый XML-паттерн по образцу `v-depo-list-view.xml`, без Java
Сложность проверки: medium — 13 view открываются UI-тестом, плюс ручной сценарий в браузере
Актуальная проверка: нет

## Коротко

На 13 списках справочников раздела «Контейнеры» (модели, типы, размеры,
характеристики, типы свойств и файлов, виды освидетельствований и ремонтов,
причины и виды брака, типы актов, договоров, гарантий) панель с одним
текстовым `propertyFilter` заменяется на `flt:rvkFilter` со строкой поиска по
названию и полями по всем колонкам грида. По результату у каждого справочника
одинаковый фильтр с поиском, условиями и личными пресетами.

## Результат и контекст

Файлы: `app/src/main/resources/ru/fgk/ws/app/container/view/cnt*/cnt-*-list-view.xml`
(13 штук, у всех одинаковая структура: `formLayout id="filterPanel"` с
`propertyFilter id="nameFilter"`). Контроллеры `Cnt*ListView.java` не
меняются. Поля названия и правила — раздел «Страницы» плана.

## Область и изоляция

Только 13 XML справочников и ключи `messages_ru.properties`, относящиеся к
ним (сейчас у справочников своих ключей `filter.*` нет; новые ключи нужны
только если подпись из метаданных не подходит). Параллельно с T01 и T02;
`messages_ru.properties` перечитывать перед правкой и менять только свои
ключи. Общие ресурсы: БД, gradle daemon при тестах — проверки после T01.

## Реализация

1. Прочитать skills `jmix-create-list-view`, `jmix-add-i18n-keys`,
   `jmix-ide-static-analysis`; открыть образец
   `nsi/view/vdepo/v-depo-list-view.xml` и шаблон в плане.
2. В каждом XML: добавить `xmlns:flt="http://fgk.ru/schema/rvk-filter"`,
   удалить `formLayout id="filterPanel"` целиком, перед `buttonsPanel`
   поставить `<flt:rvkFilter id="rvkFilter" dataLoader="<loaderId>"
   searchProperty="<поле названия>" width="100%">` с `flt:filters`: поле
   названия `defaultVisible="true"`, остальные колонки грида — скрытые поля
   (`Long` → по метаданным, `String` → текст; `CntDefect.defectReason` —
   путь `defectReason.defectReasonName` с явным `label`, ключ в messages по
   правилу `<пакет view>/cntDefectListView.filter.defectReason`).
3. Не задавать `configurationKey`, `enableSavedFilters`, `css`.
4. Проверить каждый файл IDE-инспекцией или `compileJava` плюс
   механические проверки; убедиться, что ни один XML не пуст.

## Критерии приёмки

- C1: все 13 списков открываются (`ContainerNsiViewsUiTest`), в каждом есть
  `rvkFilter` с поиском по полю названия и без старой панели.
- C2: поиск по подстроке названия фильтрует грид, Reset возвращает полный
  список (ручной сценарий на «Модели контейнеров» и «Виды ремонта»).
- C3: сырых `msg://` нет; в `messages_ru.properties` нет неиспользуемых
  ключей, добавленных или оставленных этим таском.

## Самопроверка исполнителя

```bash
./gradlew spotlessApply :app:compileJava
./gradlew :app:test --tests 'ru.fgk.ws.app.container.view.ContainerNsiViewsUiTest'
```

Плюс `grep -L 'flt:rvkFilter'` по 13 файлам (должен быть пуст) и
`grep -l 'filterPanel'` (должен быть пуст). Браузер не обязателен.

## Независимая проверка

- `./gradlew :app:test --tests 'ru.fgk.ws.app.container.*'` и
  `./gradlew spotlessCheckAll`.
- Браузер (`bootRun` в фоне, `/actuator/health` UP, `playwright-cli`, вход
  `user`/`user` через `/local-login`): открыть 3–4 справочника из меню
  «Справочники → Контейнеры», ввести подстроку в поиск — грид сужается;
  добавить условие по второй колонке (например `CntModel.tenty`); Reset;
  сохранить личный пресет. Ошибок в серверном логе и сырых `msg://` нет.
  Без браузера — `render not browser-verified`.
- Регрессия: detail-диалоги справочников открываются
  (`ContainerNsiViewsUiTest` второй тест).

## Прогресс и продолжение

- [ ] 13 XML переведены на `rvkFilter`.
- [ ] Ключи messages согласованы.
- [ ] Передать результат на независимую проверку.

Ближайший шаг: открыть `cnt-model-list-view.xml` и образец VDepo.
Препятствия: нет
