The function loadOnt (below) takes as its argument a list of `object-property-assertion`s and returns an ontology.
The function readRecords takes two arguments, a file name string and a string of what you want to uri to be, and returns a list of `objet-property-assertion`s.

The file must include tab delimited "triples" (e.g. loves bob susan) separated by newlines.
The triples are asserted as object property assertions in OWL. The function readRecords does the necessary parsing.

> example usage:
> (setf ont (loadOnt (readRecords "dummy-records.txt" "http://www.purl.org/newOntology/")))

> dummy-records.txt:
hasWife	Bob	Sally 

&lt;cr&gt;


hasBrother	Bill	Tim 

&lt;cr&gt;


hasSister	Sally	Megan 

&lt;cr&gt;



> To output the results in owl:

`(to-owl-syntax foo :rdfxml)`
```
 <rdf:Description rdf:about=\"http://www.purl.org/newOntology/Bill\">
        <www:newOntology/hasBrother rdf:resource=\"http://www.purl.org/newOntology/Tim\"/>
    </rdf:Description>
    <rdf:Description rdf:about=\"http://www.purl.org/newOntology/Bob\">
        <www:newOntology/hasWife rdf:resource=\"http://www.purl.org/newOntology/Sally\"/>
    </rdf:Description>
    <rdf:Description rdf:about=\"http://www.purl.org/newOntology/Sally\">
        <www:newOntology/hasSister rdf:resource=\"http://www.purl.org/newOntology/Megan\"/>
    </rdf:Description>
```
```
(defun loadOnt (records)
  (with-ontology foo (:collecting t) ((as records)) foo))
 
(defun readRecords(filename uri-string)
  (setf records nil)
  (with-open-file (f filename)
     (loop for line = (read-line f nil :eof)
        until (eq line :eof)
        do
	 (let ((match (split-at-regex line "\\t")))
	   (let ((predicate (first match)) (subject (second match)) (object (third match)))
		    (push `(object-property-assertion (make-uri ,(concatenate 'string uri-string predicate))
					    (make-uri ,(concatenate 'string uri-string subject))
					    (make-uri ,(concatenate 'string uri-string object))) records)))
  finally (return records))))
```