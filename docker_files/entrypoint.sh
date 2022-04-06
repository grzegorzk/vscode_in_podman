#!/usr/bin/env bash

set -e

echo "Installing extensions"

for ext in "${EXTENSIONS_DIR}"/*.vsix; do
    echo "Installing ${ext}"
    code --install-extension "${ext}"
done

echo "Extensions installed"
echo "Running code"

/usr/sbin/code
code_pid=$(ps -ef | grep "usr/lib/code/code.js" | tr -s ' ' | cut -d ' ' -f2 | head -n 1)

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
