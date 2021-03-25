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

for INSTRUCTION in ${INSTRUCTION_ARRAY[@]}; do
	for COUNT in ${COUNT_ARRAY[@]}; do
		echo $COUNT
		if [ $1 -eq 0 ]; then
			LD_PRELOAD="$LIB_PATH" ./build_${INSTRUCTION}/example $COUNT 7 | sed -n 3p | awk -F',' '{ print $3 }' | awk '{ print $1 }' >> result/pmdk_insert_throughput_${INSTRUCTION}.txt
			LD_PRELOAD="$LIB_PATH" ./build_${INSTRUCTION}/example $COUNT 7 | sed -n 4p | awk -F',' '{ print $3 }' | awk '{ print $1 }' >> result/pmdk_insert_elapsed_time_${INSTRUCTION}.txt
			LD_PRELOAD="$LIB_PATH" ./build_${INSTRUCTION}/example $COUNT 7 | sed -n 5p | awk -F',' '{ print $3 }' | awk '{ print $1 }' >> result/pmdk_lookup_throughput_${INSTRUCTION}.txt
			LD_PRELOAD="$LIB_PATH" ./build_${INSTRUCTION}/example $COUNT 7 | sed -n 6p | awk -F',' '{ print $3 }' | awk '{ print $1 }' >> result/pmdk_lookup_elapsed_time_${INSTRUCTION}.txt
		elif [ $1 -eq 1 ]; then
			./build_${INSTRUCTION}/example $COUNT 7 | sed -n 3p | awk -F',' '{ print $3 }' | awk '{ print $1 }' >> result/dram_insert_throughput_${INSTRUCTION}.txt
			./build_${INSTRUCTION}/example $COUNT 7 | sed -n 4p | awk -F',' '{ print $3 }' | awk '{ print $1 }' >> result/dram_insert_elapsed_time_${INSTRUCTION}.txt
			./build_${INSTRUCTION}/example $COUNT 7 | sed -n 5p | awk -F',' '{ print $3 }' | awk '{ print $1 }' >> result/dram_lookup_throughput_${INSTRUCTION}.txt
			./build_${INSTRUCTION}/example $COUNT 7 | sed -n 6p | awk -F',' '{ print $3 }' | awk '{ print $1 }' >> result/dram_lookup_elapsed_time_${INSTRUCTION}.txt
		else
			numactl --membind=1 ./build_${INSTRUCTION}/example $COUNT 7 | sed -n 3p | awk -F',' '{ print $3 }' | awk '{ print $1 }' >> result/devdax_insert_throughput_${INSTRUCTION}.txt
			numactl --membind=1 ./build_${INSTRUCTION}/example $COUNT 7 | sed -n 4p | awk -F',' '{ print $3 }' | awk '{ print $1 }' >> result/devdax_insert_elapsed_time_${INSTRUCTION}.txt
			numactl --membind=1 ./build_${INSTRUCTION}/example $COUNT 7 | sed -n 5p | awk -F',' '{ print $3 }' | awk '{ print $1 }' >> result/devdax_lookup_throughput_${INSTRUCTION}.txt
			numactl --membind=1 ./build_${INSTRUCTION}/example $COUNT 7 | sed -n 6p | awk -F',' '{ print $3 }' | awk '{ print $1 }' >> result/devdax_lookup_elapsed_tiem_${INSTRUCTION}.txt
		fi
	done
done
