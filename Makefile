
.PHONY: apply
apply:
	bash -c "source ./scripts/setup.sh && apply"

.PHONY: force_apply
force-apply:
	bash -c "source ./scripts/setup.sh && force_apply"

.PHONY: destroy
destroy:
	bash -c "source ./scripts/setup.sh && destroy"

.PHONY: terraform_output
terraform_output:
	bash -c "source ./scripts/setup.sh && terraform_output"

.PHONY: vault_root_token
vault_root_token:
	bash -c "source ./scripts/setup.sh && vault_root_token"

.PHONY: vault_init
vault_init:
	bash -c "source ./scripts/setup.sh && vault_init"

.PHONY: register_vault_worker
register_vault_worker:
	bash -c "source ./scripts/setup.sh && vault_worker_token"

.PHONY: vault_connect
vault_connect:
	bash -c "source ./scripts/setup.sh && vault_connect"

.PHONY: register_target_workers
register_target_workers:
	bash -c "source ./scripts/setup.sh && host_worker_tokens"

# optional call to create aws host catalog via make. This is performed via
# Terraform or manually in the tutorial

.PHONY: dhc
dhc:
	bash -c "source ./scripts/setup.sh && dynamic_host_catalog PROJECT_ID=\"${PROJECT_ID}\""
