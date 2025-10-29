# providers.tf 파일 (Kubeconfig 경로를 사용하도록 강제 수정)

# ----------------------------------------------------
# EKS 클러스터 인증을 위한 Data Source (CI에서 사용하지 않으므로 주석 처리)
# ----------------------------------------------------
/*
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
*/


# ----------------------------------------------------
# 1. Kubernetes Provider 설정 (✅ Kubeconfig 파일 경로 사용)
# ----------------------------------------------------\
provider "kubernetes" {
  # ❌ Data Source를 통한 인증 방식 대신 Kubeconfig 파일 경로를 사용합니다.
  # host                   = data.aws_eks_cluster.eks_cluster.endpoint
  # cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  # token                  = data.aws_eks_cluster_auth.eks_auth.token
  
  # ✅ CI 스크립트에서 생성한 Kubeconfig 파일 경로를 변수로 받아 사용합니다.
  config_path = var.kubeconfig_path
}

# ----------------------------------------------------\
# 2. Helm Provider 설정 (Kubernetes Provider 설정을 상속 받음)
# ----------------------------------------------------\
provider "helm" {
  # 빈 블록을 유지하여 Kubernetes Provider의 설정을 상속받도록 합니다.
}