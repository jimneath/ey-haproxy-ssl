# HAproxy SSL Termination

Updates the `/etc/haproxy.cfg` file to terminate SSL at the load balancer level. **!!! Test on a staging environment first !!!**

## Setup

- Add the contents of your certificate in to the `files/default/app.crt` file
- Add the contents of your private key in to the `files/default/app.key` file

## Warning

This has not been tested in a production environment and is not officially supported by Engine Yard. Use at your own peril.