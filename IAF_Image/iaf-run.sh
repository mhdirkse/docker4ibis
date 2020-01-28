#!/usr/bin/env bash

export scriptDir=$(dirname $(readlink -f $0))
source iaf-setup.sh $@
/usr/local/tomcat/bin/catalina.sh run
