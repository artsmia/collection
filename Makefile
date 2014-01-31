SHELL := /bin/bash
buckets = $$(redis-cli keys 'object:*' | egrep 'object:[0-9]+$$$$' | cut -d ':' -f 2 | sort -g)
bucket = $(buckets)
# ^ `make objects bucket=12` will clobber and only update 12

.PHONY: objects
objects:
	for bucket in $(bucket); do \
		[[ -d $$bucket ]] || mkdir objects/$$bucket; \
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
