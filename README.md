# Suffixes
| Suffix            | Description                                                                       |
| ------------------|-----------------------------------------------------------------------------------|
| .rsa              | rsa key                                                                           |
| .ec               | ec/prime256v1 key                                                                 |
| .key              | private key                                                                       |
| .crt              | single PEM-formatted certificate (signed by $CA)                                  |
| .cer              | single DER-formatted certificate                                                  |
| .cnf              | OpenSSL configuration                                                             |
| .csr              | Certificate Signing Request                                                       |
| .subreq           | Auxiliary CSR, when generating certificate                                        |
| .config           | Certificate configuration                                                         |
| .chain.pem        | intermediate(s) + root certificate (PEM-formatted)                                |
| .bundle.pem       | server/leaf + intermediate(s) + root + server-key (PEM-formatted)                 |
| .fullchain.pem    | server/leaf + intermediate(s) + root certificate (PEM-formatted)                  |
| .p12              | PKCS 12 archive with entire certificate chain including server public/private key |
| .pfx              | same as .p12                                                                      |
| .pkcs12           | same as .p12                                                                      |
| .jks              | Java KeyStore including entire certificate chain and server public/private key    |
| .key.pub          | Public key from Private key                                                       |
| .csr.pub          | Public key from Certificate Signing Request                                       |
| .crt.pub          | Public key from Certificate                                                       |
| .key.modulus      | Key Modulus                                                                       |
| .csr.modulus      | CSR Modulus                                                                       |
| .crt.modulus      | Certificate Modulus                                                               |
| .txt              | To decrypt an .enc-file using private key (.key)                                  |
| .enc              | To encrypt an .txt-file using public key (.key.pub)                               |

# Functions
| Suffix            | Description                                                                       |
| ------------------|-----------------------------------------------------------------------------------|
| .csr-info         | Output CSR in text-form                                                           |
| .crt-info         | Output CRT in text-form                                                           |
| .key-sha1         | SHA1 checksum from key modulus                                                    |
| .csr-sha1         | SHA1 checksum from CSR modulus                                                    |
| .crt-sha1         | SHA1 checksum from crt modulus                                                    |
| .crt-fingerprint  | Output the fingerprint of certificate                                             |

# Variables
| Variable          | Description                                                                       |
| ------------------|-----------------------------------------------------------------------------------|
| CA                | Default Root Signing Authority (defaults to "ca")                                 |
| KEY               | Type of keys to generate, either "rsa" or "ec" (defaults to "rsa")                |
| DAYS              | For how many days certificates will be valid (defaults to 1 year)                 |
| NUMBITS           | Bitsize of RSA-keys (defaults to 2048)                                            |
| PASSWORD          | Default export password, eg. for p12 and jks (defaults to "changeit")             |

# Examples

## Generate the Root CA
```
make
```
> profile = ca
> CN = Root CA

## Generate an Intermediate CA
```
make DAYS=1825 NUMBITS=4096 intermediate.crt
```
> profile = intermediate
> CN = Intermediate CA

## Generate a Server certificate signed by the Root CA
```
make servername.example.com.crt
```
> profile = server
> CN = servername.example.com
> DNS.1 = servername.example.com

## Generate a Server certificate signed by the Intermediate CA
```
make CA=intermediate servername2.example.com.crt
```
> profile = server
> CN = servername2.example.com
> DNS.1 = servername2.example.com

## Sign a CSR from a third-party
```
cp /absolute/path/to/xxx.csr 3rdparty.example.com.csr
make 3rdparty.example.com.crt
```
> profile = server
> CN = 3rdparty.example.com
> DNS.1 = 3rdparty.example.com
