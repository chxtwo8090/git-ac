# cluster_autoscaler_deploy.tf 파일 (최종적으로 이렇게만 남아야 합니다)

# -------------------------------------------------------------------------
# 1. Cluster Autoscaler (CA) Helm Chart 배포 (표준 Helm Provider 사용)
# -------------------------------------------------------------------------
resource "helm_release" "cluster_autoscaler" {
  count = var.deploy_k8s ? 1 : 0 # deploy_k8s 변수가 true일 때만 실행
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
  
  wait    = true  # Pod가 Ready가 될 때까지 기다리도록 설정하는 것이 좋습니다.
  timeout = 600   # 대기 시간을 10분으로 설정
  force_update = true
  # 💡 수정된 부분: 더 이상 필요 없는 data.aws_eks_cluster_auth.eks_auth 의존성 제거
  depends_on = [
    aws_eks_cluster.eks_cluster, # EKS 클러스터 생성이 완료될 때까지 기다립니다.
    aws_iam_role.ca_role         # CA용 IAM 역할 생성이 완료될 때까지 기다립니다.
  ]
}