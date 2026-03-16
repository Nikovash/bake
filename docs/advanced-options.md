# Bake Advanced Usage

This document describes the advanced functionality of the Bake toolchain.
These options expose the full capabilities of each tool and are intended for
users who want deeper control over the build process.

Bake is intentionally designed so the **basic workflow remains simple**, while
advanced users can customize almost every step of the compilation pipeline.

---

# Bake Command (Advanced)

The primary Bake command supports several flags that modify the behavior of the
build system.

```
./bake <branch-or-tag> [<coin-name> <github-repo-url>] [-d] [-c] [-g] [-f] [-r]
```

### Source Download Only

```
./bake <branch-or-tag> -d
```

Downloads the source code but does not begin compilation.

This is useful when:

- Preparing a workspace in advance
- Inspecting source before compiling
- Working in restricted build environments

---

# Childe (Target Selection)

The **childe** (named after **Julia Child**), tool allows the user to select compilation targets.

Example:

```
./bake <branch-or-tag> -c
```

This launches an interactive menu where the user may select supported build
targets.

Typical targets include:

- Linux
- Windows cross‑compile
- ~~MacOS support planned for future release~~

Some distributions may require additional cross‑compile headers or libraries.
These requirements vary by system and are outside the scope of this document.

Selections are saved so that future builds use the same targets unless changed.

---

# Garnish (Configure Flags)

The **garnish** tool manages configure flags used during the `./configure` stage
of the build.

Example:

```
./bake <branch-or-tag> -g
```

This launches an interactive menu listing common `configure` flags in a human
readable format.

Examples of configurable options may include:

- GUI builds
- wallet features
- dependency toggles
- build optimizations

Once a configuration is created it becomes **persistent**.

Future builds will automatically reuse the selected flags unless:

- the configuration file is deleted
- the user runs garnish again and changes the selection

If no configuration exists, `bake` falls back to the default flags defined in
`configure.ac`.

---

# Full Configuration Mode

```
./bake <branch-or-tag> -f
```

This launches both tools in sequence:

1. **Childe** – choose build targets
2. **Garnish** – configure build flags

This mode is typically used when:

- Preparing a new environment
- Building a project for the first time
- Changing compilation behavior

---

# Dishy (Workspace Management)

The **dishy** tool manages build cleanup.

Standard cleanup:

```
./dishy
```

This removes build artifacts while preserving downloaded source.

---

### Full Workspace Reset

```
./dishy -i
```

Attempts to resets the project to a **fresh download state**.

This removes:

- compiled binaries
- build artifacts
- downloaded source directories

Use this option when:

- troubleshooting build failures
- testing clean builds
- preparing reproducible build environments

---

# Sous (Maintenance Tool)

The **sous** tool manages the Bake runtime environment.

Typical responsibilities include:

- repairing incomplete Bake installations
- updating runtime assets
- removing Bake components

Example usage:

```bash
./sous # whiptail graphical use
```

```bash
./sous [-up][-f][-r][-uninstall]
```



| Flag           | Usage                                   |
| -------------- | --------------------------------------- |
| **-up**        | Checks/Updates Toolchain                |
| **-f**         | Forces Update To Current Branch tip     |
| **-r**         | Attempts to repair the `bake` toolchain |
| **-uninstall** | Uninstalls toolchain                    |

# First Run (Environment Bootstrap)

The **first_run** tool prepares a new system for Bake.

Typical responsibilities include:

- installing required dependencies
- preparing system directories
- initializing Bake configuration files
- installing shared libraries such as `kitchen.lib`

Example repair run:

```bash
./first_run
```

This attempts to repair missing Bake components without fully reinstalling the
environment.

This command is useful if:

- `/opt/bake` is incomplete
- required libraries are missing
- the Bake runtime environment becomes corrupted

---

# Build Recovery `formerly refire` [-r]

Build recovery is now handled as a special **Bake** flag.

Typical usage:

```bash
./bake [coin-name] -r
```

This attempts to resume or recover a failed build by reusing the existing workspace instead of forcing a full rebuild. while **bitoreum** is the defualt you can pass the name of any coin downloaded to the system.

This option is helpful when:

- You downloaded only to mod the repor before build
- Build failures that are corrected
- Temporary dependency failures
- Interrupted sessions
- Incomplete compile stages

The `-r` flag uses the existing workspace and logs to determine the most
appropriate point to restart the build process.

---

# Logging and Diagnostics

Bake maintains structured logs to assist troubleshooting.

Primary locations:

```
../bake/bakery.log
../bake/run-logs/
```

Logs include:

- dependency compilation
- configure output
- compile stages
- packaging operations

These logs should always be included when reporting build issues.

---

# Toolchain Architecture

The Bake environment is composed of several modular tools.

| Tool          | Purpose                   |
| ------------- | ------------------------- |
| bake          | primary build driver      |
| dishy         | workspace cleanup         |
| childe        | target selection          |
| garnish       | configure flag management |
| first_run     | environment bootstrap     |
| sous          | Toolchain Maintainer      |
| kitchen.lib   | shared function library   |
| asset_pull.sh | asset management          |

This modular architecture allows each component to evolve independently while
maintaining a consistent build workflow.

---

# Notes for Advanced Users

Bake is intentionally designed so that:

- default behavior remains simple
- advanced functionality remains optional
- builds remain deterministic whenever possible

Users are encouraged to inspect the scripts directly if deeper customization is
required.

`bake` remains a **transparent build system**, not a black box.
