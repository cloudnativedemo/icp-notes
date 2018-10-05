# 10 steps to install IBM Cloud private - Cloud Native edition v3.1

## Prerequisite
- Before you install make sure that your server meet system requirements for ICP
https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.0/supported_system_config/hardware_reqs.html
- Download ICP's preconfigured Docker engine from IBM PPA `icp-docker-18.03.1_x86_64.bin` to `/tmp`
- Download ICP installer from IBM PPA `ibm-cloud-private-x86_64-3.1.0.tar.gz` to `/tmp`

## Install IBM Cloud private
__Step 1__ - Copy `ibm-cloud-private-x86_64-3.1.0.tar.gz` to all the nodes (Boot/Master/Proxy/Worker/Management/VA nodes)
__Step 2__ - Copy icp-docker-18.03.1_x86_64.bin to all the nodes
__Step 3__ - install docker on all nodes
```shell
sudo icp-docker-18.03.1_x86_64.bin --install
```
__Step 4__ - Configure SSH access from boot node to all nodes
- Generate ssh key on boot node
```shell
sudo ssh-keygen -b 4096 -t rsa -f /root/master.id_rsa -N ""
```
- Copy ssh key to all other nodes
```shell
export SSH_KEY=$(cat /root/.ssh/master.id_rsa.pub)
ssh root@master_node "echo ${SSH_KEY} | tee -a /root/.ssh/authorized_keys"
ssh root@management_node "echo ${SSH_KEY} | tee -a /root/.ssh/authorized_keys"
ssh root@worker_node "echo ${SSH_KEY} | tee -a /root/.ssh/authorized_keys"
```
__Step 5__ - Verify OS configs
- On all nodes, check if nameserver is not pointing to a loopback ip
```shell
cat /etc/resolv.conf
```
- On all nodes, check if localhost is removed from `/etc/hosts`.
- On all nodes, check if hostname is all lowercase
- From boot node, double check if you can SSH to all other nodes using the generated SSH key on __step 4__ 

__Step 6__ - Load icp images on __all nodes__ (this step will improve the installation time by at least 40 mins)
```shell
cd /tmp
tar xf ibm-cloud-private-x86_64-3.1.0.tar.gz -O | sudo docker load
```
__Step 7__ - On boot node, generate cluster config files
```shell
mkdir /opt/ibm-cloud-private-3.1.0
cd /opt/ibm-cloud-private-3.1.0
sudo docker run -v $(pwd):/data -e LICENSE=accept ibmcom/icp-inception-amd64:3.1.0-ee cp -r cluster /data
cd cluster
mkdir images
sudo cp /tmp/ibm-cloud-private-x86_64-3.1.0.tar.gz ./images/
```
__Step 8__ - update `/opt/ibm-cloud-private-3.1.0/cluster/hosts` with the correct IPs of each node
```shell
vim /opt/ibm-cloud-private-3.1.0/cluster/hosts
```
__Step 9__ - update `/opt/ibm-cloud-private-3.1.0/cluster/config.yaml` to disable/enable custom features
Follow this [link](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.0/installing/config_yaml.html) for this list of config parameters
__Step 10__ - start the installation
```
cd /opt/ibm-cloud-private-3.1.0/cluster
sudo docker run --net=host -t -e LICENSE=accept -v $(pwd):/installer/cluster ibmcom/icp-inception-amd64:3.1.0-ee install
```

If all are going well, the install process will take around 2 hrs. At the end of the installation, you will be able to see the URL to access ICP's admin console

## Troubleshooting
If error occurs, you can SSH to the master node to troubleshoot
- To identify error pods
```shell
# list all system pods
kubectl get -n kube-system pods
```
- To view logs of the error pods
```shell
kubectl logs -n kube-system <POD_NAME>
```
