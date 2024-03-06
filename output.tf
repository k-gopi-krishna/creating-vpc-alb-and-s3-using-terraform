output "lb-ep" {    #outputting the dns name of the load balancer
  value = aws_lb.myalbp2.dns_name

}
