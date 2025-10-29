# ----------------------------------------------------
# DynamoDB 테이블 정의 (뉴스 분석 결과 저장용)
# ----------------------------------------------------
resource "aws_dynamodb_table" "analysis_results_table" {
  name           = "Financial-Analysis-Results"
  billing_mode   = "PAY_PER_REQUEST" # 온디맨드 (Pay-per-request) 모드 사용으로 유연성 확보
  hash_key       = "article_id"      # 기본 키: 뉴스 고유 ID

  attribute {
    name = "article_id"
    type = "S" # String 타입
  }
 attribute { # <-- 이 부분을 추가해야 합니다.
    name = "publish_date"
    type = "S" # String 타입 (날짜는 보통 ISO8601 형식의 문자열로 저장)
  }
  # 보조 인덱스 (GSI) 정의: 날짜별/종목별 검색을 위한 유연성 확보
  global_secondary_index {
    name               = "publish_date_index"
    hash_key           = "publish_date"
    projection_type    = "ALL"
    # 읽기/쓰기 용량은 기본 모드에서는 무시됩니다.
  }
  
  tags = {
    Name = "AnalysisResultsTable"
  }
}

# ----------------------------------------------------
# 출력값
# ----------------------------------------------------
output "dynamodb_table_name" {
  description = "DynamoDB 테이블 이름"
  value       = aws_dynamodb_table.analysis_results_table.name
}