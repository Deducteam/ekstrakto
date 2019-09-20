#!/bin/bash

NBJOBS=50

function call_zenon() {
  INPUT="$1"
  FOLDER="`echo $INPUT|cut -d'/' -f 3`"
  FILE="`echo $INPUT|cut -d'/' -f 5`"
  OUTPUT="files/proofs/$FOLDER/lemmas/$(basename $FILE .p).lp"
  if zenon_modulo -itptp -modulo -modulo-heuri -odkterm -sig $FOLDER -max-time \
    10s -max-size 2G $INPUT > $OUTPUT 2> /dev/null
  then
    echo -e "[zenonmodulo] Success on file [$FOLDER][$(basename $INPUT)]"
  else
    echo -e "[zenonmodulo] Failure on file [$FOLDER][$(basename $INPUT)]"
    rm "$OUTPUT"
    touch "files/proofs/$FOLDER/lemmas/$(basename $INPUT .p).failed"
  fi
}

export -f call_zenon


START_DATE="`date -R`"

echo "Running zenonmodulo on $NB_OK trace..."

find files/proofs -name *.p|
    xargs -P $NBJOBS -n 1 -I{} bash -c "call_zenon {}"

END_DATE="`date -R`"