#!/bin/bash

# prints
COLOR_RED='\e[1;31m'
COLOR_GREEN='\e[1;32m'
COLOR_RESET='\e[0m'

function print_example_title {
  local text="$1"
  local dots='...............................................................'
  printf '%s %s  ' "${text}" "${dots:${#text}}"
}

function print_example_success {
    echo -e "${COLOR_GREEN}SUCCESS${COLOR_RESET}"
}

function print_example_fail {
    echo -e "${COLOR_RED}FAIL${COLOR_RESET}"
}

############## context ############## 
test_env_file="./set-env.sh" ; [ -f "$test_env_file" ] && source "$test_env_file"
cd ../example

example_index=0
example_exception=0
example_list="$(ls -1 | grep -v "set-env.sh")"
for example_name in $example_list; do
    print_example_title " · EXAMPLE_${example_index}: $example_name"
    example_result="$(bash $example_name 2>&1 1>/dev/null)"
    if [ $? -ne 0 ]; then
        ((example_exception++))
        print_example_fail
        [ -n "$example_result" ] && echo "$example_result"
    else
        print_example_success
    fi
    ((example_index++))
done

if [ $example_exception -gt 0 ]; then
    echo 
    echo -e "${COLOR_RED}EXCEPTION: ${example_exception}${COLOR_RESET}" >&2
    exit 1
else
    exit 0
fi
