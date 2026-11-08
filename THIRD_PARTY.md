# Third-Party Components and Licensing

The repository as a whole is released under the [MIT License](LICENSE), with
the exceptions listed below.

## Kernel module: `oneUpPower`

`src/argon-oneup-battery/usr/src/oneUpPower-1.0/` contains the CW2217 battery
driver. It is licensed under **GPL-2.0-only** (see the SPDX headers in the
source files), matching the Linux kernel licensing requirements.

## wf-panel-pi battery widget source

`extras/argon-wfplug-batt/usr/src/wfplug-batt/` is derived from the Raspberry
Pi `wf-panel-pi` / `pplug-batt` battery plugin. The upstream files carry:

```text
Copyright (c) 2018-2025 Raspberry Pi
All rights reserved.
```

These files are **not** covered by this repository's MIT license. The
`argon-wfplug-batt` package redistributes them and a correspondingly linked
`libbatt.so`. Do not relicense or redistribute them without permission from the
copyright holder.

## External packages

`rpi-suspend` is maintained in its own upstream repository and is not part of
this source tree. See that project for its license terms.
