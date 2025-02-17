#!/bin/bash
# SPDX-License-Identifier: GPL-2.0-only
# Copyright (c) 2022 Intel Corporation
# @Desc  Test script to verify Intel CET functionality

cd "$(dirname "$0")" 2>/dev/null && source ../.env

readonly NULL="null"
readonly CONTAIN="contain"

TEST_MOD="cet_ioctl"
TEST_MOD_KO="${TEST_MOD}.ko"
KO_FILE="./cet_driver/${TEST_MOD_KO}"

export teardown_handler="cet_teardown"

usage() {
  cat <<__EOF
  usage: ./${0##*/} [-t TEST_TYPE][-n BIN_NAME][-p parameter][-k KEYWORD][-h]
  -t  Test type like cp_test
  -n  Test cpu bin name like shstk_cp and so on
  -p  PARM like null
  -k  Keyword for dmesg checking like "control protection"
  -h  show This
__EOF
}

# Reserve for taerdown, present no change for cpu test
cet_teardown() {
  check_mod=$(lsmod | grep "$TEST_MOD")
  [[ -z "$check_mod" ]] || {
    test_print_trc "rmmod $TEST_MOD"
    rmmod "$KO_FILE"
  }
}

load_cet_driver() {
  local ker_ver=""
  local check_mod=""

  pat=$(pwd)
  echo "pat:$pat"
  [[ -e "$KO_FILE" ]] || block_test "No $TEST_MOD_KO exist, please make it first"
  mod_info=$(modinfo "$KO_FILE")
  ker_ver=$(uname -r)
  if [[ "$mod_info" == *"$ker_ver"* ]]; then
    test_print_trc "$TEST_MOD_KO matched with current kernel version:$ker_ver"
  else
    block_test "$TEST_MOD_KO didn't match kernel ver:$ker_ver; modinfo:$mod_info"
  fi
  check_mod=$(lsmod | grep "$TEST_MOD")
  if [[ -z "$check_mod" ]]; then
    test_print_trc "No $TEST_MOD loaded, will load $TEST_MOD"
    do_cmd "insmod $KO_FILE"
  else
    test_print_trc "$TEST_MOD is already loaded."
  fi
}

cet_shstk_check() {
  local bin_name=$1
  local bin_parm=$2
  local name=$3
  local ssp=""
  local bp_add=""
  local sp=""
  local obj_log="${bin_name}.txt"

  bin=$(which "$bin_name")
  if [[ -e "$bin" ]]; then
    test_print_trc "Find bin:$bin"
  else
    die "bin:$bin does not exist"
  fi

  bin_output_dmesg "$bin" "$bin_parm"
  sleep 1
  case $name in
    cet_ssp)
      ssp=$(echo "$BIN_OUTPUT" \
            | grep "ssp" \
            | tail -1 \
            | awk -F "*ssp=0x" '{print $2}' \
            | cut -d ' ' -f 1)
      bp_add=$(echo "$BIN_OUTPUT" \
              | grep "ssp" \
              | tail -1 \
              | awk -F ":0x" '{print $2}' \
              | cut -d ' ' -f 1)
      [[ -n "$ssp" ]] || na_test "platform not support cet ssp check"
      do_cmd "objdump -d $bin > $obj_log"
      sp=$(grep -A1  "<shadow_stack_check>$" "$obj_log" \
            | tail -n 1 \
            | awk '{print $1}' \
            | cut -d ':' -f 1)
      if [[ "$ssp" == *"$sp"* ]]; then
        test_print_trc "sp:$sp is same as ssp:$ssp, pass"
      else
        test_print_wrg "sp:$sp is not same as ssp:$ssp"
        test_print_trc "clear linux compiler changed sp"
      fi
      if [[ "$bp_add" == "$ssp" ]] ; then
        test_print_trc "bp+1:$bp_add is same as ssp:$ssp, pass"
      else
        die "bp+1:$bp_add is not same as ssp:$ssp"
      fi
    ;;
    *)
      block_test "Invalid name:$name in cet_shstk_check"
    ;;
  esac
}

cet_dmesg_check() {
  local bin_name=$1
  local bin_parm=$2
  local key=$3
  local key_parm=$4
  local verify_key=""

  bin_output_dmesg "$bin_name" "$bin_parm"
  sleep 1
  verify_key=$(echo "$BIN_DMESG" | grep -i "$key")
  case $key_parm in
    "$CONTAIN")
      if [[ -z "$verify_key" ]]; then
        die "No $key found in dmesg:$BIN_DMESG when executed $bin_name $bin_parm, fail."
      else
        test_print_trc "$key found in dmesg:$BIN_DMESG, pass."
      fi
      ;;
    "$NULL")
      if [[ -z "$verify_key" ]]; then
        test_print_trc "No $key in dmesg:$BIN_DMESG when test $bin_name $bin_parm, pass."
      else
        die "$key found in dmesg when test $bin_name $bin_parm:$BIN_DMESG, fail."
      fi
      ;;
    *)
      block_test "Invalid key_parm:$key_parm"
      ;;
  esac
}

cet_tests() {
  bin_file=""

  # Absolute path of BIN_NAME
  bin_file=$(which "$BIN_NAME")
  test_print_trc "Test bin:$bin_file $PARM, $TYPE:check dmesg $KEYWORD"
  case $TYPE in
    cp_test)
      cet_dmesg_check "$bin_file" "$PARM" "$KEYWORD" "$CONTAIN"
      ;;
    kmod_ibt_illegal)
      load_cet_driver
      cet_dmesg_check "$bin_file" "$PARM" "$KEYWORD" "$CONTAIN"
      ;;
    kmod_ibt_legal)
      load_cet_driver
      cet_dmesg_check "$bin_file" "$PARM" "$KEYWORD" "$NULL"
      ;;
    no_cp)
      cet_dmesg_check "$bin_file" "$PARM" "$KEYWORD" "$NULL"
      ;;
    cet_ssp)
      cet_shstk_check "$bin_file" "$PARM" "$TYPE"
      ;;
    *)
      usage
      block_test "Invalid TYPE:$TYPE"
      ;;
  esac
}

while getopts :t:n:p:k:h arg; do
  case $arg in
    t)
      TYPE=$OPTARG
      ;;
    n)
      BIN_NAME=$OPTARG
      ;;
    p)
      PARM=$OPTARG
      ;;
    k)
      KEYWORD=$OPTARG
      ;;
    h)
      usage
      exit 0
      ;;
    *)
      usage
      die "Option -$OPTARG requires an argument."
      ;;
  esac
done

cet_tests
exec_teardown
