#!/bin/bash

# Fixed output folder name
output_folder="temp_env_files"

# Function to inject secrets using 1Password
inject_secrets() {
    service_name="$1"
    secret_refs_file="$2"
    
    # Define the output env file name based on the service name and fixed folder name
    output_env_file="${output_folder}/${service_name}.env"

    # Use 'op inject' to populate secrets from 1Password
    op inject -i "${secret_refs_file}" -o "${output_env_file}"

    if [ $? -eq 0 ]; then
        echo "Secrets injected from '${secret_refs_file}' to '${output_env_file}' for service '${service_name}'"
    else
        echo "Error injecting secrets from '${secret_refs_file}' to '${output_env_file}' for service '${service_name}'"
        exit 1
    fi
}

# Check if 'op' is installed
if ! command -v op &> /dev/null; then
    echo "1Password CLI ('op') is not installed. Please install it."
    exit 1
fi

# Check for the correct number of arguments
if [ "$#" -lt 2 ]; then
    echo "Usage: $0 <service_name> <secret_refs_env_file> [<service_name> <secret_refs_env_file> ...]"
    exit 1
fi

# Create the output folder if it doesn't exist
mkdir -p "${output_folder}"

# Loop through the arguments in pairs
while [ $# -ge 2 ]; do
    service_name="$1"
    secret_refs_env_file="$2"

    # Inject secrets and get the generated env file name
    inject_secrets "${service_name}" "${secret_refs_env_file}"

    echo "Secrets injected successfully for service '${service_name}'."

    shift 2
done

# Start Docker Compose in detached mode
docker-compose -f ./docker-compose.yml up -d

# Optionally, you can remove the generated env files and the folder after starting Docker Compose
if [ -d "${output_folder}" ]; then
    rm -rf "${output_folder}"
    echo "Deleted folder containing generated env files: ${output_folder}"
fi
