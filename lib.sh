


function log() {
    local log_level=$1
    local message=$2
    local timestamp=$(date +"%Y-%m-%d %H:%M:%S")

    local log_levels=("DEBUG" "INFO" "WARNING" "ERROR")

    # if [[ " ${log_levels[@]} " =~ " ${log_level} " ]]; then
    #     # Determine if the message should be printed based on log level
    #     if [[ "${log_levels[@]/$log_level/}" == "${log_levels[@]/#*/}" ]]; then
    #         # If the log level is greater than or equal to the threshold log level, print the message
    #         if [[ "${log_levels[@]/$log_level/}" == "${log_levels[@]/$LOG_LEVEL/}" ]]; then
    #             printf "[%s] [%s] %s\n" "${timestamp}" "${log_level}" "${message}"
    #         fi
    #     fi
    # else
    #     # If an invalid log level is provided, print a warning
    #     echo "[$timestamp] [WARNING] Invalid log level: $log_level"
    #     printf "[%s] [%s] %s\n" "${timestamp}" "WARNING" "Invalid log level: ${log_level}"
    # fi

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

