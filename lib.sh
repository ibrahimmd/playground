


function log() {
    local log_level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    local log_levels=("DEBUG" "INFO" "WARNING" "ERROR")

    # TODO: write logic to only log messages if above default log level

    printf "[%s] %-10s %s\n" "${timestamp}" "[${log_level}]" "${message}"
    [ $log_level == "ERROR" ] && exit 1
}

function cmd_exists() {
    local cmd=$1

    # we are not checking what linux distro we are running on
    # we are not sure if we have root access
    # cheap man's way to check if a command exists in PATH
    type -P $cmd > /dev/null

    # return 0 if command exists
    echo "$?"
}
