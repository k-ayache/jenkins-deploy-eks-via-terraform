#!groovy

import com.cloudbees.plugins.credentials.impl.*;
import com.cloudbees.plugins.credentials.*;
import com.cloudbees.plugins.credentials.domains.*;
import org.jenkinsci.plugins.plaincredentials.*
import org.jenkinsci.plugins.plaincredentials.impl.*
import com.cloudbees.plugins.credentials.common.*
import com.cloudbees.jenkins.plugins.awscredentials.AWSCredentialsImpl
import hudson.util.Secret
import org.jenkinsci.plugins.plaincredentials.impl.FileCredentialsImpl
import java.nio.file.*


def secret = '''Hi
there,
only
test'''

//echo secret.getByte()

def secretBytes = SecretBytes.fromBytes(secret.getBytes())
def credentials = new FileCredentialsImpl(CredentialsScope.GLOBAL, 'my test file', 'description', 'file.txt', secretBytes)

SystemCredentialsProvider.instance.store.addCredentials(Domain.global(), credentials)



def add_kubeconfig(){
echo "$pwd $pwd $pwd"
echo "hi"
Path fileLocation = Paths.get("./vpc.tf");
//home/jenkins/agent/workspace/terraform_eks_pipeline/vpc.tf");
def secretBytes = SecretBytes.fromBytes(Files.readAllBytes(fileLocation))
Credentials secretText = FileCredentialsImpl(CredentialsScope.GLOBAL,"my-id3", "My description", "vpc.tf", secretBytes )

SystemCredentialsProvider.instance.store.addCredentials(Domain.global(), secretText)
}




def add_creds (){
  Credentials myawscreds = (Credentials) new AWSCredentialsImpl( CredentialsScope.GLOBAL,"myawfdfdfds","my-accesfdfdfds-key","sfdfdecret", "My desfddddddddddddddddddddddddddcription" )
  SystemCredentialsProvider.getInstance().getStore().addCredentials(Domain.global(), myawscreds)
}

//def add_kubeconfig (kubeconfigSource){ 
//  Credentials myawscreds = (Credentials) new KubeconfigCredentials(com.cloudbees.plugins.credentials.CredentialsScope scope, "id-kubeconfig", "description ggggg", kubeconfigSource)
//  SystemCredentialsProvider.getInstance().getStore().addCredentials(Domain.global(), myawscreds)
//}

//add_kubeconfig("/home/jenkins/agent/workspace/terraform_eks_pipeline")

pipeline {

   parameters {
    choice(name: 'action', choices: 'create\ndestroy', description: 'Create/update or destroy the eks cluster.')
    string(name: 'cluster', defaultValue : 'dev', description: "EKS cluster name;eg demo creates cluster named eks-demo.")
    string(name: 'credential', defaultValue : 'aws-cred', description: "Jenkins credential that provides the AWS access key and secret.")
//    string(name: 'region', defaultValue : 'us-west-2', description: "AWS region.")
  }

  options {
    disableConcurrentBuilds()
    timeout(time: 1, unit: 'HOURS')
    withAWS(credentials: params.credential, region: params.region)
//    ansiColor('xterm')
  }

  agent {
    kubernetes {
      label 'app'
      defaultContainer 'jnlp'
      yaml """ 
          apiVersion: v1
          kind: Pod
          metadata:
            labels:
              component: ci
          spec:
            serviceAccount: jenkins
            containers:
              - name: docker
                image: karima/repository:ubuntu-jenkins
                imagePullPolicy: Always
                command:
                  - cat
                tty: true                
                volumeMounts:
                  - name: dockersock
                    mountPath: /var/run/docker.sock
                  - name: daemon
                    mountPath: /etc/docker/daemon.json 
            volumes:
            - name: dockersock
              hostPath:
                path: /var/run/docker.sock
            - name: daemon
              hostPath:
                path:  /etc/docker/daemon.json               
        """
    }   
  }

  stages {

    stage('Setup') {
      steps {
        container('docker') {
          script {
            currentBuild.displayName = "#" + env.BUILD_NUMBER + " " + params.action + " eks-" + params.cluster
            plan = params.cluster + '.plan'
          }
        }
      }
    }

    stage('TF Plan') {
      when {
        expression { params.action == 'create' }
      }
      steps {
        container('docker') {
          script {
            withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
              credentialsId: params.credential, 
              accessKeyVariable: 'AWS_ACCESS_KEY_ID',  
              secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {

              sh """            
                #terraform init
                #terraform plan -var-file=${params.cluster}.tfvars \
                  -out ${plan}
              """
            }
          }
        }
      }
    }

    stage('TF Apply') {
      when {
        expression { params.action == 'create' }
      }
      steps {
        container('docker') {
          script {
            //input "Create/update Terraform stack eks-${params.cluster} in aws?yes/no" 
             withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
              credentialsId: params.credential, 
              accessKeyVariable: 'AWS_ACCESS_KEY_ID',  
              secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
  
              sh """
                #terraform apply -input=false ${plan}
                #terraform output -json | jq -r '.kubeconfig.value' > kubeconfig
                # push kubeconfig to credentials jenkins to be used by other pipelines
                pwd
              """
            }
            dir ("/home/jenkins/agent/workspace/terraform_eks_pipeline")
            echo "yes"
            add_kubeconfig()
          }
        }
      }
    }
    // call multiple pipelines in parallel! to deploy all applications in k8s (grafana, prometheus, loki ....) 
    stage ('Configure and deploy apps') {
        // use another image container to deploy in k8s
//       paralel {
//           stage {
      steps {
//        container('docker') {
          // pass in parameters eks name, aws-cred,environement, kubeconfig
          build job: 'test-kubectl', parameters: [
            string(name: 'aws-cred', value: params.credential)
          ]
//        }
// } end stage paralel
// end paralel
      }
    }


    stage('TF Destroy') {
      when {
        expression { params.action == 'destroy' }
      }
      steps {
        container('docker') {
          script {
          //  input "Destroy Terraform stack eks-${params.cluster} in aws? yes/no" 
  
            withCredentials([[$class: 'AmazonWebServicesCredentialsBinding', 
              credentialsId: params.credential, 
              accessKeyVariable: 'AWS_ACCESS_KEY_ID',  
              secretKeyVariable: 'AWS_SECRET_ACCESS_KEY']]) {
  
              sh """
                terraform destroy -auto-approve
              """
            }
          }
        }
      }
    }

  }

}
