Our objects are divided into 'buckets' by: `id / 1000`. So 100 -> bucket #1, 4568 -> 4, 98742 -> 98, ….

Object records live at `objects/$bucket/$id.json`. They look like:

```json
{
  "restricted": 0,
  "image": "valid",
  "image_copyright": "",
  "life_date": "American, 1838 - 1909",
  "nationality": "American",
  "role": "Artist",
  "dated": "19th century",
  "culture": null,
  "country": "United States",
  "continent": "North America",
  "dimension": "3 1/4 x 7 1/2 in. (8.26 x 19.05 cm)",
  "medium": "Graphite",
  "title": "Sketch made on Indian Reservation, Montana",
  "id": "http://api.artsmia.org/objects/17",
  "room": "Not on View",
  "style": "19th century",
  "marks": "Signature [Cheyenne. W. Shirlaw]",
  "text": "",
  "description": "",
  "creditline": "Gift of Mrs. Florence M. Shirlaw",
  "accession_number": "13.59 ",
  "artist": "Walter Shirlaw"
}
```
(`0/17.json`)
