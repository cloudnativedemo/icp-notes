# Customise Microclimate to make it work with MQ projects (and others)
## Prepare ICP for microclimate deployment
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

__8. Customise Jenkins library__
By default, the Jenkins library parameter is pointing to https://github.com/microclimate-dev2ops/jenkins-library
This Jenkins library was a part of the Microclimate DevOps process. When a pipeline is created within a project in Microclimate, microclimate will create a Jenkins pipeline. The pipeline uses this library to
.. 1. Pull the code from github repo . 
.. 2. Build a Docker image based on a Dockerfile found in the repo . 
.. 3. Authenticate and push the image into ICP's private registry . 
.. 4. Notify Microclimate to move to the next stage (e.g. deploy) . 
.. 5. Microclimate 'helm deploy' the helm chart found in the repo (by default it's under the /chart directory) . 

Unfortunately, Microclimate only deploy it's supported project types e.g. Swift, NodeJS, Java/Liberty or Springboot. The easiest way to address this limitation is to fork and update the Jenkins library and inject the 'helm deploy' scriptlet onto step 4 (line 400 of microserviceBuilderPipeline.groovy)

```groovy
            container ('helm') {
            echo "Attempting to deploy the test release"
            def deployCommand = "helm install ${realChartFolder} --values pipeline.yaml --namespace ${namespace} --name ${helmRelease}"
            if (fileExists("chart/overrides.yaml")) {
              deployCommand += " --values chart/overrides.yaml"
            }
            if (helmSecret) {
              echo "Adding --tls to your deploy command"
              deployCommand += helmTlsOptions
            }
            testDeployAttempt = sh(script: "${deployCommand} > deploy_attempt.txt", returnStatus: true)
            if (testDeployAttempt != 0) {
              echo "Warning, did not deploy the test release into the test namespace successfully, error code is: ${testDeployAttempt}" 
              echo "This build will be marked as a failure: halting after the deletion of the test namespace."
            }
            printFromFile("deploy_attempt.txt")
         }
```

* ___Note:___ in my deployCommand, I've created one new variable `${helmRelease}`. The variable is defined on the top of the script (line 56 of the microserviceBuilderPipeline.groovy). Alternatively, you can just reuse `${image}` as your helm release name . 
```groovy
  def helmRelease = (config.releaseName ?: config.image ?: "").trim()
```

* My forked updated Jenkins library repo can be found [here](https://github.com/cloudnativedemo/jenkins-library) . 

__8. Deploy Microclimate helm chart__

>__Via Helm command line__ . 
* __Add ibm-charts Helm repo__
```
helm repo add ibm-charts https://raw.githubusercontent.com/IBM/charts/master/repo/stable/
```

* __Deploy microclimate Helm chart__
```
helm install --name microclimate --namespace default --set global.rbac.serviceAccountName=micro-sa,jenkins.rbac.serviceAccountName=pipeline-sa,hostName=microclimate.172.23.52.247.nip.io,jenkins.Master.HostName=jenkins.172.23.52.247.nip.io,jenkins.Pipeline.Template.RepositoryUrl=https://github.com/cloudnativedemo/jenkins-library.git,jenkins.Pipeline.Template.Version=master ibm-charts/ibm-microclimate --tls
```
___Note:___ Replace <172.23.52.247> with your <PROXY_IP>

>__Via ICP catalog__ . 
* Select ibm-microclimate from ICP catalog > click `Configure` . 
* Provide values for the following parameters:  
.. * `Helm release name`: your-microclimate-release-name . 
.. * `Namespace`: default (or your preferred namespace) . 
.. * `Microclimate hostname`: microclimate.172.23.52.247.nip.io (replace with your <microclimate.PROXY_IP.nip.io> or your own hostname) . 
.. * Ensure that you've already created Persistent Volumes for Microclimate and Jenkins . 
.. * `Service account name for Portal`: micro-sa . 
.. * `Jenkins library repository`: https://github.com/cloudnativedemo/jenkins-library.git . 
.. * `Jenkins hostname`: jenkins.172.23.52.247.nip.io (replace with your <jenkins.PROXY_IP.nip.io> or your own hostname) . 
.. * `Service account name`: pipeline-sa . 
.. * Click `deploy` . 
