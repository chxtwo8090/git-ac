# cluster_autoscaler_iam.tf 파일 (최종 코드)

# ----------------------------------------------------
# 1-1. 기존 EKS 클러스터 정보 및 계정 정보를 참조합니다. (추가된 부분)
# ----------------------------------------------------

# AWS 계정 ID를 가져오기 위한 데이터 소스 (필수)

# ----------------------------------------------------
# 1-2. Cluster Autoscaler용 IAM 정책 정의 (필요 권한)
# ----------------------------------------------------
# AWS Cluster Autoscaler가 ASG의 크기를 조정하는 데 필요한 최소 권한
data "aws_iam_policy_document" "ca_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "ec2:DescribeLaunchTemplateVersions" # 런치 템플릿 정보 조회
    ]
    resources = ["*"]
  }
}

# IAM 정책 생성
resource "aws_iam_policy" "ca_policy" {
  name        = "EKS-ClusterAutoscaler-Policy"
  description = "EKS Cluster Autoscaler가 ASG를 관리하는 데 필요한 권한"
  policy      = data.aws_iam_policy_document.ca_policy_document.json
}

# ----------------------------------------------------
# 2. CA용 IAM 역할 및 신뢰 정책 (IRSA) 정의
# ----------------------------------------------------\r\n
# EKS 클러스터 Issuer URL 및 ARN 구성
locals {
  # OIDC Provider URL에서 'https://' 부분을 제거합니다.
  oidc_issuer_ca = trimsuffix(aws_eks_cluster.eks_cluster.identity[0].oidc[0].issuer, "https://")
  # OIDC Provider ARN을 직접 구성합니다.
  oidc_arn_ca    = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.oidc_issuer_ca}"
}

# CA용 IAM 역할의 신뢰 정책 (Trust Policy)
data "aws_iam_policy_document" "ca_assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      # CA Pod가 kube-system 네임스페이스의 'cluster-autoscaler' Service Account를 사용할 때만 허용
      variable = "${local.oidc_issuer_ca}:sub" 
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }

    principals {
      identifiers = [local.oidc_arn_ca]
      type        = "Federated"
    }
  }
}

# CA용 IAM 역할 생성
resource "aws_iam_role" "ca_role" {
  name               = "EKS-ClusterAutoscaler-Role"
  assume_role_policy = data.aws_iam_policy_document.ca_assume_role.json
}

# ----------------------------------------------------\r\n# 3. 역할과 정책 연결\r\n# ----------------------------------------------------\r\nresource "aws_iam_role_policy_attachment" "ca_policy_attach" {\r\n  policy_arn = aws_iam_policy.ca_policy.arn\r\n  role       = aws_iam_role.ca_role.name\r\n}