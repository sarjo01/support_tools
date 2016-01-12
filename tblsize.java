//
// Copyright 2016 Actian Corporation
//
// Table size calculator, schema based
//
// 12-Jan-2016 (sarjo01) Created.
//
import java.sql.*;
import java.util.*;
//--------------------------------------
//
// tblsize main class 
//
class tblsize {

   public static void main (String args[]) {

      if (args.length < 3) {
         System.err.println(
            "\nSyntax: java tblsize db:dasport[:host:user:pwd] " +
            "tblowner sample [ tblname ]\n"); 
         System.exit(0);
      }

      Properties jprops = new Properties();
      jprops.setProperty("select_loop", "on");

      int sample = Integer.parseInt(args[2]);
      long gtot, ttot;
      Connection conn = null;
      Statement stmt = null;
      Statement stmt2 = null;
      ResultSet rs1 = null;
      ResultSet rs2 = null;
      ResultSetMetaData rsmd = null;
      int cols = 0;
      int tblcnt = 0;
      String tbllist[];

      ConnTarget tgt = new ConnTarget(args[0]);
      String url = tgt.getUrl(); 
      String schema_name = args[1];
      String table_name, col_name;
      String tblqual = "";
      String sampqual = "";
      if (sample > 1) {
         sampqual = String.format(" where mod(tid, %d)=0", sample);
      }

      if (args.length == 4)
         tblqual = "trim(table_name) like '" + args[3] + "' and ";

      try {
         conn = DriverManager.getConnection(url, jprops);
         stmt  = conn.createStatement();
         stmt2 = conn.createStatement();
         rs1 = stmt.executeQuery(
            "select count(*) from iitables where table_owner = '" +
            schema_name + "' and table_type = 'T' and " + tblqual +
            "storage_structure like 'VECT%'");
         rs1.next();
         tblcnt = rs1.getInt(1);
         stmt.close();
         if (tblcnt == 0) {
            System.err.println(
               "\nNo tables found for schema '" + schema_name + "'\n");
            System.exit(0);
         }
         tbllist = new String[tblcnt];
         rs1 = stmt.executeQuery(
            "select table_name from iitables where table_owner = '" +
            schema_name + "' and table_type = 'T' and " + tblqual +
            "storage_structure like 'VECT%' order by 1");
         for (int i=0; rs1.next(); i++) {
            tbllist[i] = rs1.getString(1);
         }
         stmt.close();
         gtot = 0;
         for (int i=0; i<tblcnt; i++) {
            table_name = tbllist[i];
            System.out.format("%-32.32s %s", table_name, " :   Scanning");
            rs1 = stmt.executeQuery(
              "select * from " + schema_name + "." + table_name + " where 1=0");
            rsmd = rs1.getMetaData();
            cols = rsmd.getColumnCount();
            ttot = 0;
            for (int j=1; j<=cols; j++) {
               col_name = rsmd.getColumnName(j);
               String qTxt = String.format(
                  "select int8(sum(int8(length(varchar(\"%s\"))))) from %s.%s %s",
                   col_name, schema_name, table_name, sampqual);
               rs2 = stmt2.executeQuery(qTxt);
               rs2.next();
               ttot += rs2.getLong(1);
               stmt2.close();
            }
            ttot *= sample;
            gtot += ttot;
            stmt.close();
            System.out.format("\r%-32.32s %s", table_name, " :");
            System.out.format("%11.11s\n",
               sizer(ttot));
         }
         String tblf = String.format("\nTOTAL: %d table(s)", tblcnt);
         System.out.format("%-32.32s   :%11.11s\n",
            tblf, sizer(gtot));
      }
      catch (SQLException sqlex) {
         System.err.println("\nDBERROR: " + sqlex.getMessage());
         System.exit(0); 
      }
   }

   private static String sizer(long size) {
      double tt;
      String pval;
      if (size < 1048576L) {
         tt = (double) size / 1024L;
         pval = "KB";
      }
      else if (size < 1073741824L) {
         tt = (double) size / 1048576L;
         pval = "MB";
      }
      else if (size < 1099511627776L) {
         tt = (double) size / 1073741824L;
         pval = "GB";
      }
      else {
         tt = (double) size / 1099511627776L;
         pval = "TB";
      }
      return String.format("%.3f%s", tt, pval);
   }
}
