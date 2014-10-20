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
				echo "$$json" | jq --sort-keys '.' > objects/$$bucket/$$id.json 2> /dev/null; \
				if [[ $$? -gt 0 ]]; then >&2 echo $$id failed; fi; \
			fi; \
		done \
	done
	ag -l '%C2%A9|%26Acirc%3B%26copy%' objects/ | xargs sed -i'' -e 's/%C2%A9/©/g; s/%26Acirc%3B%26copy%3B/©/g'

git: objects
	git add objects/
	git commit -m "$$(date +%Y-%m-%d): $$(git status -s -- objects/* | wc -l | tr -d ' ') changed"
	git push

count:
	find objects/* | wc -l

reset_objects:
	git co objects; git status -sb | grep objects | grep '??' | cut -d' ' -f2 | xargs rm

watch_changed_ids:
	redis-cli monitor | grep --line-buffered 'hmset' | while read line; do \
		echo $$line | cut -d' ' -f6 | sed 's/"//g'; \
	done

update:
	id=$(id)
	curl --silent api.artsmia.org/objects/$(id)/full/json \
	| jq --sort-keys '.' \
	| sed 's/%C2%A9/©/g; s/%26Acirc%3B%26copy%3B/©/g' > objects/$$((id/1000))/$$id.json
	for host in $(redises); do \
		cat objects/$$((id/1000))/$$id.json \
		| jq --sort-keys -c '.' \
		| redis-cli -h $$host -x hset object:$$((id/1000)) $$id > /dev/null; \
	done

.PHONY: objects git count
