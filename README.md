# Run VSCode in unprivileged podman container

* root account not involved

# Why

* Improve host system isolation when running such complex system
* Easily allow turning off access to host network for this particular program

# Run

If you have podman:

```bash
make build
make run
```

If you prefer docker:

```bash
make build DOCKER=docker
make run DOCKER=docker
```

We are forwarding X11 session and PulseAudio into the container, this is the reason why only Linux distributions are currently supported.

# Expose source code to the container

Adjust `HOST_PATH_TO_PROJECT` and `CONTAINER_PATH_TO_MOUNT_PROJECT` in `.makerc`

# Extensions

Download extensions from any extensions marketplace and drop them to `docker_files/extensions`, they will be installed next time you issue `make run`

# Settings

VSCode settings on Arch Linux can be found under `~/.config/Code/User/settings.json`

Below example shows how settings can be added:

```json
    "telemetry.telemetryLevel": "off",
    "remote.SSH.defaultExtensions": [
        "ms-python.python"
    ],
```

# Example `.vscode/launch.json`

```json
{
    "version": "0.2.0",
    "configurations": [
        {
            "name": "<your launch config name>",
            "type": "python",
            "request": "launch",
            "program": "/path/to/your/program.py",
            "args": [
                "--option-name", "value-1"
                "--another-option-name", "value-2"
            ],
            "env": {
                "IMPORTANT_ENV": "value-3"
            },
            "python": "/path/to/venv/bin/python3.8",
            "justMyCode": false,
        }
    ]
}
```

# Troubleshooting

* If you are using podman and fall into weird issues while running this container please check if your `/etc/containers/seccomp.json` diverted from https://raw.githubusercontent.com/containers/common/main/pkg/seccomp/seccomp.json
To check if seccomp.json might be an issue add `--security-opt seccomp=unconfined` to `podman run` options. It is also possible to use downloaded seccomp.json by adding following to `podman run` options: `--security-opt seccomp=/path/to/the/seccomp.json`

# Thanks

People maintaining ArchLinux:
* https://archlinux.org/
Authors of these ArchWiki pages:
* https://wiki.archlinux.org/title/Visual_Studio_Code

Great teams building products I love:
* https://podman.io/

Good souls who like to help others:
* https://gist.github.com/sham1/aa451608775d36fb55ebdbbc955bcb4d
* https://unix.stackexchange.com/questions/118811/why-cant-i-run-gui-apps-from-root-no-protocol-specified#answer-118826

Many other giants
