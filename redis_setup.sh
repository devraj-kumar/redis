#!/bin/bash

# Define color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color
YELLOW='\033[1;33m'
BLUE='\033[1;34m'
MAGENTA='\033[1;35m'

# Function to print section headers
print_header() {
    echo -e "${BLUE}====================================${NC}"
    echo -e "${BLUE}$1${NC}"
    echo -e "${BLUE}====================================${NC}"
}

# Function to check if Redis is installed
check_redis_installed() {
    print_header "Checking Redis Installation"
    if command -v redis-server &> /dev/null; then
        echo -e "${GREEN}Redis is already installed.${NC}"
    else
        echo -e "${RED}Redis is not installed.${NC}"
        echo -e "${MAGENTA}Would you like to install Redis from the internet or from a local tarball?${NC}"
        echo -e "${YELLOW}1) Install from internet${NC}"
        echo -e "${YELLOW}2) Install from local tarball${NC}"
        read -p "Enter your choice (1 or 2): " install_choice
        case $install_choice in
            1)
                install_redis
                ;;
            2)
                install_redis_from_tarball
                ;;
            *)
                echo -e "${RED}Invalid option. Exiting installation.${NC}"
                exit 1
                ;;
        esac
    fi
}

# Function to install Redis based on the operating system

install_redis() {
    echo -e "${YELLOW}Installing Redis from the internet...${NC}"
    install_success=false
    if [[ "$OSTYPE" == "linux-gnu"* ]]; then
        if ! curl -s --head http://www.google.com | grep "200 OK" > /dev/null; then
            echo -e "${RED}Internet connection is not enabled. Exiting...${NC}"
            exit 1
        fi
        if command -v apt &> /dev/null; then
            echo -e "${GREEN}Ubuntu system detected.${NC}"
            sudo apt update
            sudo apt install -y redis-server
            if [[ $? -eq 0 ]]; then
                install_success=true
            fi
        elif command -v yum &> /dev/null; then
            echo -e "${GREEN}RHEL system detected.${NC}"
            sudo yum install -y epel-release
            sudo yum install -y redis
            if [[ $? -eq 0 ]]; then
                install_success=true
            fi
        fi
    elif [[ "$OSTYPE" == "darwin"* ]]; then
        echo -e "${GREEN}macOS system detected.${NC}"
        brew install redis
        if [[ $? -eq 0 ]]; then
            install_success=true
        fi
    fi
    if [[ "$install_success" = true ]]; then
        echo -e "${GREEN}Redis installation complete.${NC}"
    else
        echo -e "${RED}Redis installation failed.${NC}"
        exit 1
    fi
}

# Function to install Redis from a local tarball
install_redis_from_tarball() {
    print_header "Installing Redis from Local Tarball"
    initial_dir=$(pwd)
    
    # List available tarballs and suppress error message if none found
    tarballs=($(ls *.tar.gz 2>/dev/null | grep redis))
    if [ ${#tarballs[@]} -eq 0 ]; then
        echo -e "${RED}No Redis tarball found in the current directory. Please place the tarball here and try again.${NC}"
        exit 1
    fi

    # Display the menu for tarball selection
    echo -e "${MAGENTA}Available Redis tarballs:${NC}"
    PS3="Please select the tarball to install: "
    select tarball in "${tarballs[@]}"; do
        if [[ -n "$tarball" && -f "$tarball" ]]; then
            echo -e "${GREEN}You selected: $tarball${NC}"
            break
        else
            echo -e "${RED}Invalid selection. Please try again.${NC}"
        fi
    done

    # Proceed with the installation
    tar -xzf "$tarball" -C /tmp
    cd /tmp/redis-*
    make && sudo make install

    if [ $? -eq 0 ]; then
        echo -e "${GREEN}Redis installed successfully from tarball.${NC}"
    else
        echo -e "${RED}Redis installation failed. Please check the output above for errors.${NC}"
    fi

    cd "$initial_dir"
}

# Function to display the main menu
display_main_menu() {
    print_header "Main Menu"
    echo -e "${YELLOW}1) Configure Instance - Set up a new Redis instance, with options for clustering.${NC}"
    echo -e "${YELLOW}2) Configure Cluster - Establish or modify a Redis cluster configuration.${NC}"
    echo -e "${YELLOW}3) Manage Instances - Start, stop, or restart Redis instances.${NC}"
    echo -e "${YELLOW}4) Backup - Create a backup of the current Redis data.${NC}"
    echo -e "${YELLOW}5) Restore - Restore Redis data from a previous backup.${NC}"
    echo -e "${YELLOW}6) Exit - Exit the script.${NC}"
    echo -e "${MAGENTA}Enter your choice:${NC}"
}

# Function to configure a single Redis instance
configure_redis_instance() {
    print_header "Configuring Redis Instance"
    read -p "Is this instance part of a cluster? (yes/no): " cluster_decision
    while [[ "$cluster_decision" != "yes" && "$cluster_decision" != "no" ]]; do
        echo -e "${RED}Invalid input. Please type 'yes' or 'no'.${NC}"
        read cluster_decision
    done

    cluster_enabled="no"
    if [[ "$cluster_decision" == "yes" ]]; then
        cluster_enabled="yes"
        echo -e "${YELLOW}Cluster mode enabled. You will need to configure the cluster after all instances are set up.${NC}"
    else
        echo -e "${YELLOW}Non-cluster mode enabled.${NC}"
    fi

    read -p "Enter the port for the instance (default 6379): " port
    port=${port:-6379}
    instance_dir="redis_instance_$port"
    mkdir -p $instance_dir
    cd $instance_dir
    while true; do
        read -p "Enter the max memory limit in GB (default 1GB): " max_memory
        max_memory="${max_memory:-1}"
        if [[ $max_memory =~ ^[0-9]+$ ]]; then
            max_memory="${max_memory}GB"
            break
        else
            echo -e "${RED}Invalid input. Please enter an integer value.${NC}"
        fi
    done

    echo -e "${MAGENTA}Select the persistence option:${NC}"
    options=("RDB snapshot (Production)" "AOF (Production)" "In-memory only (no persistence)")
    select opt in "${options[@]}"; do
        case $opt in
            "RDB snapshot (Production)")
                save_params="save 5 1\nsave 3 10\nsave 1 50"
                break
                ;;
            "AOF (Production)")
                appendonly="yes"
                save_params=""
                break
                ;;
            "In-memory only (no persistence)")
                save_params=""
                break
                ;;
            *)
                echo -e "${RED}Invalid option $REPLY. Try again.${NC}"
                ;;
        esac
    done

    # Function to read and validate positive integer input
    while true; do
        read -p "Set max clients (default 10000): " maxclients
        maxclients=${maxclients:-10000}
        if [[ "$maxclients" =~ ^[1-9][0-9]*$ ]]; then
            break
        else
            echo -e "${RED}Invalid input. Please enter a value of 1 or greater.${NC}"
        fi
    done

    while true; do
        read -p "Set timeout in milliseconds (default 6000): " timeout
        timeout=${timeout:-6000}
        if [[ "$timeout" =~ ^[1-9][0-9]*$ ]]; then
            break
        else
            echo -e "${RED}Invalid input. Please enter a value of 1 or greater.${NC}"
        fi
    done

    while true; do
        read -p "Set log level (options: debug, verbose, notice, warning, (default: nothing)): " loglevel
        if [[ -z "$loglevel" ]]; then
            loglevel="nothing"
            break
        elif [[ "$loglevel" =~ ^(debug|verbose|notice|warning)$ ]]; then
            break
        else
            echo -e "${RED}Invalid log level. Please enter one of the following: debug, verbose, notice, warning, nothing.${NC}"
        fi
    done

    if [[ -n "$loglevel" && "$loglevel" != "NOTHING" && "$loglevel" != "nothing" ]]; then
        read -p "Set log file path (leave empty for default: redis.log): " logfile
        logfile=${logfile:-redis.log}
    fi

    while true; do
        read -s -p "Enter password for Redis instance: " redis_password
        echo  # move to a new line
        if [[ -z "$redis_password" ]]; then
            echo -e "${RED}Password cannot be empty. Please enter a valid password.${NC}"
        else
            break
        fi
    done

    config_file="redis-instance-$port.conf"

    # Create configuration file
    echo "port $port" > $config_file
    echo "maxmemory $max_memory" >> $config_file
    if [[ -n "$appendonly" ]]; then
        echo "appendonly $appendonly" >> $config_file
    fi
    if [[ -n "$save_params" ]]; then
        echo -e "$save_params" >> $config_file
    fi
    echo "requirepass $redis_password" >> $config_file
    echo "maxclients $maxclients" >> $config_file
    echo "timeout $timeout" >> $config_file
    if [[ -n "$loglevel" && "$loglevel" != "NOTHING" && "$loglevel" != "nothing" ]]; then
        echo "loglevel $loglevel" >> $config_file
        echo "logfile $logfile" >> $config_file
    fi
    echo "daemonize yes" >> $config_file
    echo "cluster-enabled $cluster_enabled" >> $config_file
    if [[ "$cluster_enabled" == "yes" ]]; then
        echo "cluster-config-file nodes-$port.conf" >> $config_file
    fi
    echo "cluster-node-timeout 5000" >> $config_file
    echo "cluster-allow-reads-when-down yes" >> $config_file
    echo "cluster-require-full-coverage no" >> $config_file
    echo "cluster-slave-validity-factor  0" >> $config_file

    if pgrep -f "redis-server.*$port" > /dev/null; then
        echo -e "${YELLOW}Stopping existing Redis instance on port $port...${NC}"
        redis-cli -p $port shutdown
    fi

    echo -e "${YELLOW}Starting Redis instance with configuration file: $config_file${NC}"
    redis-server $config_file
    cd ../
    echo -e "${GREEN}Redis instance configured and started on port $port with settings from $config_file.${NC}"
}

# Function to configure Redis cluster
configure_redis_cluster() {
    print_header "Configuring Redis Cluster"
    cluster_password=""
    if [ -z "$cluster_password" ]; then
        while [ -z "$cluster_password" ]; do
            read -s -p "Enter the password for Redis cluster nodes (or type 'exit' to quit): " cluster_password
            echo
            if [[ "$cluster_password" == "exit" ]]; then
                echo -e "${YELLOW}Exiting configuration...${NC}"
                return 0
            elif [ -z "$cluster_password" ]; then
                echo -e "${RED}Password is required to configure a Redis cluster. Exiting...${NC}"
                return 1
            fi
        done
    fi

    echo -e "${YELLOW}Configuring Redis cluster with existing nodes...${NC}"

    echo -e "${MAGENTA}Enter the IP and port of each node in the cluster (e.g., 127.0.0.1:7000). Type 'done' when finished. Type 'exit' to quit.${NC}"
    nodes=()
    while true; do
        read -p "Enter node IP:port or 'done'/'exit': " node
        if [[ "$node" == "done" ]]; then
            break
        elif [[ "$node" == "exit" ]]; then
            echo -e "${YELLOW}Exiting configuration...${NC}"
            return 0
        fi
        nodes+=("$node")
    done

    if [ ${#nodes[@]} -eq 0 ]; then
        echo -e "${RED}No nodes entered. Exiting...${NC}"
        return 1
    fi

    echo -e "${GREEN}Nodes configured for the cluster: ${nodes[@]}${NC}"

    echo -e "${YELLOW}Creating Redis cluster with the selected nodes...${NC}"
    if yes yes | redis-cli --cluster create "${nodes[@]}" --cluster-replicas 1 --cluster-yes -a "$cluster_password"; then
        echo -e "${GREEN}Cluster creation complete.${NC}"
    else
        echo -e "${RED}Cluster creation failed. Please check the configuration and try again.${NC}"
        configure_redis_cluster
    fi
}

# Function to manage Redis instances
manage_redis_instances() {
    print_header "Managing Redis Instances"
    while true; do
        echo -e "${YELLOW}1) Shutdown an instance - Stop a running Redis instance.${NC}"
        echo -e "${YELLOW}2) Start/Restart an instance - Start a stopped Redis instance.${NC}"
        echo -e "${YELLOW}3) Check active Redis instance - See which Redis instances are currently running.${NC}"
        echo -e "${YELLOW}4) Read configuration file - View the settings of a specific Redis instance.${NC}"
        echo -e "${YELLOW}5) Exit management menu${NC}"
        echo -e "${MAGENTA}Choose an option for instance management:${NC}"
        read choice
        case $choice in
            1)
                echo -e "${YELLOW}Option 1: Shutdown an instance${NC}"
                echo -e "${MAGENTA}This will stop a running Redis instance, making it inactive until restarted.${NC}"
                while true; do
                    read -p "Enter the port of the instance to shutdown (or type 'exit' to leave): " port
                    if [[ $port == "exit" ]]; then
                        break
                    elif [[ $port =~ ^[0-9]+$ ]]; then
                        shutdown_redis_instance $port
                        break
                    else
                        echo -e "${RED}Invalid input. Please enter a valid port number or type 'exit' to leave.${NC}"
                    fi
                done
                ;;
            2)
                echo -e "${YELLOW}Option 2: Start/Restart an instance${NC}"
                echo -e "${MAGENTA}This will start or restart a Redis instance, making it active and ready to use.${NC}"
                while true; do
                    read -p "Enter the port of the instance to start (or type 'exit' to leave): " port
                    if [[ $port == "exit" ]]; then
                        break
                    elif [[ $port =~ ^[0-9]+$ ]]; then
                        start_redis_instance $port
                        break
                    else
                        echo -e "${RED}Invalid input. Please enter a valid port number or type 'exit' to leave.${NC}"
                    fi
                done
                ;;
            3)
                echo -e "${YELLOW}Option 3: Check active Redis instance${NC}"
                echo -e "${MAGENTA}This will show which Redis instances are currently running on your system.${NC}"
                check_redis_status
                ;;
            4)
                echo -e "${YELLOW}Option 4: Read configuration file${NC}"
                echo -e "${MAGENTA}This will display the settings of a specific Redis instance, such as its port, memory limit, and other configurations.${NC}"
                while true; do
                    read -p "Enter the port of the instance to read configuration file (or type 'exit' to leave): " port
                    if [[ $port == "exit" ]]; then
                        break
                    elif [[ $port =~ ^[0-9]+$ ]]; then
                        read_redis_conf $port
                        break
                    else
                        echo -e "${RED}Invalid input. Please enter a valid port number or type 'exit' to leave.${NC}"
                    fi
                done
                ;;
            5)
                echo -e "${YELLOW}Exiting instance management.${NC}"
                break
                ;;
            *)
                echo -e "${RED}Invalid option $REPLY. Try again.${NC}"
                ;;
        esac
    done
}

# Function to read and display the Redis configuration
read_redis_conf() {
    port=$1
    config_file="redis_instance_$port/redis-instance-$port.conf"
    if [ -f "$config_file" ]; then
        echo -e "${YELLOW}Displaying configuration for Redis instance on port $port:${NC}"
        echo -e "${MAGENTA}----------------------------------------${NC}"
        echo -e "${YELLOW}Detailed Configuration:${NC}"
        persistence_method="No persistence"
        if grep -q "appendonly yes" $config_file; then
            persistence_method="AOF (Append Only File)"
        elif grep -q "save " $config_file; then
            persistence_method="RDB snapshot"
        fi
        echo -e "${GREEN}Persistence Method: $persistence_method${NC}"
        
        port_value=$(grep "^port " $config_file | awk '{print $2}')
        maxmemory_value=$(grep "^maxmemory " $config_file | awk '{print $2}')
        maxclients_value=$(grep "^maxclients " $config_file | awk '{print $2}')
        timeout_value=$(grep "^timeout " $config_file | awk '{print $2}')
        loglevel_value=$(grep "^loglevel " $config_file | awk '{print $2}')
        logfile_value=$(grep "^logfile " $config_file | awk '{print $2}')
        cluster_enabled_value=$(grep "^cluster-enabled " $config_file | awk '{print $2}')
        cluster_node_timeout=$(grep "^cluster-node-timeout " $config_file | awk '{print $2}')
        cluster_allow_reads_when_down=$(grep "^cluster-allow-reads-when-down " $config_file | awk '{print $2}')
        cluster_require_full_coverage=$(grep "^cluster-require-full-coverage " $config_file | awk '{print $2}')
        cluster_slave_validity_factor=$(grep "^cluster-slave-validity-factor " $config_file | awk '{print $2}')

        echo -e "${GREEN}Port: ${port_value:-default (6379)}${NC}"
        echo -e "${GREEN}Max Memory: ${maxmemory_value:-default (1GB)}${NC}"
        echo -e "${GREEN}Max Clients: ${maxclients_value:-default (10000)}${NC}"
        echo -e "${GREEN}Timeout: ${timeout_value:-default (6000 milliseconds)}${NC}"
        echo -e "${GREEN}Log Level: ${loglevel_value:-nothing}${NC}"
        echo -e "${GREEN}Log File: ${logfile_value:-''}${NC}"
        echo -e "${GREEN}Cluster Enabled: ${cluster_enabled_value:-no}${NC}"
        echo -e "${GREEN}Cluster Node Timeout: ${cluster_node_timeout:-default (5000 milliseconds)}${NC}"
        echo -e "${GREEN}Cluster Allow Reads When Down: ${cluster_allow_reads_when_down:-default (no)}${NC}"
        echo -e "${GREEN}Cluster Require Full Coverage: ${cluster_require_full_coverage:-default (yes)}${NC}"
        echo -e "${GREEN}Cluster Slave Validity Factor: ${cluster_slave_validity_factor:-default (100)}${NC}"
    else
        echo -e "${RED}Configuration file for port $port not found.${NC}"
    fi
}

# Function to check and display the status of a Redis instance
check_redis_status() {
    echo -e "${YELLOW}Checking Redis status on all ports...${NC}"

    redis_processes=$(ps aux | grep '[r]edis-server')

    if [[ -z "$redis_processes" ]]; then
        echo -e "${RED}No Redis server instances are running.${NC}"
        return
    fi

    echo -e "${GREEN}Redis server instances running on the following ports:${NC}"
    echo "$redis_processes" | while read -r line; do
        if [[ "$line" =~ \*:[0-9]+ ]]; then
            port=$(echo "$line" | grep -o '\*:[0-9]*' | cut -d':' -f2)
            echo -e "${GREEN}Redis server is running on port $port${NC}"
        elif [[ "$line" =~ 127.0.0.1:[0-9]+ ]]; then
            port=$(echo "$line" | grep -o '127.0.0.1:[0-9]*' | cut -d':' -f2)
            echo -e "${GREEN}Redis server is running on port $port${NC}"
        fi
    done
}

# Function to list running Redis instances
list_running_instances() {
    print_header "Listing Running Redis Instances"
    pgrep -fl redis-server | while read -r line; do
        pid=$(echo "$line" | awk '{print $1}')
        port=$(echo "$line" | grep -oP 'port \K[0-9]+')
        cluster=$(echo "$line" | grep 'cluster-enabled' &>/dev/null && echo "yes" || echo "no")
        echo -e "${GREEN}PID: $pid - Port: $port - Cluster: $cluster${NC}"
    done
}

# Function to shutdown a Redis instance
shutdown_redis_instance() {
    port=$1
    read -sp "Enter the password for Redis on port $port (if any): " redis_password
    echo  # move to a new line for tidy output

    if redis-cli -p $port ping > /dev/null 2>&1; then
        if [[ -n "$redis_password" ]]; then
            if redis-cli -p $port -a "$redis_password" shutdown; then
                echo -e "${YELLOW}Shutdown command sent to Redis instance on port $port.${NC}"
            else
                echo -e "${RED}Failed to send shutdown command to Redis instance on port $port. Please check the port and password.${NC}"
            fi
        else
            if redis-cli -p $port shutdown; then
                echo -e "${YELLOW}Shutdown command sent to Redis instance on port $port.${NC}"
            else
                echo -e "${RED}Failed to send shutdown command to Redis instance on port $port. Please check the port.${NC}"
            fi
        fi

        sleep 2
        if ! redis-cli -p $port ping > /dev/null 2>&1; then
            echo -e "${GREEN}Redis instance on port $port has been successfully shut down.${NC}"
        else
            echo -e "${RED}Redis instance on port $port is still running. Shutdown failed.${NC}"
        fi
    else
        echo -e "${RED}No active Redis instance found on port $port. Please check the port.${NC}"
    fi
}

# Function to start a Redis instance
start_redis_instance() {
    port=$1
    config_file="redis-instance-$port.conf"
    dir="redis_instance_$port"

    if [ ! -d "$dir" ]; then
        echo -e "${RED}Error: Port $port does not exist.${NC}"
        return 1
    fi

    cd "$dir" || { echo -e "${RED}Error: Failed to locate $port${NC}"; return 1; }
    echo -e "${GREEN}Starting Redis instance on port $port with configuration file $config_file...${NC}"
    redis-server $config_file
    cd ../ || { echo -e "${RED}Error: Failed to return to the previous directory${NC}"; return 1; }
}

# Function to create backup of Redis data
backup_redis_data() {
    print_header "Creating Backup"

    while true; do
        read -p "Enter the port of the Redis instance to backup: " port
        if [[ -z "$port" ]]; then
            echo -e "${RED}Port must be provided. Please try again.${NC}"
        elif ! [[ "$port" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}Invalid port number. Please enter a valid number.${NC}"
        else
            read -sp "Enter the password for this Redis instance (if applicable, else press enter): " redis_password
            echo

            REDIS_CLI_CMD="redis-cli -p $port"
            if [ ! -z "$redis_password" ]; then
                REDIS_CLI_CMD="$REDIS_CLI_CMD -a $redis_password"
            fi

            if [[ $($REDIS_CLI_CMD ping) == "PONG" ]]; then
                echo -e "${GREEN}Successfully connected to Redis on port $port.${NC}"
                break
            else
                echo -e "${RED}(error) Could not connect to Redis on port $port. Check if Redis is running and the password is correct.${NC}"
            fi
        fi
    done

    persistence_method=$($REDIS_CLI_CMD config get appendonly | tail -n 1)
    data_dir=$($REDIS_CLI_CMD config get dir | tail -n 1)
    backup_dir="redis-backup"
    timestamp=$(date +"%Y%m%d-%H%M%S")
    mkdir -p $backup_dir

    if [ "$persistence_method" == "yes" ]; then
        aof_file_name="appendonlydir"
        aof_file_path="$data_dir/$aof_file_name"
        backup_file="$backup_dir/redis-backup-aof-$port-$timestamp.tar"
        tar -cvf $backup_file -C $data_dir $aof_file_name
    else
        rdb_file_name=$($REDIS_CLI_CMD config get dbfilename | tail -n 1)
        rdb_file_path="$data_dir/$rdb_file_name"
        backup_file="$backup_dir/redis-backup-rdb-$port-$timestamp.tar"
        $REDIS_CLI_CMD save
        tar -cvf $backup_file -C $data_dir $rdb_file_name
    fi

    echo -e "${GREEN}Backup created at ${backup_file}${NC}"
}

# Function to restore Redis data from a backup
restore_redis_data() {
    print_header "Restoring Data"
    echo -e "${MAGENTA}Available backups:${NC}"

    backup_files=($(ls redis-backup/))
    if [ ${#backup_files[@]} -eq 0 ]; then
        echo -e "${RED}No backup files found in redis-backup directory.${NC}"
        exit 1
    fi

    PS3="Please select the backup file to restore: "
    select backup_file in "${backup_files[@]}"; do
        if [[ -n "$backup_file" && -f "redis-backup/$backup_file" ]]; then
            echo -e "${GREEN}You selected: $backup_file${NC}"
            break
        else
            echo -e "${RED}Invalid selection. Please try again.${NC}"
        fi
    done

    while true; do
        read -p "Enter the location of  config file directory that you want to restore: " redis_data_dir
        if [[ -d "$redis_data_dir" ]]; then
            break
        else
            echo -e "${RED}Invalid directory. Please try again.${NC}"
        fi
    done

    while true; do
        read -p "Enter the port of the Redis instance to restore: " port
        if [[ -z "$port" ]]; then
            echo -e "${RED}Port must be provided. Please try again.${NC}"
        elif ! [[ "$port" =~ ^[0-9]+$ ]]; then
            echo -e "${RED}Invalid port number. Please enter a valid number.${NC}"
        elif ! lsof -i:$port > /dev/null; then
            if [[ -f "$redis_data_dir/redis-instance-$port.conf" ]]; then
                break
            else
                echo -e "${RED}Config file for port $port not found in directory $redis_data_dir. Please try again.${NC}"
                exit 1
            fi
        else
            echo -e "${RED}Redis instance is running on port $port. Please stop it before proceeding.${NC}"
        fi
    done

    config_file="$redis_data_dir/redis-instance-$port.conf"
    rdb_file="rdb"
    aof_dir="aof"

    if [[ "$backup_file" == *"$rdb"* ]]; then
        if grep -q "appendonly yes" "$config_file"; then
            echo -e "${RED}Cannot restore RDB backup to AOF configured instance. Exiting...${NC}"
            exit 1
        fi
    elif [[ "$backup_file" == *"$aof_dir"* ]]; then
        if ! grep -q "appendonly yes" "$config_file"; then
            echo -e "${RED}Cannot restore AOF backup to RDB configured instance. Exiting...${NC}"
            exit 1
        fi
    fi

    echo -e "${YELLOW}Restoring from backup...${NC}"
    if tar -xvf "redis-backup/$backup_file" -C "$redis_data_dir"; then
        cd $redis_data_dir
        if redis-server redis-instance-$port.conf; then
           echo -e "${GREEN}Restore complete. Restarting Redis instance on port $port...${NC}"
           exit 1
        else
            echo -e "${RED}Failed to restart Redis instance on port $port. Please check the configuration.${NC}"
            exit 1
        fi
        cd ../
    else
        echo -e "${RED}Failed to restore from backup. Please check the backup file and directory permissions.${NC}"
        exit 1
    fi
}

# Main script execution
if ! check_redis_installed; then
    echo -e "${RED}Redis installation check failed or installation aborted.${NC}"
    exit 1
fi

while true; do
    display_main_menu
    read opt
    if [[ "$opt" =~ ^[1-6]$ ]]; then
        case $opt in
            1)
                configure_redis_instance
                ;;
            2)
                configure_redis_cluster
                ;;
            3)
                manage_redis_instances
                ;;
            4)
                backup_redis_data
                ;;
            5)
                restore_redis_data
                ;;
            6)
                echo -e "${GREEN}Exiting... Thank you for using the Redis Management Tool.${NC}"
                exit 0
                ;;
        esac
    else
        echo -e "${RED}Invalid option. Please enter a number between 1 and 6.${NC}"
    fi
done

