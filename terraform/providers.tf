# providers.tf 파일 (수정된 전체 코드)

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
# 1. Kubernetes Provider 설정 (Kubeconfig 파일 경로 사용으로 변경)
# ----------------------------------------------------
provider "kubernetes" {
  # ❌ 기존 Data Source를 통한 인증 정보는 CI/CD 환경에서 Apply 단계에 불안정할 수 있으므로 주석 처리합니다.
  # host                   = data.aws_eks_cluster.eks_cluster.endpoint
  # cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  # token                  = data.aws_eks_cluster_auth.eks_auth.token
  
  # ✅ CI 스크립트에서 생성한 Kubeconfig 파일 경로를 변수로 받아 사용합니다.
  config_path = var.kubeconfig_path
}

# ----------------------------------------------------
# 2. Helm Provider 설정 (Kubernetes Provider 설정을 상속 받음)
# ----------------------------------------------------
provider "helm" {
  # 빈 블록을 유지하여 Kubernetes Provider의 설정을 상속받도록 합니다.
  # Kubeconfig 경로는 kubernetes provider에 설정되었으므로 추가 설정은 불필요합니다.
}