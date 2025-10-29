# 이 파일은 민감 정보가 포함될 수 있으므로, .gitignore에 등록하여 Git 추적에서 제외하는 것이 좋습니다.

# 1. VPC ID
#vpc_id    = "vpc-0eae18197092a5d09"

# 2. EC2 인스턴스 단독 배포용 서브넷 ID (t3.small 인스턴스 코드를 그대로 둔다면 필요)
# EC2 인스턴스를 하나만 만들었다면, 그 EC2가 위치한 서브넷 ID만 남깁니다.
subnet_id = "subnet-01c8359c671e478dd"

# 3. EKS 클러스터와 노드 그룹에 사용할 프라이빗 서브넷 ID 목록 (리스트 형식으로 지정)
#private_subnet_ids = [
#  "subnet-01c8359c671e478dd",
#  "subnet-00990ed4521d9e874"
#]

# 4. Key Pair 이름 (AWS에 등록된 이름)
key_name  = "gj-kor-aiot"

# 5. AWS 리전 (vpc_main.tf와 일치해야 함)
region    = "ap-northeast-2" 

# 6. EKS 클러스터 이름 (eks_cluster.tf의 기본값 사용 시 생략 가능)
# eks_cluster_name = "eks-project-cluster"