//
//  Session/Query Logger Process
//
//  2015-12-30 (sarjo01) Created.
//
import java.sql.*;

class vwsesslog {

   public static void main (String args[]) {

      if (args.length < 2) {
         System.out.println("Syntax: java vwsesslog <port> <interval_secs> [ new ]\n");
         System.exit(0);
      }
      String droplog = "drop table if exists vwsesslog, vwqrylog";
      String createlog = "create table vwsesslog as select " +
         "s.*, int(0) as sesskey, int(0) as qkey, int(0) as session_et " +
         "from ima_vwsesslog s where 1 = 0";
      String createqlog = "create table vwqrylog as select " +
         "session_id, sesskey, query_start_secs, qkey, session_lquery " +
         "from vwsesslog where 1 = 0";
      String createsnap = "declare global temporary table sesssnap as " +
         "select s.* from vwsesslog s where 1 = 0 " +
         "on commit preserve rows with norecovery";
      String insertsnap = "insert into sesssnap select *, int(0), int(0), int(0) from ima_vwsesslog " +
         "where db_owner != '$ingres' and db_owner != '' and " +
         "effective_user not like '%>%' and effective_user != '$ingres'";
      String upd1snap = "update sesssnap set session_lquery = trim(both ' ' from session_lquery)";
      String upd2snap = "update sesssnap set " +
         "sesskey=hash(varchar(session_id)||varchar(session_time)), " +
         "qkey=hash(varchar(session_id)||varchar(query_start_secs)||varchar(session_lquery))";
      String insertlog = "insert into vwsesslog select " +
         "* from sesssnap " +
         "where sesskey not in (select sesskey from vwsesslog)";
      String insertqlog = "insert into vwqrylog select " +
         "session_id, sesskey, query_start_secs, qkey, session_lquery " +
         "from sesssnap where qkey not in " +
         "(select qkey from vwqrylog)";
      String updlogend = "update vwsesslog set session_et = unix_timestamp() " +
         "where session_et = 0 and sesskey not in (select sesskey from sesssnap)";
      String deletesnap = "delete from sesssnap";

      String url = "jdbc:ingres://localhost:" + args[0] + "/imadb";
      long interval = Long.parseLong(args[1]) * 1000; 
      boolean newlog = false;
      if (args.length == 3 && args[2].equals("new")) newlog = true;

      Connection conn = null; 
      Statement stmt = null;

      try {
         conn = DriverManager.getConnection(url);
         conn.setAutoCommit(false);
         stmt = conn.createStatement();
         if (newlog) {
            stmt.execute(droplog);
            stmt.execute(createlog);
            stmt.execute(createqlog);
         }
         stmt.execute(createsnap);
         while (true) {
            stmt.execute(insertsnap);
            stmt.execute(upd1snap);
            stmt.execute(upd2snap);
            stmt.execute(insertlog);
            stmt.execute(insertqlog);
            stmt.execute(updlogend);
            stmt.execute(deletesnap);
            conn.commit();
            Thread.sleep(interval);
         }
      }
      catch (SQLException sqlex) {
         System.out.println(sqlex.getMessage() + "\n");
      }
      catch (InterruptedException ie) { }
   }
}
