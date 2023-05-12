# Ekstrakto

Tool to translate a proof in the [TSTP](https://tptp.org/TSTP/) into the [lambdapi](https://github.com/Deducteam/lambdapi) format.

## How does it work?

Ekstrakto generates a TPTP problem for each proof step in the TSTP input file, a Lambdapi signature file, and a Lambdapi file providing a complete proof assuming a Lambdapi file for each proof step.

One can then automatically generate a Lambdapi proof file for each proof step by running an automated theorem provers able to output Dedukti or Lambdapi proofs:
- [ZenonModulo](https://github.com/Deducteam/zenon_modulo)
- [ArchSAT](https://github.com/Gbury/archsat)
- [iProverModulo](https://github.com/gburel/iProverModulo)

## Installation
    
### Dependencies

- `OCaml >= 4.05.1`
- `ocamlbuild`
- [modulo_lp branch of zenon_modulo](https://github.com/Deducteam/zenon_modulo/tree/modulo_lp)
- [lambdapi](https://github.com/Deducteam/lambdapi)

### Compilation

First, you need to get the sources:
```bash
    git clone https://github.com/elhaddadyacine/ekstrakto.git
```
To compile the tool, just type:

```bash
    cd ekstrakto
    make
```
It will generate an executable file named `spliter.native`.
If you want to install it, do:

```bash
    sudo make install
```

## Usage

Just call `ekstrakto` with an input TSTP file as argument:
```bash
    ekstrakto $trace.p
```

Ekstrakto creates in a folder `$trace`:
- a sub-folder `lemmas` with all the `TPTP` problems
- a Lambdapi signature file `$trace.lp`
- a Lambdapi proof file `proof_$trace.lp`
- a `lambdapi.pkg` file
- a `Makefile` to produce the Lambdapi proofs and check them.

Then, one can call `make` to generate a Lambdapi proof file for each TPTP problem using `zenon_modulo`, and check them using `lambdapi` (make sure that `zenon_modulo` and `lambdapi` are in your `$PATH`).

#### Example

In the folder `examples`, do:
```bash
    ../spliter.native trace.p
    cd trace
    make
```

## Contact

<dedukti-dev@inria.fr>
