# Demo Path

## Overview
- Show Cluster Health and allocation
- Show Universe/Catalog/Packages available
- Show deployed services.

## Easy of deployment
- Show simple container deployment.
    - App name should be /website.
    - Deploy yaalexf/demo-website container using UI.
    - Map port 80 to webport
- Access using `http://PUBLIC_IP:10080/`.  Call attention how it is always hitting the same host.
- Scale up.
- Show load balancer working.  The page should show hitting different hosts across refreshs.
- Show vanilla Kubernetes.
    - `https://PUBLIC_IP/#!/overview?namespace=default`
    - Config file at `~/.kube/config`
- Deploy yaalexf/kafka-producer on K8s.
    - ```kubectl apply -f kafka-producer.yaml```
    - Dashboard `1.12 DC/OS Kafka Dashboard`
- Show messages coming in Kafka using Grafana.
    - `http://PUBLIC_IP:3000/`
    - admin/admin

## 2nd day operations
- Show task recovery crashing server
    - Show /website tasks side-by-side with a browser window.
    - Access the URL `http://PUBLIC_IP:10080/crash`
    - Call attention to how one task dies and it is quickly replaced.
- Upgrade Kafka
    - Shows current version and what versions are available for downgrade and upgrade.
        - ```dcos kafka update package-versions```
    - Starts the updagrade itself.
        - ```dcos kafka update start --package-version="2.3.0-1.1.0"```
    - Show the tasks being replaced on DC/OS UI or go back to Grafana and show how it is still receiving events.

### Optional 
- Deploy second Kubernetes using CLI
    - ```dcos kubernetes cluster create --options=k8s-uat.options.json```


