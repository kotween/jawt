# jawt

Cross-platform Rust bindings to Java AWT. Contains bindings to platform-specific APIs targeting Windows, MacOS, and X11 as well. Compatible with the [jni-sys](https://crates.io/crates/jni-sys) crate.

## Packages

- jawt-sys: Generated with `bindgen` 0.69 with the AWT headers in OpenJDK 17.

## How to re-generate bindings

Run [./generate.ps1](./generate.ps1) on PowerShell. This will install bindgen 0.69 in `.bindgen` to prevent updating the bindgen in `CARGO_HOME`.

## Versions

### jawt-sys

| jawt-sys | OpenJDK | jni-sys | x11-dl | MSRV |
| -------- | ------- | ------- | ------ | ---- |
| 0.1.0    | 17      | 0.4.0   | 2.19.1 | 1.73 |

## Licensing

Dual-licensed under MIT and Apache License version 2.0.
