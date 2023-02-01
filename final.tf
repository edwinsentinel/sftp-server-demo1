provider "aws" {
  region = "us-west-2"
}

resource "aws_instance" "sftp_server" {
  ami           = "ami-0c55b159cbfafe1f0"
  instance_type = "t2.micro"

  tags = {
    Name = "sftp-server"
  }

  provisioner "remote-exec" {
    inline = [
      "sudo apt-get update",
      "sudo apt-get install -y openssh-server",
      "sudo sed -i 's/Subsystem/Subsystem\\tsftp\\tinternal-sftp/' /etc/ssh/sshd_config",
      "sudo systemctl restart ssh",
      "sudo useradd -m ftpuser",
      "sudo echo ftpuser:ftppass | sudo chpasswd",
      "sudo chown -R ftpuser:ftpuser /home/ftpuser",
    ]
  }
}

resource "aws_security_group" "sftp_security_group" {
  name        = "sftp_security_group"
  description = "Allow incoming SFTP connections"

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_s3_bucket" "sftp_bucket" {
  bucket = "my-sftp-bucket"
}

resource "aws_lambda_function" "sftp_processor" {
  filename      = "lambda_function.zip"
  function_name = "sftp_processor"
  role          = aws_iam_role.lambda_role.arn
  handler       = "index.handler"
  runtime       = "nodejs12.x"

  environment {
    variables = {
      SFTP_INSTANCE_IP = aws_instance.sftp_server.private_ip
    }
  }
}

resource "aws_iam_role" "lambda_role" {
  name = "lambda_role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17",
    Statement = [
      {
        Action = "sts:AssumeRole",
        Effect = "Allow",
        Principal = {
          Service = "lambda.amazonaws.com"
        }
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "lambda_s3_policy_attachment" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonS3FullAccess"
  role       = aws_iam_role.lambda_role.name
}

data "archive_file" "lambda_function" {
  type        = "zip"
  source_file = "lambda_function.js"
  output_path = "lambda_function.zip
