# Space Engineers server on Linux (actually with Wine in a Docker container)

This is yet another experiment to run Space Engineers on Linux. It kind of works but
performance is not very good, especially during autosaving.

## Features

- The container image built by Docker Compose is self-contained except for the three
  mounted directories (see instructions below).
- The Torch Server GUI is displayed locally by Xpra over SSH (no need for VNC, remote
  desktop or X forwarding).

## Runtime Requirements

- Ability to run container images (e.g. Podman or Docker).
- Enough storage space for the container image (about 5 GiB) and the data directory (about
  6 GiB).

## Usage

Build the container image with Docker Compose:

```sh
make build
```

Export and upload the image to the host that will run it. Then create the directories to
be mounted:

```sh
mkdir --parents /path/to/data/{ssh_admin,ssh_etc,torch}
```

In `/path/to/data/ssh_admin`, create an `authorized_keys` file with the SSH public keys
you want to accept for the authentication of administrators.

Create a container with the following parameters:

- Mounted directories:
  - `/path/to/data/torch` to `/home/admin/torch`
  - `/path/to/data/ssh_etc` to `/etc/ssh`
  - `/path/to/data/ssh_admin` to `/home/admin/.ssh`
- Published ports:
  - TCP 22 for SSH (and the Torch Server GUI via Xpra).
  - UDP 27016 for the game server.

Make sure those ports are not blocked by the host's firewall.

Connect to the container with SSH or Xpra:

```sh
SL_REMOTE_HOST=foo.example.net make connect-remote-xpra
```

Note that this Makefile target is only an example. Feel free to modify the actual
connection command. For example, you may need to adjust the SSH command with `--ssh`.

The Torch Server can crash for many reasons, for example if you start the server without a
world. In such a case, the server will restart automatically and you'll have to try again
with a different configuration.

## Acknowledgments

I got ideas from the following:

- https://github.com/soyasoya5/se-torchapi-linux
- https://github.com/mmmaxwwwell/wine6
- https://github.com/TorchAPI/Torch/issues/514
