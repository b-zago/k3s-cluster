# k3s-cluster

GitOps source of truth for my k3s cluster. ArgoCD watches this repo and reconciles the cluster to match it.

## How it works

Uses the **app-of-apps** pattern. A single root Application points at [cluster/](cluster/); every manifest in that directory is itself an ArgoCD Application (or ApplicationSet) that installs the next layer.

```mermaid
graph TD
    GH[GitHub: b-zago/k3s-cluster]
    ROOT[root-app]
    INFRA[infra-app]
    CLOUD[localstack]
    AS[workloads ApplicationSet]

    CC[cluster-config]
    CM[cert-manager]
    IN[ingress-nginx]
    SS[sealed-secrets]

    ORG_P[organizer-prod]
    ORG_S[organizer-stage]
    WP_P[wp-prov-prod]
    WP_S[wp-prov-stage]
    MORE_AS[...]

    subgraph ns-prod[wp-instances-prod]
        WP1_P[wp1-prod]
        WP2_P[wp2-prod]
        MORE_P[...]
    end

    subgraph ns-stage[wp-instances-stage]
        WP1_S[wp1-stage]
        WP2_S[wp2-stage]
        MORE_S[...]
    end

    GH -->|polled by ArgoCD| ROOT
    ROOT --> INFRA
    ROOT --> CLOUD
    ROOT --> AS

    INFRA --> CC
    INFRA --> CM
    INFRA --> IN
    INFRA --> SS

    AS --> ORG_P
    AS --> ORG_S
    AS --> WP_P
    AS --> WP_S
    AS --> MORE_AS

    WP_P --> WP1_P
    WP_P --> WP2_P
    WP_P --> MORE_P

    WP_S --> WP1_S
    WP_S --> WP2_S
    WP_S --> MORE_S
```

Push to `main` → ArgoCD notices → cluster converges. All Applications have `automated.prune` and `selfHeal` enabled.

## Layout

- [cluster/root-app.yml](cluster/root-app.yml) — the root Application; bootstrap this one manifest and it pulls in everything else.
- [cluster/infra.yml](cluster/infra.yml) — wraps [cluster/infra/](cluster/infra/): cluster-config, cert-manager, ingress-nginx, and sealed-secrets.
- [cluster/localstack.yml](cluster/localstack.yml) — wraps [cluster/cloud/](cluster/cloud/): the LocalStack deployment plus its PVC and sealed auth secret.
- [cluster/workloads-appset.yml](cluster/workloads-appset.yml) — an ApplicationSet with a matrix generator that crosses every directory in [cluster/workloads/](cluster/workloads/) with `{prod, stage}`, producing one Application per `(app, env)` pair.

## Infra

- [cluster/infra/cluster-config.yml](cluster/infra/cluster-config.yml) — wraps [cluster/infra/cluster-config/](cluster/infra/cluster-config/): the Let's Encrypt `ClusterIssuer`, shared `ClusterRole`s, and the ArgoCD server Ingress.
- [cluster/infra/cert-manager.yml](cluster/infra/cert-manager.yml) — cert-manager from the Jetstack chart. Issues TLS certs for every ingress.
- [cluster/infra/ingress-nginx.yml](cluster/infra/ingress-nginx.yml) — ingress controller with SSL passthrough enabled (needed for the ArgoCD ingress).
- [cluster/infra/sealed-secrets.yml](cluster/infra/sealed-secrets.yml) — Bitnami sealed-secrets controller. Lets me commit encrypted secrets straight into this repo.

## Workloads

Each subdirectory of [cluster/workloads/](cluster/workloads/) is a Helm chart. The ApplicationSet picks `values-prod.yml` or `values-stage.yml` per environment and deploys to a namespace named `<app>-<env>`.

- [organizer](cluster/workloads/organizer/) — links organizer app (node server + Postgres).
- [ships](cluster/workloads/ships/) — ships app (node server + Redis).
- [portfolio](cluster/workloads/portfolio/) — portfolio site.
- [wp-prov](cluster/workloads/wp-prov/) — WordPress provisioner dashboard. Uses [charts/wp-chart/](charts/wp-chart/) at runtime to spin up WordPress instances on demand.

## Terraform

- [terraform/](terraform/) — defines all AWS resources emulated by LocalStack.

## CI/CD

The `images.server` fields in each workload's `values-prod.yml` / `values-stage.yml` are updated by GitHub Actions in the upstream application repos. When an app repo builds a new image, its workflow bumps the tag here and commits — ArgoCD picks up the change and rolls out the new version.

## charts/wp-chart

Not deployed by ArgoCD. It's the template the `wp-prov` dashboard uses to provision ad-hoc WordPress instances at runtime.
