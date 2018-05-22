# SSL Certificates

**Do not commit any private keys to your repo.**

This file documents notes about our SSL configuration.

### Let's Encrypt

Run:
```
certbot certonly --webroot -w /home/cloud/snapCloud/html/ -d snap-cloud.cs10.org
```

TODO: handle linking auto-renewed certs.