# Kubernetes HPA Example

A minimal example demonstrating the Kubernetes Horizontal Pod Autoscaler (HPA) in action.

## Project Structure

```
k8s-hpa-example/
├── app/
│   ├── main.py          # Simple HTTP server with a CPU-intensive /load endpoint
│   └── Dockerfile
├── manifests/
│   ├── deployment.yaml  # Deployment + Service
│   └── hpa.yaml         # HPA configuration
├── scripts/
│   └── loadgen.py       # Concurrent load generator
└── README.md
```

## Architecture

- **Deployment**: Runs 1 replica of a tiny Python HTTP server. CPU requests are set to `100m` and limits to `300m`.
- **Service**: NodePort service on port 80 forwarding to the pod's port 8080.
All resources are deployed to the `hpa-example-ns` namespace.

## Prerequisites

- Minikube running
- `kubectl` configured
- Metrics Server installed (required for CPU-based HPA)

### Install Metrics Server (Minikube)

```bash
minikube addons enable metrics-server
# Verify:
kubectl get deployment metrics-server -n kube-system
```

## Step-by-Step: Watch HPA Scale Up and Down

### 1. Build image and deploy

```bash
eval "$(minikube docker-env)"
docker build -t hpa-example:latest ./app/
kubectl create namespace hpa-example-ns
kubectl apply -f manifests/
```

### 2. Verify everything is running

```bash
kubectl get pods -n hpa-example-ns -l app=hpa-example
kubectl get hpa hpa-example -n hpa-example-ns
```

Expected HPA output (no load yet):

```
NAME          REFERENCE                TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
hpa-example   Deployment/hpa-example   0%/50%    1         10        1          10s
```

### 4. Find the NodePort and install load generator dependencies

```bash
# Get the NodePort assigned to the service
kubectl get svc hpa-example -n hpa-example-ns -o jsonpath='{.spec.ports[0].nodePort}'
```

Also install the load generator dependencies:

```bash
python3 -m venv .venv
source .venv/bin/activate
pip install -r requirements.txt
```

### 5. Generate load and watch HPA react

**Terminal 1** — watch pods and HPA in real time:

```bash
watch -n2 "kubectl get hpa,hpa,po -n hpa-example-ns -l app=hpa-example"
```

**Terminal 2** — fire sustained load:

```bash
# Send 500 requests with 20 concurrent workers against the NodePort
python3 scripts/loadgen.py $(minikube service hpa-example -n hpa-example-ns --url) 100 50
```

Repeat the load command several times quickly to keep CPU usage high.

### 6. Observe scaling up

After 15–30 seconds of sustained load, the HPA will scale the deployment up:

```
NAME          REFERENCE                TARGETS    MINPODS   MAXPODS   REPLICAS   AGE
hpa-example   Deployment/hpa-example   80%/50%    1         10        4          45s
```

New pods appear within seconds:

```
NAME                           READY   STATUS    RESTARTS   AGE
hpa-example-7c8b5d4f6b-2kx9m   1/1     Running   0          10s
hpa-example-7c8b5d4f6b-4nplw   1/1     Running   0          5s
hpa-example-7c8b5d4f6b-8zqxr   1/1     Running   0          5s
```

### 7. Stop the load and watch scale-down

After load stops, the HPA waits **60 seconds** (configurable in `hpa.yaml`) before scaling down. After another **60 seconds** pods are removed:

```
NAME          REFERENCE                TARGETS   MINPODS   MAXPODS   REPLICAS   AGE
hpa-example   Deployment/hpa-example   0%/50%    1         10        1          3m
```

### 8. Cleanup

```bash
kubectl delete -n hpa-example-ns -f manifests/
```

---

## How the HPA Configuration Works (`manifests/hpa.yaml`)

| Setting | Value | Meaning |
|---|---|---|
| `minReplicas` | 1 | Never scale below 1 pod |
| `maxReplicas` | 10 | Never scale above 10 pods |
| `targetCPUUtilization` | 50% | Each pod should use ~50% of its 300m CPU limit |
| `scaleUp.stabilizationWindowSeconds` | 15 | Wait 15s before adding pods after a scale-up event |
| `scaleUp.policies` | 100% / 30s | Can double the replica count every 30 seconds |
| `scaleDown.stabilizationWindowSeconds` | 60 | Wait 60s of low CPU before removing a pod |
| `scaleDown.policies` | 50% / 60s | Remove at most 50% of pods every 60 seconds |

## Troubleshooting

- **HPA shows `<unknown>/50%`**: Metrics Server is not installed or pods have no CPU requests set.

- **Pods don't scale up**: Check `kubectl describe hpa hpa-example -n hpa-example-ns` for events and ensure the image is available.

- **Local testing without a cluster**: Use `python3 app/main.py` and hit `http://localhost:8080/load` directly.
