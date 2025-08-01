#!/bin/bash

export DISH_TOP=$(realpath $(dirname "$0")/../../..)
export PASH_TOP=$(realpath $DISH_TOP/pash)
export TIMEFORMAT=%R
cd "$(realpath $(dirname "$0"))"

############################################################
# Flag parsing common across suites
MODE=faultless
SIZE_FLAG="--full"
for arg in "$@"; do
  case "$arg" in
    --small|--full) SIZE_FLAG="$arg";;
    --faultless) MODE=faultless;;
    --faulty) MODE=faulty;;
    --microbench) MODE=microbench;;
  esac
done
############################################################

if [[ $SIZE_FLAG == "--small" ]]; then
    echo "Using small input"
    input_file="/covid-mts/in_small.csv"
else
    echo "Using default input"
    input_file="/covid-mts/in.csv"
fi

# Per-suite timing CSV
export SUITE_CSV_PATH="$(pwd)/../outputs/time.csv"
mkdir -p "$(dirname "$SUITE_CSV_PATH")"

mkdir -p "outputs"
all_res_file="./outputs/covid-mts.res"
> $all_res_file

# time_file stores the time taken for each script
# mode_res_file stores the time taken and the script name for every script in a mode (e.g. bash, pash, dish, fish)
# all_res_file stores the time taken for each script for every script run, making it easy to copy and paste into the spreadsheet
covid-mts() {
    mkdir -p "outputs/$1"
    mode_res_file="./outputs/$1/covid-mts.res"
    > $mode_res_file

    echo executing covid-mts $1 $(date) | tee -a $mode_res_file $all_res_file

    for number in `seq 4` ## initial: FIXME 5.sh is not working yet
    do
        script="${number}"
        script_file="./scripts/$script.sh"
        output_dir="./outputs/$1/$script/"
        output_file="./outputs/$1/$script.out"
        time_file="./outputs/$1/$script.time"
        log_file="./outputs/$1/$script.log"
        hash_file="./outputs/$1/$script.hash"

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
        benchmark="Analytics"
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

covid-mts_hadoopstreaming() {
    # used by run_all.sh, adjust as required
    jarpath="/opt/hadoop-3.4.0/share/hadoop/tools/lib/hadoop-streaming-3.4.0.jar"
    outputs_dir="/outputs/hadoop-streaming/covid-mts"

    hdfs dfs -rm -r "$outputs_dir"
    hdfs dfs -mkdir -p "$outputs_dir"
    mkdir -p "outputs/hadoop"
    cd scripts/hadoop-streaming
    mode_res_file="../../outputs/hadoop/covid-mts.res"
    > $mode_res_file
    all_res_file="../../outputs/covid-mts.res"

    echo executing covid-mts hadoop $(date) | tee -a $mode_res_file $all_res_file
    while IFS= read -r line; do
        name=$(cut -d "#" -f2- <<< "$line")
        name=$(sed "s/ //g" <<< $name)

        # output_file="../../outputs/hadoop/$name.out"
        time_file="../../outputs/hadoop/$name.time"
        log_file="../../outputs/hadoop/$name.log"

        (time eval $line &> $log_file) 2> $time_file

        # Record timing for plotting
        t=$(cat "$time_file")
        benchmark="Analytics"
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

# For microbench timing separation
if [[ $MODE == microbench ]]; then
  export SUITE_CSV_PATH="$(pwd)/outputs/time_microbench.csv"
fi

case "$MODE" in
  faultless)
    covid-mts "bash"
    covid-mts "dish"           "--width 8 --r_split -d $d --distributed_exec"
    covid-mts "dynamic"        "--width 8 --r_split -d $d --distributed_exec --ft dynamic";;

  faulty)
    covid-mts "dynamic"        "--width 8 --r_split -d $d --distributed_exec --ft dynamic"
    covid-mts "dynamic-m"      "--width 8 --r_split -d $d --distributed_exec --ft dynamic --kill merger"
    covid-mts "dynamic-r"      "--width 8 --r_split -d $d --distributed_exec --ft dynamic --kill regular";;

  microbench)
    covid-mts "dynamic-m"      "--width 8 --r_split -d $d --distributed_exec --ft dynamic --kill merger"
    covid-mts "dynamic-on-m"   "--width 8 --r_split -d $d --distributed_exec --ft dynamic --dynamic_switch_force on --kill merger"
    covid-mts "dynamic-off-m"  "--width 8 --r_split -d $d --distributed_exec --ft dynamic --dynamic_switch_force off --kill merger";;
esac

# Hadoop streaming only faultless
if [[ $MODE == faultless ]]; then
  covid-mts_hadoopstreaming $SIZE_FLAG
fi