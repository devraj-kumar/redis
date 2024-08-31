# redis
A CLI tool to manage handles everything from checking installations to configuring Redis instances, setting up clusters, managing instances, and even performing backups and restores—all through an interactive and user-friendly interface

Overview
This script provides a comprehensive tool for managing Redis installations and configurations on Linux and macOS systems. It includes functionality for checking if Redis is installed, installing Redis either from the internet or a local tarball, configuring Redis instances, setting up Redis clusters, managing Redis instances, and performing backup and restore operations.

Features
Redis Installation: Automatically checks if Redis is installed and offers options to install it from the internet or a local tarball.
Instance Configuration: Allows users to configure Redis instances with options for clustering, memory limits, persistence methods, and other settings.
Cluster Configuration: Provides a step-by-step process to set up or modify a Redis cluster.
Instance Management: Enables starting, stopping, and restarting of Redis instances, as well as viewing their status and reading their configuration files.
Backup and Restore: Supports creating backups of Redis data and restoring data from those backups.
Script Components
1. Color Codes
The script uses color codes to enhance readability:

RED: Error messages.
GREEN: Success messages.
YELLOW: Prompts and warnings.
BLUE: Section headers.
MAGENTA: User instructions.
2. Function Descriptions
print_header()
Prints section headers to visually separate different parts of the script's output.

check_redis_installed()
Checks if Redis is installed on the system. If not installed, it prompts the user to install Redis either from the internet or a local tarball.

install_redis()
Installs Redis from the internet, with specific instructions depending on the detected operating system (Ubuntu, RHEL, or macOS).

install_redis_from_tarball()
Prompts the user to select a Redis tarball from the current directory and installs Redis from it.

display_main_menu()
Displays the main menu, allowing the user to choose from options such as configuring an instance, configuring a cluster, managing instances, backing up data, restoring data, or exiting the script.

configure_redis_instance()
Guides the user through the configuration of a new Redis instance, including setting options such as port, memory limit, persistence method, and security settings.

configure_redis_cluster()
Allows the user to configure a Redis cluster, including adding nodes and setting cluster-related options.

manage_redis_instances()
Provides options to manage existing Redis instances, including shutting them down, starting/restarting, checking their status, and reading their configuration files.

read_redis_conf()
Reads and displays the configuration of a specific Redis instance, based on the provided port.

check_redis_status()
Checks and displays which Redis instances are currently running on the system.

list_running_instances()
Lists all running Redis instances, showing their process ID, port, and whether clustering is enabled.

shutdown_redis_instance()
Shuts down a specific Redis instance based on the port provided by the user.

start_redis_instance()
Starts a Redis instance with the configuration file corresponding to the provided port.

backup_redis_data()
Creates a backup of the Redis data for a specific instance, either in RDB or AOF format, depending on the instance's configuration.

restore_redis_data()
Restores Redis data from a backup file, ensuring the backup format matches the instance's configuration (RDB or AOF).

3. Main Execution
The script first checks if Redis is installed. If Redis is installed or after it has been installed, the main menu is displayed, allowing the user to interact with the various features of the script.

4. User Interaction
The script extensively interacts with the user through prompts, allowing for customized configurations and operations based on the user's inputs. It handles errors gracefully and provides feedback for each action taken.

Usage
Run the script: Execute the script in a bash shell.
Follow prompts: Respond to the prompts to manage Redis on your system.
Choose options: Use the main menu to navigate through the available features, such as configuring instances or managing backups.
Error Handling
The script includes various checks to handle potential errors, such as invalid inputs, missing tarballs, or connection issues. It provides clear error messages and instructions for resolving issues.
