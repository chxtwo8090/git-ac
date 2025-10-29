# providers.tf 파일 (최종 수정 코드)

# ----------------------------------------------------
# EKS 클러스터 인증을 위한 Data Source (유지)
# ----------------------------------------------------
data "aws_eks_cluster_auth" "eks_auth" {
   name = var.eks_cluster_name
   depends_on = [
    aws_eks_cluster.eks_cluster
  ]
}

data "aws_eks_cluster" "eks_cluster" {
  name = aws_eks_cluster.eks_cluster.name
  depends_on = [
    aws_eks_cluster.eks_cluster
  ]
}


# ----------------------------------------------------
# 1. Kubernetes Provider 설정 (Kubeconfig 파일 경로 사용)
# ----------------------------------------------------
provider "kubernetes" {
  # CI 스크립트에서 생성한 Kubeconfig 파일 경로를 변수로 받아 사용합니다.
  config_path = var.kubeconfig_path
}

# ----------------------------------------------------
# 2. Helm Provider 설정 (HCL 구문 수정) ⬅️ CRITICAL FIX
# ----------------------------------------------------
provider "helm" {
  # 💡 수정된 부분: 'kubernetes'를 블록({}) 대신 인자(attribute, =)로 정의
  kubernetes = {
    config_path = var.kubeconfig_path
  }
}