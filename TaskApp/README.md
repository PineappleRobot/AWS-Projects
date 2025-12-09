**Project: Automated Web App Deployment to EC2 via S3**

**Using EC2 to deploy a web server where we will use S3 to house our deployment script (Install nginx) and index.html. Making use of IAM Roles to allow our EC2 instance to access our S3 bucket to that it can download both our deployment script and our webapp, we will also use EIP (Elastic IP to have a static IP and finally bind that to a URL from DuckDNS

**Skills and Concepts Demonstrated**

- **Identity and Access Management (IAM):** Securely granting permissions to compute resources using IAM Roles.
- **S3 Access Control:** Implementing the principle of least privilege by restricting S3 access only to the necessary EC2 Role.
- **Automated Provisioning (Automation/Scripting):** Using EC2 User Data to automatically install dependencies, download deployment files, and execute setup scripts at launch.
- **Operational Resilience:** Implementing line-ending fixes (dos2unix) and robust error handling to ensure script execution reliability.
- **Security Group Configuration:** Implementing network security rules to allow only necessary traffic (HTTP/Port 80) to the application server.
- **Network Permanence (Elastic IP):** Allocating and associating a public, static IPv4 address (EIP) to ensure the application's address does not change upon reboot or stop/start.
- **Domain Name Resolution (DuckDNS):** Integrating Dynamic DNS services to map a fixed domain name to the EIP.

**Architecture Overview (The Plan)**

- **S3 Bucket:** This acts as my central repository, holding both the simple web application files (index.html) and the executable deployment script (script.sh).
- **IAM Role:** This is the secure way to grant my EC2 instance _read-only_ permission to the S3 bucket without using hardcoded credentials.
- **EC2 Instance:** The instance boots up, executes the User Data script and automatically pulls the web app and configuration from S3, installing Nginx in the process.
- **EC2 Elastic IP:** Create and assign an EIP to the instance so that the instance has a static(fixed) IP address.
- **Create a custom URL (DuckDNS):** Make the WebApp easier to access by having DuckDNS point a custom subdomain to the EIP of the EC2 instance.

The JSON and Script code for the IAM role, S3 bucket, user data (EC2) are included at the bottom of the document.

**Section 1: IAM Role and S3 Setup**

**1\. Creating the IAM Role for EC2**

First, I need to create a role that my EC2 instance can assume at launch. This is how I securely grant access to my S3 bucket.

- Service: I select the EC2 service because this is the entity that will use the role.
- Policy: I'm using the AWS managed policy AmazonS3ReadOnlyAccess for simplicity, as it gives read access to all my S3 buckets. For a real production environment, I would create a custom policy restricted only to the bucket's ARN.

**Steps:**

- Navigate to the IAM Console and select Roles.
- Click Create role and choose AWS service 🡪 EC2 as the trusted entity.
- On the Permissions page, I search for and attach the AmazonS3ReadOnlyAccess policy and click next
- Add a name and description for your new role, I've gone with EC2-ReadScript-S3 for the name and Allows EC2 instances to read objects stored in a S3 bucket for my description
- You can add Tags to the role to help with organisation.


**2\. Creating the S3 Bucket and Adding the Policy**

This bucket is where I'll upload my index.html and the deployment script (script.sh). I've named mine "ec2-userdata-ish" as an example.

**Crucial Step: The Bucket Policy:** The IAM role allows the EC2 instance to _attempt_ the read, but the bucket itself needs to explicitly allow that specific IAM entity access.

**Steps:**

- Navigate to the S3 Console and create a bucket I've named mine ec2-userdata-ish.
- Once its created we need to head over to the Permissions tab so that the request from the EC2 instance isn't automatically declined.
- Click Edit in the Bucket policy section, enter the JSON code to allow the IAM role to "GetObject" from the bucket.
- Save the policy. Now the access handshake is complete.
- I've created a folder called nginx to hold my HTML file.  

**Section 2: EC2 Security and Launch Configuration**

**3\. Creating the Security Group**

My application runs on port 80, so I'm going to create a new security group for the web app instead of editing the default group, I will also add port 443 for HTTPS so that in the future if I want to use Certbot to switch from HTTP to HTTPS for added security.

- Name: I'll call it TaskApp.
- Inbound Rules:
  - SSH (Port 22): I set this to my own IP address.
  - HTTP (Port 80): I set the source to 0.0.0.0/0 (everyone) so the web app is accessible.
  - HTTPS (Port 443): Same as port 80, I set the source to 0.0.0.0/0.


**4\. Launching the EC2 Instance and Configuring User data**

This is the deployment section. Configure the instance, tying all the elements together, and providing the necessary user data to get deployment ready to use.

**Steps:**

- Navigate to the EC2 Console and hit Launch instances.
- Select the Amazon Linux AMI.
- Create a Key Pair, name it and select the file type you want, I use Putty so I will select the. ppk option.
- Under Network Settings, make sure to select the security group made earlier (TaskApp)
- Scroll all the way to the bottom of the page and expand the "Advanced Details" section:
  - Under "IAM instance profile" setting, select the IAM role we made earlier (EC2-ReadScript-S3)
  - Scroll right down to the User data box. This is where I add my deployment code to install dox2unix, download a custom script(script.sh) from my S3 bucket, use dos2unix to convert the line breaks from a DOS format to a UNIX format, change the permission to allow execution of my script and to finally execute the script.



### 5\. Assigning an Elastic IP (EIP) for a Fixed Address

Since EC2 instances lose their Public IPv4 address when stopped, I assign an Elastic IP (EIP) to this instance to ensure the application has a permanent, fixed public address. This is critical for any production, or in my case for my DuckDNS subdomain (so I don't need to keep updating the IP association in DuckDNS).

**Steps:**

- In the **EC2 Console**, navigate to **Elastic IPs** section on the left sidebar.
- Click **Allocate Elastic IP address** and select your border group (I've left mine as the default).
- Add any Tags to help with organisation.
- Select the EIP and add a name (TaskApp in my case)
- **With it still selected, click on Actions, Associate Elastic IP address.**
- Select the **Instance** option(default), then the EC2 instance ID that hosts the WebApp**.**
- Click **Associate.**

### 6\. Using DuckDNS subdomain to point to the EC2 WebApp

With the EC2 instance now having an EIP, the final step is to map the IP to a user-friendly URL using DuckDNS

**Steps:**

- Sign up for DuckDNS
- Create a new subdomain
- Under the "current ip" section next to the subdomain name, enter the EIP  

**7\. Verification**

After the instance starts running, wait 3-5 minutes for the instance to finish initializing, then connect to the WebApp

**Steps:**

- Navigate to your DuckDNS subdomain.
- Once we see the index.html content served by Nginx, confirming the end-to-end automation worked.
- If I need to troubleshoot, I SSH into the instance and check the execution log: /var/log/cloud-init-output.log


| Purpose | Code |
| --- | --- |
| S3 Bucket Policy to allow only the IAM role read access | {<br><br>"Version": "2012-10-17",<br><br>"Statement": \[<br><br>{<br><br>"Sid": "EC2 Read From Bucket",<br><br>"Effect": "Allow",<br><br>"Principal": {<br><br>"AWS": "arn:aws:iam::024260995258:role/EC2-ReadScript-S3"<br><br>},<br><br>"Action": "s3:GetObject",<br><br>"Resource": "arn:aws:s3:::ec2-userdata-ish/\*"<br><br>}<br><br>\]<br><br>} |
| IAM Role being granted S3 Read Only permissions | {<br><br>"Version": "2012-10-17",<br><br>"Statement": \[<br><br>{<br><br>"Effect": "Allow",<br><br>"Action": \[<br><br>"s3:Get\*",<br><br>"s3:List\*",<br><br>"s3:Describe\*",<br><br>"s3-object-lambda:Get\*",<br><br>"s3-object-lambda:List\*"<br><br>\],<br><br>"Resource": "\*"<br><br>}<br><br>\]<br><br>} |
| Script.sh to install nginx and copy the html file(s) to the nginx directory | echo "Installing Nginx..."<br><br>dnf install nginx -y<br><br>echo "Starting Nginx and enable at boot"<br><br>systemctl start nginx<br><br>systemctl enable nginx<br><br>S3_ASSET_BUCKET="ec2-userdata-ish/nginx"<br><br>NGINX_WEB_ROOT="/usr/share/nginx/html"<br><br>echo "Syncing website files from s3://\${S3_ASSET_BUCKET} to \${NGINX_WEB_ROOT}..."<br><br>rm /usr/share/nginx/html/index.html<br><br>aws s3 sync s3://\${S3_ASSET_BUCKET}/ \${NGINX_WEB_ROOT}/ --delete<br><br>echo "Deployment complete!" |
| User data boot script to update the system, install dos2unix, download our script from our S3 bucket, convert it, adjust the permissions and to finally execute it | #! /bin/bash<br><br>mkdir /deploy<br><br>cd /deploy<br><br>S3_CONFIG_BUCKET="ec2-userdata-ish"<br><br>SCRIPT_FILENAME="script.sh"<br><br>LOCAL_PATH="/deploy/\${SCRIPT_FILENAME}"<br><br>echo "Updating system and installing dox2unix"<br><br>dnf update -y<br><br>dnf install dos2unix -y<br><br>echo "Downloading deployment script from s3://\${S3_CONFIG_BUCKET}/\${SCRIPT_FILENAME}..."<br><br>aws s3 cp s3://\${S3_CONFIG_BUCKET}/\${SCRIPT_FILENAME} \${LOCAL_PATH}<br><br>if \[ \$? -ne 0 \]; then<br><br>echo "ERROR: Failed to download deployment script from S3. Check IAM permissions and bucket name."<br><br>exit 1<br><br>fi<br><br>echo "Convert script"<br><br>dos2unix \${SCRIPT_FILENAME}<br><br>echo "Making deployment script executable..."<br><br>chmod +x \${SCRIPT_FILENAME}<br><br>echo "Executing deployment script..."<br><br>./\${SCRIPT_FILENAME}<br><br>echo "EC2 Bootstrap process complete." |