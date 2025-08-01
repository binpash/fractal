#!/bin/bash

export DISH_TOP=$(realpath $(dirname "$0")/../..)
export PASH_TOP=$(realpath $DISH_TOP/pash)
export TIMEFORMAT=%R
cd "$(realpath $(dirname "$0"))"

# After initial cd line insert parser
############################################################
MODE=faultless
SIZE_FLAG="--full"
for arg in "$@"; do
  case "$arg" in
    --small|--full) SIZE_FLAG="$arg";;
    --faultless) MODE=faultless;;
    --microbench) MODE=microbench;;
    --faulty) MODE=faulty;;
  esac
done
if [[ $MODE == faulty ]]; then
  echo "[nlp] Fault injection not supported for NLP suite"; exit 1;
fi
############################################################
# Replace old small check
if [[ $SIZE_FLAG == "--small" ]]; then
    echo "Using small input"
    export ENTRIES=10
    export IN="/nlp/pg-small"
else
    echo "Using default input"
    export ENTRIES=100
    export IN="/nlp/pg"
fi

names_scripts=(
    "1syllable_words;6_4"
    "2syllable_words;6_5"
    "4letter_words;6_2"
    "bigrams_appear_twice;8.2_2"
    "bigrams;4_3"
    "compare_exodus_genesis;8.3_3"
    "count_consonant_seq;7_2"
    "count_morphs;7_1"
    "count_trigrams;4_3b"
    "count_vowel_seq;2_2"
    "count_words;1_1"
    "find_anagrams;8.3_2"
    "merge_upper;2_1"
    "sort;3_1"
    "sort_words_by_folding;3_2"
    "sort_words_by_num_of_syllables;8_1"
    "sort_words_by_rhyming;3_3"
    # "trigram_rec;6_1" # was initially commented out
    "uppercase_by_token;6_1_1"
    "uppercase_by_type;6_1_2"
    "verses_2om_3om_2instances;6_7"
    "vowel_sequencies_gr_1K;8.2_1"
    "words_no_vowels;6_3"
)

mkdir -p "outputs"
all_res_file="./outputs/nlp.res"
> $all_res_file

# time_file stores the time taken for each script
# mode_res_file stores the time taken and the script name for every script in a mode (e.g. bash, pash, dish, fish)
# all_res_file stores the time taken for each script for every script run, making it easy to copy and paste into the spreadsheet
nlp() {
    mkdir -p "outputs/$1"
    mode_res_file="./outputs/$1/nlp.res"
    > $mode_res_file

    echo executing nlp $1 $(date) | tee -a $mode_res_file $all_res_file

    for name_script in ${names_scripts[@]}
    do
        IFS=";" read -r -a name_script_parsed <<< "${name_script}"
        name="${name_script_parsed[0]}"
        script="${name_script_parsed[1]}"
        script_file="./scripts/$script.sh"
        # input for all nlp scripts is ./inputs/pg, which is already default for each script
        # output_file contains "done" when run successfully. The real outputs are under output_dir/
        output_dir="./outputs/$1/$script/"
        output_file="./outputs/$1/$script.out"
        time_file="./outputs/$1/$script.time"
        log_file="./outputs/$1/$script.log"
        hash_file="./outputs/$1/$script.hash"

        # Print input size
        hdfs dfs -du -h -s "/nlp/pg"

        if [[ "$1" == "bash" ]]; then
            (time bash $script_file $output_dir > $output_file ) 2> $time_file
        else
            params="$2"
            if [[ $2 == *"--distributed_exec"* ]]; then
                params="$2 --script_name $script_file"
            fi

            (time $PASH_TOP/pa.sh $params --log_file $log_file $script_file $output_dir > $output_file) 2> $time_file

            if [[ $2 == *"--kill"* ]]; then
                sleep 10
                python3 "$DISH_TOP/evaluation/notify_worker.py" resurrect
            fi

            sleep 10
        fi

        # For every file in output_dir, generate a hash and delete the file
        for file in "$output_dir"/*
        do
            # Extract the filename without the directory
            filename=$(basename "$file")

            # Generate SHA-256 hash and delete output file
            shasum -a 256 "$file" | awk '{ print $1 }' > "$output_dir/$filename.hash"
            rm "$file"
        done

        # Generate SHA-256 hash and no need to delete output file as it should only contain "done"
        shasum -a 256 "$output_file" | awk '{ print $1 }' > "$hash_file"

        cat "${time_file}" >> $all_res_file
        echo "$script_file $(cat "$time_file")" | tee -a $mode_res_file

        rm "$output_file"

        # Record timing for plotting
        t=$(cat "$time_file")
        benchmark="NLP"
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
    done
}

# None of the scripts in NLP,
# MediaConv, or LogAnalysis can be implemented in AHS as
# they perform processing in loops, the iterations of which de-
# pend on the files in a statically indeterminable directory (see
# Fig. 5) and are therefore not expressible in AHS. We attempted
# to replace the body of the loop with an AHS invocation but
# the startup overhead ended up dwarfing the execution time by
# a factor of ten on average. (source: nsdi 2023 DiSh paper)
# adjust the debug flag as required
d=1

# Replace old microbench detection: remove old loop and use MODE check
if [[ $MODE == microbench ]]; then
  export SUITE_CSV_PATH="$(pwd)/outputs/time_microbench.csv"
fi

case "$MODE" in
  faultless)
    nlp "bash"
    nlp "dish"          "--width 8 --r_split -d $d --distributed_exec --parallel_pipelines --parallel_pipelines_limit 24"
    nlp "dynamic"       "--width 8 --r_split -d $d --distributed_exec --parallel_pipelines --parallel_pipelines_limit 24 --ft dynamic";;
  microbench)
    nlp "dynamic"       "--width 8 --r_split -d $d --distributed_exec --parallel_pipelines --parallel_pipelines_limit 24 --ft dynamic"
    nlp "dynamic-on"    "--width 8 --r_split -d $d --distributed_exec --parallel_pipelines --parallel_pipelines_limit 24 --ft dynamic --dynamic_switch_force on"
    nlp "dynamic-off"   "--width 8 --r_split -d $d --distributed_exec --parallel_pipelines --parallel_pipelines_limit 24 --ft dynamic --dynamic_switch_force off";;
esac
