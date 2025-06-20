#!/bin/bash


max_resident=$1
mem_ratio=(12 25 50 75 110)

# cd /users/Nurlan/GraphOne/build || exit 1



for i in "${mem_ratio[@]}"
do
    local_mem=$(((max_resident * $i) / 100))
    echo "Setting up cgroup with memory limit: $local_mem MB ($i%)"

    CGROUP_DIR="/sys/fs/cgroup/memory/memctl"
    limit_bytes=$((local_mem * 1024 * 1024))

    # Set cgroup memory limit (as bytes)
    if ! echo "$limit_bytes" | sudo tee "$CGROUP_DIR/memory.limit_in_bytes" > /dev/null; then
        echo "Failed to set memory limit to $local_mem GB, skipping..."
        continue
    fi

    # # Prepare command and arguments for uk 2002 graph Graphone
    # GRAPHONE_BIN=/users/Nurlan/GraphOne/build/graphone32
    # INPUT_DIR=/users/Nurlan/graphs/uk-2002/clean/
    # COMMAND="$GRAPHONE_BIN -i $INPUT_DIR -j 0 -v 18520486"

    # # Prepare command and arguments for sk 2005 graph Graphone
    # GRAPHONE_BIN=/users/Nurlan/GraphOne/build/graphone32
    # INPUT_DIR=/users/Nurlan/graphs/sk-2005/clean/
    # COMMAND="$GRAPHONE_BIN -i $INPUT_DIR -j 0 -d 1 -v 50636154"

    # # Prepare command and arguments for sk 2005 graph Aspen bfs 47 GB
    # GRAPHONE_BIN=/users/Nurlan/aspen/code/run_static_algorithm
    # INPUT_DIR=/users/Nurlan/graphs/com-Friendster/com-Friendster_aspen.mtx
    # COMMAND="numactl -i all $GRAPHONE_BIN -t BFS -src 1 -s -f $INPUT_DIR"

    # Prepare command and arguments for uk 2005 graph graphone bfs/pr 11GB
    GRAPHONE_BIN=/users/Nurlan/GraphOne/build/graphone32
    INPUT_DIR=/users/Nurlan/graphs/uk-2002/clean/
    COMMAND="$GRAPHONE_BIN -i $INPUT_DIR -j 0 -v 18520486 -d 1 -z 10"

    # # Prepare command and arguments for sk 2005 graph graphone bfs 75GB
    # GRAPHONE_BIN=/users/Nurlan/GraphOne/build/graphone32
    # INPUT_DIR=/users/Nurlan/graphs/com-Friendster/clean/
    # COMMAND="$GRAPHONE_BIN -i $INPUT_DIR -j 0 -v 65608366 -d 0 -z 101"

    # # Prepare command and arguments for uk 2005 graph Aspen bfs 47 GB
    # GRAPHONE_BIN=/users/Nurlan/aspen/code/run_static_algorithm
    # INPUT_DIR=/users/Nurlan/graphs/uk-2002/uk-2002_aspen
    # COMMAND="numactl -i all $GRAPHONE_BIN -t BFS -src 10 -f $INPUT_DIR"

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

    # Execute the command using cgexec and capture verbose time output
    echo "sudo cgexec -g memory:/memctl /usr/bin/time -v $COMMAND 2>&1"
    echo "Running command under cgroup 'memctl'..."
    OUTPUT=$(sudo cgexec -g memory:/memctl /usr/bin/time -v $COMMAND 2>&1)

    # Print expected format
    echo "        Command being timed: \"$COMMAND\""
    echo "$OUTPUT" | grep "Elapsed (wall clock) time" | awk -F': ' '{print $2}'


done