# providers.tf 파일 (최종 수정됨)

# ----------------------------------------------------
# AWS Provider 설정 (기본 리전)
# ----------------------------------------------------
# terraform {
#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "6.18.0"
#     }
#   }
# }

provider "aws" {
  region = var.region
}

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

data "aws_eks_cluster" "eks_cluster" {
  name = aws_eks_cluster.eks_cluster.name
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
# 2. Helm Provider 설정 (문법 오류 수정) 🌟 수정된 부분
# ----------------------------------------------------
provider "helm" {
  # Helm Provider는 Kubernetes Provider가 설정되어 있다면,
  # 별도의 kubernetes { ... } 블록 없이도 자동으로 인증 정보를 상속받아 사용합니다.
}