SHELL := /bin/bash
# Ask redis for all the buckets.
# `make objects buckets=12` only updates bucket 12
buckets = $$(redis-cli keys 'object:*' | egrep 'object:[0-9]+$$$$' | cut -d ':' -f 2 | sort -g)

.PHONY: objects
objects:
	for bucket in $(buckets); do \
		[[ -d objects/$$bucket ]] || mkdir objects/$$bucket; \
		redis-cli --raw hgetall object:$$bucket | while read id; do \
			read -r json; \
			echo $$id; \
			echo "$$json" | jq '.' > objects/$$bucket/$$id.json; \
		 done \
	done

git: objects
	git add objects/
	git commit -m "$$(date +%Y-%m-%d): $$(git status -s -- objects/* | wc -l | tr -d ' ') changed"
	git push
