# 10 steps to install IBM Cloud private
## Cloud Native edition v3.2.0

## Prerequisite
- Before you install make sure that your server meet system requirements for ICP
https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.0/supported_system_config/hardware_reqs.html
- Download ICP's preconfigured Docker engine from IBM PPA `icp-docker-18.03.1_x86_64.bin` to `/tmp`
- Download ICP installer from IBM PPA `ibm-cloud-private-x86_64-3.1.0.tar.gz` to `/tmp`
### Hardware requirements

| Node name                                        | # node | CPU | RAM (GB) | File system                                                                                                                                                    | FS type                | OS                                 |
|--------------------------------------------------|--------|-----|----------|----------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------|------------------------------------|
| Boot                                             | 1      | 2   | 4        | /: 60GB /var/lib/docker: 100GB<br> /var/lib/kubelet: 10GB<br> /nfsvol: 100GB                                                                                        | ext4, or,xfs (ftype=1) | RHEL 7.3 or above, or Ubuntu 16.01 |
| Master/proxy                                     | 1      | 8   | 32       | /: 60GB /var: 240GB<br> /var/lib/docker: 100GB<br> /var/lib/etcd: 15GB<br> /var/lib/icp: 100GB<br> /var/lib/mysql: 10GB<br> /var/lib/registry: 100GB<br> /var/lib/kubelet: 10GB | ext4, or,xfs (ftype=1) | RHEL 7.3 or above, or Ubuntu 16.01 |
| Worker                                           | 3      | 4   | 16       | /: 60GB<br> /var/lib/docker: 100GB<br> /var/lib/kubelet: 10GB                                                                                                       | ext4, or,xfs (ftype=1) | RHEL 7.3 or above, or Ubuntu 16.01 |
| Mgmt + VA (optional for monitoring and security) | 1      | 12  | 24       | /: 60GB<br> /var: 240GB<br> /var/lib/docker: 100GB<br> /var/lib/icp: 100GB<br> /var/lib/kubelet: 10GB                                                                      | ext4, or,xfs (ftype=1) | RHEL 7.3 or above, or Ubuntu 16.01 |

### Optional: Configure AWS environment
Follow this article to prepare AWS resources if ICP is AWS Cloud platform
https://medium.com/ibm-cloud/run-ibm-cloud-private-on-amazon-web-services-aws-cloud-platform-c2cec1020ba8

## Install IBM Cloud private
__Step 1__ - Copy `ibm-cloud-private-x86_64-3.2.0.tar.gz` to all the nodes (Boot/Master/Proxy/Worker/Management/VA nodes)  

__Step 2__ - Copy icp-docker-18.03.1_x86_64.bin to all the nodes  

__Step 3__ - install docker on all nodes  
```shell
sudo icp-docker-18.03.1_x86_64.bin --install
```
__Step 4__ - Configure SSH access from boot node to all nodes  
- Generate ssh key on boot node
```shell
mkdir -p /root/.ssh
sudo ssh-keygen -b 4096 -t rsa -f /root/.ssh/master.id_rsa -N ""
```
- Copy ssh key to all other nodes
```shell
export SSH_KEY=$(cat /root/.ssh/master.id_rsa.pub)
ssh root@icpmaster "echo ${SSH_KEY} | tee -a /root/.ssh/authorized_keys"
ssh root@icpmgmt "echo ${SSH_KEY} | tee -a /root/.ssh/authorized_keys"
ssh root@icpworker01 "echo ${SSH_KEY} | tee -a /root/.ssh/authorized_keys"
ssh root@icpworker02 "echo ${SSH_KEY} | tee -a /root/.ssh/authorized_keys"
ssh root@icpworker03 "echo ${SSH_KEY} | tee -a /root/.ssh/authorized_keys"
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
tar xf ibm-cloud-private-x86_64-3.2.0.tar.gz -O | sudo docker load
```

__Step 7__ - On boot node, generate cluster config files
```shell
mkdir /opt/ibm-cloud-private-3.2.0
cd /opt/ibm-cloud-private-3.2.0
sudo docker run -v $(pwd):/data -e LICENSE=accept ibmcom/icp-inception-amd64:3.2.0-ee cp -r cluster /data
cd cluster
mkdir images
sudo cp /tmp/ibm-cloud-private-x86_64-3.2.0.tar.gz ./images/
```

__Step 8__ 
- edit `/opt/ibm-cloud-private-3.2.0/cluster/hosts` with the correct IPs of each node
```shell
vim /opt/ibm-cloud-private-3.2.0/cluster/hosts
```
- copy ssh key
```shell
sudo cp /root/.ssh/master.id_rsa /opt/ibm-cloud-private-3.2.0/cluster/ssh_key
sudo chmod 400 /opt/ibm-cloud-private-3.2.0/cluster/ssh_key
```

__Step 9__ - update `/opt/ibm-cloud-private-3.2.0/cluster/config.yaml` to disable/enable custom features
Follow this [link](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.0/installing/config_yaml.html) for this list of config parameters

* Refer to the [GlusterFS configuration](https://github.com/cloudnativedemo/icp-notes/blob/master/installicp.md#configure-glusterfs-during-the-icp-install-optional) below prior to step 10 if you wish to install GlusterFS

* For AWS, set the followings on config.yaml:
  - cloud_provider: aws
  - kubelet_nodename: nodename
  - ansible_user: <ec2/ubuntu>
  - ansible_become: true # allow ansible user to sudo
  - calico_tunnel_mtu: 8981
  - cluster_CA_domain: #in lower case
  - cluster_lb_address: #in lower case
  - proxy_lb_address: #in lower case

__Step 10__ - start the installation
```
cd /opt/ibm-cloud-private-3.2.0/cluster
sudo docker run --net=host -t -e LICENSE=accept -v $(pwd):/installer/cluster ibmcom/icp-inception-amd64:3.2.0-ee install
```

If all are going well, the install process will take around 2 hrs. At the end of the installation, you will be able to see the URL to access ICP's admin console

## Post-installation

### Setting up CLI tools
You can download the CLI tools (`cloudctl` `kubectl` `helm`) into your Linux workstation. You can take advantage of the boot node as your client workstation. Links to the tools are available on the `admin console` > `Command Line Tools`  
  ```shell
  curl -kLo cloudctl https://<MASTER_IP>:8443/api/cli/cloudctl-linux-amd64
  curl -kLo kubectl https://<MASTER_IP>:8443/api/cli/kubectl-linux-amd64
  curl -kLo helm-linux-amd64.tar.gz https://<MASTER_IP>:8443/api/cli/helm-linux-amd64.tar.gz;tar zxf helm-linux-amd64.tar.gz; cp linux-amd64/helm ./
  chmod +x cloudctl kubectl helm
  cp cloudctl kubectl helm /usr/local/bin
  ```

### Setting up Docker CA cert
Copy ca.crt from master node to your workstation (boot node)
On your workstation
```shell
mkdir -p /etc/docker/certs.d/<CLUSTER_DOMAIN>\:8500 #as defined in config.yaml
scp icpmaster:/etc/docker/certs.d/<CLUSTER_DOMAIN>\:8500/ca.crt /etc/docker/certs.d/<CLUSTER_DOMAIN>\:8500
```
Test login to your docker registry
```shell
docker login <CLUSTER_DOMAIN>:8500 #with icp cluster username and password as defined in config.yaml
```

### Pre-create persistent volumes for your workloads
Follow this [instructions](https://github.com/cloudnativedemo/icp-notes/tree/master/scripts/pv) for bulk create PVs for your workloads

---
### Configure GlusterFS during the icp install (optional)
GlusterFs configuration guide with more details can be found on [ICP Knowledge Centre](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.2.0/manage_cluster/glusterfs_land.html)

These steps are optional prior to icp install. 
Glusterfs volumes must reside within worker nodes (3 or above)
On each worker node:
- Clean up an existing volume if it's already mounted (if starting with a fresh unmounted volume, you can skip this step)
```
# find <FILE_SYSTEM> of an existing volume
df -h

# unmount the volume
umount <FILE_SYSTEM>

# remove logical volume
lvremove -y <FILE_SYSTEM>

# locate its device name (e.g. /dev/sdxx) and ensure the volume size is correct
fdisk -l

# remove all file system in the device
sudo wipefs --all --force /dev/sdxx
```
- Identify symbol link of the glusterfs device
```
ls -altr /dev/disk/*  | grep sdxx
```
- Copy the symlink under **/dev/disk/by-path:**
- If there's no symlink for the device, you must create one. 
Note: the new version of GlusterFs **only accept alphanumeric** for the symlink, if the existing device symbol link contains **special character** e.g colon (:), you must **manually create a symlink for it**
```
# Get device info and copy its DEVPATH
udevadm info --root --name=/dev/sdxx

# Create a custom udev rules file
tee /lib/udev/rules.d/10-glusterfs-icp.rules <<-EOF
ENV{DEVTYPE}=="disk", ENV{SUBSYSTEM}=="block", ENV{DEVPATH}=="<REPLACE_WITH_DEVPATH_VALUE>" SYMLINK+="disk/gluster-disk-1"
EOF

# Reload the udev rules to create the symlinks
udevadm control --reload-rules
udevadm trigger --type=devices --action=change

# Verify that the symlinks are created
ls -ltr /dev/disk/gluster-*
```
- Install and configure GlusterFS client on each worker node
```
# Add yum repo
tee /etc/yum.repos.d/glusterfs.repo <<-EOF
[centos-gluster40]
name=CentOS-\$releasever - Gluster 4.0
baseurl=https://buildlogs.centos.org/centos/7/storage/\$basearch/gluster-4.0/
gpgcheck=0
enabled=1

EOF

sudo yum install glusterfs-client -y
sudo modprobe dm_thin_pool
echo dm_thin_pool | sudo tee -a /etc/modules-load.d/dm_thin_pool.conf
```


- On the boot node, edit `/opt/ibm-cloud-private-3.2.0/cluster/hosts`
```
tee -a /opt/ibm-cloud-private-3.2.0/cluster/hosts <<-EOF
[hostgroup-glusterfs]
<REPLACE_WORKER_IP_1_HERE>
<REPLACE_WORKER_IP_2_HERE>
<REPLACE_WORKER_IP_3_HERE>
EOF

```

- On the boot node, edit `/opt/ibm-cloud-private-3.2.0/cluster/config.yaml`
> Enable storage-glusterfs
```
...
management_services:
 storage-glusterfs: enabled
...
```
> Add GlusterFS settings to `/opt/ibm-cloud-private-3.2.0/cluster/config.yaml`
```
## GlusterFS Storage Settings
storage-glusterfs:
  nodes:
    - ip: <worker_node_1_IP_address>
      devices:
        - /dev/disk/gluster-disk-1
    - ip: <worker_node_2_IP_address>
      devices:
        - /dev/disk/gluster-disk-1
    - ip: <worker_node_3_IP_address>
      devices:
        - /dev/disk/gluster-disk-1
  storageClass:
    create: true
    name: glusterfs
    isDefault: false
    volumeType: replicate:3
    reclaimPolicy: Delete
    volumeBindingMode: Immediate
    volumeNamePrefix: icp
    additionalProvisionerParams: {}
    allowVolumeExpansion: true
  gluster:
    resources:
      requests:
        cpu: 100m
        memory: 128Mi
      limits:
        cpu: 200m
        memory: 256Mi
  heketi:
    backupDbSecret: heketi-db-backup
    authSecret: "heketi-secret"
    resources:
      requests:
        cpu: 500m
        memory: 512Mi
      limits:
        cpu: 1000m
        memory: 1Gi
  prometheus:
    enabled: false
    path: "/metrics"
    port: 8080
  nodeSelector:
    key: hostgroup
    value: glusterfs
  podPriorityClass: "system-cluster-critical"
  tolerations: []
```


### Add more worker node to an existing cluster
- To add more worker node onto the cluster. On the boot node, run the following command:
```shell
cd /opt/ibm-cloud-private-3.2.0/cluster
sudo docker run --net=host -t -e LICENSE=accept -v $(pwd):/installer/cluster ibmcom/icp-inception-amd64:3.2.0-ee worker -l <NEW_WORKER_IP_1>,<NEW_WORKER_IP_2>,<NEW_WORKER_IP_3>
```

## Notes:
- Boot nodes is used to install/uninstall/re-install icp and add more worker node to icp cluster. It's important to keep the Boot node safe and back it up if necessary
- To free up some disk space, you can unload unused Docker images. On the master/proxy/management/VA/worker nodes (except Boot node), run the following command to unload unused Docker images
```shell
docker rmi $(docker images --format="{{.Repository}}:{{.Tag}}" | grep "ibmcom")
```

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
- If you experience a 'No host' error during the install, you might need to
  - Double check the file systems on all nodes. Sometimes file systems are broken
  - Extend SSH keep-alive time on all nodes as described [here](https://www.howtogeek.com/howto/linux/keep-your-linux-ssh-session-from-disconnecting/) 
