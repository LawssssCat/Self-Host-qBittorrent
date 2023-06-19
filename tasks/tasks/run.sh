#1/bin/bash

# env
export COLOR_RED='\e[1;31m'
export COLOR_GREEN='\e[1;32m'
export COLOR_RESET='\e[0m'

# args
task_path="$1"
if [ ! -x "$task_path" ]; then 
    echo "[$task_path] [${COLOR_RED}EXCEPTION${COLOR_RESET}] script unfound." >&2
    exit 1
fi

# run
task_result="$($task_path 2>&1)"
task_return="$?"
case "$task_return" in
    0)
        echo -e "[$task_path] [${COLOR_GREEN}SUCCESS${COLOR_RESET}] $task_result"
        ;;
    222)
        # skip
        ;;
    *)
        echo -e "[$task_path] [${COLOR_RED}EXCEPTION${COLOR_RESET}] $task_result" >&2
        ;;
esac