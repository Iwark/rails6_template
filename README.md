# Rails6 template

```
rails new project_name -m https://raw.githubusercontent.com/Iwark/rails6_template/master/app_template.rb
```

## Deploy

EC2

```
sudo yum update -y
sudo yum install -y zsh git gcc patch gcc-c++ readline readline-devel zlib zlib-devel libyaml-devel libffi-devel openssl-devel make bzip2 autoconf automake libtool bison iconv-devel util-linux-user libxml2-devel libxslt-devel ruby-devel gcc* make postgresql-devel
git clone git://github.com/robbyrussell/oh-my-zsh.git ~/.oh-my-zsh
cp ~/.oh-my-zsh/templates/zshrc.zsh-template ~/.zshrc

sudo passwd ec2-user
chsh -s /bin/zsh

git clone https://github.com/sstephenson/rbenv.git ~/.rbenv
echo 'export PATH="$HOME/.rbenv/bin:$PATH"' >> ~/.zshrc
echo 'eval "$(rbenv init -)"' >> ~/.zshrc
git clone git://github.com/sstephenson/ruby-build.git
cd ruby-build
sudo ./install.sh
source ~/.zshrc

rbenv install 2.6.5
rbenv global 2.6.5
rbenv rehash
gem install bundler

sudo amazon-linux-extras install postgresql11 -y

sudo amazon-linux-extras install nginx1 -y
curl --silent --location https://rpm.nodesource.com/setup_12.x | sudo bash -
sudo yum -y install nodejs
sudo npm install -g yarn

sudo yum install ImageMagick ImageMagick-devel -y
sudo yum install rpm-build -y

sudo cp -p /usr/share/zoneinfo/Japan /etc/localtime

sudo dd if=/dev/zero of=/swap.img bs=1M count=2048
sudo chmod 600 /swap.img
sudo mkswap /swap.img
sudo bash -c 'echo "/swap.img    swap    swap    defaults    0    0" >> /etc/fstab'
sudo swapon -a

sudo mkdir /var/sockets
sudo chmod 777 /var/sockets
```


### Declare APP_NAME

```
APP_NAME=app_name
APP_DOMAIN=app.com
APP_PROXY=http://app_name.com
```

### Put nginx config

```
sudo bash -c 'cat > /etc/nginx/nginx.conf' << EOF
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log;
pid /run/nginx.pid;

include /usr/share/nginx/modules/*.conf;

events {
  worker_connections 1024;
}

http {
  log_format  main  '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';

  access_log  /var/log/nginx/access.log  main;

  sendfile            on;
  tcp_nopush          on;
  tcp_nodelay         on;
  keepalive_timeout   65;
  types_hash_max_size 2048;

  include             /etc/nginx/mime.types;
  default_type        application/octet-stream;

  include /etc/nginx/conf.d/*.conf;

  server_tokens off;

  upstream ${APP_DOMAIN} {
    server unix:/var/sockets/unicorn.sock;
  }

  proxy_redirect   off;
  proxy_set_header Host               \$host;
  proxy_set_header X-Real-IP          \$remote_addr;
  proxy_set_header X-Forwarded-Host   \$host;
  proxy_set_header X-Forwarded-Server \$host;
  proxy_set_header X-Forwarded-For    \$proxy_add_x_forwarded_for;

  server {
    listen       80 default_server;
    listen       [::]:80 default_server;
    server_name  _;
    root         /home/ec2-user/${APP_NAME}/current/public;
    client_max_body_size 20M;
    fastcgi_read_timeout 120;
    try_files \$uri/index.html \$uri.html \$uri @app;

    # Load configuration files for the default server block.
    include /etc/nginx/default.d/*.conf;

    location ~ ^/uploads/ {
      gzip_static on;
      expires 1y;
      add_header Cache-Control public;
      add_header ETag "";
      break;
    }

    location ~ ^/assets/ {
      gzip_static on; # to serve pre-gzipped version
      expires 1y;
      gzip on;
      gzip_vary on;
      gzip_proxied any;
      gzip_disable "MSIE [1-6]\.";
      gzip_comp_level 6;
      gzip_types application/x-javascript text/css image/x-icon image/png image/jpeg image/gif;
      add_header Cache-Control public;
      add_header ETag "";
      break;
    }

    location / {
      proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
      proxy_set_header Host \$http_host;
      proxy_redirect off;
      try_files \$uri/index.html \$uri.html \$uri @app;
    }

    location @app {
      set \$redirect "";
      if (\$http_x_forwarded_proto != 'https') {
        set \$redirect "1";
      }
      if (\$http_user_agent !~* ELB-HealthChecker) {
        set \$redirect "\${redirect}1";
      }
      if (\$http_host ~ "${APP_DOMAIN}") {
        set \$redirect "\${redirect}1";
      }
      if (\$redirect = "111") {
        rewrite ^ https://\$host\$request_uri? permanent;
      }
      proxy_pass ${APP_PROXY};
    }

    error_page 404 /404.html;
    location = /40x.html {
    }

    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
    }
  }
}
EOF
```

### Start nginx

```
sudo service nginx start
chmod 755 ~
```