redis-cli -h $argv monitor | grep --line-buffered 'hmset' | while read line;
  set id (echo $line | cut -d' ' -f6 | sed 's/"//g')
  set json (node -e 'console.log(JSON.parse(process.argv[1]))' (echo $line | cut -d' ' -f7-1000 | sed -e 's/%C2%A9/©/g; s/%26Acirc%3B%26copy%3B/©/g'))
  set dir objects/(math $id/1000)
  set file $dir/$id.json
  if test (echo $json | jq '.public_access') -eq 0
    set private true
    cd private
  end
  echo $id "           --" (date +'%m/%d %H:%M')
  not test -d $dir; and mkdir $dir
  echo $json | jq --sort-keys '.' | grep -v public_access > $file
  # cd dat; echo $json | dat import --json --primary=id > /dev/null; cd ..
  git add -N $file
  git --no-pager diff $file
  cd ~/tmp/collection/
end
