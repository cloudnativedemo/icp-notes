#!/bin/bash

#COMMON ENV VARIABLES
BIN_DOWNLOAD_DIR="/install"
ICP_CLUSTER_NAME="icpcluster"
ICP_ADMIN_PWD="passw0rd"
MASTER_1_IP=130.198.77.44
#MASTER_2_IP=
#MASTER_3_IP=
MANAGEMENT_1_IP=130.198.77.43
VA_1_IP=130.198.77.45
PROXY_1_IP=130.198.77.37
#PROXY_2_IP=
#PROXY_3_IP=
WORKER_1_IP=130.198.77.34
WORKER_2_IP=130.198.77.39
#WORKER_3_IP=
SSH_KEY="/tmp/ssh_key"
CALICO_IPIP_ENABLED="true"
MGMT_SERVICES_ENABLED="false"
INSTALLER_BASEURL="true"
INSTALLER_FILENAME="ibm-cloud-private-x86_64-2.1.0.2.tar.gz"
INSTALL_DIR="/opt/ibm-cloud-private-2.1.0.2"
IMAGE_NAME="ibmcom/icp-inception:2.1.0.2-ee"

DOCKER_ENGINE_INSTALLER="icp-docker-17.09_x86_64.bin"

#download binaries
mkdir -p ${BIN_DOWNLOAD_DIR}

#step 2 - download installer (2.1beta)
#wget -P ${BIN_DOWNLOAD_DIR} ${INSTALLER_BASEURL}/${INSTALLER_FILENAME}

#step 3 - load images into Docker
cd ${BIN_DOWNLOAD_DIR} && tar xf ${INSTALLER_FILENAME} -O | sudo docker load

#create working directory for installation
#step 4
mkdir -p ${INSTALL_DIR}

#step 5 & 6
cd ${INSTALL_DIR} && sudo docker run -v $(pwd):/data -e LICENSE=accept ${IMAGE_NAME} cp -r cluster /data

#step 7
#gen key can copy pub key across cluster nodes
ssh-keygen -b 4096 -t rsa -f ~/.ssh/master.id_rsa -N ""
cat ~/.ssh/master.id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys

if [[ ! -z ${MASTER_1_IP+x} ]]; then
	echo "Copy SSH key to Master Node 1"
	echo ${MASTER_1_IP}
	SSH_ROOT_PWD=${SSH_ROOT_PWD_MASTER1}
	ssh-keyscan ${MASTER_1_IP} | sudo tee -a /root/.ssh/known_hosts
	scp -i ${SSH_KEY} ~/.ssh/master.id_rsa.pub root@${MASTER_1_IP}:~/.ssh/master.id_rsa.pub
	sleep 2
	ssh -i ${SSH_KEY}  -tt root@${MASTER_1_IP} 'cat ~/.ssh/master.id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys ; echo "PermitRootLogin yes" | sudo tee -a /etc/ssh/sshd_config ; sysctl -w vm.max_map_count=262144'
	sleep 2
	#disable firewall
  ssh -i ${SSH_KEY}  -tt root@${MASTER_1_IP} "ufw disable"
	#install docker engine
	scp -i ${SSH_KEY} ${BIN_DOWNLOAD_DIR}/${DOCKER_ENGINE_INSTALLER} root@${MASTER_1_IP}:/tmp/${DOCKER_ENGINE_INSTALLER}
	ssh -i ${SSH_KEY}  -tt root@${MASTER_1_IP} "/tmp/${DOCKER_ENGINE_INSTALLER} --install"
	#temporary os fix
	#ssh -i ${SSH_KEY}  -tt root@${MASTER_1_IP} 'sed -i.bak "/kernel.sched_compat_yield/d" /etc/sysctl.conf'
fi

if [[ ! -z ${MASTER_2_IP+x} ]]; then
	echo "Copy SSH key to Master Node 2"
	echo ${MASTER_2_IP}
	ssh-keyscan ${MASTER_2_IP} | sudo tee -a /root/.ssh/known_hosts
	scp -i ${SSH_KEY} ~/.ssh/master.id_rsa.pub root@${MASTER_2_IP}:~/.ssh/master.id_rsa.pub
	sleep 2
	ssh -i ${SSH_KEY}  -tt root@${MASTER_2_IP} 'cat ~/.ssh/master.id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys ; echo "PermitRootLogin yes" | sudo tee -a /etc/ssh/sshd_config ; sysctl -w vm.max_map_count=262144'
	sleep 2
        #disable firewall
  ssh -i ${SSH_KEY}  -tt root@${MASTER_2_IP} "ufw disable"
        #install docker engine
	scp -i ${SSH_KEY} ${BIN_DOWNLOAD_DIR}/${DOCKER_ENGINE_INSTALLER} root@${MASTER_2_IP}:/tmp/${DOCKER_ENGINE_INSTALLER}
  ssh -i ${SSH_KEY}  -tt root@${MASTER_2_IP} "/tmp/${DOCKER_ENGINE_INSTALLER} --install"
	#temporary os fix
	#ssh -i ${SSH_KEY}  -tt root@${MASTER_2_IP} 'sed -i.bak "/kernel.sched_compat_yield/d" /etc/sysctl.conf'
fi

if [[ ! -z ${MASTER_3_IP+x} ]]; then
	echo "Copy SSH key to Master Node 3"
	echo ${MASTER_3_IP}
	ssh-keyscan ${MASTER_3_IP} | sudo tee -a /root/.ssh/known_hosts
	scp -i ${SSH_KEY} ~/.ssh/master.id_rsa.pub root@${MASTER_3_IP}:~/.ssh/master.id_rsa.pub
	sleep 2
	ssh -i ${SSH_KEY}  -tt root@${MASTER_3_IP} 'cat ~/.ssh/master.id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys ; echo "PermitRootLogin yes" | sudo tee -a /etc/ssh/sshd_config ; sysctl -w vm.max_map_count=262144'
	sleep 2
  #disable firewall
  ssh -i ${SSH_KEY}  -tt root@${MASTER_3_IP} "ufw disable"
  #install docker engine
  scp -i ${SSH_KEY} ${BIN_DOWNLOAD_DIR}/${DOCKER_ENGINE_INSTALLER} root@${MASTER_3_IP}:/tmp/${DOCKER_ENGINE_INSTALLER}
  ssh -i ${SSH_KEY}  -tt root@${MASTER_3_IP} "/tmp/${DOCKER_ENGINE_INSTALLER} --install"
	#temporary os fix
	#ssh -i ${SSH_KEY}  -tt root@${MASTER_3_IP} 'sed -i.bak "/kernel.sched_compat_yield/d" /etc/sysctl.conf'
fi

if [[ ! -z ${MANAGEMENT_1_IP+x} ]]; then
	echo "Copy SSH key to Management Node 1"
	echo ${MANAGEMENT_1_IP}
	SSH_ROOT_PWD=${SSH_ROOT_PWD_MGMT1}
	ssh-keyscan ${MANAGEMENT_1_IP} | sudo tee -a /root/.ssh/known_hosts
	scp -i ${SSH_KEY} ~/.ssh/master.id_rsa.pub root@${MANAGEMENT_1_IP}:~/.ssh/master.id_rsa.pub
	sleep 2
	ssh -i ${SSH_KEY}  -tt root@${MANAGEMENT_1_IP} 'cat ~/.ssh/master.id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys ; echo "PermitRootLogin yes" | sudo tee -a /etc/ssh/sshd_config ; sysctl -w vm.max_map_count=262144'
	sleep 2
  #disable firewall
  ssh -i ${SSH_KEY}  -tt root@${MANAGEMENT_1_IP} "ufw disable"
  #install docker engine
  scp -i ${SSH_KEY} ${BIN_DOWNLOAD_DIR}/${DOCKER_ENGINE_INSTALLER} root@${MANAGEMENT_1_IP}:/tmp/${DOCKER_ENGINE_INSTALLER}
  ssh -i ${SSH_KEY}  -tt root@${MANAGEMENT_1_IP} "/tmp/${DOCKER_ENGINE_INSTALLER} --install"
	#temporary os fix
	#ssh -i ${SSH_KEY}  -tt root@${MANAGEMENT_1_IP} 'sed -i.bak "/kernel.sched_compat_yield/d" /etc/sysctl.conf'
fi

if [[ ! -z ${VA_1_IP+x} ]]; then
  echo "Copy SSH key to Management Node 1"
  echo ${VA_1_IP}
  SSH_ROOT_PWD=${SSH_ROOT_PWD_VA1}
  ssh-keyscan ${VA_1_IP} | sudo tee -a /root/.ssh/known_hosts
  scp -i ${SSH_KEY} ~/.ssh/master.id_rsa.pub root@${VA_1_IP}:~/.ssh/master.id_rsa.pub
  sleep 2
  ssh -i ${SSH_KEY}  -tt root@${VA_1_IP} 'cat ~/.ssh/master.id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys ; echo "PermitRootLogin yes" | sudo tee -a /etc/ssh/sshd_config ; sysctl -w vm.max_map_count=262144'
  sleep 2
  #disable firewall
  ssh -i ${SSH_KEY}  -tt root@${VA_1_IP} "ufw disable"
  #install docker engine
  scp -i ${SSH_KEY} ${BIN_DOWNLOAD_DIR}/${DOCKER_ENGINE_INSTALLER} root@${VA_1_IP}:/tmp/${DOCKER_ENGINE_INSTALLER}
  ssh -i ${SSH_KEY}  -tt root@${VA_1_IP} "/tmp/${DOCKER_ENGINE_INSTALLER} --install"
  #temporary os fix
  #ssh -i ${SSH_KEY}  -tt root@${VA_1_IP} 'sed -i.bak "/kernel.sched_compat_yield/d" /etc/sysctl.conf'
fi

if [[ ! -z ${PROXY_1_IP+x} ]]; then
	echo "Copy SSH key to Proxy Node 1"
	echo ${PROXY_1_IP}
	SSH_ROOT_PWD=${SSH_ROOT_PWD_PROXY1}
	ssh-keyscan ${PROXY_1_IP} | sudo tee -a /root/.ssh/known_hosts
	scp -i ${SSH_KEY} ~/.ssh/master.id_rsa.pub root@${PROXY_1_IP}:~/.ssh/master.id_rsa.pub
	sleep 2
	ssh -i ${SSH_KEY}  -tt root@${PROXY_1_IP} 'cat ~/.ssh/master.id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys ; echo "PermitRootLogin yes" | sudo tee -a /etc/ssh/sshd_config ; sysctl -w vm.max_map_count=262144'
	sleep 2
  #disable firewall
  ssh -i ${SSH_KEY}  -tt root@${PROXY_1_IP} "ufw disable"
  #install docker engine
  scp -i ${SSH_KEY} ${BIN_DOWNLOAD_DIR}/${DOCKER_ENGINE_INSTALLER} root@${PROXY_1_IP}:/tmp/${DOCKER_ENGINE_INSTALLER}
  ssh -i ${SSH_KEY}  -tt root@${PROXY_1_IP} "/tmp/${DOCKER_ENGINE_INSTALLER} --install"
	#temporary os fix
	#ssh -i ${SSH_KEY}  -tt root@${PROXY_1_IP} 'sed -i.bak "/kernel.sched_compat_yield/d" /etc/sysctl.conf'
fi

if [[ ! -z ${PROXY_2_IP+x} ]]; then
	echo "Copy SSH key to Proxy Node 2"
	echo ${PROXY_2_IP}
	ssh-keyscan ${PROXY_2_IP} | sudo tee -a /root/.ssh/known_hosts
	scp -i ${SSH_KEY} ~/.ssh/master.id_rsa.pub root@${PROXY_2_IP}:~/.ssh/master.id_rsa.pub
	sleep 2
	ssh -i ${SSH_KEY}  -tt root@${PROXY_2_IP} 'cat ~/.ssh/master.id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys ; echo "PermitRootLogin yes" | sudo tee -a /etc/ssh/sshd_config ; sysctl -w vm.max_map_count=262144'
	sleep 2
  #disable firewall
  ssh -i ${SSH_KEY}  -tt root@${PROXY_2_IP} "ufw disable"
  #install docker engine
  scp -i ${SSH_KEY} ${BIN_DOWNLOAD_DIR}/${DOCKER_ENGINE_INSTALLER} root@${PROXY_2_IP}:/tmp/${DOCKER_ENGINE_INSTALLER}
  ssh -i ${SSH_KEY}  -tt root@${PROXY_2_IP} "/tmp/${DOCKER_ENGINE_INSTALLER} --install"
	#temporary os fix
	#ssh -i ${SSH_KEY}  -tt root@${PROXY_2_IP} 'sed -i.bak "/kernel.sched_compat_yield/d" /etc/sysctl.conf'
fi

if [[ ! -z ${PROXY_3_IP+x} ]]; then
	echo "Copy SSH key to Proxy Node 3"
	echo ${PROXY_3_IP}
	ssh-keyscan ${PROXY_3_IP} | sudo tee -a /root/.ssh/known_hosts
	scp -i ${SSH_KEY} ~/.ssh/master.id_rsa.pub root@${PROXY_3_IP}:~/.ssh/master.id_rsa.pub
	sleep 2
	ssh -i ${SSH_KEY}  -tt root@${PROXY_3_IP} 'cat ~/.ssh/master.id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys ; echo "PermitRootLogin yes" | sudo tee -a /etc/ssh/sshd_config ; sysctl -w vm.max_map_count=262144'
	sleep 2
  #disable firewall
  ssh -i ${SSH_KEY}  -tt root@${PROXY_3_IP} "ufw disable"
  #install docker engine
  scp -i ${SSH_KEY} ${BIN_DOWNLOAD_DIR}/${DOCKER_ENGINE_INSTALLER} root@${PROXY_3_IP}:/tmp/${DOCKER_ENGINE_INSTALLER}
  ssh -i ${SSH_KEY}  -tt root@${PROXY_3_IP} "/tmp/${DOCKER_ENGINE_INSTALLER} --install"
	#temporary os fix
	#ssh -i ${SSH_KEY}  -tt root@${PROXY_3_IP} 'sed -i.bak "/kernel.sched_compat_yield/d" /etc/sysctl.conf'
fi

if [[ ! -z ${WORKER_1_IP+x} ]]; then
	echo "Copy SSH key to Worker Node 1"
	echo ${WORKER_1_IP}
	SSH_ROOT_PWD=${SSH_ROOT_PWD_WORKER1}
	ssh-keyscan ${WORKER_1_IP} | sudo tee -a /root/.ssh/known_hosts
	scp -i ${SSH_KEY} ~/.ssh/master.id_rsa.pub root@${WORKER_1_IP}:~/.ssh/master.id_rsa.pub
	sleep 2
	ssh -i ${SSH_KEY}  -tt root@${WORKER_1_IP} 'cat ~/.ssh/master.id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys ; echo "PermitRootLogin yes" | sudo tee -a /etc/ssh/sshd_config ; sysctl -w vm.max_map_count=262144'
	sleep 2
  #disable firewall
  ssh -i ${SSH_KEY}  -tt root@${WORKER_1_IP} "ufw disable"
  #install docker engine
  scp -i ${SSH_KEY} ${BIN_DOWNLOAD_DIR}/${DOCKER_ENGINE_INSTALLER} root@${WORKER_1_IP}:/tmp/${DOCKER_ENGINE_INSTALLER}
  ssh -i ${SSH_KEY}  -tt root@${WORKER_1_IP} "/tmp/${DOCKER_ENGINE_INSTALLER} --install"
	#temporary os fix
	#ssh -i ${SSH_KEY}  -tt root@${WORKER_1_IP} 'sed -i.bak "/kernel.sched_compat_yield/d" /etc/sysctl.conf'
fi

if [[ ! -z ${WORKER_2_IP+x} ]]; then
	echo "Copy SSH key to Worker Node 2"
	echo ${WORKER_2_IP}
	SSH_ROOT_PWD=${SSH_ROOT_PWD_WORKER2}
	ssh-keyscan ${WORKER_2_IP} | sudo tee -a /root/.ssh/known_hosts
	scp -i ${SSH_KEY} ~/.ssh/master.id_rsa.pub root@${WORKER_2_IP}:~/.ssh/master.id_rsa.pub
	sleep 2
	ssh -i ${SSH_KEY}  -tt root@${WORKER_2_IP} 'cat ~/.ssh/master.id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys ; echo "PermitRootLogin yes" | sudo tee -a /etc/ssh/sshd_config ; sysctl -w vm.max_map_count=262144'
	sleep 2
  #disable firewall
  ssh -i ${SSH_KEY}  -tt root@${WORKER_2_IP} "ufw disable"
  #install docker engine
  scp -i ${SSH_KEY} ${BIN_DOWNLOAD_DIR}/${DOCKER_ENGINE_INSTALLER} root@${WORKER_2_IP}:/tmp/${DOCKER_ENGINE_INSTALLER}
  ssh -i ${SSH_KEY}  -tt root@${WORKER_2_IP} "/tmp/${DOCKER_ENGINE_INSTALLER} --install"
	#temporary os fix
	#ssh -i ${SSH_KEY}  -tt root@${WORKER_2_IP} 'sed -i.bak "/kernel.sched_compat_yield/d" /etc/sysctl.conf'
fi

if [[ ! -z ${WORKER_3_IP+x} ]]; then
	echo "Copy SSH key to Worker Node 3"
	echo ${WORKER_3_IP}
	ssh-keyscan ${WORKER_3_IP} | sudo tee -a /root/.ssh/known_hosts
	scp -i ${SSH_KEY} ~/.ssh/master.id_rsa.pub root@${WORKER_3_IP}:~/.ssh/master.id_rsa.pub
	sleep 2
	ssh -i ${SSH_KEY}  -tt root@${WORKER_3_IP} 'cat ~/.ssh/master.id_rsa.pub | sudo tee -a /root/.ssh/authorized_keys ; echo "PermitRootLogin yes" | sudo tee -a /etc/ssh/sshd_config ; sysctl -w vm.max_map_count=262144'
	sleep 2
  #disable firewall
  ssh -i ${SSH_KEY}  -tt root@${WORKER_3_IP} "ufw disable"
  #install docker engine
  scp -i ${SSH_KEY} ${BIN_DOWNLOAD_DIR}/${DOCKER_ENGINE_INSTALLER} root@${WORKER_3_IP}:/tmp/${DOCKER_ENGINE_INSTALLER}
  ssh -i ${SSH_KEY}  -tt root@${WORKER_3_IP} "/tmp/${DOCKER_ENGINE_INSTALLER} --install"
	#temporary os fix
	#ssh -i ${SSH_KEY}  -tt root@${WORKER_3_IP} 'sed -i.bak "/kernel.sched_compat_yield/d" /etc/sysctl.conf'
fi


#step 8 - modify hosts
tee ${INSTALL_DIR}/cluster/hosts <<-EOF
[master]
${MASTER_1_IP}
${MASTER_2_IP}
${MASTER_3_IP}

[worker]
${WORKER_1_IP}
${WORKER_2_IP}
${WORKER_3_IP}

[proxy]
${PROXY_1_IP}
${PROXY_2_IP}
${PROXY_3_IP}

EOF

#step 9 - Setting up SSH Key
cp ~/.ssh/master.id_rsa ${INSTALL_DIR}/cluster/ssh_key
chmod 400 ${INSTALL_DIR}/cluster/ssh_key

#step 10 & 11 - modify config.yaml

#remove default password
sed -i 's/default_admin_password: admin/\#default_admin_password: admin/g' ${INSTALL_DIR}/cluster/config.yaml

tee -a ${INSTALL_DIR}/cluster/config.yaml <<-EOF

	#replace api server port to avoid conflict with Pure mgmt port
	kube_apiserver_insecure_port: 18888
	cluster_name: ${ICP_CLUSTER_NAME}
	default_admin_password: ${ICP_ADMIN_PWD}

	#IP over IP mode
	calico_ipip_enabled: ${CALICO_IPIP_ENABLED}

EOF

# source the properties:
if [[ -e "/etc/db2vip.conf" ]]; then
	. /etc/db2vip.conf
	tee -a ${INSTALL_DIR}/cluster/config.yaml <<-EOF

		#HA settings
		vip_iface: eth0
		cluster_vip: ${VIP_CLUSTER}

		# Proxy settings
		proxy_vip_iface: eth0
		proxy_vip: ${VIP_PROXY}

	EOF
fi



if $MGMT_SERVICES_ENABLED; then

	#add management node if specified

	if [[ ! -z ${MANAGEMENT_1_IP+x} ]]; then
		tee -a ${INSTALL_DIR}/cluster/hosts <<-EOF
		[management]
		${MANAGEMENT_1_IP}

		EOF
	fi

	# monitoring
	tee -a ${INSTALL_DIR}/cluster/config.yaml <<-EOF
		monitoring:
		 storageClass: "-"
		 pvPath: /opt/ibm/cfc/monitoring
		 prometheus:
		   alert_rules:
		     sample.rules: ""
		   extraArgs:
		     storage.local.retention: 24h
		     storage.local.memory-chunks: 500000
		 grafana:
		   user: admin
		   password: ${ICP_ADMIN_PWD}
		 alertmanager:
		   config:
		     alertmanager.yml: |-
		       global:
		       receivers:
		         - name: default-receiver
		       route:
		         group_wait: 10s
		         group_interval: 5m
		         receiver: default-receiver
		         repeat_interval: 3h
	EOF

	# logging
	tee -a ${INSTALL_DIR}/cluster/config.yaml <<-EOF
		#enable logging feature
		kibana_install: true
	EOF

	# vulnerability advisor
	if [[ ! -z ${VA_1_IP+x} ]]; then
		#remove default config
		sed -i 's/disabled_management_services: ["va"]/\#disabled_management_services: ["va"]/g' ${INSTALL_DIR}/cluster/config.yaml
		tee -a ${INSTALL_DIR}/cluster/config.yaml <<-EOF
			disabled_management_services: [""]
			va_api_server_nodePort: 30610
			va_crawler_enabled: true
		EOF
		#adding VA host to hosts file
		tee -a ${INSTALL_DIR}/cluster/hosts <<-EOF
			[va]
			${VA_1_IP}
		EOF
	fi
else
	sed -i 's/disabled_management_services: \["va"\]//g' ${INSTALL_DIR}/cluster/config.yaml
	tee -a ${INSTALL_DIR}/cluster/config.yaml <<-EOF
		disabled_management_services: ["service-catalog", "metering", "monitoring", "va"]
	EOF
fi


#step 12-17 optional
#step 17
mkdir -p ${INSTALL_DIR}/cluster/images
mv ${BIN_DOWNLOAD_DIR}/${INSTALLER_FILENAME} ${INSTALL_DIR}/cluster/images/

#step 18 optional

#step 19 & 20 - install
cd ${INSTALL_DIR}/cluster && docker run --net=host -t -e LICENSE=accept -v $(pwd):/installer/cluster ${IMAGE_NAME} install
