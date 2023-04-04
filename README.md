# k8s-custom-metrics

[![CodeQL](https://github.com/claick-oliveira/k8s-custom-metrics/actions/workflows/codeql.yml/badge.svg?branch=main)](https://github.com/claick-oliveira/k8s-custom-metrics/actions/workflows/codeql.yml) [![](https://github.com/jpoehnelt/in-solidarity-bot/raw/main/static//badge-flat.png)](https://github.com/apps/in-solidarity)

This repository is an example how to use custom metrics in GKE. If you want yo read more about it:

- [GKE Custom Metrics](https://cloud.google.com/kubernetes-engine/docs/tutorials/autoscaling-metrics)

Stackdriver Adapter is an implementation that uses [Custom Metrics API](https://kubernetes.io/docs/tasks/run-application/horizontal-pod-autoscale/#scaling-on-custom-metrics) and [External Metrics API](https://github.com/kubernetes/design-proposals-archive/blob/main/instrumentation/external-metrics-api.md) using [Cloud Monitoring](https://cloud.google.com/monitoring) as a backend. Its purpose is to enable pod autoscaling based on Cloud Monitoring custom metrics.

## Getting Started

These instructions will get you a copy of the project up and running on your local machine for development and testing purposes. See deployment for notes on how to deploy the project.

### Prerequisites

- git
- make
- python
- pip
- virtualenv
- vscode
- skaffold
- terraform
- docker
- minikube
- kubectl
- kubectx
- gcloud

To deloy this project you will need a Google Cloud account, [create here](https://cloud.google.com/).

#### Costs

This tutorial uses the following billable components of Google Cloud:

- [GKE](https://cloud.google.com/kubernetes-engine/pricing)
- [Pub/Sub](https://cloud.google.com/pubsub/pricing)

To generate a cost estimate based on your projected usage, use the [pricing calculator](https://cloud.google.com/products/calculator).

When you finish this tutorial, you can avoid continued billing by deleting the resources you created. For more information, see [Clean up](https://github.com/claick-oliveira/k8s-custom-metrics#clean).

### Deploying

First of all you need to clone this repository:

```bash
git clone https://github.com/claick-oliveira/k8s-custom-metrics
```

#### Infrastructure

First let's check the architecture that we will create.

#TODO: ## Add the architecture diagram

#### Terraform

Now that we know about the architecture and resources, let's create. First we need to connect our shell to the `gcloud`:

```bash
gcloud auth login
```

Now that we connected:

```bash
cd terraform
terraform apply
```

This project you need to fill some variables:

- **gcp_project_name**: The GCP project ID
- **gcp_region**: The GCP region
- **gcp_zone**: The GCP availability zone

### Running the service

First we need to connect in our GKE:

```bash
gcloud container clusters get-credentials <CLUSTER_NAME> --region <REGION> --project <PROJECT_ID>
```

To be easy and skaffold use the correct environment, let's configure `kubectx`:

Get the name of the environment:

```bash
kubectx
```

Now change the name for staging:

```bash
kubectx staging=<YOUR ENVIRONMENT>
```

Now we need to create a new namespace:

```bash
kubectl create namespace custom-metrics
```

To allow the stackdriver adapter connect on the monitoring api, wee need to create an IAM service account and give some permissions:

```bash
gcloud iam service-accounts create stackdriver-adapter-sa --project=PROJECT_ID

gcloud projects add-iam-policy-binding PROJECT_ID \
  --member "serviceAccount:stackdriver-adapter-sa@PROJECT_ID.iam.gserviceaccount.com" \
  --role "roles/monitoring.viewer"

gcloud iam service-accounts add-iam-policy-binding stackdriver-adapter-sa@PROJECT_ID.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:PROJECT_ID.svc.id.goog[custom-metrics/custom-metrics-stackdriver-adapter"
```

> Remeber to replace PROJECT_ID for your project id, example: my-project-111111
>

Now we need to create a kubernetes service account and create an annotation to link the kubernetes service account with the IAM service account:

```bash
kubectl create serviceaccount custom-metrics-stackdriver-adapter --namespace custom-metrics

kubectl annotate serviceaccount custom-metrics-stackdriver-adapter \
  --namespace custom-metrics \
  iam.gke.io/gcp-service-account=stackdriver-adapter-sa@PROJECT_ID.iam.gserviceaccount.com
```

> Remeber to replace PROJECT_ID for your project id, example: my-project-111111
>

Now we will deploy the stackdriver adapter:

```bash
kubectl apply -f https://raw.githubusercontent.com/GoogleCloudPlatform/k8s-stackdriver/master/custom-metrics-stackdriver-adapter/deploy/production/adapter_new_resource_model.yaml
```

Ok nice! So, now wee need to create a IAM service account and kubernetes service account to our applications:

```bash
gcloud iam service-accounts create pubsub-sa --project=PROJECT_ID

gcloud projects add-iam-policy-binding PROJECT_ID \
    --member "serviceAccount:pubsub-sa@PROJECT_ID.iam.gserviceaccount.com" \
    --role "roles/pubsub.subscriber" \
    --role "roles/pubsub.publisher"

gcloud iam service-accounts add-iam-policy-binding pubsub-sa@PROJECT_ID.iam.gserviceaccount.com \
    --role roles/iam.workloadIdentityUser \
    --member "serviceAccount:PROJECT_ID.svc.id.goog[custom-metrics/pubsub-sa]"

kubectl create serviceaccount pubsub-sa --namespace custom-metrics

kubectl annotate serviceaccount pubsub-sa \
    --namespace custom-metrics \
    iam.gke.io/gcp-service-account=pubsub-sa@PROJECT_ID.iam.gserviceaccount.com
```

> Remeber to replace PROJECT_ID for your project id, example: my-project-111111
>

Nice, we finished the setup.

### Test the Setup

To test the setup we will create a deployment:

```bash
kubectl apply -f ./kubernetes/wi-test.yaml
```

> Remeber to be in the root path of the project
>

Now let's connect in this pod and check if the setup it's working:

```bash
kubectl exec -it workload-identity-test \
  -c workload-identity-test \
  --namespace custom-metrics \
  -- /bin/bash
```

Now execute this command:

```bash
curl -H "Metadata-Flavor: Google" http://169.254.169.254/computeMetadata/v1/instance/service-accounts/default/email
```

If the service accounts are correctly configured, the IAM service account email address is listed as the active (and only) identity. This demonstrates that by default, the Pod acts as the IAM service account's authority when calling Google Cloud APIs.

Now you can exit the container and delete the deployment:

```bash
exit

kubectl delete -f ./kubernetes/wi-test.yaml
```

To run the applications you need to execute, but you need to be in the root folder:

```bash
skaffold run --default-repo us-central1-docker.pkg.dev/<PROJECT_ID>/custom-metrics
```

> Before you run this command remeber to create a file deployment.yaml based on the file deployment.yaml.template
> In this file you need to replace the variable <PROJECT_ID> to your project id
>

### The HPA

Now the application publisher will send messages to the Pub/Sub Topic and the application subscriber will read the messages. But the publisher is faster then the publisher and the messages will increse fast. Wait some minutes and create the HPA to increase the number of subscribers:

```bash
kubectl apply -f kubernetes/subscriber-hpa.yaml
```

And reduce to 0 the number of publishers:

```bash
kubectl scale deploy -n custom-metrics --replicas=0 publisher
```

If you want to check how many subscribers do you have:

```bash
kubectl get deployment subscriber --namespace custom-metrics
```

### And coding style tests

In this project we'll use [PEP 8](https://www.python.org/dev/peps/pep-0008/) as style guide.

## Clean

To clean the files generated as coverage, builds, env you can use:

``` bash
make cleanfull
skaffold delete
```

To clean the infrastructure:

```bash
cd terraform
terraform destroy
```

## Contributing

Please read [CONTRIBUTING.md](https://github.com/claick-oliveira/k8s-custom-metrics/blob/main/CONTRIBUTING.md) for details on our code of conduct, and the process for submitting pull requests to us.

## Authors

- **Claick Oliveira** - *Initial work* - [claick-oliveira](https://github.com/claick-oliveira)

See also the list of [contributors](https://github.com/claick-oliveira/k8s-custom-metrics/contributors) who participated in this project.

## License

This project is licensed under the GNU General Public License - see the [LICENSE](LICENSE) file for details
