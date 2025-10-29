# helm_deploy_manual.tf 파일 (최종적으로 이렇게만 남아야 합니다)

# ----------------------------------------------------
# 1. ALB Ingress Controller Helm Chart 배포 (표준 Helm Provider 사용)
# ----------------------------------------------------
resource "helm_release" "alb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  version    = "1.7.1"

  set = [
    { name = "clusterName", value = data.aws_eks_cluster.eks_cluster.name },
    { name = "serviceAccount.create", value = "true" },
    { name = "serviceAccount.name", value = "aws-load-balancer-controller" },
    { name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn", value = aws_iam_role.alb_ingress_role.arn },
    { name = "awsRegion", value = var.region },
    { name = "awsVpcID", value = var.vpc_id },
  ]
  
  wait = true

  depends_on = [
    helm_release.cluster_autoscaler
  ]
}