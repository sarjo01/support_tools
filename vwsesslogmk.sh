#
# Syntax: vwsesslogmk.sh <target Java runtime e.g. 6, 7, 8>
#
javac -target 1.$1 -source 1.$1 vwsesslog.java
jar -cf vwsesslog.jar vwsesslog.class
tar cvzf vwsesslog.tar.gz vwsesslog.jar vwsesslog.sh
