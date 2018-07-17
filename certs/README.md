# SSL Certificates

**Do not commit any private keys to your repo.**

This file documents notes about our SSL configuration.

## Let's Encrypt

Start your Lapis server on the domain where you will need the cert. For Let'sEncrrypt to work, the server needs to be publicly accessible at the domain your are requesting at cert. (You will probably want disable SSL beforehand, or else nginx will likely complain about invalid certs.)
Run:

```
certbot certonly --webroot -w /home/cloud/snapCloud/html/ -d snap-cloud.cs10.org
```

After this, certbot will give you the name of the certs it generated. Copy them to the `certs/` folder and update the file paths as necessary.

## UC Berkeley Certs
First, generate a CSR and key using `openssl`. Use the EECS website to request a new cert. (You need an EECS account to do this; at least on Snap<em>!</em> team member should be able to do this.)

When generating a cert from UC Berkeley, there are many possible cert types.
We need to concatenate the proper files for nginx to be able to read them.
You need to include the individual cert along with the intermediate certs in a single file.

```
cp cloud_snap_berkeley_edu_cert.cer cloud.snap.berkeley.edu.combined.cer
echo '' >> cloud.snap.berkeley.edu.combined.cer
cat cloud_snap_berkeley_edu_interm-reversed.cer >> cloud.snap.berkeley.edu.combined.cer
```

Use the combined file as the `ssl_certificate` in the nginx configuration.

## Diffie-Hellman Perfect Forward Secrecy
Perfect Forward Secrecy is an extension to SSL/TLS that aids in protecting connections in the event of a private key being comprised.
To do enable this, you need generate an additional key on each server. Generating this takes a few minutes, but it easy. Save this to the `certs/` directory, too.

```sh
openssl dhparam -out dhparam.cert 4096
```
