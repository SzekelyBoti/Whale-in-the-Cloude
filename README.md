<!-- Improved compatibility of back to top link -->
<a id="readme-top"></a>

<!-- PROJECT SHIELDS -->
[![Contributors][contributors-shield]][contributors-url]
[![Forks][forks-shield]][forks-url]
[![Stargazers][stars-shield]][stars-url]
[![Issues][issues-shield]][issues-url]
[![LinkedIn][linkedin-shield]][linkedin-url]

<!-- PROJECT LOGO -->
<br />
<div align="center">

<h3 align="center">🐳 Whale in the Cloud</h3>

  <p align="center">
    A fully containerized, cloud-native application deployed on AWS — built with Terraform, Docker, and Node.js across a multi-AZ infrastructure.
    <br />
    <a href="https://github.com/SzekelyBoti/Whale-in-the-Cloude"><strong>Explore the docs »</strong></a>
    <br />
    <br />
    <a href="https://github.com/SzekelyBoti/Whale-in-the-Cloude/issues/new?labels=bug&template=bug-report---.md">🐛 Report Bug</a>
    ·
    <a href="https://github.com/SzekelyBoti/Whale-in-the-Cloude/issues/new?labels=enhancement&template=feature-request---.md">✨ Request Feature</a>
  </p>
</div>
---

<!-- TABLE OF CONTENTS -->
<details>
  <summary>📚 Table of Contents</summary>
  <ol>
    <li>
      <a href="#about-the-project">About The Project</a>
      <ul>
        <li><a href="#architecture">Architecture</a></li>
        <li><a href="#built-with">Built With</a></li>
      </ul>
    </li>
    <li>
      <a href="#getting-started">Getting Started</a>
      <ul>
        <li><a href="#prerequisites">Prerequisites</a></li>
        <li><a href="#installation">Installation</a></li>
      </ul>
    </li>
    <li><a href="#usage">Usage</a></li>
    <li><a href="#project-structure">Project Structure</a></li>
    <li><a href="#roadmap">Roadmap</a></li>
    <li><a href="#contact">Contact</a></li>
  </ol>
</details>

---

<!-- ABOUT THE PROJECT -->
## 🐳 About The Project

[![Architecture Diagram][product-screenshot]](https://github.com/SzekelyBoti/Whale-in-the-Cloude)

**Whale in the Cloud** is a cloud infrastructure project built to demonstrate real-world AWS and DevOps engineering skills. It provisions a production-like environment entirely with Terraform, running Dockerized services inside EC2 instances spread across multiple availability zones.

### 🌟 Key Highlights

- 🏗️ **Custom VPC** with public, private, and database subnets across 2 AZs
- 🐋 **Dockerized Node.js app** served behind nginx, running via docker-compose on EC2
- ⚖️ **Internet-facing AWS ALB** routing traffic to private EC2 instances
- 📦 **AWS ECR** for Docker image storage and distribution
- 🗄️ **RDS PostgreSQL** with multi-AZ support in dedicated database subnets
- 🌱 **Lambda seed function** to populate the database with initial data
- 📊 **Lambda report function** that polls all server instances, composes a report, and uploads it to S3
- 🤖 **One-command deployment** via a bash automation script

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

### 🏛️ Architecture

```
                        🌐 Internet
                             │
                             ▼
                    ┌─────────────────┐
                    │   AWS ALB       │  (public subnets, 2 AZs)
                    └────────┬────────┘
                             │
              ┌──────────────┴──────────────┐
              ▼                             ▼
    ┌─────────────────┐           ┌─────────────────┐
    │   EC2 - AZ1     │           │   EC2 - AZ2     │
    │  nginx :80      │           │  nginx :80      │
    │  ├── app1 :3000 │           │  ├── app1 :3000 │
    │  └── app2 :3000 │           │  └── app2 :3000 │
    └────────┬────────┘           └────────┬────────┘
             └──────────────┬─────────────┘
                            ▼
                  ┌─────────────────┐
                  │ RDS PostgreSQL  │  (database subnets)
                  └─────────────────┘

  🔑 Bastion Host (public subnet) ──► SSH to private EC2s
  📦 ECR ──► stores whale-app & whale-nginx images
  🌱 Lambda seed ──► populates RDS with initial data
  📊 Lambda report ──► polls EC2s ──► uploads report.txt ──► S3
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

### 🛠️ Built With

* [![Terraform][Terraform-shield]][Terraform-url]
* [![Docker][Docker-shield]][Docker-url]
* [![Node.js][Node-shield]][Node-url]
* [![AWS][AWS-shield]][AWS-url]
* [![Nginx][Nginx-shield]][Nginx-url]
* [![PostgreSQL][Postgres-shield]][Postgres-url]

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

<!-- GETTING STARTED -->
## 🚀 Getting Started

### 📋 Prerequisites

Make sure you have the following installed and configured:

* **AWS CLI** configured with appropriate credentials
  ```sh
  aws configure
  ```
* **Terraform** >= 1.0
  ```sh
  terraform -version
  ```
* **Docker** Desktop running locally
  ```sh
  docker -v
  ```
* **Node.js** and npm (for Lambda packaging)
  ```sh
  node -v && npm -v
  ```
* An existing **EC2 Key Pair** in your target AWS region

### ⚙️ Installation

1. Clone the repository
   ```sh
   git clone https://github.com/SzekelyBoti/Whale-in-the-Cloude.git
   cd Whale-in-the-Cloude
   ```

2. Create your `terraform.tfvars` file inside the `terraform/` directory — **never commit this file!**
   ```sh
   cp terraform/terraform.tfvars.example terraform/terraform.tfvars
   ```
   Fill in your values:
   ```hcl
   account_id    = "YOUR_AWS_ACCOUNT_ID"
   key_pair_name = "YOUR_KEY_PAIR_NAME"
   instance_type = "t3.micro"
   db_password   = "YOUR_DB_PASSWORD"
   region        = "eu-north-1"
   environment   = "dev"
   ```

3. Make the deploy script executable
   ```sh
   chmod +x deploy.sh
   ```

4. Run the full deployment 🎉
   ```sh
   ./deploy.sh up
   ```

   This single command will:
   - 📦 Package the Lambda functions
   - 🏗️ Run `terraform init` and `terraform apply`
   - 🐋 Build and push Docker images to ECR
   - 🖥️ SSH into each EC2 instance and pull/start the containers

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

<!-- USAGE -->
## 💡 Usage

### 🤖 Deploy Script Commands

```sh
./deploy.sh up        # 🚀 Full deploy: terraform + build images + pull on servers
./deploy.sh destroy   # 💥 Tear down all AWS infrastructure
./deploy.sh build     # 🐋 Build and push Docker images to ECR only
./deploy.sh pull      # 🔄 Pull latest images on EC2 instances only
./deploy.sh report    # 📊 Invoke the Lambda report and print results
```

### 🌐 API Endpoints

Once deployed, the ALB DNS name is printed as a Terraform output. Available endpoints:

| Endpoint | Method | Description |
|---|---|---|
| `/` | `GET` | 👋 Returns a hello message and logs a visit to the database |
| `/health` | `GET` | ❤️ Health check endpoint |
| `/count` | `GET` | 🔢 Increments and returns the in-memory request counter |
| `/count/current` | `GET` | 👁️ Returns the current counter value without incrementing |
| `/visits` | `GET` | 📋 Returns the last 20 visits from the database |
| `/products` | `GET` | 🛍️ Returns all products from the database |

### 📊 Generating a Report

```sh
./deploy.sh report
```

Or invoke directly with the AWS CLI:

```sh
aws lambda invoke \
  --function-name whale-report-lambda \
  --region eu-north-1 \
  response.json && cat response.json
```

The report is stored in S3 and looks like this:

```
WHALE REPORT
Generated: 2026-05-04T10:28:41.555Z
Servers polled: 2

fcb6c2fa5282 (10.0.10.88): 3
1cf6179b38b8 (10.0.11.141): 2

TOTAL: 5
```

### 🌱 Seeding the Database

To populate the database with initial data, invoke the seed Lambda:

```sh
aws lambda invoke \
  --function-name whale-seed-db \
  --region eu-north-1 \
  seed_response.json && cat seed_response.json
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

<!-- PROJECT STRUCTURE -->
## 📁 Project Structure

```
🐳 Whale-in-the-Cloude/
├── 📄 deploy.sh                  # One-command automation script
├── 📄 README.md
├── 🖥️  app/                      # Node.js web server
│   ├── Dockerfile
│   ├── index.js
│   └── package.json
├── 🔀 nginx/                     # nginx reverse proxy config
│   ├── Dockerfile
│   └── nginx.conf
├── ⚡ lambda/                    # Lambda functions
│   ├── 📊 report/               # Report function - polls servers & uploads to S3
│   │   ├── index.js
│   │   └── package.json
│   └── 🌱 seed/                 # Seed function - populates the database
│       ├── index.js
│       └── package.json
└── 🏗️  terraform/                # All infrastructure as code
    ├── main.tf
    ├── variables.tf
    ├── outputs.tf
    ├── terraform.tfvars.example
    └── modules/
        ├── vpc/
        ├── ec2/
        ├── alb/
        ├── ecr/
        ├── iam/
        ├── rds/
        ├── s3/
        ├── bastion/
        ├── security_groups/
        ├── lambda_seed/
        └── lambda_report/
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

<!-- ROADMAP -->
## 🗺️ Roadmap

- [x] ✅ Custom VPC with public, private, and database subnets across 2 AZs
- [x] ✅ Dockerized Node.js app with nginx load balancer via docker-compose
- [x] ✅ AWS ECR for Docker image storage
- [x] ✅ EC2 instances bootstrapped with user_data
- [x] ✅ Internet-facing AWS Application Load Balancer
- [x] ✅ Bastion host for secure SSH access to private instances
- [x] ✅ RDS PostgreSQL with multi-AZ support
- [x] ✅ Lambda seed function to populate the database
- [x] ✅ Lambda report function polling all servers
- [x] ✅ S3 bucket for report storage
- [x] ✅ One-command bash deployment script
- [ ] 🔜 CloudWatch alarms and monitoring
- [ ] 🔜 HTTPS support with ACM certificate
- [ ] 🔜 Auto Scaling Group instead of fixed EC2 instances

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

<!-- CONTACT -->
## 📬 Contact

**Botond Szekely**

[![LinkedIn][linkedin-shield]][linkedin-url]

Project Link: [https://github.com/SzekelyBoti/Whale-in-the-Cloude](https://github.com/SzekelyBoti/Whale-in-the-Cloude)

<p align="right">(<a href="#readme-top">back to top</a>)</p>

---

<!-- MARKDOWN LINKS & IMAGES -->
[contributors-shield]: https://img.shields.io/github/contributors/SzekelyBoti/Whale-in-the-Cloude.svg?style=for-the-badge
[contributors-url]: https://github.com/SzekelyBoti/Whale-in-the-Cloude/graphs/contributors
[forks-shield]: https://img.shields.io/github/forks/SzekelyBoti/Whale-in-the-Cloude.svg?style=for-the-badge
[forks-url]: https://github.com/SzekelyBoti/Whale-in-the-Cloude/network/members
[stars-shield]: https://img.shields.io/github/stars/SzekelyBoti/Whale-in-the-Cloude.svg?style=for-the-badge
[stars-url]: https://github.com/SzekelyBoti/Whale-in-the-Cloude/stargazers
[issues-shield]: https://img.shields.io/github/issues/SzekelyBoti/Whale-in-the-Cloude.svg?style=for-the-badge
[issues-url]: https://github.com/SzekelyBoti/Whale-in-the-Cloude/issues
[linkedin-shield]: https://img.shields.io/badge/-LinkedIn-black.svg?style=for-the-badge&logo=linkedin&colorB=555
[linkedin-url]: https://linkedin.com/in/boti-szekely
[product-screenshot]: images/architecture.png
[Terraform-shield]: https://img.shields.io/badge/Terraform-7B42BC?style=for-the-badge&logo=terraform&logoColor=white
[Terraform-url]: https://www.terraform.io/
[Docker-shield]: https://img.shields.io/badge/Docker-2496ED?style=for-the-badge&logo=docker&logoColor=white
[Docker-url]: https://www.docker.com/
[Node-shield]: https://img.shields.io/badge/Node.js-339933?style=for-the-badge&logo=nodedotjs&logoColor=white
[Node-url]: https://nodejs.org/
[AWS-shield]: https://img.shields.io/badge/AWS-232F3E?style=for-the-badge&logo=amazonaws&logoColor=white
[AWS-url]: https://aws.amazon.com/
[Nginx-shield]: https://img.shields.io/badge/nginx-009639?style=for-the-badge&logo=nginx&logoColor=white
[Nginx-url]: https://nginx.org/
[Postgres-shield]: https://img.shields.io/badge/PostgreSQL-4169E1?style=for-the-badge&logo=postgresql&logoColor=white
[Postgres-url]: https://www.postgresql.org/
