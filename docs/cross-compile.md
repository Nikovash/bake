# Cross Compilation Notes

This document provides **known working examples** for cross-compiling builds using the `bake` Toolchain.

Cross-compiling requirements vary significantly between Linux distributions, toolchain versions, and kernel header packages. The examples below were tested primarily using:

- **Ubuntu 18.04 (x86_64)** as the build host
- Various cross-compilation targets

These instructions should be treated as **starting points**, not universal solutions.

`bake` will attempt to build using the available toolchain, but additional packages may be required depending on your distribution and target architecture.

---

# x86_64 → ARM (32‑bit)

Install the ARM 32-bit cross toolchain:

```bash
sudo apt-get update
sudo apt-get install \
    gcc-arm-linux-gnueabihf g++-arm-linux-gnueabihf \
    binutils-arm-linux-gnueabihf libc6-dev-armhf-cross
```

This toolchain allows building binaries targeting **ARMv7 / armhf systems**.

---

# x86_64 → i686 (32‑bit Linux)

## Ubuntu 18.04 (GCC 7.5)

```bash
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install \
    gcc-7-multilib g++-7-multilib libc6-dev-i386 \
    lib32stdc++-7-dev libstdc++-7-dev:i386
```

## Newer Ubuntu Versions (GCC 9/10/11+)

```bash
sudo dpkg --add-architecture i386
sudo apt-get update
sudo apt-get install \
    g++-multilib libc6-dev-i386 lib32stdc++-dev
```

This configuration allows building **32-bit Linux binaries** from a 64-bit system.

---

# x86_64 → ARM64 (aarch64)

Install the ARM64 cross compiler:

```bash
sudo apt-get update
sudo apt-get install \
    gcc-aarch64-linux-gnu g++-aarch64-linux-gnu libc6-dev-arm64-cross
```

This enables compilation for **64-bit ARM systems** such as:

- ARM servers
- Raspberry Pi 4/5 (64-bit OS)
- modern ARM SBC platforms

---

# Notes

Some of these toolchains may already be partially handled by Bake scripts.
Others may need to be installed manually depending on your system.

Because distributions differ widely, you may occasionally need to install
additional headers or libraries to complete a build.

If you encounter issues, check:

- compiler versions
- architecture packages
- kernel header availability
- libc development packages

Cross-compilation environments can vary widely between systems.

---

# Final Advice

Cross-compiling can sometimes require experimentation depending on your host
distribution and target architecture.

Use these examples as a foundation, adapt them as needed for your environment,
and keep moving forward.

You know… 

**Don't stop believing.**
