1. Crear Lambda
	- Vamos al servicio Lambda
	- Creamos una función
		· La llamaremos:	 	Arranca/Apaga EC2
		· Tipo de ejecución: 	Python 3.13
		· Usar rol existente:	LabRole
		· Habilitamos la VPC:	Seleccionamos nuestra VPC
	- Y creamos la función

2. Entramos en la función recién creada
	- Vamos a código y aqui hacemos lo siguiente:
		· Dentro del editor creamos un archivo llamado start-instance.py
		· Y pegamos la plantilla esta:
		  Créditos a Cultura DevOPS: https://github.com/culturadevops/lambda-template
			import boto3
			import json

			region = 'us-east-1'
			instances = ['i-06940c7dcc6581130']

			def lambda_handler(event, context):
				ec2 = boto3.client('ec2', region_name=region)
				ec2.start_instances(InstanceIds=instances)		# Si se quiere apagar, cambia start por stop

				return {
					'statusCode': 200,
					'body': json.dumps('started your instances: ' + str(instances))	# Aquí pon stopped en vez de started
				}
		· Le damos a Deploy en el menú de la izquierda
	- Ahora vamos a Configuración del tiempo de ejecución y le damos a Editar
		· Tiempo de ejecución:	Python 3.13
		· Controlador: start-instance.lambda_handler
		· Guardar

3. Vamos a Configuración dentro de la función:
	- Editamos la configuración general:
	- Ponemos que el tiempo de espera sea de 30 segundos
	- Guardamos

4. Dentro de la función nos dirigiremos a Test
	- Lo llamamos:	Test
	- Cambiamos el código dentro del JSON de:
		· Antes:
			{
			  "key1": "value1",
			  "key2": "value2",
			  "key3": "value3"
			}
		· Después:
			{
			
			}
	- Y le damos al botón naranja Test
		· Si sale un cuadro en verde significa que se ejecutó con éxito

5. Comprobamos dentro de las EC2 si se ha apagado/arrancado correctamente
