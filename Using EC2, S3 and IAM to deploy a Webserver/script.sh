echo "Updating system"
dnf update -y

echo "Installing Nginx..."
dnf install nginx -y

echo "Starting Nginx and enable at boot"
systemctl start nginx
systemctl enable nginx

S3_ASSET_BUCKET="ec2-userdata-ish/nginx"
NGINX_WEB_ROOT="/usr/share/nginx/html"

echo "Syncing website files from s3://${S3_ASSET_BUCKET} to ${NGINX_WEB_ROOT}..."
rm /usr/share/nginx/html/index.html
aws s3 sync s3://${S3_ASSET_BUCKET}/ ${NGINX_WEB_ROOT}/ --delete

echo "Deployment complete!"