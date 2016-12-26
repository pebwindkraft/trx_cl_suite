#!/bin/sh
# tool to examine bitcoin transactions from the "transaction command line suite"
#
# Copyright (c) 2015, 2016 Volker Nowarra 
# Coded in Nov/Dec 2015 following this reference:
#   https://en.bitcoin.it/wiki/Protocol_specification#tx
#
# included example trx:
# https://blockchain.info/de/rawtx/
#  cc8a279b0736e6a2cc20b324acc5aa688b3af7b63bbb002f46f6573c1ad84408?format=hex
#
# Version	by	date	comment
#   0.1		svn	01nov16	new release from trx_2txt (which is now discontinued)
#   0.2		svn	14dec16 created array for a trx, cause OpenBSD cut cannot 
#			handle more than ~2000 chars (buffer size in pdksh?)
#
# Permission to use, copy, modify, and distribute this software for any 
# purpose with or without fee is hereby granted, provided that the above 
# copyright notice and this permission notice appear in all copies. 
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES 
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF 
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR ANY 
# SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES WHATSOEVER 
# RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN ACTION OF CONTRACT, 
# NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF OR IN CONNECTION WITH THE 
# USE OR PERFORMANCE OF THIS SOFTWARE. 
# 

###########################
# Some variables ...      #
###########################
typeset -i tx_array_ptr=0
typeset -i loopcounter=0
TX_id=''
raw_TX=''
raw_TX_LINK=https://blockchain.info/de/rawtx/cc8a279b0736e6a2cc20b324acc5aa688b3af7b63bbb002f46f6573c1ad84408
raw_TX_LINK2HEX="?format=hex"
raw_TX_DEFAULT=010000000253603b3fdb9d5e10de2172305ff68f4b5227310ba6bd81d4e1bf60c0de6183bc010000006a4730440220128487f04a591c43d7a6556fff9158999b46d6119c1a4d4cf1f5d0ac1dd57a94022061556761e9e1b1e656c0a70aa7b3e83454cd61662df61ebdc31e43196b5e0c10012102b12126a716ce7bbb84703bcfbf0afa80283c75a7304a48cd311a5027efd906c2ffffffff0e52c4701577287b6dd02f422c2a8033fa0b4614f75fa9f0a5c4ab69634b5ba7000000006b483045022100a428348ff55b2b59bc55ddacb1a00f4ecdabe282707ba5185d39fe9cdf05d7f0022074232dae76965b6311cea2d9e5708a0f137f4ea2b0e36d0818450c67c9ba259d0121025f95e8a33556e9d7311fa748e9434b333a4ecfb590c773480a196deab0dedee1ffffffff0290257300000000001976a914fca68658b537382e27a85522d292e1ad9543fe0488ac98381100000000001976a9146af1d17462c6146a8a61217e8648903acd3335f188ac00000000

typeset -i r_flag=0
typeset -i t_flag=0
typeset -i u_flag=0
var_int=0
Verbose=0
VVerbose=0

#################################################################
### set -A or declare tx_array - bash and ksh are different ! ###
#################################################################
shell_string=$( echo $SHELL | cut -d / -f 3 )
if [ "$shell_string" == "bash" ] ; then
  # echo "bash: declaring tx_array"
  declare -a tx_array
fi

#################################
# procedure to display helptext #
#################################
proc_help() {
  echo "usage: $0 [-f|-h|-r|-t|-u|-v|-vv] tx [filename|tx-id]"
  echo "  "
  echo "examine a raw TX into separate lines, as specified by:"
  echo "https://en.bitcoin.it/wiki/Protocol_specification#tx"
  echo "  "
  echo " -f   read tx data from file"
  echo " -h   show this help text"
  echo " -r   examine RAW TX (TX hex data as parameter string)"
  echo " -t   examine TX from blockchain.info (TRANSACTION_ID as parameter string)"
  echo " -u   examine UNSIGNED RAW TX (TX hex data as parameter string)"
  echo " -v   display verbose output"
  echo " -vv  display even more verbose output"
  echo "  "
  echo " without parameter, a default transaction will be displayed"
  echo " "
}

###################################
# procedure to display tx section #
###################################
get_TX_section() {
  tx_array_from=$tx_array_ptr
  tx_array_to=$(( $tx_array_ptr + $tx_array_bytes ))
  result=""
  until [ $tx_array_from -eq $tx_array_to ]
   do 
    printf "${tx_array[$tx_array_from]}"
    tx_array_from=$(( $tx_array_from + 1 ))
  done 
}

############################################
# procedure to check trx length (=64chars) #
############################################
check_trx_len() {
  if [ ${#TX_id} -ne 64 ] ; then
    echo "*** expecting a proper formatted Bitcoin TRANSACTION_ID."
    echo "    please provide a 64 bytes string (aka 32 hex chars) with '-t'."
    exit 0
  fi
}

############################################
# procedure to check trx length (=64chars) #
############################################
check_rawtrx_len() {
  if [ ${#raw_TX} -le 27 ] ; then
    echo "*** expecting a proper formatted Bitcoin RAW TRANSACTION."
    echo "    this should start with VERSION (aka 01000000...)."
    exit 0
  fi
}

#######################################
# procedure to display verbose output #
#######################################
v_output() {
  if [ $Verbose -eq 1 ] ; then
    echo "$1"
  fi
}

#################################################
# procedure to display even more verbose output #
#################################################
vv_output() {
  if [ $VVerbose -eq 1 ] ; then
    echo "$1"
  fi
}

##########################################
# procedure to check for necessary tools #
##########################################
check_tool() {
  if [ $VVerbose -eq 1 ]; then
    printf " %-8s" $1
  fi
  which $1 > /dev/null
  if [ $? -eq 0 ]; then
    if [ $VVerbose -eq 1 ]; then
      printf " - yes \n"
    fi
  else
    printf " \n"
    echo "*** ERROR: $1 not found, please install $1."
    echo "exiting gracefully ..."
    exit 0
  fi
}

##########################################
# procedure to reverse a hex data string #
##########################################
# s=s substr($0,i,1) means, that substr($0,i,1) is appended to the variable s; s=s+something
reverse_hex() {
  echo $1 | awk '{ for(i=length;i!=0;i=i-2)s=s substr($0,i-1,2);}END{print s}'
} 

###############################################################
# procedure to calculate value of var_int or compact size int #
###############################################################
# 
# var_int is defined as:
# value         size Format
# < 0xfd        1    uint8_t
# <= 0xffff     3    0xfd + uint16_t
# <= 0xffffffff 5    0xfe + uint32_t
# -             9    0xff + uint64_t 
# if value <= 0xfd, Bytes  = 1
# if value =  0xfd, Bytes  = 2
# if value =  0xfe, Bytes  = 4
# if value =  0xff, Bytes  = 8
proc_var_int() {
  var_int=${tx_array[$tx_array_ptr]}
  if [ "$var_int" == "FD" ] ; then
    tx_array_ptr=$(( $tx_array_ptr + 1 ))
    tx_array_bytes=2
    var_int=$( get_TX_section )
    # big endian conversion!
    var_int=$( reverse_hex $var_int )
  elif [ "$var_int" == "FE" ] ; then
    tx_array_ptr=$(( $tx_array_ptr + 1 ))
    tx_array_bytes=4
    var_int=$( get_TX_section )
    # big endian conversion!
    var_int=$( reverse_hex $var_int )
  elif [ "$var_int" == "FF" ] ; then
    tx_array_ptr=$(( $tx_array_ptr + 1 ))
    tx_array_bytes=8
    var_int=$( get_TX_section )
    # big endian conversion!
    var_int=$( reverse_hex $var_int )
  else
    var_int=${tx_array[$tx_array_ptr]}
  fi
}

#################################################
# procedure to display even more verbose output #
#################################################
decode_pkscript() {
    result=$( sh ./tcls_out_pk_script.sh -q $1 )
    echo " $result"
    result=$( echo "$result" | tail -n1 )
    len=$( echo $result | cut -d " " -f 1 )
    len=${#len}
    case "$len" in
       5) # a bit ugly. logic: first param = "-p2sh", which is a length of 5, then:
          echo "  and translates base58 encoded into this bitcoin address:"
          sh ./tcls_base58check_enc.sh -q $result
          ;;
      40) 
          echo "  and translates base58 encoded into this bitcoin address:"
          sh ./tcls_base58check_enc.sh -q -p2pkh $result
          ;;
      66|130)
          echo "  and translates base58 encoded into this bitcoin address:"
          sh ./tcls_base58check_enc.sh -q -p2pk $result
          ;;
    esac
}

echo "##################################################################"
echo "### tcls_tx2txt.sh: script to de-serialize/decode Bitcoin trx  ###"
echo "##################################################################"

################################
# command line params handling #
################################

if [ $# -eq 0 ] ; then
  echo "no parameter(s) given, using defaults"
  echo " "
  echo "alternativly, try --help"
  echo " "
  raw_TX=$raw_TX_DEFAULT
else
  while [ $# -ge 1 ] 
   do
    case "$1" in
      -f)
         if [ ${#2} -gt 0 ] ; then 
           if [ -f "$2" ] ; then
             raw_TX=$( cat $2 | sed 's/[[:xdigit:]]\{2\}/& /g' )
           else
             echo "ERROR: file not found, exiting gracefully ..."
             echo " "
             exit 1
           fi
           if [ "$3" == "-r" ] ; then
             r_flag=1
             shift 
           fi
           if [ "$3" == "-u" ] ; then
             u_flag=1
             shift 
           fi
         else
           echo "ERROR: no filename given, exiting gracefully ..."
           echo " "
           exit 1
         fi
         shift 
         shift 
         ;;
      -h)
         proc_help
         exit 0
         ;;
      -r)
         r_flag=1
         if [ $u_flag -eq 1 ] ; then
           echo "*** you cannot use -r with any of -u at the same time!"
           echo " "
           exit 0
         fi
         if [ "$2" == "-f"  ] ; then
           echo "*** set '-r' to the end, like this: -f <filename> -r"
           exit 0
         elif [ "$2" == ""  ] ; then
           echo "*** you must provide a string to the -r parameter!"
           exit 0
         else
           raw_TX=$2
           shift 
         fi
         check_rawtrx_len
         shift 
         ;;
      -t)
         t_flag=1
         if [ "$2" == ""  ] ; then
           echo "*** you must provide a Bitcoin TRANSACTION_ID to the -t parameter!"
           exit 0
         else
           TX_id=$2
           shift 
         fi
         check_trx_len
         shift 
         ;;
      -u)
         u_flag=1  
         if [ $r_flag -eq 1 ] || [ $t_flag -eq 1 ] ; then
           echo "*** you cannot use -u with any of -r|-t at the same time!"
           echo " "
           exit 0
         fi
         if [ "$2" == "-f"  ] ; then
           echo "*** set '-u' to the end, like this: -f <filename> -u"
           exit 0
         elif [ "$2" == ""  ] ; then
           echo "*** you must provide an unsigned raw transaction to the -u parameter!"
           exit 0
         else
           raw_TX=$2 
           shift 
         fi
         check_rawtrx_len
         shift 
         ;;
      -v)
         Verbose=1
         echo "Verbose output turned on"
         if [ "$2" == ""  ] ; then
           raw_TX=$raw_TX_DEFAULT
         fi
         shift
         ;;
      -vv)
         Verbose=1
         VVerbose=1
         echo "VVerbose and Verbose output turned on"
         if [ "$2" == ""  ] ; then
           raw_TX=$raw_TX_DEFAULT
           echo "using defaults, based on: "
           echo "   $raw_TX_LINK"
         fi
         shift
         ;;
      *)  # No more options
         echo "*** unknown parameter $1 "
         proc_help
         exit 1
         # break
         ;;
    esac
  done
fi

# verify operating system, cause 
# Linux wants to have "--posix" for their gawk program ...
http_get_cmd="echo " 
OS=$(uname)
if [ $OS == "OpenBSD" ] ; then
  awk_cmd=awk 
  http_get_cmd="ftp -M -V -o - "
fi
if [ $OS == "Darwin" ] ; then
  awk_cmd=$(which awk) 
  http_get_cmd="curl -sS -L "
fi
if [ $OS == "Linux" ] ; then
  awk_cmd="awk --posix" 
  http_get_cmd="curl -sS -L "
fi

vv_output "##########################################"
vv_output "### Check if necessary tools are there ###"
vv_output "##########################################"
check_tool awk
check_tool bc
check_tool dc
check_tool openssl 
check_tool sed
check_tool tr

###############################################
### Check if network is required and active ###
###############################################
# 
# if param -t was given, then a Bitcoin TRANSACTION_ID should be in variable "TX_id":
#   ./trx2txt -t cc8a279b0736e6a2cc20b324acc5aa688b3af7b63bbb002f46f6573c1ad84408
# 
# no we need to:
# 1.) check if network interface is active ...
# 2.) go to the network, like this:
#     https://blockchain.info/de/rawtx/cc8a279b07...3c1ad84408?format=hex
# 3.) use OS specific calls:
#     OpenBSD: ftp -M -V -o - https://blockchain.info/de/rawtx/...
# 4.) pass everything into the variable "raw_TX"
# 
if [ "$TX_id" ] ; then
  echo "###############################################"
  echo "### Check if network is required and active ###"
  echo "###############################################"
  v_output "working with this TX_id: $TX_id"
  if [ $OS == "Linux" ] ; then
    nw_if=$( netstat -rn | awk '/^0.0.0.0/ { print $NF }' | head -n1 )
    /sbin/ifstatus $nw_if | grep -q "up"
  else
    nw_if=$( netstat -rn | awk '/^default/ { print $NF }' | head -n1 )
    ifconfig $nw_if | grep -q " active"
  fi
  if [ $? -eq 0 ] ; then
    v_output "network interface is active, good"
    v_output "trying to fetch data from blockchain.info"
    raw_TX=$( $http_get_cmd https://blockchain.info/de/rawtx/$TX_id$raw_TX_LINK2HEX )
    if [ $? -ne 0 ] ; then
      echo "*** error - fetching raw_TX data:"
      echo "    $http_get_cmd https://blockchain.info/de/rawtx/$TX_id$raw_TX_LINK2HEX"
      echo "    downoad manually, and call 'trx2txt -r ...'"
      exit 1
    fi
    if [ ${#raw_TX} -eq 0 ] ; then
      echo "*** error - fetching raw_TX data:"
      echo "    The raw trx has a length of 0. Something failed."
      echo "    downoad manually, and call 'trx2txt -r ...'"
      exit 0
    fi
    if [ "$raw_TX" == "Transaction not found" ] ; then
      echo "*** error - fetching raw_TX data:"
      echo "    Transaction not found"
      echo "    downoad manually, and call 'trx2txt -r ...'"
      exit 0
    fi
  else
    echo "*** error - no network connection"
    echo "    check 'netstat -rn' default gateway, and 'ifconfig'"
    exit 1
  fi
fi

raw_TX=$( echo $raw_TX | tr [:lower:] [:upper:] )
# bring the data in $raw_TX into an array 
result=$( echo "$raw_TX" | sed 's/[[:xdigit:]]\{2\}/& /g' )
if [ "$shell_string" == "bash" ] ; then
  # running this on OpenBSD creates errors, hence a for loop...
  # tx_array=($result)
  # IFS=' ' read -a tx_array <<< "${result}"
  for i in $result;do tx_array[$n]=$i; ((n++));done
else [ "$shell_string" == "ksh" ] 
  set -A tx_array $result
fi
v_output "raw trx is this:"
# v_output "number of tx_array elements: ${#tx_array[*]}, raw trx is this:"
result=$( echo ${tx_array[*]} | tr -d " " )
v_output "$result"

echo "###################"
echo "### so let's go ###"
echo "###################"

##############################################################################
### STEP 1 - VERSION (4 Bytes) - Transaction data format version           ###
##############################################################################
### Size: uint32_t 
if [ "$Verbose" -eq 1 ] ; then
  echo " "
  echo "VERSION"
fi
tx_array_ptr=0
tx_array_bytes=4
result=$( get_TX_section )
tx_array_ptr=$(( $tx_array_ptr + $tx_array_bytes ))
echo " $result"

##############################################################################
### STEP 2 - TX_IN COUNT, Number of Inputs (var_int)                       ###
##############################################################################
### Size: 1 or more chars, data type var_int

tx_array_bytes=1
proc_var_int
tx_array_ptr=$(( $tx_array_ptr + $tx_array_bytes ))
tx_in_count_hex=$( echo $var_int | tr -d " " )
tx_in_count_dec=$( echo "ibase=16; $tx_in_count_hex"|bc) 
if [ "$Verbose" -eq 1 ] ; then
  echo "TX_IN COUNT [var_int]: hex=$tx_in_count_hex, decimal=$tx_in_count_dec"
else
  echo " $tx_in_count_hex"
fi
while [ $loopcounter -lt $tx_in_count_dec ]
 do
  #################################################################
  ### TX_IN, a data structure of one or more transaction inputs ###
  #################################################################
  ### Size: 41+, Data type tx_in[]   
  v_output "TX_IN[$loopcounter]"
  # TX_IN consists of the following fields:
  # Size Description       Data type Comments
  # 36   previous_output   outpoint, the previous output trx reference
  #      OutPoint structure: (The first output is 0, etc.)
  #      32   hash         char[32]  the hash of the referenced transaction (reversed).
  #       4   index        uint32_t  the index of the specific output in the transaction. 
  # 1+   script length     var_int   the length of the signature script
  # ?    signature script  uchar[]   script for confirming transaction authorization
  # 4    sequence          uint32_t  transaction version as defined by the sender. 
  #                                  intended for replacement of transactions when information 
  #                                  is updated before inclusion into a block. 
  #################################################################
  ### STEP 3 - TX_IN, previous output transaction hash: 32Bytes ###
  #################################################################
  ### Size: 32, Data type char[32]
  v_output " TX_IN[$loopcounter] OutPoint hash (char[32])"
  tx_array_bytes=32
  result=$( get_TX_section )
  tx_array_ptr=$(( $tx_array_ptr + $tx_array_bytes ))
  result=$( reverse_hex $result )
  echo "  $result"
  
  ##############################################################################
  ### STEP 4 - TX_IN, previous output index                                  ###
  ##############################################################################
  ### Size: 4, Data type u_int32 (4 Bytes), previous output index 
  tx_array_bytes=4
  # echo "tx_array_ptr=$tx_array_ptr, tx_array_bytes=$tx_array_bytes"
  trx_value_hex=$( get_TX_section )
  tx_array_ptr=$(( $tx_array_ptr + $tx_array_bytes ))
  result=$( reverse_hex $trx_value_hex )
  # and convert into decimal, and then Satoshis ...
  trx_value_dec=$( echo "ibase=16; $result"|bc) 
  if [ "$Verbose" -eq 1 ] ; then
    echo " TX_IN[$loopcounter] OutPoint index (uint32_t)"
    echo "  hex=$trx_value_hex, reversed=$result, decimal=$trx_value_dec"
  else 
    echo "  $trx_value_hex"
  fi
  
  ##############################################################################
  ### STEP 5 - TX_IN, script length is var_int, 1-4 hex chars ...            ###
  ##############################################################################
  ### Size: 1 or more chars, data type var_int
  tx_array_bytes=1
  proc_var_int
  tx_array_ptr=$(( $tx_array_ptr + $tx_array_bytes ))
  script_length_hex=$var_int
  script_length_dez=$( echo "ibase=16; $script_length_hex"|bc) 
  if [ "$Verbose" -eq 1 ] ; then
    echo " TX_IN[$loopcounter] Script Length (var_int)"
    echo "  hex=$script_length_hex, decimal=$script_length_dez"
  else
    echo "  $script_length_hex"
  fi

  ##############################################################################
  ### STEP 6 - TX_IN, signature script, first hex Byte is length (2 chars)   ###
  ##############################################################################
  ### Size: 1, Data type u_int 
  # For unsigned raw transactions, this is temporarily filled with the scriptPubKey 
  # of the output. First a one-byte varint which denotes the length of the scriptSig 
  v_output " TX_IN[$loopcounter] Script Sig (uchar[])"
  tx_array_bytes=$script_length_dez
  # echo "tx_array_ptr=$tx_array_ptr, tx_array_bytes=$tx_array_bytes"
  sig_script=$( get_TX_section )
  tx_array_ptr=$(( $tx_array_ptr + $tx_array_bytes ))
  echo "  $sig_script "

  ##############################################################################
  ### STEP 7 - TX_IN, signature script, uchar[] - variable length            ###
  ##############################################################################
  ### Size: 20+, Data type uchar[] 
  if [ "$VVerbose" -eq 1 ] && [ "$script_length_dez" -ne 0 ] ; then
    if [ $u_flag -eq 1 ] ; then
      echo "  Working on an unsigned raw TX. This is the pubkey script "
      echo "  of previous trx, for which you'll need the privkey to sign:"
      decode_pkscript $sig_script
    else
      if [ "$VVerbose" -eq 1 ] ; then
        ./tcls_in_sig_script.sh -v $sig_script 
      else
        ./tcls_in_sig_script.sh -q $sig_script 
      fi 
    fi
  fi

  ##############################################################################
  ### STEP 8 - TX_IN, SEQUENCE: This is currently always set to 0xffffffff   ###
  ##############################################################################
  ### Size: 4, Data type u_int32
  v_output " TX_IN[$loopcounter] Sequence (uint32_t)"
  tx_array_bytes=4
  sequence_nr=$( get_TX_section )
  tx_array_ptr=$(( $tx_array_ptr + $tx_array_bytes ))
  if [ "$sequence_nr" == "FEFFFFFF" ] || [ "$sequence_nr" == "FFFFFFFF" ] ; then
      echo "  $sequence_nr"
      echo " "
  else
    echo "*** error: expected standard sequence number (0xFFFFFFFF), found $sequence_nr"
    exit 1
  fi

  loopcounter=$(($loopcounter + 1))
done

##############################################################################
### STEP 9 - TX_OUT, Number of Transaction outputs (var_int)               ###
##############################################################################
### Size: 1 or more chars, data type var_int
### Number of Transaction outputs
### Explanation from bitcointalk.org forum: 
### A typical UTXO will have a script of the form: 
### "Tell me x and y where hash(x) = <bitcoin adr> and y is a valid signature for x". 
### To spend the UTXO, one needs to provide x and y satisfying the script, a feat 
### practically impossible without a corresponding private key. 

v_output " "
tx_array_bytes=1
proc_var_int
tx_array_ptr=$(( $tx_array_ptr + $tx_array_bytes ))
tx_out_count_dez=$( echo "ibase=16; $var_int"|bc) 
if [ "$Verbose" -eq 1 ] ; then
  echo "TX_OUT COUNT, hex=$var_int, decimal=$tx_out_count_dez"
else
  echo " $var_int"
fi

loopcounter=0
while [ $loopcounter -lt $tx_out_count_dez ]
do
  ##############################################################################
  ### TX_OUT, a data structure of 1 or more transaction outputs or destinations 
  ##############################################################################
  ### Size Description      Data type  Comments
  ###  8   value 	    uint64_t   Transaction Value
  ###  1+  pk_script length var_int    Length of the pk_script
  ###  ?   pk_script        uchar[]    Usually contains the public key as a Bitcoin 
  ###                                  script setting up conditions to claim this output. 
  v_output "TX_OUT[$loopcounter]"

  ##############################################################################
  ### STEP 10 - TX_OUT, AMOUNT: 8 Bytes hex for the amount                   ###
  ##############################################################################
  ### Size: 8 Bytes, data type uint64_t
  tx_array_bytes=8
  trx_value_hex=$( get_TX_section )
  tx_array_ptr=$(( $tx_array_ptr + $tx_array_bytes ))
  reverse=$( reverse_hex $trx_value_hex )

  trx_value_dez=$(echo "ibase=16; $reverse"|bc) 
  # try to get it in bitcoin notation
  # OpenBSD ksh and Linux bash behave different, if value is 0
  if [ $trx_value_dez -eq 0 ] ; then
    trx_value_bitcoin=0
  else
    len=${#trx_value_dez}
    if [ $len -lt 8 ] ; then
      trx_value_bitcoin="0"$(echo "scale=8; $trx_value_dez / 100000000;" | bc)
    else
      trx_value_bitcoin=$(echo "scale=8; $trx_value_dez / 100000000;" | bc)
    fi
  fi
  if [ "$Verbose" -eq 1 ] ; then
    echo " TX_OUT[$loopcounter] Value (uint64_t)"
    echo "  hex=$trx_value_hex, reversed_hex=$reverse, dec=$trx_value_dez, bitcoin=$trx_value_bitcoin"
  else
    echo "  $trx_value_hex"
  fi

  ##############################################################################
  ### STEP 11 - TX_OUT, LENGTH: Number of bytes in the PK script (var_int)   ###
  ##############################################################################
  ### Size: 1 or more chars, data type var_int
  tx_array_bytes=1
  proc_var_int
  tx_array_ptr=$(( $tx_array_ptr + $tx_array_bytes ))
  pk_script_length_hex=$var_int
  pk_script_length_dez=$( echo "ibase=16; $pk_script_length_hex"|bc) 
  if [ "$Verbose" -eq 1 ] ; then
    echo " TX_OUT[$loopcounter] PK_Script Length (var_int)"
    echo "  hex=$pk_script_length_hex, dec=$pk_script_length_dez"
  else
    echo "  $pk_script_length_hex"
  fi

  ##############################################################################
  ### STEP 12 - TX_OUT, PUBLIC KEY SCRIPT: the OP Codes of the PK script     ###
  ##############################################################################
  ### Size: 1 or more chars, data type uchar[] 
  v_output " TX_OUT[$loopcounter] pk_script (uchar[])"
  tx_array_bytes=$pk_script_length_dez
  pk_script=$( get_TX_section )
  tx_array_ptr=$(( $tx_array_ptr + $tx_array_bytes ))
  echo "  $pk_script"

  if [ "$VVerbose" -eq 1 ] && [ $pk_script_length_dez -ne 0 ] ; then
    decode_pkscript $pk_script
  fi
  loopcounter=$(($loopcounter + 1))
done

###################################################################################
### STEP 13 - LOCK_TIME: block number or timestamp, at which this trx is locked ###
###################################################################################
### Size: 4, Data type uint32_t  
###      Value        Description
###      0            Always locked
###      < 500000000  Block number at which this transaction is locked
###      >= 500000000 UNIX timestamp at which this transaction is locked
###      A non-locked transaction must not be included in blocks, and 
###      it can be modified by broadcasting a new version before the 
###      time has expired (replacement is currently disabled in Bitcoin, 
###      however, so this is useless). 
### 
if [ "$Verbose" -eq 1 ] ; then
  echo " "
  echo " LOCK_TIME"
fi
tx_array_bytes=4
result=$( get_TX_section )
echo "$result"

################################
### and here we are done :-) ### 
################################


