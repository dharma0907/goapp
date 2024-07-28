//Finally, we got to the EKS cluster. Kubernetes clusters managed by Amazon EKS make calls to other AWS services on your behalf to manage the resources that you use with the service. For example, EKS will create an autoscaling group for each instance group if you use managed nodes. Before you can create Amazon EKS clusters, you must create an IAM role with the AmazonEKSClusterPolicy. 
resource "aws_iam_role" "democluster" {
    name = "eks_demoCluster"
   assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
}

resource "aws_iam_role_policy_attachment" "demo-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.democluster.name
}

// after creating above policy, now we will create eks cluster

resource "aws_eks_cluster" "democluster" {
    name = "dmocluster"
    role_arn = aws_iam_role.democluster.arn

    vpc_config {
      subnet_ids = [ aws_subnet.private_subnet1.id,aws_subnet.private_subnet2.id,
                     aws_subnet.public_subnet1.id, aws_subnet.public_subnet2.id ]
                                                                
    }
    depends_on = [ aws_iam_role_policy_attachment.demo-AmazonEKSClusterPolicy] 
}
//***************************************ABOVE PART WILL CREATE A****************************************************************///
// now creating node group, you can create single or multiple nodes depends upon requirement Similar to the EKS cluster, it requires an IAM role as well.

resource "aws_iam_role" "nodes" {
  name = "eks-node-group-nodes"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.nodes.name
}

resource "aws_iam_role_policy_attachment" "nodes-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.nodes.name
}
//WE ARE CREATING 3 NODE CLUSTER
resource "aws_eks_node_group" "private-nodes" {
  cluster_name    = aws_eks_cluster.democluster.id
  node_group_name = "private-nodes"
  node_role_arn   = aws_iam_role.nodes.arn

  subnet_ids = [
    aws_subnet.private_subnet1.id,
    aws_subnet.private_subnet2.id
  ]

  capacity_type  = "ON_DEMAND"
  instance_types = ["t2.small"]

  remote_access {
    ec2_ssh_key = "mahi-keyvaluepair"
    source_security_group_ids = [aws_security_group.worker_node_sg.id]
  }

  scaling_config {
    desired_size = 3
    max_size     = 5
    min_size     = 0
  }

  update_config {
    max_unavailable = 1
  }

  labels = {
    role = "general"
  }

  # taint {
  #   key    = "team"
  #   value  = "devops"
  #   effect = "NO_SCHEDULE"
  # }

  # launch_template {
  #   name    = aws_launch_template.eks-with-disks.name
  #   version = aws_launch_template.eks-with-disks.latest_version
  # }

  depends_on = [
    aws_iam_role_policy_attachment.nodes-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.nodes-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.nodes-AmazonEC2ContainerRegistryReadOnly,
  ]
}

# resource "aws_launch_template" "eks-with-disks" {
#   name = "eks-with-disks"

#   key_name = "local-provisioner"

#   block_device_mappings {
#     device_name = "/dev/xvdb"

#     ebs {
#       volume_size = 50
#       volume_type = "gp2"
#     }
#   }
# }


// creating iam OIDC openIDconnection

//To manage permissions for your applications that you deploy in Kubernetes. 
//You can either attach policies to Kubernetes nodes directly. In that case, every pod will get the same access to AWS resources. Or you can create OpenID connect provider, which will allow granting IAM permissions based on the service account used by the pod


data "tls_certificate" "eks" {
  url = aws_eks_cluster.democluster.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "eks" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.eks.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.democluster.identity[0].oidc[0].issuer
}
