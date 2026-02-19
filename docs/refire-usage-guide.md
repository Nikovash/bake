# Refire Usage Guide

`refire.sh` is a rebuild utility for Bitoreum-style coins that mirrors
the packaging format of `bakery.sh`, but **does not perform any Git
operations**. It rebuilds `depends`, rebuilds the main binaries, and
packages artifacts into `./special-delivery`.

------------------------------------------------------------------------

## Overview

-   Rebuilds from existing local source tree\
-   Preserves local edits (no git pull/reset)\
-   Uses `recipe_book.conf` to determine enabled targets\
-   Produces **Bakery-style archive naming**\
-   Supports release name override via `-rf` flag\
-   Automatically flags **Ubuntu 18.x as `Generic`** in archive naming

------------------------------------------------------------------------

## Basic Usage

``` bash
./refire.sh
```

Defaults to:

    bitoreum
    Release suffix: Release

------------------------------------------------------------------------

### Specify Coin

``` bash
./refire.sh yerbas
```

Expected repo location:

    $HOME/yerbas-build/yerbas

------------------------------------------------------------------------

## Release Name Override (`-rf`)

The `-rf` flag replaces the **Release** segment of the compressed
archive filename.

### Default Behavior

Without `-rf`:

    yerbas-ubuntu-22.04_x86_64-Release-1.2.3.tar.gz

### Override Example

``` bash
./refire.sh yerbas -rf nightly
```

Produces:

    yerbas-ubuntu-22.04_x86_64-nightly-1.2.3.tar.gz

------------------------------------------------------------------------

### Multi-Word Release Names

You may pass multiple words:

``` bash
./refire.sh yerbas -rf some Text
```

Becomes:

    some_text

Quotes are **optional for spaces**, but recommended for clarity:

``` bash
./refire.sh yerbas -rf "Some Text"
```

------------------------------------------------------------------------

### Special Characters

If using shell-sensitive characters (`&`, `*`, `$`, etc.), quotes are
required:

``` bash
./refire.sh yerbas -rf "nightly&hotfix"
```

------------------------------------------------------------------------

## How Release Slug Conversion Works

The `-rf` value is sanitized:

-   Converted to lowercase
-   Non-alphanumeric characters become `_`
-   Multiple `_` collapse into one
-   Leading/trailing `_` removed

Example:

    "Beta Build #2!"

Becomes:

    beta_build_2

------------------------------------------------------------------------

## Archive Naming Structure

### Linux Builds

    <coin>-<os_label>_<arch_label>-<release_suffix>-<version>.tar.gz

Example:

    yerbas-ubuntu-22.04_x86_64-nightly-1.2.3.tar.gz

------------------------------------------------------------------------

### Windows Builds

    <coin>-Generic-<arch_label>-<release_suffix>-<version>.zip

Example:

    yerbas-Generic-Win64_x86-nightly-1.2.3.zip

------------------------------------------------------------------------

## Ubuntu 18.x Behavior

If the build host is:

    Ubuntu 18.x

The OS label is automatically set to:

    Generic

Example:

    yerbas-Generic_x86_64-Release-1.2.3.tar.gz

------------------------------------------------------------------------

## recipe_book.conf

Located in project root:

    recipe_book.conf

Format:

    Friendly Target,y|n,QT=y|n

Example:

    Linux 64-bit,y,QT=y
    Linux ARM 64-bit,y,QT=n
    Windows 64-bit,y,QT=y

Only targets marked `y` will build.

------------------------------------------------------------------------

## Output Locations

### Artifacts

    ./special-delivery/

### Run Logs

    ./run-logs/<coin>/<timestamp>/

Includes: - depends logs - configure logs - build logs - summary log

------------------------------------------------------------------------

## Environment Variables

### Disable Binary Stripping

``` bash
STRIP_BINARIES=0 ./refire.sh yerbas
```

Default:

    STRIP_BINARIES=1

------------------------------------------------------------------------

## Common Examples

### Standard rebuild

``` bash
./refire.sh
```

------------------------------------------------------------------------

### Rebuild alternate coin

``` bash
./refire.sh yerbas
```

------------------------------------------------------------------------

### Nightly build tag

``` bash
./refire.sh yerbas -rf nightly
```

------------------------------------------------------------------------

### Custom labeled release

``` bash
./refire.sh yerbas -rf "test build"
```

------------------------------------------------------------------------

### Disable stripping

``` bash
STRIP_BINARIES=0 ./refire.sh yerbas -rf debug
```

------------------------------------------------------------------------

## Design Philosophy

`refire.sh` exists for:

-   Rapid rebuilds
-   Preserving local development state
-   Matching Bakery artifact naming
-   Consistent cross-target packaging
-   Minimal human intervention

It is intentionally **Git-agnostic** and focused purely on deterministic
rebuild + package.
