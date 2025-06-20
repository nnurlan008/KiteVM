#!/bin/bash
# this script assumes that you already have memcached server running:
# sudo cgexec -g memory:/memctl /usr/bin/memcached -m 102400 -p 11211 -t 30 -o hashpower=29,no_hashexpand -c 32768 -b 32768 -u memcache

max_resident=$1
# mem_ratio=(10 15 20 25 30 35 40 45 50 55 60 65 70 75 80 85 90 95 100)
mem_ratio=(120 75 50 25 12) #25 50 75 100)

# cd /users/Nurlan/GraphOne/build || exit 1

OUTFILE="/users/Nurlan/results_memcached_remote_1"

if [[ ! -f "$OUTFILE" ]]; then
    echo "# Memcached results for local/remote memory test" > "$OUTFILE"
    echo "" >> "$OUTFILE"
fi

for i in "${mem_ratio[@]}"
do
    OUTPUT3=$(/users/Nurlan/syscalls 6 2>&1 )
    sleep 5
    echo "Clearing page cache..."
    sudo sh -c 'echo 1 > /proc/sys/vm/drop_caches'
    sleep 5
    sudo sh -c 'echo 2 > /proc/sys/vm/drop_caches'
    sleep 5
    sudo sh -c 'echo 3 > /proc/sys/vm/drop_caches'
    sleep 5

    local_mem=$(((max_resident * $i) / 100))
    echo "Setting up cgroup with memory limit: $local_mem MB ($i%)"

    CGROUP_DIR="/sys/fs/cgroup/memory/memctl"
    limit_bytes=$((local_mem * 1024 * 1024))

    # Set cgroup memory limit (as bytes)
    if ! echo "$limit_bytes" | sudo tee "$CGROUP_DIR/memory.limit_in_bytes" > /dev/null; then
        echo "Failed to set memory limit to $local_mem MB, skipping..."
        continue
    fi

    sleep 5

    # # export PATH="/usr/local/maven/bin:$PATH"
    # YCSB=/users/Nurlan/YCSB/bin/ycsb
    # COMMAND="$YCSB run memcached -P workloads/workloada -p memcached.hosts=127.0.0.1:11211 -p threadcount=12"

    # # Execute the command using cgexec and capture verbose time output
    # echo "env PATH=/usr/local/maven/bin:$PATH /usr/bin/time -v ./bin/ycsb run memcached -P workloads/workloada -p "memcached.hosts=127.0.0.1:11211" -p threadcount=12"
    # echo "Running memcached under cgroup 'memctl' with memory limit $local_mem MB ($i%)"
    # # OUTPUT=$(env PATH=/usr/local/maven/bin:$PATH /usr/bin/time -v /usr/bin/time -v ./bin/ycsb run memcached -P workloads/workloada -p "memcached.hosts=127.0.0.1:11211" -p threadcount=12 2>&1)
    # OUTPUT=$(env PATH=/usr/local/maven/bin:$PATH /usr/bin/time -v /users/Nurlan/YCSB/bin/ycsb run memcached -P workloads/workloada -p "memcached.hosts=127.0.0.1:11211" -p threadcount=12 2>&1)

    export PATH=/usr/local/maven/bin:$PATH
    cd /users/Nurlan/YCSB || exit 1

    echo "Running YCSB memcached benchmark..."
    OUTPUT=$( /usr/bin/time -v ./bin/ycsb run memcached -P workloads/workloada -p "memcached.hosts=127.0.0.1:11211" -p threadcount=12 2>&1 )
    echo "$OUTPUT"

    runtime=$(echo "$OUTPUT" | grep "Elapsed (wall clock) time" | awk -F': ' '{print $2}' | xargs)
    throughput=$(echo "$OUTPUT" | grep "\[OVERALL\], Throughput" | awk -F, '{print $3}' | xargs)

    read_ops=$(echo "$OUTPUT" | grep "\[READ\], Operations" | awk -F, '{print $3}' | xargs)
    write_ops=$(echo "$OUTPUT" | grep "\[UPDATE\], Operations" | awk -F, '{print $3}' | xargs)

    read_avg=$(echo "$OUTPUT" | grep "\[READ\], AverageLatency" | awk -F, '{printf "%.1f", $3}' | xargs)
    read_95=$(echo "$OUTPUT" | grep "\[READ\], 95thPercentileLatency" | awk -F, '{print $3}' | xargs)
    read_99=$(echo "$OUTPUT" | grep "\[READ\], 99thPercentileLatency" | awk -F, '{print $3}' | xargs)

    write_avg=$(echo "$OUTPUT" | grep "\[UPDATE\], AverageLatency" | awk -F, '{printf "%.1f", $3}' | xargs)
    write_95=$(echo "$OUTPUT" | grep "\[UPDATE\], 95thPercentileLatency" | awk -F, '{print $3}' | xargs)
    write_99=$(echo "$OUTPUT" | grep "\[UPDATE\], 99thPercentileLatency" | awk -F, '{print $3}' | xargs)

    max_latency_u=$(echo "$OUTPUT" | grep "\[UPDATE\], MaxLatency" | awk -F, '{print $3}' | xargs)
    max_latency_r=$(echo "$OUTPUT" | grep "\[READ\], MaxLatency" | awk -F, '{print $3}' | xargs)

    echo "Runtime:                     $runtime"
    echo "Throughput:                  $throughput ops/sec"
    echo "Reads:                       $read_ops"
    echo "Writes:                      $write_ops"
    echo "READ Latency Avg/95th/99th:  $read_avg μs / $read_95 μs / $read_99 μs"
    echo "WRITE Latency Avg/95th/99th: $write_avg μs / $write_95 μs / $write_99 μs"
    echo "Max Latency (write):         ~$max_latency_u μs"
    echo "Max Latency (write):         ~$max_latency_r μs"

    runtime_sec=$(echo "$runtime" | awk -F: '{ if (NF==3) print $1*3600 + $2*60 + $3; else print $1*60 + $2 }')

    # Format into the output block
    {
    echo "; ----------------------------------------------------------------------------------"
    echo "; Local memory of ${i}%, $((100 - i))% remote memory"
    printf "RunTime\t\t%-20s (≈%d seconds)\t%s\n" "$runtime" "$runtime_sec" "Good length — reflects memory pressure"
    printf "Throughput\t%-20s ops/sec\t%s\n" "$throughput" "High throughput"
    printf "Reads\t\t~%s\t\tBalanced workload\n" "$read_ops"
    printf "Updates\t\t~%s\t\t1:1 read/write ratio\n" "$write_ops"
    echo

    printf "\t\t#   Avg\t   95th\t  99th\t Comment\n"
    printf "READ\t\t%sμs\t %sμs\t %sμs\tGood for in-memory reads\n" "$read_avg" "$read_95" "$read_99"
    printf "WRITE\t\t%sμs\t %sμs\t %sμs\tSlightly higher due to memory alloc\n" "$write_avg" "$write_95" "$write_99"
    printf "Max Latency\tUp to   ~%s μs\n" "$max_latency"

    sleep 5

    # Optional: Swap stats if ./syscalls was generated
    OUTPUT2=$(/users/Nurlan/syscalls 1 2>&1 )
    on_demand=$(echo "$OUTPUT2" | grep "On-demand Swap-ins" | awk -F: '{print $2}' | xargs)
    prefetch=$(echo "$OUTPUT2" | grep "Prefetch Swap-ins" | awk -F: '{print $2}' | xargs)
    hits=$(echo "$OUTPUT2" | grep "Hits on Prefetch" | awk -F: '{print $2}' | xargs)

    echo "On-demand Swap-ins: $on_demand"
    echo "Prefetch Swap-ins:  $prefetch"
    echo "Hits on Prefetch:   $hits"

    echo
    } >> "$OUTFILE"

    sleep 10 # Give some time before the next run


done



# memcached commands: 1.4GB
    # ./bin/ycsb load memcached -s -P workloads/workloada -p "memcached.hosts=127.0.0.1:11211" # -p threadcount=12
    # sudo cgexec -g memory:/memctl env PATH=/usr/local/maven/bin:$PATH /usr/bin/time -v ./bin/ycsb run memcached -P workloads/workloada -p "memcached.hosts=127.0.0.1:11211"

    # Nurlan@node2:~/YCSB$ sudo cgexec -g memory:/memctl --sticky taskset -c 1-12 /usr/bin/memcached -m 102400 -p 11211 -t 12 -o hashpower=29,no_hashexpand,no_lru_crawler,no_lru_maintainer -c 32768 -b 32768 -u memcache
    # sudo cgexec -g memory:/memctl env PATH=/usr/local/maven/bin:$PATH /usr/bin/time -v ./bin/ycsb run memcached -P workloads/workloada -p "memcached.hosts=127.0.0.1:11211"

    # working ones:
    # Nurlan@node2:~/YCSB$ sudo cgexec -g memory:/memctl /usr/bin/memcached -m 102400 -p 11211 -t 30 -o hashpower=29,no_hashexpand -c 32768 -b 32768 -u memcache
    # load: don't forget to 'cd YCSB'
    # /usr/bin/time -v ./bin/ycsb load memcached -s -P workloads/workloada -p memcached.hosts=127.0.0.1:11211 -p threadcount=12 -p debug=true
    # run:
    # env PATH=/usr/local/maven/bin:$PATH /usr/bin/time -v ./bin/ycsb run memcached -P workloads/workloada -p "memcached.hosts=127.0.0.1:11211" -p threadcount=12
    # watch for max Resident set size in the server:
    # grep VmRSS /proc/$(pidof memcached)/status