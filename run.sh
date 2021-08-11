#!/bin/bash -

cur_dir=$PWD
cur_path=$(readlink -e $0)
cur_workdir=${cur_path%/*}
cur_filename=$(basename "$cur_path")

cmd_params=""

#######################################################
cmd_temp_file="/tmp/.$(md5sum "$cur_path" | awk '{print $1}')"

trim() {
    trimmed=$1
    trimmed=${trimmed%% }
    trimmed=${trimmed## }

    echo "$trimmed"
}

select_yes_or_no() {
    read -r -p "Are you sure continue? [Y/n] " input
    case $input in
    [yY][eE][sS] | [yY])
        echo "yes"
        ;;

    [nN][oO] | [nN])
        echo "no"
        ;;
    *)
        echo "Invalid input: $input"
        ;;
    esac
}

parse_cmd_params() {
    if [ -e "$cmd_temp_file" ]; then
        return
    fi

    (
        all_cmd=$(grep "^cmd_.*()" "$cur_path")
        OLD_IFS=$IFS
        IFS=$'\n'
        for cmd in $all_cmd; do
            pat='^cmd_(.*)\(\)(.*)'
            [[ $cmd =~ $pat ]] # $pat must be unquoted
            #  echo "${BASH_REMATCH[0]}" ' -> ' "${BASH_REMATCH[1]}"
            name="${BASH_REMATCH[1]}"
            # name=$(echo "$cmd" | sed -n 's/^cmd_\(.*\)()\(.*\)/\1/p')
            comment=""
            alias=""
            if [[ "$cmd" == *"#"* ]]; then
                comment=${cmd##*#}
                if [[ "$comment" == *"->"* ]]; then
                    alias=${comment%%->*}
                    comment=${comment##*->}
                fi
            fi
            echo -e "$(trim "$name")@$(trim "$alias")@$(trim "$comment")"
        done
        IFS=$OLD_IFS
    ) >"$cmd_temp_file"
}

fuzzy_finder_cmd() { #fuzzy finder
    cmd=$1
    regex_ret=()
    while read -r line; do
        pat='(.*)@(.*)@(.*)'
        [[ $line =~ $pat ]] # $pat must be unquoted
        name="${BASH_REMATCH[1]}"
        alias="${BASH_REMATCH[2]}"
        comment="${BASH_REMATCH[3]}"
        if [ "$name" = "$cmd" ]; then
            # echo 'equal name' $name
            regex_ret+=($name)
        fi
        if [ "$alias" = "$cmd" ]; then
            # echo 'equal alias' $alias
            regex_ret+=($name)
        fi
    done <"$cmd_temp_file"

    regex_num=${#regex_ret[@]}
    if [ "$regex_num" = 1 ]; then
        echo "${regex_ret[@]}"
        return 0
    fi
    if [ "$regex_num" -gt 1 ]; then
        echo "find more command"
        for regex in "${regex_ret[@]}"; do
            echo -e "  $regex"
        done
        return 1
    fi

    regex_ret=()
    regex_param='*'$(echo "$cmd" | sed 's/./&\*/g')
    while read -r line; do
        pat='(.*)@(.*)@(.*)'
        [[ $line =~ $pat ]] # $pat must be unquoted
        name="${BASH_REMATCH[1]}"
        alias="${BASH_REMATCH[2]}"
        comment="${BASH_REMATCH[3]}"
        if [[ $name == $regex_param ]]; then
            # echo 'regex name' $name
            regex_ret+=($name)
            continue
        fi
        if [[ $alias == $regex_param ]]; then
            # echo 'regex alias' $alias
            regex_ret+=($name)
            continue
        fi
    done <"$cmd_temp_file"

    regex_num=${#regex_ret[@]}
    if [ "$regex_num" = 1 ]; then
        echo "${regex_ret[@]}"
        return 0
    fi
    if [ "$regex_num" -gt 1 ]; then
        echo "find more command:"
        for regex in "${regex_ret[@]}"; do
            echo -e "  $regex"
        done
        return 1
    fi
}

run_main() { # process command
    parse_cmd_params
    if [ -z "$1" ]; then
        cmd_help
        return
    fi

    cmd_param=($@)
    need_wait='no'
    if echo "${cmd_param[@]}" | grep -n -w -E -- '-p|pause' >/dev/null; then
        need_wait='yes'
        cmd_param=(${cmd_param[@]/-p/})
        cmd_param=(${cmd_param[@]/pause/})
    fi
    cmd_name=${cmd_param[0]}
    unset cmd_param[0]

    # echo "$cmd_param" "need wait" "$need_wait"
    _cmd=$(fuzzy_finder_cmd "$cmd_name")
    if [ $? != 0 ]; then
        echo "err: $_cmd"
        return
    fi
    if [ -n "$_cmd" ]; then
        echo "run cmd_${_cmd} ..."
        if [ "$need_wait" = 'yes' ]; then
            ret=$(select_yes_or_no)
            if [ "$ret" != 'yes' ]; then
                echo "exit now, $ret"
                exit 1
            fi
        fi
        cmd_"$_cmd" "${cmd_param[@]}"
    else
        echo "not found command $cmd_name"
    fi
}

cmd_help() { # Show all command.
    tmp_file=$(mktemp)
    (
        long_cmd=$(cat "$cmd_temp_file" | awk -F@ '{print $1}' | awk '{ print length, $0 }' | sort -n -s | tail -1 | cut -d" " -f2-)
        while read -r line; do
            pat='(.*)@(.*)@(.*)'
            [[ $line =~ $pat ]] # $pat must be unquoted
            name="${BASH_REMATCH[1]}"
            alias="${BASH_REMATCH[2]}"
            comment="${BASH_REMATCH[3]}"
            if [ -n "$alias" ]; then
                name="$name($alias)"
            fi
            printf "  %-${#long_cmd}s - %s\n" "${name}" "${comment}"
        done <"$cmd_temp_file"
    ) >"$tmp_file"
    line_num=$(wc -l <"$tmp_file")
    if [ "$line_num" -gt $LINES ]; then
        sort "$tmp_file" | less -r
    else
        sort "$tmp_file"
    fi
    rm -f "$tmp_file"
}

#######################################################

cmd_test_1() { # t1-> test 1
    echo "cmd_test_1"
}

cmd_test_2() { #t2-> test 2
    echo "cmd_test_2"
}

#######################################################

# start
run_main $@
