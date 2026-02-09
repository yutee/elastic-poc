# Spinnging up elastic

To bring up elastic and kibana, we will be using SSL with insecure certs. This is to avoid back and forth with recent security measures in version 9.x.

These are the steps to follow:
```bash
cd ~/poc

# 1. Stop everything and clean up
docker compose down -v
rm -rf certs

# 2. Create certificate directory
mkdir -p certs

# 3. Generate CA certificate
docker run --rm \
  -v "$(pwd)/certs:/certs" \
  docker.elastic.co/elasticsearch/elasticsearch:9.3.0 \
  bin/elasticsearch-certutil ca --pem --out /certs/ca.zip --pass ""

# 4. Extract CA
docker run --rm \
  -v "$(pwd)/certs:/certs" \
  docker.elastic.co/elasticsearch/elasticsearch:9.3.0 \
  bash -c "cd /certs && unzip -o ca.zip"

# 5. Generate instance certificates
docker run --rm \
  -v "$(pwd)/certs:/certs" \
  docker.elastic.co/elasticsearch/elasticsearch:9.3.0 \
  bin/elasticsearch-certutil cert \
  --ca-cert /certs/ca/ca.crt \
  --ca-key /certs/ca/ca.key \
  --pem \
  --out /certs/certs.zip \
  --pass "" \
  --dns elasticsearch \
  --dns localhost \
  --ip 127.0.0.1
  
# OR

docker run --rm \
  -v "$(pwd)/certs:/certs" \
  docker.elastic.co/elasticsearch/elasticsearch:9.3.0 \
  bin/elasticsearch-certutil cert \
  --ca-cert /certs/ca/ca.crt \
  --ca-key /certs/ca/ca.key \
  --pem \
  --out /certs/certs.zip \
  --dns elasticsearch \
  --dns localhost \
  --ip 127.0.0.1  

# 6. Extract instance certificates
docker run --rm \
  -v "$(pwd)/certs:/certs" \
  docker.elastic.co/elasticsearch/elasticsearch:9.3.0 \
  bash -c "cd /certs && unzip -o certs.zip"

# 7. Set permissions
chmod -R 755 certs

# 8. Replace your docker-compose.yml and .env with the new ones

# 9. Start Elasticsearch first
docker compose up -d elasticsearch
sleep 30

# 10. Set kibana_system password
docker exec elasticsearch curl -s -X POST \
  --cacert /usr/share/elasticsearch/config/certs/ca/ca.crt \
  -u elastic:elastic \
  "https://localhost:9200/_security/user/kibana_system/_password" \
  -H "Content-Type: application/json" \
  -d '{"password":"elastic"}'

# 11. Start Kibana
docker compose up -d kibana

# 12. Wait and check logs
sleep 45
docker logs kibana --tail 30
```