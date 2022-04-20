#!/usr/bin/env bash

set -e

chmod 0500 ~/.ssh
chmod 0400 ~/.ssh/*
touch ~/.ssh/config
chmod 0700 ~/.ssh/config

echo "Installing extensions"
CUSTOM_EXTENSIONS_DIR=~/.config/Code/extensions
mkdir -p "${CUSTOM_EXTENSIONS_DIR}"
for ext in "${EXTENSIONS_DIR}"/*.vsix; do
    ext_api="$(basename "${ext}" | sed -e "s/\([^\.]*\..*\)-[0-9]*.*/\1/g")"
    if [ -n "$(code --extensions-dir="${CUSTOM_EXTENSIONS_DIR}" --list-extensions | grep "${ext_api}")" ]; then
        echo "${ext} already installed, skipping to the next extension."
        continue
    fi
    echo "Installing ${ext}"
    code --extensions-dir="${CUSTOM_EXTENSIONS_DIR}" --install-extension "${ext}"
done
echo "Extensions installed"

/usr/sbin/code --verbose --extensions-dir="${CUSTOM_EXTENSIONS_DIR}"
code_pid=$(ps -ef | grep "/opt/visual-studio-code/code" | tr -s ' ' | cut -d ' ' -f2 | head -n 1)

_term() {
    echo "Termination initiated (probably by ctrl+c)"
    if [ -n "$code_pid" ]; then
        kill -INT "$code_pid"
        for icnt in $(seq 1 120); do
            if [ -z "$(ps -q "$code_pid" -o comm=)" ]; then
                break;
            fi;
            echo "Waiting for code-oss to terminate...";
            sleep 1;
        done

        if [ -n "$(ps -q "$code_pid" -o comm=)" ]; then
            kill -9 "$code_pid"
            exit 1
        fi;
    fi;
    echo "Code terminated"
    exit 0
}

# 0 - EXIT
# 1 - HUP
# 2 - INT
# 3 - QUIT
# 13 - PIPE
# 15 - TERM
trap _term 1 2 3 13 15

tail --pid=$code_pid -f /dev/null
