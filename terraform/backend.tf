terraform {
  backend "s3" {
    bucket = "labgrafana"
    key = "estado/tfstate"
    region = "sa-east-1"
    encrypt = true
    use_lockfile = true
  }
}