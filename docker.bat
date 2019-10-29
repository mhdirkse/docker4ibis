@echo off

setlocal EnableExtensions EnableDelayedExpansion

set projects_directory=..
set ibis_name=%1
set database=h2
set hostport=80
set otap_stage=LOC

for /f "tokens=1,2 delims==" %%i in (docker4ibis.properties) do set %%i=%%j

set ibis_classes=classes
set ibis_config=configurations
set ibis_tests=tests

PUSHD "%projects_directory%/%1"
if exist docker4ibis.properties (
	for /f "tokens=1,2 delims==" %%i in (%projects_directory%/%1/docker4ibis.properties) do set %%i=%%j
)
POPD

rem set ibis_classes=%ibis_classes:$projects_directory=!projects_directory!%
rem set ibis_classes=%ibis_classes:$ibis_name=!ibis_name!%
rem if defined ibis_config set ibis_config=%ibis_config:$projects_directory=!projects_directory!%
rem if defined ibis_config set ibis_config=%ibis_config:$ibis_name=!ibis_name!%
rem if defined ibis_tests set ibis_tests=%ibis_tests:$projects_directory=!projects_directory!%
rem if defined ibis_tests set ibis_tests=%ibis_tests:$ibis_name=!ibis_name!%

(
echo version: "3"
echo services:
echo   oracle:
echo     image: store/oracle/database-enterprise:12.2.0.1
echo     container_name: IAF_oracle
echo     expose:
echo       - "1521"
echo       - "5500"
echo.
echo   mssql:
echo     image: mcr.microsoft.com/mssql/server
echo     container_name: IAF_mssql
echo     expose:
echo       - "1433"
echo     environment:
echo       - "ACCEPT_EULA=Y"
echo       - "SA_PASSWORD=SqlDevOps2017"
echo       - "MSSQL_PID=Developer"
echo.
echo   postgresql:
echo     image: postgres
echo     container_name: IAF_postgres
echo     expose:
echo       - "5432"
echo     environment:
echo       - "POSTGRES_PASSWORD:root"
echo.
echo   mysql:
echo     image: mysql
echo     container_name: IAF_mysql
echo     expose:
echo       - "3306"
echo     environment:
echo       - MYSQL_ROOT_PASSWORD=root
echo     command: 
echo       --lower_case_table_names=1
echo.
echo   mariadb:
echo     image: mariadb
echo     container_name: IAF_mariadb
echo     expose:
echo       - "3306"
echo     environment:
echo       - MYSQL_ROOT_PASSWORD=root
echo     command: 
echo       --lower_case_table_names=1
echo.
echo   wait:
echo     image: ibissource/iaf:7.5
echo     container_name: waiting_container
echo     command: bash -c ^"
if "%database%" == "oracle" echo        ./wait-for-it.sh IAF_oracle:5500 --timeout=0 --strict -- sleep 2^"
if "%database%" == "mssql" echo        ./wait-for-it.sh IAF_mssql:1433 --timeout=0 --strict -- sleep 2^"
if "%database%" == "postgresql" echo        ./wait-for-it.sh IAF_postgres:5432 --timeout=0 --strict -- sleep 2^" 
if "%database%" == "mysql" echo        ./wait-for-it.sh IAF_mysql:3306 --timeout=0 --strict -- sleep 2^"
if "%database%" == "mariadb" echo        ./wait-for-it.sh IAF_mariadb:3306 --timeout=0 --strict -- sleep 2^"
echo.
echo   %ibis_name%:
echo     image: ibissource/iaf:7.5
echo     container_name: %ibis_name%
echo     ports:
echo       - "%hostport%:8080"
echo     volumes:
echo       - %projects_directory%/%ibis_name%/%ibis_classes%:/usr/local/tomcat/contextpath/docker/WEB-INF/classes
if defined ibis_config echo       - %projects_directory%/%ibis_name%/%ibis_config%:/usr/local/ibis/configurations
if defined ibis_tests echo       - %projects_directory%/%ibis_name%/%ibis_tests%:/usr/local/ibis/tests
echo     environment:
echo       - ^"JAVA_OPTS=-Dotap.stage=%otap_stage% -Dinstance.name=%ibis_name% -Dscenariosroot1.directory=/usr/local/ibis/tests -Dscenariosroot1.description=Default -Dlocal.temp=/usr/local/tomcat/logs -Dconfigurations.directory=/usr/local/ibis/configurations^"
echo     command: bash -c ^"
echo        ./iaf-setup.sh %database% %ibis_name%^"
) > docker-compose.yml

if defined database if NOT "%database%" == "h2" (
	docker-compose up -d %database%
    docker-compose up wait
    docker stop waiting_container
	docker rm waiting_container
)

if "%database%" == "postgresql" (
	docker cp postgres_create_user.sql IAF_postgres:/create_user.sql
	docker exec -it IAF_postgres psql -U postgres -f create_user.sql -v db=%ibis_name% -v user=%ibis_name%_user
) else if "%database%" == "oracle" (
	docker cp oracle_create_user.sql IAF_oracle:/create_user.sql
	docker exec -it IAF_oracle bash -c "source /home/oracle/.bashrc; sqlplus /nolog @create_user.sql c##%ibis_name%_user"
) else if "%database%" == "mssql" (
	docker cp mssql_create_user.sql IAF_mssql:/create_user.sql
	docker exec -it IAF_mssql bash -c "echo :setvar db %ibis_name% > param_input.sql"
	docker exec -it IAF_mssql bash -c "echo :setvar user c##%ibis_name%_user >> param_input.sql"
	docker exec -it IAF_mssql bash -c "cat create_user.sql >> param_input.sql"
	docker exec -it IAF_mssql bash -c "/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P 'SqlDevOps2017' -i param_input.sql"
) else if "%database%" == "mysql" (
	docker cp mysql_create_user.sql IAF_mysql:/create_user.sql
	docker exec -it IAF_mysql bash -c "sed -i 's/@user/%ibis_name%_user/g' create_user.sql"
	docker exec -it IAF_mysql bash -c "sed -i 's/@db/%ibis_name%/g' create_user.sql"
	docker exec -it IAF_mysql bash -c "mysql --password=root < create_user.sql"
) else if "%database%" == "mariadb" (
	docker cp mariadb_create_user.sql IAF_mariadb:/create_user.sql
	docker exec -it IAF_mariadb bash -c "sed -i 's/@user/%ibis_name%_user/g' create_user.sql"
	docker exec -it IAF_mariadb bash -c "sed -i 's/@db/%ibis_name%/g' create_user.sql"
	docker exec -it IAF_mariadb bash -c "mysql --password=root < create_user.sql"
)

docker-compose up %ibis_name%

exit
