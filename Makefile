SIGNING_GH_USER=tonyg

all:

tag: $(SIGNING_GH_USER).keys
	git -c gpg.format=ssh -c user.signingKey="`cat $(SIGNING_GH_USER).keys`" tag -m $(TAG) -s $(TAG)
	git push --tag

.INTERMEDIATE: $(SIGNING_GH_USER).keys vouch.sig

%.keys:
	curl -s -O https://github.com/$@

release: tag vouch $(SIGNING_GH_USER).keys
	cp -p vouch vouch.orig
	sed \
		-e "s:^__version__='UNRELEASED':__version__='$(TAG)':" \
		-e "s:^__signer__='':__signer__='$$(cat $(SIGNING_GH_USER).keys)':" \
		< vouch.orig > vouch
	-rm -f vouch.sig
	ssh-keygen -Y sign -f $(SIGNING_GH_USER).keys -n 'vouch.id release' vouch
	gh release create -d --generate-notes $(TAG) vouch vouch.sig
	mv vouch.orig vouch
