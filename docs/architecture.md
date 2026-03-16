# Bake Architecture

This document describes the internal architecture of the complete **bake Toolchain**.

It is intended for contributors and advanced users who want to understand how the
system works internally.

`bake` is designed around a **modular shell-based toolchain** where each component
has a clearly defined responsibility. The goal is to keep the system transparent,
maintainable, and easy to extend.

---

# Core Design Philosophy

Bake follows several guiding principles:

- **Simplicity first** — the default workflow should require minimal user input.
- **Modularity** — each tool performs a single role.
- **Transparency** — the build process is visible and script-driven.
- **Deterministic builds** — builds should produce consistent results.
- **Minimal system intrusion** — Bake should avoid modifying the host system unnecessarily.

---

# Toolchain Overview

The Bake ecosystem is composed of several independent tools.

| Tool          | Purpose                    |
| ------------- | -------------------------- |
| bake          | Primary build driver       |
| dishy         | Workspace cleanup          |
| childe        | Build target selection     |
| garnish       | Configure flag management  |
| first_run     | Environment bootstrap      |
| kitchen.lib   | Shared function library    |
| asset_pull.sh | Runtime library management |

Each component interacts through shared configuration and common helper
functions provided by **kitchen.lib**.

---

# The Bake Driver

The `bake` script is the entry point for most operations.

Responsibilities include:

- cloning or updating source repositories
- selecting versions (tags or branches)
- coordinating build stages
- invoking helper tools when requested
- packaging final build artifacts

Bake attempts to keep the core workflow simple:

```
./bake <branch-or-tag>
```

Additional flags expose advanced functionality.

---

# Shared Library: kitchen.lib

`kitchen.lib` contains shared functions used across the Bake toolchain.

Typical responsibilities include:

- Logging helpers
- Environment detection
- Path management
- Common build utilities
- Consistent error handling

Using a shared library keeps the individual tools smaller and easier to maintain.

---

# Asset Management

Bake manages shared runtime components using **asset_pull.sh**.

Responsibilities include:

- ensuring `kitchen.lib` exists in `/opt/bake`
- upgrading the library when a newer version is available
- repairing incomplete Bake installations
- downloading runtime assets if local copies are missing

This mechanism ensures the runtime environment stays consistent across systems.

---

# Runtime Environment

Bake installs certain shared components into:

```
/opt/bake
```

Typical contents:

```
/opt/bake
├── kitchen.lib
├── bake.info
```

This directory allows Bake tools to share state and runtime libraries
independent of the working repository.

---

# Workspace Layout

Inside the Bake repository, a typical structure looks like:

```
bake/
├── bake
├── dishy
├── childe
├── garnish
├── first_run
├── sous
├── assets/
│   ├── kitchen.lib
│   └── asset_pull.sh
├── run-logs/
├── special-delivery/
└── bakery.log
```

Important directories:

| Directory        | Purpose                      |
| ---------------- | ---------------------------- |
| run-logs         | detailed build logs          |
| special-delivery | final packaged binaries      |
| assets           | shared scripts and libraries |

---

# Logging System

Bake generates structured logs for debugging.

Primary locations:

```
bakery.log
run-logs/
```

Logs include:

- Dependency compilation
- Configure output
- Compiler output
- Packaging operations

These logs should be included when reporting build issues.

---

# Build Flow

A typical Bake build follows this sequence:

1. **Source acquisition**
   
   - clone or update repository

2. **Environment preparation**
   
   - dependency checks
   - toolchain setup

3. **Configuration**
   
   - configure flags applied
   - optional garnish selections

4. **Compilation**
   
   - make / build steps

5. **Packaging**
   
   - binaries archived
   - checksums generated

6. **Delivery**
   
   - artifacts stored in `special-delivery`

---

# Extending Bake

New tools or features should follow the existing design philosophy:

- keep scripts modular
- avoid duplicating logic already present in `kitchen.lib`
- document new flags and functionality
- maintain predictable build behavior

Whenever possible, new functionality should integrate with the existing
Bake workflow rather than replacing it.

---

# Final Notes

Bake intentionally avoids becoming a complex build framework.

Instead, it aims to remain a **transparent and hackable build system** that users can easily inspect and modify.

If you want to understand how something works in `bake`, the best place
to start is always the scripts themselves.










































