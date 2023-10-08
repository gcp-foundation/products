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
          echo "Initialising Terraform"
          terraform init || exit 1 ;
        EOT
      ]
    }
    apply = {
      id         = "apply"
      entrypoint = "/bin/bash"
      args = [
        "-c",
        <<-EOT
          echo "Initialising Terraform"
          terraform init || exit 1 ;
        EOT
      ]
    }
  }
}
