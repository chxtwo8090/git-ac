# ----------------------------------------------------
# 데이터 소스: 기존에 생성된 리소스 참조
# ----------------------------------------------------

# VPC에 생성된 프라이빗 서브넷 ID 목록을 가져옵니다.
# 주의: 이 데이터 소스는 이전에 vpc_main.tf에 정의된 'aws_subnet.private' 리소스의
# 출력값을 사용합니다. (실제 프로젝트에서는 output을 사용하거나 이름을 통해 검색할 수 있음)
# 여기서는 간단하게 변수를 통해 입력받는다고 가정합니다.
# 실제로는 vpc_main.tf 파일에 output을 정의하고 참조하는 것이 좋습니다.

variable "eks_cluster_name" {
  description = "생성할 EKS 클러스터의 이름"
  type        = string
  default     = "eks-project-cluster"
}

variable "private_subnet_ids" {
  description = "EKS 클러스터가 사용할 프라이빗 서브넷 ID 목록"
  type        = list(string)
  # 이 값은 실제 환경에 맞게 [subnet-01c8359c671e478dd, 다른_프라이빗_서브넷_ID] 식으로 설정해야 합니다.
  # 현재는 하나의 ID만 알고 있으므로 예시로 작성합니다.
  default     = ["subnet-01c8359c671e478dd"] 
}
/*
# 기존에 생성된 IAM 역할 ARN을 데이터 소스로 가져옵니다.
data "aws_iam_role" "eks_cluster_role_data" {
  name = "EKS-Cluster-Role-for-Project"
}
*/
/*
data "aws_iam_role" "eks_node_role_data" {
  name = "EKS-Worker-Node-Role-for-Project"
}
*/
# ----------------------------------------------------
# 1. EKS 클러스터 (Control Plane) 정의
# ----------------------------------------------------
resource "aws_eks_cluster" "eks_cluster" {
  name     = var.eks_cluster_name
  role_arn = aws_iam_role.eks_cluster_role.arn
  version  = "1.34" # 최신 안정화 버전으로 설정 (필요에 따라 변경 가능)

  vpc_config {
    # 클러스터 엔드포인트는 프라이빗 서브넷에 연결
  subnet_ids         = aws_subnet.private[*].id
    # 엔드포인트 접근 설정 (Public, Private 모두 활성화)
    endpoint_public_access  = true
    endpoint_private_access = true
  }

  depends_on = [
    aws_iam_role_policy_attachment.eks_cluster_policy,
    aws_iam_role_policy_attachment.eks_cluster_vpc_policy,
  ]
  
  tags = {
    Name = var.eks_cluster_name
  }
}

# ----------------------------------------------------
# 2. EKS 관리형 노드 그룹 (EC2 기반 워커 노드 연결)
# ----------------------------------------------------
resource "aws_eks_node_group" "eks_worker_group" {
  cluster_name    = aws_eks_cluster.eks_cluster.name
  node_group_name = "t3-small-node-group"
  node_role_arn   = aws_iam_role.eks_node_role.arn
  subnet_ids      = aws_subnet.private[*].id
  instance_types  = ["t3.small"] # 요구사항 반영
  ami_type        = "AL2023_x86_64_STANDARD" # Amazon Linux 2 AMI 사용

  scaling_config {
    desired_size = 2 # 시작 시 노드 2개
    min_size     = 1
    max_size     = 4 # Auto Scaling을 위한 최대 크기
  }

  # 노드 그룹 생성 시 클러스터 보안 그룹을 참조하여 통신을 허용
  # 기존에 생성한 EC2 인스턴스가 아닌, 이 Node Group이 관리하는 인스턴스입니다.
  remote_access {
    ec2_ssh_key = var.key_name
    # SSH는 기존에 만든 보안 그룹을 사용하는 것이 좋지만,
    # 여기서는 EKS의 관리형 노드 그룹에 맞는 방식을 따릅니다.
    # source_security_group_ids = [aws_security_group.eks_node_sg.id] # 필요시 주석 해제
  }

  depends_on = [
    aws_eks_cluster.eks_cluster,
  ]
}

# ----------------------------------------------------
# 3. 출력값 (kubectl 연결 정보)
# ----------------------------------------------------
output "eks_cluster_name" {
  value = aws_eks_cluster.eks_cluster.name
}

output "kubeconfig_command" {
  description = "kubectl을 클러스터에 연결하기 위한 명령어"
  value = "aws eks update-kubeconfig --region ${var.region} --name ${aws_eks_cluster.eks_cluster.name}"
}