resource "helm_release" "prometheus_stack" {
  name             = "observability"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true
  version          = "55.0.0" # Always pin versions in production!

  # Ensures this doesn't run until the EKS cluster is fully ready
  depends_on = [
    aws_eks_cluster.example,
    helm_release.aws_load_balancer_controller
  ]
}