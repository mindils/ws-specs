# 01. Пакет, меню и экран настроек Case.one

> **Этап 1.** Первая задача целиком: завести домен и дать экран, куда вводятся адрес Case.one,
> логин и пароль. Никаких таблиц-зеркал, никакой синхронизации.

## Результат задачи

Пользователь заходит в меню «Претензионная и судебная работа» → «Case.one» → «Настройки»,
вводит URL / логин / пароль, сохраняет. Значения лежат в БД, пароль — зашифрованным.

## 1. Доменный пакет

```
app/src/main/java/ru/fgk/ws/app/legal/
├── caseone/
│   ├── entity/          CaseOneSettings
│   ├── service/         CaseOneCryptoService, CaseOneSettingsService
│   └── view/settings/   CaseOneSettingsView
└── security/            LegalCaseOneAdminRole
```

Ресурсы — зеркально:
`app/src/main/resources/ru/fgk/ws/app/legal/caseone/view/settings/case-one-settings-view.xml`

Остальные подпакеты (`config`, `controller`, `dto`) заводятся в задаче 02 по мере надобности —
пустых каталогов не создаём.

### Именование

- Java-пакет: `ru.fgk.ws.app.legal`, интеграция — `ru.fgk.ws.app.legal.caseone`.
- Имя сущности Jmix — с префиксом домена, как `diadoc_DiadocDocument`
  (`app/src/main/java/ru/fgk/ws/app/diadoc/entity/DiadocDocument.java:17`):
  `@JmixEntity(name = "legal_CaseOneSettings")`.
- Таблица: `legal_caseone_settings`.
- ID экрана: `legal_CaseOneSettingsView`.

## 2. Меню

В `app/src/main/resources/ru/fgk/ws/app/menu.xml` — новый корневой пункт рядом с `contract_work`:

```xml
<menu id="legal"
      title="msg://ru.fgk.ws.app.legal/menu.legal"
      description="msg://ru.fgk.ws.app.legal/menu.legal">
  <menu id="legal_caseone"
        title="msg://ru.fgk.ws.app.legal/menu.caseone"
        description="msg://ru.fgk.ws.app.legal/menu.caseone">
    <item view="legal_CaseOneSettingsView"
          title="msg://ru.fgk.ws.app.legal.caseone.view.settings/caseOneSettingsView.title"
          description="msg://ru.fgk.ws.app.legal.caseone.view.settings/caseOneSettingsView.title"/>
  </menu>
</menu>
```

Второй пункт («Проверка API») добавляется в задаче 02.

## 3. Сущность `CaseOneSettings`

`app/src/main/java/ru/fgk/ws/app/legal/caseone/entity/CaseOneSettings.java`,
таблица `legal_caseone_settings`. Обычная таблица → `Long id` + `GenerationType.IDENTITY`
(дефолт из `CLAUDE.md`). Строка в таблице **ровно одна**.

Lombok — только `@Getter`/`@Setter`. Описания полей — `@Comment`, как в
`app/src/main/java/ru/fgk/ws/app/nsi/entity/NsiNds.java`. `@InstanceName` — на `baseUrl`.

| Колонка | Тип | Назначение |
|---|---|---|
| `id` | BIGINT identity | PK |
| `base_url` | varchar(500) | напр. `http://case.main.vgk` (без завершающего `/`) |
| `username` | varchar(255) | логин технической учётки |
| `password_enc` | varchar(1000) | шифротекст с префиксом `enc:` |
| `enabled` | boolean, default false | глушилка интеграции целиком |
| `page_size` | int, default 200 | размер страницы при выгрузке (пригодится в задаче 04) |
| `connect_timeout_ms` | int, default 10000 | таймаут соединения |
| `read_timeout_ms` | int, default 120000 | таймаут чтения |
| `last_check_at` | timestamptz | когда последний раз жали «Проверить подключение» |
| `last_check_result` | varchar(1000) | результат проверки (OK / текст ошибки) |

## 4. `CaseOneCryptoService`

`app/src/main/java/ru/fgk/ws/app/legal/caseone/service/CaseOneCryptoService.java`

Обёртка над `org.springframework.security.crypto.encrypt.Encryptors.delegatingText(key, salt)`.
`spring-security-crypto` уже на classpath (транзитивно через `jmix-security-starter`) —
новых зависимостей не нужно.

```java
String encrypt(String raw);      // -> "enc:" + шифротекст
String decrypt(String stored);   // принимает "enc:..." ; без префикса -> IllegalStateException
boolean isConfigured();          // ключ задан?
```

В `app/src/main/resources/application.properties`:

```properties
# Case.one
rvk.caseone.secret-key=${CASEONE_SECRET_KEY:}
rvk.caseone.secret-salt=5c0744940b5c369b
```

Правила:
- Ключ пустой → при старте `log.warn` (приложение поднимается: интеграция может быть выключена),
  а `encrypt`/`decrypt` кидают понятное исключение с текстом «не задан `CASEONE_SECRET_KEY`».
- Префикс `enc:` обязателен — по нему отличаем зашифрованное значение от возможного legacy.
- Открытый текст в колонку не пишем **никогда**, даже как fallback.
- Соль — hex-константа в properties (не секрет, но менять нельзя: сломает расшифровку).

## 5. `CaseOneSettingsService`

`app/src/main/java/ru/fgk/ws/app/legal/caseone/service/CaseOneSettingsService.java`
Единственная точка чтения настроек в приложении. Constructor injection, без field `@Autowired`.

```java
CaseOneSettings getSettings();                              // создаёт строку с дефолтами, если её нет
String getDecryptedPassword();
void savePassword(CaseOneSettings s, String rawPassword);   // шифрует и кладёт в поле
boolean isEnabled();
```

Настройки читаются на каждый вызов (строка одна, запрос дешёвый) — изменение в UI
подхватывается без рестарта. Кешировать не нужно.

## 6. Экран `CaseOneSettingsView`

`app/src/main/java/ru/fgk/ws/app/legal/caseone/view/settings/CaseOneSettingsView.java`
+ `.../view/settings/case-one-settings-view.xml`

Тип — `StandardView` (не пара list/detail: строка одна, список не нужен).

```java
@Route(value = "legal/caseone-settings", layout = MainView.class)
@ViewController(id = "legal_CaseOneSettingsView")
@ViewDescriptor(path = "case-one-settings-view.xml")
```

Состав:

| Компонент | Поле |
|---|---|
| `textField` | `baseUrl`, `username` |
| `passwordField` | пароль — **значение не подставляется**, поле всегда пустое при открытии; пустое при сохранении = «не менять пароль» |
| `checkbox` | `enabled` |
| `integerField` | `pageSize`, `connectTimeoutMs`, `readTimeoutMs` |
| read-only метки | `lastCheckAt`, `lastCheckResult` |
| кнопка | **«Сохранить»** |
| кнопка | **«Проверить подключение»** — появляется в задаче 02, когда есть токен-сервис |

Уведомления — через `ru.fgk.ws.core.util.DefaultNotification`, как в остальном проекте.

> Кнопка «Проверить подключение» относится к задаче 02 (нужен `CaseOneTokenService`).
> В задаче 01 её можно сразу разместить в разметке, но обработчик добавить в 02 —
> либо не добавлять вовсе и внести вместе с кодом.

## 7. Liquibase

`app/src/main/resources/ru/fgk/ws/app/liquibase/changelog/01-tbl/tbl-legal_caseone_settings.xml`

По образцу `.../01-tbl/tbl-diadoc_sign_settings.xml`:
`runOnChange="true"` + `<preConditions onFail="MARK_RAN"><not><tableExists .../></not></preConditions>`.
Файл подхватывается автоматически через `includeAll` в
`app/src/main/resources/ru/fgk/ws/app/liquibase/changelog.xml`.

`<addForeignKeyConstraint>` не использовать (запрет в `CLAUDE.md` §6).
Перед написанием — свериться со skill `jmix-liquibase`.

## 8. Роль

`app/src/main/java/ru/fgk/ws/app/legal/security/LegalCaseOneAdminRole.java`,
по образцу `app/src/main/java/ru/fgk/ws/app/security/DrContractReadRole.java`, `scope = "UI"`:

- код `legal-caseone-admin`;
- `@MenuPolicy` + `@ViewPolicy` на `legal_CaseOneSettingsView`;
- `@EntityPolicy(entityClass = CaseOneSettings.class, actions = EntityPolicyAction.ALL)`
  + `@EntityAttributePolicy(attributes = "*", action = MODIFY)`.

Атрибут `passwordEnc` доступен только этой роли.

## 9. i18n

Всё — в `app/src/main/resources/ru/fgk/ws/app/messages_ru.properties` (в модуле `app` других
locale-файлов нет). Хардкод-строк в UI быть не должно.

```properties
ru.fgk.ws.app.legal/menu.legal=Претензионная и судебная работа
ru.fgk.ws.app.legal/menu.caseone=Case.one
```
плюс название сущности, все её атрибуты, заголовок экрана, подписи кнопок, тексты уведомлений.

## Проверка

1. `./gradlew :app:test` — зелёный (регресс не сломан).
2. `./gradlew :app:bootRun` → миграция создала `main.legal_caseone_settings`.
3. В меню появился раздел «Претензионная и судебная работа» → «Case.one» → «Настройки».
4. Экран открывается, сохранение проходит.
5. Пароль зашифрован — MCP `rvk-ws`:
   ```sql
   select base_url, username, left(password_enc, 4) as prefix, length(password_enc)
     from main.legal_caseone_settings;
   ```
   Ожидаем `prefix = 'enc:'` и отсутствие исходного пароля в значении.
6. Тест `CaseOneCryptoServiceTest`: round-trip, префикс `enc:`, внятная ошибка при пустом ключе,
   значение без префикса отвергается.
