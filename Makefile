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
				file=objects/$$bucket/$$id.json; \
				if [[ -f private/$$file ]]; then file=private/$$file; fi; \
				echo "$$json" | jq --sort-keys '.' > $$file 2> /dev/null; \
				if [[ $$? -gt 0 ]]; then >&2 echo $$id failed; fi; \
			fi; \
		done \
	done
	ag -l '%C2%A9|%26Acirc%3B%26copy%' {private/,}objects/ | xargs sed -i'' -e 's/%C2%A9/©/g; s/%26Acirc%3B%26copy%3B/©/g'

git: objects check_public_access
	for dir in . private; do \
		cd $$dir; \
		git add --all objects/; \
		git commit -m "$$(date +%Y-%m-%d): $$(git status -s -- objects/* | wc -l | tr -d ' ') changed"; \
		git push; \
	done

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
	| grep -v public_access \
	| sed 's/%C2%A9/©/g; s/%26Acirc%3B%26copy%3B/©/g' > objects/$$((id/1000))/$$id.json
	for host in $(redises); do \
		cat objects/$$((id/1000))/$$id.json \
		| jq --sort-keys -c '.' \
		| redis-cli -h $$host -x hset object:$$((id/1000)) $$id > /dev/null; \
	done

check_public_access:
	ag -l '"public_access": 0' objects | while read file; do mkdir private/$$(dirname $$file) 2>/dev/null; mv $$file private/$$file; echo $$file ' -> private'; done
	ag -l '"public_access": 1' private/objects | while read file; do mv $$file $${file#private/}; echo $$file ' -> public'; done
	time ag -l public_access {private/,}objects | while read file; do grep -v public_access $$file | sponge $$file; done

departments:
	@curl --silent $(internalAPI)/departments/ | jq -r 'map([.department, .department_id])[][]' | while read name; do \
		read id; \
		curl --silent $(internalAPI)/departments/$$id \
		| jq --arg name "$$name" --arg id "$$id" '{name: $$name, id: $$id, artworks: map(.object_id)}' \
		> departments/$$id.json; \
	done;

.PHONY: objects git count departments
