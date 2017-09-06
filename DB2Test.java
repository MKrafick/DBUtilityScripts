/*
   Compile this with `javac DB2Test.java`
   Then run it with `java -cp "$DB2_HOME/java/db2jcc.jar:." DB2Test <JDBC URL> <username> <password>`
   You might need single quotes or escaping on the password...

   This code was taken from http://www.justexample.com/wp/connect-db2-java/ then extended a bit.
   It is unclear how the original was licensed. This work is licensed under the MIT license,
   Copyright 2017, Jonathan Gnagy.
   https://opensource.org/licenses/MIT
*/

import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;

public class DB2Test {

    public static void main(String[] args) {
        String jdbcClassName="com.ibm.db2.jcc.DB2Driver";
        String url = args[0];
        String user = args[1];
        String password = args[2];

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