#!/bin/bash
#
syntax() {
echo;echo "Syntax: tblsize.sh dbname tblspec ownerspec [ sample ]";echo
exit
}
[ $# -lt 3 ] && syntax
dasport=`ingprenv II_INSTALLATION`7
dbname=$1
tblspec=$2
ownerspec=$3
sample=$4
echo;echo Begin: `date`;echo
java -cp ./tblsize.jar:$II_SYSTEM/ingres/lib/iijdbc.jar tblsize $dbname $dasport $tblspec $ownerspec $sample
echo;echo End: `date`;echo
