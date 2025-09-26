# renovate: depName=aws-cloud-controller-manager
AWS_CCM_VERSION := 0.0.10

# run a make update whenever the helm chart version changes
update:
	helm repo add aws-cloud-controller-manager https://kubernetes.github.io/cloud-provider-aws
	helm repo update
	helm template --version $(AWS_CCM_VERSION) aws-cloud-controller-manager aws-cloud-controller-manager/aws-cloud-controller-manager --set args="{--v=2,--cloud-provider=aws,--configure-cloud-routes=false}" > aws/manifests/ccm.yaml
