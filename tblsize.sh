#!/bin/bash
#
syntax() {
echo && echo "Syntax: tblsize.sh dbname tblowner [ tblname ]" && echo
exit
}
[ $# -lt 2 ] && syntax
ii=`ingprenv II_INSTALLATION`
dasport=${ii}7
dbname=$1
tblowner=$2
tblname=$3
echo;echo Begin: `date`;echo
java -cp ./tblsize.jar:$II_SYSTEM/ingres/lib/iijdbc.jar tblsize ${dbname}:${dasport} $tblowner $tblname
echo;echo End: `date`;echo
