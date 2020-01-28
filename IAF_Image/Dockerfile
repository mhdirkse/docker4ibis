FROM tomcat:7.0.93-jre8
ENV IAF_VERSION=7.5-20190918.183145
WORKDIR /usr/local/tomcat/webapps
RUN rm -rf docker
RUN wget -O docker.war "https://nexus.ibissource.org/content/groups/public/org/ibissource/ibis-adapterframework-webapp/${IAF_VERSION}/ibis-adapterframework-webapp-${IAF_VERSION}.war"

RUN wget -O /usr/local/tomcat/lib/h2.jar "https://repo1.maven.org/maven2/com/h2database/h2/1.4.199/h2-1.4.199.jar"
RUN wget -O /usr/local/tomcat/lib/postgresql-42.0.0.jar "https://jdbc.postgresql.org/download/postgresql-42.0.0.jar"
RUN wget -O /usr/local/tomcat/lib/mysql-connector-java-5.1.44.jar "https://repo1.maven.org/maven2/mysql/mysql-connector-java/5.1.44/mysql-connector-java-5.1.44.jar"
RUN wget -O /usr/local/tomcat/lib/mariadb-java-client-2.3.0.jar "https://repo1.maven.org/maven2/org/mariadb/jdbc/mariadb-java-client/2.3.0/mariadb-java-client-2.3.0.jar"
RUN wget -O /usr/local/tomcat/lib/jtds-1.3.1.zip "http://www.java2s.com/Code/JarDownload/jtds/jtds-1.3.1.jar.zip"
RUN wget -O /usr/local/tomcat/lib/geronimo-jms_1.1_spec-1.1.1.jar "https://repo1.maven.org/maven2/org/apache/geronimo/specs/geronimo-jms_1.1_spec/1.1.1/geronimo-jms_1.1_spec-1.1.1.jar"
RUN wget -O /usr/local/tomcat/lib/commons-dbcp-1.4.jar "https://repo1.maven.org/maven2/commons-dbcp/commons-dbcp/1.4/commons-dbcp-1.4.jar"
RUN wget -O /usr/local/tomcat/lib/commons-pool-1.5.6.jar "https://repo1.maven.org/maven2/commons-pool/commons-pool/1.5.6/commons-pool-1.5.6.jar"
RUN unzip /usr/local/tomcat/lib/jtds-1.3.1.zip -d /usr/local/tomcat/lib
RUN rm /usr/local/tomcat/lib/jtds-1.3.1.zip

COPY wait-for-it.sh wait-for-it.sh 
RUN chmod +x wait-for-it.sh
COPY iaf-setup.sh iaf-setup.sh
COPY iaf-run.sh iaf-run.sh
RUN chmod +x iaf-setup.sh
RUN chmod +x iaf-run.sh
RUN bash -c "catalina.sh start; sleep 5;"
RUN mkdir /usr/local/tomcat/contextpath
RUN mv docker /usr/local/tomcat/contextpath/docker
RUN rm docker.war