# ----------------------------------------------
# 필수 변수 (Terraform 적용 전에 채워야 함)
# ----------------------------------------------

variable "vpc_id" {
  description = "EC2 인스턴스와 보안 그룹을 생성할 VPC의 ID입니다."
  type        = string
  # Make optional: when empty, configuration can use the VPC created in this repo (aws_vpc.eks_vpc)
  default     = ""
}

variable "subnet_id" {
  description = "EC2 인스턴스를 배포할 프라이빗 서브넷의 ID입니다."
  type        = string
  # Optional: leave empty to use subnets created by this Terraform configuration
  default     = ""
}

variable "key_name" {
  description = "EC2 인스턴스에 접속하기 위해 사용할 기존 SSH 키 페어의 이름입니다."
  type        = string
  # Optional: provide an existing key name if you want EC2 access; otherwise leave empty
  default     = ""
}

variable "region" {
  description = "AWS 리전 (vpc_main.tf에서 사용한 리전과 일치해야 함)"
  type        = string
  default     = "ap-northeast-2" # 서울 리전 가정
}

# 컨트롤: Helm/Kubernetes 리소스 배포 여부 (CI에서 2단계로 분리할 때 사용)
variable "deploy_k8s" {
  description = "If false, skip creating Helm/Kubernetes resources. Used to split infra and k8s deploys in CI."
  type        = bool
  default     = true
}
variable "kubeconfig_path" {
  description = "Path to the Kubeconfig file (for CI/CD use, passed via -var)."
  type        = string
  default     = ""
}
