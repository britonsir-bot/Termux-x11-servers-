# Termux X11 Desktop Supervisor

A collection of Bash scripts for launching, supervising, and managing
an XFCE desktop environment inside Termux using Termux:X11.

## Features

- Desktop startup and management
- XFCE session supervision
- Desktop watchdog and recovery
- Memory scheduling
- Adaptive memory management

## Project Structure

```text
termux-x11-desktop/
├── README.md
├── .gitignore
└── src/
    ├── launchers/
    │   ├── desktop
    │   └── linux-desktop.sh
    ├── supervisor/
    │   ├── xfce-supervisor.sh
    │   └── desktop-watchdog.sh
    └── memory/
        ├── memory-scheduler.sh
        └── adaptive-memory-manager.sh
```

## Requirements

- Android with Termux installed
- Termux:X11
- XFCE and the commands required by the scripts

## Runtime State

The original scripts use:

`$HOME/.local/state/termux-desktop`

This location stores desktop runtime state and logs. The scripts originate
from an existing Termux installation and require portability testing
before they can be considered a universal installer.

## Installation

Installation instructions will be added after dependencies and startup
behavior have been verified on a clean Termux environment.

## Security

Review all source files before publishing. Never commit credentials,
access tokens, private logs, PID files, or other sensitive information.

## Project Status

Initial repository setup. Portability, installation, and recovery testing
are pending.
