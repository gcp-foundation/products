###############################################################################
# Local variables for defining the cloudbuild step code
###############################################################################

locals {
  steps = {

    ###############################################################################
    # Terraform init step
    ###############################################################################

    init = {
      id         = "init"
      entrypoint = "/bin/bash"
      args = [
        "-c",
        <<-EOT
          echo "Initialising Terraform"
          terraform init || exit 1 ;
        EOT
      ]
    }

    ###############################################################################
    # Terraform plan step
    ###############################################################################

    plan = {
      id         = "plan"
      entrypoint = "/bin/bash"
      args = [
        "-c",
        <<-EOT
            echo "Planning Terraform"
            export plan_name=$BRANCH_NAME
            terraform plan -input=false -out "$${plan_name}.tfplan" || exit 2 ;
            gsutil cp "$${plan_name}.tfplan" "gs://${module.build_output.name}/terraform/cloudbuild/plans/$${plan_name}.tfplan" 
        EOT
      ]
    }

    ###############################################################################
    # Terraform apply step
    ###############################################################################

    apply = {
      id         = "apply"
      entrypoint = "/bin/bash"
      args = [
        "-c",
        <<-EOT
            echo "Applying Terraform"
            export plan_name=$BRANCH_NAME
            terraform apply -input=false -auto-approve "$${plan_name}.tfplan" || exit 3 ;
        EOT
      ]
    }
  }
}
