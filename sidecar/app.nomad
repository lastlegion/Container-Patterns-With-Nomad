job "ssl-proxy-example" {
  datacenters=["dc1"]
  group "ssl-proxy" {
    task "app-server" {
      driver = "docker"

      config {
        image = "hashicorp/http-echo:latest"
        args  = [
          "-listen", ":8080",
          "-text", "Hello World!",
        ]
      }

      resources {
        network {
          mbits = 10
          port "http" {
            static = 8080
          }
        }
      }
      service {
        name = "app-server"
        port = "http"
      }
    }

    task "ssl-proxy-sidecar"{
      driver = "docker"
      config {
        image = "nginx"
        port_map {
          https = 443
        }
        volumes = [
          "config/nginx.conf:/etc/nginx/nginx.conf",
          "secrets/certificate.crt:/secrets/certificate.crt",
          "secrets/certificate.key:/secrets/certificate.key",
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
          worker_processes  1;
          events {
              worker_connections  1024;
          }
          http {
              include       mime.types;
              default_type  application/octet-stream;
              sendfile        on;
              keepalive_timeout  65;
              server {
                listen       443 ssl;
                server_name  localhost;
                ssl_certificate      /secrets/certificate.crt;
                ssl_certificate_key  /secrets/certificate.key;
                location / {
                  proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
                  proxy_set_header Host $http_host;
                  proxy_pass http://{{ env "NOMAD_ADDR_app_server_http" }};
                }
              }
          }
        EOF
        destination = "config/nginx.conf"
      }
      template {
        # Warning: Fetch certificate from a secret store like vault for prod
        data = <<EOF
-----BEGIN CERTIFICATE-----
MIIDajCCAlKgAwIBAgITPAgZrdQO2jRhM/KkR8Czc1iC+jANBgkqhkiG9w0BAQsF
ADBFMQswCQYDVQQGEwJBVTETMBEGA1UECAwKU29tZS1TdGF0ZTEhMB8GA1UECgwY
SW50ZXJuZXQgV2lkZ2l0cyBQdHkgTHRkMB4XDTIwMDYyODE5NTA0MVoXDTIxMDYy
ODE5NTA0MVowRTELMAkGA1UEBhMCQVUxEzARBgNVBAgMClNvbWUtU3RhdGUxITAf
BgNVBAoMGEludGVybmV0IFdpZGdpdHMgUHR5IEx0ZDCCASIwDQYJKoZIhvcNAQEB
BQADggEPADCCAQoCggEBAO1F4ucwIZ8zqMiijXioT+wBs588crkY6iwKrG7pyqmL
2rZSQ/79AvypH9J6tmw4lcOJC0l5mcjUdgmg38r0A2AqRVtr5vp0r31/y3NhN7SA
UkKzBn3Ov5J+/ZIs5qhxt9YOZ+hYYk/Jbf1IBWdb8Dvp+QIW4FSoe7evnjwpwxFm
UtY/2Wg6gXVxaxxxtuWN4p/l/CZgpSugHeXyoGZU+DkND8XJsQj7kFcpwA13/k6b
1qPDS4hxtH0KQ3a1g9pleAcKB9tXV/2gCjGZw9Xh750J5S4IcdI47Rp1zH2JWEj6
das9qu5C3AYH7Q30ErLkiLmHaLfkRv5YChk59xidmA0CAwEAAaNTMFEwHQYDVR0O
BBYEFDFdXOVa/V45p+oYtRWCU9NW/xH9MB8GA1UdIwQYMBaAFDFdXOVa/V45p+oY
tRWCU9NW/xH9MA8GA1UdEwEB/wQFMAMBAf8wDQYJKoZIhvcNAQELBQADggEBAIaa
wR7FbprGRuWkqkcUOQ14v8550xwDercuOfsHmzLKbAWJmxWsuuADmafmu5Hbsso6
feXGmyjdZcd+vLEJAwp3d4fyohJCIw0RA6Z7vCdpogex16LyAStRjtVs52jcdRVK
yxU6rF+qxxQySJfujV0x/rkvc7AxNyoc/BHv7S8r5EpHJZyv7FtoRiEdJ2JxM1Ox
5TVuMkjqGXGrek4hKIrOmAMcCppgGubRtcq9HUHfiitGZIM3d00u0sfYbxxJks1Z
jlw8JveeVvRFTvdwW23+JHnTvqpremm5PhmvPPnRNOhR1WhKxvJWWdeYDBjBoaPo
vAIDwNat6MpbCNH6pSs=
-----END CERTIFICATE-----
        EOF
        destination = "secrets/certificate.crt"
      }
      template {
        # Warning: Fetch certificate from a secret store like vault for prod.
        data = <<EOF
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQDtReLnMCGfM6jI
oo14qE/sAbOfPHK5GOosCqxu6cqpi9q2UkP+/QL8qR/SerZsOJXDiQtJeZnI1HYJ
oN/K9ANgKkVba+b6dK99f8tzYTe0gFJCswZ9zr+Sfv2SLOaocbfWDmfoWGJPyW39
SAVnW/A76fkCFuBUqHu3r548KcMRZlLWP9loOoF1cWsccbbljeKf5fwmYKUroB3l
8qBmVPg5DQ/FybEI+5BXKcANd/5Om9ajw0uIcbR9CkN2tYPaZXgHCgfbV1f9oAox
mcPV4e+dCeUuCHHSOO0adcx9iVhI+nWrParuQtwGB+0N9BKy5Ii5h2i35Eb+WAoZ
OfcYnZgNAgMBAAECggEBAI1t0sorDl9u03SEL/9zk/ABM6f+yAM8rpiB5DZYdMyK
6Fs0vgMHnPgtdyJmssXfFKXw0iGBsgDbY2Bp2/uFZ12y1JShxJQVaWVM/2BO2n1k
36OSQpRK4DXaLBstWG+fGQ0mmRkNVcxpLH6Ep3PsgU21MQ/lwuGza8sZiyAhZHzB
cz8/0X4DZFdVRJQO0IZu8a4NSGeVoXf1eQBSyliuSVpAwkaldZZMRu3maTC8L4Kl
7CVybw3FjzOkF98emcdqNmdUTwbT5ps3EjoK4FbnuGDDWu6jwsb5+A8EVtaY83VT
UGu67Byew6GdovdMmPPMctb4NbusP+NJK3eZDQkAy6ECgYEA/bSHhoSdOUDPCVaB
/pRJ8kQv0mzKXZqcJs+DbmkQEegohiVMaldlWwBjWIRxhAIJfp4ytweAzhQZOUB9
Ne8A49iGl3CHjqvtegcfX18EOiAF1LBTnwgalRybzU6rX9zc9ReNaSeZjTMenKNU
lYxw3HlRYT/K8B4M12ja+5wWpisCgYEA72tOoGPe56uHGChETonI8eX3wk6zobQz
Z7b+JUeAVpxSL0ypIS8VkjmXOe32zO5uEoi+8sQEXsYigfxnOHABqe2/osdg0NJr
pX8PvaFvq3i+rffRH+QyKth+rvNqnjUF0fMVVjm4JJ4pZu17rgJmNUWkuUZ9gOzr
8lszR85ulqcCgYEA66tdETnzCpIHQDdZvfBl2GQ6wA9K1DSgxPSStGdoBBpSOno/
R7Ezd5sercUp5WQ3CaVOmvKfVc8ZtzMOnKENhJlIPTjM010l1erz25XZyVyhzfaV
Vu8iMk1G9SoUy5HQtuNP+tRMMPvBfePC2MCCvmr7i4jErNRdPWQrtvpBl80CgYBZ
CRrwYrOejBdtUGw2mN71toPw6ru6wvzq8Q6KZpC/pNqbZHLxOEVZX7lxfaFujKy6
j8gTF/pYFG740BjC0ESOITBHJMZIYjhOD3aXGtYgeoLOx34p0f8mF+Tkwvk/ZJCJ
h1DEBCsK0xaqhF6eU54W6ZNco25A59rHAkuLxKUzuQKBgD8uJpOp13W1tYJJosPO
YqJoqwedOmyE5ZWGASr7L0gm3cNSVN2ANhytjby4FpFU2hM3wUB9SjWQs2dxE1a/
EFG7bYgACbS289cpWA2nmcfhhGn7tV26xLuMFma0GQhr6jpQbuqONbrnlyRJGvMr
7iyk7nrNu9Ez3yM9zVMuvIJH
-----END PRIVATE KEY-----
        EOF
        destination = "secrets/certificate.key"
      }
    }
  }
}
