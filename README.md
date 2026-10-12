# Wurl

Wurl is a URI scheme for sharing references to resources among members of a reverse engineering project.

## Motivation

I find myself in need of a way to refer to disparate files and locations within those files in a compact, universal, timeless, and normalized form. This would be useful while editing wikis, collaborating with others, and leaving notes for my future self.

### Requirements

* Disparate files: can handle executables, libraries, binary resources, text, etc...
* Compact: as short as possible while still accomplishing the other requirements.
* Universal: two people with different project configurations should understand a reference the same.
* Timeless: references should not need to be updated when information is learned or forgotten.
* Normalized: only one valid representation of any given reference.

### Prior Art

One way to attempt to do this is in prose: "In `FUEL.exe` from the Russian release at address `0x009A8310`." This doesn't really hold up: (1) it is far from compact, (2) if a second Russian release disk is found, it becomes ambiguous which executable is being referred to, and (3) there are many valid ways to write a sentence to convey that information, so it is not normalized.

Another way is to use your software reverse engineering (SRE) toolkit's protocol handler functionality: [`ghidra:` (GhidraGo)](https://www.ghidradocs.com/12.1.4_PUBLIC/help/GhidraGo/help/topics/GhidraGo/GhidraGo.html), [`binaryninja:`](https://docs.binary.ninja/guide/index.html#loading-files), and [`ida:` (Heimdallr)](https://www.interruptlabs.co.uk/articles/heimdallr-a-way-to-integrate-ida-pro-into-obsidian-notes). These are certainly a step in the right direction, but they still don't meet all my requirements: (1) it isn't universal since I can't share a link to my Ghidra project with someone using Binary Ninja, and maybe not even someone else using Ghidra if the link uses a symbol name they don't have in their project or their project is at a different path on their computer than mine, (2) they aren't timeless; if I win the lottery tomorrow and buy IDA Pro I'll have to pay someone go update all my links too, and (3) there are many ways to refer to the same location with these URIs (address, section + offset, label), so it is not normalized.

The URIs themselves are not compact, but since they are proper URIs, you can hide them behind text and write something like: "[...] and that thing happens [here](https://www.youtube.com/watch?v=QREQ4F-CT8M)." So they get a pass from me, at least in places where you're viewing the rendered page more often than the Markdown. And some of the universality concerns can be solved by having everyone in a community agree to use the same Ghidra server, but servers go down and move, so that's not a complete solution.

Finally, some editors allow you to run them with arguments to open a file with the cursor at a specified position, e.g. `code.exe --goto file.txt:10:2` or `imhex.exe --open file.bin --select 0x10` (you can't actually combine `open` with `select` in ImHex right now). This suffers all of the same flaws as the SRE toolkit URIs, with the added drawback that they aren't clickable.

So, there are plenty of good solutions that would work without issue if you were working on a short-lived project alone or in a small group with shared preferences and confidence in their tool choices. Everything I mentioned has a purpose and serves it well; I just need something with a different purpose to fulfil my requirements.

## Specification

### Scheme

Wurl URIs start with the `wurl:` scheme. The scheme-specific part is human-readable and writable, so you may want to hide the scheme behind link text for brevity on a rendered page, `[e02b9c3@822FD26C](wurl:e02b9c3@822FD26C)`. But the scheme-specific part should always be visible so people without a Wurl protocol handler installed can see the pieces they need to understand the reference. These URIs are meant to be used like a citation: "FUEL loads settings from the Windows Registry ([e02b9c3@822FD26C](wurl:e02b9c3@822FD26C))."

While it is convenient to have it be a URI so it can be clicked, you may also copy information out of the URI and paste it into a tool's "go to" navigation box or run the protocol handler manually; the scheme is intended to be used in this way as well. Unfortunately, due to perceived security risks, some sites, like GitHub, will not allow links with arbitrary schemes, so prioritizing this method of use is important.

This repository contains a reference implementation of a protocol handler for Wurl URIs. The "Reference Implementation" section has information on how to install, configure, and run the reference implementation.

### File

The required file hash follows the `wurl:` scheme; it is the lowercase, hexadecimal, SHA-256 hash of the file contents. This is the format output by `sha256sum`. I like [Git's revision selection rules](https://git-scm.com/book/en/v2/Git-Tools-Revision-Selection), so you may use a prefix of the hash. Examples: `wurl:e02b9c3c14fe3226cb11982e61e4bc2b5698df7c9c3e02174e18e7fd6d07bee5`, `wurl:e02b9c3`.

A prefix length of 7 characters should be good, but no fewer than 4. If you are having collisions with prefixes within a project, increase the length of the prefix. Try to always use the same prefix length for all files within a project; the URIs look better in lists when they line up, and this keeps the URIs normalized. If you are going to use a prefix, then try to hide the full-length hash behind link text, `[e02b9c3](wurl:e02b9c3c14fe3226cb11982e61e4bc2b5698df7c9c3e02174e18e7fd6d07bee5)`. If you aren't editing rich text, then it's fine to use the prefix in the URI, but make sure the full-length hash isn't far away, maybe at the bottom of the file, `wurl:e02b9c3`. The hash prefix strikes a balance between compactness and universality.

Since the file is specified in terms of the hash of its contents, it is content-addressable; we eliminate any assumptions about what path a file may exist at on any given computer. This is in the vein of [IPFS](https://ipfs.tech/); in fact, a protocol handler could even fetch the file from IPFS, add it to a Ghidra project, and then open it, if it wasn't already present. In this way, Wurl could be considered more of a Uniform Resource Locator than a Uniform Resource Identifier, since the file's identity is its location.

### Location

A location optionally follows the file hash and identifies a place in that file. The location starts with a location type character, which is followed by the location type-specific payload. You can refer generally to a file when the location isn't important by omitting the location, e.g. `wurl:e02b9c3`.

#### Address

The address location type is denoted by the `@` character. The payload is an address, as capitalized hexadecimal, without a `0x` prefix, and zero-padded to the number of digits in the highest possible address. The justification for capitalizing and padding the address is to distinguish it visually from the file hash and match how most SRE toolkits display addresses. The address should assume the binary gets loaded at its preferred base address, again because this is how most SRE toolkits are configured to display addresses by default. Examples: `e02b9c3@822FD26C`, `b0b8de2@000000014010E682`.

This idea of an address as a single number is [deeply flawed](https://github.com/iximeow/yaxpeax-arch/issues/8#issuecomment-4682404862). I've basically only considered PE/COFF and ELF executables, since that is what I will be using the most, but it leaves many other forms of addresses unrepresentable. For systems with multiple address spaces (banked memory, bus-switched spaces, memory-mapped I/O, etc.), I considered something like `a80e4f2@lowbus:000100` where you can specify the address space. For bytecode-compiled virtual machine-based programs (.NET Common Language Runtime, Java Virtual Machine, Python, WebAssembly, etc.), things really start to fall apart. CLR has metadata tokens, and JVM has Constant Pool Indexes and Bytecode Indexes, at least I think, and the others have their own things; these are mostly expressible as numbers or pairs of numbers, so I can imagine a syntax like `a80e4f2@0274FD45:5D2CFFD6`. None of these "enhanced addressing forms" have made it into the specification yet; I just wanted to discuss them and call out a failure of Wurl at present.

The protocol handlers for SRE toolkits usually allow a freeform string using their "go to" expression format. This bypasses the problem completely at the cost of a normal form, since many expressions can resolve to the same place in a binary. I don't think I'm quite ready to do that; I like Wurl being completely parseable, since then a protocol handler can rewrite the pieces into any arbitrary tool's expression format. By making it a freeform string and forwarding it directly to every tool, you can only accept the intersection of every tool's expression format. In some cases you may be able to get away with using an offset location and having the protocol handler or tool do the work to open the correct place by converting it, but the point of the address location form is to be useful as written text and imply an "image" view of a binary file.

#### Offset

The offset location type is denoted by the `#` character. The payload is an offset from the beginning of the file, as capitalized hexadecimal, without a `0x` prefix, and zero-padded to the number of digits in the highest possible offset. Examples: `e02b9c3#00CAFE`, `5b651ba#01A`.

#### Line and Column

The line and column location type is denoted by the `:` character. The payload is a line number and optionally a column number, separated by another `:`, both as decimal and 1-based, as displayed in most editors by default. Examples: `5b651ba:15`, `5b651ba:3:4`. I'm not going to recommend zero-padding these since it makes them so much uglier and harder to read, even though by not padding them, some reasonable sorts might place the single-digit lines after the double-digit lines.

This assumes that the text encoding and line-ending convention are a property of the file, since that information is not carried by the URI. I'm fine with that assumption; it would bloat the URI to have to say "UTF-8 and CRLF". And most editors can correctly infer that for most files. If the exact byte of text is that important, use the offset location form.

### Extensions

In general, protocol handlers should try to interpret malformed input to the best of their ability, and entities creating Wurl URIs should try to emit well-formed output[.](https://en.wikipedia.org/wiki/Robustness_principle) To that end, we can imagine an extensions string with arbitrary data that a protocol handler should ignore if it doesn't understand, or honor if it does.

The optional extensions string follows the `?` character and appears at the end of a Wurl URI, and is an arbitrary freeform string. For example, the Wurl URI `wurl:e02b9c3@822FD26C?view=decompiler` might open the program in IDA Pro with the decompiler view active, or if you are using a protocol handler that doesn't understand `view=decompiler` and using Ghidra, it would open the program at the correct address in Ghidra's default view, ignoring the extensions string. The extensions string should not be vital to understanding the reference; it should be safe to hide it behind the link text, and I would recommend doing so: `[e02b9c3@822FD26C](wurl:e02b9c3@822FD26C?view=decompiler)`. I encourage customizing Wurl to fit your needs, while prioritizing compatibility with compliant protocol handlers.

## FAQ (Frequently Anticipated Questions)

### How Should I Pronounce Wurl?

Great question, thanks for asking! I say "Whirl," and I have a North Shore Massachusetts accent, so aim for that.

### Did You Have Any Ideas That Haven't Made it in Yet?

Other than the "enhanced addressing forms" idea already discussed, I thought a way to handle ranges could be useful. One idea was to separate two locations with a `-`, like `e02b9c3@822FD26C-822FE000` or `5b651ba:15-18`. And you could even extend that to multiple selections with `,`, like `e02b9c3@822FD26C-822FE000,738B72A9-738B82E0`. But wide-ranging tool support for ranges and multiple selection is lacking and those strings just look really ugly, so I decided not to pursue it. If you want to use that grammar, then maybe just use that for the text and have the actual link target the first location of the range.

A time location could be useful for video and audio files. My preferred syntax would be a decimal number of seconds with optional fractional seconds, separated from the file hash with a `;`, e.g., `a9f8b31;147` or `a9f8b31;10981.85`. It feels visually close to the lines and columns location type, which I like. VLC even supports `vlc --start-time=147 easier.mp4`, so tool support exists. I haven't integrated it into the standard yet because files that use time locations are not common in reverse engineering projects, and for the files that do exist, the need to refer to a specific time and not just the whole file is very small. Also, it opens the door to handling a lot more location types. Most of the time I'm sharing a video reference with someone it's a YouTube link, and that already supports `&t=201` in the query string to start playback at a specific time.

A big gap in tooling is plugins for various SRE toolkits and editors to copy Wurl URIs. I can imagine a Ghidra or Visual Studio Code extension to right-click and copy a Wurl URI from your cursor. If I do ever end up writing these, they will end up in this repository. But Wurl URIs are easy enough to assemble by hand that I'm not sure I'll feel a need to write extensions.

Finally, a utility to generate a config for the reference implementation from a list of directories and Ghidra/Binary Ninja/IDA projects would speed up onboarding. I think this is opinionated enough that people would want to write their own scripts to do this, but I might add one to this repository if I write one. The config format isn't standardized; it's an implementation detail of the reference implementation, so other implementations might use a different format and need their own generators.

### I'm a Tool Developer, Should I Implement Wurl?

No. The point is for a generic 3rd-party protocol handler to dispatch requests to tools using their unique interfaces. You should implement command-line arguments or your own `<tool>:` protocol handler that Wurl can invoke, though.

### Who should use Wurl?

Me. I am not pitching this as a standard that should be widely adopted, and I have no aspirations of such. I'm just making something that I plan on using publicly. If you think it's cool, then you're free to adopt it. You don't even have to use the reference implementation. The whole point of it is that you could write your own protocol handler that fits your needs, and all of the Wurl links in the world would "just work". If you do want to use the reference implementation, but your favorite SRE toolkit or editor isn't supported, open an issue or PR; I'd be happy to take a look.

## Reference Implementation

### Releases

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

Have fun clicking these! (If your Markdown renderer didn't suppress the link)

* [e02b9c3](wurl:e02b9c3)
* [e02b9c3@822FD26C](wurl:e02b9c3@822FD26C)
* [e02b9c3#00CAFE](wurl:e02b9c3c14fe3226cb11982e61e4bc2b5698df7c9c3e02174e18e7fd6d07bee5#00CAFE)
* [5b651ba:15](wurl:5b651ba:15)
* [5b651ba:3:4](wurl:5b651ba0a41d821d9670f23:3:4)
* [5b651ba#01A](wurl:5b651ba0a41d821d9670f2387c3ab503af594e57cf61c55aa35cb80ac58171ca#01A)
