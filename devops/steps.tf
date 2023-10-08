locals {
  steps = {
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
    plan = {
      id         = "plan"
      entrypoint = "/bin/bash"
      args = [
        "-c",
        <<-EOT
            echo "Planning Terraform"
            export plan_name=$BRANCH_NAME
            terraform plan -input=false -out "$${tmp/plan}/$${plan_name}.tfplan" || exit 2 ;
        EOT
      ]
    }
    apply = {
      id         = "apply"
      entrypoint = "/bin/bash"
      args = [
        "-c",
        <<-EOT
            echo "Applying Terraform"
            export plan_name=$BRANCH_NAME
            terraform apply -input=false -auto-approve "$${tmp/plan}/$${plan_name}.tfplan" || exit 3 ;
        EOT
      ]
    }
  }
}
