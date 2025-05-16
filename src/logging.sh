# Generic helpers for logging

# Internal: Logging function doing actual output.
function _log() {
    echo "$( date -Ins --utc ) $1 $2" >&2
}

# Public: Logging function for "debug" level.
#
# $1 - Message to log.
function debug() {
    _log DEBUG "$1"
}


# Public: Logging function for "info" level.
#
# $1 - Message to log.
function info() {
    _log INFO "$1"
}


# Public: Logging function for "warning" level.
#
# $1 - Message to log.
function warning() {
    _log WARNING "$1"
}


# Public: Logging function for "error" level.
#
# $1 - Message to log.
function error() {
    _log ERROR "$1"
}


# Public: Logging function for "fatal" level, also exits script with exit code 1.
#
# $1 - Message to log.
function fatal() {
    _log FATAL "$1"
    exit 1
}
