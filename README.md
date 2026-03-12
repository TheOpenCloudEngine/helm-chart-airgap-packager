# Helm Chart Airgap Packager

Airgap(인터넷 차단) 환경에서 Helm Chart와 Chart가 참조하는 Docker 이미지를 함께 설치할 수 있도록 패키징해주는 CLI 도구입니다.

## 개요

```
인터넷 연결 환경                        Airgap 환경
──────────────────────                  ──────────────────────
helm-airgap pack          →  번들 전송  →  helm-airgap install
  - Helm chart pull                          - 이미지 로드/푸시
  - Docker image pull                        - Helm chart 설치
  - 번들(.tar.gz) 생성
```

### 번들 구조

```
<chart-name>-<version>-airgap.tar.gz
└── <chart-name>-<version>/
    ├── manifest.json          # 메타데이터 (차트 정보, 이미지 목록)
    ├── charts/
    │   └── <chart>.tgz        # Helm chart 아카이브
    └── images/
        ├── <image1>.tar       # docker save 이미지 파일
        └── <image2>.tar
```

## 설치

### 요구사항

- Python 3.10+
- Helm CLI (설치 방법은 아래 참고)
- Docker 또는 Podman (이미지 패키징 시)

### Helm 설치

#### Linux

```bash
# 공식 설치 스크립트 (권장)
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash

# 특정 버전 설치
curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | DESIRED_VERSION=v3.17.0 bash
```

패키지 매니저를 사용할 수도 있습니다.

```bash
# apt (Debian/Ubuntu)
curl https://baltocdn.com/helm/signing.asc | gpg --dearmor | sudo tee /usr/share/keyrings/helm.gpg > /dev/null
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/helm.gpg] https://baltocdn.com/helm/stable/debian/ all main" | sudo tee /etc/apt/sources.list.d/helm-stable-debian.list
sudo apt-get update && sudo apt-get install helm

# dnf (RHEL/Fedora/Rocky)
sudo dnf install helm

# yum (CentOS/RHEL 7)
sudo yum install helm
```

#### macOS

```bash
brew install helm
```

#### Windows

```powershell
# Chocolatey
choco install kubernetes-helm

# Scoop
scoop install helm

# winget
winget install Helm.Helm
```

#### 설치 확인

```bash
helm version
# version.BuildInfo{Version:"v3.x.x", ...}
```

### pip 설치

```bash
pip install .
# 또는 개발 모드
pip install -e .
```

## 사용법

### 1. pack — 번들 생성 (인터넷 연결 환경)

```bash
# Helm 레포에서 차트 pull 후 번들 생성
helm-airgap pack nginx \
  --repo-url https://charts.bitnami.com/bitnami \
  --chart-version 15.14.0 \
  -o nginx-airgap.tar.gz

# 이미 추가된 레포 사용
helm repo add bitnami https://charts.bitnami.com/bitnami
helm-airgap pack bitnami/nginx -o nginx-airgap.tar.gz

# 로컬 차트 디렉토리
helm-airgap pack ./my-chart/ -o my-chart-airgap.tar.gz

# 로컬 .tgz 아카이브
helm-airgap pack ./my-chart-1.0.0.tgz -o my-chart-airgap.tar.gz

# OCI 레지스트리
helm-airgap pack oci://registry.example.com/charts/nginx -o nginx-airgap.tar.gz

# 커스텀 values 파일로 이미지 탐색 범위 확장
helm-airgap pack bitnami/nginx \
  --repo-url https://charts.bitnami.com/bitnami \
  -f my-values.yaml \
  --set "image.tag=1.25" \
  -o nginx-airgap.tar.gz

# 특정 이미지 추가/제외
helm-airgap pack bitnami/nginx \
  --repo-url https://charts.bitnami.com/bitnami \
  --include-image myrepo/sidecar:v1 \
  --exclude-image "bitnami/nginx-exporter" \
  -o nginx-airgap.tar.gz

# 차트만 번들링 (이미지 제외)
helm-airgap pack bitnami/nginx \
  --repo-url https://charts.bitnami.com/bitnami \
  --skip-images \
  -o nginx-airgap.tar.gz
```

### 2. inspect — 번들 내용 확인

```bash
# 번들 내용 출력
helm-airgap inspect nginx-airgap.tar.gz

# JSON 형식으로 출력
helm-airgap inspect nginx-airgap.tar.gz --json
```

출력 예시:
```
Bundle created : 2024-01-15T09:30:00+00:00
Packager ver.  : 0.1.0
Chart          : nginx @ 15.14.0
Chart file     : nginx-15.14.0.tgz

Images (2):
  [✓] docker.io/bitnami/nginx:1.25.3-debian-11-r0
       file: docker.io_bitnami_nginx_1.25.3-debian-11-r0.tar
  [✓] docker.io/bitnami/nginx-exporter:0.11.0-debian-11-r90
       file: docker.io_bitnami_nginx-exporter_0.11.0-debian-11-r90.tar
```

### 3. install — Airgap 환경에서 설치

```bash
# 기본 설치 (이미지를 로컬 Docker에 로드)
helm-airgap install nginx-airgap.tar.gz my-nginx

# Private registry에 이미지를 push하면서 설치
helm-airgap install nginx-airgap.tar.gz my-nginx \
  --registry myregistry.local:5000 \
  --namespace web

# 인증서 없는 레지스트리 사용
helm-airgap install nginx-airgap.tar.gz my-nginx \
  --registry myregistry.local:5000 \
  --registry-insecure

# 추가 values 파일 적용
helm-airgap install nginx-airgap.tar.gz my-nginx \
  --registry myregistry.local:5000 \
  -f override-values.yaml \
  --set "service.type=NodePort" \
  --wait

# 이미지만 push하고 Helm 설치는 건너뜀
helm-airgap install nginx-airgap.tar.gz my-nginx \
  --registry myregistry.local:5000 \
  --skip-helm

# Helm 설치만 하고 이미지 로드는 건너뜀
helm-airgap install nginx-airgap.tar.gz my-nginx \
  --skip-load
```

## 옵션 전체 목록

### `helm-airgap pack`

| 옵션 | 설명 |
|------|------|
| `CHART` | 차트 참조 (repo/name, 로컬 경로, OCI ref) |
| `-o, --output PATH` | 출력 번들 경로 (.tar.gz 또는 디렉토리) |
| `--chart-version VERSION` | 특정 차트 버전 지정 |
| `--repo-url URL` | Helm 레포지토리 URL |
| `--repo-name NAME` | Helm 레포 별칭 (기본: airgap-repo) |
| `--repo-username USER` | 레포 인증 사용자명 (env: HELM_REPO_USERNAME) |
| `--repo-password PASS` | 레포 인증 패스워드 (env: HELM_REPO_PASSWORD) |
| `-f, --values FILE` | 추가 values 파일 (반복 사용 가능) |
| `--set KEY=VAL` | helm template용 --set 옵션 (반복 사용 가능) |
| `--skip-images` | 이미지 없이 차트만 번들링 |
| `--include-image REF` | 번들에 이미지 명시 추가 (반복 사용 가능) |
| `--exclude-image PATTERN` | 이미지 제외 패턴 (반복 사용 가능) |
| `-v, --verbose` | 디버그 로그 출력 |

### `helm-airgap install`

| 옵션 | 설명 |
|------|------|
| `BUNDLE` | 번들 .tar.gz 경로 |
| `RELEASE_NAME` | Helm 릴리즈 이름 |
| `-n, --namespace NS` | Kubernetes 네임스페이스 (기본: default) |
| `--registry HOST:PORT` | 이미지를 push할 Private registry |
| `--registry-insecure` | 비보안(HTTP) 레지스트리 허용 |
| `-f, --values FILE` | 추가 values 파일 (반복 사용 가능) |
| `--set KEY=VAL` | 추가 --set 옵션 (반복 사용 가능) |
| `--skip-load` | 이미지 로드 건너뜀 |
| `--skip-push` | 레지스트리 push 건너뜀 |
| `--skip-helm` | Helm 설치 건너뜀 |
| `--no-create-namespace` | --create-namespace 비활성화 |
| `--wait` | Helm --wait 옵션 활성화 |
| `-v, --verbose` | 디버그 로그 출력 |

## Private Registry 사용 시나리오

Airgap 환경에 Private Container Registry(예: Harbor, Docker Registry)가 있을 경우:

```bash
# 설치 시 --registry 옵션으로 레지스트리를 지정하면:
# 1. 번들의 이미지를 로컬에 로드
# 2. <registry>/<original-path>:<tag> 형태로 retag
# 3. 해당 레지스트리에 push
# 4. Helm 설치 시 global.imageRegistry=<registry> 자동 설정

helm-airgap install my-chart-airgap.tar.gz my-release \
  --registry harbor.internal.company.com \
  --namespace production
```

## 이미지 추출 방식

1. **helm template 방식** (기본, 정확도 높음)
   - `helm template`로 모든 매니페스트를 렌더링
   - `image:` 필드를 파싱하여 이미지 목록 추출

2. **values.yaml 파싱 방식** (fallback)
   - `values.yaml`에서 `repository`/`tag`/`registry` 패턴 탐색
   - helm template 실패 시 자동으로 사용

## 개발

```bash
git clone https://github.com/TheOpenCloudEngine/helm-chart-airgap-packager.git
cd helm-chart-airgap-packager
pip install -e .

# 도움말 확인
helm-airgap --help
helm-airgap pack --help
helm-airgap install --help
helm-airgap inspect --help
```

## 라이선스

MIT License
