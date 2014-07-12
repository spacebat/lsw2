;; Copyright © 2013 Alan Ruttenberg and SUNY at Buffalo All Rights Reserved.

;; Redistribution and use in source and binary forms, with or without
;; modification, are permitted provided that the following conditions
;; are met:

;; 1. Redistributions of source code must retain the above copyright
;; notice, this list of conditions and the following disclaimer.

;; 2. Redistributions in binary form must reproduce the above
;; copyright notice, this list of conditions and the following
;; disclaimer in the documentation and/or other materials provided
;; with the distribution.

;; 3. The name of the author may not be used to endorse or promote
;; products derived from this software without specific prior written
;; permission.

;; THIS SOFTWARE IS PROVIDED BY Alan Ruttenberg "AS IS" AND ANY EXPRESS OR
;; IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED
;; WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
;; ARE DISCLAIMED. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY
;; DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL
;; DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE
;; GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
;; INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,
;; WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING
;; NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS
;; SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.

(defvar *default-connection* nil)
(defvar *jdbc-trace* nil)

(defun with-jdbc-connection (fn jdbc-url)
  (let ((connection nil))
    (unwind-protect
	 (progn
	   (when (search "jdbc:sqlite" jdbc-url) 
	       (#"forName" 'Class "org.sqlite.JDBC"))
	   (let ((*default-connection* (#"getConnection" 'java.sql.DriverManager jdbc-url)))
	     (funcall fn *default-connection*)))
      (and connection (#"close" connection))
      )))

(defgeneric with-jdbc-connection-named (keyword function)
  (:documentation "if a sql query is executed with a connection that is a keyword instead of a connection object, the sql is wrapped in a lambda and passed to this function, which calls the lambda with a single argument which is the connection. Clients of this functionality need to define eql methods on the first argument to implement the necessary setup of the connection"
  ))

;; Do a sql query to connection. Result is a list of list, with each list one row of fields.
;; if with-headers is non-nil, then the values are instead ("fieldname" . value) instead of just value.
;; query can be a list of strings, in which case they are concatenated
;; if format-args is supplied then the query string used as a format string with the format-args
(defun sql-query (query &optional (connection *default-connection*) &key with-headers print format-args trace)
  (when (listp query) (setq query (format nil "~{~a~^ ~}" query)))
  (when format-args (setq query (apply 'format nil query format-args)))
  (when (or trace *jdbc-trace*) (print query))
  (if (keywordp connection)
      (with-jdbc-connection-named connection
	(lambda(c) (sql-query query c :with-headers with-headers :print print)))
      (if (and (null connection) (not (null *default-connection*)))
	  (sql-query query *default-connection* :with-headers with-headers :print print)
	  (cond ((or (equal "com.microsoft.sqlserver.jdbc.SQLServerConnection" (jclass-name (jobject-class connection)))
		     (equal "oracle.jdbc.driver.T4CConnection" (jclass-name (jobject-class connection)))
		     (equal "com.hxtt.sql.access.r" (jclass-name (jobject-class connection)))
		     (equal "org.postgresql.jdbc4.Jdbc4Connection" (jclass-name (jobject-class connection)))
		     (equal "org.sqlite.Conn" (jclass-name (jobject-class connection)))
		     (equal "com.mysql.jdbc.JDBC4Connection" (jclass-name (jobject-class connection))))
		 (let (statement results)
		   (unwind-protect 
			(progn
			  (setq statement (#"createStatement" connection))
			  (setq results (#"executeQuery" statement (if (consp query) (apply 'format nil (car query) (cdr query)) query )))
			  (when print 
			    (format t "~{~a~^	~}~%" (loop for i from 1 to (#"getColumnCount" (#"getMetaData" results)) collect (#"getColumnName" (#"getMetaData" results) i))))
			  (loop while (#"next" results) 
			     with headers and columns
			     collect (block columns (loop for column from 1 to (#"getColumnCount" (#"getMetaData" results))
						       if with-headers
						       do (unless headers (setq headers (make-array (#"getColumnCount" (#"getMetaData" results)))) )
						       and collect (cons (or (svref headers (1- column))
									     (setf (svref headers (1- column))
										   (#"getColumnName" (#"getMetaData" results) column)))
									 (#"getString" results column)) into columns
						       else collect (#"getString" results column) into columns
						       finally (return-from columns (if print (progn (format t "~{~s~^	~}~%" (mapcar 'cdr columns)) (values)) columns))))
			     into rows
			     finally (if print nil (return-from nil rows))))
		     (and (boundp 'results) results (#"close" results))
		     (and (boundp 'statement) statement (#"close" statement)))
		   ))
		(t (error "Don't yet support sql-query for ~a" (jclass-name (jobject-class connection))))))))

(defun sql-server-driver-properties ()
  (map 'list (lambda(e)
	       (cons (get-java-field e "name" t)
		     (get-java-field e "description" t)))
       (get-java-field 'SQLServerDriver "DRIVER_PROPERTIES"t)))

;;(add-to-classpath "/Volumes/Big/Downloads/2011/2011-01-13/sqljdbc_3.0/enu/sqljdbc4.jar")
;;(add-to-classpath "/Volumes/Big/Downloads/2013-04-12/sqljdbc_4.0/enu/sqljdbc4.jar")
;; sqljdbc4.jar is in lib/
;; not enough in java 7 - put sqljdbc4.jar in same dir as abcl.jar

(defun table-column-names  (table connection)
  (mapcar 'car (car (sql-query (list "select top 1 * from ~a" table) connection :with-headers t))))

(defun table-rowcount (table connection)
  "Return the number or rows in a table"
  (caar (sql-query (list "select count(*) from ~a" table) connection)))

(defun sql-server-columns-matching (connection &key (table-match "%")  schema (column-match "%"))
  "Retrieve table,schema,column for all tables. Constraint tables to match table-match and column to match column-match"
  (sql-query (list "SELECT t.name AS table_name, SCHEMA_NAME(schema_id) AS schema_name, c.name AS column_name FROM sys.tables AS t
INNER JOIN sys.columns c ON t.OBJECT_ID = c.OBJECT_ID
where t.name like '~a' and c.name like '~a'
ORDER BY schema_name, table_name;" table-match  column-match) connection))

(defun table-names (connection)
  (cond ((equal "com.hxtt.sql.access.r" (jclass-name (jobject-class connection)))
	 (let ((arr (jnew-array "java.lang.String" 1)))
	   (jarray-set arr "TABLE" 0)
	   (loop with tables = 
		(#"getTables" (#"getMetaData" c) +null+ +null+ "%" arr)
	      for next? = (#"next" tables)
	      until (not next?) do (print (#"getString" tables 3))
		)))
	(t (error "table-names not supported for other than access database at the moment"))))

(defun table-counts (connection tables &optional (threshold 1) &rest fields)
  (loop for table in tables 
     for count = (parse-integer (caar (sql-query (format nil "select count(*) from ~a" table) connection)))
     if (and (plusp count)
	     (<= count threshold)
	     fields)
     collect (list table count (sql-query (format nil "select ~{~a~^,~} from ~a" fields table) connection))
     else collect (list table count)))
