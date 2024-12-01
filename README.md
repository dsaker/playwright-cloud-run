# playwright-python-cloud-run

This repository is a template for building a python playwright container and deploying it to Cloud Run Job. It also sets up alerts on failures. I have used it to check for a price change on a tent that I would like if it gets any cheaper.

### You will need

- [Google Cloud Account](https://cloud.google.com/gcp?utm_source=PMAX&utm_medium=display&utm_campaign=FY24-na-US-DR-pmax-1707554&utm_content=pmax&gad_source=1&gclid=Cj0KCQiAr7C6BhDRARIsAOUKifjo58qAVylj5zOaRSJI0u_EPtQ5qrQtiVxsWyArxU5147iaginiuKQaAnesEALw_wcB&gclsrc=aw.ds&hl=en)
- [GCLOUD CLI](https://cloud.google.com/sdk/docs/install)
- [Terraform CLI](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)
- [Docker](https://docs.docker.com/engine/install/)

### Create Google Cloud Repository
```
cd terraform 
terraform init
terraform apply -target=google_artifact_registry_repository.playwright_repo
```
- comment out the first resource google_artifact_registry_repository.playwright_repo
- deploy docker image to artifact repository
```
cd ..
docker build --platform linux/amd64 --push -t us-east4-docker.pkg.dev/playwright-python/playwright-python/playwright:latest .
```

### Create the Cloud Run Job and Monitoring Alert
```
cp terraform.tfvars.tmpl terraform.tfvars
```
fill in the sms_notification and email_notification variable to receive alerts
```
cd terraform
terraform apply
```

