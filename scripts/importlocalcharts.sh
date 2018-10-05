#!/bin/bash

# #################################################
# Script importlocalcharts.sh                     #
# Description: import helm charts to local repos  #
# Author: Do Nguyen                               #
# Email: nguyendo@au1.ibm.com                     #
# #################################################


while test $# -gt 0; do
        case "$1" in
                -h|--help)
                        echo "importlocalcharts.sh - import helm charts to local repos"
                        echo " "
                        echo "importlocalcharts.sh [options]"
                        echo " "
                        echo "options:"
                        echo "-h, --help              show this message"
                        echo "-, --input-dir=DIR      specify a directory of yaml files"
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
                *)
                        break
                        ;;
        esac
done

if [ -z "${INPUT_DIR}" ]; then
	echo "importlocalcharts.sh - import helm charts to local repos"
	echo " "
	echo "importlocalcharts.sh [options]"
	echo " "
	echo "options:"
	echo "-h, --help              show this message"
	echo "-, --input-dir=DIR      specify a directory of yaml files"
	exit 1
fi

for filename in ${INPUT_DIR}/*; do cloudctl catalog load-chart --archive ${filename} --repo local-charts; done
