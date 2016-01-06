#!/bin/bash
#
# Session Logger
#
# 2015-12-08 (sarjo01) Created.
# 2015-12-10 (sarjo01) Add session_id to list.
# 2015-12-16 (sarjo01) Add queries.
# 2015-12-30 (sarjo01) Add new ima table, client_terminal.
# 2016-01-05 (sarjo01) Use case stmt for commands.
#
cmdlist="start stop status list queries"
ii=`ingprenv II_INSTALLATION`
dasport=${ii}7
p=
table=
outfile=/tmp/vwsesslog${ii}.out
iiup=$(echo "\q" | sql imadb | grep login)
[ "$iiup" != "" ] && table=$(echo "help table vwsesslog\g" | sql -S imadb | grep Name:)
syntax() {
   echo
   echo "Syntax: vwsesslog.sh start interval_seconds [ new ]"
   echo "        vwsesslog.sh stop"
   echo "        vwsesslog.sh status"
   echo "        vwsesslog.sh list [ timestamp [ dbname ] ]"
   echo "        vwsesslog.sh queries [ session_id ]"
   echo
   exit
}
imatable() {
cat << IMATBL | sql -u\$ingres imadb 2>&1 >/dev/null
drop table if exists ima_vwsesslog\\g
register table ima_vwsesslog (
   server varchar(64) not null not default is
      'SERVER',
   session_id varchar(32) not null not default is
      'exp.scf.scs.scb_self',
   effective_user varchar(32) not null not default is
      'exp.scf.scs.scb_euser',
   real_user varchar(32) not null not default is
      'exp.scf.scs.scb_ruser',
   db_name varchar(32) not null not default is
      'exp.scf.scs.scb_database',
   db_owner varchar(32) not null not default is
      'exp.scf.scs.scb_dbowner',
   client_host varchar(20) not null not default is
      'exp.scf.scs.scb_client_host',
   client_user varchar(32) not null not default is
      'exp.scf.scs.scb_client_user',
   client_terminal varchar(20) not null not default is
      'exp.scf.scs.scb_client_tty',
   session_time integer not null not default is
      'exp.clf.unix.cs.scb_connect',
   query_start_secs integer4 not null not default is
      'exp.scf.scs.scb_query_start_secs',
   session_lquery varchar(250) not null not default is
      'exp.scf.scs.scb_lastquery' )
as import from 'tables'
with dbms = IMA, structure = unique sortkeyed,
key = (server, session_id)\\g
grant all on ima_vwsesslog to public with grant option\\g
IMATBL
}
setp() {
   p=$(ps -fade | grep vwsesslog.jar | grep $dasport | grep -v grep | awk '{print $2}')
}
status() {
   setp
   if [[ -n $p ]]
   then
      echo Started...
   else
      echo Stopped. && [ -s $outfile ] && echo Last error: && cat $outfile
   fi
}
stoplog() {
   setp
   [ "$p" != "" ] && kill $p 
}
chkconnect() {
   [ "$iiup" == "" ] && echo && echo "Can't connect to imadb. Installation down?" && echo && exit
}

[ $# -lt 1 ] && syntax
case $1 in

   "queries")

[ "$2" != "" ] && session_id="where varchar(session_id, 22) = '$2'"
chkconnect
echo
echo "Session_ID             Query_started       Query_text"
echo "---------------------- ------------------- ------------------------------------------------------------"
cat << QUERIES | sql -S imadb
\silent
\notitles
select varchar(session_id, 22),
varchar(timestamp(from_unixtime(query_start_secs)), 19),
varchar(session_lquery, 60)
from vwqrylog $session_id order by 2\\g
QUERIES
echo
status
echo
   ;;

   "status") 

status
   ;;

   "stop")

stoplog 
status
   ;;

   "start")

[[ $2 != *[[:digit:]]* ]] && syntax
interval=$2
chkconnect
stoplog 
imatable
if [[ -z $table ]]
then
   new=new
else
   new=$3
fi
setsid java -cp ./vwsesslog.jar:$II_SYSTEM/ingres/lib/iijdbc.jar vwsesslog $dasport $interval $new >$outfile 2>&1 < /dev/null &
sleep 2
status 
   ;;

   "list")

chkconnect
[ "$table" == "" ] && echo && echo "Logging table not initialized." && echo && exit
ts=
tdb=
[ "$2" != "" ] && ts="where '$2' between start_time and end_time"
[ "$3" != "" ] && tdb="and db_name = '$3'"
echo
echo "Session_ID             Client_host  Client_term  Client_user  Eff_user     Real_user    DB_name      Session_started     Session_ended_by"
echo "---------------------- ------------ ------------ ------------ ------------ ------------ ------------ ------------------- -------------------"
cat << SELECT | sql -S imadb
\silent
\notitles
with t as (select
varchar(session_id, 22) as session_id,
varchar(client_host, 12) as client_host,
varchar(client_terminal, 12) as client_terminal,
varchar(client_user, 12) as client_user,
varchar(effective_user, 12) as effectiver_user,
varchar(real_user, 12) as real_user,
varchar(db_name, 12) as db_name,
varchar(timestamp(from_unixtime(session_time)), 19) as start_time,
case when session_et = 0 then '                   ' else
varchar(timestamp(from_unixtime(session_et)), 19) end as end_time
from vwsesslog)
select * from t $ts $tdb order by start_time\\g
SELECT
echo
status
echo
   ;;

   *)
syntax
   ;;
esac
