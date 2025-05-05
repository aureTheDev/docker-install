#!/bin/bash

COLOR_RED='\033[0;31m'
COLOR_GREEN='\033[0;32m'
COLOR_RESET='\033[0m'

header_info() {
    clear
    printf "${COLOR_RED}"
    cat <<"EOF"
 _______                       __                                  ______                        __                __  __ 
|       \                     |  \                                |      \                      |  \              |  \|  \
| $$$$$$$\  ______    _______ | $$   __   ______    ______         \$$$$$$ _______    _______  _| $$_     ______  | $$| $$
| $$  | $$ /      \  /       \| $$  /  \ /      \  /      \         | $$  |       \  /       \|   $$ \   |      \ | $$| $$
| $$  | $$|  $$$$$$\|  $$$$$$$| $$_/  $$|  $$$$$$\|  $$$$$$\        | $$  | $$$$$$$\|  $$$$$$$ \$$$$$$    \$$$$$$\| $$| $$
| $$  | $$| $$  | $$| $$      | $$   $$ | $$    $$| $$   \$$        | $$  | $$  | $$ \$$    \   | $$ __  /      $$| $$| $$
| $$__/ $$| $$__/ $$| $$_____ | $$$$$$\ | $$$$$$$$| $$             _| $$_ | $$  | $$ _\$$$$$$\  | $$|  \|  $$$$$$$| $$| $$
| $$    $$ \$$    $$ \$$     \| $$  \$$\ \$$     \| $$            |   $$ \| $$  | $$|       $$   \$$  $$ \$$    $$| $$| $$
 \$$$$$$$   \$$$$$$   \$$$$$$$ \$$   \$$  \$$$$$$$ \$$             \$$$$$$ \$$   \$$ \$$$$$$$     \$$$$   \$$$$$$$ \$$ \$$
EOF
    printf "${COLOR_RESET}\n"
}

handle_result() {
    if [ "$1" -ne 0 ]; then
        printf "${COLOR_RED}[!] Error during step: %s${COLOR_RESET}\n" "$2" >&2
        exit 1
    else
        printf "${COLOR_GREEN}[+] %s: Success${COLOR_RESET}\n" "$2"
    fi
}

# Vérification si l'utilisateur est root
if [ "$EUID" -ne 0 ]; then
    echo -e "${COLOR_RED}[!] Ce script doit être exécuté en tant que root. Veuillez réessayer avec 'sudo' ou en tant que root.${COLOR_RESET}"
    exit 1
fi

# Function to detect the OS
detect_os() {
    if [ -f /etc/os-release ]; then
        . /etc/os-release
        echo $ID
    else
        echo "unknown"
    fi
}

# Function to install Docker on Debian-based systems (Debian/Ubuntu)
install_docker_debian() {
    printf "${COLOR_GREEN}Installing Docker on Debian/Ubuntu...${COLOR_RESET}\n"
    sudo apt-get update
    handle_result $? "Updating package list"

    sudo apt-get install -y ca-certificates curl gnupg lsb-release
    handle_result $? "Installing prerequisites"

    sudo mkdir -p /etc/apt/keyrings
    curl -fsSL https://download.docker.com/linux/$ID/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg
    handle_result $? "Adding Docker GPG key"

    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/$ID \
    $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    handle_result $? "Adding Docker repository"

    sudo apt-get update
    handle_result $? "Updating package list with Docker repository"

    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    handle_result $? "Installing Docker"
}

# Function to install Docker on Fedora
install_docker_fedora() {
    printf "${COLOR_GREEN}Installing Docker on Fedora...${COLOR_RESET}\n"
    sudo dnf -y install dnf-plugins-core
    handle_result $? "Installing DNF plugins"

    sudo dnf config-manager --add-repo https://download.docker.com/linux/fedora/docker-ce.repo
    handle_result $? "Adding Docker repository"

    sudo dnf -y install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
    handle_result $? "Installing Docker"

    sudo systemctl start docker
    handle_result $? "Starting Docker service"

    sudo systemctl enable docker
    handle_result $? "Enabling Docker service"
}

# Function to create the docker group and add users
configure_docker_group() {
    # Create the docker group if it doesn't exist
    if ! getent group docker > /dev/null; then
        groupadd docker
        handle_result $? "Creating 'docker' group"
    else
        printf "${COLOR_GREEN}[+] 'docker' group already exists${COLOR_RESET}\n"
    fi

    # Prompt to add users to the docker group
    printf "${COLOR_GREEN}Enter the usernames to add to the 'docker' group (separated by spaces): ${COLOR_RESET}"
    read -r users

    for user in $users; do
        if id "$user" &>/dev/null; then
            usermod -aG docker "$user"
            handle_result $? "Adding user '$user' to 'docker' group"
        else
            printf "${COLOR_RED}[!] User '$user' does not exist. Skipping.${COLOR_RESET}\n"
        fi
    done

    printf "${COLOR_GREEN}[+] Configuration of 'docker' group completed.${COLOR_RESET}\n"
}

# Main script
header_info

OS=$(detect_os)
case $OS in
    ubuntu|debian)
        install_docker_debian
        ;;
    fedora)
        install_docker_fedora
        ;;
    *)
        printf "${COLOR_RED}Unsupported OS: $OS${COLOR_RESET}\n"
        exit 1
        ;;
esac

configure_docker_group

echo -e "${COLOR_GREEN}Docker installation and configuration completed successfully!${COLOR_RESET}\n"