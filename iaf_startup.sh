#!/bin/bash

Project_Directory=..
Ibis_Name=$1
Database=h2
Hostport=80
Otap_Stage=LOC
Ibis_Classes=$Project_Directory/$Ibis_Name/classes
Ibis_Config=$Project_Directory/$Ibis_Name/configurations
Ibis_Tests=$Project_Directory/$Ibis_Name/tests

sed -i $'s/\r$//' project_directory.txt
source project_directory.txt
sed -i $'s/\r$//' $Project_Directory/$1/properties.txt
source $Project_Directory/$1/properties.txt

(
echo "version: \"3\"
services:
  oracle:
    image: store/oracle/database-enterprise:12.2.0.1
    container_name: IAF_oracle
    expose:
      - \"1521\"
      - \"5500\"
 
  mssql:
    image: mcr.microsoft.com/mssql/server
    container_name: IAF_mssql
    expose: 
      - \"1433\"
    environment:
      - \"ACCEPT_EULA=Y\"
      - \"SA_PASSWORD=SqlDevOps2017\"
      - \"MSSQL_PID=Developer\"
 
  postgresql:
    image: postgres
    container_name: IAF_postgres
    expose:
      - \"5432\"
    environment:
      - \"POSTGRES_PASSWORD: testiaf_user\"

  mysql:
    image: mysql
    container_name: IAF_mysql
    expose:
      - \"3306\"
    environment:
      - MYSQL_ROOT_PASSWORD=root
    command: 
      --lower_case_table_names=1

  mariadb:
    image: mariadb
    container_name: IAF_mariadb
    expose:
      - \"3306\"
    environment:
      - MYSQL_ROOT_PASSWORD=root
    command: 
      --lower_case_table_names=1

  wait:
    image: ibissource/iaf:7.5
    container_name: waiting_container     
    command: bash -c \""
) > docker-compose.yml
if [ $Database == "oracle" ]
then
    echo "       ./wait-for-it.sh IAF_oracle:5500 --timeout=0 --strict -- sleep 2\"" >> docker-compose.yml
elif [ $Database == "mssql" ]
then
	echo "       ./wait-for-it.sh IAF_mssql:1433 --timeout=0 --strict -- sleep 2\"" >> docker-compose.yml
elif [ $Database == "postgresql" ]
then
	echo "       ./wait-for-it.sh IAF_postgres:5432 --timeout=0 --strict -- sleep 2\"" >> docker-compose.yml
elif [ $Database == "mysql" ]
then
  echo "       ./wait-for-it.sh IAF_mysql:3306 --timeout=0 --strict -- sleep 2\"" >> docker-compose.yml
elif [ $Database == "mariadb" ]
then
  echo "       ./wait-for-it.sh IAF_mariadb:3306 --timeout=0 --strict -- sleep 2\"" >> docker-compose.yml
fi
(
echo "
  $Ibis_Name:
    image: ibissource/iaf:7.5
    container_name: $Ibis_Name
    ports:
      - \"$Hostport:8080\"
    volumes:
      - $Ibis_Classes:/usr/local/tomcat/contextpath/docker/WEB-INF/classes"
) >> docker-compose.yml
if [ ! -z "$Ibis_Config" ]
then
	echo "      - $Ibis_Config:/usr/local/ibis/configurations" >> docker-compose.yml
fi
if [ ! -z "$Ibis_Tests" ]
then
	echo "      - $Ibis_Tests:/usr/local/ibis/tests" >> docker-compose.yml
fi
(
echo "    environment:
      - \"JAVA_OPTS=-Dotap.stage=$Otap_Stage -Dinstance.name=$Ibis_Name -Dscenariosroot1.directory=/usr/local/ibis/tests -Dscenariosroot1.description=Default -Dlocal.temp=/usr/local/tomcat/logs -Dconfigurations.directory=/usr/local/ibis/configurations\"
    command: bash -c \"
       ./iaf-setup.sh $Database $Ibis_Name\""
) >> docker-compose.yml

if [ ! -z $Database ] && [ ! $Database == "h2" ]
then (
  docker-compose up -d $Database
  docker-compose up wait
  docker stop waiting_container
  docker rm waiting_container
)
fi

if [ $Database == "postgresql" ] 
then (
	docker cp postgres_create_user.sql IAF_postgres:/create_user.sql
	docker exec -it IAF_postgres psql -U postgres -f create_user.sql -v db=$Ibis_Name -v user=${Ibis_Name}_user
) 
elif [ $Database == "oracle" ]
then ( 
	docker cp oracle_create_user.sql IAF_oracle:/create_user.sql
	docker exec -it IAF_oracle bash -c "source /home/oracle/.bashrc; sqlplus /nolog @create_user.sql c##${Ibis_Name}_user"
) 
elif [ $Database == "mssql" ] 
then (
	docker cp mssql_create_user.sql IAF_mssql:/create_user.sql
  docker exec -it IAF_mssql bash -c "echo :setvar db $Ibis_Name > param_input.sql"
  docker exec -it IAF_mssql bash -c "echo :setvar user c##${Ibis_Name}_user >> param_input.sql"
  docker exec -it IAF_mssql bash -c "cat create_user.sql >> param_input.sql"
	docker exec -it IAF_mssql bash -c "/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P 'SqlDevOps2017' -i create_user.sql"
)
elif [ $Database == "mysql" ] 
then (
  docker cp mysql_create_user.sql IAF_mysql:/create_user.sql
  docker exec -it IAF_mysql bash -c "sed -i 's/@user/%Ibis_Name%_user/g' create_user.sql"
  docker exec -it IAF_mysql bash -c "sed -i 's/@db/%Ibis_Name%/g' create_user.sql"
  docker exec -it IAF_mysql bash -c "mysql --password=root < create_user.sql"
)
elif [ $Database == "mariadb" ] 
then (
  docker cp mariadb_create_user.sql IAF_mariadb:/create_user.sql
  docker exec -it IAF_mariadb bash -c "sed -i 's/@user/%Ibis_Name%_user/g' create_user.sql"
  docker exec -it IAF_mariadb bash -c "sed -i 's/@db/%Ibis_Name%/g' create_user.sql"
  docker exec -it IAF_mariadb bash -c "mysql --password=root < create_user.sql"
)
fi

docker-compose up $Ibis_Name

exit