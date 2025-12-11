+++
date = "2013-07-31 12:09:43+00:00"
title = "Spatial search on multiple points in Solr"
tags = ["django", "python", "search", "solr"]
description = "Finding the closest location across globally distributed clinical trials"
+++

At TrialReach we deal with clinical trials data, which contain a lot of spatial information. Tipically, clinical trials treat a certain set of conditions and they happen in various locations globally.
If you are a patient then searching across clinical trials becomes really spatial sensitive: you are only interested in the closest location to you.

This case might apply to other events as well, but the key point is global distribution. I am not interested in any point in the globe, just the closest to me.

<h2>Solution</h2>
Solr 4 does have support for this with the new spatial field called SpatialRecursivePrefixTreeFieldType, with many caveats though.

A schema could look this way:

```xml
<?xml version="1.0" encoding="UTF-8" ?>
<schema name="example" version="1.5">
 <fields>
   <field name="id" type="string" indexed="true" stored="true" required="true" multiValued="false" /> 
   <field name="title" type="text_en" indexed="true" stored="true" required="true"/>
   <field name="condition" type="text_en" indexed="true" stored="true" required="true" multiValued="true"/>
   <field name="location" type="location_rpt" indexed="true" stored="true" multiValued="true"/>
   <field name="_version_" type="long" indexed="true" stored="true" />
 </fields>
 ... 
  <types>
 ...
    <fieldType name="location_rpt" class="solr.SpatialRecursivePrefixTreeFieldType"
        geo="true" distErrPct="0.025" maxDistErr="0.000009" units="degrees" />
 </types>
</schema>
```

A sample indexer using GeoDjango and PySolr (Haystack does not support this). It should be quite easy to work out how it works, PySolr is just a very thin wrapper for doing HTTP POST requests to Apache Solr.

```python
import pysolr

solr = pysolr.Solr("http://1.2.3.4:8983/solr/", timeout=10)

records = models.Study.objects.all()
solr_data = []
for record in records:
    solr_dict = {
                "id": str(record.id),
                "title": record.title,
                "condition": [c.name for c in record.conditions.all()],
                "location": ["{1} {0}".format(l.point.coords[0], l.point.coords[1]) for l in record.locations.all()],
		# "point" is a Point GeoDjango type
		# SOLR FORMAT is "long lat", separated by a space
            }
    solr_data.append(solr_dict)
solr.add(solr_data)
```

For querying, we use these sort of urls:

```
http://1.2.3.4:8983/solr/select/?sort=score+asc&fq=title:lupus+condition:lupus&q={!geofilt score=distance sfield=location pt=LAT,LONG d=KM_RADIUS}&fl=*,score
```

- to return the distance you need to use the score, and the only thing you use in the q parameter is the geofilt (otherwise will influence the score), all other filters go in fq
- if you do not need the distance, loose the score parameter in geofilt (it is inefficient)
- distance returned is the distance between specified LAT,LONG and the closest LAT,LONG in the SpatialRecursivePrefixTreeFieldType set.
- score returned is in DEGREES. You have to convert it in Km or miles.

<h2>Shortcomings</h2>
- the only way to get the distance is through the score
- you cannot get the matched point through highlighting or any other way
- units of measure are a bit confusing