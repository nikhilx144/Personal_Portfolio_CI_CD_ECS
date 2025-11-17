pipeline {
  agent any

  environment {
    AWS_REGION     = 'ap-south-1'
    ECR_REPO       = '661979762009.dkr.ecr.ap-south-1.amazonaws.com/edu_map_ecr_repo' 
    TERRAFORM_DIR  = 'terraform/'
  }

  options {
    timestamps()
    buildDiscarder(logRotator(numToKeepStr: '10'))
  }

  stages {
    stage('Checkout SCM') {
      steps {
        checkout scm
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          env.IMAGE_TAG = sh(returnStdout: true, script: "git rev-parse --short HEAD").trim()
          echo "Building Docker image with tag: ${IMAGE_TAG}"

          sh """
            docker build -t ${ECR_REPO}:${IMAGE_TAG} .
            docker tag ${ECR_REPO}:${IMAGE_TAG} ${ECR_REPO}:latest
          """
        }
      }
    }

    stage('Push Image to ECR') {
      steps {
        withAWS(credentials: 'aws-ecr-access-key', region: "${AWS_REGION}") {
          echo "Logging into AWS ECR and pushing image..."
          sh """
            aws ecr get-login-password --region ${AWS_REGION} | \
              docker login --username AWS --password-stdin ${ECR_REPO}

            docker push ${ECR_REPO}:${IMAGE_TAG}
            docker push ${ECR_REPO}:latest
          """
        }
      }
    }

    stage('Terraform Apply') {
      steps {
        withAWS(credentials: 'aws-terraform-apply-access-key', region: "${AWS_REGION}") {
          dir("${TERRAFORM_DIR}") {
            echo "Running Terraform with image tag ${IMAGE_TAG}"
            sh """
              terraform init -reconfigure
              terraform plan -var="image_tag=${IMAGE_TAG}" -out=tfplan
              terraform apply -auto-approve tfplan
            """
          }
        }
      }
    }

    stage('Smoke Test') {
      steps {
        script {
          def albDns = sh(
            script: "cd ${TERRAFORM_DIR} && terraform output -raw alb_dns_name || true",
            returnStdout: true
          ).trim()
          if (albDns) {
            echo "Performing smoke test on ALB endpoint: http://${albDns}"
            sh """
              for i in {1..5}; do
                echo "Attempt \$i: Checking ALB..."
                if curl -fs http://${albDns}; then
                  echo "✅ ALB responded successfully"
                  exit 0
                fi
                sleep 10
              done
              echo "❌ ALB not responding after multiple retries"
              exit 1
            """
          } else {
            echo "⚠️ No ALB DNS name found (Terraform output missing)"
          }
        }
      }
    }
  }

  post {
    success { echo "✅ Deployment pipeline succeeded" }
    failure { echo "❌ Deployment pipeline failed" }
    always { 
      echo "🧹 Cleaning workspace..."
      cleanWs()
    }
  }
}
