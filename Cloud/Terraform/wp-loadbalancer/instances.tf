resource "aws_instance" "wp_instance" {
  count                  = 2
  ami                    = "ami-0e2c8caa4b6378d8c"
  instance_type          = "t2.micro"
  subnet_id              = aws_subnet.wp_subnet[0].id
  vpc_security_group_ids = [aws_security_group.wp_sg.id]

  user_data = <<-EOF
              #!/bin/bash
              exec > /var/log/user-data.log 2>&1

              sudo rm -rf /var/www/html/*
              sudo apt-get update -y
              sudo DEBIAN_FRONTEND=noninteractive apt-get install -y \
                apache2 \
                php \
                libapache2-mod-php \
                php-mysql \
                mysql-client

              sudo a2enmod rewrite
              sudo systemctl start apache2
              sudo systemctl enable apache2

              wget https://wordpress.org/latest.tar.gz -P /tmp
              tar -xzf /tmp/latest.tar.gz -C /var/www/html --strip-components=1

              RDS_ENDPOINT="${aws_db_instance.wp_db.endpoint}"
              RDS_ENDPOINT_WITHOUT_PORT=$${RDS_ENDPOINT%%:*}

              sudo cp /var/www/html/wp-config-sample.php /var/www/html/wp-config.php
              sudo sed -i "s/database_name_here/${aws_db_instance.wp_db.db_name}/" /var/www/html/wp-config.php
              sudo sed -i "s/username_here/${aws_db_instance.wp_db.username}/" /var/www/html/wp-config.php
              sudo sed -i "s/password_here/${aws_db_instance.wp_db.password}/" /var/www/html/wp-config.php
              sudo sed -i "s/localhost/$RDS_ENDPOINT_WITHOUT_PORT/" /var/www/html/wp-config.php

              sudo chown -R www-data:www-data /var/www/html
              sudo systemctl restart apache2

              sudo rm -f /var/www/html/index.html
              EOF

  tags = { Name = "wp_instance" }

  lifecycle {
    ignore_changes = [user_data]
  }
}
