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

## CI/CD (GitOps) — Responsabilidades y Verificación

Este repositorio implementa CI/CD usando **GitHub Actions (CI)** + **GHCR (registry)** + **ArgoCD (CD/GitOps)**.

### Objetivo del flujo
Al detectar un **push/commit en `main`**:
1) **CI** construye la imagen Docker y la publica en **GHCR** con tag inmutable (`SHA`).
2) **CI** actualiza `helm/sandboxservice/values-dev.yaml` con `image.tag = <SHA>` y hace commit/push (GitOps bump).
3) **CD (ArgoCD)** detecta ese commit y despliega automáticamente en el clúster (namespace `dev`).

---

## Responsabilidades (quién hace qué)

### Desarrollador (equipo)
- Realiza cambios de código en `src/` y/o chart en `helm/`.
- Hace push a la rama configurada (`main`).
- Revisa el resultado del pipeline en GitHub Actions.
- NO debe hacer despliegues manuales en `dev` (evitar `kubectl apply` o `helm install` manual), porque ArgoCD es la fuente de verdad.

### GitHub Actions (CI)
Archivo: `.github/workflows/ci-cd-dev.yml`

Responsable de:
- Autenticarse contra GHCR usando `GITHUB_TOKEN`.
- **Build** de la imagen desde `Dockerfile`.
- **Push** de la imagen a GHCR:
  - `ghcr.io/<owner-lc>/sandboxservice:<SHA>`
  - `ghcr.io/<owner-lc>/sandboxservice:dev` (tag “cómodo”)
- Modificar `helm/sandboxservice/values-dev.yaml`:
  - `image.repository = ghcr.io/<owner-lc>/sandboxservice`
  - `image.tag = <SHA>`
- Hacer commit/push del bump.
- Si el build falla, NO hace bump → ArgoCD NO despliega una imagen inexistente.

### GHCR (GitHub Container Registry)
Responsable de almacenar imágenes publicadas por el CI.

Recomendación para ambiente local (Docker Desktop K8s):
- Configurar el paquete como **Public** para evitar `imagePullSecrets` y errores `ImagePullBackOff`.

### ArgoCD (CD/GitOps)
Archivo: `argocd/app-dev.yaml`

Responsable de:
- Monitorear el repo (ruta `helm/sandboxservice`).
- Renderizar Helm usando `values-dev.yaml`.
- Aplicar cambios al namespace `dev`.
- Mantener estado `Synced/Healthy`.
- Corregir drift si alguien cambia recursos manualmente (si `selfHeal` está habilitado).

### Administrador del clúster (si aplica)
- Mantener el clúster disponible.
- Validar conectividad y permisos en namespaces (`argocd`, `dev`).
- Si GHCR es privado: crear `imagePullSecret` y soportarlo en el chart.

---

## Archivos clave
- `.github/workflows/ci-cd-dev.yml` → Pipeline CI.
- `helm/sandboxservice/values.yaml` → Defaults (local).
- `helm/sandboxservice/values-dev.yaml` → Overrides para dev (GHCR + tag actualizado por CI).
- `helm/sandboxservice/templates/deployment.yaml` → Debe usar:
  - `{{ .Values.image.repository }}:{{ .Values.image.tag }}`
- `argocd/app-dev.yaml` → App ArgoCD que apunta al chart + values-dev.

---

## Cómo verificar que CI/CD funciona (Checklist)

### A) Verificación CI (GitHub Actions)
1) En GitHub → pestaña **Actions**.
2) Selecciona workflow: **ci-cd-dev**.
3) El run debe terminar en ✅ verde.
4) En los logs, confirma:
   - “Login to GHCR” OK
   - “Build & Push image” OK
   - “Update values-dev.yaml” OK
   - “Commit & push bump” OK

**Evidencia esperada:** aparece un nuevo commit automático en `main` como:
- `chore(ci): bump dev image tag to <SHA>`

> Nota: el workflow ignora cambios directos a `values-dev.yaml` para evitar loops.

### B) Verificación Registry (GHCR)
1) En GitHub → sección **Packages** del repo/owner.
2) Debe existir el paquete `sandboxservice`.
3) Debe existir un tag con el **SHA** del commit.
4) Recomendación: poner el package como **Public** (en Settings del package).

### C) Verificación CD (ArgoCD)
1) Abre ArgoCD UI (port-forward):
   ```bash
   kubectl -n argocd port-forward svc/argocd-server 9090:443
   # https://127.0.0.1:9090



## levantar local
wsl --shutdown

Restart-Service com.docker.service

docker info
kubectl get nodes