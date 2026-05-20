# k3s-cluster

(description coming soon)

## Repo structure

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
│   │   └── sealed-secrets  # NO CANT BE BRRR
│   └── workloads           # argocd appset and workloads defining resources


## App of apps pattern

To make argocd fully watch and apply every manifest in the repo automatically i decided to implement the Apps of apps pattern.

It all starts with the [ root-app.yaml ](./cluster/root-app.yaml) that wraps the whole cluster directory. Every committed change in the files inside [ cluster/ ](./cluster/) gets picked up by argocd and synced. Since root-app manifest is also in the directory it also watches itself.

For example let's look at [ infra.yaml ](./cluster/infra.yaml) which watches all the files in the [ cluster/infra/ ](./cluster/infra/) directory. It contains essential resources for the cluster to function such as [traefik.yaml](./cluster/infra/traefik.yaml). If I wanted to upgrade traefik chart version I would just bump the version in the manifest file and push. ArgoCD **infra application** will then detect changes in the file and will apply the new version of traefik chart. Of course if I wanted to add another important resource I would simply create another manifest in the directory. ArgoCD will pick it up and apply automatically.   

I really like this approach since it enables me to only modify/add/remove manifests locally and when I'm ready I can just push to repo and ArgoCD will take care of the rest.
**But most importantly** my repo is the exact description of what is currently applied on the cluster and when something unexpected will occur I can always revert.

We can visualize my ArgoCD GitOps setup easily with a tree structure:

CHART

## Secrets management

I manage all my secrets with **Sealed Secrets** [(project repo)](https://github.com/bitnami-labs/sealed-secrets) to safely store them in my repo. It encrypts my secret values using a public key, which only the controller in my cluster can decrypt with it's private key.

### Implemented
- Automated secrets encryption with my own [rika](https://github.com/b-zago/rikami) CLI tool

### TODO
- Automatic secrets backup to a secure bucket
- Automate key rotation


## Deployments

*This is where the fun begins*

During my work on this infrastructure I've noticed that every application that I want to deploy is basically a combination of the following:

**HTTPRoute** -> **Service** -> **Deployment**

I got tired pretty quickly of copying same files and changing them only slightly over and over so I came up with my own way to automate that process.

### Library
I've built a Helm chart library which contains of most often used resources (such as deployments) with pre-defined labels structure. The library is built in a way that it will automatically "bind" resources that depend on each other like **Services** to corresponding **Deployments** or **HTTPRoute** to **Services** given the correct values are provided in the Helm chart.  

### Chart generation

To solve the problem of having to manually create folders and edit values files, I've also built my own CLI tool that leverages Go's template engine as my own "presets" (called "shards" in CLI) for commonly used sets of resources.

For example ***Redis.shard*** is a ready to go template that will generate correct values into the chart so that the Helm library will deploy:

- Service on port 6379 bind to redis deployment
- Deployment that runs on redis image 

You can also combine these templates together which can create application systems containing of many kind of resources.

Of course we can customize everything pretty much however we want with custom functions in the template files that are understandable by CLI.

The example above is really simplified as you can do so much more with [rika](https://github.com/b-zago/rikami). (<- to read more) 

### ArgoCD syncs

As [appset.yaml](./cluster/workloads/appset.yaml) watches for "values-*.yaml" files in the charts and when it detects a new one it automatically applies it to a corresponding namespace. (staging/prod)




