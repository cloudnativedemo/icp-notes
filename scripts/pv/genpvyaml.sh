#!/bin/bash

# ############################################################
# Script importlocalcharts.sh                                #
# Description: generate a pv yaml based on provided specs    #
# Author: Do Nguyen                                          #
# Email: nguyendo@au1.ibm.com                                #
# ############################################################

while test $# -gt 0; do
        case "$1" in
                -h|--help)
                        echo "genpvyaml - generate yaml template for persistent volume"
                        echo " "
                        echo "genpvyaml [options]"
                        echo " "
                        echo "options:"
                        echo "-h, --help                show this message"
                        echo "-c, --count=NUMBER_PV     specify the number of persistent volumes to be generated"
                        echo "-o, --output-dir=DIR      specify a directory for output"
                        echo "-s, --volume-size=size    specify size of the persistent volume"
                        echo "-p, --file-prefix=string  specify a prefix string for the output files [a-z][A-Z]"
                        echo "-d, --target-dir=string 	specify a directory for output files"
                        echo "-s, --nfs-server=string  	specity nfs server ip/dns"
                        echo "-r, --nfs-root-path=string  specify root path for nfs"
                        exit 0
                        ;;
                -c)
                        shift
                        if test $# -gt 0; then
                                export PV_COUNT=$1
                        else
                                echo "no number of volumes specified"
                                exit 1
                        fi
                        shift
                        ;;
                --count*)
                        export PV_COUNT=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                -o)
                        shift
                        if test $# -gt 0; then
                                export OUTPUT=$1
                        else
                                echo "no output dir specified"
                                exit 1
                        fi
                        shift
                        ;;
                --output-dir*)
                        export OUTPUT=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                -m)
                        shift
                        if test $# -gt 0; then
                                export ACCESS_MODE=$1
                        else
                                echo "no access mode dir specified"
                                exit 1
                        fi
                        shift
                        ;;
                --access-mode*)
                        export ACCESS_MODE=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                -s)
                        shift
                        if test $# -gt 0; then
                                export VOLUME_SIZE=$1
                        else
                                echo "no access mode dir specified"
                                exit 1
                        fi
                        shift
                        ;;
                --volume-size*)
                        export VOLUME_SIZE=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                -p)
                        shift
                        if test $# -gt 0; then
                                export FILE_PREFIX=$1
                        else
                                echo "no pv prefix specified"
                                exit 1
                        fi
                        shift
                        ;;
                --file-prefix*)
                        export FILE_PREFIX=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                -s)
                        shift
                        if test $# -gt 0; then
                                export NFS_SERVER=$1
                        else
                                echo "no nfs server specified"
                                exit 1
                        fi
                        shift
                        ;;
                --nfs-server*)
                        export NFS_SERVER=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                -r)
                        shift
                        if test $# -gt 0; then
                                export NFS_ROOT=$1
                        else
                                echo "no nfs root path specified"
                                exit 1
                        fi
                        shift
                        ;;
                --nfs-root-path*)
                        export NFS_ROOT=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;

                *)
                        break
                        ;;
        esac
done

if [ -z "${PV_COUNT}" ] || [ -z "${OUTPUT}" ] || [ -z "${ACCESS_MODE}" ] || [ -z "${VOLUME_SIZE}" ] || [ -z "${FILE_PREFIX}" ] || [ -z "${NFS_SERVER}" ] || [ -z "${NFS_ROOT}" ]; then
	echo "genpvyaml - generate yaml template for persistent volume"
	echo " "
	echo "genpvyaml [options]"
	echo " "
	echo "options:"
	echo "-h, --help                show this message"
	echo "-c, --count=NUMBER_PV     specify the number of persistent volumes to be generated"
	echo "-o, --output-dir=DIR      specify a directory for output"
        echo "-s, --volume-size=size    specify size of the persistent volume"
        echo "-p, --file-prefix=string  specify a prefix string for the output files [a-z][A-Z]"
        echo "-s, --nfs-server=string   specity nfs server ip/dns"
        echo "-r, --nfs-root-path=string  specify root path for nfs"
	exit 1
fi

echo "Number of PV: ${PV_COUNT}"
echo "Output directory: ${OUTPUT}"
echo "Access mode: ${ACCESS_MODE}"
echo "Volume size: ${VOLUME_SIZE}"
echo "File prefix: ${FILE_PREFIX}"
echo "NFS server: ${NFS_SERVER}"
echo "NFS root path: ${NFS_ROOT}"

n=0
until [ $n -ge ${PV_COUNT} ]
do
        mkdir -p ${NFS_ROOT}/${FILE_PREFIX}/pv${n}
        #small PV
	mkdir -p ${OUTPUT}
        tee ${OUTPUT}/${FILE_PREFIX}-${n}.yaml <<-EOF
		apiVersion: v1
		kind: PersistentVolume
		metadata:
		  name: ${FILE_PREFIX}-${n}
		spec:
		  capacity:
		    storage: ${VOLUME_SIZE}
		  accessModes:
		    - ${ACCESS_MODE}
		  persistentVolumeReclaimPolicy: Recycle
		  nfs:
		    path: ${NFS_ROOT}/${FILE_PREFIX}/pv${n}
		    server: ${NFS_SERVER}
	EOF
        n=$[$n+1]

done
