# Benchmarks
This file contains some scripts in order to run benchmarks for ekstrakto.
We use the TPTP (http://www.tptp.org/) library to run our benchmarks.

## Generating TPTP problems from TSTP file
In order to generate TSTP files we need to run a prover on the set of TPTP files that the TPTP library (version 7.4.0) contains:
```bash
    wget http://www.tptp.org/TPTP/Distribution/TPTP-v7.4.0.tgz
    tar -xvf TPTP-v7.4.0.tgz
``` 
We select only the files that ekstrakto accepts (CNF files for now):
```bash
    cp TPTP-v7.4.0/Problems/*/*-*.p problems/
    cp -r TPTP-v7.4.0/Axioms/ problems
```

### E prover
We follow instruction presented in https://github.com/eprover/eprover to install E prover.
To get a TSTP file from E prover we need to run the command:
```bash
    eprover --proof-object --auto <FILENAME> --output-file=<OUTPUT_FILENAME>
```
To run this command on the set of TPTP files we use the script in `scripts/eprover.sh` by fixing the cpu limit to 300 and the memory limit to 2Gb.

### Vampire
We use the same instructions in the E prover section by replacing the eprover with:
```bash
    vampire4 <FILENAME> -p tptp > <OUTPUT_FILENAME>
```
and by using the script in `scripts/vampire.sh`

## Subproofs
TODO
## Type Checking 
TODO