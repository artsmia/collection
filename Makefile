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

git:
	git add --all departments/
	git add --all exhibitions/
	for dir in . private; do \
		cd $$dir; \
		find objects -name 'sed*' | xargs rm; \
		git add --all objects/; \
		git commit -m "$$(date +%Y-%m-%d): $$(git status -s -- objects/* | wc -l | tr -d ' ') changed"; \
		git push; \
	done

daily: objects exhibitions departments check_public_access git

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
	ag -l '"public_access": "0"' objects | while read file; do mkdir private/$$(dirname $$file) 2>/dev/null; mv $$file private/$$file; echo $$file ' -> private'; done
	ag -l '"public_access": "1"' private/objects | while read file; do mv $$file $${file#private/}; echo $$file ' -> public'; done
	time ag -l public_access {private/,}objects | while read file; do grep -v public_access $$file | sponge $$file; done

departments:
	@curl --silent $(internalAPI)/departments/ | jq -r 'map([.department, .department_id])[][]' | while read name; do \
		read id; \
		curl --silent $(internalAPI)/departments/$$id \
		| jq --arg name "$$name" --arg id "$$id" '{name: $$name, id: $$id, artworks: map(.object_id)}' \
		> departments/$$id.json; \
	done;

.PHONY: objects departments exhibitions

exhibitionIds = $$(curl --silent 'http://api.artsmia.org/exhibitions' | jq 'map(.exhibition_id) | sort | .[]' | uniq)
# IDEA - iterating all ~2k exhibitions takes a long time.
# Could this only do the latest 50 6 days a week, and on the 7th day do all umpteen thousand?
exhibitions:
	@for id in $(exhibitionIds); do \
		bucket=$$((id/1000)); \
		printf "$$id "; \
		[[ -d exhibitions/$$bucket ]] || mkdir exhibitions/$$bucket; \
		file=exhibitions/$$bucket/$$id.json; \
		curl --silent "http://api.artsmia.org/exhibitions/$$id" \
		| grep '^{' \
		| jq '.exhibition + {objects: [.objects[] | values] | sort | unique}' \
		> $$file; \
		if [[ $$? -gt 0 ]]; then \
			>&2 echo $$id failed; \
		else \
			if jq --exit-status '.objects | length > 0' $$file > /dev/null; then \
				venues=$$(jq -r '.objects[]' $$file \
				| xargs -I "{}" curl --silent "http://api.artsmia.org/exhibitions/object/{}" \
				| grep  '^{' | sed 's/<br \/>//g' \
				| jq -s "[.[].exhibitions[] | select(.exhibition_id == $$id) | { \
					venue: (.venue // .[\"1\"]), begin: .begin, end: .end, display_date: .display_date \
				}] | unique_by([.venue, .display_date])"); \
			else \
				venues="[]"; \
			fi; \
			withVenues=$$(jq --arg venues "$$venues" '. + {venues: $$venues | fromjson}' $$file); \
			if [[ $$? -eq 0 ]]; then jq '.' <<<$$withVenues > $$file; else >&2 echo $$id venues failed; fi; \
		fi; \
	done;

exhibitionIndexCsv:
	curl --silent 'http://api.artsmia.org/exhibitions' \ 
	| jq -r 'map([.exhibition_id, .exhibition_title]) | .[] | @csv' \
	| uniq | sort -n > all_exhibitions.csv

redisDb=9
redisPrefix=mia-collection:
# The above are set to not accidentally overwrite the default collection information (`-n 0` with no prefix) but in order to re-populate that, overwrite in the `make` command
buildRedisFromJSONFiles:
	find objects/$(buckets) -name '*.json' | while read file; do \
			id=$$(basename $$file .json | cut -d'/' -f3); \
			bucket=$$(($$id/1000)); \
			jq -c '.' $$file | redis-cli -x -n $(redisDb) hset $(redisPrefix)object:$$bucket $$id >/dev/null; \
		done

objectFileToRedis:
	@id=$$(basename $(file) .json); \
	bucket=$$(($$id/1000)); \
	jq -c '.' $(file) | redis-cli -x -n $(redisDb) hset $(redisPrefix)object:$$bucket $$id >/dev/null;

allObjectFilesToRedis:
	find objects -type f \
	| parallel --bar --joblog +jsonToRedis.joblog \
	    make objectFileToRedis file={} redisDb=$(redisDb) redisPrefix=$(redisPrefix)
