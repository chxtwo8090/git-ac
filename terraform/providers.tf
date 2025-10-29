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
# 2. Helm Provider 설정 (Kubeconfig 파일 경로 명시) ⬅️ CRITICAL FIX
# ----------------------------------------------------
provider "helm" {
  # 💡 수정: Helm Provider가 Kubeconfig 파일을 찾도록 명시적으로 경로 지정
  kubernetes {
    config_path = var.kubeconfig_path
  }
}