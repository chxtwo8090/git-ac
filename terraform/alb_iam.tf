# alb_iam.tf 파일 (변경 없음, 최종 코드)

 # ----------------------------------------------------
 # 1. EKS 클러스터(이 리포지토리에서 생성되는 리소스)를 참조합니다.
 # ----------------------------------------------------

# AWS 계정 ID를 가져오기 위한 데이터 소스 (필수)
data "aws_caller_identity" "current" {}


# ----------------------------------------------------
# 2. ALB Ingress Controller용 IAM 정책 정의 (OIDC Provider 참조 우회)
# ----------------------------------------------------

# EKS 클러스터 Issuer URL 구성
locals {
  # EKS 클러스터 리소스의 OIDC issuer를 사용합니다.
  oidc_issuer = trimsuffix(aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://")
  # OIDC Provider ARN을 직접 구성합니다.
  oidc_arn    = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_issuer}"
}


data "aws_iam_policy_document" "alb_ingress_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      # OIDC Provider URL을 직접 참조합니다.
      variable = "${local.oidc_issuer}:sub" 
      
      values = ["system:serviceaccount:kube-system:aws-load-balancer-controller"]
    }

    principals {
      identifiers = [local.oidc_arn]
      type        = "Federated"
    }
  }
}


# ----------------------------------------------------\r\n# 3. ALB Ingress Controller용 IAM 역할 및 정책 연결\r\n# ----------------------------------------------------\r\n
# 3-1. IAM 역할 생성 (Service Account에 연결될 역할)
resource "aws_iam_role" "alb_ingress_role" {
  name               = "ALB-Ingress-Controller-Role"
  assume_role_policy = data.aws_iam_policy_document.alb_ingress_assume_role.json
}

# 3-2. AWS 공식 ALB Policy 다운로드 및 연결 
resource "aws_iam_policy" "alb_ingress_controller_policy" {
  name        = "ALB-Ingress-Controller-Policy"
  description = "AWS Load Balancer Controller에 필요한 권한"
  
  # 정책 내용은 iam-policy-alb-ingress-controller.json 파일에서 가져옵니다.
  policy = file("iam-policy-alb-ingress-controller.json") 
}

# 3-3. 역할과 정책 연결
resource "aws_iam_role_policy_attachment" "alb_ingress_policy_attach" {
  policy_arn = aws_iam_policy.alb_ingress_controller_policy.arn
  role       = aws_iam_role.alb_ingress_role.name
}