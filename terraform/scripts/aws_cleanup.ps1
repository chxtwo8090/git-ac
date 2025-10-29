<#
aws_cleanup.ps1

안내: 이 스크립트는 AWS 계정에서 특정 리소스(예: IAM 정책/역할, ECR 리포지토리,
DynamoDB 테이블, 보안 그룹)를 삭제합니다. 실행 전 반드시 AWS CLI에 적절한 자격이
설정되어 있는지 확인하세요 (예: `aws configure` 또는 환경 변수).

이 스크립트는 파괴적(destructive)입니다. 실행 전에 반드시 내용을 검토하고, 필요 시 한 줄씩
복사해 수동으로 실행하세요.

사용법:
  PowerShell에서:
    cd terraform\scripts
    .\aws_cleanup.ps1

#>

param(
    [switch]$AutoConfirm
)

Set-StrictMode -Version Latest

# 한글(및 유니코드) 출력 깨짐 방지 시도
[Console]::OutputEncoding = [System.Text.Encoding]::UTF8
$OutputEncoding = New-Object System.Text.UTF8Encoding

# AWS CLI가 설치되어 PATH에 있는지 확인
if (-not (Get-Command aws -ErrorAction SilentlyContinue)) {
    Write-Error "AWS CLI가 시스템에 없거나 PATH에 없습니다. 먼저 'aws --version'을 실행해 설치/경로를 확인하세요."
    exit 1
}

function Confirm([string]$message) {
    if ($AutoConfirm) { return $true }
    $ans = Read-Host "$message [y/N]"
    return $ans -eq 'y' -or $ans -eq 'Y'
}

Write-Host "AWS Cleanup helper — 시작합니다. 이 스크립트는 파괴적입니다." -ForegroundColor Yellow

if (-not (Confirm "계속하시겠습니까? 모든 삭제 작업은 되돌릴 수 없습니다.")) {
    Write-Host "취소됨." -ForegroundColor Cyan
    exit 0
}

# 기본 리소스 이름 목록 (repo의 .tf에서 사용된 이름들)
$policyNames = @(
    'ALB-Ingress-Controller-Policy',
    'EKS-App-Data-Access-Policy',
    'EKS-ClusterAutoscaler-Policy'
)

$roleNames = @(
    'EKS-Cluster-Role-for-Project',
    'EKS-Worker-Node-Role-for-Project'
)

$ecrRepos = @(
    'gemma-llm-api',
    'financial-news-scraper',
    'analysis-frontend'
)

$dynamoTables = @(
    'Financial-Analysis-Results'
)

$securityGroupNames = @(
    'eks-worker-node-sg'
)

# 계정 ID 조회
try {
    $accountId = aws sts get-caller-identity --query Account --output text 2>$null
} catch {
    $accountId = $null
}
if (-not $accountId) {
    Write-Error 'AWS 계정 ID를 가져올 수 없습니다. AWS CLI가 구성되어 있고 유효한 자격(AWS_ACCESS_KEY_ID/AWS_SECRET_ACCESS_KEY 또는 aws configure)이 설정되어 있는지 확인하세요. 예: aws sts get-caller-identity'
    exit 1
}
Write-Host "AWS Account ID: $accountId" -ForegroundColor Green

##############################
# IAM Policy 삭제
##############################
foreach ($pname in $policyNames) {
    Write-Host "\n-- 처리: IAM Policy '$pname'" -ForegroundColor Cyan
    $arn = "arn:aws:iam::$accountId:policy/$pname"
    # 존재 확인
    $exists = aws iam get-policy --policy-arn $arn 2>$null
    if (-not $?) {
        Write-Host "정책이 존재하지 않음: $pname" -ForegroundColor DarkYellow
        continue
    }

    if (-not (Confirm "정책 $pname (ARN: $arn)을 삭제하시겠습니까?")) { continue }

    # 정책을 사용하는 엔터티(roles, users, groups) 분리
    $entities = aws iam list-entities-for-policy --policy-arn $arn --output json | ConvertFrom-Json
    if ($entities.RoleNames) {
        foreach ($r in $entities.RoleNames) {
            Write-Host "Detach policy from role: $r"
            aws iam detach-role-policy --role-name $r --policy-arn $arn
        }
    }
    if ($entities.UserNames) {
        foreach ($u in $entities.UserNames) {
            Write-Host "Detach policy from user: $u"
            aws iam detach-user-policy --user-name $u --policy-arn $arn
        }
    }
    if ($entities.GroupNames) {
        foreach ($g in $entities.GroupNames) {
            Write-Host "Detach policy from group: $g"
            aws iam detach-group-policy --group-name $g --policy-arn $arn
        }
    }

    # 정책 버전 정리(비디폴트 버전 삭제)
    $versions = aws iam list-policy-versions --policy-arn $arn --output json | ConvertFrom-Json
    foreach ($v in $versions.Versions) {
        if (-not $v.IsDefaultVersion) {
            Write-Host "Delete policy version: $($v.VersionId)"
            aws iam delete-policy-version --policy-arn $arn --version-id $v.VersionId
        }
    }

    # 정책 삭제
    Write-Host "Delete policy: $arn"
    aws iam delete-policy --policy-arn $arn
}

##############################
# IAM Role 삭제
##############################
foreach ($rname in $roleNames) {
    Write-Host "\n-- 처리: IAM Role '$rname'" -ForegroundColor Cyan
    $role = aws iam get-role --role-name $rname 2>$null
    if (-not $?) { Write-Host "Role 없음: $rname" -ForegroundColor DarkYellow; continue }

    if (-not (Confirm "Role $rname 을 삭제하시겠습니까? (정책 분리 및 프로파일 제거 포함)")) { continue }

    # 역할에 연결된 정책 분리
    $attached = aws iam list-attached-role-policies --role-name $rname --output json | ConvertFrom-Json
    foreach ($ap in $attached.AttachedPolicies) {
        Write-Host "Detach attached policy $($ap.PolicyArn) from $rname"
        aws iam detach-role-policy --role-name $rname --policy-arn $ap.PolicyArn
    }

    # inline 정책 삭제
    $inline = aws iam list-role-policies --role-name $rname --output json | ConvertFrom-Json
    foreach ($iname in $inline.PolicyNames) {
        Write-Host "Delete inline policy $iname from $rname"
        aws iam delete-role-policy --role-name $rname --policy-name $iname
    }

    # 인스턴스 프로파일에서 제거(있을 경우)
    $profiles = aws iam list-instance-profiles-for-role --role-name $rname --output json | ConvertFrom-Json
    foreach ($ip in $profiles.InstanceProfiles) {
        Write-Host "Remove role from instance profile: $($ip.InstanceProfileName)"
        aws iam remove-role-from-instance-profile --instance-profile-name $ip.InstanceProfileName --role-name $rname
        # 인스턴스 프로파일 삭제 시도 (주의)
        Write-Host "Delete instance profile: $($ip.InstanceProfileName)"
        aws iam delete-instance-profile --instance-profile-name $ip.InstanceProfileName
    }

    # 역할 삭제
    Write-Host "Delete role: $rname"
    aws iam delete-role --role-name $rname
}

##############################
# ECR 리포지토리 삭제
##############################
foreach ($repo in $ecrRepos) {
    Write-Host "\n-- 처리: ECR Repository '$repo'" -ForegroundColor Cyan
    $exists = aws ecr describe-repositories --repository-names $repo 2>$null
    if (-not $?) { Write-Host "Repository 없음: $repo" -ForegroundColor DarkYellow; continue }
    if (-not (Confirm "ECR repository $repo 를 강제로 삭제하시겠습니까? (모든 이미지 삭제)")) { continue }
    aws ecr delete-repository --repository-name $repo --force
}

##############################
# DynamoDB 테이블 삭제
##############################
foreach ($table in $dynamoTables) {
    Write-Host "\n-- 처리: DynamoDB Table '$table'" -ForegroundColor Cyan
    $exists = aws dynamodb describe-table --table-name $table 2>$null
    if (-not $?) { Write-Host "Table 없음: $table" -ForegroundColor DarkYellow; continue }
    if (-not (Confirm "DynamoDB 테이블 $table 를 삭제하시겠습니까?")) { continue }
    aws dynamodb delete-table --table-name $table
}

##############################
# Security Group 삭제
##############################
foreach ($sgName in $securityGroupNames) {
    Write-Host "\n-- 처리: Security Group '$sgName'" -ForegroundColor Cyan
    $sgId = aws ec2 describe-security-groups --filters Name=group-name,Values=$sgName --query "SecurityGroups[0].GroupId" --output text 2>$null
    if (-not $sgId -or $sgId -eq 'None') { Write-Host "SG 없음: $sgName" -ForegroundColor DarkYellow; continue }
    if (-not (Confirm "Security Group $sgName (ID: $sgId) 을 삭제하시겠습니까?")) { continue }
    aws ec2 delete-security-group --group-id $sgId
}

Write-Host ""
Write-Host '모든 지정된 리소스에 대해 처리 시도가 완료되었습니다. 에러 메시지가 있으면 확인 후 수동 조치 필요할 수 있습니다.' -ForegroundColor Green
