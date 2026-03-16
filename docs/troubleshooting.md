# 🛠️ Troubleshooting

This guide helps diagnose and resolve common issues when using the **Bake build toolchain**.

If a build fails, the most important step is to **check the logs first**. Bake provides structured logging to help identify problems quickly.

---

# 🚫 Common Problems & Fixes

## Nothing happens after running Bake

Ensure the script is executable:

```bash
chmod +x bake
```

Run Bake using:

```bash
./bake <branch-or-tag>
```

Do not attempt to run the script without `./`

---

## Build Fails Midway

Look for output similar to:

```
make[2]: *** [target] Error
```

When this happens:

1. Scroll **upward** to find the **first error message**.
2. That error is usually the real cause of the failure.

You should also inspect Bake logs:

```
../bake/bakery.log
../bake/run-logs/
```

These logs contain detailed output from dependency compilation, configuration, and build stages.

---

## Permission Denied

If you encounter a `Permission denied` error:

- Ensure you are working inside a **user-writable directory** (such as your home directory).
- Do **not run Bake entirely with `sudo`**.

Bake internally uses `sudo` only for steps that require system-level installation.

---

## Configure Errors

Errors such as:

```
configure: error: something failed
```

usually indicate **missing development dependencies**.

Check the lines immediately above the error message to determine which dependency is missing.

Typical missing packages include:

- development libraries (`*-dev`)
- cross-compile headers
- architecture-specific toolchains

Some cross-compilation environments may require additional packages depending on your Linux distribution.

---

## Missing Binaries After Build

If Bake finishes but no binaries appear in the final archive:

Check the delivery folder:

```
../bake/special-delivery/
```

If the directory is empty, the build likely failed earlier during compilation.

Review:

```
..bake/run-logs/
../bake/bakery.log
```

to locate the first error.

---

## Rebuilding After Failure

If a build fails and you want to reset the workspace, use **Dishy**:

```bash
./dishy
```

To reset the workspace to a **fresh download state**:

```bash
./dishy -i
```

⚠️ The `-i` option removes build artifacts and downloaded source directories.

---

## Not Enough RAM / System Freezes

Large builds can consume significant RAM.

If you are building on a small VPS or embedded system:

### Add swap space

```bash
sudo fallocate -l 4G /swapfile
sudo chmod 600 /swapfile
sudo mkswap /swapfile
sudo swapon /swapfile
```

### Use fewer build threads

Some systems may struggle with high parallel builds.

You can limit build threads by modifying your environment before running Bake:

```
export MAKEFLAGS="-j2"
```

Lower values reduce memory usage but increase compile time. Future version will likelt have a thread flag, for now this is not the case.

---

# 📜 Logs

Bake generates structured logs to help diagnose failures.

Primary locations:

```
../bake/bakery.log
../bake/run-logs/
```

Logs may include:

- dependency compilation output
- configure stage output
- compiler output
- packaging stages

Always include relevant logs when reporting issues.

---

# 📬 Still Stuck?

If you cannot resolve the issue:

Open an issue on GitHub:

https://github.com/Nikovash/bake/issues

Please include:

- Your **Linux distribution**
- Your **CPU architecture**
- The **Bake command used**
- Relevant **error output**
- Any relevant **log files**

This information helps diagnose problems much faster.
