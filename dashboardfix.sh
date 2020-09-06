#!/usr/bin/env bash

working_dir= ~/jmeter-kubernetes

echo $working_dir

#Get namesapce variable
unset tenant
tenant=$(awk '{print $NF}' ~/jmeter-kubernetes/tenant_export)

echo $tenant

## Create jmeter database automatically in Influxdb

echo "Creating Influxdb jmeter Database"

##Wait until Influxdb Deployment is up and runningi
influxdb_status= minikube kubectl -- get po -n perf | grep influxdb-jmeter | awk '{print $3}'
echo $influxdb_status

##influxdb_pod= minikube kubectl -- get po -n $tenant | grep influxdb-jmeter | awk `{print $1}`

influxdb_pod= minikube kubectl -- get po -n perf | grep influxdb-jmeter | awk '{print $1}'

echo $influxdb_pod

minikube kubectl -- exec -it -n $tenant $influxdb_pod -- influx -execute 'CREATE DATABASE jmeter'

## Create the influxdb datasource in Grafana

echo "Creating the Influxdb data source"
grafana_pod= minikube kubectl -- get po -n $tenant | grep jmeter-grafana | awk '{print $1}'

## Make load test script in Jmeter master pod executable

#Get Master pod details

master_pod= minikube kubectl -- get po -n $tenant | grep jmeter-master | awk '{print $1}'

minikube kubectl -- exec -ti -n $tenant $master_pod -- cp -r /load_test /jmeter/load_test

minikube kubectl -- exec -ti -n $tenant $master_pod -- chmod 755 /jmeter/load_test

##kubectl cp $working_dir/influxdb-jmeter-datasource.json -n $tenant $grafana_pod:/influxdb-jmeter-datasource.json

minikube kubectl -- exec -ti -n $tenant $grafana_pod -- curl 'http://admin:admin@127.0.0.1:3000/api/datasources' -X POST -H 'Content-Type: application/json;charset=UTF-8' --data-binary '{"name":"jmeterdb","type":"influxdb","url":"http://jmeter-influxdb:8086","access":"proxy","isDefault":true,"database":"jmeter","user":"admin","password":"admin"}'

