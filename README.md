<p align="center">
  <img src="assets/BB_logo.png" alt="Project Logo" width="200"/>
</p>

<div align="center">
<h1>Bake</h1>
  <h2>The Kitchen For Crypto Compiling</h2>
  <img src="https://img.shields.io/badge/version-3.5-blue">
  <img src="https://img.shields.io/badge/platform-linux-green">
  <img src="https://img.shields.io/badge/license-MIT-purple">
  <img src="https://img.shields.io/badge/status-active-success">
</div>
<p></p>

**Bake** is a modular, script-driven build toolchain for compiling compatible cryptocurrency projects from source.

Bake is designed around **Debian / Ubuntu / Linux Mint style hosts** and other apt/dpkg-based Linux environments. It automates repository preparation, dependency builds, project compilation, packaging, checksums, logging, and optional target/configuration selection through helper tools.

Originally developed for `{Crystal} Bitoreum`, Bake is coin-agnostic infrastructure. Bitoreum is the default project target, but Bake can also build other compatible source trees when a coin name and repository URL are supplied.

---

## Supported Hosts

Bake currently supports running on:

- Debian-style Linux hosts
- Ubuntu/Mint-style Linux hosts
- apt/dpkg-based clones or containers
- WSL only when it is an apt/dpkg-based Linux environment

Bake intentionally exits early on unsupported hosts before attempting package installation or dependency setup.

Unsupported host examples:

- macOS / Darwin
- Native Windows / MSYS / MINGW / Cygwin
- Fedora / RHEL / Alma / Rocky
- Arch / Manjaro
- openSUSE
- Alpine
- Linux hosts without both `apt-get` and `dpkg`

> Windows **targets** may still be built from a supported Linux host using cross-compilation. Native Windows hosts are not supported.

---

## ✨ Features

- One-command fresh builds
- Refire mode for rebuilding an already-downloaded local project
- Download/check-only mode
- Depends-only mode for dependency toolchain validation
- Automatic first-run Bake runtime bootstrap
- Automatic cleanup of stale `first_run` installer after runtime setup
- Debian/Ubuntu/Mint host validation with graceful unsupported-host exits
- Cross-compile target selection through `recipe_book.conf`
- Persistent configure flag management through `build_flags.list`
- Optional `childe` and `garnish` interactive helpers
- Improved depends cleanup reporting
- Option to preserve failed dependency artifacts for troubleshooting
- Structured build and dependency logs
- Release-style archive packaging into `special-delivery/`
- Global checksums for generated artifacts

---

## Quick Start

Clone Bake:

```bash
git clone https://github.com/Nikovash/bake.git
cd bake
```

Run Bake against the default project target:

```bash
./bake <branch_or_tag>
```

Example:

```bash
./bake v4.1.0.0
```

On a fresh system, Bake will run the first-run runtime bootstrap automatically before continuing.

---

## First-Run Runtime Bootstrap

Bake requires a small runtime under `/opt/bake`, including:

```text
/opt/bake/bake.info
/opt/bake/kitchen.lib
```

You may run the bootstrap manually:

```bash
./first_run
```

Or simply run Bake:

```bash
./bake <branch_or_tag>
```

If the runtime is missing, Bake will run `first_run` automatically, verify that the runtime files exist, remove the stale local `first_run` installer, and continue.

---

## Building Other Projects

Bake can build other compatible repositories by supplying a coin/project name and repository URL:

```bash
./bake <branch_or_tag> <coin_name> <repo_url>
```

Example:

```bash
./bake v3.2.0.15 yerbas https://github.com/The-Yerbas-Endeavor/Yerbas
```

This prepares or updates a local source tree for `yerbas`, checks out the requested branch or tag, builds enabled targets, packages artifacts, and writes logs.

---

## Command Usage

```text
Usage:
  Fresh bake:
    ./bake <branch_or_tag> [<coin_name> <repo_url>] [-d] [--depends-only] [--keep-failed-depends|--preserve-failed-depends] [-c] [-g] [-f] [-o] [-m <label>]

  Depends-only bake:
    ./bake <branch_or_tag> [<coin_name> <repo_url>] --depends-only
    ./bake depends <branch_or_tag> [<coin_name> <repo_url>]

  Refire:
    ./bake -r <coin_name> [-d] [--depends-only] [--keep-failed-depends|--preserve-failed-depends] [-c] [-g] [-f] [-o] [-m <label>]
```

---

## ⚙️ Commands, Modes, & Flags

| Option | Description |
| ------ | ----------- |
| `-d` | Download/check only. Prepare or update the source repo, then exit without building. |
| `--depends-only` | Build dependency toolchains only, then exit before project compile/package. |
| `depends` | Prefix alias for `--depends-only`, for example `./bake depends <branch_or_tag>`. |
| `--keep-failed-depends` | Skip depends cleanup before rebuilding so failed dependency artifacts can be inspected. |
| `--preserve-failed-depends` | Alias for `--keep-failed-depends`. |
| `-c` | Run `childe` before build/refire to select build targets. |
| `-g` | Run `garnish` before build/refire to configure build flags. |
| `-f` | Run both `childe` and `garnish`. |
| `-o` | Allow Oracle Ampere ARM targets to honor GUI flags. |
| `-r` | Refire mode for an already-downloaded local project. |
| `-m <label>` | Replace `Release` in archive names with a custom label. |
| `-h`, `--help` | Show command help. |

`-d` and `--depends-only` cannot be used together.

---

## Common Workflows

### Fresh build

```bash
./bake dev
```

### Fresh build for another compatible project

```bash
./bake main examplecoin https://github.com/example/examplecoin
```

### Download or update source only

```bash
./bake dev -d
```

### Build dependency toolchains only

```bash
./bake dev --depends-only
```

or:

```bash
./bake depends dev
```

### Preserve failed dependency artifacts for inspection

```bash
./bake dev --keep-failed-depends
```

or:

```bash
./bake depends dev --preserve-failed-depends
```

### Refire an existing local source tree

```bash
./bake -r bitoreum
```

### Refire with a custom archive label

```bash
./bake -r bitoreum -m TestBuild
```

---

## Depends Cleanup Reporting

Bake reports dependency cleanup actions before dependency builds. The log records:

- the cleanup mode
- the depends root path
- cleanup commands used
- paths that may be removed or regenerated
- reclaimed disk space when practical

When dependency builds fail, Bake reports likely inspection paths and the relevant dependency build log.

Use this flag when troubleshooting failed dependency builds:

```bash
./bake <branch_or_tag> --keep-failed-depends
```

This prevents the next run from immediately cleaning failed dependency work directories before inspection.

---

## Bake Toolchain Components

| Tool | Purpose |
| ---- | ------- |
| `bake` | Primary build driver. |
| `first_run` | One-time runtime bootstrap installer. May be run manually or automatically by Bake. |
| `kitchen.lib` | Shared function library installed under `/opt/bake`. |
| `asset_pull.sh` | Ensures Bake runtime assets and `kitchen.lib` are available and up to date. |
| `childe` | Build target selection helper. |
| `garnish` | Configure flag management helper. |
| `dishy` | Workspace cleanup and reset helper. |
| `sous` | Bake runtime maintenance, repair, update, and uninstall helper. |

---

## Configuration Files

Bake uses these files from the directory where Bake is run:

| File | Purpose |
| ---- | ------- |
| `recipe_book.conf` | Build target matrix. Controls which targets are enabled. |
| `build_flags.list` | Persistent configure and dependency flags. |
| `version.properties` | Bake version metadata. |

Target output and logs are also written relative to the run directory.

---

## Cleaning the Workspace

Use `dishy` to clean the build workspace.

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
./dishy <coin_name> [-i]
```

---

## Runtime Maintenance with Sous

`sous` manages the Bake runtime environment.

Typical uses include:

- repairing incomplete runtime installations
- updating runtime libraries
- uninstalling Bake runtime components

Example:

```bash
./sous
```

---

## 📜 Logging and Artifacts

Bake writes structured logs and generated archives relative to the run directory.

Primary paths:

```text
bakery.log
run-logs/<coin_name>/depends/
run-logs/<coin_name>/build/
special-delivery/
```

Log categories include:

- Bake startup and runtime bootstrap
- host validation
- dependency cleanup
- dependency build output
- project configure/build output
- packaging output
- checksum generation

Final release archives and global checksums are written to:

```text
special-delivery/
```

---

## 📦 Requirements

Required:

- Debian / Ubuntu / Linux Mint style Linux host
- `apt-get`
- `dpkg`
- `sudo` privileges
- internet connection
- `git`

Installed or checked by Bake as needed:

- compiler and build tooling
- cross-compilers for supported targets
- dependency build requirements
- archive/checksum tools

Optional but useful:

- `screen` for long remote build sessions
- `whiptail` or `dialog` for helper tools that use menus

---

## Contributing

Pull requests and issues are welcome.

Guidelines:

- Keep Bake coin-agnostic where practical
- Maintain modular tool boundaries
- Document new flags and behavior in this README
- Keep command help and README usage examples aligned
- Preserve deterministic and reproducible build behavior
- Keep scripts readable and auditable

See [`CONTRIBUTING.md`](CONTRIBUTING.md) for full development guidelines.

---

## License

Bake is released under the **MIT License**.

See [`LICENSE`](LICENSE) for details.

---
