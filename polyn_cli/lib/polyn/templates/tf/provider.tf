provider "jetstream" {
  servers = var.jetstream_servers
  credentials = var.nats_credentials
  tls {
    ca_file = var.nats_ca_file
  }
}
