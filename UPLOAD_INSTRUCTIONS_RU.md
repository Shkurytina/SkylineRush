# Как обновить SkylineRush на GitHub одним заходом

1. Скачай ZIP `SkylineRush-v3-FULL.zip` и распакуй его. **Внутри архива сразу лежат `src`, `.github`, `docs` и файлы корня.**
2. Открой https://github.com/Shkurytina/SkylineRush и нажми `.` — откроется github.dev.
3. Перетащи **все файлы и папки из распакованного архива** в корень проводника github.dev. Подтверди замену существующих файлов. Не создавай вложенную `SkylineRush-v3`.
4. Проверь, что появились `src/shared/Economy.lua`, `tests/test_repository.py`, `docs/TEST_PLAN.md`, `.github/workflows/rojo-build.yml` и новый `README.md`.
5. Открой Source Control через `Ctrl+Shift+G`, введи `Release Skyline Rush v3 portfolio prototype` и нажми **Commit & Push** («Фиксация и отправка»).
6. Перейди на GitHub → **Actions** → **Validate and Build SkylineRush**. Убедись, что сборка зелёная, и что доступен артефакт `SkylineRush-place`.
7. Если сборка красная, открой первый упавший шаг и пришли текст ошибки. **Нельзя считать проект проверенным в движке только по зелёной CI-сборке.**

## Как дать ссылку работодателю

Ссылка на исходники: https://github.com/Shkurytina/SkylineRush

Работодатель может открыть последний запуск Actions, скачать `SkylineRush-place`, распаковать архив и открыть `.rbxlx` в Roblox Studio. В Studio при отсутствии доступа к DataStore будет показано уведомление о демонстрационном режиме; прогресс не сохраняется.

## Важно

CI проверяет структуру, парсинг Luau и генерирует Roblox Place. Без реального запуска в Roblox Studio остаются непроверенными интерактивность, физика, Roblox DataStore и мультиплеер.
