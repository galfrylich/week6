With In this ansible playbook you can run the Weight Tracker app on the azure resources that are built in this Terraform module- https://github.com/galfrylich/week6.

1. Connect to the ansible VM you have in your environment. (The user name and password are the same as the one you used to create the VM, you can find them in the .tfvars files and your Terraform output.)
2. Install ansible
3. Run the command "export ANSIBLE_HOST_KEY_CHECKING=False" to enable connection to the hosts machines with user name and password.
4. Add the file inventory. The file should contain this data: {vm ip} add as much as vm you have
5. You should add this file to your .gitigonre because it contains secret data.
6. Add file caled pm2start.sh with the commands:
* cd /home/bootcamp-app/
* pm2 start src/index.js -i max
* pm2 startup
* sudo env PATH=$PATH:/usr/bin /usr/lib/node_modules/pm2/bin/pm2 startup systemd -u webuser --hp /home/webuser
* pm2 save

7. Add the load balancer public ip to your okta app sign-in redirect URIs.
8. Run the command ansible-playbook -i inventory weightTrackerPlayBook.yaml.
    
    

