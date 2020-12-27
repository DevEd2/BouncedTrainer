#!/bin/sh
cd GFX
for i in *.bmp
do
	echo converting $i
	bmp2cgb $i > /dev/null
done
for i in *.chr
do
	echo packing $i
	python3 wlenc.py $i
	rm $i
done
cd ..
