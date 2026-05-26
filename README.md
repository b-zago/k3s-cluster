# k3s-cluster

My k3s single node cluster with GitOps deployments.

- [Repo structure](#repo-structure)
- [Tech overview](#tech-overview)
- [CI/CD](#ci/cd)
- [Deployments](#deployments)
- [Secrets management](#secrets-management)
- [App of apps pattern](#app-of-apps-pattern)
- [Labels](#labels)

## Repo structure

```
├── charts
│   ├── nyanify
│   │   └── templates
│   ├── portfolio
│   │   └── templates
│   ├── ...
├── cluster
│   ├── infra               # essential resources
│   │   ├── cluster-config  # config resources
│   │   ├── monitoring      # prometheus-grafana stack
│   └── workloads           # argocd appset and workloads defining resources
```


## Tech overview

- **Traefik** as GatewayAPI and Ingress controller
- **Sealed Secrets** as secret management in repo
- **Prometheus with Grafana** as monitoring stack
- **Cert Manager** with dns-01 challange-response automatic certifications

## CI/CD

Pretty straightforward - Github Actions build the docker image with sha tag and then the tag gets updated inside values-*.yaml file in corresponding [charts/](./charts/). ArgoCD then sees the change and applies it.

I use reusable workflows and actions across my different repos. You can find them [here](https://github.com/b-zago/actions).

For more information about charts themselves see section below.

## Deployments

*This is where the fun begins*

I use my own solution for this.

In short, deployment workflow looks like this:

![diagram](./diagrams/rikami.diagram.svg)

More automatic via api:

1. Generate an application's configuration file using pre-built presets with the help of [rika] CLI that uses my custom made Go's template processor.
2. Push that generated file to [rikami-api](https://github.com/b-zago/rikami-api) repo under `resources/` directory.
3. Use just one command to generate the Helm chart from that file (that uses [rikami Helm library](https://github.com/b-zago/rikami-charts) to generate corresponding k8s manifests) and push it to this repo automatically.
4. ArgoCD picks up the new directory created inside [charts/](./charts/) directory and applies the generated manifests.

And locally:

1. Generate an application's configuration file using pre-built presets with the help of [rika] CLI that uses my custom made Go's template processor.
2. Generate the Helm chart from that configuration file that uses Helm chart library to generate corresponding k8s manifests.
3. Commit and push to this repo so that ArgoCD will pick up the new directory created inside [charts/](./charts/) and apply generated manifests. 

In both cases any secrets get sealed automatically.

I'm still working to automate this process even further by integrating it with Github Actions.

***Why?***

During my work on this infrastructure I've noticed that every application that I want to deploy is basically a combination of the following:

**HTTPRoute** -> **Service** -> **Deployment**

I got tired pretty quickly of copying same files and changing them only slightly over and over so I came up with my own way to automate that deployment process.

### Library

I've built a [Helm chart library](https://github.com/b-zago/rikami-charts) which contains most often used resources (such as deployments) with pre-defined labels structure. The library is built in a way that it will automatically "bind" resources that depend on each other like **Services** to corresponding **Deployments** or **HTTPRoute** to **Services** given the correct values are provided in the Helm chart.  

### Chart generation

To solve the problem of having to manually create folders and edit values files, I've also built my own CLI tool that leverages Go's template engine as my own "presets" (called "shards" in CLI) for commonly used sets of resources.

For example ***Redis.shard*** is a ready to go template that will generate correct values into the chart so that the Helm library will deploy:

- Service on port 6379 bind to redis deployment
- Deployment that runs on redis image 

You can also combine these templates together which can create application systems containing of many kind of resources.

Of course we can customize everything pretty much however we want with custom functions in the template files that are understandable by CLI.

The example above is really oversimplified to just get the idea across but you can do so much more with [rika](https://github.com/b-zago/rikami) to generate whatever application you want.

### ArgoCD syncs

As [appset.yaml](./cluster/workloads/appset.yaml) watches for "values-*.yaml" files in the charts and when it detects a new one it automatically applies it to a corresponding namespace. (staging/prod)

## Secrets management

I manage all my secrets with **Sealed Secrets** [(project repo)](https://github.com/bitnami-labs/sealed-secrets) to safely store them in my repo. It encrypts my secret values using a public key, which only the controller in my cluster can decrypt with it's private key.

### Implemented

- Automated secrets encryption with my own [rika](https://github.com/b-zago/rikami) CLI tool

### TODO

- Automatic secrets backup to a secure bucket
- Automate key rotation

## App of apps pattern

To make argocd fully watch and apply every manifest in the repo automatically i decided to implement the Apps of apps pattern.

It all starts with the [ root-app.yaml ](./cluster/root-app.yaml) that wraps the whole cluster directory. Every committed change in the files inside [ cluster/ ](./cluster/) gets picked up by argocd and synced. Since root-app manifest is also in the directory it also watches itself.

For example let's look at [ infra.yaml ](./cluster/infra.yaml) which watches all the files in the [ cluster/infra/ ](./cluster/infra/) directory. It contains essential resources for the cluster to function such as [traefik.yaml](./cluster/infra/traefik.yaml). If I wanted to upgrade traefik chart version I would just bump the version in the manifest file and push. ArgoCD **infra application** will then detect changes in the file and will apply the new version of traefik chart. Of course if I wanted to add another important resource I would simply create another manifest in the directory. ArgoCD will pick it up and apply automatically.   

I really like this approach since it enables me to only modify/add/remove manifests locally and when I'm ready I can just push to repo and ArgoCD will take care of the rest.
**But most importantly** my repo is the exact description of what is currently applied on the cluster and when something unexpected will occur I can always revert.

## Labels

Labels for prod/staging are entirely handled by [ rikami library chart ](https://github.com/b-zago/rikami-charts) automatically when correct values are provided.

I've chosen following labels for all of my prod/staging workloads:

- **runs-on** - describes what is being run on a resource (example for deployments/pods nginx,python,nodejs and for resources like secrets the runs-on-* (example runs-on-webserver=true) applies since they can be technically run on many different resources, however you can pass in helm regular runsOn either way.
- **part-of** - the name of a higher level application this one is part of (ex portfolio)
- **instance** - unique name to ID a resource in an application.
- **component** - the component within the architecture. This name should be pretty broad (ex server,db,cache or httroute, service)

For argocd applications and appsets:

- **part-of** - describing which app watches that application in the apps of apps tree
- **appset** - if this application was created via an appset, this will tell exactly which appset it belongs to
- **part-of** - similar to regular workloads, describes a higher level application in regards to the tree


