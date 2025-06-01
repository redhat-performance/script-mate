#!/bin/bash

# Generic helpers for logging

# Detect if we are in terminal and can use coloured output
# https://unix.stackexchange.com/questions/9957/how-to-check-if-bash-can-print-colors
_COLORS=false
if [ -t 1 ]; then
    ncolors=$(tput colors)
    if [ -n "$ncolors" ] && [ "$ncolors" -ge 8 ]; then
        _COLORS=true
        _NORMAL="$(tput sgr0)"
        _BOLD="$(tput bold)"
        _YELLOW="$(tput setaf 3)"
        _GREEN="$(tput setaf 2)"
        _MAGENTA="$(tput setaf 5)"
        _RED="$(tput setaf 1)"
    fi
fi

# Internal: Logging function doing actual output.
function _log() {
    if $_COLORS; then
        case $1 in
            DEBUG) c=$_YELLOW;;
            INFO) c=$_GREEN;;
            WARNING) c=$_MAGENTA;;
            ERROR|FATAL) c=$_RED;;
            *) c="";;
        esac
        echo "${c}$( date -Ins --utc ) ${_BOLD}${1}${_NORMAL}${c} ${2}${_NORMAL}" >&2
    else
        echo "$( date -Ins --utc ) ${1} ${2}" >&2
    fi
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
