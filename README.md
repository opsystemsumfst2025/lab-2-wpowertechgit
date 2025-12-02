[![Review Assignment Due Date](https://classroom.github.com/assets/deadline-readme-button-22041afd0340ce965d47ae6ef1cefeee28c7c493a6346c4f15d667ab976d596c.svg)](https://classroom.github.com/a/eRdVNyPN)
# 2. Labor — Fájlrendszerek és Jogosultságok

Ez a labor a 2. szemináriumot ("Fájlrendszerek és Jogosultságok") tükrözi. Minden feladat a diákon tárgyalt tanulási célokhoz kapcsolódik.

**Kezdés:**

1. Klónozd le ezt a repository-t a Linux környezetedben (WSL2 / VM):
   ```bash
   git clone <repository-url>
   cd lab-02-security-breach
   ```
2. Futtasd a beállító szkriptet, hogy "elrontsd" a jogosultságokat:
   ```bash
   bash setup_lab.sh
   ```
3. Most kövesd az alábbi szakaszokat a javításhoz és automatizáláshoz.

---

## Mai Tanulási Célok

### 1. Koncepcionális Tudás (a "miért")

#### Az Egységes Gyökér Fa

Ellentétben a Windowsszal (ahol `C:\`, `D:\`, stb. van), a Linuxnak **egy gyökere** van: `/`.
Minden—a fájljaid, programjaid, még a hardver is—ebből az egyetlen pontból indul ki.

```
/
├── bin/        (alapvető parancsok, mint ls, cp)
├── home/       (személyes munkaterület)
│   └── student/
├── etc/        (konfigurációs fájlok)
├── proc/       (a kernel által generált virtuális fájlok)
└── var/        (naplók, ideiglenes adatok)
```

#### A Három Identitás

Minden Linux fájlt egy "kidobó" véd, aki háromféle látogatót ellenőriz:

1. **User (u)** — A tulajdonos (általában aki létrehozta a fájlt).
2. **Group (g)** — Felhasználók egy csoportja, akik megosztják a hozzáférést.
3. **Others (o)** — Mindenki más a rendszeren.

Minden identitásnak három jogosultsága lehet:

| Jogosultság      | Szimbólum | Oktális Érték | Jelentés                                                 |
| ----------------- | ---------- | ---------------- | --------------------------------------------------------- |
| **Read**    | `r`      | 4                | Fájl tartalmának megtekintése                          |
| **Write**   | `w`      | 2                | Fájl módosítása                                       |
| **Execute** | `x`      | 1                | Fájl futtatása programként (vagy könyvtárba lépés) |

#### Jogosultsági Matematika (Oktális Kód)

A jogosultságokat az értékek **összeadásával** számoljuk:

```
r (4) + w (2) + x (1) = 7  (teljes hozzáférés)
r (4) + w (2)         = 6  (olvasás/írás, nincs futtatás)
r (4)         + x (1) = 5  (olvasás/futtatás, nincs írás)
r (4)                 = 4  (csak olvasás)
                        0  (nincs hozzáférés)
```

**Vizuális Lebontás:**

Amikor látsz egy `-rwxr-xr--` stringet, így dekódold:

```
-  rwx  r-x  r--
│   │    │    │
│   │    │    └─── Others: r-- = 4 (csak olvasás)
│   │    └──────── Group:  r-x = 5 (olvasás + futtatás)
│   └───────────── User:   rwx = 7 (olvasás + írás + futtatás)
│
└───────────────── Típus: - = fájl, d = könyvtár
```

Tehát a `-rwxr-xr--` oktálisan **754**.

#### Futtatási Bit Könyvtárakon

**Kritikus különbség:**

- **Fájl `+x` bitel** → A kernel futtathatja programként.
- **Könyvtár `+x` bitel** → *Beléphetsz* `cd`-vel és hozzáférhetsz a benne lévő fájlokhoz.

`+x` nélkül egy könyvtáron, még ha olvasási jogod van is, nem tudsz `cd`-zni bele vagy megnyitni a fájljait.

#### Minden Fájl

Linuxban a hardver és a kernel adatok fájlként jelennek meg:

```bash
cat /proc/cpuinfo    # CPU információk (a kernel generálja futásidőben)
cat /proc/meminfo    # Memória statisztikák
ls /dev/sda          # A merevlemezed
```

Ezek nem tárolódnak a lemezen—a kernel hozza létre őket, amikor olvasod őket.

---

### 2. Gyakorlati Készségek (a "hogyan")

#### Útvonal Navigáció

**Abszolút útvonalak** a gyökértől indulnak:

```bash
/home/student/documents/lab02
```

**Relatív útvonalak** a jelenlegi helyzetedtől indulnak:

```bash
./documents/lab02    # a pont az "aktuális könyvtárat" jelenti
../lab01             # a dupla pont a "szülő könyvtárat" jelenti
```

**Rövidítések:**

- `~` = saját home könyvtárad (`/home/student`)
- `.` = aktuális könyvtár
- `..` = szülő könyvtár

#### Jogosultságok Módosítása

**Numerikus mód** (oktális):

```bash
chmod 755 script.sh    # rwxr-xr-x
chmod 640 secret.txt   # rw-r-----
```

**Szimbolikus mód** (ember által olvasható):

```bash
chmod u+x script.sh    # futtatási jog hozzáadása a usernek
chmod g-w file.txt     # írási jog eltávolítása a grouptól
chmod o= file.txt      # összes jog eltávolítása az otherstől
```

**Gyakori Minták:**

| Oktális | Szimbolikus   | Használati Eset                                   |
| -------- | ------------- | -------------------------------------------------- |
| `755`  | `rwxr-xr-x` | Szkriptek, amiket mindenki futtathat               |
| `700`  | `rwx------` | Privát szkriptek (csak te)                        |
| `644`  | `rw-r--r--` | Szöveges fájlok (mások olvashatják)            |
| `600`  | `rw-------` | Titkos fájlok (csak te)                           |
| `777`  | `rwxrwxrwx` | **VESZÉLYES** (mindenki bármit csinálhat) |

#### Tulajdonjog

Fájl tulajdonosának megváltoztatása (valós rendszereken `sudo` szükséges):

```bash
sudo chown student:student file.txt
```

Ebben a laborban jogosultsági módosításokkal fogod szimulálni a tulajdonjogi problémákat.

#### Alapvető Szkriptelés

Egy shell szkript egy szöveges fájl, amely olyan parancsokat tartalmaz, amelyeket manuálisan begépelnél.

**Egy szkript anatómiája:**

```bash
#!/bin/bash                    # Shebang: megmondja a rendszernek, hogy bash-t használjon
NAME="Student"                 # Változó (NINCS szóköz az = körül!)
echo "Hello, $NAME"            # Változó elérése $-lal

TARGET_DIR="$1"                # $1 = első argumentum a szkriptnek
if [ -z "$TARGET_DIR" ]; then  # Ellenőrzés, hogy üres-e
  echo "Error: No directory"
  exit 1                       # Kilépés hibakóddal
fi

echo "Processing: $TARGET_DIR"
```

**Szkriptek futtatása:**

```bash
chmod +x myscript.sh     # Először futtathatóvá kell tenni
./myscript.sh /home      # Futtatás (pont-perjel szükséges az aktuális könyvtárhoz)
```

---

### 3. Alapvető Parancsok Referencia

Tartsd kéznél ezt a táblázatot a labor alatt:

| Parancs             | Cél                                                                       |
| ------------------- | -------------------------------------------------------------------------- |
| `ls -l`           | Jogosultságok, tulajdonosok és méretek megjelenítése.                 |
| `chmod`           | Jogosultsági bitek módosítása.                                         |
| `chown`           | Fájl tulajdonos/csoport módosítása (valós életben sudo szükséges). |
| `cat`             | Fájl tartalmának kiírása.                                              |
| `touch`           | Üres fájl létrehozása vagy időbélyegek frissítése.                 |
| `mkdir -p`        | Könyvtárak létrehozása (szülőkkel együtt) biztonságosan.           |
| `rm -rf`          | Rekurzív törlés (óvatosan kezelendő).                                 |
| `nano` / `code` | Fájlok szerkesztése.                                                     |

---

### 4. Gyakori Csapdák (Ne Ess Beléjük!)

**Csapda #1: Szóközök a Változó Értékadásban**

```bash
❌ NAME = "Student"    # A BASH azt gondolja, hogy NAME egy parancs
✅ NAME="Student"      # Nincs szóköz az = körül
```

**Csapda #2: Permission Denied Szkriptek Futtatásakor**

```bash
$ ./myscript.sh
bash: ./myscript.sh: Permission denied

# Javítás: add hozzá a futtatási jogot
$ chmod +x myscript.sh
$ ./myscript.sh
# Most már működik!
```

**Csapda #3: Írás Próbálkozás a Home-on Kívül**

```bash
$ touch /bin/myfile
touch: cannot touch '/bin/myfile': Permission denied

# Nem te vagy a /bin tulajdonosa. Dolgozz a home vagy repo könyvtáradban.
```

**Csapda #4: Könyvtár Futtatási Bit Nélkül**

```bash
$ chmod 644 mydir    # Olvasás/írás adása, de NINCS futtatás
$ ls mydir
ls: cannot access 'mydir': Permission denied

# Könyvtáraknak +x-re van szükségük, hogy beléphess
$ chmod 755 mydir
$ ls mydir
# Most már működik!
```

---

## 0. Környezet Bemelegítés (Hierarchia + Szókincs)

1. Futtasd a `pwd` parancsot a repository-ban, hogy megerősítsd az abszolút útvonaladat. Figyeld meg, hogy minden végül a `/`-ból ered.
2. Futtasd az `ls -l` parancsot és írd le a user/group/others jogosultságokat minden bejegyzésre.
3. Látogass meg egy virtuális fájlt, hogy megerősítsd az "minden fájl" koncepciót:
   ```bash
   cat /proc/cpuinfo | head -5
   ```

   Magyarázd meg, miért működik ez, annak ellenére, hogy semmi sem tárolódott a lemezen.

---

## 1. Jogosultsági Javítások (Három identitás + Oktális matematika)

Kövesd pontosan a lépéseket és jegyezd fel a használt parancsot, valamint hogy miért oldotta meg a problémát.

1. **Evidence szkript**

   - Próbáld ki: `./evidence/script.sh` → várd a `Permission denied` hibát.
   - Javítás oktálissal: `chmod 755 evidence/script.sh`.
   - Futtasd újra a szkriptet a siker megerősítéséhez.
2. **Zárt szoba**

   - Próbáld ki: `ls locked_room` → sikertelen, mert nincs futtatási jogod a könyvtáron.
   - Javítás: `chmod 700 locked_room` hogy csak te léphess be és olvasd a tartalmát.
   - Erősítsd meg a hozzáférést a `locked_room/secret.txt`-hez.
3. **Incidens napló**

   - Vizsgáld meg: `ls -l evidence/log_1.txt`.
   - Alkalmazd: `chmod 600 evidence/log_1.txt` hogy csak te olvashasd/írd.
   - Fűzz hozzá egy záró sort:
     ```bash
     echo "[$(date +%Y-%m-%d)] Ügy Lezárva: <NEVED>" >> evidence/log_1.txt
     ```

---

## 2. Tulajdonjog és Biztonsági Ellenőrzések (szimbolikus vs numerikus)

1. Gyakorold a szimbolikus módot: kapcsold át a csoport olvasási jogát az `evidence/log_1.txt` fájlon `chmod g-r ...` és `chmod g+r ...` használatával.
2. Próbáld meg: `touch /bin/testfile` (várd a hibát). Dokumentáld a hibát és magyarázd meg, miért dolgozunk a saját könyvtárainkban.
3. Hozz létre egy munkakönyvtárat a repón belül: `mkdir -p sandbox/temp`.

---

## 3. Automatizációs Szkript (`fix_system.sh`)

Készítsd el a `fix_system.sh` szkriptet a repo gyökerében, hogy gyakorold a shebang-eket, argumentumokat és fájlkeresést.

Ellenőrzőlista:

1. Kezdd a shebang-gel: `#!/bin/bash`.
2. Tárold az első argumentumot: `TARGET_DIR="$1"`.
3. Ha a `TARGET_DIR` üres, írd ki: `Error: No directory provided` és lépj ki `1`-es kóddal.
4. Biztonságossá tedd a `.txt` fájlokat: `find "$TARGET_DIR" -name '*.txt' -exec chmod 644 {} \;`.
5. Biztonságossá tedd a `.sh` fájlokat: `find "$TARGET_DIR" -name '*.sh' -exec chmod 700 {} \;`.
6. Fűzd hozzá az aktuális dátumot az `audit.log`-hoz.
7. Tedd futtathatóvá a szkriptet: `chmod +x fix_system.sh`.

Teszteld:

```bash
./fix_system.sh evidence
```

Használd az `ls -l evidence` parancsot annak ellenőrzésére, hogy a `.txt` fájlok `rw-r--r--` (644) és a `.sh` fájlok `rwx------` (700) jogosultságúak.

---

## 4. Ellenőrző Szkript

1. Állítsd vissza a futtatási jogot az értékelőn: `chmod +x verify.sh`.
2. Futtasd: `./verify.sh`.
3. Ha bármely ellenőrzés sikertelen, kövesd a szkript által kiírt utasítást, javítsd a hibát és futtasd újra.
4. Sikeres futtatás esetén kiírja: `SYSTEM SECURE - PASS`. Készíts képernyőképet erről a terminál kimenetről a beadáshoz.

---

## 5. Gondolkodási Kérdések

Készíts rövid válaszokat az ellenőrzéshez:

1. Miért van szükség egy könyvtárnak futtatási bitre, mielőtt `cd`-zhetnél bele?
2. Milyen kockázatot jelentene a `chmod 777 evidence/script.sh` parancs?
3. Hogyan dönti el a `fix_system.sh`, hogy melyik fájl kapjon `644` és melyik `700` jogosultságot?

---

## Beadási Lépések

1. Győződj meg róla, hogy a `verify.sh` sikeres eredményt jelez.
2. Add hozzá a munkádat:
   ```bash
   git add evidence/log_1.txt fix_system.sh audit.log
   ```
3. Commit és push:
   ```bash
   git commit -m "2. Labor – fájlrendszer és jogosultságok"
   git push
   ```
