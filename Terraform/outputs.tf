output "public_ip" {
  value = aws_instance.my-infra.public_ip
}

output "instance_id" {
  value = aws_instance.my-infra.id
}

output "private_key_path" {
  value = local_file.private_key.filename
}