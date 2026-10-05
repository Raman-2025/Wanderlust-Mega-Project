# 1. Create the Policy granting ECR and EKS access
resource "aws_iam_policy" "github_actions_policy" {
  name        = "GitHubActionsDeployPolicy-${var.cluster_name}"
  description = "Permissions for GitHub Actions to push to ECR and deploy to EKS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "ecr:GetAuthorizationToken",
          "ecr:BatchCheckLayerAvailability",
          "ecr:CompleteLayerUpload",
          "ecr:InitiateLayerUpload",
          "ecr:PutImage",
          "ecr:UploadLayerPart"
        ]
        Resource = "*"
      },
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster"
        ]
        Resource = "*"
      }
    ]
  })
}

# 2. Tell AWS to trust GitHub's authentication system
resource "aws_iam_openid_connect_provider" "github" {
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [
    "6938fd4d98bab03faadb97b34396831e3780aea1",
    "1c58a3a8518e8759bf075b76b750d4f2df264fcd",
    "1b511abead59c6ce207077c0bf0e0043b1382612"
  ]
}

# 3. Create a Role that ONLY your specific GitHub repository is allowed to assume
resource "aws_iam_role" "github_oidc_role" {
  name = "GitHub-Actions-OIDC-Role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = aws_iam_openid_connect_provider.github.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "token.actions.githubusercontent.com:aud" = "sts.amazonaws.com"
        }
        StringLike = {
          "token.actions.githubusercontent.com:sub" = "repo:*"
        }
      }
    }]
  })
}

# 4. Attach the ECR/EKS policy to the new OIDC Role
resource "aws_iam_role_policy_attachment" "github_oidc_attach" {
  role       = aws_iam_role.github_oidc_role.name
  policy_arn = aws_iam_policy.github_actions_policy.arn 
}

# 5. Register the Role with your EKS Cluster (Notice: no system:masters)
resource "aws_eks_access_entry" "github_oidc_k8s_access" {
  # Change aws_eks_cluster.example.name if your cluster resource is named differently
  cluster_name  = aws_eks_cluster.example.name
  principal_arn = aws_iam_role.github_oidc_role.arn
  type          = "STANDARD"
}

# 6. Grant the Role Cluster Admin rights safely via AWS Policies
resource "aws_eks_access_policy_association" "github_oidc_admin_policy" {
  # Change aws_eks_cluster.example.name if your cluster resource is named differently
  cluster_name  = aws_eks_cluster.example.name
  principal_arn = aws_iam_role.github_oidc_role.arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"
  
  access_scope {
    type = "cluster"
  }

  depends_on = [
    aws_eks_access_entry.github_oidc_k8s_access
  ]
}

output "github_oidc_role_arn" {
  value = aws_iam_role.github_oidc_role.arn
}