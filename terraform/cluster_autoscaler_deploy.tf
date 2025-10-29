# cluster_autoscaler_deploy.tf 파일 (최종적으로 이렇게만 남아야 합니다)

# -------------------------------------------------------------------------
# 1. Cluster Autoscaler (CA) Helm Chart 배포 (표준 Helm Provider 사용)
# -------------------------------------------------------------------------
resource "helm_release" "cluster_autoscaler" {
  count = var.deploy_k8s ? 1 : 0
  name       = "cluster-autoscaler"
  repository = "https://kubernetes.github.io/autoscaler"
  chart      = "cluster-autoscaler"
  namespace  = "kube-system"
  version    = "9.36.0"

  values = [
    templatefile("${path.module}/templates/cluster-autoscaler-values.yaml", {
      cluster_name = aws_eks_cluster.eks_cluster.name
      region       = var.region
    })
  ]

  set = [
    { name = "image.tag", value = "v1.34.0" },
    { name = "rbac.create", value = "true" },
  { name = "aws.clusterName", value = aws_eks_cluster.eks_cluster.name },
    { name = "serviceAccount.create", value = "true" },
    { name = "serviceAccount.name", value = "cluster-autoscaler" },
    { name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn", value = aws_iam_role.ca_role.arn } 
  ]

    depends_on = [
    aws_eks_cluster.eks_cluster,
      data.aws_eks_cluster_auth.eks_auth,
      aws_eks_node_group.eks_worker_group,
  ]
}