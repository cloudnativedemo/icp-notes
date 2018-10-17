# 10 steps to install IBM Cloud private
## Cloud Native edition v3.1

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
mkdir -p /root/.ssh
sudo ssh-keygen -b 4096 -t rsa -f /root/.ssh/master.id_rsa -N ""
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

* Refer to the [GlusterFS configuration](https://github.com/cloudnativedemo/icp-notes/blob/master/installicp.md#configure-glusterfs-during-the-icp-install-optional) below prior to step 10 if you wish to install GlusterFS

__Step 10__ - start the installation
```
cd /opt/ibm-cloud-private-3.1.0/cluster
sudo docker run --net=host -t -e LICENSE=accept -v $(pwd):/installer/cluster ibmcom/icp-inception-amd64:3.1.0-ee install
```

If all are going well, the install process will take around 2 hrs. At the end of the installation, you will be able to see the URL to access ICP's admin console

---
### Configure GlusterFS during the icp install (optional)
GlusterFs configuration guide with more details can be found on [ICP Knowledge Centre](https://www.ibm.com/support/knowledgecenter/en/SSBS6K_3.1.0/manage_cluster/glusterfs_land.html)

These steps are optional prior to icp install. 
Glusterfs volumes must reside within worker nodes (3 or above)
On each worker node:
- Clean up an existing volume if it's already mounted (if starting with a fresh unmounted volume, you can skip this step)
```
# find <SYMBOL_LINK> of an existing volume
df -h

# unmount the volume
umount <SYMBOL_LINK>

# remove logical volume
lvremove <SYMBOL_LINK>

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


- On the boot node, edit `/opt/ibm-cloud-private-3.1.0/cluster/hosts`
```
tee -a /opt/ibm-cloud-private-3.1.0/cluster/hosts <<-EOF
[hostgroup-glusterfs]
<REPLACE_WORKER_IP_1_HERE>
<REPLACE_WORKER_IP_2_HERE>
<REPLACE_WORKER_IP_3_HERE>
EOF

```

- On the boot node, edit `/opt/ibm-cloud-private-3.1.0/cluster/config.yaml`
> Enable storage-glusterfs
```
...
management_services:
 storage-glusterfs: enabled
...
```
> Add GlusterFS settings to `/opt/ibm-cloud-private-3.1.0/cluster/config.yaml`
```
## GlusterFS Storage Settings
storage-glusterfs:
  nodes:
    - ip: <worker_node_m_IP_address>
      devices:
        - <link path>/<symlink of device aaa>
        - <link path>/<symlink of device bbb>
    - ip: <worker_node_n_IP_address>
      devices:
        - <link path>/<symlink of device ccc>
    - ip: <worker_node_o_IP_address>
      devices:
        - <link path>/<symlink of device ddd>
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
cd /opt/ibm-cloud-private-3.1.0/cluster
sudo docker run --net=host -t -e LICENSE=accept -v $(pwd):/installer/cluster ibmcom/icp-inception-amd64:3.1.0-ee worker -l <NEW_WORKER_IP_1>,<NEW_WORKER_IP_2>,<NEW_WORKER_IP_3>
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
