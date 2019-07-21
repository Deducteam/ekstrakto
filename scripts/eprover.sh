#!/bin/bash

NBJOBS=50
MAXTIME="300s"
MAXMEM="2048M"

cd files

function make_trace() {
  INPUT="$1"
  OUTPUT="traces/$(basename $INPUT)"
  if eprover --proof-object --auto --cpu-limit=300 --memory-limit=2048 $INPUT \
    --silent --output-file=$OUTPUT &> /dev/null
  then
    echo -e "[eprover] Success on file [$(basename $INPUT)]"
  else
    echo -e "[eprover] Failure on file [$(basename $INPUT)]"
    touch "traces/$(basename $INPUT .p).failed"
    rm $OUTPUT
  fi
}

export readonly MAXTIME=$MAXTIME
export readonly MAXMEM=$MAXMEM
export -f make_trace

NBPROBLEMS="`ls problems/*.p | wc -l`"

START_DATE="`date -R`"
if [ ! -d "traces" ]; then
  echo "[eprover] Running with $NBJOBS processes, $MAXTIME of time and $MAXMEM of RAM."
  echo "[eprover] Running eprover on $NBPROBLEMS problems."
  echo "================================================="
  mkdir traces
  find problems -type f -name *.p|
    xargs -P $NBJOBS -n 1 -I{} bash -c "make_trace {}"
  END_DATE="`date -R`"

  echo "[eprover] Producing report."
  NBALL="`ls traces | wc -l`"
  NB_KO="`ls traces | grep "failed$" | wc -l`"
  NB_OK="`ls traces | grep -v "failed$" | wc -l`"
  EPROVERV="`eprover --version`"

  echo "======================================================" > generation_data.txt
  echo "========================EPROVER=======================">> generation_data.txt
  echo "Generation start date: $START_DATE">> generation_data.txt
  echo "Generation end date  : $END_DATE"  >> generation_data.txt
  echo "Eprover version      : $EPROVERV"  >> generation_data.txt
  echo "Number of processes  : $NBJOBS"    >> generation_data.txt
  echo "Maximum time         : $MAXTIME"   >> generation_data.txt
  echo "Maximum memory       : $MAXMEM"    >> generation_data.txt
  echo "Number of files      : $NBALL"     >> generation_data.txt
  echo "Number of success    : $NB_OK"     >> generation_data.txt
  echo "Number of failures   : $NB_KO"     >> generation_data.txt

else
  echo "[eprover] ERROR : traces already produced."
fi
