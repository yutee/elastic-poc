folder structure 1:
```bash
[root@d-siemdatapoc elastic-poc]# tree -L 10
.
├── certs
│   ├── ca
│   │   ├── ca.crt
│   │   └── ca.key
│   ├── ca.zip
│   ├── certs.zip
│   ├── es02-extracted
│   │   └── es02
│   │       ├── es02.crt
│   │       └── es02.key
│   ├── es02.zip
│   └── instance
│       ├── instance.crt
│       └── instance.key
├── configs
│   ├── elasticsearch.yaml
│   └── kibana.yaml
├── docker-compose.yaml
├── docker-compose.yaml.bak
├── new_certs_temp
│   └── instance
│       ├── instance.crt
│       └── instance.key
├── new_certs.zip
├── README.md
└── scripts
    ├── install-agent-linux.sh
    └── install-agent-windows.ps1

9 directories, 19 files
```

folder structure 2:
```bash
[Smeuser@d-siemintpoc elastic-poc]$ tree -L 10
.
├── artifacts
│   ├── agent
│   └── endpoint
├── certs
│   ├── ca
│   │   └── ca.crt
│   └── instance
│       ├── es02.crt
│       └── es02.key
├── configs
│   └── nginx-artifacts.conf
└── docker-compose.yaml

7 directories, 5 files
```

had to run commands to gen cert
```bash
cd ~/elastic-poc

docker run --rm \
  -v "$(pwd)/certs:/certs" \
  docker.elastic.co/elasticsearch/elasticsearch:9.3.0 \
  bin/elasticsearch-certutil cert \
  --ca-cert /certs/ca/ca.crt \
  --ca-key /certs/ca/ca.key \
  --pem \
  --out /certs/es02.zip \
  --name es02 \
  --dns es02 \
  --dns localhost \
  --ip 127.0.0.1 \
  --ip <server2-ip>

docker run --rm \
  -v "$(pwd)/certs:/certs" \
  docker.elastic.co/elasticsearch/elasticsearch:9.3.0 \
  bash -c "cd /certs && unzip -o es02.zip -d es02-extracted"

chmod -R 755 certs
```

then nginx config:
```
server {
    listen 80;
    server_name artifact-server;

    # Elastic Agent binaries
    # Fleet will request paths like /agent/elastic-agent-9.3.0-linux-x86_64.tar.gz
    location /agent/ {
        alias /usr/share/nginx/html/agent/;
        autoindex on;
        add_header Content-Type application/octet-stream;
    }

    # Endpoint security artifacts (placeholder for future use)
    location /endpoint/ {
        alias /usr/share/nginx/html/endpoint/;
        autoindex on;
    }

    # Health check endpoint
    location /health {
        return 200 "ok\n";
        add_header Content-Type text/plain;
    }
}
```

images pulled for server 2
```bash
# Set your stack version
export STACK_VERSION=9.3.0

docker pull docker.elastic.co/elasticsearch/elasticsearch:${STACK_VERSION}
docker pull docker.elastic.co/package-registry/distribution:lite-${STACK_VERSION}
docker pull nginx:stable-alpine
```