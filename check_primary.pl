#!/bin/sh
arch=$1; shift
for pkg in $(cat $*);
do b=$(echo $pkg | sed 's/^.*:\(.*\)-[^-]*-[^-]*$/\1/')
    sed -e "s/^\(\t$b-[^-]*-[^-]*\)$/*\1/" -i api.${arch}
done
