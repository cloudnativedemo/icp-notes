## Bulk create PV

__Step 1 - Generate Persistent Volume yaml__
```shell
. ./gensample.sh
```

__Step 2 - Login with cloudctl__
```shell
cloudctl login
```

__Step 3 - Run batch job to create PVs__
```shell
. ./createbatch.sh --input-dir=out
```
