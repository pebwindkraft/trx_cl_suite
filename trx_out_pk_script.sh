#!/bin/sh
##############################################################################
# Read the bitcoin PK_script OPCODES from a transaction's TRX_OUT
# script by Sven-Volker Nowarra 
#
# Version	by	date	comment
# 0.1		svn	02jun16	initial release
# 
# Copyright (c) 2015, 2016 Volker Nowarra 
# Complete rewrite of code in June 2016 from following reference:
#   https://en.bitcoin.it/wiki/Protocol_specification#tx
#   https://en.bitcoin.it/wiki/Script
# 
#  As of Bitcoin Core 0.10, these are considered standard scripts:
# 
#   P2PKH (pay-to-public-key-hash)
#   P2SH (pay-to-script-hash)
#   P2PK (pay-to-public-key)
#   Multisignature
#   OP_RETURN metadata
# 
# 
# Permission to use, copy, modify, and distribute this software for any 
# purpose with or without fee is hereby granted, provided that the above 
# copyright notice and this permission notice appear in all copies. 
# 
# 
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES 
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF 
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY 
# SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER 
# RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, 
# NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE 
# USE OR PERFORMANCE OF THIS SOFTWARE. 
#

ret_string=''
QUIET=0
param=76A9146AF1D17462C6146A8A61217E8648903ACD3335F188AC

case "$1" in
  -q)
     QUIET=1
     shift
     ;;
  -?|-h|--help)
     echo "usage: trx_out_sig_script.sh [-?|-h|--help|-q] hex_string"
     echo "  "
     echo "convert a raw hex string from a bitcoin trx-out into it's OpCodes. "
     echo "if no parameter is given, the data from a demo trx is used. "
     echo "  "
     exit 0
     ;;
  *)
     ;;
esac

if [ $QUIET -eq 0 ] ; then 
  echo "###############################################################"
  echo "### trx_out_pk_script.sh: read PK_script OPCODES from a trx ###"
  echo "###############################################################"
  echo "  "
fi

if [ $# -eq 0 ] ; then 
  if [ $QUIET -eq 0 ] ; then 
    echo "no parameter, hence showing example pk_script:"
    echo "$param"
  fi
else 
  param=$( echo $1 | tr "[:lower:]" "[:upper:]" )
fi

###########################################################################
### procedure to show data following an "OP_DATA" opcode                ###
###########################################################################
op_data_show() {
  n=1
  output=
  while [ $n -le $cur_opcode_dec ]
   do
    output=$output${opcode_ar[offset]}
    ret_string=$ret_string${opcode_ar[offset]}
    if [ $n -eq 8 ] || [ $n -eq 24 ] || [ $n -eq 40 ] || [ $n -eq 56 ] ; then 
      output=$output":"
    fi
    if [ $n -eq 16 ] || [ $n -eq 32 ] || [ $n -eq 48 ] || [ $n -eq 64 ] ; then 
      echo "        $output" 
      output=
    fi
    n=$(( n + 1 ))
    offset=$(( offset + 1 ))
  done 
  echo "        $output" 
}

#####################
### GET NEXT CODE ###
#####################
get_next_opcode() {
  cur_opcode=${opcode_ar[offset]}
  cur_hexcode="0x"$cur_opcode
  cur_opcode_dec=$( echo "ibase=16;$cur_opcode" | bc )
  # echo "offset=$offset, opcode=$cur_opcode, opcode_dec=$cur_opcode_dec"
  offset=$(( offset + 1 ))
}

#####################################
### STATUS 1 (OP_DUP)             ###
#####################################
S1_OP_DUP() {
  get_next_opcode
  case $cur_opcode in
    A9) echo "    $cur_opcode: OP_HASH160"
        S2_OP_HASH160
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 2 (OP_HASH160)         ###
#####################################
S2_OP_HASH160() {
  get_next_opcode
  case $cur_opcode in
    14) echo "    $cur_opcode: OP_Data$cur_opcode (= decimal $cur_opcode_dec)"
        op_data_show
        S3_OP_DATA20
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 3 (OP_DATA20)          ###
#####################################
S3_OP_DATA20() {
  get_next_opcode
  case "$cur_opcode" in
    88) echo "    $cur_opcode: OP_EQUALVERIFY"
        S4_OP_EQUALVERIFY
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 4 (OP_EQUALVERIFY)     ###
#####################################
S4_OP_EQUALVERIFY() {
  get_next_opcode
  case $cur_opcode in
    AC) echo "    $cur_opcode: OP_CHECKSIG"
        S5_P2PKH
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 5 (P2PKH)              ###
#####################################
S5_P2PKH() {
  echo "  This is a P2PKH script:"
}
#####################################
### STATUS 6 (OP_DATA65)          ###
#####################################
S6_OP_DATA65() {
  get_next_opcode
  case $cur_opcode in
    AC) echo "    $cur_opcode: OP_CHECKSIG"
        S7_P2PK
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 7 (P2PK)               ###
#####################################
S7_P2PK() {
    echo "  This is a P2PK script:"
}
#####################################
### STATUS 8 (OP_HASH160)         ###
#####################################
S8_OP_HASH160() {
  get_next_opcode
  case $cur_opcode in
    14) echo "    $cur_opcode: OP_Data$cur_opcode (= decimal $cur_opcode_dec)"
        op_data_show
        S9_OP_DATA20
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 9 (OP_DATA20)          ###
#####################################
S9_OP_DATA20() {
  get_next_opcode
  case $cur_opcode in
    87) echo "    $cur_opcode: OP_EQUAL" 
        S10_P2SH
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 10 (P2SH)              ###
#####################################
S10_P2SH() {
    # P2SH addresses start with a "05" in their base58encoded representation!
    # https://en.bitcoin.it/wiki/List_of_address_prefixes
    echo "  This is a P2SH script:"
    # we add a "P2SH" string at the end, to notify the following 
    # base58encode script about this special adress
    ret_string="$ret_string -P2SH"
}
#####################################
### STATUS 11 (OP_DATA33)         ###
#####################################
S11_OP_DATA33() {
  get_next_opcode
  case $cur_opcode in
    AC) echo "    $cur_opcode: OP_CHECKSIG"
        S12_P2PK
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 12 (P2PK)              ###
#####################################
S12_P2PK() {
    echo "This is a P2PK script:"
}
#####################################
### STATUS 13 (OP_1)              ###
#####################################
S13_OP_1() {
  get_next_opcode
  case $cur_opcode in
    21) echo "    $cur_opcode: OP_Data$cur_opcode (= decimal $cur_opcode_dec)"
        op_data_show
        S20_OP_DATA33
        ;;
    41) echo "    $cur_opcode: OP_Data$cur_opcode (= decimal $cur_opcode_dec)"
        op_data_show
        S14_OP_DATA65
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 14 (OP_DATA65)         ###
#####################################
S14_OP_DATA65() {
  get_next_opcode
  case $cur_opcode in
    21) echo "    $cur_opcode: OP_Data$cur_opcode (= decimal $cur_opcode_dec)"
        op_data_show
        S15_OP_DATA33 
        ;;
    41) echo "    $cur_opcode: OP_Data$cur_opcode (= decimal $cur_opcode_dec)"
        op_data_show
        S17_OP_DATA65
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 15 (OP_DATA33)         ###
#####################################
S15_OP_DATA33() {
  get_next_opcode
  case $cur_opcode in
    52) echo "    $cur_opcode: OP_Data$cur_opcode (= decimal $cur_opcode_dec)"
        op_data_show
        S22_PRE_MULTISIG
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 17 (OP_DATA65)         ###
#####################################
S17_OP_DATA65() {
  get_next_opcode
  case $cur_opcode in
    41) echo "    $cur_opcode: OP_Data$cur_opcode (= decimal $cur_opcode_dec)"
        op_data_show
        S18_OP_DATA65
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 18 (OP_DATA65)         ###
#####################################
S18_OP_DATA65() {
  get_next_opcode
  case $cur_opcode in
    53) echo "    $cur_opcode: OP_Data$cur_opcode (= decimal $cur_opcode_dec)"
        S22_PRE_MULTISIG
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 20 (OP_DATA33)         ###
#####################################
S20_OP_DATA33() {
  get_next_opcode
  case $cur_opcode in
    21) echo "    $cur_opcode: OP_Data$cur_opcode (= decimal $cur_opcode_dec)"
        op_data_show
        S21_OP_DATA33
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 21 (OP_DATA33)         ###
#####################################
S21_OP_DATA33() {
  get_next_opcode
  case $cur_opcode in
    52) echo "    $cur_opcode: OP_Data$cur_opcode (= decimal $cur_opcode_dec)"
        op_data_show
        S22_PRE_MULTISIG
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 22 (PRE_MULTISIG)     ###
#####################################
S22_PRE_MULTISIG() {
  get_next_opcode
  case $cur_opcode in
    AE) echo "    $cur_opcode: OP_CHECKMULTISIG"
        S23_MULTISIG
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 23 (MULTISIG)          ###
#####################################
S23_MULTISIG() {
    echo "This is a Multisig script:"
}
#####################################
### STATUS 24 (OP_RETURN)         ###
#####################################
S24_OP_RETURN() {
  get_next_opcode
  case $cur_opcode in
    28) echo "    $cur_opcode: OP_Data$cur_opcode (= decimal $cur_opcode_dec)"
        offset=$(( offset + 1 ))
        op_data_show
        S25_NULL_DATA
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 25 (NULL_DATA)         ###
#####################################
S25_NULL_DATA() {
    echo "This is a NULLDATA script:"
}
#####################################
### STATUS 26 (UNKNOWN)           ###
#####################################
S26_UNKNOWN() {
    echo "This is an UNKNOWN script:"
}

##########################################################################
### AND HERE WE GO ...                                                 ###
##########################################################################

typeset -i cur_opcode_dec
offset=0

opcode_array=$( echo $param | sed 's/[[:xdigit:]]\{2\}/ &/g' )
opcode_array_elements=$( echo ${#opcode_array} / 3 | bc )
# echo "opcode_array_elements=$opcode_array_elements, array=$opcode_array"

shell_string=$( echo $SHELL | cut -d / -f 3 )
if [ "$shell_string" == "bash" ] ; then
  i=0
  j=1
  declare -a opcode_ar
  while [ $i -lt $opcode_array_elements ]
   do
    # echo ${opcode_array:$j:2}
    opcode_ar[$i]=${opcode_array:$j:2}
    # echo "opcode_ar[$j]=$opcode_ar[$j]"
    i=$(( i + 1 ))
    j=$(( j + 3 ))
  done
elif [ "$shell_string" == "ksh" ] ; then
  set -A opcode_ar $opcode_array
fi

#####################################
### STATUS 0  INIT                ###
#####################################
  while [ $offset -lt $opcode_array_elements ]  
   do

    get_next_opcode

    case $cur_opcode in
      76) echo "    $cur_opcode: OP_DUP"
	  S1_OP_DUP
          ;;
      A9) echo "    $cur_opcode: OP_HASH160"
	  S8_OP_HASH160
          ;;
      51) echo "    $cur_opcode: OP_1, OP_TRUE"
	  S13_OP_1
          ;;
      6A) echo "    $cur_opcode: OP_RETURN"
	  S24_OP_RETURN
          ;;
      20) echo "    $cur_opcode: OP_Data32"
	  S26_UNKNOWN
          ;;
      21) echo "    $cur_opcode: OP_Data33"
          op_data_show
	  S11_OP_DATA33
          ;;
      24) echo "    $cur_opcode: OP_DATA36"
	  S26_UNKNOWN
          ;;
      41) echo "    $cur_opcode: OP_DATA65"
          op_data_show
	  S6_OP_DATA65
          ;;
      *)
          ;;
    esac

    if [ $offset -gt 300 ] ; then
      echo "emergency exit, output scripts should not reach this size ..."
      exit 1
    fi
  done

echo "   $ret_string"


