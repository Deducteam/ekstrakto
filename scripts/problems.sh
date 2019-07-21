#!/bin/bash

mkdir -p files
cd files
if [ -d "problems" ]; then
  echo "[TPTP] ERROR : Problem files already extracted."
else
  echo "[TPTP] Extracting files..."
  tar -xzf ../cnf_problems.tar.gz
  echo "[TPTP] Extraction completed."
  PROBLEMS_FOUND="`ls problems/*.p | wc -l`"
  echo "[TPTP] $PROBLEMS_FOUND TPTP files"
fi