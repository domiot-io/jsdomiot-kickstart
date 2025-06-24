#!/bin/bash

# DOMIoT Linux Kickstart Script
# Author: DOMIoT ( domiot.org )
# Version: 1.0.0

set -e  # Exit on any error

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

DOMIOT_DIR="domiot"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

print_status() {
    echo -e "${GREEN}[INFO]${NC} $1"
}

print_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

print_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

print_header() {
    echo -e "${BLUE}================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}================================${NC}"
}

version_meets_requirement() {
    local current="$1"
    local required="$2"
    [ "$(printf '%s\n' "$required" "$current" | sort -V | head -n1)" = "$required" ]
}

check_system_requirements() {
    print_header "Checking System Requirements"
    
    local missing_tools=()
    local outdated_tools=()
    
    # Check git
    if command -v git &> /dev/null; then
        GIT_VERSION=$(git --version | cut -d' ' -f3)
        if ! version_meets_requirement "$GIT_VERSION" "2.0.0"; then
            outdated_tools+=("git (current: $GIT_VERSION, required: >= 2.0.0)")
        else
            print_status "✅ git $GIT_VERSION meets requirements"
        fi
    else
        missing_tools+=("git")
    fi
    
    # Check gcc
    if command -v gcc &> /dev/null; then
        GCC_VERSION=$(gcc --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+' | head -n1)
        if ! version_meets_requirement "$GCC_VERSION" "4.8"; then
            outdated_tools+=("gcc (current: $GCC_VERSION, required: >= 4.8)")
        else
            print_status "✅ gcc $GCC_VERSION meets requirements"
        fi
    else
        missing_tools+=("gcc")
    fi
    
    # Check make
    if command -v make &> /dev/null; then
        MAKE_VERSION=$(make --version | head -n1 | grep -o '[0-9]\+\.[0-9]\+' | head -n1)
        print_status "✅ make $MAKE_VERSION is available"
    else
        missing_tools+=("make")
    fi
    
    # Check Node.js
    if command -v node &> /dev/null; then
        NODE_VERSION=$(node --version | cut -d'v' -f2)
        if ! version_meets_requirement "$NODE_VERSION" "18.0.0"; then
            print_error "Node.js version $NODE_VERSION is too old (required: >= 18.0.0)"
            print_error "Please update Node.js to version 18.0.0 or higher and run this script again"
            exit 1
        else
            print_status "✅ Node.js $NODE_VERSION meets requirements"
        fi
    else
        print_error "Node.js is not installed"
        print_error "Please install Node.js 18.0.0 or higher and run this script again"
        exit 1
    fi
    
    # Check npm
    if command -v npm &> /dev/null; then
        NPM_VERSION=$(npm --version)
        if ! version_meets_requirement "$NPM_VERSION" "6.0.0"; then
            print_error "npm version $NPM_VERSION is too old (required: >= 6.0.0)"
            print_error "Please update npm and run this script again"
            exit 1
        else
            print_status "✅ npm $NPM_VERSION meets requirements"
        fi
    else
        print_error "npm is not installed"
        print_error "Please install npm 6.0.0 or higher and run this script again"
        exit 1
    fi
    
    # missing/outdated tools
    if [ ${#missing_tools[@]} -gt 0 ] || [ ${#outdated_tools[@]} -gt 0 ]; then
        if [ ${#missing_tools[@]} -gt 0 ]; then
            print_error "Missing required tools: ${missing_tools[*]}"
        fi
        if [ ${#outdated_tools[@]} -gt 0 ]; then
            print_error "Outdated tools: ${outdated_tools[*]}"
        fi
        print_error "Please install/update the required tools and run this script again"
        exit 1
    fi
    
    print_status "All system requirements are met!"
}

install_for_debian() {
    print_status "Checking Debian dependencies..."
    local need_install=false
    local missing_packages=()
    
    if ! dpkg -l | grep -q "linux-headers-$(uname -r)"; then
        missing_packages+=("linux-headers-$(uname -r)")
        need_install=true
    fi
    if ! dpkg -l | grep -q "build-essential"; then
        missing_packages+=("build-essential")
        need_install=true
    fi
    
    if [ "$need_install" = true ]; then
        print_status "Installing missing Debian packages: ${missing_packages[*]}"
        
        sudo apt-get update || { print_status "Error: Failed to update apt-get."; return 1; }
        sudo apt-get install -y "${missing_packages[@]}" || { print_status "Error: Failed to install Debian dependencies."; return 1; }
        
        print_status "Debian dependencies installed successfully."
        return 0
    else
        print_status "All required Debian system packages are already installed."
        return 0
    fi
}

install_for_redhat() {
    print_status "Checking RedHat/CentOS/Fedora dependencies..."
    local need_install=false
    local missing_packages=()

    if ! rpm -q kernel-devel &>/dev/null; then
        missing_packages+=("kernel-devel")
        need_install=true
    fi  
    if [ "$need_install" = true ]; then
        print_status "Installing missing RedHat/CentOS/Fedora packages: ${missing_packages[*]}"
        
        if command -v dnf &> /dev/null; then
            sudo dnf install -y "${missing_packages[@]}" || { print_status "Error: Failed to install RedHat/CentOS/Fedora dependencies via dnf."; return 1; }
        else
            sudo yum install -y "${missing_packages[@]}" || { print_status "Error: Failed to install RedHat/CentOS/Fedora dependencies via yum."; return 1; }
        fi
        
        print_status "RedHat/CentOS/Fedora dependencies installed successfully."
        return 0
    else
        print_status "All required RedHat/CentOS/Fedora system packages are already installed."
        return 0
    fi
}

install_for_arch() {
    print_status "Checking Arch Linux dependencies..."
    local need_install=false
    local missing_packages=()

    if ! pacman -Q linux-headers &>/dev/null; then
        missing_packages+=("linux-headers")
        need_install=true
    fi
    if ! pacman -Q base-devel &>/dev/null; then
        missing_packages+=("base-devel")
        need_install=true
    fi
    
    if [ "$need_install" = true ]; then
        print_status "Installing missing Arch Linux packages: ${missing_packages[*]}"
        
        sudo pacman -S --noconfirm "${missing_packages[@]}" || { print_status "Error: Failed to install Arch Linux dependencies."; return 1; }
        
        print_status "Arch Linux dependencies installed successfully."
        return 0
    else
        print_status "All required Arch Linux system packages are already installed."
        return 0
    fi
}

install_for_alpine() {
    print_status "Checking Alpine Linux dependencies..."
    local need_install=false
    local missing_packages=()

    if ! apk list --installed | grep -q "linux-headers"; then
        missing_packages+=("linux-headers")
        need_install=true
    fi
    if ! apk list --installed | grep -q "build-base"; then
        missing_packages+=("build-base")
        need_install=true
    fi
    
    if [ "$need_install" = true ]; then
        print_status "Installing missing Alpine Linux packages: ${missing_packages[*]}"
        
        sudo apk update || { print_status "Error: Failed to update apk."; return 1; }
        sudo apk add "${missing_packages[@]}" || { print_status "Error: Failed to install Alpine Linux dependencies."; return 1; }
        
        print_status "Alpine Linux dependencies installed successfully."
        return 0
    else
        print_status "All required Alpine Linux system packages are already installed."
        return 0
    fi
}

install_missing_dependencies() {
    print_header "Installing Missing System Dependencies"
    case $OS in
        "debian")
            install_for_debian
            return $?
            ;;
        "redhat")
            install_for_redhat
            return $?
            ;;
        "arch")
            install_for_arch
            return $?
            ;;
        "alpine")
            install_for_alpine
            return $?
            ;;
        *)
            print_status "Unsupported OS: $OS. Cannot check or install dependencies."
            return 1
            ;;
    esac
}

detect_os() {
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if [ -f /etc/debian_version ]; then
            OS="debian"
            DISTRO=$(lsb_release -si 2>/dev/null || echo "Debian")
        elif [ -f /etc/redhat-release ]; then
            OS="redhat"
            DISTRO=$(cat /etc/redhat-release | cut -d' ' -f1)
        elif [ -f /etc/arch-release ]; then
            OS="arch"
            DISTRO="Arch"
        elif [ -f /etc/alpine-release ]; then
            OS="alpine"
            DISTRO="Alpine"
        else
            OS="unknown"
            DISTRO="Unknown"
        fi
    else
        print_error "This script only supports Linux distributions"
        exit 1
    fi
    
    print_status "Detected OS: $DISTRO ($OS)"
}

create_directories() {
    print_header "Creating Directory Structure"
    
    mkdir -p "$DOMIOT_DIR"
    cd "$DOMIOT_DIR"
    
    print_status "Directory structure created in $PWD"
}

clone_repositories() {
    print_header "Cloning DOMIoT Repositories"
    
    print_status "Cloning drivers repository..."
    if git clone https://github.com/domiot-io/drivers.git; then
        print_status "✅ Drivers repository cloned successfully"
    else
        print_error "Failed to clone drivers repository"
        exit 1
    fi
    
    print_status "Cloning jsdomiot repository..."
    if git clone https://github.com/domiot-io/jsdomiot.git; then
        print_status "✅ jsdomiot repository cloned successfully"
    else
        print_error "Failed to clone jsdomiot repository"
        exit 1
    fi
}

install_npm_dependencies() {
    print_header "Installing Node.js Dependencies"
    
    if [ -d "jsdomiot" ] && [ -f "jsdomiot/package.json" ]; then
        print_status "Installing dependencies for jsdomiot"
        cd jsdomiot
        npm install jsdomiot iot-bindings-node
        cd ..
    fi
}

# Function to build and load drivers
build_drivers() {
    print_header "Building and Loading Drivers"
    
    print_warning "⚠️ IMPORTANT SAFETY NOTICE ⚠️"
    print_warning "This step will build and load drivers, which requires root privileges."
    print_warning "Loading drivers can potentially affect system stability."
    print_warning "The DOMIoT drivers are simulation drivers for testing purposes."
    echo ""
    
    read -p "Do you want to build and automatically load all drivers? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Skipping driver build and load. You can build them manually later."
        print_status "To build drivers manually: cd domiot/drivers/linux/[driver-name] && make"
        return
    fi
    
    LOAD_MODULES=true
    print_status "Will build and automatically load all successfully built drivers"
    echo ""
    
    if [ -d "drivers" ]; then
        cd drivers
        
        # Build Linux drivers
        if [ -d "linux" ]; then
            cd linux
            print_status "Building Linux drivers..."
            
            # Build each driver module
            for driver_dir in */; do
                if [ -d "$driver_dir" ] && [ -f "$driver_dir/Makefile" ]; then
                    driver_name=$(basename "$driver_dir")
                    
                    # only allow known DOMIoT simulation drivers
                    case "$driver_name" in
                        "ihubx24-sim"|"ohubx24-sim"|"iohubx24-sim"|"lcd-sim"|"video-sim")
                            print_status "Building safe simulation driver: $driver_name"
                            ;;
                        *)
                            print_warning "⚠️  Skipping unknown driver: $driver_name (safety measure)"
                            continue
                            ;;
                    esac
                    
                    cd "$driver_dir"
                    
                    # Clean and build
                    make clean >/dev/null 2>&1
                    if make; then
                        print_status "✅ Successfully built $driver_name"
                        
                        # Load module
                        if [ "$LOAD_MODULES" = true ] && [ -f "$driver_name.ko" ]; then
                            modinfo "$driver_name.ko" >/dev/null 2>&1 || {
                                print_warning "⚠️  Invalid module: $driver_name, skipping load"
                                cd ..
                                continue
                            }

                            print_status "Loading 2 devices of module: $driver_name (via make load NUM_DEVICES=2)";
                            sudo make load NUM_DEVICES=2;

                        fi
                    else
                        print_warning "Failed to build $driver_name"
                    fi
                    
                    cd ..
                fi
            done
            
            cd ..
        fi
        
        cd ..
        print_status "Driver build process completed"
        
        # print loaded modules
        print_status "Checking loaded DOMIoT drivers:"
        lsmod | grep -E "(ihubx24|ohubx24|iohubx24|lcd|video)-sim" || print_status "No DOMIoT simulation drivers currently loaded"
        
    else
        print_warning "No drivers directory found, skipping driver build"
    fi
}

finalize_setup() {
    print_header "Finalizing Setup"
    
    cd "$SCRIPT_DIR/$DOMIOT_DIR"
    
    EXAMPLE_DIR="jsdomiot/examples/0-retail-buttons-shelving-units"
    if [ -d "$EXAMPLE_DIR" ]; then
        print_status "Navigating to first example directory..."
        cd "$EXAMPLE_DIR"
        pwd
        
        echo ""
        print_header " DOMIoT Installation Complete!"
        echo ""
        print_status "✅ System requirements verified (git, gcc, make, Node.js, npm)"
        print_status "✅ Missing dependencies installed (if any)"
        print_status "✅ Repositories cloned (drivers and jsdomiot)"
        print_status "✅ All drivers built with 'make'"
        print_status "✅ Driver modules loaded (if selected)"
        print_status "✅ jsdomiot dependencies installed with 'npm install'"
        echo ""
        echo -e "${GREEN} To go to the first example directory, execute:${NC}"
        echo -e "${BLUE}  cd $(pwd)${NC}"
        echo ""
        echo -e "${GREEN} To run this example, execute:${NC}"
        echo -e "${YELLOW}   node main.mjs${NC}"
        echo ""
        echo -e "${GREEN} More examples available in:${NC}"
        echo -e "${YELLOW}   domiot/jsdomiot/examples/${NC}"
        echo ""
        echo -e "${GREEN} Monitor simulation drivers:${NC}"
        echo -e "${YELLOW}   cat /dev/ihubx24-sim0                ${NC}# Monitor input"
        echo -e "${YELLOW}   watch -n 1 cat /tmp/ohubx24-output0  ${NC}# Monitor output"
        echo -e "${YELLOW}   cat /dev/iohubx24-sim0               ${NC}# Monitor input"
        echo -e "${YELLOW}   watch -n 1 cat /tmp/lcd-output0      ${NC}# Monitor LCD output"
        echo -e "${YELLOW}   cat /dev/video-sim0                  ${NC}# Monitor input"
        echo ""
        
        ls
        pwd
        echo -e "${BLUE}Ready to run: node main.mjs ${NC}"
        
    else
        print_error "Example directory not found: $EXAMPLE_DIR"
        # Fallback to jsdomiot/examples if specific example doesn't exist
        if [ -d "jsdomiot/examples" ]; then
            cd jsdomiot/examples
            print_status "Navigated to examples directory:"
            pwd
            echo -e "${YELLOW}Available examples:${NC}"
            ls -la
            echo ""
            echo -e "${GREEN}To run examples, navigate to a specific example directory and run:${NC}"
            echo -e "${YELLOW}   node main.mjs${NC}"
        else
            exit 1
        fi
    fi
}


main() {
    print_header "DOMIoT Kickstart Script v1.0.0"
    
    echo ""
    print_warning "⚠️ SAFETY DISCLAIMER ⚠️"
    print_warning "This script will:"
    print_warning "• Install system packages (requires sudo)"
    print_warning "• Clone repositories from github.com/domiot-io"
    print_warning "• Build and optionally load drivers"
    print_warning "• Run npm install with Node.js packages"
    echo ""
    print_warning "This script is intended for development/testing environments."
    echo ""
    
    read -p "Do you understand the risks and want to continue? (y/N): " -n 1 -r
    echo
    if [[ ! $REPLY =~ ^[Yy]$ ]]; then
        print_status "Installation cancelled by user. Exiting safely."
        exit 0
    fi
    
    print_status "Starting installation for Linux systems..."
    
    # check if running as root
    if [ "$EUID" -eq 0 ]; then
        print_error "Please don't run this script as root. Use a regular user with sudo privileges."
        exit 1
    fi
    
    # check sudo access
    if ! sudo -n true 2>/dev/null; then
        print_status "This script requires sudo access for system packages and driver installation"
        sudo -v
    fi
    
    detect_os
    check_system_requirements
    install_missing_dependencies
    create_directories
    clone_repositories
    install_npm_dependencies
    build_drivers
    finalize_setup
}

main "$@" 
