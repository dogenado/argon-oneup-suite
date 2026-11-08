# wfplug-batt source

This directory contains the source for the enhanced `libbatt.so` battery
widget used by `argon-wfplug-batt`.

## Provenance and licensing

These files are derived from the Raspberry Pi `wf-panel-pi` / `pplug-batt`
battery plugin. The original files carry:

```text
Copyright (c) 2018-2025 Raspberry Pi
All rights reserved.
```

They are **not** covered by the repository's MIT license. See
[`THIRD_PARTY.md`](../../../../../THIRD_PARTY.md) at the repository root for
details. Do not relicense these files without permission from the copyright
holder.

## Rebuilding

The package normally ships a prebuilt aarch64 `libbatt.so`, whose SHA256 is
recorded in `../../share/argon-oneup/wf-panel-pi/libbatt.so.sha256`.
`build_packages.sh` verifies that checksum on every build.

To rebuild from source, provide a wf-panel-pi source checkout and the gtkmm-3
and gtk-layer-shell development files:

```bash
sudo apt install g++ gcc pkg-config libgtkmm-3.0-dev libglibmm-2.4-dev \
                 libgtk-layer-shell-dev
WF_PANEL_PI_SRC=/path/to/wf-panel-pi make
```

The headers live in `src/wf-panel-pi/` (`plugin.h`, `widget.hpp`,
`plug_conf.h`, `notification.h`). The Makefile adds that directory to the
include path automatically.

Then either copy `libbatt.so` over the packaged binary manually, or run:

```bash
REBUILD_LIBBATT=1 WF_PANEL_PI_SRC=/path/to/wf-panel-pi \
  UPDATE_LIBBATT_SHA=1 ./build_packages.sh
```

`REBUILD_LIBBATT=1` requires `src/plugin.h` and `src/widget.hpp` in the
wf-panel-pi source tree. Without that variable, the build only verifies the
prebuilt binary.
