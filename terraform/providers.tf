# providers.tf 파일 (최종적으로 수정된 코드)

# ----------------------------------------------------
# EKS 클러스터 인증을 위한 Data Source
# ----------------------------------------------------
data "aws_eks_cluster_auth" "eks_auth" {
  # 클러스터 이름은 변수로 받아 사용합니다 (eks_cluster.tf의 var.eks_cluster_name)
  name = var.eks_cluster_name
  # Data Source가 클러스터 생성을 기다리도록 의존성 추가
  depends_on = [
    aws_eks_cluster.eks_cluster
  ]
}


# ----------------------------------------------------
# 1. Kubernetes Provider 설정 (EKS 인증 정보 명시)
# ----------------------------------------------------
provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks_cluster.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks_cluster.certificate_authority[0].data)
  token                  = data.aws_eks_cluster_auth.eks_auth.token
}

# ----------------------------------------------------
# 2. Helm Provider 설정 (빈 블록으로 복구)
# ----------------------------------------------------
provider "helm" {
  # 빈 블록으로 유지하여 Kubernetes Provider 설정을 상속하도록 시도합니다.
}