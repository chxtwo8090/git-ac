#!/bin/bash

#====================================================
# AWS/EKS 인프라 구성을 위한 필수 도구 일괄 설치 스크립트
# 도구 목록: AWS CLI, Terraform, kubectl, Helm, jq
# 지원 OS: Debian/Ubuntu, Amazon Linux/CentOS/RHEL
#====================================================

# 설치할 도구의 버전 지정 (필요에 따라 최신 버전으로 변경 가능)
TERRAFORM_VERSION="1.8.0"
KUBECTL_VERSION="v1.34"
HELM_VERSION="v3.15.0"
JQ_VERSION="1.7.1" # jq는 OS 패키지 관리자로 설치 시 버전을 명시하지 않음

INSTALL_DIR="/usr/local/bin"

# 운영체제 감지
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "🚨 경고: 지원되지 않는 운영체제입니다. 설치를 중단합니다."
    exit 1
fi

# sudo 권한 확인
if ! command -v sudo &> /dev/null; then
    echo "🚨 오류: sudo 명령어를 찾을 수 없습니다. 스크립트 실행에는 sudo 권한이 필요합니다."
    exit 1
fi

echo "===================================================="
echo "🎯 EKS 인프라 필수 도구 설치 시작 (OS: $OS)"
echo "===================================================="

# 패키지 관리자 업데이트 및 기본 유틸리티 설치
install_dependencies() {
    echo "--- 1. 필수 의존성 (curl, unzip, wget, jq) 설치 중..."
    if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
        sudo apt update -y
        sudo apt install -y curl unzip wget jq
    elif [[ "$OS" == "amzn" || "$OS" == "centos" || "$OS" == "rhel" ]]; then
        # Amazon Linux 2023은 dnf를 사용합니다.
        # dnf가 없으면 yum을 사용하도록 폴백
        if command -v dnf &> /dev/null; then
            sudo dnf install -y curl unzip wget jq
        else
            sudo yum install -y curl unzip wget jq
        fi
    else
        echo "⚠️ 경고: 기본 의존성 설치를 위한 패키지 관리자를 찾을 수 없습니다."
    fi
    echo "--- 기본 의존성 설치 완료."
}

# AWS CLI v2 설치
install_aws_cli() {
    echo "--- 2. AWS CLI v2 설치 중..."
    local TEMP_DIR=$(mktemp -d)
    cd $TEMP_DIR
    curl "https://awscli.amazonaws.com/awscli-exe-linux-x86_64.zip" -o "awscliv2.zip"
    unzip awscliv2.zip
    sudo ./aws/install --install-dir $INSTALL_DIR/aws-cli --bin-dir $INSTALL_DIR
    rm -rf $TEMP_DIR

    if command -v aws &> /dev/null; then
        echo "✅ AWS CLI 설치 완료: $(aws --version)"
    else
        echo "❌ AWS CLI 설치 실패."
    fi
}

# Terraform 설치
install_terraform() {
    echo "--- 3. Terraform v$TERRAFORM_VERSION 설치 중..."
    local TF_ZIP="terraform_${TERRAFORM_VERSION}_linux_amd64.zip"
    wget -q "https://releases.hashicorp.com/terraform/${TERRAFORM_VERSION}/${TF_ZIP}"
    unzip $TF_ZIP
    sudo mv terraform $INSTALL_DIR/
    rm -f $TF_ZIP
    
    if command -v terraform &> /dev/null; then
        echo "✅ Terraform 설치 완료: $(terraform version | head -n 1)"
    else
        echo "❌ Terraform 설치 실패."
    fi
}

# kubectl 설치
install_kubectl() {
    echo "--- 4. kubectl $KUBECTL_VERSION 설치 중..."
    # 공식 Google Cloud 저장소에서 바이너리 다운로드
    curl -LO "https://dl.k8s.io/release/${KUBECTL_VERSION}/bin/linux/amd64/kubectl"
    sudo install -o root -g root -m 0755 kubectl $INSTALL_DIR/
    rm -f kubectl

    if command -v kubectl &> /dev/null; then
        echo "✅ kubectl 설치 완료: $(kubectl version --client --short)"
    else
        echo "❌ kubectl 설치 실패."
    fi
}

# Helm 설치
install_helm() {
    echo "--- 5. Helm $HELM_VERSION 설치 중..."
    local HELM_TAR="helm-${HELM_VERSION}-linux-amd64.tar.gz"
    wget -q "https://get.helm.sh/${HELM_TAR}"
    tar -zxvf ${HELM_TAR}
    sudo mv linux-amd64/helm $INSTALL_DIR/
    rm -rf linux-amd64 ${HELM_TAR}

    if command -v helm &> /dev/null; then
        echo "✅ Helm 설치 완료: $(helm version --short)"
    else
        echo "❌ Helm 설치 실패."
    fi
}

# 메인 실행
install_dependencies
install_aws_cli
install_terraform
install_kubectl
install_helm

echo "===================================================="
echo "🎉 모든 필수 도구 설치가 완료되었습니다!"
echo "===================================================="
echo "다음 명령으로 PATH에 추가되었는지 확인하세요:"
echo "aws --version"
echo "terraform version"
echo "kubectl version --client"
echo "helm version --short"
echo "jq --version"
echo "===================================================="

exit 0
