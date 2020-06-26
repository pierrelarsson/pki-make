include Makefile.config

.SUFFIXES:
.PRECIOUS: %.key %.csr %.crt %.passwd %.cnf
.INTERMEDIATE: %.cnf- .hashes

crtfp = `openssl x509 -in $@ -outform DER | openssl sha1 | awk '{print $$2}'`
csrfp = `openssl req -in $@ -outform DER | openssl sha1 | awk '{print $$2}'`
keyid = `openssl pkey -in $@ -pubout -outform DER | openssl sha1 | awk '{print $$2}'`
crtid = `openssl x509 -noout -in $@ -pubkey | openssl enc -base64 -d | openssl sha1 | awk '{print $$2}'`
csrid = `openssl req -noout -in $@ -pubkey | openssl enc -base64 -d | openssl sha1 | awk '{print $$2}'`

CN = $(notdir $(subst STAR,*,$*))
DAYS = 1095

ifeq "$(CHF)" "SHA1"
dgst := -sha1
NUMBITS := 1024
else ifeq "$(CHF)" "SHA256"
dgst := -sha256
NUMBITS := 2048
else ifeq "$(CHF)" "ECC256"
dgst := -sha256
NUMBITS := 2048
else
$(error Unsupported Cryptographic Hash Function '$(CHF)')
endif

$(CA).crt : DAYS = 7300
$(CA).crt : %.crt : %.csr %.cnf
	@test ! -f $@ || install --verbose \
		--preserve-timestamps \
		--mode=0664 \
		-D $@ $*/$(crtid)/$(crtfp).crt
	openssl x509 -req -extfile $*.cnf \
		-in $< \
		-out $@ \
		-days $(DAYS) \
		-signkey $*.key
	rm --verbose --force $*.serial

%.cnf : %.cnf-
	@test -f $@ \
		&& vimdiff -- $@ $< \
		|| vim --not-a-term - < $< +"file $@|set filetype=dosini"
	test -f $@

%.csr : %.key | %.cnf
	@test ! -f $@ || install --verbose \
		--preserve-timestamps \
		--mode=0664 \
		-D $@ $*/$(csrid)/$(csrfp).csr
	openssl req -verbose -utf8 -batch -new $(dgst) \
		-config $*.cnf \
		-key $< \
		-out $@

%.crt : %.csr %.cnf | $(CA).crt
	@test ! -f $@ || install --verbose \
		--preserve-timestamps \
		--mode=0664 \
		-D $@ $*/$(crtid)/$(crtfp).crt
	openssl x509 -req -extfile $*.cnf \
		-in $< \
		-out $@ \
		-days $(DAYS) \
		-CA $(CA).crt \
		-CAkey $(CA).key \
		-CAserial $(CA).serial \
		-CAcreateserial

%.cer : %.crt
	openssl x509 -in $< -outform DER -out $@

%.ca.pem : %.p12
	openssl pkcs12 -nodes -nokeys -cacerts \
		-passin pass:$(PASSWORD) \
		-in $< \
		-out $@

%.chain.pem : %.p12
	openssl pkcs12 -nodes -nokeys -chain \
		-passin pass:$(PASSWORD) \
		-in $< \
		-out $@

%.bundle.pem : %.p12
	openssl pkcs12 -nodes \
		-passin pass:$(PASSWORD) \
		-in $< \
		-out $@

%.pubkey : %.key
	openssl rsa \
		-in $<.key \
		-pubout \
		-out $@

.hashes :
	@mkdir --verbose --parents .hashes
	@find . -type f -iname "*.crt" -exec \
		ln --symbolic --relative --suffix=.crt --backup=simple --target-directory=.hashes {} \;
	openssl rehash .hashes

%.key :
	@mkdir --verbose --parents $(@D)
	@test ! -f $@ || install --verbose \
		--preserve-timestamps \
		--mode=0600 \
		-D $@ $*/$(keyid)/key
ifeq "$(CHF)" "SHA1"
	openssl genrsa -out $@ $(NUMBITS)
else ifeq "$(CHF)" "SHA256"
	openssl genrsa -out $@ $(NUMBITS)
else ifeq "$(CHF)" "ECC256"
	openssl ecparam -genkey -name prime256v1 -out $@
endif

%.cnf- :
	@mkdir --verbose --parents $(@D)
	@echo '[ certificate ]' >> $@
	@echo '#extensions                  = ca|intermediate|server|client|personal' >> $@
	@test "$(@D)" = "." \
		&& echo 'extensions                  = server' >> $@ \
		|| echo 'extensions                  = $(firstword $(subst /, ,$(@D)))' >> $@
	@echo >> $@
	@echo '[ request_subject ]' >> $@
	@test -z "$(COUNTRY)" \
		&& echo '#countryName                 = Country Name (2 letter code)' >> $@ \
		|| echo 'countryName                 = $(COUNTRY)' >> $@
	@test -z "$(STATE)" \
		&& echo '#stateOrProvinceName         = State or Province Name (full name)' >> $@ \
		|| echo 'stateOrProvinceName         = $(STATE)' >> $@
	@test -z "$(LOCALITY)" \
		&& echo '#localityName                = Locality Name (eg, city)' >> $@ \
		|| echo 'localityName                = $(LOCALITY)' >> $@
	@test -z "$(ORGANIZATION)" \
		&& echo '#organizationName            = Organization Name (eg, company)' >> $@ \
		|| echo 'organizationName            = $(ORGANIZATION)' >> $@
	@test -z "$(ORGANIZATIONALUNIT)" \
		&& echo '#organizationalUnitName      = Organizational Unit Name (eg, section)' >> $@ \
		|| echo 'organizationalUnitName      = $(ORGANIZATIONALUNIT)' >> $@
	@echo 'commonName                  = $(CN)' >> $@
	@test -z "$(EMAIL)" \
		&& echo '#emailAddress                = $(USER)@$(call CN, $*)' >> $@ \
		|| echo 'emailAddress                = $(EMAIL)' >> $@
	@echo >> $@
	@echo '[ alternative_names ]' >> $@
	@echo 'DNS.1                       = $(CN)' >> $@
	@echo '#IP.1                        = 127.0.0.1' >> $@
	@echo '#email.1                     = $(USER)@$(CN)' >> $@
	@echo >> $@
	@echo '.include openssl.cnf' >> $@
	@chmod 0444 $@

%.p12 : %.crt %.key | .hashes
	openssl pkcs12 -export -maciter -chain -nodes \
		-CApath .hashes \
		-name $(CN) \
		-in $*.crt \
		-inkey $*.key \
		-passout pass:$(PASSWORD) \
		-out $@
	rm --recursive --force .hashes

%.pfx : %.p12
	cp --verbose $< $@

%.pkcs12 : %.p12
	cp --verbose $< $@

%.jks : %.p12
	keytool -importkeystore \
		-srckeystore $< \
		-srcstoretype pkcs12 \
		-srcstorepass $(PASSWORD) \
		-destkeystore $@ \
		-deststoretype jks \
		-deststorepass $(PASSWORD)

%.crt+info :
	openssl x509 -in $*.crt -noout -text -modulus -fingerprint -serial

%.csr+info :
	openssl req -in $*.csr -noout -text -modulus

%.p12+info :
	openssl pkcs12 -in $*.p12 -info -nodes -passin pass:$(PASSWORD)
