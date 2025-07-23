# 🚀 Production-Ready NestJS Application on AWS with CI/CD

> A complete, production-grade infrastructure for deploying and managing a NestJS application on AWS. This project uses ECS Fargate for container orchestration, RDS for a managed database, and a full CI/CD pipeline with AWS CodePipeline for automated builds and deployments from GitHub.

---

## **📝 1. Project Overview**

This project provides a secure, scalable, and automated foundation for running a containerized NestJS application on AWS. The entire infrastructure is defined as code using Terraform, enabling consistent and repeatable deployments across different environments. It includes everything from the network foundation to a complete CI/CD pipeline that triggers on a `git push`.

* **Purpose/Goal:** To automate the provisioning of a robust, secure, and scalable cloud environment for a NestJS application, complete with a continuous integration and deployment pipeline.
* **Target Audience:** Developers seeking to deploy containerized applications and DevOps Engineers responsible for managing cloud infrastructure and automation.

---

## **🗺️ 2. Architecture**

The architecture is designed for high availability and security. It isolates the application and database in private subnets, exposing the application only through a public-facing Application Load Balancer. The CI/CD pipeline automates the process of building the application's Docker image and deploying it to the ECS cluster.

### **Architecture Diagram**

*(You can create a diagram using a tool like diagrams.net or Cloudcraft and embed it here.)*

```
[Client] -> [Internet] -> [Route 53] -> [ACM Certificate] -> [Application Load Balancer (Public Subnets)]
                                                                    |
                                                                    v
                                    [ECS Fargate Tasks (Private Subnets)] <-> [RDS PostgreSQL (Private Subnets)]
                                                                    ^
                                                                    |
[GitHub] --(Webhook)--> [CodePipeline] --(Build)--> [CodeBuild] --(Push Image)--> [ECR] --(Deploy)--> [ECS Service]
```

* **Workflow:** A developer pushes code to the specified branch in the GitHub repository. A webhook triggers the AWS CodePipeline. CodeBuild checks out the source code, builds the Docker image, and pushes it to the Amazon ECR repository. Finally, CodePipeline triggers a deployment action, causing Amazon ECS to pull the new image from ECR and deploy it as a new task in the Fargate cluster. The Application Load Balancer then directs traffic to the healthy new task.

### **AWS Services Used**

* **Networking & Content Delivery:**
    * **VPC, Subnets, Route Tables:** Creates a secure and isolated network environment with public subnets for the load balancer and private subnets for the application and database.
    * **Internet Gateway & NAT Gateway:** Provides internet access for the public subnets and enables resources in the private subnets to access the internet for things like pulling dependencies, without being publicly exposed.
    * **Route 53 & ACM:** Manages the application's domain name and provides automated SSL/TLS certificate provisioning and renewal.
* **Compute & Containers:**
    * **Amazon ECS (Elastic Container Service) with Fargate:** Runs the containerized NestJS application without requiring the management of underlying EC2 instances.
    * **Amazon ECR (Elastic Container Registry):** A private Docker registry to store, manage, and deploy the application's container images.
* **Database:**
    * **Amazon RDS (Relational Database Service):** A managed PostgreSQL database instance, relieving the operational burden of database management.
    * **AWS Secrets Manager:** Securely stores and manages the database password, injecting it into the ECS task at runtime.
* **CI/CD & Developer Tools:**
    * **AWS CodePipeline:** The core of the CI/CD pipeline, orchestrating the source, build, and deploy stages.
    * **AWS CodeBuild:** A fully managed build service that compiles the source code, runs tests, and produces the Docker image.
    * **Amazon S3:** Used as the artifact store for the CodePipeline.
* **Security & Identity:**
    * **AWS IAM (Identity and Access Management):** Defines granular permissions for all AWS services, ensuring they operate under the principle of least privilege.
    * **Amazon Cognito:** Provides a managed user directory and authentication service for the application, integrated with the ALB.
    * **Security Groups:** Acts as a virtual firewall for the ALB, ECS tasks, and RDS instance to control inbound and outbound traffic.
* **Monitoring:**
    * **Amazon CloudWatch:** Collects logs from the ECS application and CodeBuild project for monitoring and debugging.

---

## **🚀 3. Deployment & Configuration**

The entire stack is defined in Terraform and can be deployed with a few commands after setting up the required variables.

### **Prerequisites**

* An AWS Account.
* `AWS CLI` configured with appropriate permissions.
* `Terraform` (v1.0 or later).
* A **GitHub Personal Access Token (PAT)** with `repo` and `admin:repo_hook` scopes. This is required for CodePipeline to access your repository and set up the webhook.
* A registered domain name and its associated Hosted Zone ID in Route 53.

### **Deployment Steps**

1.  **Clone the repository:**
    ```bash
    git clone [URL_to_your_repo]
    cd [project-directory]
    ```

2.  **Create a `terraform.tfvars` file:**
    This file will contain all the specific values for your deployment. Create a file named `terraform.tfvars` and populate it using the template below. **Do not commit this file to source control.**

    **`terraform.tfvars` Template:**
    ```hcl
    aws_region            = "us-east-1"
    project_name          = "nestjs-app"
    domain_name           = "your.domain.com"
    route53_zone_id       = "YOUR_ROUTE53_HOSTED_ZONE_ID"
    cognito_domain_prefix = "your-unique-cognito-prefix"
    db_username           = "yourdbuser"
    db_password           = "YourSecureDBPassword123!"
    github_owner          = "your-github-username"
    github_repo           = "your-github-repo-name"
    github_branch         = "main"
    github_token          = "your_github_personal_access_token"
    ```

3.  **Ensure `buildspec.yml` exists in your application repository:**
    The CodeBuild project expects to find a `buildspec.yml` file in the root of your NestJS application repository. This file contains the instructions for building your Docker image.

4.  **Initialize Terraform:**
    This command downloads the necessary provider plugins.
    ```bash
    terraform init
    ```

5.  **Plan the deployment:**
    This command shows you what resources will be created. It's a good practice to review the plan before applying.
    ```bash
    terraform plan
    ```

6.  **Apply the configuration:**
    This command builds and deploys all the AWS resources. You will be prompted to confirm the action.
    ```bash
    terraform apply
    ```

### **Manual Setup Steps**

There are no manual setup steps required in the AWS console. All resources are provisioned by Terraform.

---

## **⚙️ 4. Usage & Operations**

After a successful deployment, the application URL will be available in the Terraform outputs. The CI/CD pipeline is fully active.

### **Access Points**

* **Application URL:** The primary access point for your application. You can get this from the Terraform output:
    ```bash
    terraform output application_url
    ```
* **ALB DNS Name:** The direct DNS name for the Application Load Balancer.
    ```bash
    terraform output alb_dns_name
    ```
* **RDS Endpoint:** The database endpoint for your application. This is automatically passed to your ECS tasks as an environment variable.
    ```bash
    terraform output rds_instance_endpoint
    ```

### **CI/CD Pipeline**

* **Trigger:** The pipeline automatically starts when you push a commit to the branch specified in `var.github_branch` (e.g., `main`).
* **Monitoring the Pipeline:** You can view the pipeline's progress in the AWS Console under **Developer Tools > CodePipeline**.
* **Build Logs:** All build logs from CodeBuild are streamed to a CloudWatch Log Group named `/aws/codebuild/${var.project_name}-build`.

### **Application Logging**

* **Logs:** All logs (stdout/stderr) from your NestJS application running in ECS are streamed to a **CloudWatch Log Group** named `/ecs/${var.project_name}`. This is the primary place to debug application issues.

---

## **🛡️ 6. Security**

Security is a core component of this architecture, with multiple layers of protection.

* **IAM Roles & Policies:** The principle of *least privilege* is strictly applied. Each AWS service has a dedicated IAM role with policies that grant only the permissions required for its specific tasks.
* **Network Security:**
    * The VPC isolates your resources from the public internet.
    * The application and database run in **private subnets**, making them inaccessible directly from the internet.
    * **Security Groups** act as stateful firewalls, allowing traffic only from trusted sources (e.g., only the ALB can send traffic to the ECS tasks, and only the ECS tasks can connect to the RDS database).
* **Data Security:**
    * **Encryption in Transit:** The ALB uses an ACM certificate to enforce HTTPS, encrypting all data between the client and the load balancer.
    * **Encryption at Rest:** RDS and S3 encrypt data at rest by default.
    * **Secrets Management:** The database password is not hardcoded. It is securely stored in **AWS Secrets Manager** and injected into the ECS container at runtime.
* **Authentication:** **Amazon Cognito** is integrated with the ALB to handle user authentication before traffic is even forwarded to your application, offloading a critical security concern.

---

## **💰 7. Cost**

* **Cost Estimation:** This architecture is designed for production and is **not fully covered by the AWS Free Tier**. Key services that will incur costs include:
    * **NAT Gateway:** Billed per hour and for data processed.
    * **Amazon RDS:** Billed per hour based on the instance size.
    * **Application Load Balancer:** Billed per hour and per LCU (Load Balancer Capacity Unit).
    * **ECS on Fargate:** Billed based on the vCPU and memory allocated to your tasks.
* **Cost Optimization:**
    * For development or staging environments, consider using smaller RDS and Fargate task sizes.
    * Implement **Application Auto Scaling** on the ECS service to scale the number of tasks based on demand, ensuring you only pay for the capacity you need.
    * Shut down non-production environments when not in use.
