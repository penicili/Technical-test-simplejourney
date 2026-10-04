# BUILD

- Build command: docker build --build-arg VERSION=1 -t techtest:1 .
- Final image size: 4.76MB
- Explanation/Penjelasan: Building image from scratch/ Build image dari image scratch
- 

# DEPLOY
- Run old image/buat container dari image lama: docker run docker run -d --name hello --restart unless-stopped -p 8080:8080 techtest:1
- Replace go binary/Ganti binary go:
export MSYS_NO_PATHCONV=1
CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w -X main.version=1.0.1" -o app-new .
docker cp app-new hello:/app
- Restart the container/Restart Container:
docker restart -t 2 hello