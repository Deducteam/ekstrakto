#!/bin/bash

NBJOBS=50

cd files
function call_ekstrakto() {
  INPUT="$1"
  if ekstrakto $INPUT &> /dev/null
  then
    echo -e "[ekstrakto] Success on file [$(basename $INPUT)]"
  else
    echo -e "[ekstrakto] Failure on file [$(basename $INPUT)]"
    touch "proofs/$(basename $INPUT).failed"
  fi
}

export -f call_ekstrakto

NB_OK="`ls traces | wc -l`"

START_DATE="`date -R`"
if [ ! -d "proofs" ]; then
  echo "[ekstrakto] Running on $NB_OK traces."
  echo "===================================="
  mkdir proofs
  cd proofs
  ls ../traces/*.p|
    xargs -P $NBJOBS -n 1 -I{} bash -c "call_ekstrakto {}"

  END_DATE="`date -R`"

  cd ..
  echo "[ekstrakto] Producing report."
  NBALL="`ls proofs | wc -l`"
  NB_KO="`ls proofs | grep "failed$" | wc -l`"
  NB_OK="`ls proofs | grep -v "failed$" | wc -l`"

  echo "" >> generation_data.txt
  echo "======================================================">> generation_data.txt
  echo "========================EKSTRAKTO=====================">> generation_data.txt
  echo "Generation start date: $START_DATE">> generation_data.txt
  echo "Generation end date  : $END_DATE"  >> generation_data.txt
  echo "Number of processes  : $NBJOBS"    >> generation_data.txt
  echo "Number of files      : $NBALL"     >> generation_data.txt
  echo "Number of success    : $NB_OK"     >> generation_data.txt
  echo "Number of failures   : $NB_KO"     >> generation_data.txt

else
  echo "[ekstrakto] ERRPR : Proofs already produced."
fi