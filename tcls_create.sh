#!/bin/sh
# tool to create a raw, unsigned bitcoin transaction 
# 
# Copyright (c) 2015, 2016 Volker Nowarra 
# Coded in June 2016 following this reference:
#   https://en.bitcoin.it/wiki/Protocol_specification#tx
#   http://bitcoin.stackexchange.com/questions/3374/how-to-redeem-a-basic-tx
# 
# Version by      date    comment
# 0.1	  svn     13jul16 initial release from previous "trx2txt" (discontinued) code
# 0.2	  svn     20dec16 rework of fee calculation
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
#
###########################
# Some variables ...      #
###########################
Verbose=0
VVerbose=0

typeset -i i=0
prev_TX=''
RAW_TX=''
RAW_TX_LINK2HEX="?format=hex"

filename=''
typeset -r c_utx_fn=tmp_c_utx.txt   # create unsigned, raw tx file (for later signing)
typeset -r prawtx_fn=tmp_rawtx.txt  # partial raw tx file, used to extract data

typeset -i txfee_per_byte=50
typeset -i txfee_param_flag=0
typeset -i txfee=0
typeset -i c_txfee=0            # calculated trx fee
typeset -i d_txfee=0            # delta trx fee
typeset -i f_txfee=0            # file trx fee
typeset -i amount=0
typeset -i TX_amount=0
typeset -i prev_amount=0
typeset -i prev_total_amount=0
typeset -i f_param_flag=0
typeset -i m_param_flag=0
typeset -i t_param_flag=0
typeset -i std_sig_chars=90     # expected chars that need to be added, to calculate txfee

StepCode=''
typeset -i StepCode_decimal=0

#################################
# procedure to display helptext #
#################################
proc_help() {
  echo " "
  echo "usage: $0 [-h|-q|-v|-vv] -m|-t <tx_id> <params> [txfee] [ret_address]"
  echo "usage: $0 [-h|-q|-v|-vv] -f <filename> <amount> <address> [txfee] [ret_address]"
  echo " "
  echo "Create a single input transaction from command line (or multiple inputs with '-f')"
  echo " -h  show this HELP text"
  echo " -v  display Verbose output"
  echo " -vv display VERY Verbose output"
  echo " "
  echo " -f  create a TX with multiple inputs from file (use -f help for further details)"
  echo " -m  MANUALLY provide <params> for a single input and output (see below)"
  echo " -t  <TRANSACTION_ID>: fetch TX-id and pubkey script from blockchain.info"
  echo " "
  echo " <params> consists of these details (keep the order!):"
  echo "  1) <prev output index> : output index from previous TX-ID"
  echo "  2) <prev pubkey script>: (not with '-t') the PK SCRIPT from previous TX"
  echo "  3) <amount>            : the amount to spend (decimal, in Satoshi)"
  echo "                           *** careful: input - output = TX fee !!!"
  echo "  4) <address>           : the target Bitcoin address"
  echo " "
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

#################################################
# procedure to concatenate string for a raw trx #
#################################################
trx_concatenate() {
  RAW_TX=$RAW_TX$StepCode
  vv_output "$RAW_TX"
  vv_output " "
}

##########################################
# procedure to reverse a hex data string #
##########################################
# "s=s substr($0,i,1)" means that substr($0,i,1) 
# is appended to the variable s; s=s+something
reverse_hex() {
  echo $1 | awk '{ for(i=length;i!=0;i=i-2)s=s substr($0,i-1,2);}END{print s}'
} 

###########################################################
# to stay with portable code, use zero padding function ###
###########################################################
zero_pad(){
  # zero_pad <string> <length>
  [ ${#1} -lt $2 ] && printf "%0$(($2-${#1}))d" ''
  printf "%s" "$1"
}

##########################################
# procedure to check for necessary tools #
##########################################
check_tool() {
  if [ $VVerbose -eq 1 ]; then
    if [ $1 != "http_get_cmd" ] ; then
      printf " %-35s" $1
    fi
  fi
  if [ $1 == "http_get_cmd" ] ; then
    if [ $OS == "OpenBSD" ] ; then
      which ftp > /dev/null
    else
      which curl > /dev/null
    fi
  else
    which $1 > /dev/null
  fi
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

#######################################
# procedure to check even length of h #
#######################################
leading_zeros() {
  # get the length of the string h, and if not 'even', add a beginning 
  # zero. Background: we need to convert the hex characters to a hex value, 
  # and need to have an even amount of characters... 
  len=${#h}
  s=$(( $len % 2 ))
  if [ $s -ne 0 ] ; then
    h=$( echo "0$h" )
  fi
  len=${#h}
  # echo "after mod 2 calc, h=$h"
} 

#####################################################
# procedure to calculate the checksum of an address #
#####################################################
get_chksum() {
  # this is not working properly on other UNIXs, made it more portable:
  # chksum_f8=$( xxd -p -r <<<"00$h" |
  #     openssl dgst -sha256 -binary |
  #     openssl dgst -sha256 -binary |
  #     xxd -p -c 80 |
  #     head -c 8 |
  #     tr [:lower:] [:upper:] )
  # Step 4 - add network byte
  chksum_f8=$( echo "00$h" | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
  printf $chksum_f8 > tmp_plusnetworkbyte.txt
  # Step 5 - hash 256
  openssl dgst -sha256 -binary tmp_plusnetworkbyte.txt > tmp_sha256.hex
  rm tmp_plusnetworkbyte.txt
  # Step 6 - another hash 256
  openssl dgst -sha256 -binary tmp_sha256.hex > tmp_dsha256.hex
  # Step 7 - get first 4 Bytes (8 chars) as the checksum
  chksum_f8=$( od -An -t x1 tmp_dsha256.hex | tr -d [[:blank:]] | tr -d "\n" | 
               cut -b 1-8 | tr [:lower:] [:upper:] )
}

###############################################
### Check length of provided trx characters ###
###############################################
chk_trx_len() {
  if [ $VVerbose -eq 1 ]; then
    printf " check length of trx (32Bytes/64chars)"
  fi
  if [ ${#prev_TX} -ne 64 ] ; then
    echo " "
    echo "*** ERROR: expecting a proper formatted Bitcoin TRANSACTION_ID."
    echo "    Please provide a 64 bytes string (aka 32 hex chars)"
    echo "    Hint: empty lines in file are not allowed!"
    echo "    current length: ${#prev_TX}, prev_TX:"
    echo "    $prev_TX"
    exit 1 
  fi
  if [ $VVerbose -eq 1 ]; then
    printf " - yes \n" 
  fi
}

####################################################
### GET_TX_VALUES() - fetch required trx values ###
####################################################
#  if param "-t" or "-f" is given, then this shall be executed:
#    ./tcls_tx2txt.sh -vv -r $RAW_TX | grep -A7 TX_OUT[$PREV_OutPoint] > $prawtx_fn
#  It would come back with this data, where we can grep / fetch:
#  
#  1--> ### TX_OUT[1]
#       000000000001B1FC
#       ###   TRX Value[1] (uint64_t)
#  2--> hex=FCB1010000000000, reversed_hex=000000000001B1FC, dez=111100, bitcoin=0.00111100
#       ###   PK_Script Length[1] (var_int)
#  3--> hex=19, dez=25
#  4--> ###   pk_script[1] (uchar[])
#       76A9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988AC
#       ...
#  
#  1--> used to be in the right output ($PREV_OutPoint)
#  2--> used with -f flag, adding up all the amounts 
#  3--> used for STEP 5, need to grep and cut
#  4--> used for STEP 6, need to grep -A1 -B1 pk_script[$PREV_OutPoint]
#  
#
get_trx_values() {
  vv_output "./tcls_tx2txt.sh -vv -r $RAW_TX | grep -A7 TX_OUT[$PREV_OutPoint] > $prawtx_fn"
  ./tcls_tx2txt.sh -vv -r $RAW_TX | grep -A7 TX_OUT[[]$PREV_OutPoint[]] > $prawtx_fn
  #
  # is it better to use grep / cut / tr or a simple awk ???
  # awk is 30% faster, and uses only half the system udn usr CPU cycles
  #
  # prev_amount=$( grep -m1 bitcoin $prawtx_fn | cut -d "=" -f 4 | cut -d "," -f 1 )
  # STEP5_SCRIPT_LEN=$( grep -A1 -B1 pk_script $prawtx_fn | head -n1 | cut -b 7,8 )
  # STEP6_SCRIPTSIG=$( grep -A1 -B1 pk_script $prawtx_fn | tail -n1 | tr -d "[:space:]" )
  #
  prev_amount=$( awk -F "=|," '/bitcoin/ { print $6 }' $prawtx_fn )
  STEP5_SCRIPT_LEN=$( awk -F ",|=" 'NR==5 { print $2 }' $prawtx_fn )
  STEP6_SCRIPTSIG=$( awk '/pk_script/ { getline;print $1}' $prawtx_fn )
  RAW_TX=''
  vv_output "   prev_amount=$prev_amount"
  vv_output "   STEP5_SCRIPT_LEN=$STEP5_SCRIPT_LEN"
  vv_output "   STEP6_SCRIPTSIG=$STEP6_SCRIPTSIG"
  
  if [ "$prev_amount" == "" ] && [ "$STEP5_SCRIPT_LEN" == "" ] ; then 
    echo " "
    echo "*** ERROR: inconsistant data from www.blockchain.info"
    echo "           don't know how to continue without values." 
    echo "           exiting gracefully ... "
    exit 1
  fi
}

##################################
### Check bitcoin address hash ###
##################################
chk_bc_address_hash() {
  echo $s | awk -f tcls_verify_bc_address.awk > /dev/null
  if [ $? -eq 1 ] ; then
    echo "*** ERROR: invalid address: $s"
    echo "    exiting gracefully ..."
    exit 1
  fi 
  
  s=$( echo $s | awk -f tcls_verify_bc_address.awk )
  vv_output "$s"
  s=$( echo $s | sed 's/[0-9]*/ 58*&+ /g' )
  vv_output "$s"
  h=$( echo "16o0d $s +f" | dc )
  vv_output "$h"
  
  # separating the hash value (last 8 chars) of this string
  len=${#h}
  from=$(( $len - 7 ))
  chksum_l8=$( echo $h | cut -b $from-$len )
  # vv_output "chksum_l8 (last 8 chars): $chksum_l8"
  
  # checksum verification: 
  # remove last 8 chars ('the checksum'), double sha256 the string, and the 
  # first 8 chars should match the value from $chksum_l8. 
  to=$(( $len - 8 ))
  h=$( echo $h | cut -b 1-$to )
  
  # First find the length of the string, and if not 'even', add a beginning 
  # zero. Background: we need to convert the hex characters to a hex value, 
  # and need to have an even amount of characters... 
  leading_zeros
  get_chksum
  if [ "$chksum_f8" != "$chksum_l8" ] ; then
    # try max 10 iterations for leading zeros ...
    i=0
    while [ $i -lt 10 ] 
     do
      h=$( echo "0$h" )
      leading_zeros
      echo "h=$h, f8=$chksum_f8, l8=$chksum_l8"
      get_chksum
      if [ "$chksum_f8" == "$chksum_l8" ] ; then
        vv_output "calculated chksum of $h: $chksum_f8 == $chksum_l8"
        i=10
        break
      fi
      i=`expr $i + 1`
    done
    if [ "$chksum_f8" != "$chksum_l8" ] ; then
      echo "*** calculated chksum of $h: $chksum_f8 != $chksum_l8"
      echo "*** looks like an invalid bitcoin address"
      exit 1
    fi
  fi
}

step3to7() {
  ##############################################################################
  ### STEP 3 - TX_IN, previous transaction hash: 32hex = 64 chars            ###
  ##############################################################################
  v_output "###  3. TX_IN, previous transaction hash"
  vv_output "###     org trx:  $prev_TX"
  StepCode=$( reverse_hex $prev_TX )
  vv_output "###     reversed: $StepCode"
  trx_concatenate
  
  ##############################################################################
  ### STEP 4 - TX_IN, the output index we want to redeem from                ###
  ##############################################################################
  v_output "###  4. TX_IN, the output index we want to redeem from"
  StepCode=$( echo "obase=16;$PREV_OutPoint"|bc -l)
  StepCode=$( zero_pad $StepCode 8 )
  StepCode=$( reverse_hex $StepCode )
  vv_output "###            convert from $PREV_OutPoint to reversed hex: $StepCode"
  trx_concatenate
  
  ##############################################################################
  ### STEP 5 - TX_IN, scriptsig length: first hex Byte is length (2 chars)   ###
  ##############################################################################
  # For the purpose of signing the transaction, this is temporarily filled 
  # with the scriptPubKey of the output we want to redeem. 
  v_output "###  5. TX_IN, scriptsig length"
  if [ $t_param_flag -eq 0 ] ; then
    StepCode=${#PREV_PKScript}
    StepCode=$(( $StepCode / 2 ))
    StepCode=$( echo "obase=16;$StepCode"|bc ) 
  else
    vv_output "StepCode=$STEP5_SCRIPT_LEN"
    StepCode=$STEP5_SCRIPT_LEN
  fi 
  trx_concatenate
  
  ##############################################################################
  ### STEP 6 - TX_IN, signature script, uchar[] - variable length            ###
  ##############################################################################
  # the actual scriptSig (which is the scriptPubKey of the prev_TX
  v_output "###  6. TX_IN, signature script"
  if [ $t_param_flag -eq 0 ] ; then
    StepCode=$PREV_PKScript
    vv_output "$StepCode"
  else
    vv_output "StepCode=$STEP6_SCRIPTSIG"
    StepCode=$STEP6_SCRIPTSIG
  fi 
  trx_concatenate
  
  ##############################################################################
  ### STEP 7 - TX_IN, SEQUENCE: This is currently always set to 0xffffffff   ###
  ##############################################################################
  # This is currently always set to 0xffffffff
  v_output "###  7. TX_IN, concatenate sequence number (currently always 0xffffffff)"
  StepCode="ffffffff"
  trx_concatenate
}  

##############################################################################
### STEP 9 - TX_OUT, TX_amount: a 4 bytes hex (8 chars) for the amount     ###
##############################################################################
# a 8-byte reversed hex field, e.g.: 3a01000000000000"
step9() {
  v_output "###  9. TX_OUT, tx_out amount (in Satoshis): $amount"
  StepCode=$( echo "obase=16;$amount"|bc -l ) 
  StepCode=$( zero_pad $StepCode 16 )
  StepCode_rev=$( reverse_hex $StepCode ) 
  vv_output "                in hex=$StepCode, reversed=$StepCode_rev"
  StepCode=$StepCode_rev
  trx_concatenate
}

##############################################################################
### STEP 10 - TX_OUT, LENGTH: Number of bytes in the PK script (var_int)   ###
##############################################################################
# pubkey script length, we use 0x19 here ...
step10() {
  v_output "### 10. TX_OUT, LENGTH: Number of bytes in the PK script (var_int)"
  StepCode="19"
  trx_concatenate
}

##############################################################################
### STEP 11 - TX_OUT, PUBLIC KEY SCRIPT: the OP Codes of the PK script     ###
##############################################################################
# convert parameter TARGET_Address to the pubkey script.
# the P2PKH script is preceeded with "76A914" and ends with "88AC":
#
# bitcoin-tools.sh has this logic, which only works in bash. I changed
# it to be a bit more POISX compliant (also work in ksh). 
# decodeBase58() {
#     echo -n "$1" | sed -e's/^\(1*\).*/\1/' -e's/1/00/g' | tr -d '\n'
#     dc -e "$dcr 16o0$(sed 's/./ 58*l&+/g' <<<$1)p" |
#     while read n; do echo -n ${n/\\/}; done
# }
#
step11() {
  v_output "### 11. TX_OUT, PUBLIC KEY SCRIPT: the OP Codes of the PK script"
  s=$TARGET_Address 
  chk_bc_address_hash

  StepCode=$h
  StepCode=$( echo "76A914"$StepCode )
  StepCode=$( echo $StepCode"88AC")
  trx_concatenate
}

##############################
### Calculate the trx fees ###
##############################
calc_txfee() {
# ... THIS NEEDS FURTHER ANALYSIS !!!
# trx fees are calculated  with a trx fee per byte, which is changing...
# Exact length can only be determined during signing process, but here is 
# a rough calc: 
# if TX_script in this unsigned TX is 
#    P2PKH (1 input, 1 output), then sig length will be ~227 Bytes 
#    P2SH can be much longer
#    SegWit and MerkleTrees can be much shorter
# on default tx fees, proposal:
#    TX size <=   1000 bytes => use a standard txfee, or manually provided txfee
#    TX size <=   5000 bytes => use standard txfee / 2
#    TX size <=  10000 bytes => use standard txfee / 4
#    TX size <= 100000 bytes => use standard txfee / 8
# 
# calc_txfee needs to know the length of our RAW_TX
# each input requires later on a signature (length=70 Bytes/140 chars), 
# which replaces the existing PKSCRIPT (length 25 Bytes, 50 chars). 
# Each input must be signed, so roughly 90 chars signature are added ($std_sig_chars). 
# $line_items below is the current TX_IN, so if we have a multi input TX, 
# this can be more than 1, and we need a txfee calc for each UTXO 
#
# for a later improvement:
# eventually it makes sense, to verify TX_Fee calcs after the signing process?
# just to double check?
#
txfee_pb_adjusted=$txfee_per_byte
echo $RAW_TX > $c_utx_fn
TX_chars=$( wc -c $c_utx_fn | awk '{ print $1 }' )
TX_bytes=$(( $line_items * std_sig_chars + $TX_chars ))
if [ $TX_bytes -le 1000 ] ; then
  c_txfee=$(( $txfee_per_byte * $TX_bytes ))
elif [ $TX_bytes -le 10000 ] ; then
  txfee_pb_adjusted=$(( $txfee_per_byte / 2 ))
  c_txfee=$(( $txfee_pb_adjusted * $TX_bytes ))
elif [ $TX_bytes -le 100000 ] ; then
  txfee_pb_adjusted=$(( $txfee_per_byte / 3 ))
  c_txfee=$(( $txfee_pb_adjusted * $TX_bytes ))
else
  txfee_pb_adjusted=$(( $txfee_per_byte / 4 ))
  c_txfee=$(( $txfee_pb_adjusted * $TX_bytes ))
fi
}


echo "##########################################################"
echo "### tcls_create.sh: create a raw, unsigned Bitcoin trx ###"
echo "##########################################################"

################################
# command line params handling #
################################

if [ "$1" == "-h" ] ; then
  proc_help
  exit 0
fi  

if [ "$1" == "-f" ] && [ "$2" == "help" ] ; then
  echo " provide the following parameters:"
  echo " -f <filename> <amount> <address> [txfee] [ret_address]"
  echo "    <filename>:    prev trx params line by line separated by blanks, containing:"
  echo "                   prev_trx-id prev_output-index prev_pubkey-script"
  echo "    <amount>:      amount in Satoshis for the whole transaction"
  echo "    <address>:     the target address for this transaction"
  echo "    [txfee]:      numeric amount for trx fees (Satoshi/Byte), default=50 Satoshis/Byte"
  echo "    [ret_address]: a return address, to avoid spending too much trx fees to miners :-)"
  echo " "
  echo "    help:"
  echo "    blockchain.info/de/unspent?active=<address>"
  echo "    *** careful: input - output = trx fee !!!"
  echo " "
  exit 0
fi  

if [ $# -lt 3 ] ; then
  echo "insufficient parameter(s) given... "
  echo " "
  proc_help
  exit 0
else
  param_count=$#
  while [ $# -ge 1 ] 
   do
    case "$1" in
      -f)
         f_param_flag=1
         if [ $# -lt 4 ] ; then
           echo "*** you must provide correct number of parameters"
           proc_help
           exit 1
         fi
         if [ "$2" == ""  ] ; then
           echo "*** you must provide a FILENAME to the -f parameter!"
           exit 1
         fi
         filename=$2
         TX_amount=$3
         TARGET_Address=$4
         if [ $# -gt 4 ] ; then
           # if length of string $5 is more then 8 chars, then it is certainly a return address
           # can't imagine trx fees of more than a bitcoin...
           if [ ${#txfee_per_byte} -gt 8 ] ; then
             echo "RETURN_Address=$5"
             RETURN_Address=$5
           else 
             txfee_param_flag=1
             txfee_per_byte=$5
           fi
           shift 
         fi
         if [ $# -eq 5 ] ; then
           RETURN_Address=$5
           shift 
         fi
         shift 
         shift 
         shift 
         shift 
         ;;
      -m)
         m_param_flag=1
         if [ $# -lt 6 ] ; then
           echo "*** you must provide correct number of parameters"
           proc_help
           exit 1
         fi
         if [ $t_param_flag -eq 1 ] ; then
           echo "*** you cannot use -m with -t at the same time."
           echo "    Exiting gracefully ... "
           exit 1
         fi
         if [ "$2" == ""  ] ; then
           echo "*** you must provide a Bitcoin TRANSACTION_ID to the -m parameter!"
           exit 1
         fi
         prev_TX=$2
         PREV_OutPoint=$3
         PREV_PKScript=$4
         TX_amount=$5
         TARGET_Address=$6
         if [ $# -gt 6 ] ; then
           # if length of string $7 is more then 8 chars, then it is certainly a return address
           # can't imagine trx fees of more than a bitcoin...
           if [ ${#txfee_per_byte} -gt 8 ] ; then
             echo "RETURN_Address=$7"
             RETURN_Address=$7
           else 
             txfee_param_flag=1
             txfee_per_byte=$7
           fi
           shift
         fi
         if [ $# -eq 7 ] ; then
           RETURN_Address=$7
           shift
         fi
         shift 
         shift 
         shift 
         shift 
         shift 
         shift 
         ;;
      -t)
         t_param_flag=1
         if [ $# -lt 5 ] ; then
           echo "*** you must provide correct number of parameters"
           proc_help
           exit 0
         fi
         if [ $m_param_flag -eq 1 ] ; then
           echo "*** you cannot use -t with -m at the same time!"
           echo "    Exiting gracefully ... "
           exit 0
         fi
         if [ "$2" == ""  ] ; then
           echo "*** you must provide a Bitcoin TRANSACTION_ID to the -t parameter!"
           exit 0
         fi
         prev_TX=$2
         PREV_OutPoint=$3
         TX_amount=$4
         TARGET_Address=$5
         if [ $# -gt 5 ] ; then
           # if length of string $5 is more then 8 chars, then it is certainly a return address
           # can't imagine trx fees of more than a bitcoin...
           if [ ${#txfee_per_byte} -gt 8 ] ; then
             echo "RETURN_Address=$6"
             RETURN_Address=$6
           else 
             txfee_param_flag=1
             txfee_per_byte=$6
           fi
           shift
         fi
         if [ $# -eq 6 ] ; then
           RETURN_Address=$6
           shift
         fi
         shift 
         shift 
         shift 
         shift 
         shift 
         ;;
      -v)
         Verbose=1
         echo " Verbose output turned on"
         shift
         ;;
      -vv)
         Verbose=1
         VVerbose=1
         echo " VERY Verbose and Verbose output turned on"
         shift
         ;;
      *)
         echo "unknown parameter(s), don't know what to do. Exiting gracefully ..."
         proc_help
         exit 1
         ;;
    esac
  done
fi

#############################################
### Display the parameters to our program ###
#############################################
v_output " PARAM_COUNT      $param_count"
v_output " FILENAME         $filename"
v_output " prev_TX          $prev_TX"
v_output " PREV_OutPoint    $PREV_OutPoint"
v_output " PREV_PKScript    $PREV_PKScript"
v_output " TRX_AMOUNT       $TX_amount"
v_output " TARGET_Address   $TARGET_Address"
v_output " txfee_per_byte   $txfee_per_byte"
v_output " RETURN_Address   $RETURN_Address"

# verify operating system, cause 
# Linux wants to have "--posix" for their gawk program ...
# and curl is called with option "-k" - this avoids checking of certificates!
http_get_cmd="echo " 
OS=$(uname)
if [ $OS == "OpenBSD" ] ; then
  awk_cmd=awk 
  http_get_cmd="ftp -M -V -o - "
fi
if [ $OS == "Darwin" ] ; then
  awk_cmd=$(which awk) 
  http_get_cmd="curl -sS -L --insecure "
fi
if [ $OS == "Linux" ] ; then
  awk_cmd="awk --posix" 
  http_get_cmd="curl -sS -L --insecure "
fi

vv_output "##########################################"
vv_output "### Check if necessary tools are there ###"
vv_output "##########################################"
check_tool awk
check_tool bc
check_tool cut
check_tool dc
check_tool od
check_tool openssl
check_tool sed
check_tool tr
# OpenBSD uses ftp, others curl:
if [ $VVerbose -eq 1 ]; then
  printf " http_get: OpenBSD=ftp, others=curl "
fi
check_tool http_get_cmd

vv_output " "
vv_output "###################"
vv_output "### so let's go ###"
vv_output "###################"

# we have at last one line item, when using "-m", or more than one using "-f"
line_items=1
if [ "$m_param_flag" -eq 1 ] ; then
  vv_output "prev_TX=$prev_TX"
  vv_output "PREV_OutPoint=$PREV_OutPoint"
  vv_output "PREV_PKScript=$PREV_PKScript"
  vv_output "TX_amount=$TX_amount"
  vv_output "TARGET_Address=$TARGET_Address"
fi

###############################################
### Check if network is required and active ###
###############################################
# 
# if we create a trx, and param -t was given, then a 
# Bitcoin TRANSACTION_ID should be in variable "prev_TX":
# 
# now we need to:
# 1.) check if network interface is active ...
# 2.) go to the network, like this:
#     https://blockchain.info/de/rawtx/cc8a279b07...3c1ad84408?format=hex
# 3.) use OS specific calls:
#     OpenBSD: ftp -M -V -o - https://blockchain.info/de/rawtx/...
# 4.) pass everything into the variable "RAW_TX"
# 
if [ "$t_param_flag" -eq 1 ] ; then
  chk_trx_len 
  if [ $VVerbose -eq 1 ]; then
    printf " check if network is required and active (netstat and ifconfig)"
  fi
  if [ $OS == "Linux" ] ; then
    nw_if=$( netstat -rn | awk '/^0.0.0.0/ { print $NF }' | head -n1 )
    /sbin/ifstatus $nw_if | grep -q "up"
  else
    nw_if=$( netstat -rn | awk '/^default/ { print $NF }' | head -n1 )
    ifconfig $nw_if | grep -q " active"
  fi
  if [ $VVerbose -eq 1 ]; then
    printf " - yes \n going for this TRX: $prev_TX\n"
  fi
  if [ $VVerbose -eq 1 ]; then
    printf " check if we can reach www.blockchain.info (ping)" 
  fi
  ping -c1 www.blockchain.info > /dev/zero
  if [ $? -ne 0 ] ; then
    echo " "
    echo "*** ERROR: www.blockchain.info not reachable"
    echo "    verify your network settings, or assemble trx manually [-m]"
    echo "    exiting gracefully ... "
    exit 1
  else
    if [ $VVerbose -eq 1 ]; then
      printf " - yes \n fetch data from blockchain.info \n"
    fi
    RAW_TX=$( $http_get_cmd https://blockchain.info/de/rawtx/$prev_TX$RAW_TX_LINK2HEX )
    if [ $? -ne 0 ] ; then
      echo " "
      echo "*** ERROR: fetching RAW_TX data:"
      echo "    $http_get_cmd https://blockchain.info/de/rawtx/$prev_TX$RAW_TX_LINK2HEX"
      echo "    downoad manually, and call 'tcls_tx2txt.sh -r ...'"
      exit 1
    fi
    if [ ${#RAW_TX} -eq 0 ] ; then
      echo "*** ERROR: the raw trx has a length of 0. Something failed."
      echo "    downoad manually, and call 'tcls_tx2txt.sh -r ...'"
      exit 1
    fi
  fi
  get_trx_values 

  # also as a prep for later txfee calculations, we try to fetch current txfees.
  # we can only use this, if there was no parameter given for txfee!
  if [ $txfee_param_flag -eq 0 ] ; then
    txfee_per_byte=$( $http_get_cmd https://bitcoinfees.21.co/api/v1/fees/recommended | awk ' BEGIN {FS="[:}]"} { print $4 }' )
  fi
fi

##############################################################################
### STEP 1 - VERSION (8 chars) - Add four-byte version field               ###
##############################################################################
v_output " "
v_output "###  1. VERSION"
StepCode="01000000"
trx_concatenate

##############################################################################
### STEP 2 - TX_IN COUNT, One-byte varint specifying the number of inputs  ###
##############################################################################
v_output "###  2. TX_IN COUNT"
StepCode="01"
if [ "$f_param_flag" -eq 1 ] ; then
  vv_output "[-f] <FILENAME>: get data from file $filename"
  if [ -f "$filename" ] ; then
    StepCode_decimal=$( wc -l $filename | awk '{ printf "%02d", $1 }' )
    # it is better to use awk, cause cut works only with blanks, not white space.
    # so when length fields change, cut is "off":
    #   StepCode=$( wc -l test.txt | cut -d " " -f 8 )
    # convert to the decimal wc -l result to hex
    if [ $StepCode_decimal -gt 254 ] ; then
      echo "*** not yet prepared to work with very big numbers."
      echo "    need to wait for next release - sorry!"
      echo "    exiting gracefully"
      exit 1
    fi
    if [ $StepCode_decimal -lt 10 ] ; then
      StepCode=0$( echo "obase=16;$StepCode_decimal"|bc ) 
    else
      StepCode=$( echo "obase=16;$StepCode_decimal"|bc ) 
    fi   
    vv_output "lines in file equals trx inputs: $StepCode_decimal, hex: 0x$StepCode"
  else
    echo "*** ERROR: file $filename does not exist"
    echo " "
    exit 1
  fi
fi
trx_concatenate

############################
### TX_IN: call STEP 3-7 ### 
############################
if [ "$f_param_flag" -eq 1 ] ; then
  # each line item is a references to the previous transaction:
  # prev_TX      --> the trx number
  # PREV_OutPoint --> the outpoint, from which to spend 
  # PREV_PKScript --> the corresponding public key script
  # prev_amount   --> and the amount from all inputs
  # if only prev_TX is given, need to connect to network and do s.th. like
  # listunspend(trx_number) ?
  while IFS=" " read prev_TX PREV_OutPoint PREV_PKScript prev_amount
   do
    # for every line item we need to check the trx, and get the values:
    chk_trx_len 
    # if only prev_TX is given, we could fetch remaining items with 'get_trx_values' ?
    v_output "####### TX_IN: line item $line_items"
    vv_output "        prev_TX=$prev_TX"
    vv_output "        PREV_OutPoint=$PREV_OutPoint"
    vv_output "        PREV_PKScript=$PREV_PKScript"
    vv_output "        prev_amount=$prev_amount"
    step3to7 
    line_items=$(( $line_items + 1 ))
    prev_total_amount=$(( $prev_total_amount + $prev_amount ))
  done <"$filename"
  line_items=$(( $line_items - 1 ))
else
  step3to7
fi

##############################################################################
### STEP 8 - TX_OUT, Number of Transaction outputs (var_int)               ###
##############################################################################
# This is per default set to 1 
# if we have a return address (which is between 28 and 32 chars...), 
# then add another tx_out, otherwise miners get happy :-)
v_output "###  8. TX_OUT, Number of Transaction outputs (var_int)"
if [ ${#RETURN_Address} -gt 28 ] ; then
  StepCode="02"
else
  StepCode="01"
fi 
trx_concatenate

##############################
### TX_OUT: call STEP 9-11 ### 
##############################
# this is for the first TX_out 
amount=$TX_amount
step9
step10
step11

############################################
### TX_OUT: if there is a return address ###
############################################
# if we have a return address (which is between 28 and 32 chars...), 
# then make sure, money gets back to us ... so we add a second address in TX_out
# but before, we need to calculate txfees, and deduct the return amounts 
calc_txfee
if [ "$f_param_flag" -eq 1 ] ; then
  d_txfee=$(( $prev_total_amount - $TX_amount - $c_txfee ))
fi
if [ "$t_param_flag" -eq 1 ] ; then
  d_txfee=$(( $prev_amount - $TX_amount - $c_txfee ))
fi
if [ ${#RETURN_Address} -gt 28 ] ; then
  amount=$d_txfee 
  step9
  step10
  TARGET_Address=$RETURN_Address
  step11
fi 

############################################################################
### STEP 12 - LOCK_TIME: block nor timestamp at which this trx is locked ###
############################################################################
v_output "### 12. LOCK_TIME: block or timestamp at which this trx is locked"
StepCode="00000000" 
trx_concatenate

##############################################################################
### STEP 13 - HASH CODE TYPE                                               ###
##############################################################################
v_output "### 13. HASH CODE TYPE"
StepCode="01000000" 
trx_concatenate
echo $RAW_TX > $c_utx_fn

##############################################################################
### Finished, presenting results ...                                       ###
##############################################################################
echo " "

##########################################
### verifying input and output amounts ###
##########################################

echo "###########################################################################"
echo "### amount(tx_in) - amount(tx_out) = TRXFEEs. *Double check YOUR MATH!* ###"
if [ "$t_param_flag" -eq 1 ] ; then
  printf "### amount of trx input(s) (in Satoshis):              %16d ###\n" $prev_amount
  if [ $prev_amount -lt $TX_amount ] ; then
    echo "*** ERROR: input insufficient, please verify amount(s)."
    echo " "
    exit 0 
  fi
fi
if [ "$f_param_flag" -eq 1 ] ; then
  printf "### amount of trx input(s) (in Satoshis):              %16d ###\n" $prev_total_amount
  printf "### desired amount to spend (in Satoshis):             %16d ###\n" $TX_amount
  if [ $prev_total_amount -lt $TX_amount ] ; then
    echo "*** ERROR: input insufficient, please verify amount(s)."
    echo " "
    exit 0 
  fi
else
  printf "### amount to spend (trx_output, in Satoshis):         %16d ###\n" $TX_amount
fi

#########################
### checking TRX FEEs ###
#########################
calc_txfee
printf "### proposed TX-FEE (@ $txfee_pb_adjusted Satoshi/Byte * $TX_bytes TX_bytes):"
line_length=$(( ${#txfee_pb_adjusted} + ${#TX_bytes} ))
case $line_length in
 5) printf "      %10d" $c_txfee
    ;;
 6) printf "     %10d" $c_txfee
    ;;
 7) printf "    %10d" $c_txfee
    ;;
 8) printf "   %10d" $c_txfee
    ;;
 9) printf "  %10d" $c_txfee
    ;;
esac
printf " ###\n" $c_txfee

if [ "$f_param_flag" -eq 1 ] ; then
  f_txfee=$(( $prev_total_amount - $TX_amount ))
  d_txfee=$(( $prev_total_amount - $TX_amount - $c_txfee ))
  if [ $d_txfee -lt 0 ] ; then
    printf "### Achieving negative value with this txfee:          %16d ###\n" $d_txfee 
    echo "*** ERROR: input insufficient, to cover trx fees, exiting gracefully ..." 
    echo " "
    exit 0
  else
    if [ ${#RETURN_Address} -gt 28 ] ; then
      printf "### value to return address:                           %16d ###\n" $d_txfee 
    else
      printf "### *** possible value to return address:              %16d ###\n" $d_txfee 
      printf "### *** without return address, txfee will be:         %16d ###\n" $f_txfee 
    fi
  fi
fi

if [ "$t_param_flag" -eq 1 ] ; then
  f_txfee=$(( $prev_amount - $TX_amount ))
  d_txfee=$(( $prev_amount - $TX_amount - $c_txfee ))
  if [ $d_txfee -lt 0 ] ; then
    printf "### Achieving negative value with this txfee:          %16d ###\n" $d_txfee 
    echo "*** ERROR: input insufficient, to cover trx fees, exiting gracefully ..." 
    echo " "
    exit 0
  else
    if [ ${#RETURN_Address} -gt 28 ] ; then
      printf "### value to return address:                           %16d ###\n" $d_txfee 
    else
      printf "### *** possible value to return address:              %16d ###\n" $d_txfee 
      printf "### *** without return address, txfee will be:         %16d ###\n" $f_txfee 
    fi
  fi
fi

echo "###########################################################################"
echo " "
echo "$RAW_TX" | tr [:upper:] [:lower:] > $c_utx_fn
echo "*** DOUBLE CHECK YOUR MATH! *** "
echo "File '$c_utx_fn' contains the unsigned raw transaction. If *YOUR MATH*"
echo "is ok, then take this file on a clean USB stick to the cold storage"
echo "(second computer), and sign it there."
echo " "
echo "... before doing so, you may want to check the output with:"
echo "./tcls_tx2txt.sh -vv -f $c_utx_fn -u"
echo " "

################################
### and here we are done :-) ### 
################################

if [ -f tmp_sha256.hex ];  then rm tmp_sha256.hex  ; fi
if [ -f tmp_dsha256.hex ]; then rm tmp_dsha256.hex ; fi


