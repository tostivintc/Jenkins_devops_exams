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
        stage('Cast service'){
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
        stage('Movie service'){
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
        stage('Cast service'){
          steps {
            script {
            sh '''
              docker run -d -p 8002:8000 --name cast-service $DOCKER_ID/$DOCKER_CAST_IMAGE:$DOCKER_TAG
              sleep 10
            '''
            }
          }
        }
        stage('Movie service'){
          steps {
            script {
            sh '''
              docker run -d -p 8001:8000 --name movie-service $DOCKER_ID/$DOCKER_MOVIE_IMAGE:$DOCKER_TAG
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
    stage('Deploy') {
      parallel {
        stage('Deploy dev') {
          environment {
            KUBECONFIG = credentials("config")
            PORT=31000
          }
          steps {
            script {
              sh '''
                rm -Rf .kube
                mkdir .kube
                cat $KUBECONFIG > .kube/config
                helm upgrade --install app charts --namespace dev --set service.nodePort=$PORT --set image.tag="${DOCKER_TAG}"
                echo "Dev env available at http://0.0.0.0:$PORT"
              '''
            }
          }
        }
        stage('Deploy staging'){
          environment {
            KUBECONFIG = credentials("config")
            PORT=31001
          }
          steps {
            script {
              sh '''
                rm -Rf .kube
                mkdir .kube
                cat $KUBECONFIG > .kube/config
                helm upgrade --install app charts --namespace staging --set service.nodePort=$PORT --set image.tag="${DOCKER_TAG}"
                echo "Staging env available at http://0.0.0.0:$PORT"
              '''
            }
          }
        }
        stage('Deploy QA'){
          environment {
            KUBECONFIG = credentials("config")
            PORT=31002
          }
          steps {
            script {
              sh '''
                rm -Rf .kube
                mkdir .kube
                cat $KUBECONFIG > .kube/config
                helm upgrade --install app charts --namespace qa --set service.nodePort=$PORT --set image.tag="${DOCKER_TAG}""
                echo "QA env available at http://0.0.0.0:$PORT"
              '''
            }
          }
        }
      }
    }
    stage('Deploy prod'){
      environment {
        KUBECONFIG = credentials("config")
        PORT=31003
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
            cat $KUBECONFIG > .kube/config
                helm upgrade --install app charts --namespace prod --set service.nodePort=$PORT --set image.tag="${DOCKER_TAG}""
            echo "Prod env available at http://0.0.0.0:$PORT"
          '''
        }
      }
    }
  }
}
