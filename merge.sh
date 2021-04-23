#!/bin/bash
for i in $(ls | grep -e 0.*); do
	echo $(date) $i
	rm -f ./$i/log.txt
	cd ./$i
	for j in $(ls); do
		cat $j>>$i.txt
	done
	cd ../
	echo "--------------"
done
