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

The scripts use:

`$HOME/.local/state/termux-desktop`

This location stores desktop runtime state and logs.

## Development Status

The scripts originate from an existing Termux installation.
Portability, installation, dependency verification, startup, and
recovery behavior must be tested in a clean Termux environment
before the project can be considered a universal installer.

## Security

Never commit credentials, private logs, PID files, or other sensitive
runtime information.

## References

- Termux: https://github.com/termux/termux-app
- Termux:X11: https://github.com/termux/termux-x11
