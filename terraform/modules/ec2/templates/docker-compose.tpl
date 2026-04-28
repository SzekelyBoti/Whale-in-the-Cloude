services:
  nginx:
    image: ${ecr_base}/${project}-nginx:latest
    ports:
      - "80:80"
    volumes:
      - /home/ec2-user/nginx.conf:/etc/nginx/nginx.conf:ro
    depends_on:
      - app1
      - app2
  app1:
    image: ${ecr_base}/${project}-app:latest
    environment:
      - PORT=3000
      - DB_HOST=${db_host}
      - DB_NAME=${db_name}
      - DB_USER=${db_username}
      - DB_PASSWORD=${db_password}
  app2:
    image: ${ecr_base}/${project}-app:latest
    environment:
      - PORT=3001
      - DB_HOST=${db_host}
      - DB_NAME=${db_name}
      - DB_USER=${db_username}
      - DB_PASSWORD=${db_password}