# AWS

As of this writing, we support two types of AWS deployments with Cluster API (CAPI):

- A "standard" cluster with HA control plane and a machine deployment for workers.
- An "autoscaling-workers" cluster that uses autoscaling groups for the worker set (they are called "MachinePools" in Cluster API lingo).

Currently supported versions:

- Talos: v0.10+ (see releases in this repository for previous versions).
- cluster-api-provider-aws (CAPI): [v0.6.4](https://github.com/kubernetes-sigs/cluster-api-provider-aws/releases/tag/v0.6.4).
- cloud-provider-aws: [v1.20.0-alpha.0](https://github.com/kubernetes/cloud-provider-aws/releases/tag/v1.20.0-alpha.0).

## Assumptions and Caveats

This guide assumes that you have an existing VPC and subnet setup in your AWS environment.
Unless you have Direct Connect or some VPN to your AWS environment, VMs on this subnet should be allowed to have public IPs so that you can connect to the instances via talosctl.

## Preparation

### Cloud

- In order for the cloud-provider-aws to work properly, you should define two IAM policies in your environment: one for controlplane nodes and one for workers.
See [here](https://kubernetes.github.io/cloud-provider-aws/prerequisites/) for the defined policies that need to be created.

- Create a security group that allows port 50000 to your VMs.
This will be necessary in order to connect to these VMs via talosctl.

### Management Plane

- Install CAPI components to an existing Kubernetes cluster.
If you need a quick cluster, see [Talos docs](https://talos.dev) for an example of creating a docker-based cluster with `talosctl cluster create`.

- If you plan to use MachinePools/Autoscaling groups, export the experimental environment variable so that it gets enabled:
```bash
export EXP_MACHINE_POOL=true
```

- Export the path to your AWS credentials by issuing the following, updating the credentials path as necessary:
```bash
export AWS_B64ENCODED_CREDENTIALS=$(cat ~/.aws/credentials | base64 | tr -d '\n')
```

- Using Cluster API's `clusterctl` tool, initialize the management plane:
```bash
clusterctl init -b talos -c talos -i aws
```

- Unfortunately, until the v0.6.5 release of the AWS Cluster API provider, a patched version of the manager must be used.
Issue the following to patch the deployment:
```bash
kubectl patch deploy -n capa-system capa-controller-manager --type='json' -p='[{"op": "replace", "path": "/spec/template/spec/containers/0/image", "value": "docker.io/rsmitty/cluster-api-aws-controller-amd64:dev"}]'
```

## Create cluster

First, using either the [autoscaling](./autoscaling-workers/autoscaling-workers.env) or [standard](./standard/standard.env) environment file as a base, substituting information as necessary to match your AWS environment.

- Source the environment variables with `source /path/to/envfile`

- Finally, create your cluster using the proper template.

For standard:
```bash
clusterctl config cluster ${CLUSTER_NAME} --from https://github.com/talos-systems/cluster-api-templates/blob/main/aws/standard/standard.yaml | kubectl apply -f -
```

For MachinePools/Autoscaling groups:
```bash
clusterctl config cluster ${CLUSTER_NAME} --from https://github.com/talos-systems/cluster-api-templates/blob/main/aws/autoscaling-workers/autoscaling-workers.yaml | kubectl apply -f -
```

## Connecting

- Once created, you can fetch a talosconfig for the new cluster with:
```
kubectl get talosconfig \
  -l cluster.x-k8s.io/cluster-name=${CLUSTER_NAME} \
  -o yaml -o jsonpath='{.items[0].status.talosConfig}' > ${CLUSTER_NAME}.yaml
```

- With the talosconfig in hand, the kubeconfig can be fetched with:
```
talosctl --talosconfig ${CLUSTER_NAME}.yaml kubeconfig
```
