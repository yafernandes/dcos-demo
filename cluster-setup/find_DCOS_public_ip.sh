#! /bin/bash
for id in $(dcos node --json | jq --raw-output '.[] | select(.attributes.public_ip == "true") | .id');
do
	dcos node ssh --user=centos --option StrictHostKeyChecking=no --option LogLevel=quiet --master-proxy --mesos-id=$id "curl -s ifconfig.co" ;
done 2> /dev/null
