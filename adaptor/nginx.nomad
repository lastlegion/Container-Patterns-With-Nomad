job "nginx" {
  datacenters=["dc1"]
  group "nginx" {
    task "app-nginx"{
      driver = "docker"
      config {
        image = "nginx"
        port_map {
          http = 80
        }
        volumes = [
          "config/nginx.conf:/etc/nginx/nginx.conf",
        ]
      }
      resources {
        network {
          mbits = 10
          port "http" {}
        }
      }
      template {
        data = <<EOF
          worker_processes  3;
          events {
            worker_connections  1024;
          }
          http {
            server {
              location /status {
                stub_status;
                access_log off;
              }
            }
          }
        EOF
        destination = "config/nginx.conf"
      }
    }
    task "adaptor-nginx-exporter" {
			driver = "docker"
			config {
				image = "nginx/nginx-prometheus-exporter:0.8.0"
				args = [
					"--nginx.scrape-uri", "http://${NOMAD_ADDR_service_nginx_http}/status"
				]
				port_map {
					http = 9113
				}
			}
			resources{
				network {
					mbits = 10
					port "http" {}
				}
			}
  	}
	}
}
