## Strapi manual installation
```
$ sudo apt update
$ curl -sL https://deb.nodesource.com/setup_18.x | sudo -E bash -
$ sudo apt install nodejs -y
```
![node -v](https://github.com/nikhilk1699/strapi_installation/assets/109533285/ca8150bd-2825-4506-bd42-d8f26cdf4710)
### copy the public ip into browser
![Uploading image.png…]()


```
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql.service
```
![postgre](https://github.com/nikhilk1699/strapi_installation/assets/109533285/a4dc0b0e-3644-42a9-9553-7ae049c942ac)

```
sudo apt update
sudo apt install nginx -y
```
![nginx](https://github.com/nikhilk1699/strapi_installation/assets/109533285/76b28bb8-870e-4532-a756-42293eef34c0)

```
$ sudo nano /etc/nginx/sites-available/3.87.153.154
```
```
server {
    listen 80;
    listen [::]:80;

    server_name 3.87.153.154  www.3.87.153.154;
        
    location / {
        proxy_pass http://localhost:1337;
        include proxy_params;
    }
}
```
```
$ sudo ln -s /etc/nginx/sites-available/3.87.153.154 /etc/nginx/sites-enabled/
$ sudo nginx -t
sudo systemctl restart nginx
```
![image](https://github.com/nikhilk1699/strapi_installation/assets/109533285/3a8c925f-384f-47a5-ab34-8432b6f3b58c)
![nginxconfin2](https://github.com/nikhilk1699/strapi_installation/assets/109533285/a1deed0d-6d21-47e0-9d81-c32c9e5fc138)

```
sudo -i -u postgres createdb strapi-db -y
sudo -i -u postgres createuser --interactive
```
![postgredb](https://github.com/nikhilk1699/strapi_installation/assets/109533285/1f439bdf-0047-4907-8b97-f5c0db1f7f44)

```
sudo -u postgres psql
postgre=# ALTER USER nikhil PASSWORD '*';
postgre=# \q
```
![adddb](https://github.com/nikhilk1699/strapi_installation/assets/109533285/0b241a70-f1e1-474f-b5bb-f8c43cf17547)

```
$ npx create-strapi-app@latest strapi-pro
```
![image](https://github.com/nikhilk1699/strapi_installation/assets/109533285/09cac9c2-0740-4fca-99d0-21913eac3fb6)
![image](https://github.com/nikhilk1699/strapi_installation/assets/109533285/77861f44-4346-4993-b79c-fd827940ef4c)

```
$ cd my-project
$ NODE_ENV=production npm run build
```
![image](https://github.com/nikhilk1699/strapi_installation/assets/109533285/e16eb32d-1c6b-4590-ad56-60d56573c2b9)

```
$ node /home/ubuntu/strapi-pro/node_modules/.bin/strapi start
```
![image](https://github.com/nikhilk1699/strapi_installation/assets/109533285/817bc9f3-7e6d-4d72-9689-12d31e6455f0)


 




