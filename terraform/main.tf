# Used to determine your public IP for forwarding rules
data "http" "whatismyip" {
  url = "http://whatismyip.akamai.com/"
}

provider "aws" {
 region = "us-east-1"
}

module "dcos" {
  source = "dcos-terraform/dcos/aws"

  # dcos_instance_os    = "coreos_1855.5.0"
  dcos_instance_os    = "centos_7.5"
  cluster_name        = "afernandes" 
  ssh_public_key_file = "~/secrets/mesosphere.id_rsa.pub"
  admin_ips           = ["0.0.0.0/0"]

  num_masters        = "1"
  num_private_agents = "3"
  num_public_agents  = "1"

  bootstrap_instance_type = "t3.medium"
  masters_instance_type = "m5a.xlarge"
  private_agents_instance_type = "m5a.2xlarge"
  public_agents_instance_type = "m5a.2xlarge"

  # availability_zones = ["us-east-1a","us-east-1b","us-east-1c"]
  dcos_version = "1.12.1"

  # dcos_variant = "open"
  dcos_variant = "ee"
  dcos_license_key_contents = "${file("~/secrets/license.txt")}"

  dcos_resolvers      = "\n   - 169.254.169.253"  # Required for Flink demo
  tags={owner = "afernandes"} 

  public_agents_additional_ports = [
    "6443",  # k8s-prod
    "7443",  # k8s-uat
    "10080", # demo-website
    "10443", # demo-website using https
    "3000",  # Grafana
    "9090",  # Prometheus
    "9093",  # Prometheus Alert Manager
    "9091",  # Prometheus Push Gateway
    "12080", # Portworx Lighthouse
    "8888",  # Jupyter Notebook
    "11080", # CI/CD demo - /jupyter-deployed-app
    "30443", # Kubernetes Dashboard exposed using NodePort
    "6090"   # HAProxy
    ]
}

output "masters-ips" {
  value = "${module.dcos.masters-ips}"
}

output "cluster-address" {
  value = "${module.dcos.masters-loadbalancer}"
}

output "public-agents-loadbalancer" {
  value = "${module.dcos.public-agents-loadbalancer}"
}