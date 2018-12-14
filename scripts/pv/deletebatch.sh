#!/bin/bash

# ############################################################
# Script deletebatch.sh                                      #
# Description: kubectl delete all yamls in the provided dir  #
# Author: Do Nguyen                                          #
# Email: nguyendo@au1.ibm.com                                #
# ############################################################

while test $# -gt 0; do
        case "$1" in
                -h|--help)
                        echo "deletebatch - create kube objects match with file name in batch"
                        echo " "
                        echo "deletebatch [options]"
                        echo " "
                        echo "options:"
                        echo "-h, --help              show this message"
                        echo "-i, --input-dir=DIR     specify a directory of yaml files"
                        echo "-t, --object-type=DIR   specify a k8s object type (pv, pvc, deployment, svc, etc.)"
                        exit 0
                        ;;
                -i)
                        shift
                        if test $# -gt 0; then
                                export INPUT_DIR=$1
                        else
                                echo "no output dir specified"
                                exit 1
                        fi
                        shift
                        ;;
                --input-dir*)
                        export INPUT_DIR=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                -t)
                        shift
                        if test $# -gt 0; then
                                export OBJECT_TYPE=$1
                        else
                                echo "no object type specified"
                                exit 1
                        fi
                        shift
                        ;;
                --object-type*)
                        export OBJECT_TYPE=`echo $1 | sed -e 's/^[^=]*=//g'`
                        shift
                        ;;
                *)
                        break
                        ;;
        esac
done
me=$(echo $filename | cut -f 1 -d '.')
if [ -z "${INPUT_DIR}" ] || [ -z "${OBJECT_TYPE}" ]; then
	echo "createbatch - create kube objects in batch"
	echo " "
	echo "createbatch [options]"
	echo " "
	echo "options:"
	echo "-h, --help              show this message"
	echo "-i, --input-dir=DIR     specify a directory of yaml files"
	echo "-t, --object-type=DIR   specify a k8s object type (pv, pvc, deployment, svc, etc.)"
	exit 1
fi

for filename in ${INPUT_DIR}/*; do echo "kubectl delete $OBJECT_TYPE/$(basename ${filename} ".yaml")"&&kubectl delete $OBJECT_TYPE/$(basename ${filename} ".yaml"); done
