#!/bin/bash

export DISH_TOP=$(realpath $(dirname "$0")/../..)
export PASH_TOP=$(realpath $DISH_TOP/pash)
export TIMEFORMAT=%R
cd "$(realpath $(dirname "$0"))"

# Per-suite timing CSV
export SUITE_CSV_PATH="$(pwd)/outputs/time.csv"
mkdir -p "$(dirname "$SUITE_CSV_PATH")"

if [[ "$@" == *"--small"* ]]; then
    scripts_inputs=(
        "nfa-regex;100M"
        "sort;300M"
        "top-n;300M"
        "wf;300M"
        "spell;300M"
        "diff;300M"
        "bi-grams;300M"
        "set-diff;300M"
        "sort-sort;300M"
        "shortest-scripts;all_cmdsx300"
    )
else
    scripts_inputs=(
        "nfa-regex;1G"
        "sort;3G"
        "top-n;3G"
        "wf;3G"
        "spell;3G"
        "diff;1G"
        "bi-grams;3G"
        "set-diff;3G"
        "sort-sort;3G"
        "shortest-scripts;all_cmdsx1000"
    )
fi

mkdir -p "outputs"
all_res_file="./outputs/classics.res"
> $all_res_file

# time_file stores the time taken for each script
# mode_res_file stores the time taken and the script name for every script in a mode (e.g. bash, pash, dish, fish)
# all_res_file stores the time taken for each script for every script run, making it easy to copy and paste into the spreadsheet
classics() {
    mkdir -p "outputs/$1"
    mode_res_file="./outputs/$1/classics.res"
    > $mode_res_file

    echo executing classics $1 $(date) | tee -a $mode_res_file $all_res_file

    for script_input in ${scripts_inputs[@]}
    do
        IFS=";" read -r -a parsed <<< "${script_input}"
        script_file="./scripts/${parsed[0]}.sh"
        input_file="/classics/${parsed[1]}.txt"
        output_file="./outputs/$1/${parsed[0]}.out"
        time_file="./outputs/$1/${parsed[0]}.time"
        log_file="./outputs/$1/${parsed[0]}.log"
        hash_file="./outputs/$1/${parsed[0]}.hash"

        # Print input size
        hdfs dfs -du -h -s "$input_file"

        if [[ "$1" == "bash" ]]; then
            (time bash $script_file $input_file > $output_file) 2> $time_file
        else
            params="$2"
            if [[ $2 == *"--distributed_exec"* ]]; then
                params="$2 --script_name $script_file"
            fi

            (time $PASH_TOP/pa.sh $params --log_file $log_file $script_file $input_file > $output_file) 2> $time_file

            if [[ $2 == *"--kill"* ]]; then
                sleep 10
                python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect
            fi

            sleep 10
        fi

        # Generate SHA-256 hash and delete output file
        shasum -a 256 "$output_file" | awk '{ print $1 }' > "$hash_file"
        rm "$output_file"

        # Record timing for plotting
        t=$(cat "$time_file")
        benchmark="Classics"
        system="$1"
        # Detect nodes (fallback 4)
        nodes=$(hdfs dfsadmin -report 2>/dev/null | awk '/Datanodes available/{print $4}' | cut -d'(' -f1)
        nodes=${nodes:-4}
        fault_mode="none"; fault_pct=0
        if [[ $2 == *"--kill merger"* ]]; then fault_mode="merger"; fault_pct=50; fi
        if [[ $2 == *"--kill regular"* ]]; then fault_mode="regular"; fault_pct=50; fi
        persistence="dynamic"
        if [[ $2 == *"--dynamic_switch_force on"* ]]; then persistence="enabled"; fi
        if [[ $2 == *"--dynamic_switch_force off"* ]]; then persistence="disabled"; fi
        $DISH_TOP/evaluation/record_time.sh "$benchmark" "$(basename $script_file)" "$system" "$persistence" "$t"

        cat "${time_file}" >> $all_res_file
        echo "$script_file $(cat "$time_file")" | tee -a $mode_res_file
    done
}

classics_hadoopstreaming() {
    # used by run_all.sh, adjust as required
    jarpath="/opt/hadoop-3.4.0/share/hadoop/tools/lib/hadoop-streaming-3.4.0.jar"
    basepath="/classics"
    outputs_dir="/outputs/hadoop-streaming/classics"

    hdfs dfs -rm -r "$outputs_dir"
    hdfs dfs -mkdir -p "$outputs_dir"
    mkdir -p "outputs/hadoop"
    source ./scripts/bi-gram.aux.sh
    source ./scripts/hadoop-streaming/to_shell_cmd.sh
    cd scripts/hadoop-streaming
    mode_res_file="../../outputs/hadoop/classics.res"
    > $mode_res_file
    all_res_file="../../outputs/classics.res"

    echo executing classics hadoop $(date) | tee -a $mode_res_file $all_res_file

    for script_input in ${scripts_inputs[@]}
    do
        IFS=";" read -r -a parsed <<< "${script_input}"
        script_name="${parsed[0]}.sh"
        input_file="${parsed[1]}.txt"
        line=$(get_hadoopstreaming_cmd $script_name)
        if [ $? -ne 0 ]; then
            echo "Error generating Hadoop Streaming command for $script_name"
            exit 1
        fi
        # output_file="../../outputs/hadoop/$name.out"
        time_file="../../outputs/hadoop/${parsed[0]}.time"
        log_file="../../outputs/hadoop/${parsed[0]}.log"

        (time eval $line &> $log_file) 2> $time_file

        # Record timing for plotting
        t=$(cat "$time_file")
        benchmark="Classics"
        system="ahs"
        # Detect nodes (fallback 4)
        nodes=$(hdfs dfsadmin -report 2>/dev/null | awk '/Datanodes available/{print $4}' | cut -d'(' -f1)
        nodes=${nodes:-4}
        persistence=""
        $DISH_TOP/evaluation/record_time.sh "$benchmark" "$(basename $script_name)" "$system" "$persistence" "$t"

        cat "${time_file}" >> $all_res_file
        echo "./scripts/hadoop-streaming/${parsed[0]}.sh $(cat "$time_file")" | tee -a $mode_res_file
    done

    cd "../.."
}

# adjust the debug flag as required
d=1

# classics "bash"
# classics "dish"        "--width 8 --r_split -d $d --distributed_exec"

classics "dynamic"     "--width 8 --r_split -d $d --distributed_exec --ft dynamic"
classics "dynamic-m"   "--width 8 --r_split -d $d --distributed_exec --ft dynamic --kill merger"
classics "dynamic-r"   "--width 8 --r_split -d $d --distributed_exec --ft dynamic --kill regular"

# # For microbenchmarks
# classics "dynamic-on-m"     "--width 8 --r_split -d $d --distributed_exec --ft dynamic --dynamic_switch_force on --kill merger"
# classics "dynamic-off-m"    "--width 8 --r_split -d $d --distributed_exec --ft dynamic --dynamic_switch_force off --kill merger"

