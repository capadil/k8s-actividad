# SandboxService

## Run local
dotnet run --project src/SandboxService

## Docker
docker build -t sandboxservice:local .
docker run --rm -p 8080:8080 -e APP_VERSION="docker-1" sandboxservice:local

## Endpoints
- GET /health
- GET /version

##


# K8S-ACTIVIDAD — GitOps con ArgoCD + Helm + GitHub Actions (GHCR)

Este repositorio despliega un microservicio .NET en Kubernetes usando:
- **Docker** (build de imagen)
- **Helm** (chart del microservicio)
- **ArgoCD** (GitOps: ArgoCD sincroniza el estado del clúster desde Git)
- **GitHub Actions** (CI: build/push a GHCR + actualización de Helm values para gatillar despliegue)

## 1) Arquitectura del flujo (CI/CD)
**Trigger:** push/commit a rama `main`

1. GitHub Actions (CI):
   - Build Docker image (Dockerfile)
   - Push a GHCR: `ghcr.io/<owner>/sandboxservice:<SHA>`
   - Actualiza `helm/sandboxservice/values-dev.yaml` con `image.tag=<SHA>` (GitOps bump) y hace commit
2. ArgoCD (CD):
   - Detecta el commit nuevo del repositorio
   - Renderiza el Helm chart (helm template)
   - Aplica manifests al namespace `dev`
   - Deja la app en estado **Synced/Healthy**

> Importante: para evitar “dobles despliegues”, en `dev` no se deben aplicar manifests manuales (kubectl/helm install manual). ArgoCD debe ser la única fuente de verdad.

---

## 2) Estructura del repo
- `src/SandboxService/` → microservicio .NET
- `Dockerfile` → build de la imagen
- `helm/sandboxservice/` → Helm chart (values.yaml + values-dev.yaml + values-prod.yaml)
- `argocd/app-dev.yaml` → definición ArgoCD Application (dev)
- `.github/workflows/ci-cd-dev.yml` → pipeline CI/CD (se crea con esta guía)
- `k8s/` → manifiestos legacy (NO se usan si trabajas con ArgoCD+Helm)

---

## 3) Prerrequisitos (local)
- Docker Desktop con **Kubernetes habilitado**
- `kubectl`
- `helm` (v3+)
- `git`

Verifica:
```bash
kubectl config current-context
kubectl get nodes
helm version

## configuracion de ARGO
## crear el namespace
kubectl create namespace argocd

# Agrega el repositorio oficial de Helm de Argo (contiene los charts de Argo CD, Argo Workflows, etc.)
helm repo add argo https://argoproj.github.io/argo-helm

# Actualiza el índice local de repositorios Helm para tener la lista más reciente de charts y versiones
helm repo update

# Instala Argo CD usando el chart oficial de Helm en el namespace 'argocd'
# (La release se llamará 'argocd', útil para luego hacer upgrade/rollback)
helm install argocd argo/argo-cd -n argocd

# Observa en tiempo real el arranque de los pods de Argo CD hasta que queden en Running/Ready
kubectl -n argocd get pods -w

# Crea un túnel local para acceder a la UI/API de Argo CD:
# tu PC -> https://localhost:9090  se redirige al Service argocd-server:443 dentro del cluster
kubectl -n argocd port-forward svc/argocd-server 9090:443
# Obtiene la contraseña inicial del usuario 'admin' desde el Secret generado por Argo CD
# (Kubernetes guarda los secretos en base64, por eso se decodifica)
[Text.Encoding]::UTF8.GetString([Convert]::FromBase64String((kubectl -n argocd get secret argocd-initial-admin-secret -o jsonpath="{.data.password}")))


kubectl create namespace dev
kubectl create namespace prod

# Crea o actualiza la Application de Argo CD definida en este YAML.
# Esto "registra" la app en Argo CD para que sincronice el estado deseado desde Git hacia el cluster (entorno dev).

kubectl apply -f argocd/app-dev.yaml
kubectl -n argocd get applications
kubectl -n argocd describe application sandboxservice-dev


## pendiente CI CD

wsl --shutdown

Restart-Service com.docker.service

docker info
kubectl get nodes