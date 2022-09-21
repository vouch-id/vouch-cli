SIGNING_GH_USER=tonyg

all:

tag: $(SIGNING_GH_USER).keys
	git -c gpg.format=ssh -c user.signingKey="`cat $(SIGNING_GH_USER).keys`" tag -m $(TAG) -s $(TAG)
	git push --tag

%.sig: % $(SIGNING_GH_USER).keys
	-rm -f $@
	ssh-keygen -Y sign -f $(SIGNING_GH_USER).keys -n 'vouch.id release' $*

.INTERMEDIATE: $(SIGNING_GH_USER).keys vouch.sig

%.keys:
	curl -s -O https://github.com/$@

release: tag vouch vouch.sig
	gh release create -d --generate-notes $(TAG) vouch vouch.sig
