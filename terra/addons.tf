### addons ####
resource "aws_eks_addon" "aws-ebs-csi-driver" {
  cluster_name = aws_eks_cluster.example.name
  addon_name   = "aws-ebs-csi-driver"
  
  # Inherits permissions from the worker node role you already created
  resolve_conflicts_on_create = "OVERWRITE"
  resolve_conflicts_on_update = "PRESERVE"
  
  depends_on = [
    aws_eks_node_group.example,
    aws_eks_pod_identity_association.ebs_csi_assoc
  ]
}

resource "aws_eks_addon" "coredns" {
  cluster_name = aws_eks_cluster.example.name 
  addon_name   = "coredns"
  depends_on   = [aws_eks_node_group.example]
}

resource "aws_eks_addon" "kube_proxy" {
  cluster_name = aws_eks_cluster.example.name
  addon_name   = "kube-proxy"
}

resource "aws_eks_addon" "vpc_cni" {
  cluster_name = aws_eks_cluster.example.name
  addon_name   = "vpc-cni"
}

resource "aws_eks_addon" "eks-pod-identity-agent" {
  cluster_name = aws_eks_cluster.example.name
  addon_name   = "eks-pod-identity-agent"
}






#### Dedicated IAM Role for the EBS CSI Pod ####
resource "aws_iam_role" "ebs_csi_pod_role" {
  name = "ebs-csi-pod-role-${var.cluster_name}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Principal = {
          Service = "pods.eks.amazonaws.com"
        }
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
      }
    ]
  })
}

# Attach the EBS CSI Policy to the new Pod Role
resource "aws_iam_role_policy_attachment" "ebs_csi_pod_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEBSCSIDriverPolicy"
  role       = aws_iam_role.ebs_csi_pod_role.name
}

#### Link the IAM Role directly to the Kubernetes Service Account ####
resource "aws_eks_pod_identity_association" "ebs_csi_assoc" {
  cluster_name    = aws_eks_cluster.example.name
  namespace       = "kube-system"
  service_account = "ebs-csi-controller-sa"
  role_arn        = aws_iam_role.ebs_csi_pod_role.arn
}







resource "aws_iam_policy" "alb_controller_policy" {
  name   = "AWSLoadBalancerControllerIAMPolicy-${var.cluster_name}"
  policy = file("${path.module}/iam_policy.json")
}

resource "aws_iam_role" "alb_controller_role" {
  name = "alb-controller-role-${var.cluster_name}"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = { Service = "pods.eks.amazonaws.com" }
      Action = ["sts:AssumeRole", "sts:TagSession"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
  policy_arn = aws_iam_policy.alb_controller_policy.arn
  role       = aws_iam_role.alb_controller_role.name
}

resource "aws_eks_pod_identity_association" "alb_controller_assoc" {
  cluster_name    = aws_eks_cluster.example.name
  namespace       = "kube-system"
  service_account = "aws-load-balancer-controller"
  role_arn        = aws_iam_role.alb_controller_role.arn
}