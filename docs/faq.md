# ❓ **bake** Toolchain FAQ

Frequently asked questions about the **bake Toolchain**.

---

## Why the name change from `bake.sh` to `bake`?

There are a few reasons for the change:

- **B**itoreum m**ake** → `bake`
- Fewer characters to type, which reduces the chance of typing errors
- The project started as a small script but has grown into a larger toolchain, making a cleaner command name more appropriate

---

## What platforms can I build for?

Bake supports Debian-based Linux distributions and can build for the following targets:

- Linux 64‑bit (`x86_64-pc-linux-gnu`)
- Linux 32‑bit (`i686-pc-linux-gnu`)
- Linux ARM 32‑bit (`arm-linux-gnueabihf`)
- Linux ARM 64‑bit (`aarch64-linux-gnu`)
- Raspberry Pi 4+ (`aarch64-linux-gnu`)
- Ampere ARM servers (`aarch64-linux-gnu`)
- Windows 64‑bit (`x86_64-w64-mingw32`) — cross‑compiled

---

## Why does Bake install Python 3.10.17?

Crystal Bitoreum was forked from Bitoreum, which was forked from Raptoreum, which in turn was forked from DASH and originally based on Bitcoin.

Some dependencies in this lineage still require **Python 3.10**.

Modern operating systems typically ship with Python 3.12 or newer. `bake` installs the **final release of Python 3.10** (3.10.17), as an alternate installation so those dependencies can run without interfering with the system Python.

This installation:

- Does **not** replace the system Python
- Is used only by Bake during the build process
- Runs within the build environment (often inside a `screen` session)

---

## Where are the final `.tar.gz` or `.zip` build files?

Finished build archives are placed in:

```
../bake/special-delivery
```

Each archive typically contains:

- Compiled binaries
- Supporting files
- A checksum file for verification

---

## Can I run Bake multiple times?

Yes.

However, if you want to reset your workspace or remove old build artifacts, you should run:

```
./dishy
```

---

## Can I run Bake on a VPS?

Yes, although you may need to make a few adjustments depending on your server resources.

Recommended steps:

- Add swap space if your VPS has **less than 2GB RAM**
- Use a `screen` session to avoid losing long builds if your SSH connection drops

Future versions of `bake` may include additional options for limiting CPU thread usage.

---

## The build is slow — what can I do?

Compilation speed is largely dependent on system resources.

To improve build performance:

- Use a machine with more CPU cores
- Ensure you are not building inside a low‑power container
- Add additional RAM or swap space

---

## Can I build using my own fork of a project?

Yes.

Bake was designed to support building from **custom repositories**, not just the default Bitoreum source.

You can provide:

- a custom repository URL
- a branch or tag to build

This allows Bake to work with many compatible projects.

---

## How do I verify build checksums?

Inside each build directory or archive you will find a checksum file.

To verify:

```
sha256sum -c checksums-<version>.txt
```

This ensures the binaries were packaged correctly and have not been modified.

---

## How do I clean up old builds?

Every good kitchen needs a **Dishy**.

Dishy is the workspace cleanup tool included with Bake.

```
./dishy [<coin-name>] [-i]
```

Notes:

- Defaults to **Bitoreum** if no coin name is specified
- The `-i` option resets the workspace to a fresh download state

⚠️ This operation can remove build artifacts and downloaded sources, so use it carefully.

---

## Still have questions?

If your question is not covered here, open an issue:

https://github.com/Nikovash/bake/issues
