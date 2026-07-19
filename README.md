# Run VSCode in unprivileged podman container

* root account not involved

# Why

* Improve host system isolation when running such complex system
* Easily allow turning off access to host network for this particular program

## Requirements

- [Podman](https://podman.io/) or [Docker](https://www.docker.com/) (installed and configured)
- GNU Make

## Getting Started

Note: all `make` commands below make use of Podman by default. Pass `Docker=docker` if you prefer to run in docker container.

### Build the image

```bash
make build
```

### Add below function at the end of your .bashrc, replace `/path/to/vscode_in_podman` with full path where vscode_in_podman was cloned to

```bash
function code {
    vscode_dir=/path/to/vscode_in_podman
    if [ -z "$1" ]; then
        echo "Call 'code .' or 'code /path/to/project'";
    else
        proj_dir=$(cd "$1" && pwd);
        make -s -C $vscode_dir run HOST_PATH_TO_PROJECT="$proj_dir" CONTAINER_PATH_TO_MOUNT_PROJECT="$proj_dir";
    fi;
}
```

Once updated:

```bash
source ~/.bashrc
```

You can then call code as you would normally do:

```bash
cd path/to/your/project
code .
```

### You can also run the container manually

```bash
make run HOST_PATH_TO_PROJECT=/path/to/your/project
```
Note:
We are forwarding X11 session and PulseAudio into the container, this is the reason why only Linux distributions are currently supported.

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

# Run without network

If you want network not to be available from within the container, set `NO_NETWORK=yes` when running:

```bash
make run NO_NETWORK=yes
```

# Downgrading

If you need to run downgraded version you can look up relevant commit [on AUR page of visual-studio-code-bin package](https://aur.archlinux.org/cgit/aur.git/log/?h=visual-studio-code-bin)

```bash
make build VSCODE_PKGBUILD_VERSION=<your PKGBUILD hash>
make run
```

Example:
 - if you happen to work remotely with code hosted on Ubuntu 18.03 and wanted to build VSCode downgraded to version 1.85.2, you can do this by building the image like below:

```bash
make build VSCODE_PKGBUILD_VERSION=902d1f5c27a958c47afd4d18a084478c03bdcb25
```

# Run with nvidia GPU

If you require access to nvidia GPU you need to build and run using `WITH_NVIDIA_GPU=yes`

```bash
make build WITH_NVIDIA_GPU=yes
make run WITH_NVIDIA_GPU=yes
```

You might have to [run nvidia-ctk](https://wiki.archlinux.org/title/Podman#NVIDIA_GPUs)

Old nvidia GPUs are currently not supported

# Troubleshooting

* If you are using podman and fall into weird issues while running this container please check if your `/etc/containers/seccomp.json` diverted from https://raw.githubusercontent.com/containers/common/main/pkg/seccomp/seccomp.json
To check if seccomp.json might be an issue add `--security-opt seccomp=unconfined` to `podman run` options. It is also possible to use downloaded seccomp.json by adding following to `podman run` options: `--security-opt seccomp=/path/to/the/seccomp.json`


* If you get error similar to below:
```
Error: crun: cannot stat `/usr/lib/libnvidia-egl-wayland.so.1.1.20`: No such file or directory: OCI runtime attempted to invoke a command that was not found
```
Try:

```bash
nvidia-ctk cdi generate --output=/etc/cdi/nvidia.yaml
```

# Thanks

People building Code
* https://code.visualstudio.com/

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
