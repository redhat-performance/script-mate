# Generic helpers for logging

_YELLOW='\033[1;33m'
_GREEN='\033[0;32m'
_ORANGE='\033[0;33m'
_RED='\033[0;31m'
_NC='\033[0m'

# Internal: Logging function doing actual output.
function _log() {
    case $1 in
        DEBUG) c=$_YELLOW;;
        INFO) c=$_GREEN;;
        WARNING) c=$_ORANGE;;
        ERROR|FATAL) c=$_RED;;
        *) c="";;
    esac
    echo -e "${c}$( date -Ins --utc ) ${1} ${2}${_NC}" >&2
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
