## Primero:
#### Crea esta estructura de directorios:
###### server-minecraft/
###### ├── data # Directorio
###### └── docker-compose.yml

#### Después copia y pega el contenido del fichero .yml del servidor que busques tener en docker-compose.yml.
#### Si es un servidor con mods, deberas de añadir dentro de la carpeta que no es data los mods que quieras tener.

#### Esta página te lo hace todo: https://setupmc.com/java-server/

#### Finalmente ejecuta
###### sudo docker-compose up
#### O si quieres hacerlo en segundo plano
###### sudo docker-compose up -d