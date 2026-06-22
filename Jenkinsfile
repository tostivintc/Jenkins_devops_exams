pipeline {
  environment { // Declaration of environment variables
    DOCKER_ID = "cyriltostivint" // replace this with your docker-id
    DOCKER_CAST_IMAGE = "cast-service"
    DOCKER_MOVIE_IMAGE = "movie-service"
    DOCKER_TAG = "v${BUILD_ID}.0" // we will tag our images with the current build in order to increment the value by 1 with each new build
  }
  agent any // Jenkins will be able to select all available agents
  stages {
    stage('Docker Build'){
      parallel {
        stage('Docker Build cast service'){
          steps {
            script {
            sh '''
              docker rm -f cast-service
              docker build -t $DOCKER_ID/$DOCKER_CAST_IMAGE:$DOCKER_TAG cast-service
              sleep 6
            '''
            }
          }
        }
        stage('Docker Build movie service'){
          steps {
            script {
            sh '''
              docker rm -f movie-service
              docker build -t $DOCKER_ID/$DOCKER_MOVIE_IMAGE:$DOCKER_TAG movie-service
              sleep 6
            '''
            }
          }
        }
      }
    }
    stage('Docker Run'){
      parallel {
        stage('Docker run cast-service'){
          steps {
            script {
            sh '''
              docker run -d -p 8002:8000 --name cast-service $DOCKER_ID/$DOCKER_IMAGE:$DOCKER_TAG
              sleep 10
            '''
            }
          }
        }
        stage('Docker run movie-service'){
          steps {
            script {
            sh '''
              docker run -d -p 8001:8000 --name movie-service $DOCKER_ID/$DOCKER_IMAGE:$DOCKER_TAG
              sleep 10
            '''
            }
          }
        }
      }
    }
    stage('Docker Push') { //we pass the built image to our docker hub account
      environment {
        DOCKER_PASS = credentials("DOCKER_HUB_PASS") // we retrieve  docker password from secret text called docker_hub_pass saved on jenkins
      }
      steps {
        script {
          sh '''
            docker login -u $DOCKER_ID -p $DOCKER_PASS
            docker push $DOCKER_ID/$DOCKER_CAST_IMAGE:$DOCKER_TAG
            docker push $DOCKER_ID/$DOCKER_MOVIE_IMAGE:$DOCKER_TAG
          '''
        }
      }
    }
    stage('Deploy dev') {
      environment {
        KUBECONFIG = credentials("config") // we retrieve  kubeconfig from secret file called config saved on jenkins
      }
      steps {
        script {
          sh '''
            rm -Rf .kube
            mkdir .kube
            ls
            cat $KUBECONFIG > .kube/config
            cp fastapi/values.yaml values.yml
            sed -i "s+tag.*+tag: ${DOCKER_TAG}+g" values.yml
            cat values.yml
            helm upgrade --install app fastapi --values=values.yml --namespace dev
            PORT=$(kubectl get --namespace dev -o jsonpath="{.spec.ports[0].nodePort}" services app-fastapi)
            echo "Dev env available at http://0.0.0.0:$PORT"
          '''
        }
      }
    }
    stage('Deploy staging'){
      environment {
        KUBECONFIG = credentials("config") // we retrieve  kubeconfig from secret file called config saved on jenkins
      }
      steps {
        script {
          sh '''
            rm -Rf .kube
            mkdir .kube
            ls
            cat $KUBECONFIG > .kube/config
            cp fastapi/values.yaml values.yml
            sed -i "s+tag.*+tag: ${DOCKER_TAG}+g" values.yml
            cat values.yml
            helm upgrade --install app fastapi --values=values.yml --namespace staging
            PORT=$(kubectl get --namespace staging -o jsonpath="{.spec.ports[0].nodePort}" services app-fastapi)
            echo "Staging env available at http://0.0.0.0:$PORT"
          '''
        }
      }
    }
    stage('Deploy prod'){
      environment {
        KUBECONFIG = credentials("config") // we retrieve  kubeconfig from secret file called config saved on jenkins
      }
      steps {
        // Create an Approval Button with a timeout of 15minutes.
        // this require a manuel validation in order to deploy on production environment
        timeout(time: 15, unit: "MINUTES") {
          input message: 'Do you want to deploy in production ?', ok: 'Yes'
        }
        script {
          sh '''
            rm -Rf .kube
            mkdir .kube
            ls
            cat $KUBECONFIG > .kube/config
            cp fastapi/values.yaml values.yml
            sed -i "s+tag.*+tag: ${DOCKER_TAG}+g" values.yml
            cat values.yml
            helm upgrade --install app fastapi --values=values.yml --namespace prod
            PORT=$(kubectl get --namespace prod -o jsonpath="{.spec.ports[0].nodePort}" services app-fastapi)
            echo "Prod env available at http://0.0.0.0:$PORT"
          '''
        }
      }
    }
  }
}
