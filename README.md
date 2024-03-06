# creating-vpc-alb-and-s3-using-terraform

Here is the diagram 

![image](https://github.com/k-gopi-krishna/creating-vpc-alb-and-s3-using-terraform/assets/119429981/8267f066-e7e8-4d2d-8d2d-46b79f139a5a)


Inorder to run the configuration follow these commands

terraform init

terraform plan

terraform apply -auto-approve

#to destroy all the resources created 

terraform destroy -auto-approve

Note: Please change the name of the s3 bucket (should be globally unique)

Explaination:

Here we are creating a custom vpc with 2 public subnets 

Creating an Internet Gateway inorder to connect vpc to the internet

Instances are hosted in both the public subnets and load is equaly distributed using Application Load Balancer

Creating an S3 bucket by allowing public access so instances can access without creating an IAM Role

