#!/bin/bash

# Változó a szkript első argumentumához
TARGET_DIR="$1"

# Ellenőrzés: Hiba, ha a könyvtár nem volt megadva
if [ -z "$TARGET_DIR" ]; then
  echo "Error: No directory provided"
  exit 1
fi

echo "Fixing permissions in $TARGET_DIR..."

# Biztonságossá teszi a .txt fájlokat: Csak a user ír/olvas, mindenki más csak olvas (644)
find "$TARGET_DIR" -name '*.txt' -exec chmod 644 {} \;

# Biztonságossá teszi a .sh fájlokat: Csak a user ír/olvas/futtat, mindenki más kizárva (700)
find "$TARGET_DIR" -name '*.sh' -exec chmod 700 {} \;

# Hozzáfűzi az aktuális dátumot az audit.log fájlhoz
echo "[$(date +%Y-%m-%d)] Permissions fixed for $TARGET_DIR" >> audit.log

echo "Done. Check audit.log for details."

# Futtatási jog hozzáadása
chmod +x fix_system.sh

# Tesztelés
./fix_system.sh evidence
# Ellenőrzés: ls -l evidence
# .txt fájloknak rw-r--r-- (644), .sh fájloknak rwx------ (700) kell lenniük.