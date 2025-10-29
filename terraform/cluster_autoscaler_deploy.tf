# cluster_autoscaler_deploy.tf 파일 (최종 코드)

# ----------------------------------------------------
# 데이터 소스: 기존에 생성된 리소스 참조 (data 블록은 제거/주석 처리)
# ----------------------------------------------------
/*
data "aws_iam_role" "ca_role_data" {
  name = "EKS-ClusterAutoscaler-Role"
}
*/
# NOTE: aws_eks_cluster_data와 aws_eks_cluster_auth는 
#       providers.tf에 정의되어 있으므로 여기서는 정의하지 않고 참조만 합니다.

# -------------------------------------------------------------------------
# 1. Cluster Autoscaler (CA) null_resource를 이용한 우회 배포
# -------------------------------------------------------------------------

# Kubernetes Provider의 인증 실패를 우회하기 위한 null_resource
resource "null_resource" "cluster_autoscaler_deploy_manual" {
  # EKS 인증 토큰이 확보된 후에 실행되도록 의존성 설정
  depends_on = [
    data.aws_eks_cluster_auth.eks_auth,
    aws_eks_cluster.eks_cluster // 클러스터가 준비될 때까지 기다림
  ]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"] 

    command = <<-EOT
      # 🌟 1. Helm 실행 파일 PATH 추가 및 KUBECONFIG 환경 변수를 Windows 경로로 설정
      export PATH=$PATH:/c/Users/user/Desktop/windows-amd64 && export KUBECONFIG='C:\\Users\\user\\.kube\\config'
      export PATH=$PATH:/c/Program\ Files/Amazon/AWSCLIV2
      
      # 2. Cluster Autoscaler Helm Repo 추가 및 업데이트
      helm repo add autoscaler https://kubernetes.github.io/autoscaler --force-update
      
      # 3. Cluster Autoscaler 배포 명령어 (IRSA ARN을 resource에서 참조하도록 수정)
      helm upgrade --install cluster-autoscaler autoscaler/cluster-autoscaler --namespace kube-system --version "9.36.0" --set "image.tag=v1.34.0" --set "rbac.create=true" --set "aws.clusterName=eks-project-cluster" --set "serviceAccount.create=true" --set "serviceAccount.name=cluster-autoscaler" --set "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn=${aws_iam_role.ca_role.arn}" --set-file "values=./templates/cluster-autoscaler-values.yaml" --wait
    EOT
  }
}