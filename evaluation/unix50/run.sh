#!/bin/bash

export DISH_TOP=$(realpath $(dirname "$0")/../..)
export PASH_TOP=$(realpath $DISH_TOP/pash)
export TIMEFORMAT=%R
cd "$(realpath $(dirname "$0"))"

# Insert after cd line
############################################################
MODE=faultless
SIZE_FLAG="--full"
for arg in "$@"; do
  case "$arg" in
    --small|--full) SIZE_FLAG="$arg";;
    --faultless) MODE=faultless;;
    --faulty|--microbench) MODE=unsupported;;
  esac
done
if [[ $MODE == unsupported ]]; then echo "[unix50] only faultless runs supported"; exit 1; fi
############################################################

# Per-suite timing CSV
export SUITE_CSV_PATH="$(pwd)/outputs/time.csv"
mkdir -p "$(dirname "$SUITE_CSV_PATH")"

if [[ $SIZE_FLAG == "--small" ]]; then
    scripts_inputs=(
        "1;1_300M"
        "2;1_300M"
        "3;1_300M"
        "4;1_300M"
        "5;2_300M"
        "6;3_300M"
        "7;4_300M"
        "8;4_300M"
        "9;4_300M"
        "10;4_300M"
        "11;4_300M"
        "12;4_300M"
        "13;5_300M"
        "14;6_300M"
        "15;7_300M"
        "16;7_300M"
        "17;7_300M"
        "18;8_300M"
        "19;8_300M"
        "20;8_300M"
        "21;8_300M"
        # "22;8_300M"
        "23;9.1_300M"
        "24;9.2_300M"
        "25;9.3_300M"
        "26;9.4_300M"
        # "27;9.5_300M"
        "28;9.6_300M"
        "29;9.7_300M"
        "30;9.8_300M"
        "31;9.9_300M"
        "32;10_300M"
        "33;10_300M"
        "34;10_300M"
        "35;11_300M"
        "36;11_300M"
    )
else
        scripts_inputs=(
        "1;1_10G"
        "2;1_10G"
        "3;1_10G"
        "4;1_10G"
        "5;2_10G"
        "6;3_10G"
        "7;4_10G"
        "8;4_10G"
        "9;4_10G"
        "10;4_10G"
        "11;4_10G"
        "12;4_10G"
        "13;5_10G"
        "14;6_10G"
        "15;7_10G"
        "16;7_10G"
        "17;7_10G"
        "18;8_10G"
        "19;8_10G"
        "20;8_10G"
        "21;8_10G"
        # "22;8_10G"
        "23;9.1_10G"
        "24;9.2_10G"
        "25;9.3_10G"
        "26;9.4_10G"
        # "27;9.5_10G"
        "28;9.6_10G"
        "29;9.7_10G"
        "30;9.8_10G"
        "31;9.9_10G"
        "32;10_10G"
        "33;10_10G"
        "34;10_10G"
        "35;11_10G"
        "36;11_10G"
    )
fi

mkdir -p "outputs"
all_res_file="./outputs/unix50.res"
> $all_res_file

# time_file stores the time taken for each script
# mode_res_file stores the time taken and the script name for every script in a mode (e.g. bash, pash, dish, fish)
# all_res_file stores the time taken for each script for every script run, making it easy to copy and paste into the spreadsheet
unix50() {
    mkdir -p "outputs/$1"
    mode_res_file="./outputs/$1/unix50.res"
    > $mode_res_file

    echo executing unix50 $1 $(date) | tee -a $mode_res_file $all_res_file

    for script_input in ${scripts_inputs[@]}
    do
        IFS=";" read -r -a parsed <<< "${script_input}"
        script_file="./scripts/${parsed[0]}.sh"
        input_file="/unix50/${parsed[1]}.txt"
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
        benchmark="Unix50"
        system="$1"
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

unix50_hadoopstreaming() {
    # used by run_all.sh, adjust as required
    jarpath="/opt/hadoop-3.4.0/share/hadoop/tools/lib/hadoop-streaming-3.4.0.jar"
    basepath="/unix50"
    outputs_dir="/outputs/hadoop-streaming/unix50"
    if [[ "$@" == *"--small"* ]]; then
        size="300M"
    else
        size="10G"
    fi

    hdfs dfs -rm -r "$outputs_dir"
    hdfs dfs -mkdir -p "$outputs_dir"
    mkdir -p "outputs/hadoop"
    cd scripts/hadoop-streaming
    mode_res_file="../../outputs/hadoop/unix50.res"
    > $mode_res_file
    all_res_file="../../outputs/unix50.res"

    echo executing unix50 hadoop $(date) | tee -a $mode_res_file $all_res_file
    while IFS= read -r line; do
        if [[ ! $line =~ ^hadoop ]]; then
            continue
        fi

        name=$(cut -d "#" -f2- <<< "$line")
        name=$(sed "s/ //g" <<< $name)

        # output_file="../../outputs/hadoop/$name.out"
        time_file="../../outputs/hadoop/$name.time"
        log_file="../../outputs/hadoop/$name.log"

        (time eval $line &> $log_file) 2> $time_file

        # Record timing for plotting
        t=$(cat "$time_file")
        benchmark="Unix50"
        system="ahs"
        # Detect nodes (fallback 4)
        nodes=$(hdfs dfsadmin -report 2>/dev/null | awk '/Datanodes available/{print $4}' | cut -d'(' -f1)
        nodes=${nodes:-4}
        persistence=""
        $DISH_TOP/evaluation/record_time.sh "$benchmark" "${name}.sh" "$system" "$persistence" "$t"

        cat "${time_file}" >> $all_res_file
        echo "./scripts/hadoop-streaming/$name.sh $(cat "$time_file")" | tee -a $mode_res_file
    done <"run_all.sh"

    cd "../.."
}

# adjust the debug flag as required
d=1

unix50 "bash"
unix50 "dynamic"       "--width 8 --r_split -d $d --distributed_exec --ft dynamic"

unix50 "dish"          "--width 8 --r_split -d $d --distributed_exec"
unix50_hadoopstreaming $@