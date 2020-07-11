job "service" {
  datacenters=["dc1"]
  group "service" {
    task "service-stable" {
      driver = "docker"
      config {
        image = "hashicorp/http-echo:0.2.1"
        args  = [
          "-listen", ":8080",
          "-text", "Hello World!",
        ]
      }

      resources {
        network {
          mbits = 10
          port "http" {}
        }
      }
      service {
        name = "service-stable"
        tags = ["http", "stable"]
        port = "http"
      }
    }

    task "service-experimental" {
      driver = "docker"
      config {
        image = "hashicorp/http-echo:0.2.3"
        args  = [
          "-listen", ":8080",
          "-text", "Hello World!",
        ]
      }

      resources {
        network {
          mbits = 10
          port "http" {}
        }
      }
      service {
        name = "service-experimental"
        tags = ["http", "experimental"]
        port = "http"
      }
    }
  }
}
