variable "jetstream_servers" {
  type = string
  description = "The JetStream servers to connect to"
}

variable "nats_credentials" {
  type = string
  description = "Path to file with NATS credentials"
}

variable "nats_ca_file" {
  type = string
  description = "Fully Qualified Path to a file containing Root CA (PEM format). Use when the server has certs signed by an unknown authority."
  default = ""
}

variable "polyn_env" {
  type = string
  description = "The environment terraform is running in"
  default = "development"
}