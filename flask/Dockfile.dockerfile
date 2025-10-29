# app/flask/Dockerfile

# 1. Python 공식 slim 이미지 사용 (가볍습니다)
FROM python:3.9-slim

# 2. 작업 디렉토리를 /app으로 설정
WORKDIR /app

# 3. 의존성 파일 복사 및 설치
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# 4. 애플리케이션 코드 복사
COPY app.py .

# 5. Flask 앱 실행 명령 (프로덕션용 Gunicorn 사용)
# Gunicorn은 5000번 포트로 실행됩니다.
CMD ["gunicorn", "-w", "4", "-b", "0.0.0.0:5000", "app:app"]
