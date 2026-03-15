<p align="center">
  <img src="assets/BB_logo.png" alt="Project Logo" width="200"/>
</p>

<div align="center">
<h1>Bake</h1>
  <h2>The Kitchen For Crypto Compiling</h2>
  <img src="https://img.shields.io/badge/version-3.0rc-blue">
  <img src="https://img.shields.io/badge/platform-linux-green">
  <img src="https://img.shields.io/badge/license-MIT-purple">
  <img src="https://img.shields.io/badge/status-active-success">
</div>
<p></p>

Bake is a **modular cryptocurrency compile from source system** designed to produce
**repeatable, deterministic multi‑target builds** for core wallets and related software.

Originally created for {Crystal} **Bitoreum**, **bake** now supports compiling
**any compatible repository** with minimal configuration.

The system automates:

- Dependency installation
- Architecture targeting
- Build configuration
- Packaging and checksums
- Logging and diagnostics

Bake focuses on **transparency, reproducibility, and modular tooling**

# Bake Toolchain

Bake operates as a collection of specialized tools.

  |Tool            | Role |
  |----------------|-------------------------------------|
  | **first_run**  |Environment Initialization |
  | **bake**       | Main build Operation |
  | **childe**     | Architecture Target Selection |
  | **garnish**    | Build flag configuration |
  | **dishy**      | Workspace cleaning tool |
  | **asset_pull.sh** | Self‑healing runtime asset assist |
  | **kitchen.lib** | Shared runtime library |

While Each tool can perform a **single well‑defined task**, the user can and should use them
in conjuction with each other to create a seemless build pipeline, while keeping the system
easy to debug and extend.

# Build Pipeline

    git repo
       │
       ▼
    bake
       │
       ├── first_run (initial setup)
       │
       ├── asset_pull
       │
       ├── childe (select targets)
       │
       ├── garnish (set build flags)
       │
       ▼
    dependency build
       │
       ▼
    configure / compile
       │
       ▼
    artifact packaging
       │
       ▼
    checksums + compressed archives

# ✨ Features

-   Deterministic build environment
-   Multi‑architecture builds
-   Optional GUI wallet compilation (QT)
-   Automatic dependency installation
-   Self‑healing runtime assets
-   Structured logging
-   Build artifact packaging
-   Checksum generation
-   Workspace reset utilities

# Supported Targets

Bake supports building for:

-   Linux x86_64
-   Linux x86
-   Linux ARM64
-   Linux ARMv7
-   Raspberry Pi
-   Oracle Ampere ARM
-   Windows x86_64 (cross‑compile)

Target selection is handled through **childe**

# Instilation & Initial Setup
### 1. Install git
Some distros do not install this by default and it is required
```bash
sudo apt update
sudo apt install -y git
```

### 2. Clone bake
```bash
git clone https://github.com/Nikovash/bake.git
cd bake
```

### 3. Run `first_run`
```bash
./first_run
```
The `first_run` will:
- Initilize the **bake** runtime environment
- Install the bake libraries
- Prepare the workspace
- Self-destruct on sucessful completion, this is by design

### [optional] 4. Optional Installs
**bake** utilizes a few dependencies that like `git` are not always included with every distro they are:
```bash
sudo apt install -y whiptail
```
AND 
```bash
sudp apt install -y dialog
```
# Basic Usage
### Building a project

The **bake** environemnt has always bee centered around easy and minimal input ease of use. However, over time the need for both simple and complex use cases has arrisin and this toolchain now accomidates many uses. The most basic of use to create a compiled from source version of Bitoreum follows this baic pattern:
`./bake <branch-or-tag>` selevitng any valid branch or tag from the Nikovash/bitoreum repo will start building right away. Example:
```bash
./bake v4.1.0.0
```
This command will default to building Bitoreum version 4.1.0.0 with all the standard build options set in the `makefile` and `configure.ac`. thes can be overridden and are discussed in andvanced usage later.

You can also use this software to build other projects as well with a few other additions to the basic command:
```bash
./bake <version-or-tag> [<coin-name> <github-repo-url>
```
```bash
./bake v3.1.4.20 yerbas https://github.com/The-Yerbas-Endeavor/Yerbas
```
For example, whould attempt to build from sournce the Yerbas coin of version 3.1.4.20. Optional flags listed below work for this usage as well.

Full optional flags
```bash
./bake <version-or-tag> [<coin-name> <Github-Repo-URL>] [-d] [-c] [-g] [-f] [-h]
```
### -d
Only Downloads the source from Github Repo

### -c
Runs the **childe** tool and allows you to select targets for building. Some cross compile headers may be requried for your specific distro/kernel that is outside the scope of this document.

### -g
Runs the **garnish** tool and allows you to select from a human readable list flages that would apply toe the ./configure step of the build. Once this list is built it is persistant until you hange it or delete the file. Then the default flags from `configure.ac` are used.

### -f
Full options, runs both the **childe** & **garnish** tool

### -h
displays a bit of help and usage syntax

# Cleaning the Kitchen

Use **Dishy** to clean the workspace.

Standard cleanup:
```bash
./dishy
```
Reset everything to a fresh download state:
```bash
./dishy -i
```
Dishy will default to bitoreum, if you want to use Dishy on other coins you have downloaded just pass the coin name:
```bash
./dishy <coin-name> [-i]
```
# 📜 Logging

Bake produces structured logs for troubleshooting
## Primary log locations:
    bakery.log
    run-logs/

Logs include:
- Dependency builds
- Compile output
- Packaging stages

# Contributing

Pull requests and issues are welcome!
Guidelines:
- Maintain modular structure
- Document new flags
- Keep scripts readable
- Preserve deterministic builds

## 📦 Requirements

- Linux (Ubuntu 18.04+ recommended)
- `sudo` privileges
- Internet connection
- Optional: `screen` (for remote session safety)
- git
- [whiptail and/or dialog]
