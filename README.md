# Wurl

Wurl protocol specification and reference implementation.

## What is Wurl?

Wurl is a URI for sharing references to resources among members of a reverse engineering project.

## Motivation

I find myself in need of a way to refer to disparate files and locations within those files in a compact, universal, timeless, and normalized form. This would be useful while editing wikis, collaborating with others, and leaving notes for my future self.

### Requirements

* Disparate files: can handle executables, libraries, binary resources, text, etc...
* Compact: as short as possible while still accomplishing the other requirements.
* Universal: two people with different project configurations should understand a reference the same.
* Timeless: references should not need to be updated when information is learned or forgotten.
* Normalized: only one valid representation of any given reference.

It should be easy to accept that each of those requirements have an objective measure. I also want to tack on that I would prefer the references be pleasant to look at, but I admit that is entirely subjective and up to my own preferences.

### Prior Art

One way to attempt to do this is in prose: "In `FUEL.exe` from the Russian release at address `0x009A8310`." This doesn't really hold up: (1) it is far from compact, (2) if a second Russian release disk is found, it becomes ambiguous which executable is being referred to, and (3) there are many valid ways to write a sentence to convey that information, so it is not normalized.

Another way is to use your software reverse engineering toolkit's protocol handler functionality: [`ghidra:` (GhidraGo)](https://www.ghidradocs.com/12.1.4_PUBLIC/help/GhidraGo/help/topics/GhidraGo/GhidraGo.html), [`binaryninja:`](https://docs.binary.ninja/guide/index.html#loading-files), and [`ida:` (Heimdallr)](https://www.interruptlabs.co.uk/articles/heimdallr-a-way-to-integrate-ida-pro-into-obsidian-notes). These are certainly a step in the right direction, but they still don't meet all my requirements: (1) it isn't universal since I can't share a link to my Ghidra project with someone using Binary Ninja, and maybe not even someone else using Ghidra if the link uses a symbol name they don't have in their project or their project is at a different path on their computer than mine, (2) they aren't timeless; if I win the lottery tomorrow and buy IDA Pro I'll have to pay someone go update all my links too, and (3) there are many ways to refer to the same location with these protocols (address, section + offset, label), so it is not normalized.

The protocol strings themselves are not compact but since they are proper protocols you can hide them behind text and write something like: "[...] and that thing happens [here](https://www.youtube.com/watch?v=QREQ4F-CT8M)." So they get a pass from me, at least in places where you're viewing the rendered page more often than the Markdown. And some of the universality concerns can be solved by having everyone in a community agree to use the same Ghidra server, but servers go down and move, so that's not a complete solution.

Finally, some editors allow you to run them with arguments to open a file with the cursor at a specified position, e.g. `code.exe --goto file.txt:10:2` or `imhex.exe --open file.bin --select 0x10` (you can't actually combine `open` with `select` in ImHex right now). This suffers all of the same flaws as the SRE toolkit protocols with the added drawback that they aren't clickable.

So, there are plenty of good solutions that would work without issue if you were working on a short lived project alone or in a small group with shared preferences and confidence in their tool choices. Everything I mentioned has a purpose and serves it well, I just need something with a different purpose to fulfil my requirements.

## Specification


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
