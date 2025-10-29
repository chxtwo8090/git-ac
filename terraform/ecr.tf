# ----------------------------------------------------
# 1. Gemma LLM API 이미지 저장소
# ----------------------------------------------------
resource "aws_ecr_repository" "llm_api_repo" {
  name                 = "gemma-llm-api"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "Gemma LLM API Repository"
  }
}

# ----------------------------------------------------
# 2. 뉴스 수집기 이미지 저장소
# ----------------------------------------------------
resource "aws_ecr_repository" "scraper_repo" {
  name                 = "financial-news-scraper"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "News Scraper Repository"
  }
}

# ----------------------------------------------------
# 3. 프론트엔드 이미지 저장소 (결과 게재 사이트)
# ----------------------------------------------------
resource "aws_ecr_repository" "frontend_repo" {
  name                 = "analysis-frontend"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Name = "Frontend Repository"
  }
}

# ----------------------------------------------------
# 출력값: ECR Push/Pull 시 필요한 ARN
# ----------------------------------------------------
output "llm_api_ecr_uri" {
  description = "Gemma LLM API ECR Repository URI"
  value       = aws_ecr_repository.llm_api_repo.repository_url
}

output "scraper_ecr_uri" {
  description = "Scraper ECR Repository URI"
  value       = aws_ecr_repository.scraper_repo.repository_url
}