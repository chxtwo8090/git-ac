# helm_deploy_manual.tf 파일 (ALB Ingress Controller 수정 완료)

# ----------------------------------------------------
# 1. ALB Ingress Controller Helm Chart 배포 (VPC ID 명시적 전달)
# ----------------------------------------------------
resource "helm_release" "alb_controller" {
  count = var.deploy_k8s ? 1 : 0
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.1"

  # 🌟 CRITICAL FIX: VPC ID와 Region을 values 블록을 통해 명시적으로 전달합니다.
  values = [
    templatefile("${path.module}/templates/alb-controller-values.yaml", {
      cluster_name = aws_eks_cluster.eks_cluster.name
      region       = var.region
      vpc_id       = aws_vpc.eks_vpc.id
      alb_role_arn = aws_iam_role.alb_ingress_role.arn
    })
  ]
  # -----------------------------------------------------------------------------

  set = [
    # clusterName은 values 블록에서 전달되므로 set에서 제거합니다.
    { name = "serviceAccount.create", value = "true" },
    { name = "serviceAccount.name", value = "aws-load-balancer-controller" },
    # IRSA ARN은 annotation으로 명시적으로 설정하여 ServiceAccount에 연결합니다.
    { name = "serviceAccount.annotations.eks\\\\.amazonaws\\\\.com/role-arn", value = aws_iam_role.alb_ingress_role.arn },
    # ❌ awsRegion, awsVpcID는 values 블록으로 이동했으므로 제거합니다.
  ]

  wait    = true
  timeout = 600
  force_update = true # 릴리스 상태 오류 방지 (이전 수정)

  depends_on = [
    helm_release.cluster_autoscaler[0]
  ]
}