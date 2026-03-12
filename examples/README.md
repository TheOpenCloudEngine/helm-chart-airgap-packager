# Examples

각 차트별 airgap 번들 생성(pack) 및 설치(install) 예제 스크립트 모음입니다.

## 사용 흐름

```
[인터넷 연결 환경]          [에어갭 환경]
     pack-*.sh    →  전송  →  install-*.sh
```

## 차트 목록

| 앱 | 앱 버전 | 차트 버전 | 레포 타입 | Pack | Install |
|----|---------|-----------|-----------|------|---------|
| Apache Airflow | 3.1.7 | 1.19.0 | Helm Repo | [pack-airflow.sh](./pack-airflow.sh) | [install-airflow.sh](./install-airflow.sh) |
| Keycloak | 26.3.3 | 25.2.0 | OCI | [pack-keycloak.sh](./pack-keycloak.sh) | [install-keycloak.sh](./install-keycloak.sh) |
| Apache ZooKeeper | 3.9.3 | 13.8.7 | OCI | [pack-zookeeper.sh](./pack-zookeeper.sh) | [install-zookeeper.sh](./install-zookeeper.sh) |
| PostgreSQL | 16.4.0 | 15.5.38 | Helm Repo | [pack-postgresql.sh](./pack-postgresql.sh) | [install-postgresql.sh](./install-postgresql.sh) |
| MariaDB | 10.6.12 | 11.5.7 | Helm Repo | [pack-mariadb.sh](./pack-mariadb.sh) | [install-mariadb.sh](./install-mariadb.sh) |
| Apache Cassandra | 5.0.5 | 12.3.11 | OCI | [pack-cassandra.sh](./pack-cassandra.sh) | [install-cassandra.sh](./install-cassandra.sh) |
| Prometheus | 3.10.0 | 28.13.0 | Helm Repo | [pack-prometheus.sh](./pack-prometheus.sh) | [install-prometheus.sh](./install-prometheus.sh) |
| Grafana | 12.1.1 | 12.1.8 | OCI | [pack-grafana.sh](./pack-grafana.sh) | [install-grafana.sh](./install-grafana.sh) |

## 레포 타입별 pack 명령어 패턴

### Helm Repo 방식

```bash
helm-airgap pack <chart-name> \
  --repo-url <repo-url> \
  --repo-name <alias> \
  --chart-version <version> \
  -o ./bundles/<chart>-<version>-airgap.tar.gz
```

### OCI Registry 방식

```bash
helm-airgap pack oci://registry-1.docker.io/bitnamicharts/<chart-name> \
  --chart-version <version> \
  -o ./bundles/<chart>-<version>-airgap.tar.gz
```

## 실행 전 확인사항

### Pack (인터넷 환경)
- `helm` CLI 설치 확인: `helm version`
- `docker` 또는 `podman` 설치 및 실행 확인: `docker info`
- `helm-airgap` 설치 확인: `helm-airgap --version`

### Install (에어갭 환경)
- `helm` CLI 설치 확인
- `docker` 또는 `podman` 설치 및 실행 확인
- `kubectl` 클러스터 연결 확인: `kubectl cluster-info`
- Private Registry 주소 확인 (기본값: `myregistry.local:5000`)

## 번들 파일 전송

```bash
# scp로 전송
scp ./bundles/*.tar.gz user@airgap-host:/path/to/bundles/

# rsync로 전송
rsync -avz --progress ./bundles/ user@airgap-host:/path/to/bundles/
```
