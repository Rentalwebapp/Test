# Azure VM + Pipeline Setup

This guide provides a straightforward path to deploy the Valentine page on an Azure VM using an Azure DevOps pipeline.

## 1) Create the Azure VM

> Replace placeholders with your values.

```bash
az login
az group create --name valentines-rg --location eastus
az vm create \
  --resource-group valentines-rg \
  --name valentines-vm \
  --image Ubuntu2204 \
  --size Standard_B2s \
  --admin-username azureuser \
  --generate-ssh-keys

# Open ports 22 (SSH) and 80 (HTTP)
az vm open-port --resource-group valentines-rg --name valentines-vm --port 22
az vm open-port --resource-group valentines-rg --name valentines-vm --port 80
```

Grab the public IP for the VM:

```bash
az vm show -d --resource-group valentines-rg --name valentines-vm --query publicIps -o tsv
```

## 2) Configure the VM for the Django app

SSH into the VM:

```bash
ssh azureuser@<VM_PUBLIC_IP>
```

Install prerequisites and create a systemd service:

```bash
sudo apt-get update
sudo apt-get install -y python3-venv python3-pip nginx unzip

sudo mkdir -p /var/www/valentine-app
sudo chown -R azureuser:azureuser /var/www/valentine-app
```

Create `/etc/systemd/system/valentine.service`:

```ini
[Unit]
Description=Valentine Django App
After=network.target

[Service]
User=azureuser
WorkingDirectory=/var/www/valentine-app
ExecStart=/var/www/valentine-app/venv/bin/gunicorn SearchingYourHome.wsgi:application --bind 0.0.0.0:8000
Restart=always

[Install]
WantedBy=multi-user.target
```

Enable the service:

```bash
sudo systemctl daemon-reload
sudo systemctl enable valentine.service
```

Configure Nginx (`/etc/nginx/sites-available/valentine`):

```nginx
server {
    listen 80;
    server_name _;

    location /static/ {
        alias /var/www/valentine-app/staticfiles/;
    }

    location / {
        proxy_pass http://127.0.0.1:8000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

Enable the site:

```bash
sudo ln -s /etc/nginx/sites-available/valentine /etc/nginx/sites-enabled/valentine
sudo nginx -t
sudo systemctl restart nginx
```

## 3) Azure DevOps Pipeline

1. Create a Service Connection in Azure DevOps:
   - **Project Settings → Service connections → New**.
   - Pick **SSH**.
   - Enter the VM public IP, username (`azureuser`), and your private key.
   - Name it `azure-vm-ssh`.

2. Update pipeline variables in `azure-pipelines.yml`:
   - `vmHost` and `vmUser` (if different).
   - `appPath` if you deploy elsewhere.

3. Run the pipeline.

Once it completes, browse to:

```
http://<VM_PUBLIC_IP>/valentine
```

## 4) Valentine Page Route

The page is available at `/valentine` in the Django app.
