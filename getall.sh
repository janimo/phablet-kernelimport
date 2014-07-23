cd $(dirname $0)
SERIES=utopic

./getkernel.sh goldfish $SERIES
./getkernel.sh mako $SERIES
./getkernel.sh manta $SERIES
./getkernel.sh flo $SERIES
./getkernel.sh deb $SERIES
./getkernel.sh hammerhead $SERIES
./getinitrd.sh $SERIES
