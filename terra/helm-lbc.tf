resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"

  # Pass variables directly into the Helm chart
  set {
    name  = "clusterName"
    value = aws_eks_cluster.example.name 
  }

  set {
    name  = "serviceAccount.create"
    value = "true"
  }

  set {
    name  = "serviceAccount.name"
    value = "aws-load-balancer-controller"
  }

  set {
    name  = "vpcId"
    value =  aws_vpc.main.id
  }

  set {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    # CHANGE THIS to the IAM Role ARN you created for the Load Balancer Controller
    value = "arn:aws:iam::945714973951:role/AmazonEKSLoadBalancerControllerRole"
  }

  depends_on = [aws_eks_cluster.example]
}