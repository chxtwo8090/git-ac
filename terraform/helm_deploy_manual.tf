# helm_deploy_manual.tf 파일 (최종 코드)

# ----------------------------------------------------
# 데이터 소스: 기존에 생성된 리소스 참조 (data 블록은 제거/주석 처리)
# ----------------------------------------------------
/*
data "aws_iam_role" "alb_role_data" {
  name = "ALB-Ingress-Controller-Role"
}
*/

# -------------------------------------------------------------------------
# 2. ALB Ingress Controller (ALB) null_resource를 이용한 우회 배포
# -------------------------------------------------------------------------
resource "null_resource" "alb_controller_deploy_manual" {
  # CA 배포가 완료된 후에 실행되도록 의존성 설정
  depends_on = [
    null_resource.cluster_autoscaler_deploy_manual,
  ]

  provisioner "local-exec" {
    interpreter = ["bash", "-c"]

    # Kubernetes Provider의 인증 실패를 우회하기 위해 셸에서 직접 helm 명령 실행
    # 🌟 KUBECONFIG 환경 변수를 Windows 경로(이스케이프 처리)로 설정하고 IRSA ARN을 resource에서 참조하도록 수정
    command = "export PATH=$PATH:/c/Users/user/Desktop/windows-amd64 && export KUBECONFIG='C:\\\\Users\\\\user\\\\.kube\\\\config' && helm repo add aws-load-balancer-controller https://aws.github.io/eks-charts --force-update && helm upgrade --install aws-load-balancer-controller aws-load-balancer-controller/aws-load-balancer-controller --namespace kube-system --version \"1.7.1\" --set \"clusterName=${data.aws_eks_cluster.eks_cluster_data.name}\" --set \"serviceAccount.create=true\" --set \"serviceAccount.name=aws-load-balancer-controller\" --set \"serviceAccount.annotations.eks\\\\.amazonaws\\\\.com/role-arn=${aws_iam_role.alb_ingress_role.arn}\" --set \"awsRegion=${var.region}\" --set \"awsVpcID=${var.vpc_id}\" --wait" 
  }
}