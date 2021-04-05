default: public.json all.json

public.json:
	ag -l 'public_info": 1' */*.json | xargs cat | jq -s '.' | sponge public.json

all.json:
	ag -l 'public_info' */*.json | xargs cat | jq -s '.' | sponge all.json
