/*
   Original example taken from "Just Example - Connect to DB2 in Java" (http://www.justexample.com/wp/connect-db2-java/), license unknown
   Comments, notes, and minor edits made by M. Krafick - Aug 6, 2017
   
   Purpose: Simple pass/fail of a DB2 JDBC connection string
   
   Pre-Req:
     - Make sure your Java environment is being loaded via .profile or .bash_profile
     - On Mac, I added this in my .profile: "export JAVA_HOME=$(/usr/libexec/java_home)"
   
   Usage Notes:   
     - Swap out String URL with Database Name and Port, User, Password as needed.
     - Save as "DB2ConnectionTest.java"
     - Compile with "javac DB2ConnectionTest.java"
     - Run with `java -cp "/path/to/JDBC/Driver:." DB2ConnectionTest`
         Notice you are directing class path (-cp) to where db2jcc.jar and db2jcc4.jar are located
         This is followed by :. which means look in current directory as well, this is where your .java file is saved 
*/

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DB2ConnectionTest {

	public static void main(String[] args) {
		String jdbcClassName="com.ibm.db2.jcc.DB2Driver";
		String url="jdbc:db2://servername:port/DBNAME";
		String user="UserID";
		String password="Password";

		Connection connection = null;
		try {
			//Load class into memory
			Class.forName(jdbcClassName);
			//Establish connection
			connection = DriverManager.getConnection(url, user, password);

		} catch (ClassNotFoundException e) {
			e.printStackTrace();
		} catch (SQLException e) {
			e.printStackTrace();
		}finally{
			if(connection!=null){
				System.out.println("Connected successfully.");
				try {
					connection.close();
				} catch (SQLException e) {
					e.printStackTrace();
				}
			}
		}

	}

}