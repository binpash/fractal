#!/bin/bash

cd "$(realpath $(dirname "$0"))"
IN="inputs"
mkdir -p inputs
cd inputs

hdfs dfs -mkdir /media-conv

if [[ "$@" == *"--small"* ]]; then
    # Check if the wav_small directory does not exist
    if [ ! -d "wav_small" ]; then
        WAV_DATA_FILES=5
        wget -q https://atlas-group.cs.brown.edu/data/wav.zip -O wav_small.zip
        mkdir wav_small
        unzip -q wav_small.zip -d wav_small
        cd wav_small/wav
        for f in *.wav; do
            for (( i = 0; i <= $WAV_DATA_FILES; i++ )); do
                # echo copying to $f$i.wav
                cp "$f" "$f$i.wav"
            done
        done
        cd -
        hdfs dfs -put wav_small/wav /media-conv/wav_small
        echo "WAV_small Generated"
    fi

    # Check if the small/jpg directory doesn't exist and handle small/jpg.zip
    if [ ! -d "jpg_small" ]; then
        JPG_DATA_LINK=https://atlas-group.cs.brown.edu/data/small/jpg.zip
        wget -q $JPG_DATA_LINK -O jpg_small.zip
        unzip -q jpg_small.zip -d jpg_small
        IMG_DATA_FILES=100
        mkdir -p jpg_small/jpg_small
        i=0
        for file in jpg_small/jpg/*; do
            filename=$(basename "$file")
            cp "$file" "jpg_small/jpg_small/${filename}"
            ((i++))
            if [ $i -ge $IMG_DATA_FILES ]; then
                break
            fi
        done
        hdfs dfs -put jpg_small/jpg_small /media-conv/jpg_small
        echo "JPG_small Generated"
        rm -rf jpg_small.zip
    fi
else
    if [ ! -d "wav" ]; then
        WAV_DATA_FILES=120
        mkdir wav_full
        wget -q https://atlas-group.cs.brown.edu/data/wav.zip -O wav.zip
        unzip -q wav.zip -d wav_full
        cd wav_full/wav
        for f in *.wav; do
            for (( i = 0; i <= $WAV_DATA_FILES; i++ )); do
                # echo copying to $f$i.wav
                cp "$f" "$f$i.wav"
            done
        done
        cd -
        hdfs dfs -put wav_full/wav /media-conv/wav
        echo "WAV Generated"
    fi

    # Check if the directories don't exist and handle full/jpg.zip
    if [ ! -d "jpg" ]; then
        JPG_DATA_LINK=https://atlas-group.cs.brown.edu/data/full/jpg.zip
        wget -q $JPG_DATA_LINK -O jpg_full.zip
        unzip -q jpg_full.zip -d jpg_full
        hdfs dfs -put jpg_full/jpg /media-conv/jpg
        echo "JPG Generated"
        rm -rf jpg_full.zip
    fi
fi
