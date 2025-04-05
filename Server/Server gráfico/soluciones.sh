# Crea el fichero .Xauthority en tu directorio home
# sin sudo
touch /.Xauthority

# Si solo te funciona el entorno, pero no te funcionan
# herramientas como Firefox pon sin sudo:
xhost +SI:localuser:$USER
# Insistiendo un poco con el comando simplemente me 
# apareció adding the user.

# Esto no se si soluciona algo, pero si el resto no funciona
# para iniciar sesión con el usuario haz esto:
vim /etc/lightdm/lightdm.conf # Si no existe créalo
# Y después asegúrate de que dentro este esto:
[SeatDefaults]
user-session=xfce