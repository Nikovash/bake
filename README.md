<p align="center">
  <img src="assets/BB_logo.png" alt="Project Logo" width="200"/>
</p>

<div align="center">
<h1>Bake</h1>
  <h2>The Kitchen For Crypto Compiling</h2>
  <img src="https://img.shields.io/badge/version-3.3-blue">
  <img src="https://img.shields.io/badge/platform-linux-green">
  <img src="https://img.shields.io/badge/license-MIT-purple">
  <img src="https://img.shields.io/badge/status-active-success">
</div>
<p></p>

**Bake** is a modular build toolchain designed to simplify compiling cryptocurrency software from source.

Bake focuses on **ease of use, deterministic builds, and modular tooling**, allowing both simple and advanced build workflows without requiring complex manual setup.

Originally developed for {Crystal} Bitoreum, `bake` (**b**itoreum m**ake**), can also be used to compile other compatible blockchain projects directly from source.

# ✨ Features

- Simple one-command builds
- Deterministic and reproducible compilation
- Modular tooling architecture
- Support for multiple repositories
- Cross-compile target selection
- Persistent configure flag management
- Structured logging for troubleshooting

Bake is designed to remain **transparent and script-driven**, making it easy to understand, modify, and extend.

# Quick Start

Clone the repository:

```bash
git clone https://github.com/Nikovash/bake.git
cd bake
```

Run a standard build:

```bash
./bake <branch-or-tag>
```

Example:

```bash
./bake v4.1.0.0
```

This will build the selected version using the default configuration defined in the project's `Makefile` and `configure.ac`.

# Building Other Projects

Bake can also compile other compatible repositories.

```bash
./bake <version-or-tag> [<coin-name> <github-repo-url>]
```

Example:

```bash
./bake v3.1.4.20 yerbas https://github.com/The-Yerbas-Endeavor/Yerbas
```

This command will build **Yerbas version 3.1.4.20** from source.

Optional flags may also be used with this syntax.

# ⚙️ Command Options

```bash
./bake <version-or-tag> [<coin-name> <github-repo-url>] [-d] [-c] [-g] [-f] [-h]
```

| Flag | Description                                         |
| ---- | --------------------------------------------------- |
| `-d` | Download source only (no build)                     |
| `-c` | Launch **childe** to select build targets           |
| `-g` | Launch **garnish** to configure `./configure` flags |
| `-f` | Run both **childe** and **garnish**                 |
| `-h` | Display help and usage syntax                       |

For other options that can extend `bake` Toolset functionality please see the [Advanced Usage Guide](docs/advanced-options.md)

# 🍳 Bake Toolchain

Bake is composed of several modular tools.

| Tool              | Purpose                      |
| ----------------- | ---------------------------- |
| **bake**          | Primary build driver         |
| **dishy**         | Workspace cleanup and reset  |
| **childe**        | Build target selection       |
| **garnish**       | Configure flag management    |
| **sous**          | Runtime Maintenance/Update   |
| **first_run**     | Environment bootstrap        |
| **kitchen.lib**   | Shared function library      |
| **asset_pull.sh** | Library and asset management |

Each component is designed to remain independent while sharing common logic through `kitchen.lib`.

# Cleaning the Workspace

Use **Dishy** to clean the build workspace.

Standard cleanup:

```bash
./dishy
```

Reset to a fresh download state:

```bash
./dishy -i
```

Clean a different project:

```bash
./dishy <coin-name> [-i]
```
---
### Sous (Maintenance Tool)

`sous` manages the Bake runtime environment.

Typical uses include:

- repairing incomplete installations
- updating runtime libraries
- uninstalling Bake components

Example:

```bash
./sous
```

# 📜 Logging

Bake produces structured logs for troubleshooting.

Primary log locations:

```
../bake/bakery.log
../bake/run-logs/
```

Logs include:

- Dependency builds
- Compile output
- Packaging stages

# 📦 Requirements

Bake is designed for Linux systems.

Minimum requirements:

- Linux (Ubuntu 18.04+ recommended)
- `sudo` privileges
- Internet connection
- `git`
- `whiptail` and/or `dialog`

Optional but recommended:

- `screen` (for remote build sessions)

# Contributing

Pull requests and issues are welcome.

Guidelines:

- Maintain modular structure
- Document new flags and features
- Keep scripts readable
- Preserve deterministic build behavior

Please see [**CONTRIBUTING.md**](CONTRIBUTING.md) for full development guidelines.

# License

Bake is released under the **MIT License**

See [`LICENSE`](LICENSE) for details.

---
