#!/bin/bash

generate_one_trace () {
	INPUT="$1"
	FILE=$(basename $1)
	OUTPUT=/home/debian/yacine/tstp/$FILE
	echo $INPUT
	if /home/debian/yacine/vampire4 /home/debian/yacine/problems/bench/$INPUT --time_limit 5m --memory_limit 2000 -p tptp > $OUTPUT
	then
		echo $INPUT OK
	else
		echo $INPUT FAIL
		mv $OUTPUT $OUTPUT.fail
	fi
}

export -f generate_one_trace

find /home/debian/yacine/problems -type f | 
	xargs -n 1 -P 56 -I{} bash -c "generate_one_trace {}"