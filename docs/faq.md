# ❓ Frequently Asked Questions (FAQ)

---

### Q: Why the name change from `bake.sh` to `bake`?

A: There are a couple of reasons, 

- **B**itoreum m**ake** = `bake`
- Fewer characters to type, leading to hopefully less errors
- bake started off as a simple script, it has gotten a bit more complex these days beffiting a a stronger less complex name

### 🔧 Q: What platforms can I build for?

A: The script supports Debian fork Linux Distributions with the following architecture types:

- Linux 64-bit		(`x86_64-pc-linux-gnu`)
- Linux 32-bit		(`i686-pc-linux-gnu`)
- Linux ARM 32-bit	(`arm-linux-gnueabihf`)
- Linux ARM 64-bit	(`aarch64-linux-gnu`)
- Raspberry Pi 4+	(`aarch64-linux-gnu`)
- Ampere		(`aarch64-linux-gnu`)
- Windows 64-bit	(`x86_64-w64-mingw32`) Cross compile

---

### 🐍 Q: Why does it install Python 3.10.17?

A: Crystal Bitoreum was forked from, Bitoreum, which was forked from Raptoreum, which was forked from Dash, which was based on Bitcoin, some of these dependecies require Python 3.10. Modern OS's have moved onto Python 3.12+. This script installs the last version of Python 3.10 as an alt install. This does not disrupt the python required for your OS and can be called relative to the instance of a terminal window, hence the use of screen.

---

### 📦 Q: Where are the final `.tar.gz` and/or `*.zip` files?

A: Compressed binaries are placed in:

```bash
../bake/special-delivery
```

Each `.tar.gz` or `*.zip` archive includes binaries and a checksum file.

---

### 🔁 Q: Can I run the script multiple times?

A: Yes, although in order to clean up your workspace consider running `dishy`

---


### 🖥️ Q: Can I run this on a VPS?

A: Yes, but you may need to:

- Add swap space if you have <2GB RAM
- We are working on adding the ability to reduce thread use as a future option

---

### 📉 Q: The build is slow — what can I do?

A:

- Use a machine with more CPU cores
- Ensure you’re not building inside a low-power container or VM
- Add RAM or swap for large builds

---

### 🔑 Q: Can I build with my own fork?

A: Absolutely. We have gone through great lenghts to allow this toolchain to be use with a variety of other projects

---

### 📜 Q: How do I verify checksums?

Inside each build folder or `.tar.gz` or `*.zip` archive:

```bash
sha256sum -c checksums-<version>.txt
```
---

### 🧼 Q: How do I clean up old builds?

Within the `bake` folder is a new helper, every good kitchen needs a dishy! This action is destructive, so use with caution!!!
```bash
../bake/./dishy [<coin-name>] [-i] # Defaults to bitoreum if no coin is passed
```
---

Still have questions?  
Open an issue at: [https://github.com/Nikovash/bake/issues](https://github.com/Nikovash/bake/issues)
