#! /bin/bash

if [ -z "$1" ]; then
    echo "Usage: cluster_setup <URL>"
    exit 1
fi

if [ -z "$LANGUAGE" ]; then
    LANG=en_US.utf-8 LANGUAGE=en_US.utf-8 LC_ALL=en_US.utf-8
fi

# Setup dcos CLI
dcos cluster remove --all
dcos cluster setup https://$(echo $1 | sed -r "s|https?://||") --username=bootstrapuser --password=deleteme --no-check --insecure
dcos config set core.ssl_verify false
dcos package install dcos-enterprise-cli --yes

# Create service accounts
if [ ! -f public-key.pem ]; then
    dcos security org service-accounts keypair private-key.pem public-key.pem
fi

for service_account in k8s-prod k8s-dev k8s-test dcos-edgelb
do
    dcos security org service-accounts create -p public-key.pem -d 'Service account' $service_account
    dcos security org groups add_user superusers $service_account
    dcos security secrets create-sa-secret private-key.pem $service_account $service_account/sa
done

# Add repos
while read repo_url; do 
    dcos package repo add --index=0 $repo_url
done < ~/secrets/repos.txt

dcos package repo add --index=0 kubernetes-cluster-aws https://universe-converter.mesosphere.com/transform?url=https://infinity-artifacts.s3.amazonaws.com/autodelete7d/kubernetes-cluster/20190321-132924-7ULxAvO0rAS2UMnB/stub-universe-kubernetes-cluster.json
# Install EdgeLB
dcos package install --options=edgelb.options.json edgelb --yes

# Installs MKE
dcos package install kubernetes --yes

# Install previous Kafka version for upgrade demostration
dcos package install kafka --package-version="2.3.0-1.0.0" --options=kafka.options.json --yes

dcos package install prometheus --yes
dcos package install grafana --yes

# Configures EdgeLB
dcos security secrets create -f https.cert edgelb_cert
until dcos edgelb ping; do sleep 1; done
dcos edgelb create edgelb.cfg.json

# Installs Kubertnetes cluster k8s-prod.  First checks if MKE is fully deployed.
while [ -z "`dcos kubernetes manager plan status deploy | grep deploy | grep COMPLETE`" ]; do
    echo "MKE not ready.  Checking again in 10 secods."
    sleep 10;
done

PUBLIC_IP=$(./find_DCOS_public_ip.sh)
PUBLIC_IP=${PUBLIC_IP%$'\r'}

dcos kubernetes cluster create --options=k8s-prod.options.json --yes

# Setup kubectl.  First waits for Kubernets to be fully deployed
while [ -z "`dcos kubernetes cluster debug plan status deploy --cluster-name=k8s-prod | grep deploy | grep COMPLETE`" ]; do
    echo "Kubernetes Cluster not ready.  Checking again in 10 secods."
    sleep 10;
done

rm -rf ~/.kube
dcos kubernetes cluster kubeconfig \
    --insecure-skip-tls-verify \
    --context-name=k8s-prod \
    --cluster-name=k8s-prod \
    --apiserver-url=https://$PUBLIC_IP:6443/

# Installs dklb and exposes Kubernetes dashboard.
kubectl apply -f https://raw.githubusercontent.com/mesosphere/dklb/master/docs/deployment/00-prereqs.yaml
kubectl apply -f https://raw.githubusercontent.com/mesosphere/dklb/master/docs/deployment/10-deployment.yaml
kubectl apply -f dashboard-ext.yaml

# Setup Grafana Datasource and Dashboards
curl -s -u admin:admin \
-H "Content-Type: application/json" \
-d '{ "name": "Prometheus", "type": "prometheus", "url": "http://prometheus.prometheus.l4lb.thisdcos.directory:9090", "access": "proxy", "isDefault": true }' \
-X POST \
http://$PUBLIC_IP:3000/api/datasources

for dashboard_url in $(cat graphana_dashboards.txt); do
    echo -e "Importing $dashboard_url\n"
    dashboard=$(curl -s -H "Content-Type: application/json" $dashboard_url | jq -c .)
    curl -s -u admin:admin \
    -H "Content-Type: application/json" \
    -d "{ \
        \"dashboard\": $dashboard, \
        \"overwrite\": true, \
        \"inputs\": [{ \
            \"name\": \"DS_PROMETHEUS\", \
            \"type\": \"datasource\", \
            \"pluginId\": \"prometheus\", \
            \"value\": \"Prometheus\" \
        }] \
    }" \
    -X POST \
    http://$PUBLIC_IP:3000/api/dashboards/import
    echo -e "\n" 
done

echo -e "\nThe public ip is \033[0;32m$PUBLIC_IP\033[0m"