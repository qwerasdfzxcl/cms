#!/usr/bin/env bash
set -euo pipefail

echo "[1/5] Installing CMS with setup.py..."
source $HOME/cms_venv/bin/activate
python3 setup.py install
find $HOME/cms_venv/bin/ -type f -exec sed -i '1s|^#!python$|#!/usr/bin/env python3|' {} +

function restart_screen {
    local name=$1
    local cmd=$2

    if screen -list | grep -q "\.${name}"; then
        echo "Killing existing screen session: ${name}"
        screen -S "$name" -X quit
        sleep 0.5
    fi

    echo "Starting new screen session: ${name}"
    screen -dmS "$name" bash -c "$HOME/cms_venv/bin/$cmd"
}

echo "[2/5] Starting AdminWebServer..."
restart_screen AWS "cmsAdminWebServer"

echo "[3/5] Starting LogService..."
restart_screen LS "cmsLogService"

if [ $# -gt 0 ]; then
    echo "[4/5] Starting ResourceService..."
    restart_screen RS "cmsResourceService -a $*"
else
    echo "[4/5] No arguments passed. Skipping cmsResourceService."
fi

echo "[5/5] Starting RankingWebServer..."
restart_screen RWS "cmsRankingWebServer"

echo "Done"

