job "request-splitter" {
  datacenters=["dc1"]
  group "request-splitter" {
    task "app-container" {

    }
    task "request-splitter-ambassador"{
      driver = "docker"
      config {
        image = "nginx"
        port_map {
          https = 443
        }
        volumes = [
          "config/nginx.conf:/etc/nginx/nginx.conf",
        ]
      }
      resources {
        network {
          mbits = 10
          port "https" {}
        }
      }
      template {
        data = <<EOF
          worker_processes  3;
          events {
            worker_connections  1024;
          }
          http {
            upstream app_stable {
              {{ range service "app-server-stable" }}
              server {{.Address}}:{{.Port}} {{end}}
            }
            upstream app_experimental {
              {{ range service "app-server-experimental" }}
              server {{.Address}}:{{.Port}} {{end}}
            }
            split_clients "${remote_addr}" $appversion {
              95%     app_stable;
              *       app_experimental;
            }
            server {
              listen 80;
              location / {
                proxy_set_header Host $host;
                proxy_pass http://$appversion;
              }
            }
          }
        EOF
        destination = "config/nginx.conf"
      }
    }
  }
}
