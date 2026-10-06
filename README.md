# Wurl

Wurl protocol specification and reference implementation.

## Motivation



## Specification



## Reference Implementation

### Install Release

Stable versioned releases can be found on the [Releases page](https://github.com/widberg/wurl/releases).

### Build from Source

#### Prerequisites

* [Git](https://git-scm.com/)
* [Zig](https://ziglang.org/) 0.17.0

#### Checkout

```sh
git clone https://github.com/widberg/wurl.git
cd wurl
```

#### Build

```sh
zig build -Doptimize=ReleaseSafe
```

#### Test

```sh
zig build test
```

### Install

#### Windows

Save the following to `wurl.reg` and run it to add a protocol handler to Windows. Be sure to fix the path to `wurl.exe`.

```reg
Windows Registry Editor Version 5.00

[HKEY_CLASSES_ROOT\wurl]
"URL Protocol"=""
@="URL:wurl"

[HKEY_CLASSES_ROOT\wurl\shell]

[HKEY_CLASSES_ROOT\wurl\shell\open]

[HKEY_CLASSES_ROOT\wurl\shell\open\command]
@="\"D:\\programming\\widberg\\wurl\\zig-out\\bin\\wurl.exe\" \"%1\""
```

#### Linux

You're smart. You'll figure it out. :3

#### MacOS

There's probably a `.plist` somewhere you need to edit. Good luck!

### Example Config

The config is loaded from `wurl.zon` next to `wurl.exe`.

```zon
.{
    .imhex = "imhex",
    .vscode = "code",
    .ghidra = "C:\\Users\\widberg\\AppData\\Local\\gvm\\ghidra_12.1.4_PUBLIC\\support\\GhidraGo\\GhidraGo.bat",
    .files = .{
        .{
            .hash = "e02b9c3c14fe3226cb11982e61e4bc2b5698df7c9c3e02174e18e7fd6d07bee5",
            .path = "C:\\Users\\widberg\\Downloads\\Disney-Pixar Cars - Race-O-Rama (USA, Europe) (En,Fr,De,Es,It)\\default.xex",
            .ghidra = .{
                .project = .{
                    .non_shared = .{
                        .path = "C:/Users/widberg/Downloads/cars",
                        .name = "cars"
                    }
                },
                .program = "default.xex"
            }
        },
        .{
            .hash = "5b651ba0a41d821d9670f2387c3ab503af594e57cf61c55aa35cb80ac58171ca",
            .path = "D:\\programming\\widberg\\wurl\\LICENSE"
        }
    }
}
```

### Example Links

Have fun clicking these!

* [e02b9c3](wurl:e02b9c3)
* [e02b9c3@822FD26C](wurl:e02b9c3@822FD26C)
* [e02b9c3#00CAFE](wurl:e02b9c3c14fe3226cb11982e61e4bc2b5698df7c9c3e02174e18e7fd6d07bee5#00CAFE)
* [5b651ba:15](wurl:5b651ba:15)
* [5b651ba:3:4](wurl:5b651ba0a41d821d9670f23:3:4)
* [5b651ba#01A](wurl:5b651ba0a41d821d9670f2387c3ab503af594e57cf61c55aa35cb80ac58171ca#01A)
