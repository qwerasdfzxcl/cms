#!/usr/bin/env bash
set -euo pipefail

VENV="$HOME/cms_venv"
ACTIVATE="$VENV/bin/activate"

echo "[1/5] Installing CMS with setup.py..."
source "$ACTIVATE"
python3 setup.py install

# ── helper ────────────────────────────────────────────────────────────────
restart_screen () {
    local session="$1"; shift          # ex) AWS
    local bin="$1";     shift || true  # ex) cmsAdminWebServer
    local exe="$VENV/bin/$bin"

    # 남은 건 전부 인수
    local -a args=("$@")

    # 1. 확인
    if [[ ! -x "$exe" ]]; then
        echo "[$session] ERROR: $exe not found or not executable" >&2
        return 1
    fi

    # 2. 기존 세션 종료
    if screen -list | grep -q "\\.${session}"; then
        echo "Killing existing screen session: $session"
        screen -S "$session" -X quit
        sleep 0.3
    fi

    # 3. 명령 문자열 조립 (args 가 없어도 안전)
    local cmdstr
    printf -v cmdstr '%q ' "$exe" "${args[@]}"

    echo "Starting new screen session: $session -> $cmdstr"

    screen -dmS "$session" bash -c \
        "source \"$ACTIVATE\" && exec $cmdstr"
}

# ── launch ────────────────────────────────────────────────────────────────
echo "[2/5] Starting AdminWebServer..."
restart_screen AWS cmsAdminWebServer

echo "[3/5] Starting LogService..."
restart_screen LS  cmsLogService

if (( $# > 0 )); then
    echo "[4/5] Starting ResourceService..."
    restart_screen RS  cmsResourceService -a "$@"
else
    echo "[4/5] No arguments passed. Skipping cmsResourceService."
fi

echo "[5/5] Starting RankingWebServer..."
restart_screen RWS cmsRankingWebServer

echo "Done"
