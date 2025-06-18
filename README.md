
# pldi25-src-artifact

This repository constains:
1. how FStar code can be embedded in a Rust executable alongside extracted Pulse code
2. how some simple array operations can be verified to use constant-memory in Pulse

Elaborations:
1. The pipeline to embed FStar into Rust uses [ocaml-rs](https://zshipko.github.io/ocaml-rs/) for OCaml <-> Rust interop: the FStar code is compiled into OCaml, and the Dune package manager is used to produce a static object file. OCaml and FStar is compiled statically using [musl-libc](https://musl.libc.org/) for which there exists a Nix flake file in this repository. To spawn a developer environment which recompiles the required parts with musl, run `USE_MUSL=true nix develop --impure`. This will recompile 255 packages. The recompilation took ~6 hours on AMD Ryzen™ 7 PRO 8700GE when compiled on DDR5 tmpfs. The recompilation is required to avoid glibc linking issues with OCaml and Rust, that is, for `dune build` and `cargo build` to successfully run.
2. This work uses Pulse, of which there is a presentation [on Friday at 2PM](https://pldi25.sigplan.org/details/pldi-2025-papers/62/PulseCore-An-Impredicative-Concurrent-Separation-Logic-for-Dependently-Typed-Program). The goal of the work is similar to [Kuiper, which was presented on Tuesday](https://pldi25.sigplan.org/details/ARRAY-2025-papers/6/Kuiper-verified-and-efficient-GPU-programming). In comparison, this work does not provide GPU backend, and targets only constant-memory allocations.

## How-to

Software versions used in this demo is pinned in this PR: https://github.com/FStarLang/pulse/pull/264

### OCaml codegen

Requires Pulse.

Install with Nix: `nix shell "github:FStarLang/pulse?ref=pull/264/head#pulse-exe"`.
A binary called `pulse.exe` should now be in your path.

Then, within `lib` folder:

`pulse.exe Lang.fst --odir . --codegen OCaml --ext pulse:extract_ocaml_bare --extract 'Lang'`

You now have generated the OCaml file.

The FFI stubs must be declared manually, look for `lib` for an example.

### Rust codegen

1. `pulse.exe Pad.fst --odir . --codegen Extension --extract 'Pad'`
2. `nix shell "github:FStarLang/pulse?ref=pull/264/head#pulse2rust" -- -odir ../src Pad.ast`

You have now generated Rust source code.
You will need to finalize the FFI bridge in `src` directory manually.