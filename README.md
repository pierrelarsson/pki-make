SUFFIXES
========
.crt            Single PEM-formatted certificate
.cer            Single DER-formatted certificate
.cnf            OpenSSL configuration
.csr            Certificate Signing Request
.ca.pem         PEM-formatted intermediate and root/CA certificates
.chain.pem      PEM-formatted certificate chain (server, intermediate and root certificate)
.bundle.pem     PEM-formatted certificate chain (server, intermediate and root certificate) -and server private key
.pubkey         Public portion of Private key
.key            PEM-formatted Private key
.p12            PKCS 12 archive with entire certificate chain including server public/private key
.pfx            -See above-
.pkcs12         -See above-
.jks            Java KeyStore including entire certificate chain and server public/private key

Methods
=======
.crt+info       Print information regarding certificate
.csr+info       Print information regarding a signing request
.p12+into       Print information PKCS12 archive

Environment Overrides
=====================
CA              Certificate Authority used to sign CSR's
DAYS            Validity days, defaults to 3 years except for CA, which defaults to 20 years
NUMBITS         Size of RSA private key
