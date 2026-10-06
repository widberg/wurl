# Wurl

Wurl protocol specification and reference implementation.

## Motivation

Widberg Uniform Resource Locator

I find myself in need of a way to refer to disparate files and locations within those files in a compact, unambiguous, universal, timeless, and normalized form. This would be useful while editing this wiki, collaborating with others, and leaving notes for my future self.

## Requirements

* Disparate files: can handle executables, libraries, binary resources, text, etc...
* Compact: as short as possible while still accomplishing the other requirements.
* Unambiguous: a reference should be understood without sharing additional context.
* Universal: two people with different project configurations should understand a reference the same.
* Timeless: references should not need to be updated when information is learned or forgotten.
* Normalized: only one valid representation of any given reference.

## Prior Art

One way to attempt to do this is in prose: "In `FUEL.exe` from the Russian release at address `0x009A8310`." This doesn't really hold up: (1) it is far from compact, (2) if a second Russian release disk is found, it becomes ambiguous which executable is being referred to, (3) there are many valid ways to write a sentence to convey that information, so it is not normalized.

Another way is to use your software reverse engineering toolkit's protocol handler functionality: [`ghidra://` (GhidraGo)](https://www.ghidradocs.com/12.1.4_PUBLIC/help/GhidraGo/help/topics/GhidraGo/GhidraGo.html), [`binaryninja://`](https://docs.binary.ninja/guide/index.html#loading-files), and [`ida://` (Heimdallr)](https://www.interruptlabs.co.uk/articles/heimdallr-a-way-to-integrate-ida-pro-into-obsidian-notes). These are certainly a step in the right direction, but they still don't meet all my requirements: (1) 

codex.exe file.txt:10:2
imhex.exe --open file.bin --select 10

https://docs.oracle.com/javase/tutorial/java/package/namingpkgs.html

https://git-scm.com/book/en/v2/Git-Tools-Revision-Selection

## Addresses

## Offsets

imhex

@
#
:

wurl://


https://en.wikipedia.org/wiki/Robustness_principle

extensions after "?"

encourage customization

The extension stuff should not be vital to understanding. it should be safe to hide that in the link and not visible in the text. something like the view equals thing from the Ida extension

ranges by separating with a "-" and multiple selection by separating with commas


who is this for? me. I am not pitching this as a standard. I'm just making something that I plan on using public. I have no aspirations of this being a standard


programs with multiple address spaces. aaaa@lowbus:0000100 maybe?

https://github.com/iximeow/yaxpeax-arch/issues/8#issuecomment-4682404862

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
