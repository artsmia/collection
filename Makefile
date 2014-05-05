SHELL := /bin/bash
# Ask redis for all the buckets.
# `make objects buckets=12` only updates bucket 12
buckets = $$(redis-cli keys 'object:*' | egrep 'object:[0-9]+$$$$' | cut -d ':' -f 2 | sort -g)

objects:
	for bucket in $(buckets); do \
		echo $$bucket; \
		[[ -d objects/$$bucket ]] || mkdir objects/$$bucket; \
		redis-cli --raw hgetall object:$$bucket | grep -v "<br />" | while read id; do \
			if [[ $$id = *[[:digit:]]* ]]; then \
				read -r json; \
				echo "$$json" | jq --sort-keys '.' > objects/$$bucket/$$id.json; \
			fi; \
		done \
	done

git: objects
	git add objects/
	git commit -m "$$(date +%Y-%m-%d): $$(git status -s -- objects/* | wc -l | tr -d ' ') changed"
	git push

count:
	find objects/* | wc -l

.PHONY: objects git count
