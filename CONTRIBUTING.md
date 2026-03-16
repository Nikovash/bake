# Contributing to Bake

Thank you for considering a contribution to **Bake**!  
Bake is a modular build toolchain designed to simplify compiling cryptocurrency projects from source while keeping the workflow deterministic and easy to use.

Contributions are welcome in many forms, including bug reports, feature suggestions, documentation improvements, and code contributions.

---

### 🧩 Ways to Contribute

**🐛 Report Bugs**

If you discover unexpected behavior or a build failure:

1. Check existing GitHub issues.

2. If none match, open a new issue.

3. Include relevant logs (for example `bakery.log` or files from `run-logs/`).

---

### ✨ Suggest Features

Have an idea that could improve the `bake` Toolset ?

Open an issue describing:

- The problem

- The proposed solution

- The expected behavior

Feature discussions are always welcome before implementation.

---

### 🛠 Code Contributions (Authorized Contributors)

1. Fork the repository

```bash
git clone https://github.com/Nikovash/bake.git 
cd bake
```



2. Create a branch for your work

```bash
git checkout -b my-feature
```

3. Make your changes

Bake is designed around **modular scripts**, so contributions should preserve that structure and methodology.

4. Commit your work

```bash
git add <files>  
git commit -m "feat(component): short description"
```

5. Push your branch and open a Pull Request

```bash
git push origin my-feature
```

---

# Development Guidelines

Bake follows a few core design principles.

### Keep The Toolchain Modular

Scripts should remain independent components where possible.

Example tools include:

- `bake` — primary build driver

- `dishy` — workspace cleanup

- `childe` — build architecture target selection

- `garnish` — Configure build flag management

- `sous` — `bake` Toolset maintainer and Uninstaller

Shared logic should go into reusable libraries such as `kitchen.lib`.

---

### Maintain Deterministic Builds

Bake aims to produce reproducible builds whenever possible.

Avoid introducing behavior that:

- changes builds unpredictably

- relies on undocumented external tools

- modifies system state outside the Bake workspace

---

### Document New Flags

If you add:

- CLI flags

- configuration options

- new tools

Please update the README, and relevent exrta documentation accordingly.

---

# ✅ Pull Request Guidelines

When opening a Pull Request:

- Keep changes focused

- Include clear commit messages

- Link related issues if applicable

Example commit style:

```bash
- fix(asset_pull): prevent kitchen.lib downgrade  
- feat(dishy): add workspace reset option  
- docs(readme): clarify build flags
```

---

# 💬 Community Standards

Please keep all interactions respectful and constructive.

We welcome collaboration from developers, builders, and users of all experience levels.

Follow the [GitHub Community Guidelines](https://docs.github.com/en/site-policy/github-terms/github-community-guidelines).

---

Your contributions help improve **Bake** and make compiling open-source blockchain software easier for everyone!

<p align="center"> 💙 Your contributions power the chain. </p>
