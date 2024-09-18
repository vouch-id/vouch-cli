SIGNING_PUBKEY=../vouch-website/content/download/vouch.pub

all:

tag:
	git -c gpg.format=ssh -c user.signingKey="`cat $(SIGNING_PUBKEY)`" tag -m $(TAG) -s $(TAG)
	git push --tag

.INTERMEDIATE: vouch.sig

%.keys:
	curl -s -O https://github.com/$@

release: tag vouch $(SIGNING_PUBKEY)
	cp -p vouch vouch.orig
	sed \
		-e "s:^__version__='UNRELEASED':__version__='$(TAG)':" \
		-e "s:^__signer__='':__signer__='$$(cat $(SIGNING_PUBKEY))':" \
		< vouch.orig > vouch
	-rm -f vouch.sig
	ssh-keygen -Y sign -f $(SIGNING_PUBKEY) -n 'vouch.id release' vouch
	gh release create -d --generate-notes $(TAG) vouch vouch.sig
	mv vouch.orig vouch
