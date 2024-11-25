#!/usr/bin/env bash

#
# Registers azure resource providers defined in a text file.
#
#  azure-providers.txt
#  ------------------------------
#  Microsoft.ApiManagement
#  Microsoft.Web
#  Microsoft.DocumentDB
#  Microsoft.OperationalInsights
#
# Usage:
#  ./register-azure-providers.sh azure-providers.txt
#  cat azure-providers.txt | ./register-azure-providers.sh
#

str_len () {
  str=$1

  echo ${#str}
}

# https://en.wikipedia.org/wiki/ANSI_escape_code#Control_Sequence_Introducer_commands
print_provider_name () {
  provider=$1

  provider_name_len=$(str_len "$provider")
  dot_len=$((max_len_provider_name-provider_name_len+5))
  echo -ne "\033[0K$provider "
  printf '.%.0s' $(seq 1 $dot_len)
  echo -n " "
}

# https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
print_not_registered_state () {
  echo -e "\033[38;5;15m\033[48;5;1m NotRegistered \033[m"
}

# https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
print_registered_state () {
  echo -e "\033[38;5;0m\033[48;5;2m Registered \033[m"
}

# https://en.wikipedia.org/wiki/ANSI_escape_code#8-bit
print_state () {
  state=$1
  echo -e "\033[38;5;15m\033[48;5;243m $state \033[m"
}

# https://en.wikipedia.org/wiki/ANSI_escape_code#Control_Sequence_Introducer_commands
move_cursor_to_first_line () {
  number_of_lines=$1
  echo -ne "\033[${number_of_lines}F"
}

delay_in_seconds=5
max_len_provider_name=0
elapsed_time_start=$(date +%s)

# Read azure resource providers from text file into associative array 
# with state of NotRegistered
declare -A providers
while IFS= read -r line || [[ "$line" ]]; do
  providers[$line]="NotRegistered"
  provider_name_len=$(str_len "$line")
  if [ "$provider_name_len" -gt "$max_len_provider_name" ]; then
    max_len_provider_name=$provider_name_len
  fi
done < "${1:-/dev/stdin}"

# Get list of all registered azure resource providers
mapfile -t registered_providers < <(az provider list --query "sort_by([?registrationState=='Registered'].{Provider:namespace}, &Provider)" --out tsv)

# Build a sorted list of azure resource providers to register
mapfile -t sorted_required_providers < <(for key in "${!providers[@]}"; do echo "$key"; done | sort)

# Register the providers in the list that are not already registered
for provider in "${sorted_required_providers[@]}"; do 
  
  print_provider_name "$provider"

  if [ "$(echo "${registered_providers[@]}" | grep "$provider" )" == "" ]; then
    
    print_not_registered_state
    az provider register --namespace "$provider" > /dev/null 2>&1

  else
    
    print_registered_state
    providers[$provider]="Registered"

  fi
done

sleep $delay_in_seconds

total_number_of_providers=${#providers[@]}
not_registered_count=$total_number_of_providers

# Print the updated state of each of the provider registrations
while [ "$not_registered_count" -gt 0 ]
do
  move_cursor_to_first_line "$total_number_of_providers"
  for provider in "${sorted_required_providers[@]}"; do 

    if [ "${providers[$provider]}" == "Registered" ]; then
      state="Registered"
    else
      state=$(az provider show --namespace "$provider" --query 'registrationState' --output tsv)
    fi

    print_provider_name "$provider"
    if [ "$state" = "Registered" ]; then
      ((not_registered_count--))
      print_registered_state
      providers[$provider]="Registered"
    elif [ "$state" = "NotRegistered" ]; then
      print_not_registered_state
    else
      print_state "$state"
    fi

  done

  if [ "$not_registered_count" -gt 0 ]; then
    sleep $delay_in_seconds
    not_registered_count=$total_number_of_providers
  fi
done

elapsed_time_end=$(date +%s)
elapsed_time=$(( elapsed_time_end - elapsed_time_start ))
echo -e "\nElapsed time - $(date -d@${elapsed_time} -u +%Hh:%Mm:%Ss)\n"
