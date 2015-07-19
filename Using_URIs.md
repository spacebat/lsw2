**Work in progress** document on how URIs work in lsw2.

The files to consult are primarily uri.lisp and namespace.lisp in /util.

There are two ways to specify the full URI:

1.	using a namespace prefix (make-uri nil "ex:bob") which expands the prefix "ex:" (defined in util/namespace.lisp)
2.	using a full path (make-uri "http://example.com/bob")

you can also directly call make-uri-base-relative (discussed below):
(make-uri-base-relative "foo" "ex:") -> !ex:foo

The expansion in #1 is due to a lookup of predefined prefixes that are stored in a list, `*namespace-replacements*`.
e.g.: `(car  *namespace-replacements*)` => `("http://xmlns.com/wordnet/1.6/" "wordnet:")`

uris (default and new (?)) are stored in a hash table, `*interned-uris*`.

The default uri namespace is a string stored in `*default-uri-base*` and is "http://www.example.com".

a uri is a struct, which includes the fields full, abbreviated, and blank-p.

make-uri has the following signature:
(make-uri string &optional abbreviation)
If string is nil and abbreviation is given, it will perform a lookup to "unabbreviate" the short name before storing in `*interned-uris*`.

make-uri has the following signature:
`(make-uri-base-relative (string &optional (base *default-uri-base*))`
Concatentates base and string and calls make-uri.

(What is '!' used for?)
The symbol `!' is set as a macro character for read-uri

make-uri has the following signature:
(read-uri (stream char))
Does some error handling and calls get-uri-alias-or-make-uri-base-relative.

get-uri-alias-or-make-uri-base-relative has the signature:
(get-uri-alias-or-make-uri-base-relative (string))
Retrieves alias from `*local-uri-aliases*` or adds a new one (to `*interned-uris*`).