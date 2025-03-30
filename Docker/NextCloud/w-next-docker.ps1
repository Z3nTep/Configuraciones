# Montar el volumen
docker volume create `
--driver local `
--name nextcloud_aio_nextcloud_datadir `
-o device="W:/NextCloud" `
-o type="none" `
-o o="bind"

# Arrancar el contenedor.
docker run `
--sig-proxy=false `
--name nextcloud-aio-mastercontainer `
--publish 5.0.0.1:80:80 `
--publish 5.0.0.1:8080:8080 `
--publish 5.0.0.1:8443:8443 `
--volume nextcloud_aio_mastercontainer:/mnt/docker-aio-config `
--volume //var/run/docker.sock:/var/run/docker.sock:ro `
-e NEXTCLOUD_DATADIR="nextcloud_aio_nextcloud_datadir" `
nextcloud/all-in-one:latest