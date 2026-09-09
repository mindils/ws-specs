# Продолжение задач аддона — 2026-09-08

[К плану](README.md) · [Полный отчёт и пофайловая статика](../../../rvk-filter/docs/continuation-verification.md)

Продолжены F02/F03/F07. Новых страниц в rvk-ws нет: M001, M002, M003 и N002;
136 остальных остаются в [бэклоге](13-pages-backlog.md).

Добавлены 13 фиксированных property-операций, valueList для UUID/чисел, корневые Studio
metadata. Исправлены UUID equality, буквальный LIKE и полный applied-list (включая
схлопывание области chips на длинной форме). Обновлены XML/Java API, XSD, en/ru,
examples и tests. AND/OR, reference sources, выбор операции и поставка остаются открыты.

Аддон: 496 passed на PostgreSQL, без пропусков и ошибок; publishToMavenLocal выполнен.
qa подтвердил пять production Lit fixtures, valueList/Enter/дедупликацию/снятие chip,
полный список chips и ширину 360px. Это standalone transport fixtures; результаты
финального app:test: 1196 passed, 9 skipped, 0 failures/errors; compileJava и
spotlessCheckAll PASS. Host-проход qa 2026-09-09: PASS на четырёх страницах под Lumo,
Apply/Reset, чипы и dropdown; 360px без overflow, admin list открывается.
Вход — local-login/FullAccess. У причин отклонения 0 строк, проверен только UI state;
для остальных трёх страниц подтверждено изменение выборки. /actuator/health:
302 без входа, 403 после входа; UP не подтверждён. Точные доказательства и
ограничения — в полном отчёте; весь F11 этим не закрыт.

Сверены и отмечены уже выполненные до этой сессии typed JPQL/IN, configurationKey,
en/ru, пресеты и startup definitions. Статусы F02–F07 обновлены без возврата страниц
из бэклога. В этом checkout specs/.git отсутствует, пакет исключён из главного Git:
документы записаны на диск; git-настройки и вложенные репозитории не создавались.
