# jsdomiot Kickstart

A complete setup script for DOMIoT (Document Object Model for IoT) on Linux systems.

## Quick Start

To install and set up DOMIoT on your Linux system, simply run:

```
chmod +x kickstart.sh
./kickstart.sh
```

## What It Does

The kickstart script will:

1. **Install System Dependencies** - All necessary libraries and build tools.
2. **Install Node.js** - Latest LTS version if not already installed.
3. **Clone Repositories** - Downloads the required DOMIoT repositories:
   - [drivers](https://github.com/domiot-io/drivers.git): IoT hardware drivers.
   - [jsdomiot](https://github.com/domiot-io/jsdomiot.git): Main DOMIoT library.
4. **Build and Load Drivers** - Compiles and loads Linux kernel modules.
5. **Install Dependencies** - Node.js packages for the projects.
6. **Navigate to Examples** - Shows you the first example to get started.

## Requirements

- **Linux Distribution** - Supports Debian, Ubuntu, CentOS, RHEL, Fedora, Arch, Alpine, etc.
- **User with sudo privileges** - Required for system package installation and driver loading.
- **Internet connection** - For downloading packages and repositories.

## After Installation

Once the script completes, go to the first example directory:
```
cd domiot/jsdomiot/examples/0-retail-buttons-shelving-units
```

To run the example:
```
node main.mjs
```

## After installation

After installation, check the `domiot/README.md` for detailed information about the repositories and available examples. 
