terraform {
  backend "s3" {
    bucket = "labgrafanagoku"
    key = "estado/tfstate"
    region = "sa-east-1"
    encrypt = true
    use_lockfile = true
  }
}