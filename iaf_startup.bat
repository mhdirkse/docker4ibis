@echo off

setlocal EnableExtensions EnableDelayedExpansion

set Project_Directory=..
set Ibis_Name=%1
set Database=h2
set Hostport=80
set Otap_Stage=LOC
set Ibis_Classes=%Project_Directory%/%Ibis_Name%/classes
set Ibis_Config=%Project_Directory%/%Ibis_Name%/configurations
set Ibis_Tests=%Project_Directory%/%Ibis_Name%/tests

for /f "tokens=1,2 delims==" %%i in (project_directory.txt) do set %%i=%%j
for /f "tokens=1,2 delims==" %%i in (%Project_Directory%/%1/properties.txt) do set %%i=%%j
set Ibis_Classes=%Ibis_Classes:$Project_Directory=!Project_Directory!%
set Ibis_Classes=%Ibis_Classes:$Ibis_Name=!Ibis_Name!%
if defined Ibis_Config set Ibis_Config=%Ibis_Config:$Project_Directory=!Project_Directory!%
if defined Ibis_Config set Ibis_Config=%Ibis_Config:$Ibis_Name=!Ibis_Name!%
if defined Ibis_Tests set Ibis_Tests=%Ibis_Tests:$Project_Directory=!Project_Directory!%
if defined Ibis_Tests set Ibis_Tests=%Ibis_Tests:$Ibis_Name=!Ibis_Name!%

(
echo version: "3"
echo services:
echo   oracle:
echo     image: container-registry.oracle.com/database/enterprise
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
echo       - "POSTGRES_PASSWORD: testiaf_user"
echo.
echo   wait:
echo     image: iaf:7.5
echo     container_name: waiting_container
echo     command: bash -c ^"
if "%Database%" == "oracle" echo        ./wait-for-it.sh IAF_oracle:5500 --timeout=0 --strict -- sleep 2^"
if "%Database%" == "mssql" echo        ./wait-for-it.sh IAF_mssql:1433 --timeout=0 --strict -- sleep 2^"
if "%Database%" == "postgresql" echo        ./wait-for-it.sh IAF_postgres:5432 --timeout=0 --strict -- sleep 2^" 
echo.
echo   %Ibis_Name%:
echo     image: iaf:7.5
echo     container_name: %Ibis_Name%
echo     ports:
echo       - "%Hostport%:8080"
echo     volumes:
echo       - %Ibis_Classes%:/usr/local/tomcat/contextpath/docker/WEB-INF/classes
if defined Ibis_Config echo       - %Ibis_Config%:/usr/local/ibis/configurations
if defined Ibis_Tests echo       - %Ibis_Tests%:/usr/local/ibis/tests
echo     environment:
echo       - ^"JAVA_OPTS=-Dotap.stage=%Otap_Stage% -Dinstance.name=%Ibis_Name% -Dscenariosroot1.directory=/usr/local/ibis/tests -Dscenariosroot1.description=Default -Dlocal.temp=/usr/local/tomcat/logs -Dconfigurations.directory=/usr/local/ibis/configurations^"
echo     command: bash -c ^"
echo        ./iaf-setup.sh %Database% %Ibis_Name%^"
) > docker-compose.yml

if defined Database if NOT "%Database%" == "h2" (
	docker-compose up -d %Database%
    docker-compose up wait
    docker stop waiting_container
	docker rm waiting_container
)

if "%Database%" == "postgresql" (
	docker cp postgres_create_user.sql IAF_postgres:/create_user.sql
	docker exec -it IAF_postgres psql -U postgres -f create_user.sql -v db=%Ibis_Name% -v user=%Ibis_Name%_user
) else if "%Database%" == "oracle" (
	docker cp oracle_create_user.sql IAF_oracle:/create_user.sql
	docker exec -it IAF_oracle bash -c "source /home/oracle/.bashrc; sqlplus /nolog @create_user.sql c##%Ibis_Name%_user"
) else if "%Database%" == "mssql" (
	docker cp mssql_create_user.sql IAF_mssql:/create_user.sql
	docker exec -it IAF_mssql bash -c "echo :setvar db %Ibis_Name% > param_input.sql"
	docker exec -it IAF_mssql bash -c "echo :setvar user c##%Ibis_Name%_user >> param_input.sql"
	docker exec -it IAF_mssql bash -c "cat create_user.sql >> param_input.sql"
	docker exec -it IAF_mssql bash -c "/opt/mssql-tools/bin/sqlcmd -S localhost -U SA -P 'SqlDevOps2017' -i param_input.sql"
)

docker-compose up %Ibis_Name%

exit
