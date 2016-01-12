#!/bin/bash
#
syntax() {
echo && echo "Syntax: tblsize.sh dbname tblowner sample [ tblname ]" && echo
exit
}
[ $# -lt 3 ] && syntax
ii=`ingprenv II_INSTALLATION`
dasport=${ii}7
dbname=$1
tblowner=$2
sample=$3
tblname=$4
echo;echo Begin: `date`;echo
java -cp ./tblsize.jar:$II_SYSTEM/ingres/lib/iijdbc.jar tblsize ${dbname}:${dasport} $tblowner $sample $tblname
echo;echo End: `date`;echo
