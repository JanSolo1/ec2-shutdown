# EC2-shutdown

The EC2 instance will be turned off every off at 8PM UTC

## Env's

To provide your env's you have to follow the structure below

**Example Structure**
```
    your-project
    ├── terraform
    │   ├── app
    │   │   └── main.tf
    └── terragrunt
        ├── dev
        │   ├── app
        │   │   ├── terragrunt.hcl
        │   │   └── whatever.tfvars   <-- Here
        │   └── stage.hcl
        │
        ├── prod
        │   ├── app
        │   │   ├── terragrunt.hcl
        │   │   └── whatever.tfvars   <-- Here
        │   └── stage.hcl
        │ 
        └── root-config.hcl
```

**Terragrunt Usage**

```hcl
locals {
  inputs_from_tfvars = jsondecode(read_tfvars_file("whatever.tfvars"))
}

inputs = {
    supercoolenv = local.inputs_from_tfvars.supercoolenv
}
```

**.tfvars File**
```
supercoolenv="cool"
```
