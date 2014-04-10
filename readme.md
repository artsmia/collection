Our objects are divided into 'buckets' by their `id / 1000`. Bucket 0
holds records 0-999; bucket 1, 1000-1999, ….

Each record lives in a json file at `objects/$bucket/$id.json`. Here's
what [`objects/0/17.json`][] looks like:

```json
{
  "accession_number": "13.59",
  "artist": "Walter Shirlaw",
  "continent": "North America",
  "country": "United States",
  "creditline": "Gift of Mrs. Florence M. Shirlaw",
  "culture": null,
  "dated": "19th century",
  "description": "",
  "dimension": "3 1/4 x 7 1/2 in. (8.26 x 19.05 cm)",
  "id": "http://api.artsmia.org/objects/17",
  "image": "valid",
  "image_copyright": "",
  "life_date": "American, 1838 - 1909",
  "marks": "Signature [Cheyenne. W. Shirlaw]",
  "medium": "Graphite",
  "nationality": "American",
  "provenance": "",
  "restricted": 0,
  "role": "Artist",
  "room": "Not on View",
  "style": "19th century",
  "text": "",
  "title": "Sketch made on Indian Reservation, Montana"
}
```

[`objects/0/17.json`]: https://github.com/artsmia/collection.json/blob/master/objects/0/17.json
