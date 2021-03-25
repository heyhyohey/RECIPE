#!/bin/zsh

if [ $# -ne 1 ]; then
	echo "Usage: ./exp.sh [mode]\nmode 0: Load libvmmalloc (pmdk)\nmode 1: No library load (dram)\nmode 2: NUMA pmem node bind (devdax)"
	exit 1
fi

LIB_PATH="/root/radix-tree/RECIPE-origin/pmdk/src/nondebug/libvmmalloc.so.1"
SCRIPT_PATH="/root/radix-tree/RECIPE/scripts/set_vmmalloc.sh"
COUNT_ARRAY=(10000 50000 100000 500000 1000000 5000000 10000000 50000000)
INSTRUCTION_ARRAY=(clflush_fence clflushopt_fence clwb_fence store_fence ntstore_fence clflush clflushopt clwb store ntstore)

source $SCRIPT_PATH

if [ $1 -eq 0 ]; then
	MODE="dram"
elif [ $1 -eq 1 ]; then
	MODE="pmdk"
else
	MODE="devdax"
fi

for INSTRUCTION in ${INSTRUCTION_ARRAY[@]}; do
	echo $INSTRUCTION
	for COUNT in ${COUNT_ARRAY[@]}; do
		INST_TH=0
		INST_ET=0
		LU_TH=0
		LU_ET=0
		for i in {1..5}; do
			if [ $1 -eq 0 ]; then
				TH1=`LD_PRELOAD="$LIB_PATH" ./build_${INSTRUCTION}/example $COUNT 7 | sed -n 3p | awk -F',' '{ print $3 }' | awk '{ print $1 }'`
				ET1=`LD_PRELOAD="$LIB_PATH" ./build_${INSTRUCTION}/example $COUNT 7 | sed -n 4p | awk -F',' '{ print $3 }' | awk '{ print $1 }'`
				TH2=`LD_PRELOAD="$LIB_PATH" ./build_${INSTRUCTION}/example $COUNT 7 | sed -n 5p | awk -F',' '{ print $3 }' | awk '{ print $1 }'`
				ET2=`LD_PRELOAD="$LIB_PATH" ./build_${INSTRUCTION}/example $COUNT 7 | sed -n 6p | awk -F',' '{ print $3 }' | awk '{ print $1 }'`
			elif [ $1 -eq 1 ]; then
				TH1=`./build_${INSTRUCTION}/example $COUNT 7 | sed -n 3p | awk -F',' '{ print $3 }' | awk '{ print $1 }'`
				ET1=`./build_${INSTRUCTION}/example $COUNT 7 | sed -n 4p | awk -F',' '{ print $3 }' | awk '{ print $1 }'`
				TH2=`./build_${INSTRUCTION}/example $COUNT 7 | sed -n 5p | awk -F',' '{ print $3 }' | awk '{ print $1 }'`
				ET2=`./build_${INSTRUCTION}/example $COUNT 7 | sed -n 6p | awk -F',' '{ print $3 }' | awk '{ print $1 }'`
			else
				TH1=`numactl --membind=1 ./build_${INSTRUCTION}/example $COUNT 7 | sed -n 3p | awk -F',' '{ print $3 }' | awk '{ print $1 }'`
				ET1=`numactl --membind=1 ./build_${INSTRUCTION}/example $COUNT 7 | sed -n 4p | awk -F',' '{ print $3 }' | awk '{ print $1 }'`
				TH2=`numactl --membind=1 ./build_${INSTRUCTION}/example $COUNT 7 | sed -n 5p | awk -F',' '{ print $3 }' | awk '{ print $1 }'`
				ET2=`numactl --membind=1 ./build_${INSTRUCTION}/example $COUNT 7 | sed -n 6p | awk -F',' '{ print $3 }' | awk '{ print $1 }'`
			fi
			INST_TH=$(bc <<< "$INST_TH + $TH1")
			INST_ET=$(bc <<< "$INST_ET + $ET1")
			LU_TH=$(bc <<< "$LU_TH + $TH2")
			LU_ET=$(bc <<< "$LU_ET + $ET2")
		done 
		INST_TH=$(bc -l <<< "scale=7;$INST_TH / 5")
		INST_ET=$(bc -l <<< "scale=7;$INST_ET / 5")
		LU_TH=$(bc -l <<< "scale=7;$LU_TH / 5")
		LU_ET=$(bc -l <<< "scale=7;$LU_ET / 5")
		echo $INST_TH
		echo $INST_TH >> result/${MODE}_insert_throughput_${INSTRUCTION}.txt
		echo $INST_ET >> result/${MODE}_insert_elapsed_time_${INSTRUCTION}.txt
		echo $LU_TH >> result/${MODE}_lookup_throughput_${INSTRUCTION}.txt
		echo $LU_ET >> result/${MODE}_lookup_elapsed_time_${INSTRUCTION}.txt
	done
done
