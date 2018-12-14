## Bulk create PV

__Step 1 - Edit `gensample.sh` to update the environment variables
```
NFS_SERVER=<NFS Server IP>
PV_ROOT=/nfsvol/pv
YAML_OUTDIR=$(pwd)/out
```
__Step 2 - Generate Persistent Volume yaml__
```shell
. ./gensample.sh
```

__Step 3 - Login with cloudctl__
```shell
cloudctl login
```

__Step 4 - Run batch job to create PVs__
```shell
. ./createbatch.sh --input-dir=out
```
