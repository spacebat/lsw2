How do I run a sparql query on an ontology that is created?

> -First set up a toy ontology:
(setf ont (with-ontology foo (:collecting t) ((asq (subclass-of !human !mortal))) foo))

> -inspect the form (useful for debugging):
(sparql-stringify '(:select (?a) () (?a !rdfs:subClassOf !ex:mortal)))

> -query all the subclasses of mortal:
(sparql '(:select (?a) () (?a !rdfs:subClassOf !ex:mortal)) :kb ont :use-reasoner :sparqldl)

output:
((!ex:human) (!owl:Nothing) (!ex:mortal))