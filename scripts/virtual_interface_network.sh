#!/bin/bash


NODE_NAME_PREFIX="${NODE_NAME_PREFIX:-node}"
IPV4_INTERNAL_PREFIX="${IPV4_INTERNAL_PREFIX:-10.1.10.}"
IPV4_INTERNAL_NETMASK=${IPV4_INTERNAL_NETMASK:-255.255.255.0}
NODE_FIRST_POS=${NODE_FIRST_POS:-10}


function stderr { printf "$@\n" >&2; }

trap "stderr 'Timeout caught.' && exit 1" SIGTERM 
set -e -o pipefail

function is_number(){
  is_number='^[0-9]+$'
  if [[ ! $1 =~ $is_number ]]; then
      return 1
  else
      return 0
  fi
}

#echo 'Tests is_number'
#if is_number a; then echo 'FAIL: "a" should not pass'; else printf '.'; fi
#if is_number 'a'; then echo 'FAIL: "a" passed as string should not pass'; else printf '.'; fi
#if is_number '1'; then printf '.'; else echo 'FAIL: Number as string "1" should pass'; fi
#if is_number 1; then printf '.'; else echo 'FAIL: Number 1 should pass'; fi
#echo


function between_zero_and_fe(){
  if [ $1 -eq 0 > /dev/null 2>&1 ]; then
    ## Input equals 0, OK
    return 0
  elif [ $1 -gt 0 -a $1 -le 244  > /dev/null 2>&1 ]; then
    ## Input is greater than 0 AND less than 244
    return 0
  else
    ## Input DOES NOT match range
    return 1
  fi
}

#echo 'Tests between_zero_and_fe'
#if between_zero_and_fe ''    > /dev/null 2>&1; then echo 'FAIL: Empty input "" should not pass. We expect a digit.'; else printf '.'; fi
#if between_zero_and_fe 'a'   > /dev/null 2>&1; then echo 'FAIL: "a" should not pass. We expect a digit.'; else printf '.'; fi
#if between_zero_and_fe foo   > /dev/null 2>&1; then echo 'FAIL: "foo" should not pass. We expect a digit.'; else printf '.'; fi
#if between_zero_and_fe 999   > /dev/null 2>&1; then echo 'FAIL: Number 999 should not pass. Although it is a digit, it is higher than expected'; else printf '.'; fi
#if between_zero_and_fe "999" > /dev/null 2>&1; then echo 'FAIL: Number as string "999" should not pass. Although it is a digit, it is highger than expected'; else printf '.'; fi
#if between_zero_and_fe 99    > /dev/null 2>&1; then printf '.'; else echo 'FAIL: Number 99 SHOULD pass, it is within 0..244 range'; fi
#if between_zero_and_fe "5"   > /dev/null 2>&1; then printf '.'; else echo 'FAIL: Number as string "5" SHOULD pass, it is within 0..244 range'; fi
#echo


function between_current_and_fe(){
  ## BOTH inputs MUTS be numbers
  if ! is_number $1; then
    return 1
  fi
  if ! is_number $2; then
    return 1
  fi
  if [ $1 -le $2 -a $2 -le 244 ]; then
    if [ $1 -eq $2 ]; then
      return 1
    else
      return 0
    fi
  fi
  return 1
}

#echo 'Tests between_current_and_fe'
#if between_current_and_fe 5 1; then echo 'FAIL: This should fail because Number 5 is higher than maximum of a set of 1 '; else printf '.'; fi
#if between_current_and_fe '5' '1'; then echo 'FAIL: This should fail because Number passed as string "5" is higher than said maximum of a set of "1"'; else printf '.'; fi
#if between_current_and_fe 1 5; then printf '.'; else echo 'FAIL: This should pass because we can have member Number 1 out of 5 others'; fi
#if between_current_and_fe "1" '5'; then printf '.'; else echo 'FAIL: This should pass because we can have a member Number "1" (passed as string) out of "5" others (notice 5 passed as string)'; fi
#if between_current_and_fe 1 1; then printf "\nFAIL: Current (1) is not zero indexed, but second argument (1) is. In a 1 node cluser, we would only have one node called node0.\n"; else printf '.'; fi
#if between_current_and_fe foo 1; then echo 'FAIL: This should fail because first argument was "foo" is not a number and we expect only digits'; else printf '.'; fi
#if between_current_and_fe 1 bar; then echo 'FAIL: This should fail because second argument was "bar" is not a number and we expect only digits'; else printf '.'; fi
#if between_current_and_fe foo bar; then echo 'FAIL: This should fail because both arguments are strings and we expect only digits'; else printf '.'; fi
#echo



function is_valid_dns_name() {
  dns_name_regex='^[a-z][a-z0-9]+$'
  if [[ $1 =~ $dns_name_regex ]]; then
      return 0
  fi
  return 1
}

#echo 'Tests is_valid_dns_name'
#if is_valid_dns_name 'node1'; then printf '.'; else echo 'FAIL: "node1" is a valid DNS name'; fi
#if is_valid_dns_name 'node2'; then printf '.'; else echo 'FAIL: "node2" is a valid DNS name'; fi
#if is_valid_dns_name 'n0de'; then printf '.'; else echo 'FAIL: "n0de" is a valid DNS name'; fi
#if is_valid_dns_name '1node'; then echo 'FAIL: "1node" is invalid, DNS names MUST NOT start by digits'; else printf '.'; fi
#if is_valid_dns_name 'node_234'; then echo 'FAIL: "node_234" is invalid, DNS names CANNOT contain underscore'; else printf '.'; fi
#if is_valid_dns_name 234; then echo 'FAIL: "234" is invalid, DNS names CANNOT contain only digits'; else printf '.'; fi
#echo



if test "$(id -g)" -ne "0"; then
  stderr 'You must run this as root.'
  exit 1
fi

if ! is_number ${NODE_FIRST_POS}; then
  stderr "NODE_FIRST_POS environment MUST be a number, \"${NODE_FIRST_POS}\" is invalid."
  exit 1
fi


###
## Validate a number for a node number
## Must be between 0 and 244
## e.g. node1 will have private IP 10.10.0.11
if ! is_number $NODE_NUMBER; then
  NODE_NUMBER=""
fi
if ! between_zero_and_fe $NODE_NUMBER; then
  NODE_NUMBER=""
fi
while ! is_number $NODE_NUMBER; do
  read -p "What is the node number you want this to be? " NODE_NUMBER
  if between_zero_and_fe $NODE_NUMBER; then
    NODE_NUMBER=$NODE_NUMBER
  else
    stderr "Input \"$NODE_NUMBER\" is invalid, it MUST be a number and under 244"
    NODE_NUMBER=""
  fi
done
###



###
## Validate how many members of the cluster we will have.
## We want to know how many we will have so we know how many
## /etc/hosts entries to make
##
## Catch situation where we privde a number as environment
## but is an invalid type.
if ! is_number $NODE_COUNT_MAX; then
  NODE_COUNT_MAX=""
fi
COUNTER_CURRENT_AND_MAX=0
MAX_ITER_COUNTER_CURRENT_AND_MAX=3
while ! is_number $NODE_COUNT_MAX; do
  read -p "How many nodes will we have? " NODE_COUNT_MAX
  if ! between_current_and_fe $NODE_NUMBER $NODE_COUNT_MAX; then
    if [[ ${NODE_NUMBER} -eq ${NODE_COUNT_MAX} ]]; then
      NODE_COUNT_MAX_TIP=$(printf %d $((${NODE_COUNT_MAX} + 1)))
      stderr "Is this the last node of a cluster? If so, maybe you mean  \"${NODE_COUNT_MAX_TIP}\"?"
    else
      stderr "Maximum node number \"${NODE_COUNT_MAX}\" cannot be lower than \"${NODE_NUMBER}\""
    fi
    NODE_COUNT_MAX=""
  else
    break;
  fi
  if [[ $COUNTER_CURRENT_AND_MAX -gt 0 ]]; then
    printf "(${COUNTER_CURRENT_AND_MAX}/${MAX_ITER_COUNTER_CURRENT_AND_MAX}) "
    if [[ ${COUNTER_CURRENT_AND_MAX} -ge ${MAX_ITER_COUNTER_CURRENT_AND_MAX} ]]; then
      stderr "Maximum iterations reached. Aborting"
      exit 1
    fi
  fi
  COUNTER_CURRENT_AND_MAX=$(printf %d $((${COUNTER_CURRENT_AND_MAX} + 1)))
done
NODE_COUNT_MAX=$(printf %d $((${NODE_COUNT_MAX} - 1)))
###



NODE_POS=$(printf %d $((${NODE_NUMBER} + ${NODE_FIRST_POS})))
IPV4_INTERNAL="${IPV4_INTERNAL_PREFIX}${NODE_POS}"
NODE_NAME="${NODE_NAME_PREFIX}${NODE_NUMBER}"
NODE_COUNT_MAX_HUMAN=$(printf %d $((${NODE_COUNT_MAX} + 1)))
echo "# This is the ${NODE_NUMBER}th node of a ${NODE_COUNT_MAX_HUMAN} total nodes cluster, it will be known as ${NODE_NAME} with IPv4 private IP ${IPV4_INTERNAL}"



if test -z ${NODE_NAME}; then
  read -p 'What is the name you want to give to this node?: ' NODE_NAME
  # Thanks http://stackoverflow.com/questions/5284147/validating-ipv4-addresses-with-regexp
  regex='^[a-z][a-z0-9]+$'
  if [[ ! $NODE_NAME =~ $regex ]]; then
    stderr "${NODE_NAME} would not be a valid DNS node name, try with something else"
    exit 1
  fi
fi



if test -z ${IPV4_INTERNAL}; then
  read -a IPV4_INTERNAL -p 'What is the IPv4 address you want to give on the private network?: '
  # Thanks http://stackoverflow.com/questions/5284147/validating-ipv4-addresses-with-regexp
  regex='^((25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|2[0-4][0-9]|[01]?[0-9][0-9]?)$'
  if [[ ! $IPV4_INTERNAL =~ $regex ]]; then
    stderr "${IPV4_INTERNAL} is NOT a valid IPv4 address, try with something else."
    exit 1
  fi
fi



hostnamectl set-hostname ${NODE_NAME}

sed -i '/^auto eth0/ s/eth0$/eth0 eth0:1/' /etc/network/interfaces.d/eth0
#sed -i '/^iface eth0 inet dhcp/ s/eth0 inet dhcp$/eth0:1 inet dhcp/' /etc/network/interfaces.d/eth0

(cat <<- _EOF_
iface eth0:1 inet static
      address ${IPV4_INTERNAL}
      netmask ${IPV4_INTERNAL_NETMASK}
_EOF_
) >> /etc/network/interfaces.d/eth0

ifup eth0:1



LIST=""
for i in `seq 0 $NODE_COUNT_MAX`; do
  if [[ ! "${NODE_NUMBER}" = "${i}" ]]; then
    NODE_POS=$(printf %d $((${i} + ${NODE_FIRST_POS})))
    IP="${IPV4_INTERNAL_PREFIX}${NODE_POS}"
    APPEND_CLUSTER_MEMBER=""
  else
    IP="127.0.1.1"
    APPEND_CLUSTER_MEMBER=" self"
  fi
  LIST+="${IP}\t${NODE_NAME_PREFIX}${i}\t# cluster_member ${APPEND_CLUSTER_MEMBER}\n"
done

grep -q -e "${NODE_NAME_PREFIX}${i}" /etc/hosts || printf $"\n##########\n${LIST}##########\n" >> /etc/hosts



echo Done!
