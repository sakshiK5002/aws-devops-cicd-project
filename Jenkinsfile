pipeline {
    agent any

    tools {
        jdk 'JDK17'
        maven 'Maven3'
    }

    parameters {
        string(
            name: 'jenkinskey',
            defaultValue: 'jenkinskey',
            description: 'AWS EC2 Key Pair name'
        )
        string(
            name: 'ADMIN_CIDR',
            defaultValue: '3.111.51.146/32',
            description: 'IP allowed to access the Application EC2'
        )
    }

   environment {
    DOCKER_IMAGE = 'sakshi0716/aws-devops-project-repo'
    SONAR_SERVER = 'SonarQube'
    SONAR_HOST = 'http://3.111.51.146:9000'

    EC2_KEY_NAME = 'jenkinskey'
    ADMIN_CIDR = '3.111.51.146/32'
}

    stages {

        stage('Checkout') {
            steps {
                git branch: 'main',
                    url: 'https://github.com/sakshiK5002/aws-devops-cicd-project.git'
            }
        }

        stage('Build with Maven') {
            steps {
                sh 'mvn clean package'
            }
        }

        stage('SonarQube Analysis') {
    steps {
        withCredentials([
            string(
                credentialsId: 'sonar-token',
                variable: 'SONAR_TOKEN'
            )
        ]) {
            sh '''
                mvn clean verify org.sonarsource.scanner.maven:sonar-maven-plugin:5.8.0.7211:sonar \
                -Dsonar.projectKey=my-project \
                -Dsonar.projectName=my-project \
                -Dsonar.host.url=$SONAR_HOST \
                -Dsonar.token=$SONAR_TOKEN
            '''
        }
    }
}
        stage('Check WAR File') {
    steps {
        sh '''
            echo "Checking target directory..."
            ls -lah target/ || true
            echo "Searching WAR files..."
            find . -name "*.war"
        '''
    }
}

       stage('Docker Build') {
    steps {
        sh '''
            mv target/aws-devops-project-1.0.war target/ROOT.war
            docker build -t $DOCKER_IMAGE .
        '''
    }
}

        stage('Docker Push') {
            steps {
                withCredentials([
                    usernamePassword(
                        credentialsId: 'dockerhub-creds',
                        usernameVariable: 'DOCKER_USER',
                        passwordVariable: 'DOCKER_PASS'
                    )
                ]) {
                    sh '''
                        set +x
                        echo "$DOCKER_PASS" | docker login \
                            -u "$DOCKER_USER" --password-stdin
                        docker push "$DOCKER_IMAGE"
                        docker logout
                    '''
                }
            }
        }

        stage('Terraform Provisioning') {
            steps {
                dir('terraform') {
                    sh '''
                        terraform init
                        terraform validate
                        terraform plan \
                          -var="key_name=${EC2_KEY_NAME}" \
                          -var="admin_cidr=${ADMIN_CIDR}" \
                          -out=tfplan

                        terraform apply -auto-approve tfplan

                        terraform output -raw public_ip \
                          > ../app_ip.txt
                    '''
                }
            }
        }

        stage('Deploy with Ansible') {
            steps {
                script {
                    def appIP = readFile('app_ip.txt').trim()

                    withCredentials([
                        usernamePassword(
                            credentialsId: 'dockerhub-creds',
                            usernameVariable: 'DOCKER_USER',
                            passwordVariable: 'DOCKER_PASS'
                        ),
                        sshUserPrivateKey(
                            credentialsId: 'app-ec2-ssh-key',
                            keyFileVariable: 'SSH_KEY',
                            usernameVariable: 'SSH_USER'
                        )
                    ]) {
                        sh '''
                            chmod 600 "$SSH_KEY"

                            ansible-playbook \
                              -i "${APP_IP}," \
                              -u "$SSH_USER" \
                              --private-key "$SSH_KEY" \
                              ansible/deploy.yml \
                              -e "docker_image=${DOCKER_IMAGE}" \
                              -e "dockerhub_username=${DOCKER_USER}" \
                              -e "dockerhub_password=${DOCKER_PASS}"
                        '''
                    }
                }
            }
            environment {
                APP_IP = "${appIP}"
            }
        }

        stage('Application URL') {
            steps {
                script {
                    def appIP = readFile('app_ip.txt').trim()

                    echo "Application deployed successfully!"
                    echo "Application URL: http://${appIP}:8080"
                }
            }
        }
    }
}
