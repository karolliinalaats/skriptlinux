#!/usr/bin/env bash
# backup.sh — Steps 1–11 with concise output

set -euo pipefail

SRC=~/skriptlinux/praks2/src
DEST=~/skriptlinux/praks2/backup
LOGDIR=~/skriptlinux/praks2/logs
LOGFILE=$LOGDIR/backup.log
MODE="${1:-normal}"   # --gzip | --xz | --dry-run | default=zstd

mkdir -p "$DEST" "$LOGDIR"

timestamp() { date '+%F %T'; }
log() { printf "[ %s ] %s\n" "$(timestamp)" "$1" >> "$LOGFILE"; }

log "BACKUP START (mode: $MODE)"

# Check source
if [[ ! -d "$SRC" ]]; then
  echo "Lähtekaust puudub: $SRC"
  log "ERROR – source missing: $SRC"
  log "BACKUP FAILED"
  exit 1
fi

# Step 8: free-space check
echo "Kontrollin vaba ruumi..."
SIZE_SRC=$(du -sb "$SRC" | awk '{print $1}')
FREE_DEST=$(df -B1 "$DEST" | awk 'NR==2{print $4}')
echo "Kausta suurus: $SIZE_SRC baiti"
echo "Vaba ruumi sihtketal: $FREE_DEST baiti"
if (( FREE_DEST < SIZE_SRC )); then
  echo "Viga: Vaba ruumi pole piisavalt! Varundus katkestatud."
  log "ERROR – Not enough free space. Need $SIZE_SRC, have $FREE_DEST"
  log "BACKUP FAILED (low disk space)"
  exit 1
fi
log "Free space OK (need $SIZE_SRC, have $FREE_DEST)"

DATE=$(date +%F_%H-%M-%S)

# Step 10: compressor choice
declare -a COMPRESS_ARGS
EXT=""
case "$MODE" in
  --gzip) COMPRESS_ARGS=(-z);               EXT="tar.gz" ;;
  --xz)   COMPRESS_ARGS=(-J);               EXT="tar.xz" ;;
  --dry-run)
    echo "Kuiv jooks – näitan, mis läheks arhiivi (uut faili ei looda)."
    tar -cf - -C "$(dirname "$SRC")" "$(basename "$SRC")" | tar -tvf -
    log "DRY RUN done"
    log "BACKUP END"
    exit 0
    ;;
  *)      COMPRESS_ARGS=(-I "zstd -19 -T0"); EXT="tar.zst" ;;
esac
ARCHIVE="$DEST/src-$DATE.$EXT"
log "Compressor: $EXT"

# Step 11: .backupignore + excludes
IGNORE_FILE="$SRC/.backupignore"
declare -a EXCL_ARGS
EXCL_ARGS+=(--exclude='*.jpg' --exclude='src/bin')
[[ -f "$IGNORE_FILE" ]] && EXCL_ARGS+=(--exclude-from="$IGNORE_FILE") && USED_IGNORE=1 || USED_IGNORE=0

# Step 1+5: make archive
echo "Pakkimine algab (rakendatakse välistusi; .backupignore kui olemas)..."
tar "${COMPRESS_ARGS[@]}" "${EXCL_ARGS[@]}" \
    -cf "$ARCHIVE" -C "$(dirname "$SRC")" "$(basename "$SRC")"
echo "Varukoopia loodud: $ARCHIVE"
log "Archive: $ARCHIVE"

# Step 2: quick list
echo
echo "Kontrollin arhiivi sisu (esimesed 5 rida):"
if [[ "$EXT" == "tar.zst" ]]; then
  tar -I 'zstd -d' -tf "$ARCHIVE" | head -n 5
else
  tar -tf "$ARCHIVE" | head -n 5
fi

# Step 3: size
echo
echo "Arhiivi suurus:"
SIZE_HUMAN=$(du -h "$ARCHIVE" | awk '{print $1}')
echo "$SIZE_HUMAN"
log "Size: $SIZE_HUMAN"

# Step 9: checksum + verify
echo
echo "Arvutan SHA-256 kontrollsumma..."
CHECKSUM_FILE="$ARCHIVE.sha256"
sha256sum "$ARCHIVE" > "$CHECKSUM_FILE"
echo "Kontrollin kontrollsummat..."
if sha256sum -c "$CHECKSUM_FILE" >/dev/null 2>&1; then
  echo "Kontrollsumma OK – arhiiv on terve."
  log "Checksum OK"
else
  echo "Viga: Kontrollsumma EI KLAPI!"
  log "ERROR – checksum failed"
  log "BACKUP FAILED"
  exit 1
fi

# Step 4: keep only 3 newest archives (leave .sha256 files as-is)
echo
echo "Hoidan alles ainult 3 kõige uuemat koopiat..."
cd "$DEST"
ls -1t *.tar.* 2>/dev/null | tail -n +4 | xargs -r rm -f
echo "Alles olevad koopiad:"
ls -1t *.tar.* 2>/dev/null || true
log "Rotation done (keep 3 archives)"

# Step 5: spot-check exclusions
echo
echo "Kontroll, et arhiiv ei sisalda .jpg faile ega bin/ kausta:"
if [[ "$EXT" == "tar.zst" ]]; then
  tar -I 'zstd -d' -tf "$ARCHIVE" | grep -E '(\.jpg$|/bin/)' >/dev/null \
    && echo "Hoiatus: leiti sobiv muster." \
    || echo "OK – neid faile pole arhiivis."
else
  tar -tf "$ARCHIVE" | grep -E '(\.jpg$|/bin/)' >/dev/null \
    && echo "Hoiatus: leiti sobiv muster." \
    || echo "OK – neid faile pole arhiivis."
fi

echo
if [[ "$USED_IGNORE" -eq 1 ]]; then
  echo "Kõik tehtud. .backupignore reeglid rakendati (kui fail oli olemas)."
else
  echo "Kõik tehtud. .backupignore puudus – töötati ainult vaikimisi välistustega."
fi

log "BACKUP END"
