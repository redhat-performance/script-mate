`PROW_GCSWEB_HOST`
------------------

Public: Prow host that can be used to download CI artifacts


`HORREUM_HOST`
--------------

Public: Horreum host


`ES_HOST`
---------

Public: ElasticSearch/OpenSearch host


`DASHBOARD_ES_INDEX`
--------------------

Public: Results dashboard ElasticSearch/OpenSearch index name


`DRY_RUN`
---------

Public: Whether to do writes to remote systems or just skip them


`check_json()`
--------------

Public: Checks if given file is a valid JSON.

* $1 - File to verify.

Returns exit code 0 if file is valid JSON, 1 othervise.


`check_json_string()`
---------------------

Public: Checks if given string is a valid JSON.

* $1 - String to verify.

Returns exit code 0 if string is valid JSON, 1 othervise.


`json_complete()`
-----------------

Public: Checks if given JSON file have main expected fields.

* $1 - File to check.

Returns exit code 0 if JSON file have all expected fields, 1 othervise.


`enritch_stuff()`
-----------------

Public: Add or update key and value to JSON file.

* $1 - File to work with.
* $2 - Field name to add/update.
* $3 - Field value to add/update.

Returns exit code 0.


`prow_list()`
-------------

Public: List test run IDs from Prow.

* $1 - Prow job name.

Returns exit code 0 and prints job IDs, one a line.


`prow_subjob_list()`
--------------------

Public: TODO.


`prow_download()`
-----------------

Public: Download artifact from Prow job result.

* $1 - Prow job name.
* $2 - Prow job run ID.
* $3 - Prow job run name.
* $4 - Artifact path in Prow storage.
* $5 - Output file name where to store the downloaded file.

Returns exit code 0.


`horreum_upload()`
------------------

Public: Upload JSON data file to Horreum if it is not there already.

* $1 - Status data file name (JSON file).
* $2 - Key name from the JSON file we will use to check if this file is already ther in the Horreum.
* $3 - Horreum label name that corresponds with previous parameter on a Horreum side.

Returns exit code 0 and prints job IDs, one a line.


`resultsdashboard_upload()`
---------------------------

Public: Upload new result to our Results Dashboard.

* $1 - Status data file location.
* $2 - Product group to use in Results Dashboard.
* $3 - Product name to use in Results Dashboard.
* $4 - Version of the tested product instance.

It is also possible to use `@field` notation for loading actual value of the parameter from status data file field `.field`.

Returns exit code 0 and prints job IDs, one a line.


`format_date()`
---------------

Public: TODO.


