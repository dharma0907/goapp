pipeline{
    agent{
        agent any
    }
    environment {
        AWS_ACCESS_KEY_ID = credentials('AWS_ACCESS_KEY_ID')
        AWS_SECRET_ACCESS_KEY = credentials('AWS_SECRET_ACCESS_KEY')
        AWS_DEFAULT_REGION = "us-east-1"
    }
    stages{
        stage("Create an EKS Cluster"){
            steps{
                echo "========executing eks cluster commands from terraform code========"
                script{
                     dir(aws_eks){
                        sh "terraform init"
                        sh "terraform plan"
                        sh "terraform apply -auto-approve"
                     }

                }
            }
        }
        stage('Wait for 10 minutes') {
            steps {
                echo 'Waiting for 5 minutes...'
                sleep time: 10, unit: 'MINUTES'
            }
        }
        stage("executing k8 manifest files"){
            steps{
                echo "========executing k8 manifest files suing kubectl commands========"
                script{
                     dir(k8/manifest){
                         sh "aws eks update-kubeconfig  --name democluster"
                         sh "kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.11.1/deploy/static/provider/aws/deploy.yaml"
                         sh "kubectl apply -f deployment.yaml"
                         sh "kubectl apply -f service.yaml"
                         sh "kubectl apply -f ingress.yaml"
                     }

                }
            }
        }
        stage('Wait for 5 minutes') {
            steps {
                echo 'Waiting for 5 minutes...'
                sleep time: 5, unit: 'MINUTES'
            }
        }
        stage("destroy an EKS Cluster"){
            steps{
                echo "========destroy eks cluster commands from terraform code========"
                script{
                     dir(aws_eks){
                        sh "terraform destroy -auto-approve"
                     }

                }
            }
        }
    }
    post{
        always{
            echo "========always========"
        }
        success{
            echo "========pipeline executed successfully ========"
        }
        failure{
            echo "========pipeline execution failed========"
        }
    }
}
