pipeline {
  agent any
  stages {
    stage('Pre-Build') {
      steps {
        withEnv([
          "AWS_DEFAULT_REGION=${env.AWS_DEFAULT_REGION}",
          "AWS_ACCOUNT=${env.AWS_ACCOUNT}",
          "AWS_REPOSITORY=${env.BACKEND_AWS_REPOSITORY}"
        ])
        sh '''#!/bin/bash
aws ecr get-login-password --region ${AWS_DEFAULT_REGION} | docker login --username AWS --password-stdin ${AWS_ACCOUNT}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com
echo $VERSION'''
      }
    }

    stage('Build') {
      steps {
        sh '''#!/bin/bash
chmod +x ./gradlew
./gradlew build
docker build -t ${AWS_REPOSITORY}:v$VERSION .'''
      }
    }

    stage('Post-Build') {
      steps {
        sh '''#!/bin/bash
docker push ${AWS_REPOSITORY}:v$VERSION'''
        sh '''#!/bin/bash
rm -rf * rm -rf .*'''
      }
    }

    stage('Checkout') {
      steps {
        git(url: 'https://github.com/gmstcl/demo-apps', branch: 'backend', credentialsId: 'a9c1964d-6d52-4da5-9467-5da0c1daa130')
      }
    }
    
    stage('Test') { 
        steps {
            sh 'docker run -d --name demo-backend -p 8081:8080 ${AWS_REPOSITORY}:v$VERSION'

            script {
                def container_id = sh(script: 'docker ps -q -f name=demo-backend', returnStdout: true).trim()
                env.CONTAINER_ID = container_id
            }

            sh 'sleep 5'
            sh 'chmod +x test.sh'
            sh './test.sh'

            junit 'reports/test-results.xml'

            sh 'docker stop $CONTAINER_ID'
            sh 'docker rm $CONTAINER_ID'

    stage('Test') {
      steps {
        sh 'docker run -d --name demo-backend -p 8081:8080 226347592148.dkr.ecr.ap-northeast-2.amazonaws.com/demo-backend:v1.1.0'
        script {
          def container_id = sh(script: 'docker ps -q -f name=demo-backend', returnStdout: true).trim()
          env.CONTAINER_ID = container_id
        }

        sh 'sleep 5'
        sh 'chmod +x test.sh'
        sh './test.sh'
        junit 'reports/test-results.xml'
        sh 'docker stop $CONTAINER_ID'
        sh 'docker rm $CONTAINER_ID'
      }
    }

    stage('Clone-helm-repo') {
      steps {
        git(url: 'https://github.com/gmstcl/demo-charts', branch: 'main', credentialsId: 'a9c1964d-6d52-4da5-9467-5da0c1daa130')
      }
    }

    stage('helm-Pre-Build') {
      steps {
        sh '''#!/bin/bash
sed -i "s|version:.*|version: $VERSION|g" backend-skills-repo/Chart.yaml
sed -i "s|tag:.*|tag: backend-v$VERSION|g" backend-skills-repo/values.yaml'''
      }
    }

    stage('helm-Build') {
      steps {
        sh '''#!/bin/bash
helm package backend-skills-repo
helm repo index . --merge index.yaml --url https://github.com/gmstcl/demo-charts/releases/download/v$VERSION/'''
      }
    }

    stage('helm-Post-Build') {
      steps {
        sh '''
git config user.name "gmstcl"
git config user.email "as.gmstcl@gmail.com"
        '''
        withCredentials(bindings: [usernamePassword(credentialsId: 'a9c1964d-6d52-4da5-9467-5da0c1daa130', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
          sh '''
git remote set-url origin https://${GIT_USERNAME}:${GIT_PASSWORD}@github.com/gmstcl/demo-charts.git
echo $GIT_PASSWORD | gh auth login --with-token
          '''
        }

        sh '''
NAME=$(gh release view v$VERSION --json assets --jq \'.assets[].name\' || echo none)
isFrontend=$(echo $NAME | grep frontend | wc -l)
isBackend=$(echo $NAME | grep backend | wc -l)

if [ $isBackend -eq 0 ]  && [ $isFrontend -eq 1 ]; then
  gh release upload v$VERSION backend-skills-repo-$VERSION.tgz
elif [ $isBackend -eq 1 ] && [ $isFrontend -eq 0 ]; then 
  echo "Only Backend"
elif [ $isBackend -eq 0 ] && [ $isFrontend -eq 0 ]; then
  gh release create v$VERSION backend-skills-repo-$VERSION.tgz -t v$VERSION --generate-notes
elif [ $isBackend -eq 1 ] && [ $isFrontend -eq 1 ]; then
  echo "Failed"
fi
        '''
        sh '''#!/bin/bash
gh release create v$VERSION backend-skills-repo-$VERSION.tgz -t v$VERSION --generate-notes
rm -rf *.tgz
git add -A
git commit -m "$VERSION"
git push origin  main
rm -rf *
rm -rf .*'''
      }
    }

    // stage('Staging-Deploy') {
      // steps {
        // sh '''#!/bin/bash
// aws eks update-kubeconfig --name skills-staging-cluster
// helm repo add demo-backend-charts https://gmstcl.github.io/demo-charts/
// helm repo update
// helm uninstall skills-backend -n skills 
// helm install skills-backend --set Values.version=green --set image.repository=${AWS_ACCOUNT}.dkr.ecr.${AWS_DEFAULT_REGION}.amazonaws.com/demo-backend --set image.tag=v$VERSION demo-backend-charts/backend-skills-repo -n skills
// sleep 20 
// kubectl get pods -n skills''' 
        // script {
            // def statusCode = sh(script: "kubectl exec deployment/backend-app -n skills -- curl -s -o /dev/null -w '%{http_code}' localhost:8080/api/health", returnStdout: true).trim()
            // if (statusCode != "200") {
              // error "Health check failed with status code: ${statusCode}"
        // }
        // }
      // }
    // }
  
    stage('Approval') {
      steps {
        emailext(mimeType: 'text/html', subject: "[Jenkins] Approval Request from ${currentBuild.fullDisplayName} - v${VERSION}", from: 'as.gmstcl@gmail.com', to: 'as.gmstcl@gmail.com', body: '''<a href="${BUILD_URL}input">Please check this approval request.</a>
                          <img src="https://image.fmkorea.com/files/attach/new3/20230629/14339012/770863625/5916893416/6f736479948b0c9424a6adaf9bab41d2.png" alt="Clid">''')
        script {
          def userInput = input id: 'userInput',
          message: 'Deploy to production?',
          submitterParameter: 'submitter',
          submitter: 'admin'
        }

      }
    }

  }
  environment {
    VERSION = sh(script: 'cat VERSION', returnStdout: true).trim()
  }
}