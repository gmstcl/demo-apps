pipeline {
  agent any
  stages {
    stage('Pre-Build') {
      steps {
        sh '''#!/bin/bash
aws ecr get-login-password --region ap-northeast-2 | docker login --username AWS --password-stdin 226347592148.dkr.ecr.ap-northeast-2.amazonaws.com
echo $VERSION'''
      }
    }

    stage('Build') {
      steps {
        sh '''#!/bin/bash
chmod +x ./gradlew
./gradlew build
docker build -t 226347592148.dkr.ecr.ap-northeast-2.amazonaws.com/demo-backend:v1.1.0 .'''
      }
    }

    stage('Post-Build') {
      steps {
        sh '''#!/bin/bash
docker push 226347592148.dkr.ecr.ap-northeast-2.amazonaws.com/demo-backend:v1.1.0'''
        sh '''#!/bin/bash
rm -rf * rm -rf .*'''
      }
    }

    stage('Clone-helm-repo') {
      steps {
        git(url: 'https://github.com/gmstcl/demo-charts', branch: 'main', credentialsId: '06647ebb-e150-48d6-9219-ae08346a4a2f')
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
        withCredentials(bindings: [usernamePassword(credentialsId: '06647ebb-e150-48d6-9219-ae08346a4a2f', usernameVariable: 'GIT_USERNAME', passwordVariable: 'GIT_PASSWORD')]) {
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

    stage('Staging-Deploy') {
      steps {
        sh '''#!/bin/bash
echo \'Hello Staging-Deploy\''''
      }
    }

    stage('Approval') {
      steps {
        emailext mimeType: 'text/html',
                 subject: "[Jenkins] Approval Request from ${currentBuild.fullDisplayName}",
                 to: "as.gmstcl@gmail.com",
                 body: '''<a href="${BUILD_URL}input">Please check this approval request.</a>'''
                
                script {
                    def userInput = input id: 'userInput',
                                        message: 'Deploy to production?', 
                                        submitterParameter: 'submitter',
                                        submitter: 'admin',
                                        parameters: [
                                            [$class: 'TextParameterDefinition', defaultValue: '1.0', description: 'Image Tag', name: 'tag'],
                                            [$class: 'TextParameterDefinition', defaultValue: 'BAR', description: 'Environment', name: 'FOO']
                                        ]
                    echo ("Env: "+userInput['tag'])
                    echo ("Target: "+userInput['FOO'])
                    echo ("submitted by: "+userInput['submitter'])
                }
      }
    }

  }
  environment {
    VERSION = sh(script: 'cat VERSION', returnStdout: true).trim()
  }
}