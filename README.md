# ekstrakto

A tool to extract `TPTP` problems from a `TSTP` trace and reconstruct the proof in `lambdapi`.

## Installation
    
### Dependencies

- `OCaml >= 4.05.1`
- `ocamlbuild`
- `zenon_modulo` (https://github.com/elhaddadyacine/zenon_modulo)
- `lambdapi` (optional) (https://github.com/Deducteam/lambdapi)
- `eprover` or any first order automated prover (optional) (https://github.com/eprover/eprover)

### Compilation

First, you need to get the sources :
```bash
    git clone https://github.com/elhaddadyacine/ekstrakto.git
```
To compile the tool, just type :

```bash
    make
```
It will generate a native file named `spliter.native` if you want to install the tool in your binary installation folder (where ocaml is installed, if ocaml is installed in the `/usr/bin/` directory then you need to call `make install` with `sudo`) use :

```bash
    make install
```

## Usage

In order to use `ekstrakto` you need to have a `TSTP` trace (the repository contains an example (see `examples` folder) named `trace.p`).
You just need to type :
```bash
    ./spliter.native path/to/your/tstp/trace/file
```

Or (if you installed the tool)
```bash
    ekstrakto path/to/your/tstp/trace/file
```

The program will create a folder which has the same name as the trace.
It generates all the sub problems in the `TPTP` format (inside `lemmas` folder) and add a signature file in `lambdapi` format.
It generates also a Makefile to produce proofs in `lambdapi` and typecheck them.
And finally, produce a proof (named `proof_<TRACENAME>.lp`) using all sub solutions in `lambdapi`.

You need to have `zenon_modulo` (use `modulo_lp` branch) and `lambdapi` installed to generate the proofs of each sub problem and then generate the `.lpo` files with `lambdapi`
#### Example

A trace file named `trace.p` (in `examples`) in the repository contains an example.

The program will generate 3 files, logic folder (that contains `zenon_modulo` logic files), 1 signature file, a Makefile and 1 proof file :
- lemmas/c_0_5.p
- lemmas/c_0_6.p
- lemmas/c_0_7.p
- logic/
- trace.lp
- Makefile
- proof_trace.lp

It will produce the proof of each sub problem and typecheck them with `lambdapi`  :
```bash
cd trace
make proof
```
Files produced : 
```bash
lemmas/c_0_5.lp         # the proof of each problem (with zenon_modulo)
lemmas/c_0_6.lp         # ...
lemmas/c_0_7.lp         # ...

lemmas/c_0_5.lpo        # typeching of each proof (with lambdapi)
lemmas/c_0_6.lpo        # ...
lemmas/c_0_7.lpo        # ...

trace.lpo               # the signature of the proof (contains all used symbols)
proof_trace.lpo         # the global proof (contains the combination of sub solutions)
```


## Contact

Mohamed Yacine EL HADDADD <elhaddad@lsv.fr>
