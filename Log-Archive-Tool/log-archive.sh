#!/bin/bash

set -euo pipefail

if [ "$#" -ne 1 ]; then
    echo "Error: Missing required argument."
    echo "Usage: log-archive <log-directory>"
    exit 1
fi

LOG_DIR="$1"

if [ ! -d "$LOG_DIR" ]; then
    echo "Error: Directory '$LOG_DIR' does not exist."
    exit 1
fi

ARCHIVE_DIR="archives"
mkdir -p "$ARCHIVE_DIR"

TIMESTAMP=$(date +"%Y%m%d_%H%M%S")
ARCHIVE_NAME="logs_archive_${TIMESTAMP}.tar.gz"
ARCHIVE_PATH="${ARCHIVE_DIR}/${ARCHIVE_NAME}"

echo "Archiving logs from '$LOG_DIR' into '$ARCHIVE_PATH'..."
tar -czf "$ARCHIVE_PATH" -C "$LOG_DIR" .

LOG_FILE="${ARCHIVE_DIR}/archive_history.log"
LOG_TIMESTAMP=$(date +"%Y-%m-%d %H:%M:%S")
echo "[${LOG_TIMESTAMP}] Created archive: ${ARCHIVE_NAME} from ${LOG_DIR}" >> "$LOG_FILE"

echo "Success! Logs archived to: $ARCHIVE_PATH"
echo "Log entry appended to: $LOG_FILE"