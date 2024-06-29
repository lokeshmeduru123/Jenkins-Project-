module "jenkins" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins-tf"

  instance_type          = "t3.small"
  vpc_security_group_ids = ["sg-0fbd7c454bc70bbba"] #replace your SG
  subnet_id = "subnet-035dd07111bfc7dac" #replace your Subnet
  ami = data.aws_ami.ami_info.id
  user_data = file("jenkins.sh")
  tags = {
    Name = "jenkins-tf"
  }
}

module "jenkins_agent" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "jenkins-agent"

  instance_type = "t3.small"
  vpc_security_group_ids = ["sg-0fbd7c454bc70bbba"]
  # convert StringList to list and get first element
  subnet_id = "subnet-035dd07111bfc7dac"
  ami = data.aws_ami.ami_info.id
  user_data = file("jenkins-agent.sh")
  tags = {
    Name = "jenkins-agent"
  }
}

resource "aws_key_pair" "tools" {
  key_name   = "tools"
  # you can paste the public key directly like this
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABgQDRgTmkO3Xr0LEImSNtSN82XNMU0Arp/FsZRq7TpGSnI6GkywpxLWt4GRKupiAOMI/Lk+iTiyWIZaMdOV1mq4bCkWtwn3N7gVefKNOsW/7DwOzP1qaxKBr7lIqLndYEG9MjePK/z1mLP14UtABcHXwZpfA1iQeOnMf+7/45BZL9lRzQod1iqGRRT3UaPIqT5SNxSD+z68oy6A2v547GmyfpfHT2CTNIBEWlKW3lHOb1wP/18tJVVObzsKRGzscpYGKEXr9P7TWLfgbS6K6HzVZm87iD2Q2FYFQRWf2D+cjAxTPG8NJQKdyfcPI3/G+mdRvFLc74QK8qPNKQqodwj5UoMNouQXD+VA6VAKp/GFz+yX6WSKtxIBYYtGNOmbeEEtMESf9dsW/y9FzpmbMoFk53rCAjS0bq8UF7vmhN3E/yNfyPxS9ZK2BrXRgEgMZjogVHrWmdVbhYUlaEsPM7LPH+bT8irpfJ5+HBO8crI2difpOvQt+wr+LqWTVEkvSAwss= lokes@DESKTOP-ALATB33"
  #public_key = file("~/.ssh/tools.pub")
  # ~ means windows home directory
}

module "nexus" {
  source  = "terraform-aws-modules/ec2-instance/aws"

  name = "nexus"

  instance_type          = "t3.medium"
  vpc_security_group_ids = ["sg-0fbd7c454bc70bbba"]
  # convert StringList to list and get first element
  subnet_id = "subnet-035dd07111bfc7dac"
  ami = data.aws_ami.nexus_ami_info.id
  key_name = aws_key_pair.tools.key_name
  root_block_device = [
    {
      volume_type = "gp3"
      volume_size = 30
    }
  ]
  tags = {
    Name = "nexus"
  }
}

module "records" {
  source  = "terraform-aws-modules/route53/aws//modules/records"
  version = "~> 2.0"

  zone_name = var.zone_name

  records = [
    {
      name    = "jenkins"
      type    = "A"
      ttl     = 1
      records = [
        module.jenkins.public_ip
      ]
      allow_overwrite = true
    },
    {
      name    = "jenkins-agent"
      type    = "A"
      ttl     = 1
      records = [
        module.jenkins_agent.private_ip
      ]
      allow_overwrite = true
    },
    {
      name    = "nexus"
      type    = "A"
      ttl     = 1
      allow_overwrite = true
      records = [
        module.nexus.public_ip
      ]
      allow_overwrite = true
    }
  ]

}