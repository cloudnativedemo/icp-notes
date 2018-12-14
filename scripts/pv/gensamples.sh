#!/bin/bash

# #################################################
# Script gensamples.sh                            #
# Description: generate pv yaml                   #
# Author: Do Nguyen                               #
# Email: nguyendo@au1.ibm.com                     #
# #################################################

NFS_SERVER=172.23.50.112
PV_ROOT=/nfsvol/pv
YAML_OUTDIR=$(pwd)/out

mkdir -p ${PV_ROOT}

./genpvyaml.sh --count=5 --access-mode=ReadWriteMany --volume-size=2Gi --file-prefix=smallx --output-dir=${YAML_OUTDIR} --nfs-server=${NFS_SERVER} --nfs-root-path=${PV_ROOT}
./genpvyaml.sh --count=5 --access-mode=ReadWriteMany --volume-size=10Gi --file-prefix=mediumx --output-dir=${YAML_OUTDIR} --nfs-server=${NFS_SERVER} --nfs-root-path=${PV_ROOT}
./genpvyaml.sh --count=5 --access-mode=ReadWriteMany --volume-size=15Gi --file-prefix=largex --output-dir=${YAML_OUTDIR} --nfs-server=${NFS_SERVER} --nfs-root-path=${PV_ROOT}
./genpvyaml.sh --count=5 --access-mode=ReadWriteMany --volume-size=20Gi --file-prefix=xlargex --output-dir=${YAML_OUTDIR} --nfs-server=${NFS_SERVER} --nfs-root-path=${PV_ROOT}

./genpvyaml.sh --count=5 --access-mode=ReadWriteOnce --volume-size=2Gi --file-prefix=small1 --output-dir=${YAML_OUTDIR} --nfs-server=${NFS_SERVER} --nfs-root-path=${PV_ROOT}
./genpvyaml.sh --count=5 --access-mode=ReadWriteOnce --volume-size=10Gi --file-prefix=medium1 --output-dir=${YAML_OUTDIR} --nfs-server=${NFS_SERVER} --nfs-root-path=${PV_ROOT}
./genpvyaml.sh --count=5 --access-mode=ReadWriteOnce --volume-size=15Gi --file-prefix=large1 --output-dir=${YAML_OUTDIR} --nfs-server=${NFS_SERVER} --nfs-root-path=${PV_ROOT}
./genpvyaml.sh --count=5 --access-mode=ReadWriteOnce --volume-size=20Gi --file-prefix=xlarge1 --output-dir=${YAML_OUTDIR} --nfs-server=${NFS_SERVER} --nfs-root-path=${PV_ROOT}
