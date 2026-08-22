# dotfiles

Конфигурация macOS на базе chezmoi + Homebrew.

> **Репозиторий публичный и секретов не содержит — ни в открытом виде, ни в зашифрованном.**
> Всё чувствительное живёт вне git и восстанавливается отдельно: см.
> [«Секреты вне репозитория»](#секреты-вне-репозитория) и `restore-secrets.sh`.

## Что управляется

**CLI-инструменты** (Brewfile):
`age` `bat` `btop` `curl` `eza` `fzf` `gh` `rclone` `ripgrep` `rsync` `yazi` `zoxide`

**Shell:**
`zsh` `antidote` `starship` `atuin`

**Dotfiles-менеджер:**
`chezmoi`

**GUI-приложения** (Brewfile casks):
`Ghostty` `JetBrains Mono Nerd Font` `Arc` `Claude` `Claude Code` `Easydict` `IINA` `Karabiner-Elements` `Zed`

**Конфиги** (chezmoi):
- zsh — `.zshrc` + `conf.d/` (конфиг каждого инструмента в своём файле, включается через `command -v`
  в рантайме, а не на этапе `chezmoi apply`), `.zprofile`, `.zshenv` (XDG + `ZDOTDIR`), плагины в две фазы
- git — identity (`name`/`email` из `.chezmoi.toml.tmpl`), глобальный `.gitignore`, современные дефолты
  (`push.autoSetupRemote`, `rebase.autoStash`, `rerere`, `zdiff3`), SSH-подпись коммитов — настроена,
  но выключена (см. комментарий в `dot_config/git/config.tmpl`)
- ripgrep — `--smart-case` и игнор `.git/` через `RIPGREP_CONFIG_PATH`
- starship — тема Catppuccin Mocha
- atuin — настройки и тема Catppuccin Mocha Mauve (ключ E2E-шифрования — вне репозитория)
- ghostty — шрифт, тема, quick-terminal
- btop — конфиг + тема Catppuccin Mocha
- bat — конфиг + тема Catppuccin Mocha + синтаксис antidote
- zed — `settings.json`
- Claude Code — глобальный `settings.json` (не проектные `.claude/`: `theme`, `tui`, `model`, `language`, `voice`)
- Karabiner-Elements — `karabiner.json` (тап левого/правого Cmd переключает раскладку), подробности и ручное
  восстановление разрешений macOS — в `karabiner-recovery.md`
- ssh — публичный ключ и `~/.ssh/config` (приватный ключ в репозитории не хранится)
- macOS system defaults — Finder/Dock/меню-бар/системный звук, применяется скриптом при `chezmoi apply`
- `~/dev/{sandbox,gh}`, `~/sync/obsidian` — пустые каталоги-заготовки

**Темы** (скачиваются при `chezmoi apply`):
Catppuccin Mocha для bat, btop, atuin — из официальных репозиториев catppuccin.

## Структура

```
dotfiles/
├── .chezmoi.toml.tmpl                       # конфиг chezmoi (генерируется при init)
├── .chezmoiignore                           # что НЕ применять в $HOME (README, Brewfile, CLAUDE*, .keep)
├── .chezmoiversion                          # минимальная версия chezmoi
├── .chezmoiexternal.toml                    # темы Catppuccin: chezmoi качает и кэширует их сам
├── .chezmoiscripts/                         # скрипты; не создают записей в целевом каталоге
│   ├── run_onchange_after_10-install-brewfile.sh.tmpl  # brew bundle (Homebrew — предусловие)
│   ├── run_onchange_after_20-rebuild-bat-cache.sh.tmpl # bat cache --build после тем и синтаксисов
│   └── run_onchange_after_30-set-macos-defaults.sh.tmpl # defaults write, идёт последним
├── Brewfile                                  # список CLI-пакетов и GUI-приложений (casks)
├── restore-secrets.sh                        # раскладывает секреты из бэкапа (их нет в репозитории)
├── CLAUDE.md / CLAUDE.ru.md                  # инструкции для Claude Code (англ/рус)
├── karabiner-recovery.md                     # ручное восстановление разрешений macOS для Karabiner-Elements
├── dot_zshenv                                # → ~/.zshenv
├── dev/{sandbox,gh}/.keep                    # → ~/dev/{sandbox,gh} (пустые; .keep в .chezmoiignore)
├── sync/obsidian/.keep                       # → ~/sync/obsidian (пустой)
├── dot_claude/settings.json                  # → ~/.claude/settings.json (глобальный, не проектный)
├── private_dot_ssh/
│   ├── id_ed25519_gh.pub                     # → ~/.ssh/id_ed25519_gh.pub (публичный, не секрет)
│   └── config                                # → ~/.ssh/config
└── dot_config/
    ├── zsh/
    │   ├── dot_zshrc              # → ~/.config/zsh/.zshrc (две фазы conf.d + compinit между ними)
    │   ├── conf.d/                # → ~/.config/zsh/conf.d/ — по файлу на инструмент,
    │   │   ├── antidote-pre.zsh   #   каждый сам решает, включаться ли (command -v/[[ -d ]] в
    │   │   ├── antidote-post.zsh  #   первой строке) — работает независимо от порядка установки
    │   │   ├── atuin.zsh
    │   │   ├── bat.zsh
    │   │   ├── eza.zsh
    │   │   ├── rg.zsh
    │   │   ├── starship.zsh
    │   │   └── zoxide.zsh
    │   ├── dot_zprofile             # → ~/.config/zsh/.zprofile
    │   ├── dot_zsh_plugins.txt      # → ~/.config/zsh/.zsh_plugins.txt (фаза 1, kind:fpath)
    │   └── dot_zsh_plugins_post.txt # → ~/.config/zsh/.zsh_plugins_post.txt (фаза 2)
    ├── git/
    │   ├── config.tmpl            # → ~/.config/git/config (name/email из data)
    │   └── ignore                 # → ~/.config/git/ignore (глобальный .gitignore)
    ├── starship/starship.toml
    ├── private_atuin/private_config.toml
    ├── zed/private_settings.json
    ├── ghostty/config.ghostty
    ├── karabiner/karabiner.json
    ├── btop/btop.conf
    ├── ripgrep/config             # → ~/.config/ripgrep/config (через RIPGREP_CONFIG_PATH)
    └── bat/
        ├── config
        └── syntaxes/zsh_plugins.sublime-syntax
```

## Восстановление на чистой системе

> **Что нужно иметь под рукой.** Только каталог с секретами из резервной копии
> (1Password/Google Drive) — `rclone.conf`, `atuin-key`, `id_ed25519_gh`. Ни ключа шифрования,
> ни токена для клонирования: репозиторий публичный, читается и клонируется без авторизации.

### 1. Xcode Command Line Tools
```bash
xcode-select --install
```
**Дождитесь окончания установки** (открывается отдельное окно, минуты) и проверьте:
```bash
git --version
```
Это не формальность. У chezmoi `useBuiltinGit = "auto"`: встроенный git используется, только если
`git` не найден в `$PATH`, и он заметно ограниченнее системного. Проще убедиться, что CLT на месте,
чем разбираться потом.

### 2. Homebrew
```bash
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
```
**Установщик спросит пароль администратора** — он нужен, чтобы создать `/opt/homebrew`.

Homebrew намеренно вынесен в предусловие, а не ставится изнутри chezmoi. Скрипт, который сам
запрашивает `sudo`, — плохой паттерн: непонятно, что именно потребует привилегий. Здесь пароль
спрашивает официальный установщик Homebrew, в вашем терминале, и это единственное место в
процедуре, где он нужен для системных изменений.

После установки выполните строчку `eval "$(...)"`, которую напечатает установщик, — иначе `brew`
не окажется в `$PATH` текущей сессии.

### 3. Применить всё одной командой
```bash
sh -c "$(curl -fsLS get.chezmoi.io)" -- init --apply \
  https://github.com/rajivgeraev/dotfiles-public.git
```
Выполнится автоматически, по порядку:
1. поставит chezmoi и склонирует репозиторий (авторизация не нужна — репозиторий публичный)
2. создаст все конфиги в `~/.config/` и скачает темы Catppuccin (`.chezmoiexternal.toml`)
3. `run_onchange_after_10-install-brewfile.sh.tmpl`: поставит весь Brewfile — CLI-инструменты и
   GUI-приложения. **Один раз спросит пароль администратора** на каске `karabiner-elements`: он
   единственный из девяти ставится через `.pkg`, остальные — обычные `.app` и привилегий не требуют
4. `run_onchange_after_20-rebuild-bat-cache.sh.tmpl`: пересоберёт кеш bat
5. `run_onchange_after_30-set-macos-defaults.sh.tmpl`: применит настройки macOS
   (Finder/Dock/меню-бар/звук), идёт последним

Числовые префиксы `10-`/`20-`/`30-` задают порядок явно, а не через алфавитную сортировку имён.

> **Конфиги применяются раньше пакетов — так и задумано.** Если `brew bundle` частично упадёт
> (обычно из-за сети), restore не прервётся: конфиги уже на диске, а недоустановленный инструмент
> просто не включится, потому что `conf.d/*.zsh` гейтят каждый через `command -v` при запуске шелла.
> Скрипт напечатает предупреждение и команду для повторной попытки.

Ничего повторно запускать не нужно — `.zshrc`/`conf.d/*.zsh` гейтят каждый инструмент через
`command -v` в момент запуска шелла, а не на этапе `apply`, так что корректно собираются с первого
раза независимо от того, что именно успело установиться к моменту рендера.

> 💡 Этот шаг может выглядеть «зависшим» надолго — Brewfile ставит десяток GUI-приложений, и это самая долгая
> часть (особенно в VM с медленной сетью, как UTM). Чтобы видеть прогресс, а не тишину — `-v`:
> ```bash
> sh -c "$(curl -fsLS get.chezmoi.io)" -- init https://github.com/rajivgeraev/dotfiles-public.git
> ./bin/chezmoi apply -v
> ```
> `-v` печатает содержимое каждого скрипта перед запуском и diff по каждому файлу; сам
> `run_once_before_install-brewfile.sh.tmpl` тоже запускает `brew bundle --verbose`, так что видно
> каждый пакет построчно. Если всё равно кажется, что зависло — в другом окне терминала
> `ps aux | grep -E 'brew|curl'`: если процессы есть, значит просто качает.

### 4. Восстановить секреты из резервной копии
В репозитории их нет, поэтому раскладываем вручную — одной командой, с правильными правами:
```bash
~/.local/share/chezmoi/restore-secrets.sh /path/to/backup/secrets
```
Скрипт ждёт каталог с тремя файлами и раскладывает их с режимом `0600`:

| в бэкапе | куда | зачем |
|---|---|---|
| `rclone.conf` | `~/.config/rclone/rclone.conf` | удалённые хранилища |
| `atuin-key` | `~/.local/share/atuin/key` | E2E-ключ истории (шаг 6) |
| `id_ed25519_gh` | `~/.ssh/id_ed25519_gh` | ключ для GitHub |

Права выставляются явно: раньше это делал chezmoi через префикс `private_`, пока секреты лежали
в репозитории.

Публичный ключ (`~/.ssh/id_ed25519_gh.pub`) и `~/.ssh/config` восстановились шагом 3 — они не секретны.
После этого шага `git push` в репозиторий работает по SSH.

### 5. Переключить origin на SSH
`init` склонировал по HTTPS, что для публичного репозитория нормально, но для записи нужен SSH —
ключ уже на месте после шага 4:
```bash
git -C ~/.local/share/chezmoi remote set-url origin git@github.com:rajivgeraev/dotfiles-public.git
```

### 5a. Проверить результат
**Откройте новое окно терминала.** Установщик `get.chezmoi.io` кладёт бинарник в `./bin/chezmoi`
относительно текущего каталога, а не в `$PATH`; полноценный `chezmoi` появляется из Brewfile в
`/opt/homebrew/bin`, и этот путь попадает в `$PATH` только через `.zprofile` — то есть в новом шелле.

```bash
chezmoi doctor   # диагностика окружения chezmoi
chezmoi verify   # сверяет $HOME с source state, код возврата 0 = всё ок
```

> ⚠️ `chezmoi verify` считает расхождением и **невыполненные скрипты**, а не только несовпавшие файлы.
> После полного `init --apply` они уже отработали, поэтому там ожидается 0. Если код возврата 1 —
> сначала посмотрите `chezmoi status`: строки с `R` в первой колонке означают «скрипт ждёт запуска»
> (обычное дело после `apply --exclude=scripts`), а `MM` — настоящее расхождение файла.
> Отделить одно от другого: `chezmoi verify --exclude=scripts`.

### 6. Войти в Atuin (история шелла из облака)
История зашифрована end-to-end ключом, который лежит только локально (`~/.local/share/atuin/key`,
восстанавливается шагом 4). Без ключа `atuin login` не расшифрует историю, даже зная пароль.
Пароль от аккаунта в репозитории **не хранится** (у CLI нет входа по токену — только `-u`/`-p`/`-k`, проверено
на актуальной версии) — вводится вручную при запуске:
```bash
atuin login -u rajivgeraev -k "$(cat ~/.local/share/atuin/key)"
atuin sync
```
Пароль спросится интерактивно. `atuin login` формально должен запускать синк автоматически, но неявно и не
сразу (следующий периодический синк — раз в 5 минут). Явный `atuin sync` сразу после логина гарантированно
подтягивает всю историю сейчас, а не когда-нибудь.

### 7. Открыть Ghostty
При первом запуске antidote автоматически скачает zsh-плагины.

### 8. Karabiner-Elements: выдать разрешения macOS
Сам конфиг уже восстановлен шагом 3, но Accessibility и Driver Extensions выдаются только вручную,
через System Settings — см. раздел [«Karabiner-Elements»](#karabiner-elements-переключение-раскладки-по-cmd)
ниже и подробный разбор в [`karabiner-recovery.md`](karabiner-recovery.md).

### 9. Продолжить настройку через Claude Code
```bash
cd ~/.local/share/chezmoi
claude
```
`CLAUDE.md` в этом каталоге инструктирует Claude Code восстановить свою память о возможностях chezmoi
(она не хранится в git и на новой машине пустая) прежде чем продолжать менять конфигурацию — просто
начни новую задачу, остальное распишет само.

## Рабочий процесс

```bash
# Редактировать конфиг (открывает источник в редакторе)
chezmoi edit ~/.config/zsh/.zshrc

# Применить изменения
chezmoi apply

# Посмотреть что изменится
chezmoi diff

# Добавить новый файл
chezmoi add ~/.config/something

# Обновить из репозитория
chezmoi update
```

## Karabiner-Elements: переключение раскладки по Cmd

Тап левого Cmd → русская раскладка, тап правого Cmd → английская (идемпотентно, повторный тап не переключает
обратно). Сам конфиг (`~/.config/karabiner/karabiner.json`) восстанавливается автоматически через chezmoi, cask
ставится через `brew bundle` — но macOS требует ручной выдачи разрешений (Accessibility, Driver Extensions) и
добавления раскладки "Russian - PC" через System Settings, это не автоматизируется. Пошагово — в
[`karabiner-recovery.md`](karabiner-recovery.md).

## Секреты вне репозитория

Репозиторий публичный, поэтому секретов в нём нет **вообще** — ни открытым текстом, ни зашифрованными.
Шифрование защищает содержимое, но не отменяет того, что шифротекст, однажды опубликованный, скачивается
навсегда и расшифровывается задним числом при любой будущей утечке ключа. Проще не публиковать его совсем.

### Что считается секретом

| Файл | Почему |
|---|---|
| `~/.config/rclone/rclone.conf` | токены и пароли к удалённым хранилищам |
| `~/.local/share/atuin/key` | ключ E2E-шифрования истории команд |
| `~/.ssh/id_ed25519_gh` | приватный SSH-ключ |

Все три хранятся в менеджере паролей и раскладываются `restore-secrets.sh` (см. шаг 4 восстановления).
Публичная часть ключа и `~/.ssh/config` секретами не являются и лежат в репозитории как обычные файлы.

### Правило при добавлении нового конфига

Прежде чем сделать `chezmoi add`, откройте файл и убедитесь, что в нём нет токенов, паролей, приватных
ключей и имён удалённых хостов. Если есть — файл не добавляется в этот репозиторий; секрет отправляется
в менеджер паролей, а его путь дописывается в `ITEMS` внутри `restore-secrets.sh`.

Это же касается вещей, которые не выглядят секретом, но выдают инфраструктуру: имена rclone-remote'ов,
адреса серверов, названия облачных провайдеров.

### Если решим вернуть шифрование

`age` остаётся в `Brewfile`, так что вернуться можно в любой момент: добавить `encryption = "age"` и
секцию `[age]` в `.chezmoi.toml.tmpl`, затем `chezmoi add --encrypt`. Но для публичного репозитория
это осознанный шаг назад — см. рассуждение выше.
