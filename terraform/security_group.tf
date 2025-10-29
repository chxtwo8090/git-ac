# ----------------------------------------------
# 1. EC2/EKS 노드 보안 그룹
# ----------------------------------------------

resource "aws_security_group" "eks_node_sg" {
  name        = "eks-worker-node-sg"
  description = "eks-worker-node-group"
  vpc_id      = aws_vpc.eks_vpc.id

  # 인바운드 규칙: SSH 접속 허용
  ingress {
    description = "Allow SSH Access for Management"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # 주의: 실제 프로덕션 환경에서는 특정 IP로 제한해야 함
  }

  # 🚀 인바운드 규칙: NodePort 범위 허용 (ALB 헬스 체크 및 통신용)
  # EKS 클러스터가 위치한 VPC 내부 CIDR (10.0.0.0/16)에서 
  # NodePort 범위(30000-32767)를 허용하는 것이 핵심입니다.
  ingress {
    description = "Allow NodePort range from VPC for ALB Health Check"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    # VPC CIDR 블록은 vpc_main.tf에 정의된 "10.0.0.0/16"을 가정하고 적용합니다.
    cidr_blocks = ["10.0.0.0/16"] 
  }

  # 아웃바운드 규칙: 모든 트래픽 허용 (노드가 외부 인터넷에 접근하여 이미지 다운로드 등)
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1" # 모든 프로토콜
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "EKS-Node-Security-Group"
  }
}