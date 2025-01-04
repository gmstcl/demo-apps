pipeline {
  agent any
  environment {
     VERSION = sh(script: 'cat VERSION', returnStdout: true).trim()
  }
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
      }
    }

    stage('Clone-helm-repo') {
      steps {
        git(url: 'https://github.com/gmstcl/demo-charts', branch: 'main', credentialsId: '06647ebb-e150-48d6-9219-ae08346a4a2f')
      }
    }

    stage('helm-Build') {
      steps {
        sh '''#!/bin/bash sed -i "s|version:.*|version: $VERSION|g" backend-skills-repo/Chart.yaml
sed -i "s|tag:.*|tag: backend-v$VERSION|g" backend-skills-repo/values.yaml'''
      }
    }

  }
}