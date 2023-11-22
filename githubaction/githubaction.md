# strapi GitHub Actions workflow 
### create file .github/workflows/az_tga.yml
##### terraform code and strapi script available in following path: https://github.com/PearlThoughtsInternship/snipe-it.git  /strapin/
```
name: terraform apply

on:
  push:
    branches:
      - nikhil-kadam
  
  workflow_dispatch:
  
permissions:
  contents: read

env:
  ARM_CLIENT_ID: ${{ secrets.AZURE_CLIENT_ID_NK }}
  ARM_CLIENT_SECRET: ${{ secrets.AZURE_CLIENT_SECRET_NK }}
  ARM_SUBSCRIPTION_ID: ${{ secrets.AZURE_SUBSCRIPTION_ID_NK }}
  ARM_TENANT_ID: ${{ secrets.AZURE_TENANT_ID_NK }}
  ROOT_PATH: '${{ github.workspace }}/strapin'

# Use the Bash shell regardless of whether the GitHub Actions runner is ubuntu-latest
defaults:
  run:
    shell: bash

jobs:
  build:
    runs-on: self-hosted

    steps:
      - name: Check out code
        uses: actions/checkout@v2  
    
      - name: setup Terraform
        run: |
          wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
          echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
          sudo apt-get update
          sudo apt install terraform -y
        
      - name: Terraform Init
        run: |
          terraform init 
        working-directory: ${{ env.ROOT_PATH }}
      
      - name: Terraform Plan
        run: |
          terraform plan -input=false
        working-directory: ${{ env.ROOT_PATH }}
      
      - name: Terraform Apply
        run: |
          terraform apply -auto-approve -input=false
        working-directory: ${{ env.ROOT_PATH }}
        
      - name: Show Terraform State
        run: |
          cat ${{ env.ROOT_PATH }}/terraform.tfstate
        working-directory: ${{ env.ROOT_PATH }}

      - name: permission Terraform State
        run: |
           chmod 777 ${{ github.workspace }}/strapin
           chmod 777 ${{ github.workspace }}/strapin/terraform.tfstate
           
        working-directory: ${{ env.ROOT_PATH }}

      - name: Setup Terraform Backend
        run: |
          cat > backend.tf << EOF
          terraform {
            backend "azurerm" {
              resource_group_name = "nstrapi-rg"
              storage_account_name  = "strapistroage"
              container_name       = "secretfile"
              key                  = "terraform.tfstate"
            }
          }
          EOF
          # Set write permissions for the file
          chmod 755 backend.tf
        working-directory: ${{ env.ROOT_PATH }} 

      - name: Terraform Init Reconfigure
        run: |
           echo "yes" | terraform init -reconfigure 
        working-directory: ${{ env.ROOT_PATH }}
   ```
- This workflow is triggered on two events:
- Push to the nikhil-kadam branch.
- Manual trigger using the GitHub Actions workflow_dispatch event.
- This workflow requires read access to repository contents.
- environment variables are used to configure authentication and other settings for Terraform. They are sourced from GitHub Secrets.
- sets the default shell for the subsequent script steps to Bash.
- The workflow has one job named "build" that runs on a self-hosted runner.
- checks out the repository code.
- Installs Terraform by adding HashiCorp's GPG key and configuring the apt repository.
- Initializes the Terraform configuration in the specified working directory.
- Runs terraform plan to generate an execution plan.
- Applies the Terraform plan with auto-approval and without user input.
- Outputs the contents of the Terraform state file.
- Grants read and write permissions to the Terraform state file and its directory.
- Generates a backend.tf file specifying Azure as the backend for storing the Terraform state.
- Re-initializes Terraform with reconfiguration, automatically approving changes.

## create self-hosted runner
### It's designed to be run in a self-hosted environment, likely to have more control over the runner and the infrastructure it interacts with.
- following steps to create self-hosted runner
- step1: create vm on azure portal and login using ssh
- step2: when successfully login run following command into your vm:
```
mkdir actions-runner && cd actions-runner
curl -o actions-runner-linux-x64-2.311.0.tar.gz -L https://github.com/actions/runner/releases/download/v2.311.0/actions-runner-linux-x64-2.311.0.tar.gz
echo "29fc8cf2dab4c195bb147384e7e2c94cfd4d4022c793b346a6175435265aa278  actions-runner-linux-x64-2.311.0.tar.gz" | shasum -a 256 -c
tar xzf ./actions-runner-linux-x64-2.311.0.tar.gz
./config.sh --url https://github.com/PearlThoughtsInternship/snipe-it --token A2DVQZNKLXQTPUJ7BEIPLCDFLYCX4
./run.sh &
```
# check the following screenshots:

![actionsecrit](https://github.com/nikhilk1699/strapi_installation/assets/109533285/bff2a19b-a70f-47a7-a3c5-75ac3be2214c)

![image](https://github.com/nikhilk1699/strapi_installation/assets/109533285/b36c3121-0a96-402a-8cfe-1120ae2f0649)

![mans](https://github.com/nikhilk1699/strapi_installation/assets/109533285/2baa1884-f78b-46f1-97b7-a33bc3602db0)

![mms](https://github.com/nikhilk1699/strapi_installation/assets/109533285/6bdd46e2-94b0-4348-ac21-4ad8ceac42e8)

![re](https://github.com/nikhilk1699/strapi_installation/assets/109533285/0c7436fb-5098-4054-bb47-2840b0db7ee5)

![build scc](https://github.com/nikhilk1699/strapi_installation/assets/109533285/4fa63b07-a72c-42de-aaef-e1763d8e009e)

![image](https://github.com/nikhilk1699/strapi_installation/assets/109533285/bfb86c56-d226-45c1-85f2-3a1ac7c1f874)

![mmms](https://github.com/nikhilk1699/strapi_installation/assets/109533285/7333ce20-deb7-4669-a9ca-6e118f4a2704)

![image](https://github.com/nikhilk1699/strapi_installation/assets/109533285/37de8f50-3fd1-461c-b231-680a84bf7a64)














   
