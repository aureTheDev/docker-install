# Docker Installation Script

This Bash script installs Docker and Docker Compose on **Debian**, **Ubuntu**, or **Fedora** systems. It also configures the `docker` group to allow non-root users to run Docker commands.

## Features

- Automatically detects the operating system (Debian, Ubuntu, Fedora).
- Installs Docker and Docker Compose.
- Creates the `docker` group if it doesn't exist.
- Prompts to add one or more users to the `docker` group.
- Provides clear error handling and success messages.

## Prerequisites

- The script must be run as **root** or with `sudo`.
- An active internet connection is required to download packages.

## Usage

### Download and Run the Script

You can download and run the script using the following command:

```sh
bash -c "$(wget -qLO - https://github.com/aureTheDev/docker-install/raw/main/docker-install.sh)"
```
