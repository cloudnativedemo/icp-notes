# Loading IBM helm charts to local ICP repository

__Step 1__ - Git clone the repo into your temp folder

`git clone https://github.com/IBM/charts.git`

All the chart packages are located in `charts/repo/stable`

__Step 2__ - Login to ICP cluster

```shell
cloudctl login  -a https://mycluster.icp:8443 --skip-ssl-validation
```

__Step 3__ - Bulk import helm chart archives into ICP's local repository using [importlocalcharts.sh](scripts/importlocalcharts.sh)

```shell
./importlocalcharts.sh --input-dir=charts/repo/stable
```

__Step 4__ - Verify the imported helm charts from the ICP console/catalog
