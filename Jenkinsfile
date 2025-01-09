pipeline {
    agent any
    environment {
        VERSION = sh(script: 'cat VERSION', returnStdout: true).trim()
    }
    stages {
        stage('Pre-Build') {
            steps {
                withEnv([
                    "AWS_DEFAULT_REGION=${env.AWS_DEFAULT_REGION}",
                    "AWS_ACCOUNT=${env.AWS_ACCOUNT}",
                    "AWS_REPOSITORY=${env.BACKEND_AWS_REPOSITORY}"
                ]) {
                    sh '''
                    aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com
                    echo $VERSION
                    '''
                }
            }
        }

        stage('Build') {
            steps {
                withEnv(["AWS_REPOSITORY=${env.BACKEND_AWS_REPOSITORY}"]) {
                sh '''
                chmod +x ./gradlew
                ./gradlew build
                docker build -t ${AWS_REPOSITORY}:v$VERSION .
                '''
                }
            }
        }

        stage('Post-Build') {
            steps {
                withEnv(["AWS_REPOSITORY=${env.BACKEND_AWS_REPOSITORY}"]) {
                sh '''
                docker push ${AWS_REPOSITORY}:v$VERSION
                rm -rf * .*
                '''
                }
            }
        }

        stage('Checkout') {
            steps {
                git url: 'https://github.com/gmstcl/demo-apps', branch: 'backend', credentialsId: 'a9c1964d-6d52-4da5-9467-5da0c1daa130'
            }
        }

        stage('Test') {
            steps {
                withEnv(["AWS_REPOSITORY=${env.BACKEND_AWS_REPOSITORY}"]) {
                sh 'docker run -d --name demo-backend -p 8081:8080 ${AWS_REPOSITORY}:v$VERSION'

                script {
                    env.CONTAINER_ID = sh(script: 'docker ps -q -f name=demo-backend', returnStdout: true).trim()
                }

                sh '''
                sleep 5
                chmod +x test.sh
                ./test.sh
                '''

                junit 'reports/test-results.xml'

                sh '''
                docker stop $CONTAINER_ID
                docker rm $CONTAINER_ID
                '''
                }
            }
        }

        stage('Clone-helm-repo') {
            steps {
                git url: 'https://github.com/gmstcl/demo-charts', branch: 'main', credentialsId: 'a9c1964d-6d52-4da5-9467-5da0c1daa130'
            }
        }

        stage('helm-Pre-Build') {
            steps {
                sh '''
                sed -i "s|version:.*|version: $VERSION|g" backend-skills-repo/Chart.yaml
                sed -i "s|tag:.*|tag: backend-v$VERSION|g" backend-skills-repo/values.yaml
                '''
            }
        }

        stage('helm-Build') {
            steps {
                sh '''
                helm package backend-skills-repo
                helm repo index . --merge index.yaml --url https://github.com/gmstcl/demo-charts/releases/download/v$VERSION/
                '''
            }
        }

        stage('helm-Post-Build') {
            steps {
                sh '''
                git config user.name "gmstcl"
                git config user.email "as.gmstcl@gmail.com"
                '''

                withCredentials([usernamePassword(credentialsId: 'a9c1964d-6d52-4da5-9467-5da0c1daa130', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
                    sh '''
                    git remote set-url origin https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/gmstcl/demo-charts.git
                    echo $GIT_PASSWORD | gh auth login --with-token
                    '''
                }

                sh '''
                NAME=$(gh release view v$VERSION --json assets --jq '.assets[].name' || echo none)
                isFrontend=$(echo $NAME | grep frontend | wc -l)
                isBackend=$(echo $NAME | grep backend | wc -l)

                if [ $isBackend -eq 0 ] && [ $isFrontend -eq 1 ]; then
                    gh release upload v$VERSION backend-skills-repo-$VERSION.tgz
                elif [ $isBackend -eq 0 ] && [ $isFrontend -eq 0 ]; then
                    gh release create v$VERSION backend-skills-repo-$VERSION.tgz -t v$VERSION --generate-notes
                fi
                '''
                sh 'rm -rf *.tgz'
                sh 'git add -A'
                sh 'git commit -m "$VERSION"'
                sh 'git push origin main'
            }
        }

        stage('Approval') {
            steps {
                emailext mimeType: 'text/html', subject: "[Jenkins] Approval Request from ${currentBuild.fullDisplayName} - v${VERSION}", from: 'as.gmstcl@gmail.com', to: 'as.gmstcl@gmail.com', body: '''<a href="${BUILD_URL}input">Please check this approval request.</a>'''
                script {
                    input id: 'userInput', message: 'Deploy to production?', submitterParameter: 'submitter', submitter: 'admin'
                }
            }
        }
    }
}
