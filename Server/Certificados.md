# Cómo crear certificados SSL

A continuación se muestran los comandos para generar certificados SSL tanto con **OpenSSL** (autofirmado) como con **Let's Encrypt/Certbot**.

---

## Certificado autofirmado con OpenSSL

```
openssl req -x509 -nodes -days 365 -newkey rsa:2048 -keyout n8n-certs/privkey.pem -out n8n-certs/cert.pem -subj "/CN=tu-dominio.com"
chmod 600 n8n-certs/privkey.pem n8n-certs/cert.pem
```

---

## Certificado válido con Let's Encrypt/Certbot

```
sudo certbot certonly --standalone -d tu-dominio.com --non-interactive --agree-tos -m tu-email@dominio.com
sudo mkdir -p n8n-certs
sudo cp /etc/letsencrypt/live/tu-dominio.com/fullchain.pem /etc/letsencrypt/live/tu-dominio.com/privkey.pem n8n-certs/
```
