#!/bin/bash

if [ -z ${1+x} ]; then 
  echo "PLease give the Ibis name as argument.";
  exit 
fi

projects_directory=.. 
ibis_name=$1
database=h2
hostport=80
otap_stage=LOC

env | grep ^project\\.dir= | cut -d= -f2-

sed -i $'s/\r$//' docker4ibis.properties
source docker4ibis.properties
ibis_classes=classes
ibis_config=configurations
ibis_tests=tests

File=$projects_directory/$ibis_name/docker4ibis.properties
if test -f "$File"; then
  sed -i $'s/\r$//' $projects_directory/$1/docker4ibis.properties
  source $projects_directory/$1/docker4ibis.properties
fi

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
      - \"POSTGRES_PASSWORD:root\"

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
    image: ibissource/iaf:7.5-20190918.183145
    container_name: waiting_container     
    command: bash -c \""
) > docker-compose.yml
if [ $database == "oracle" ]
then
    echo "       ./wait-for-it.sh IAF_oracle:5500 --timeout=0 --strict -- sleep 2\"" >> docker-compose.yml
elif [ $database == "mssql" ]
then
	echo "       ./wait-for-it.sh IAF_mssql:1433 --timeout=0 --strict -- sleep 2\"" >> docker-compose.yml
elif [ $database == "postgresql" ]
then
	echo "       ./wait-for-it.sh IAF_postgres:5432 --timeout=0 --strict -- sleep 2\"" >> docker-compose.yml
elif [ $database == "mysql" ]
then
  echo "       ./wait-for-it.sh IAF_mysql:3306 --timeout=0 --strict -- sleep 2\"" >> docker-compose.yml
elif [ $database == "mariadb" ]
then
  echo "       ./wait-for-it.sh IAF_mariadb:3306 --timeout=0 --strict -- sleep 2\"" >> docker-compose.yml
fi
(
echo "
  $ibis_name:
    image: ibissource/iaf:7.5-20190918.183145
    container_name: $ibis_name
    ports:
      - \"$hostport:8080\"
    volumes:
      - $projects_directory/$ibis_name/$ibis_classes:/usr/local/tomcat/contextpath/docker/WEB-INF/classes"
) >> docker-compose.yml
if [ ! -z "$ibis_config" ]
then
	echo "      - $projects_directory/$ibis_name/$ibis_config:/usr/local/ibis/configurations" >> docker-compose.yml
fi
if [ ! -z "$ibis_tests" ]
then
	echo "      - $projects_directory/$ibis_name/$ibis_tests:/usr/local/ibis/tests" >> docker-compose.yml
fi
(
echo "    environment:
      - \"JAVA_OPTS=-Dotap.stage=$otap_stage -Dinstance.name=$ibis_name -Dscenariosroot1.directory=/usr/local/ibis/tests -Dscenariosroot1.description=Default -Dlocal.temp=/usr/local/tomcat/logs -Dconfigurations.directory=/usr/local/ibis/configurations\"
    command: bash -c \"
       ./iaf-setup.sh $database $ibis_name\""
) >> docker-compose.yml

if [ ! -z $database ] && [ ! $database == "h2" ]
then (
  docker-compose up -d $database
  docker-compose up wait
  docker stop waiting_container
  docker rm waiting_container
)
fi

if [ $database == "postgresql" ] 
then (
	docker cp postgres_create_user.sql IAF_postgres:/create_user.sql
	docker exec -it IAF_postgres psql -U postgres -f create_user.sql -v db=$ibis_name -v user=${ibis_name}_user
) 
elif [ $database == "oracle" ]
then ( 
	docker cp oracle_create_user.sql IAF_oracle:/create_user.sql
	docker exec -it IAF_oracle bash -c "source /home/oracle/.bashrc; sqlplus /nolog @create_user.sql c##${ibis_name}_user"
) 
elif [ $database == "mssql" ] 
then (
	docker cp mssql_create_user.sql IAF_mssql:/create_user.sql
  docker exec -it IAF_mssql bash -c "echo :setvar db $ibis_name > param_input.sql"
  docker exec -it IAF_mssql bash -c "echo :setvar user c##${ibis_name}_user >> param_input.sql"
  docker exec -it IAF_mssql bash -c "cat create_user.sql >> param_input.sql"
	docker exec -it IAF_mssql bash -c "/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P 'SqlDevOps2017' -i create_user.sql"
)
elif [ $database == "mysql" ] 
then (
  docker cp mysql_create_user.sql IAF_mysql:/create_user.sql
  docker exec -it IAF_mysql bash -c "sed -i 's/@user/%ibis_name%_user/g' create_user.sql"
  docker exec -it IAF_mysql bash -c "sed -i 's/@db/%ibis_name%/g' create_user.sql"
  docker exec -it IAF_mysql bash -c "mysql --password=root < create_user.sql"
)
elif [ $database == "mariadb" ] 
then (
  docker cp mariadb_create_user.sql IAF_mariadb:/create_user.sql
  docker exec -it IAF_mariadb bash -c "sed -i 's/@user/%ibis_name%_user/g' create_user.sql"
  docker exec -it IAF_mariadb bash -c "sed -i 's/@db/%ibis_name%/g' create_user.sql"
  docker exec -it IAF_mariadb bash -c "mysql --password=root < create_user.sql"
)
fi

docker-compose up $ibis_name

exit