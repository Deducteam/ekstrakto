#!/bin/bash

NBJOBS=56

function call_zenon() {
  INPUT="$1"
  FOLDER="`echo $INPUT|cut -d'/' -f 4`"
  FILE="`echo $INPUT|cut -d'/' -f 6`"
  OUTPUT="~/yacine/proofs_eprover/$FOLDER/lemmas/$(basename $FILE .p).lp"
  if zenon_modulo -itptp -modulo -modulo-heuri -odkterm -sig $FOLDER -max-time \
    10s -max-size 2G $INPUT > $OUTPUT 2> /dev/null
  then
    echo -e "[zenonmodulo] Success on file [$FOLDER][$(basename $INPUT)]"
  else
    echo -e "[zenonmodulo] Failure on file [$FOLDER][$(basename $INPUT)]"
    rm "$OUTPUT"
    touch "~/yacine/proofs_eprover/$FOLDER/lemmas/$(basename $INPUT .p).failed"
  fi
}

export -f call_zenon

find ~/yacine/proofs_eprover -name "*.p"|
    xargs -P $NBJOBS -n 1 -I{} bash -c "call_zenon {}"