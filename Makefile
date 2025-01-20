.SUFFIXES:
.PHONY: clean
.PRECIOUS: %.key %.csr %.crt %.passwd %.config
.INTERMEDIATE: .hashes %.subreq

CA		?= ca
KEY		?= rsa
DAYS		?= 365
NUMBITS		?= 2048
PASSWORD	?= changeit

$(CA).crt : DAYS = 7300
$(CA).crt : NUMBITS = 4096
$(CA).crt : %.crt : %.key | %.config
	openssl req -new -x509 \
		-config $*.config \
		-days $(DAYS) \
		-key $< \
		-out $*.crt

%.config : default.template
	cp --verbose --no-clobber $< $@
	$(EDITOR) $@

%.rsa :
	openssl genrsa -out $@ $(NUMBITS)

%.ec :
	openssl ecparam -genkey -name prime256v1 -out $@

%.key : %.$(KEY)
	cp --verbose --interactive $< $@

%.key.pub : %.key
	openssl rsa -pubout -in $< -out $@

%.config : default.template
	-cp --verbose --no-clobber $< $@
	$(EDITOR) $@

%.csr : %.key | %.config
	openssl req -config $*.config \
		-new \
		-key $< \
		-out $@

%.subreq : | %.rsa %.config
	openssl req -config $*.config \
		-section subreq \
		-new \
		-key $*.rsa \
		-out $@

%.enc : %.key.pub
	openssl pkeyutl -encrypt -pubin \
		-inkey $< \
		-in $*.txt \
		-out $@

%.txt : %.key
	openssl pkeyutl -decrypt \
		-inkey $< \
		-in $*.enc \
		-out $@

%.csr.pub : %.csr
	openssl req -pubkey -noout -in $< -out $@

%.crt : %.csr.pub %.subreq | %.config $(CA).crt
	openssl x509 -req \
		-in $*.subreq \
		-out $@ \
		-CA $(CA).crt \
		-CAkey $(CA).key \
		-force_pubkey $< \
		-days $(DAYS) \
		-clrext \
		-extfile $*.config

%.crt.pub : %.crt
	openssl x509 -pubkey -noout -in $< -out $@

%.cer : %.crt
	openssl x509 -in $< -outform DER -out $@

%.chain.pem : %.p12
	openssl pkcs12 -noenc -nokeys -cacerts \
		-passin pass:$(PASSWORD) \
		-in $< \
		-out $@

%.fullchain.pem : %.p12
	openssl pkcs12 -noenc -nokeys \
		-passin pass:$(PASSWORD) \
		-in $< \
		-out $@

%.bundle.pem : %.p12
	openssl pkcs12 -noenc \
		-passin pass:$(PASSWORD) \
		-in $< \
		-out $@

%.key.modulus : %.key
	openssl rsa -modulus -noout -in $< -out $@

%.crt.modulus : %.crt
	openssl x509 -modulus -noout -in $< -out $@

%.csr.modulus : %.csr
	openssl req -modulus -noout -in $< -out $@

.hashes :
	@mkdir --verbose --parents .hashes
	@find . -type f -iname "*.crt" -exec \
		ln --symbolic --relative --suffix=.crt --backup=simple --target-directory=.hashes {} \;
	openssl rehash .hashes

%.p12 : %.crt %.key | .hashes
	openssl pkcs12 -export -maciter -chain \
		-CApath .hashes \
		-name $(notdir $(subst STAR,*,$*)) \
		-in $*.crt \
		-inkey $*.key \
		-passout pass:$(PASSWORD) \
		-out $@
	rm --recursive --force .hashes

%.pfx : %.p12
	cp --verbose --force $< $@

%.pkcs12 : %.p12
	cp --verbose --force $< $@

%.jks : %.p12
	keytool -importkeystore \
		-srckeystore $< \
		-srcstoretype pkcs12 \
		-srcstorepass $(PASSWORD) \
		-destkeystore $@ \
		-deststoretype jks \
		-deststorepass $(PASSWORD)

%.csr-info : %.csr
	@openssl req -in $< -noout -text

%.crt-info : %.crt
	@openssl x509 -in $< -noout -text

%.key-sha1 : %.key
	@openssl rsa -in $< -noout -modulus | openssl sha1

%.csr-sha1 : %.csr
	@openssl req -in $< -noout -modulus | openssl sha1

%.crt-sha1 : %.crt
	@openssl x509 -in $< -noout -modulus | openssl sha1

%.crt-fingerprint : %.crt
	@openssl x509 -in $< -outform DER | openssl sha1 | awk '{print $$2}'

%/ :
	mkdir --parents --verbose $(@D)

clean :
	rm --verbose --force *.key *.csr *.crt *.passwd *.pem *.p12 *.serial *.config *.index *.index.old *.index.attr *.index.attr.old *.pub *.modulus
	rm --verbose --force --recursive certs
