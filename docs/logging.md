`_COLORS`
---------

Internal: Detect if we are in terminal and can use coloured output https://unix.stackexchange.com/questions/9957/how-to-check-if-bash-can-print-colors


`_log()`
--------

Internal: Logging function doing actual output.


`debug()`
---------

Public: Logging function for "debug" level.

* $1 - Message to log.


`info()`
--------

Public: Logging function for "info" level.

* $1 - Message to log.


`warning()`
-----------

Public: Logging function for "warning" level.

* $1 - Message to log.


`error()`
---------

Public: Logging function for "error" level.

* $1 - Message to log.


`fatal()`
---------

Public: Logging function for "fatal" level, also exits script with exit code 1.

* $1 - Message to log.


