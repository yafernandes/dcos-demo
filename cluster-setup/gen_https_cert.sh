openssl req -newkey rsa:2048 -new -nodes -x509 -days 3650 -keyout https.key -out https.csr \
    -subj "/C=CA/ST=ON/L=Toronto/O=Mesosphere/OU=Sales Engineering/CN=dcos"
cat https.csr https.key > https.cert