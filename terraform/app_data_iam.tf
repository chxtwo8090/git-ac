# app_data_iam.tf 파일 (최종 코드)

# ----------------------------------------------------
# 0. EKS 클러스터 정보 및 계정 정보 참조 (수정 및 추가된 부분)
# ----------------------------------------------------

# ----------------------------------------------------
# 1. 애플리케이션용 IAM 정책 정의
# ----------------------------------------------------

# 데이터베이스(DynamoDB) 및 이미지 저장소(ECR) 접근에 필요한 권한
data "aws_iam_policy_document" "app_access_policy_document" {
  # 1-1. DynamoDB 접근 권한 (읽기/쓰기/업데이트/삭제)
  statement {
    effect = "Allow"
    actions = [
      "dynamodb:PutItem",
      "dynamodb:GetItem",
      "dynamodb:UpdateItem",
      "dynamodb:DeleteItem",
      "dynamodb:Query",
      "dynamodb:Scan"
    ]
    resources = [
      "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/Financial-Analysis-Results",
      "arn:aws:dynamodb:${var.region}:${data.aws_caller_identity.current.account_id}:table/Financial-Analysis-Results/index/*"
    ]
  }

  # 1-2. ECR 이미지 Pull 권한 (모든 리전에 대한 ECR 권한)
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
    ]
    resources = ["*"]
  }
}

resource "aws_iam_policy" "app_access_policy" {
  name        = "EKS-App-Data-Access-Policy"
  description = "EKS 앱이 DynamoDB 및 ECR에 접근하는 데 필요한 권한"
  policy      = data.aws_iam_policy_document.app_access_policy_document.json
}


# ----------------------------------------------------
# 2. 앱용 IAM 역할 및 신뢰 정책 (IRSA) 정의
# ----------------------------------------------------

# EKS 클러스터 Issuer URL 및 ARN 구성
locals {
  # OIDC Provider URL에서 'https://' 부분을 제거합니다.
  # EKS 클러스터 리소스의 OIDC issuer를 사용
  oidc_issuer_app = trimsuffix(aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://") 
  oidc_arn_app    = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_issuer_app}"
}

# 앱용 IAM 역할의 신뢰 정책 (Trust Policy)
data "aws_iam_policy_document" "app_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_issuer_app}:sub" 
      values   = ["system:serviceaccount:default:app-service-account"]
    }

    principals {
      identifiers = [local.oidc_arn_app]
      type        = "Federated"
    }
  }
}

# 앱용 IAM 역할 생성
resource "aws_iam_role" "app_access_role" {
  name               = "EKS-App-Data-Access-Role"
  assume_role_policy = data.aws_iam_policy_document.app_assume_role.json
}

# ----------------------------------------------------\r\n# 3. 역할과 정책 연결\r\n# ----------------------------------------------------\r\nresource "aws_iam_role_policy_attachment" "app_policy_attach" {\r\n  policy_arn = aws_iam_policy.app_access_policy.arn\r\n  role       = aws_iam_role.app_access_role.name\r\n}