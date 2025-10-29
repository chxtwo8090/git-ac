# alb_controller_deploy.tf 최종 코드

# ----------------------------------------------------
# 데이터 소스: 기존에 생성된 리소스 참조
# ----------------------------------------------------
/*
# ALB용 IAM 역할 ARN을 참조합니다. (alb_iam.tf 에서 생성됨)
data "aws_iam_role" "alb_role_data" {
  name = "ALB-Ingress-Controller-Role"
}
*/
# NOTE: aws_eks_cluster_data와 aws_eks_cluster_auth는 
#       providers.tf에 정의되어 있으므로 여기서는 정의하지 않고 참조만 합니다.

# ----------------------------------------------------
# 1. ALB Ingress Controller Helm Chart 배포
# ----------------------------------------------------
# WARNING: 이전 단계에서 null_resource를 통해 배포에 성공했으므로, 
# 실패를 유발하는 이 helm_release 리소스는 제거되었습니다.

# resource "helm_release" "aws_load_balancer_controller" {
#   name       = "aws-load-balancer-controller"
#   repository = "https://aws.github.io/eks-charts"
#   chart      = "aws-load-balancer-controller"
#   namespace  = "kube-system"
#   version    = "1.7.1"
# 
#   # IRSA 활성화 및 IAM 역할 연결 (리스트 형식의 set 인자)
#   set = [
#     { name = "clusterName", value = data.aws_eks_cluster.eks_cluster_data.name },
#     { name = "serviceAccount.create", value = "true" },
#     { name = "serviceAccount.name", value = "aws-load-balancer-controller" },
#     { name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn", value = data.aws_iam_role.alb_role_data.arn },
#     { name = "awsRegion", value = var.region },
#     { name = "awsVpcID", value = var.vpc_id }
#   ]
# 
#   depends_on = [
#     aws_eks_cluster.eks_cluster,
#     null_resource.cluster_autoscaler_deploy_manual,
#   ]
# }