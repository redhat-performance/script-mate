#!/bin/bash

# Helpers for shovel.py tool from OPL and for working with status data JSONs
# https://github.com/redhat-performance/opl/blob/main/opl/shovel.py

# Public: Prow host that can be used to download CI artifacts
PROW_GCSWEB_HOST="${PROW_GCSWEB_HOST:-https://gcsweb-ci.apps.ci.l2s4.p1.openshiftapps.com}"

# Public: Horreum host
HORREUM_HOST="${HORREUM_HOST:-https://horreum.corp.redhat.com}"

# Public: ElasticSearch/OpenSearch host
ES_HOST="http://elasticsearch.intlab.perf-infra.lab.eng.rdu2.redhat.com"

# Public: Results dashboard ElasticSearch/OpenSearch index name
DASHBOARD_ES_INDEX="${DASHBOARD_ES_INDEX:-results-dashboard-data}"

# Public: Whether to do writes to remote systems or just skip them
DRY_RUN="${DRY_RUN:-false}"

# Public: Whether to print debugging output
DEBUG="${DEBUG:-false}"


# Source dependencies
source "$( dirname "${BASH_SOURCE[0]}" )/logging.sh"


# Check for required tools
if ! type shovel.py &>/dev/null; then
    fatal "shovel.py utility not available"
fi
if ! type jq >/dev/null; then
    fatal "Please install jq"
fi


# Check for required secrets
if [ -z "${HORREUM_API_TOKEN:-}" ]; then
    fatal "Please provide HORREUM_API_TOKEN variable"
fi


# Public: Checks if given file is a valid JSON.
#
# $1 - File to verify.
#
# Returns exit code 0 if file is valid JSON, 1 othervise.
function check_json() {
    local f="$1"
    if jq --exit-status . "$f" &>/dev/null; then
        debug "File is valid JSON, good"
        return 0
    else
        error "File is not a valid JSON, removing it and skipping further processing"
        $DEBUG && head "$f"
        rm -f "$f"
        return 1
    fi
}


# Public: Checks if given string is a valid JSON.
#
# $1 - String to verify.
#
# Returns exit code 0 if string is valid JSON, 1 othervise.
function check_json_string() {
    local data="$1"
    if echo "$data" | jq --exit-status . &>/dev/null; then
        return 0
    else
        error "String is not a valid JSON, bad"
        return 1
    fi
}


# Public: Checks if given JSON file have main expected fields.
#
# $1 - File to check.
# $2... - List of paths to check (optional, default is .started and .ended)
#
# Returns exit code 0 if JSON file have all expected fields, 1 othervise.
function json_complete() {
    local f="$1"

    local check_this
    if [[ $# -gt 1 ]]; then
        shift
        check_this=$@
    else
        check_this=".started .ended"
    fi

    debug "Checking if $f contains these fields: $check_this"

    local value
    for key in $check_this; do
        value="$( jq --raw-output "$key" "$f" )"
        if [ -z "$value" ] || [ "$value" = "null" ]; then
            error "File $f does not contain $key filed: '$value'"
            return 1
        fi
    done
}


# Public: Add or update key and value to JSON file.
#
# $1 - File to work with.
# $2 - Field name to add/update.
# $3 - Field value to add/update.
#
# Returns exit code 0.
function enritch_stuff() {
    local f="$1"
    local key="$2"
    local value="$3"
    local current_in_file

    current_in_file=$( jq --raw-output "$key" "$f" )
    if [[ "$current_in_file" == "None" ]]; then
        debug "Adding $key to JSON file"
        jq "$key = \"$value\"" "$f" >"$$.json" && mv -f "$$.json" "$f"
    elif [[ "$current_in_file" != "$value" ]]; then
        debug "Changing $key in JSON file"
        jq "$key = \"$value\"" "$f" >"$$.json" && mv -f "$$.json" "$f"
    else
        debug "Key $key already in file, skipping enritchment"
    fi
}


# Public: List test run IDs from Prow.
#
# $1 - Prow job name.
#
# Returns exit code 0 and prints job IDs, one a line.
function prow_list() {
    local job="$1"
    shovel.py prow --base-url "$PROW_GCSWEB_HOST/gcs/test-platform-results/logs/" --job-name "$job" list
}


# Public: List subjobs of a given job (these are basically just "run-*" directories in Prow job artifacts directory created by "max concurrency" type of jobs).
#
# $1 - Prow job name.
# $2 - Prow job run ID.
# $3 - Prow job run name.
# $4 - Artifact path in Prow storage.
#
# Returns exit code 0 and prints subjob directory names, one a line.
function prow_subjob_list() {
    local job="$1"
    local id="$2"
    local run="$3"
    local path="$4"
    # Note: this `... | rev | cut ... | rev` is just a hack how to get fields from back
    # (normally you would just use negative index for that, but cut does not support that)
    shovel.py html links \
        --url $PROW_GCSWEB_HOST/gcs/test-platform-results/logs/$job/$id/artifacts/$run/$path/ \
        --regexp ".*/run-[^/]+/" \
        | rev | cut -d "/" -f 2 | rev
}


# Public: Download artifact from Prow job result.
#
# $1 - Prow job name.
# $2 - Prow job run ID.
# $3 - Prow job run name.
# $4 - Artifact path in Prow storage.
# $5 - Output file name where to store the downloaded file.
# $6 - Where in resulting JSON to store original download path (optional, not used by default)
#
# Returns exit code 0.
function prow_download() {
    local job="$1"
    local id="$2"
    local run="$3"
    local path="$4"
    local out="$5"
    local record_link="${6:-}"
    if [ -e "$out" ]; then
        debug "We already have $out, not overwriting it"
    else
        shovel.py prow --job-name "$job" download --job-run-id "$id" --run-name "$run" --artifact-path "$path" --output-path "$out" --record-link "$record_link"
        info "Downloaded from Prow: $out"
    fi
}


# Public: Upload JSON data file to Horreum if it is not there already.
#
# $1 - Status data file name (JSON file).
# $2 - Key name from the JSON file we will use to check if this file is already ther in the Horreum.
# $3 - Horreum label name that corresponds with previous parameter on a Horreum side.
# $4 - Team owning the test in Horreum (optional, "rhtap-perf-test-team" by default).
# $5 - Result access setting in Horreum (optional, "PUBLIC" by default).
#
# Returns exit code 0 and prints job IDs, one a line.
function horreum_upload() {
    local f="$1"
    local test_job_matcher="${2:-jobName}"
    local test_job_matcher_label="${3:-jobName}"

    local test_owner="${4:-rhtap-perf-test-team}"
    local test_access="${5:-PUBLIC}"

    local test_matcher
    test_matcher="$( status_data.py --status-data-file "$f" --get "$test_job_matcher" )"

    debug "Uploading to Horreum: $f with $test_job_matcher_label(a.k.a. $test_job_matcher): $test_matcher"

    if $DRY_RUN; then
        echo shovel.py horreum --base-url "$HORREUM_HOST" --api-token "..." upload --test-name "@name" --owner "$test_owner" --access "$test_access" --input-file "$f" --matcher-field "$test_job_matcher" --matcher-label "$test_job_matcher_label" --start "@started" --end "@ended" --trashed --trashed-workaround-count 20
        echo shovel.py horreum --base-url "$HORREUM_HOST" --api-token "..." result --test-name "@name" --output-file "$f" --start "@started" --end "@ended"
    else
        shovel.py horreum --base-url "$HORREUM_HOST" --api-token "$HORREUM_API_TOKEN" upload --test-name "@name" --owner "$test_owner" --access "$test_access" --input-file "$f" --matcher-field "$test_job_matcher" --matcher-label "$test_job_matcher_label" --start "@started" --end "@ended" --trashed --trashed-workaround-count 20
        info "Uploaded to Horreum: $f"
        shovel.py horreum --base-url "$HORREUM_HOST" --api-token "$HORREUM_API_TOKEN" result --test-name "@name" --output-file "$f" --start "@started" --end "@ended"
        info "Determined result from Horreum $f: $( jq -r .result "$f" )"
    fi
}


# Public: Upload given JSON file to OpenSearch/ElasticSearch.
#
# $1 - Status data file location.
# $2 - Field in the JSON we should use to check if document is already there.
#
# This requires `ES_HOST` and `ES_INDEX` variables to be set so we know where to upload.
#
# Returns exit code 0.
function opensearch_upload() {
    local file="$1"
    local matcher="$2"

    debug "Uploading to OpenSearch: $file"

    if $DRY_RUN; then
        echo shovel.py opensearch --base-url "$ES_HOST" --index "$ES_INDEX" upload --input-file "$file" --matcher-field "$matcher"
    else
        shovel.py opensearch --base-url "$ES_HOST" --index "$ES_INDEX" upload --input-file "$file" --matcher-field "$matcher"
        info "Uploaded to OpenSearch: $file"
    fi
}


# Public: Upload new result to our Results Dashboard.
#
# $1 - Status data file location.
# $2 - Product group to use in Results Dashboard.
# $3 - Product name to use in Results Dashboard.
# $4 - Version of the tested product instance.
#
# It is also possible to use `@field` notation for loading actual value of the parameter from status data file field `.field`.
#
# Returns exit code 0 and prints job IDs, one a line.
function resultsdashboard_upload() {
    local file="$1"
    local group="$2"
    local product="$3"
    local version="$4"

    debug "Uploading to Results Dashboard: $file"

    if $DRY_RUN; then
        echo shovel.py resultsdashboard --base-url $ES_HOST upload --input-file "$file" --group "$group" --product "$product" --test @name --result-id @metadata.env.BUILD_ID --result @result --date @started --link @jobLink --release latest --version "$version"
    else
        shovel.py resultsdashboard --base-url $ES_HOST upload --input-file "$file" --group "$group" --product "$product" --test @name --result-id @metadata.env.BUILD_ID --result @result --date @started --link @jobLink --release latest --version "$version"
        info "Uploaded to Results dashboard: $file"
    fi
}


# Public: TODO.
format_date() {
    date -d "$1" +%FT%TZ --utc
}
