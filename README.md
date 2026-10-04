# BUILD

- Build command: docker build --build-arg VERSION=1 -t techtest:1 .
- Final image size: 4.76MB
- Explanation/Penjelasan: Building image from scratch/ Build image dari image scratch
- Size explanation/Penjelasan ukuran: The image has only one layer that contains the Go binary (stripped with -s -w), no OS layer. Most of the 4.76MB is the Go runtime and net/http embedded in the binary / Image hanya berisi satu layer berisi binary Go (sudah di-strip dengan -s -w), tanpa layer OS. Sebagian besar dari 4.76MB adalah Go runtime dan net/http yang ikut tertanam di binary.
- Base image choice/Alasan pilih base image: scratch. The binary is statically linked (CGO_ENABLED=0), so it needs no libc, shell, or package manager. scratch gives the smallest size and attack surface. Trade-off: no shell inside the container for debugging / scratch dipilih karena binary static (CGO_ENABLED=0), jadi tidak butuh libc, shell, atau package manager. Ukuran dan attack surface paling kecil. Kekurangannya: tidak ada shell di dalam container untuk debugging.
- Version injection/Injeksi versi: -ldflags "-X main.version=1" so GET / shows the build version / agar GET / menampilkan versi build.

# DEPLOY
- Run old image/buat container dari image lama: docker run -d --name hello --restart unless-stopped -p 8080:8080 techtest:1
- curl output before binary swap/ output curl dari image lama: Hello, DevOps! version=1
- Replace go binary/Ganti binary go:
export MSYS_NO_PATHCONV=1
CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w -X main.version=1.0.1" -o app-new .
docker cp app-new hello:/app
- Restart the container/Restart Container:
docker restart -t 2 hello
- curl output after binary swap/ output curl setelah binary swap: Hello, DevOps! version=1.0.1
- Explanation/Penjelasan: I chose docker cp + docker restart. It needs no image rebuild or registry pull, and the same container (name, port, restart policy) is kept, so downtime is only about 1-2 seconds during restart. The old binary can be copied out first, so rollback is a single docker cp. The downside is that the change lives only in the container's writable layer and is lost if the container is recreated from the old image, which is acceptable for an emergency hotfix, with the permanent fix shipped as a new image from the pipeline / Saya memilih docker cp + docker restart. Cara ini tidak butuh rebuild image atau pull dari registry, dan container yang sama (nama, port, restart policy) tetap dipakai, jadi downtime hanya sekitar 1-2 detik saat restart. Binary lama bisa disalin keluar dulu sehingga rollback cukup satu docker cp. Kekurangannya, perubahan hanya ada di writable layer container dan hilang kalau container dibuat ulang dari image lama, ini bisa diterima untuk hotfix darurat, dengan perbaikan permanen lewat image baru dari pipeline.

# CI/CD JENKINS
- Stages/Tahapan: Checkout, Test, Build Image, Push, Deploy
  - Checkout: pull source from repo, version = git rev-parse --short HEAD / ambil source dari repo, versi = git rev-parse --short HEAD
  - Test: docker build --target test . (runs go test ./...), pipeline stops here if tests fail / menjalankan go test ./..., pipeline berhenti di sini kalau test gagal
  - Build Image: docker build --build-arg VERSION=<commit hash> -t techtest:<commit hash> .
  - Push: runs only if REGISTRY parameter is set, uses Jenkins credential ID registry-creds / hanya jalan kalau parameter REGISTRY diisi, memakai credential Jenkins dengan ID registry-creds
  - Deploy: extract binary from the new image, then run deploy.sh (docker cp + docker restart + health check) / ambil binary dari image baru, lalu jalankan deploy.sh (docker cp + docker restart + health check)
- Secrets/Rahasia: no secrets in Jenkinsfile, credentials are accessed with withCredentials / tidak ada secret di Jenkinsfile, credential diakses lewat withCredentials
- Successful pipeline run/Pipeline sukses: screenshots/pipeline-success.png
- Failed test run/Pipeline gagal saat test: screenshots/pipeline-test-fail.png
- Rollback explanation/Penjelasan rollback: Before swapping, deploy.sh copies the running binary out of the container. After docker cp and restart, it checks GET / for up to 15 seconds expecting the new version. If the copy, restart, or health check fails, an EXIT trap restores the old binary and restarts the container, then the script exits with an error so the Deploy stage turns red while the service stays on the last healthy version / Sebelum menukar binary, deploy.sh menyalin binary yang sedang jalan keluar dari container. Setelah docker cp dan restart, script memeriksa GET / sampai 15 detik dan mengharapkan versi baru. Jika copy, restart, atau health check gagal, trap EXIT mengembalikan binary lama dan me-restart container, lalu script keluar dengan error sehingga stage Deploy merah sementara layanan tetap berjalan di versi terakhir yang sehat.