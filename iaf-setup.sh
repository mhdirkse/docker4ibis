#!/usr/bin/env bash
#   Use this script to change the context.xml file depending on the database to use.

DATABASE_TYPE="$1"
IBIS_NAME="${2,,}"
USER="$IBIS_NAME"_user
C_USER=c##"$2"_user
FILE=/usr/local/tomcat/contextpath/docker/WEB-INF/classes/context.xml

if [[ $DATABASE_TYPE == "" ]]; 
	then 
		echo "no database type given" 
fi

if test -f "$FILE"; then
	cp $FILE /usr/local/tomcat/conf/context.xml
	sed -i -e "s|</Context>||g" /usr/local/tomcat/conf/context.xml
	(echo "	<Resource
		name=\"jdbc/$IBIS_NAME\""
	) >> /usr/local/tomcat/conf/context.xml
else
	(
	echo "<?xml version=\"1.0\" encoding=\"UTF-8\"?>
<Context>
	<Resource
		name=\"jdbc/$IBIS_NAME\""
	) > /usr/local/tomcat/conf/context.xml
fi

if [[ $DATABASE_TYPE == "oracle" ]]; then
	(echo "		factory=\"org.apache.naming.factory.BeanFactory\"
		type=\"oracle.jdbc.xa.client.OracleXADataSource\"
		URL=\"jdbc:oracle:thin:@IAF_oracle:1521:ORCLCDB\"
		user=\"$C_USER\"
		password=\"$C_USER\"") >> /usr/local/tomcat/conf/context.xml
elif [[ $DATABASE_TYPE == "mssql" ]]; then
	(echo "		auth=\"Container\"
		type=\"javax.sql.DataSource\"
		username=\"$C_USER\"
		password=\"${C_USER}00\"
		driverClassName=\"net.sourceforge.jtds.jdbc.Driver\"
		url=\"jdbc:jtds:sqlserver://IAF_mssql:1433/$2\"
		maxActive=\"8\"
		maxIdle=\"4\"
		validationQuery=\"select 1\"") >> /usr/local/tomcat/conf/context.xml
elif [[ $DATABASE_TYPE == "postgresql" ]]; then
	(echo "		auth=\"Container\"
 		type=\"javax.sql.DataSource\"
 		driverClassName=\"org.postgresql.Driver\"
 		url=\"jdbc:postgresql://IAF_postgres:5432/$IBIS_NAME\"
 		username=\"$USER\"
 		password=\"$USER\"
 		maxActive=\"20\"
 		maxIdle=\"10\"
 		maxWait=\"-1\"
 		validationQuery=\"select 1\"") >> /usr/local/tomcat/conf/context.xml
elif [[ $DATABASE_TYPE == "mysql" ]] || [[ $DATABASE_TYPE == "mariadb" ]]; then
	(echo "		auth=\"Container\"
		type=\"javax.sql.DataSource\"
		username=\"${2}_user\"
		password=\"${2}_user\"
		driverClassName=\"com.mysql.jdbc.Driver\"
		url=\"jdbc:mysql://IAF_${DATABASE_TYPE}:3306/$IBIS_NAME\"
		maxActive=\"8\"
		maxIdle=\"3\"
		validationQuery=\"select 1\"") >> /usr/local/tomcat/conf/context.xml
else 
	(echo "		type=\"org.h2.jdbcx.JdbcDataSource\"
		factory=\"org.apache.naming.factory.BeanFactory\"
		URL=\"jdbc:h2:/usr/local/tomcat/logs/ibisname\"") >> /usr/local/tomcat/conf/context.xml
fi
(
echo "	/>
</Context>"
) >> /usr/local/tomcat/conf/context.xml

rm -rf /usr/local/tomcat/webapps/ROOT

(
echo "<Context displayName=\"$IBIS_NAME\"
    docBase=\"/usr/local/tomcat/contextpath/docker/\"
    path=\"/$IBIS_NAME\"
    reloadable=\"true\"
/>"
) > /usr/local/tomcat/conf/Catalina/localhost/${IBIS_NAME}.xml

/usr/local/tomcat/bin/catalina.sh run