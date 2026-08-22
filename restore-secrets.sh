#!/bin/bash
# Восстанавливает секреты, которых сознательно нет в этом репозитории.
#
# Репозиторий публичный, поэтому в нём не хранится ни одного секрета — ни в
# открытом виде, ни в зашифрованном. Раньше их шифровал age, а приватный ключ
# лежал отдельно; теперь секреты просто лежат отдельно, и один слой отпадает.
#
# Использование:
#   ./restore-secrets.sh /path/to/backup/secrets
#
# Ожидаемое содержимое каталога с бэкапом (лишние файлы игнорируются,
# отсутствующие — пропускаются с предупреждением):
#
#   rclone.conf     ->  ~/.config/rclone/rclone.conf    0600
#   atuin-key       ->  ~/.local/share/atuin/key        0600
#   id_ed25519_gh   ->  ~/.ssh/id_ed25519_gh            0600
#
# Права выставляются явно: chezmoi больше не делает это за нас (он делал это
# через префикс private_, когда секреты жили в репозитории).

set -euo pipefail

if [ $# -ne 1 ]; then
  echo "Usage: $0 <каталог-с-секретами>" >&2
  exit 1
fi

SRC="${1%/}"
[ -d "$SRC" ] || { echo "!! Нет такого каталога: $SRC" >&2; exit 1; }

# исходное_имя|целевой_путь
ITEMS=(
  "rclone.conf|$HOME/.config/rclone/rclone.conf"
  "atuin-key|$HOME/.local/share/atuin/key"
  "id_ed25519_gh|$HOME/.ssh/id_ed25519_gh"
)

missing=0
for item in "${ITEMS[@]}"; do
  IFS='|' read -r name dest <<< "$item"
  src="$SRC/$name"

  if [ ! -f "$src" ]; then
    echo "!! пропускаю: в бэкапе нет $name"
    missing=$((missing + 1))
    continue
  fi

  mkdir -p "$(dirname "$dest")"
  install -m 600 "$src" "$dest"
  echo "ok  $name -> $dest (0600)"
done

echo
if [ "$missing" -gt 0 ]; then
  echo "Готово, но $missing файл(ов) не найдено — проверьте каталог бэкапа."
  exit 1
fi
echo "Готово: все секреты на месте."
