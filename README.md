# Enable HCP Boundary session recordings with AWS

## Summary:

This repo contains Terraform resources for deploying a test environment for enabling session recording and credential injection using Vault, and is designed to be deployed against an HCP Boundary Plus cluster. The cloud infrastructure is deployed in aws using terraform. An aws instance is created and hosts both a vault and boundary worker service. Additional hosts are deployed for use by the dynamic host catalog plugin, which also host the boundary worker service.

The lab environment is designed to accompany the Hashicorp Boundary tutorial [Enable session recording with AWS and Vault](https://developer.hashicorp.com/boundary/tutorials/enterprise/aws-session-rec-vault).

### Dependencies

- [jq](https://stedolan.github.io/jq/download/)
- [make](https://www.gnu.org/software/make/) or [GnuWin32 make](https://gnuwin32.sourceforge.net/packages/make.htm)
- [terraform](https://developer.hashicorp.com/terraform/tutorials/aws-get-started/install-cli)

### AWS Access

An AWS account is required with create access for the following services:
  - Amazon EC2
  - AWS IAM
  - Amazon S3

You will need your `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY`.

> [!IMPORTANT]  
> Internal users should uncomment all lines in `infra/iam.tf` that start with `permissions_boundary`. This will allow resource creation within the `boundary_team_acctest_dev` account.

### Environment Variables:

- `AWS_REGION`: Optional. The AWS region that should be used. Defaults to `us-east-1`.
- `BOUNDARY_ADDR`: Required. The controller url from your boundary hcp instance.
- `BOUNDARY_USERNAME`: Required. The administrator username used when creating your boundary hcp instance.
- `BOUNDARY_PASSWORD`: Required. The administrator password used when creating your boundary hcp instance.
- `BOUNDARY_AUTH_METHOD_ID`: Required. The administrator auth method id used when creating your boundary hcp instance.
- `BOUNDARY_CLUSTER_ID`: Required. The boundary hcp instance id.
- `INSTANCE_COUNT`: Optional. The number of aws instances that will be spun up to test dynamic host catalogs. Defaults to 2. Minimum is 1. Maximum is 5.

### Makefile Commands:

- `apply`: This deploys a set of aws resources defined in the infra folder. Supporting the ability to test a self managed boundary worker & any version of vault. Required env variables: `BOUNDARY_CLUSTER_ID`. Optional env variables: `INSTANCE_COUNT` (determine number of aws_instances to create for testing dynamic host catalog[1,5]). Created resource names will be prefixed with the terraform workspace value, which will be derived from the whoami output.
- `force-apply`: This taints the aws_instance resource to recreate and refresh vault.
- `destroy`: This destroys the aws resources defined in the infra folder.
- `terraform_output`: This prints the outputs from `make apply`.
- `vault_connect`: This connects you to the vault instance using ssh.
- `vault_token`: This fetches the root token from the vault service and the public address of the aws_instance.
- `vault_init`: This logs in to the vault service using the root token and creates the default policies used in most boundary tutorials. It enables kv version 2 secrets and puts the aws_instance keypair under the path secret/${terraform.workspace}_ec2_ssh. Lastly, it creates a vault token that can be used to create a vault credential-store.
- `register_vault_worker`: This grabs the worker auth registration secret from the vault instance and register it to your hcp boundary cluster.
- `register_host_workers`: This grabs the worker auth registration secret from the aws host instances and register it to your hcp boundary cluster.
- `dhc`: [optional] This prints information about the aws instance ids, private ips, public ips, public dns, & tags that can be used for testing dynamic host catalogs. Required arg: `PROJECT_ID`. This will automate creating a dynamic host catalog resource with the provided project_id.

## Deployment

To deploy the lab environment:

1. Set the required environment variables:
   - `AWS_ACCESS_KEY_ID`
   - `AWS_SECRET_ACCESS_KEY`
   - `AWS_REGION`
   - `BOUNDARY_ADDR`
   - `BOUNDARY_USERNAME`
   - `BOUNDARY_PASSWORD`
   - `BOUNDARY_AUTH_METHOD_ID`
   - `BOUNDARY_CLUSTER_ID`

1. Deploy Terraform using `make`:

   ```shell
   make apply
   ```

1. Use the appropriate outputs to continue the tutorial, such as:
   - recording_bucket_name
   - recording_storage_user_access_key_id
   - recording_storage_user_secret_access_key
   - target_secret_access_key
   - target_access_key_id
   - target_instance_public_dns
   - target_instance_public_ips
   - vault_public_dns
   - vault_public_ip
   - host_key_pair_name

   View the outputs any time:

   ```shell
   make terraform_output
   ```

When you are done:
1.  Execute `make destroy` to tear down all the resources you brought up in AWS using `make apply`.

### Helpful guides:

- [SSH Credential Injection with Vault](https://developer.hashicorp.com/boundary/tutorials/credential-management/hcp-private-vault-cred-injection)
- [Self Managed Worker](https://developer.hashicorp.com/boundary/tutorials/hcp-administration/hcp-manage-workers)
- [AWS Dynamic Host Catalogs](https://developer.hashicorp.com/boundary/tutorials/host-management/aws-host-catalogs)
- [Azure Dynamic Host Catalogs](https://developer.hashicorp.com/boundary/tutorials/host-management/azure-host-catalogs)
