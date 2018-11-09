# Prepare ICP for microclimate deployment
Refer [here](https://github.com/IBM/charts/tree/master/stable/ibm-microclimate) for full instructions

__1. Create pipeline deployment namespace__
```
kubectl create namespace microclimate-pipeline-deployments
```

__2. Edit ClusterImagePolicy__
```
kubectl edit clusterimagepolicies ibmcloud-default-cluster-image-policy

```
> To add the following:
```
  - name: mycluster.icp:8500:*
  - name: docker.io/maven:*
  - name: docker.io/lachlanevenson/k8s-helm:*
  - name: docker.io/jenkins/*
```

__3. Create Docker Registry secret to microclimate namespace__
```
kubectl create secret docker-registry microclimate-registry-secret \
  --docker-server=mycluster.icp:8500 \
  --docker-username=admin \
  --docker-password=admin \
  --docker-email=null
```

__4. Initialise Helm and login__
```
helm init --client-only --skip-refresh
cloudctl login -a https://mycluster.icp:8443 -u admin -p admin -c id-mycluster-account -n default --skip-ssl-validation
```

__5. Create Helm secret__
```
export HELM_HOME=$HOME/.helm
kubectl create secret generic microclimate-helm-secret --from-file=cert.pem=$HELM_HOME/cert.pem --from-file=ca.pem=$HELM_HOME/ca.pem --from-file=key.pem=$HELM_HOME/key.pem
```

__6. Create Docker Registry secret for `microclimate-pipeline-deployments` namespace__
```
kubectl create secret docker-registry microclimate-pipeline-secret \
  --docker-server=mycluster.icp:8500 \
  --docker-username=admin \
  --docker-password=admin \
  --docker-email=null \
  --namespace=microclimate-pipeline-deployments
```

__7. Update ImagePullSecret for `microclimate-pipeline-deployments` namespace__
```
kubectl patch serviceaccount default --namespace microclimate-pipeline-deployments -p '{"imagePullSecrets": [{"name": "microclimate-pipeline-secret"}]}'
```

__8. Add ibm-charts Helm repo__
```
helm repo add ibm-charts https://raw.githubusercontent.com/IBM/charts/master/repo/stable/
```

__9. Deploy microclimate Helm chart__
```
helm install --name microclimate --namespace default --set global.rbac.serviceAccountName=micro-sa,jenkins.rbac.serviceAccountName=pipeline-sa,hostName=microclimate.172.23.52.247.nip.io,jenkins.Master.HostName=jenkins.172.23.52.247.nip.io ibm-charts/ibm-microclimate --tls
```

