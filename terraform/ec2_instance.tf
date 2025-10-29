# ec2_instance.tf 파일 (수정됨)

# ----------------------------------------------
# 1. EKS 워커 노드용 인스턴스 프로파일 정의 🌟 추가된 부분
# ----------------------------------------------
resource "aws_iam_instance_profile" "eks_worker_profile" {
  name = "EKS-Worker-Node-Profile-for-Project"
  # iam_roles.tf에 정의된 역할을 참조합니다.
  role = aws_iam_role.eks_node_role.name 
}

# ----------------------------------------------
# 2. AWS Amazon Linux AMI (EC2 인스턴스)
# ----------------------------------------------

# 데이터 소스: 최신 Amazon Linux 2023 AMI ID를 동적으로 가져옴
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]

  filter {
    name   = "name"
    # Amazon Linux 2023 (AL2023) 이미지를 필터링합니다.
    values = ["al2023-ami-2023.*-kernel-6.1-x86_64"]
  }

  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
}

resource "aws_instance" "eks_worker_instance" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = "t3.small"
  subnet_id     = aws_subnet.private[0].id
  key_name      = var.key_name
  
  # 🌟 CRITICAL FIX: IAM 인스턴스 프로파일 연결
  iam_instance_profile = aws_iam_instance_profile.eks_worker_profile.name 
  
  # 보안 그룹 연결
  vpc_security_group_ids = [
    aws_security_group.eks_node_sg.id
  ]
  
  # 인스턴스는 워커 노드로 사용될 것이므로 공개 IP는 필요 없음
  associate_public_ip_address = false 

  tags = {
    Name = "EKS-Worker-T3-Small-Test-Instance"
    # EKS 노드로 작동할 수 있도록 태그를 추가합니다.
    "kubernetes.io/cluster/eks-project-cluster" = "owned"
  }
}