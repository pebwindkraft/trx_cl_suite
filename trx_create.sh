#!/bin/sh
# tool to create a raw, unsigned bitcoin transaction 
# 
# Copyright (c) 2015, 2016 Volker Nowarra 
# Coded in June 2016 following this reference:
#   https://en.bitcoin.it/wiki/Protocol_specification#tx
#   http://bitcoin.stackexchange.com/questions/3374/how-to-redeem-a-basic-tx
# 
# Version	by      date    comment
# 0.1		svn     13jul16 initial release from previous "trx2txt" (discontinued) code
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
VERBOSE=0
VVERBOSE=0

typeset -i i=0
PREV_TRX=''
RAW_TRX=''
RAW_TRX_LINK2HEX="?format=hex"

filename=''
typeset -r urtx_fn=tmp_urtx.txt
typeset -r rawtx_fn=tmp_rawtx.txt

typeset -i prev_total_amount=0
typeset -i TRXFEE_Per_Bytes=50
typeset -i trxfee=0
typeset -i c_trxfee=0            # calculated trx fee
typeset -i d_trxfee=0            # delta trx fee
typeset -i f_trxfee=0            # file trx fee
typeset -i Amount=0
typeset -i TRX_Amount=0
typeset -i PREV_Amount=0
typeset -i F_PARAM_FLAG=0
typeset -i M_PARAM_FLAG=0
typeset -i T_PARAM_FLAG=0

STEPCODE=''
typeset -i STEPCODE_decimal=0

#################################
# procedure to display helptext #
#################################
proc_help() {
  echo " "
  echo "usage: $0 [-h|-q|-v|-vv] -m|-t <trx_id> <params> [trxfee] [ret_address]"
  echo "usage: $0 [-h|-q|-v|-vv] -f <filename> <amount> <address> [trxfee] [ret_address]"
  echo " "
  echo "Create a single input transaction from command line (or multiple inputs with '-f')"
  echo " -h  show this HELP text"
  echo " -v  display VERBOSE output"
  echo " -vv display VERY VERBOSE output"
  echo " "
  echo " -f  create a trx with multiple inputs from file (use -f help for further details)"
  echo " -m  MANUALLY provide <params> for a single input and output (see below)"
  echo " -t  <TRANSACTION_ID>: fetch trx_id and pubkey script from blockchain.info"
  echo " "
  echo " <params> consists of these details (keep the order!):"
  echo "  1) <prev output index> : output index from previous TRX_ID"
  echo "  2) <prev pubkey script>: (not with '-t') the PK SCRIPT from previous TRX"
  echo "  3) <amount>            : the amount to spend (decimal, in Satoshi)"
  echo "                           *** careful: input - output = trx fee !!!"
  echo "  4) <address>           : the target Bitcoin address"
  echo " "
}

#######################################
# procedure to display verbose output #
#######################################
v_output() {
  if [ $VERBOSE -eq 1 ] ; then
    echo "$1"
  fi
}

#################################################
# procedure to display even more verbose output #
#################################################
vv_output() {
  if [ $VVERBOSE -eq 1 ] ; then
    echo "$1"
  fi
}

#################################################
# procedure to concatenate string for raw trx   #
#################################################
trx_concatenate() {
  RAW_TRX=$RAW_TRX$STEPCODE
  vv_output "$RAW_TRX"
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
  if [ $VVERBOSE -eq 1 ]; then
    printf " %-8s" $1
  fi
  which $1 > /dev/null
  if [ $? -eq 0 ]; then
    if [ $VVERBOSE -eq 1 ]; then
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
  printf $chksum_f8 > tmpfile
  # Step 5 - hash 256
  openssl dgst -sha256 -binary tmpfile > tmpfile1
  # Step 6 - another hash 256
  openssl dgst -sha256 -binary tmpfile1 > tmpfile
  # Step 7 - get first 4 Bytes (8 chars) as the checksum
  chksum_f8=$( od -An -t x1 tmpfile | tr -d [[:blank:]] | tr -d "\n" | 
               cut -b 1-8 | tr [:lower:] [:upper:] )
}

###############################################
### Check length of provided trx characters ###
###############################################
chk_trx_len() {
  if [ $VVERBOSE -eq 1 ]; then
    printf " check length of trx (32Bytes/64chars)"
  fi
  if [ ${#PREV_TRX} -ne 64 ] ; then
    echo " "
    echo "*** ERROR: expecting a proper formatted Bitcoin TRANSACTION_ID."
    echo "    Please provide a 64 bytes string (aka 32 hex chars)"
    echo "    Hint: empty lines in file are not allowed!"
    echo "    current length: ${#PREV_TRX}, PREV_TRX:"
    echo "    $PREV_TRX"
    exit 1 
  fi
  if [ $VVERBOSE -eq 1 ]; then
    printf " - yes \n" 
  fi
}

####################################################
### GET_TRX_VALUES() - fetch required trx values ###
####################################################
#  if param "-t" or "-f" is given, then this shall be executed:
#    ./trx_2txt.sh -vv -r $RAW_TRX | grep -A7 TX_OUT[$PREV_OutPoint] > $rawtx_fn
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
  vv_output "./trx_2txt.sh -vv -r $RAW_TRX | grep -A7 TX_OUT[$PREV_OutPoint] > $rawtx_fn"
  ./trx_2txt.sh -vv -r $RAW_TRX | grep -A7 TX_OUT[[]$PREV_OutPoint[]] > $rawtx_fn
  #
  # is it better to use grep / cut / tr or a simple awk ???
  # awk is 30% faster, and uses only half the system udn usr CPU cycles
  #
  # PREV_Amount=$( grep -m1 bitcoin $rawtx_fn | cut -d "=" -f 4 | cut -d "," -f 1 )
  # STEP5_SCRIPT_LEN=$( grep -A1 -B1 pk_script $rawtx_fn | head -n1 | cut -b 7,8 )
  # STEP6_SCRIPTSIG=$( grep -A1 -B1 pk_script $rawtx_fn | tail -n1 | tr -d "[:space:]" )
  #
  PREV_Amount=$( awk -F "=|," '/bitcoin/ { print $6 }' $rawtx_fn )
  STEP5_SCRIPT_LEN=$( awk -F ",|=" 'NR==5 { print $2 }' $rawtx_fn )
  STEP6_SCRIPTSIG=$( awk '/pk_script/ { getline;print $1}' $rawtx_fn )
  RAW_TRX=''
  vv_output "   PREV_Amount=$PREV_Amount"
  vv_output "   STEP5_SCRIPT_LEN=$STEP5_SCRIPT_LEN"
  vv_output "   STEP6_SCRIPTSIG=$STEP6_SCRIPTSIG"
  
  if [ "$PREV_Amount" == "" ] && [ "$STEP5_SCRIPT_LEN" == "" ] ; then 
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
  echo $s | awk -f trx_verify_bc_address.awk > /dev/null
  if [ $? -eq 1 ] ; then
    echo "*** ERROR: invalid address: $s"
    echo "    exiting gracefully ..."
    exit 1
  fi 
  
  # s=$( echo $s | awk -f trx_base58.awk )
  s=$( echo $s | awk -f trx_verify_bc_address.awk )
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
  vv_output "###     org trx:  $PREV_TRX"
  STEPCODE=$( reverse_hex $PREV_TRX )
  vv_output "###     reversed: $STEPCODE"
  trx_concatenate
  
  ##############################################################################
  ### STEP 4 - TX_IN, the output index we want to redeem from                ###
  ##############################################################################
  v_output "###  4. TX_IN, the output index we want to redeem from"
  STEPCODE=$( echo "obase=16;$PREV_OutPoint"|bc -l)
  STEPCODE=$( zero_pad $STEPCODE 8 )
  STEPCODE=$( reverse_hex $STEPCODE )
  vv_output "###            convert from $PREV_OutPoint to reversed hex: $STEPCODE"
  trx_concatenate
  
  ##############################################################################
  ### STEP 5 - TX_IN, scriptsig length: first hex Byte is length (2 chars)   ###
  ##############################################################################
  # For the purpose of signing the transaction, this is temporarily filled 
  # with the scriptPubKey of the output we want to redeem. 
  v_output "###  5. TX_IN, scriptsig length"
  if [ $T_PARAM_FLAG -eq 0 ] ; then
    STEPCODE=${#PREV_PKScript}
    STEPCODE=$(( $STEPCODE / 2 ))
    STEPCODE=$( echo "obase=16;$STEPCODE"|bc ) 
  else
    vv_output "STEPCODE=$STEP5_SCRIPT_LEN"
    STEPCODE=$STEP5_SCRIPT_LEN
  fi 
  trx_concatenate
  
  ##############################################################################
  ### STEP 6 - TX_IN, signature script, uchar[] - variable length            ###
  ##############################################################################
  # the actual scriptSig (which is the scriptPubKey of the PREV_TRX
  v_output "###  6. TX_IN, signature script"
  if [ $T_PARAM_FLAG -eq 0 ] ; then
    STEPCODE=$PREV_PKScript
    vv_output "$STEPCODE"
  else
    vv_output "STEPCODE=$STEP6_SCRIPTSIG"
    STEPCODE=$STEP6_SCRIPTSIG
  fi 
  trx_concatenate
  
  ##############################################################################
  ### STEP 7 - TX_IN, SEQUENCE: This is currently always set to 0xffffffff   ###
  ##############################################################################
  # This is currently always set to 0xffffffff
  v_output "###  7. TX_IN, concatenate sequence number (currently always 0xffffffff)"
  STEPCODE="ffffffff"
  trx_concatenate
}  

##############################################################################
### STEP 9 - TX_OUT, TRX_Amount: a 4 bytes hex (8 chars) for the amount   ###
##############################################################################
# a 8-byte reversed hex field, e.g.: 3a01000000000000"
step9() {
  v_output "###  9. TX_OUT, trx_out amount (in Satoshis): $Amount"
  STEPCODE=$( echo "obase=16;$Amount"|bc -l ) 
  STEPCODE=$( zero_pad $STEPCODE 16 )
  STEPCODE_rev=$( reverse_hex $STEPCODE ) 
  vv_output "                in hex=$STEPCODE, reversed=$STEPCODE_rev"
  STEPCODE=$STEPCODE_rev
  trx_concatenate
}

##############################################################################
### STEP 10 - TX_OUT, LENGTH: Number of bytes in the PK script (var_int)   ###
##############################################################################
# pubkey script length, we use 0x19 here ...
step10() {
  v_output "### 10. TX_OUT, LENGTH: Number of bytes in the PK script (var_int)"
  STEPCODE="19"
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

  STEPCODE=$h
  STEPCODE=$( echo "76A914"$STEPCODE )
  STEPCODE=$( echo $STEPCODE"88AC")
  trx_concatenate
}

##############################
### Calculate the trx fees ###
##############################
calc_trxfee() {
# calc_trxfee needs to know the length of our RAW_TRX
# we drop here, whatever we have so far ...
echo $RAW_TRX > $urtx_fn
trx_chars=$( wc -c $urtx_fn | awk '{ print $1 }' )
trx_bytes=$(( $line_item * 90 + $trx_chars ))
c_trxfee=$(( $TRXFEE_Per_Bytes * $trx_bytes ))
}


echo "#########################################################"
echo "### trx_create.sh: create a raw, unsigned Bitcoin trx ###"
echo "#########################################################"

################################
# command line params handling #
################################

if [ "$1" == "-h" ] ; then
  proc_help
  exit 0
fi  

if [ "$1" == "-f" ] && [ "$2" == "help" ] ; then
  echo " provide the following parameters:"
  echo " -f <filename> <amount> <address> [trxfee] [ret_address]"
  echo "    <filename>:    prev trx params line by line separated by blanks, containing:"
  echo "                   prev_trx-id prev_output-index prev_pubkey-script"
  echo "    <amount>:      amount in Satoshis for the whole transaction"
  echo "    <address>:     the target address for this transaction"
  echo "    [trxfee]:      numeric amount for trx fees (Satoshi/Byte), default=50 Satoshis/Byte"
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
         F_PARAM_FLAG=1
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
         TRX_Amount=$3
         TARGET_Address=$4
         if [ $# -gt 4 ] ; then
           TRXFEE_Per_Bytes=$5
           # if length of string $5 is more then 8 chars, then it is certainly a return address
           # can't imagine trx fees of more than a bitcoin...
           if [ ${#TRXFEE_Per_Bytes} -gt 8 ] ; then
             echo "RETURN_Address=$5"
             RETURN_Address=$5
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
         shift 
         ;;
      -m)
         M_PARAM_FLAG=1
         if [ $# -lt 6 ] ; then
           echo "*** you must provide correct number of parameters"
           proc_help
           exit 1
         fi
         if [ $T_PARAM_FLAG -eq 1 ] ; then
           echo "*** you cannot use -m with -t at the same time."
           echo "    Exiting gracefully ... "
           exit 1
         fi
         if [ "$2" == ""  ] ; then
           echo "*** you must provide a Bitcoin TRANSACTION_ID to the -m parameter!"
           exit 1
         fi
         PREV_TRX=$2
         PREV_OutPoint=$3
         PREV_PKScript=$4
         TRX_Amount=$5
         TARGET_Address=$6
         if [ $# -gt 6 ] ; then
           TRXFEE_Per_Bytes=$7
           # if length of string $7 is more then 8 chars, then it is certainly a return address
           # can't imagine trx fees of more than a bitcoin...
           if [ ${#TRXFEE_Per_Bytes} -gt 8 ] ; then
             echo "RETURN_Address=$7"
             RETURN_Address=$7
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
         T_PARAM_FLAG=1
         if [ $# -lt 5 ] ; then
           echo "*** you must provide correct number of parameters"
           proc_help
           exit 0
         fi
         if [ $M_PARAM_FLAG -eq 1 ] ; then
           echo "*** you cannot use -t with -m at the same time!"
           echo "    Exiting gracefully ... "
           exit 0
         fi
         if [ "$2" == ""  ] ; then
           echo "*** you must provide a Bitcoin TRANSACTION_ID to the -t parameter!"
           exit 0
         fi
         PREV_TRX=$2
         PREV_OutPoint=$3
         TRX_Amount=$4
         TARGET_Address=$5
         if [ $# -gt 5 ] ; then
           TRXFEE_Per_Bytes=$6
           # if length of string $5 is more then 8 chars, then it is certainly a return address
           # can't imagine trx fees of more than a bitcoin...
           if [ ${#TRXFEE_Per_Bytes} -gt 8 ] ; then
             echo "RETURN_Address=$6"
             RETURN_Address=$6
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
         VERBOSE=1
         echo " VERBOSE output turned on"
         shift
         ;;
      -vv)
         VERBOSE=1
         VVERBOSE=1
         echo " VERY VERBOSE and VERBOSE output turned on"
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
v_output " PREV_TRX         $PREV_TRX"
v_output " PREV_OutPoint    $PREV_OutPoint"
v_output " PREV_PKScript    $PREV_PKScript"
v_output " TRX_AMOUNT       $TRX_Amount"
v_output " TARGET_Address   $TARGET_Address"
v_output " TRXFEE_Per_Bytes $TRXFEE_Per_Bytes"
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
check_tool curl
check_tool cut
check_tool dc
check_tool od
check_tool openssl
check_tool sed
check_tool tr

vv_output " "
vv_output "###################"
vv_output "### so let's go ###"
vv_output "###################"

# we have at last one line item, when using "-m", or more than one using "-f"
line_item=1
if [ "$M_PARAM_FLAG" -eq 1 ] ; then
  vv_output "PREV_TRX=$PREV_TRX"
  vv_output "PREV_OutPoint=$PREV_OutPoint"
  vv_output "PREV_PKScript=$PREV_PKScript"
  vv_output "TRX_Amount=$TRX_Amount"
  vv_output "TARGET_Address=$TARGET_Address"
fi

###############################################
### Check if network is required and active ###
###############################################
# 
# if we create a trx, and param -t was given, then a 
# Bitcoin TRANSACTION_ID should be in variable "PREV_TRX":
# 
# now we need to:
# 1.) check if network interface is active ...
# 2.) go to the network, like this:
#     https://blockchain.info/de/rawtx/cc8a279b07...3c1ad84408?format=hex
# 3.) use OS specific calls:
#     OpenBSD: ftp -M -V -o - https://blockchain.info/de/rawtx/...
# 4.) pass everything into the variable "RAW_TRX"
# 
if [ "$T_PARAM_FLAG" -eq 1 ] ; then
  chk_trx_len 
  if [ $VVERBOSE -eq 1 ]; then
    printf " check if network is required and active (netstat and ifconfig)"
  fi
  if [ $OS == "Linux" ] ; then
    nw_if=$( netstat -rn | awk '/^0.0.0.0/ { print $NF }' | head -n1 )
    ifstatus $nw_if | grep -q "up"
  else
    nw_if=$( netstat -rn | awk '/^default/ { print $NF }' | head -n1 )
    ifconfig $nw_if | grep -q " active"
  fi
  if [ $VVERBOSE -eq 1 ]; then
    printf " - yes \n going for this TRX: $PREV_TRX\n"
  fi
  if [ $VVERBOSE -eq 1 ]; then
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
    if [ $VVERBOSE -eq 1 ]; then
      printf " - yes \n fetch data from blockchain.info with $http_get_cmd \n"
    fi
    RAW_TRX=$( $http_get_cmd https://blockchain.info/de/rawtx/$PREV_TRX$RAW_TRX_LINK2HEX )
    if [ $? -ne 0 ] ; then
      echo " "
      echo "*** ERROR: fetching RAW_TRX data:"
      echo "    $http_get_cmd https://blockchain.info/de/rawtx/$PREV_TRX$RAW_TRX_LINK2HEX"
      echo "    downoad manually, and call 'trx_2txt -r ...'"
      exit 1
    fi
    if [ ${#RAW_TRX} -eq 0 ] ; then
      echo "*** ERROR: the raw trx has a length of 0. Something failed."
      echo "    downoad manually, and call 'trx_2txt -r ...'"
      exit 1
    fi
  fi
  get_trx_values 
fi

##############################################################################
### STEP 1 - VERSION (8 chars) - Add four-byte version field               ###
##############################################################################
v_output " "
v_output "###  1. VERSION"
STEPCODE="01000000"
trx_concatenate

##############################################################################
### STEP 2 - TX_IN COUNT, One-byte varint specifying the number of inputs  ###
##############################################################################
v_output "###  2. TX_IN COUNT"
STEPCODE="01"
if [ "$F_PARAM_FLAG" -eq 1 ] ; then
  vv_output "[-f] <FILENAME>: get data from file $filename"
  if [ -f "$filename" ] ; then
    STEPCODE_decimal=$( wc -l $filename | awk '{ printf "%02d", $1 }' )
    # it is better to use awk, cause cut works only with blanks, not white space.
    # so when length fields change, cut is "off":
    #   STEPCODE=$( wc -l test.txt | cut -d " " -f 8 )
    # convert to the decimal wc -l result to hex
    if [ $STEPCODE_decimal -gt 254 ] ; then
      echo "*** not yet prepared to work with very big numbers."
      echo "    need to wait for next release - sorry!"
      echo "    exiting gracefully"
      exit 1
    fi
    if [ $STEPCODE_decimal -lt 10 ] ; then
      STEPCODE=0$( echo "obase=16;$STEPCODE_decimal"|bc ) 
    else
      STEPCODE=$( echo "obase=16;$STEPCODE_decimal"|bc ) 
    fi   
    vv_output "lines in file equals trx inputs: $STEPCODE_decimal, hex: 0x$STEPCODE"
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
if [ "$F_PARAM_FLAG" -eq 1 ] ; then
  # each line item is a references to the previous transaction:
  # PREV_TRX      --> the trx number
  # PREV_OutPoint --> the outpoint, from which to spend 
  # PREV_PKScript --> the corresponding public key script
  # PREV_Amount   --> and the amount from all inputs
  # if only PREV_TRX is given, need to connect to network and do s.th. like
  # listunspend(trx_number) ?
  while IFS=" " read PREV_TRX PREV_OutPoint PREV_PKScript PREV_Amount
   do
    # for every line item we need to check the trx, and get the values:
    chk_trx_len 
    # if only PREV_TRX is given, then we can fetch remaining items with 'get_trx_values' ?
    v_output "####### TX_IN: line item $line_item"
    vv_output "        PREV_TRX=$PREV_TRX"
    vv_output "        PREV_OutPoint=$PREV_OutPoint"
    vv_output "        PREV_PKScript=$PREV_PKScript"
    vv_output "        PREV_Amount=$PREV_Amount"
    step3to7 
    line_item=$(( $line_item + 1 ))
    prev_total_amount=$(( $prev_total_amount + $PREV_Amount ))
  done <"$filename"
  line_item=$(( $line_item - 1 ))
else
  step3to7
fi

##############################################################################
### STEP 8 - TX_OUT, Number of Transaction outputs (var_int)               ###
##############################################################################
# This is per default set to 1 
# if we have a return address (which is between 28 and 32 chars...), 
# then add another tx_out, otherwise miners get happy :-)
v_output "###  8. TX_OUT, Number of Transaction outputs (var_int)"
if [ ${#RETURN_Address} -gt 28 ] ; then
  STEPCODE="02"
else
  STEPCODE="01"
fi 
trx_concatenate

##############################
### TX_OUT: call STEP 9-11 ### 
##############################
Amount=$TRX_Amount
step9
step10
step11

############################################
### TX_OUT: if there is a return address ###
############################################
# if we have a return address (which is between 28 and 32 chars...), 
# then make sure, money gets back to us ...
# but before, we need to calculate trxfees, and deduct the return amounts ...
calc_trxfee
if [ "$F_PARAM_FLAG" -eq 1 ] ; then
  d_trxfee=$(( $prev_total_amount - $TRX_Amount - $c_trxfee ))
fi
if [ "$T_PARAM_FLAG" -eq 1 ] ; then
  d_trxfee=$(( $PREV_Amount - $TRX_Amount - $c_trxfee ))
fi
if [ ${#RETURN_Address} -gt 28 ] ; then
  Amount=$d_trxfee 
  step9
  step10
  TARGET_Address=$RETURN_Address
  step11
fi 

############################################################################
### STEP 12 - LOCK_TIME: block nor timestamp at which this trx is locked ###
############################################################################
v_output "### 12. LOCK_TIME: block or timestamp at which this trx is locked"
STEPCODE="00000000" 
trx_concatenate

##############################################################################
### STEP 13 - HASH CODE TYPE                                               ###
##############################################################################
v_output "### 13. HASH CODE TYPE"
STEPCODE="01000000" 
trx_concatenate
echo $RAW_TRX > $urtx_fn

##############################################################################
### Finished, presenting results ...                                       ###
##############################################################################
echo " "

##########################################
### verifying input and output amounts ###
##########################################

echo "###########################################################################"
echo "### amount(tx_in) - amount(tx_out) = TRXFEEs. *Double check YOUR MATH!* ###"
if [ "$T_PARAM_FLAG" -eq 1 ] ; then
  printf "### amount of trx input(s) (in Satoshis):              %16d ###\n" $PREV_Amount
  if [ $PREV_Amount -lt $TRX_Amount ] ; then
    echo "*** ERROR: input insufficient, please verify amount(s)."
    echo " "
    exit 0 
  fi
fi
if [ "$F_PARAM_FLAG" -eq 1 ] ; then
  printf "### amount of trx input(s) (in Satoshis):              %16d ###\n" $prev_total_amount
  printf "### desired amount to spend (in Satoshis):             %16d ###\n" $TRX_Amount
  if [ $prev_total_amount -lt $TRX_Amount ] ; then
    echo "*** ERROR: input insufficient, please verify amount(s)."
    echo " "
    exit 0 
  fi
else
  printf "### amount to spend (trx_output, in Satoshis):         %16d ###\n" $TRX_Amount
fi

#########################
### checking TRX FEEs ###
#########################
# trx fees are calculated  with a trx fee per byte, which is changing...
# currently in Sep 2016 it is roughly 50 Satoshis per Byte. Exact length can only 
# be determined during signing process, but here is a rough calc: each input 
# requires later on a signature (length=70 Bytes/140 chars), which replaces 
# the existing PKSCRIPT (length 25 Bytes, 50 chars). Each input must be signed, 
# so roughly 90 chars signature are added. Normal 1 input one output P2PKH trx are 
# roughly 227 Bytes ... THIS NEEDS FURTHER ANALYSIS !!!
calc_trxfee

printf "### proposed TRXFEE (@ $TRXFEE_Per_Bytes Satoshi/Byte * $trx_bytes trx_bytes):"
line_length=$(( ${#TRXFEE_Per_Bytes} + ${#trx_bytes} ))
case $line_length in
 5) printf "     %10d" $c_trxfee
    ;;
 6) printf "    %10d" $c_trxfee
    ;;
 7) printf "   %10d" $c_trxfee
    ;;
 8) printf "  %10d" $c_trxfee
    ;;
 9) printf " %10d" $c_trxfee
    ;;
esac
printf " ###\n" $c_trxfee

if [ "$F_PARAM_FLAG" -eq 1 ] ; then
  f_trxfee=$(( $prev_total_amount - $TRX_Amount ))
  # d_trxfee=$(( $prev_total_amount - $TRX_Amount - $c_trxfee ))
  if [ $d_trxfee -lt 0 ] ; then
    printf "### Achieving negative value with this trxfee:         %16d ###\n" $d_trxfee 
    echo "*** ERROR: input insufficient, to cover trx fees, exiting gracefully ..." 
    echo " "
    exit 0
  else
    if [ ${#RETURN_Address} -gt 28 ] ; then
      printf "### value to return address:                           %16d ###\n" $d_trxfee 
    else
      printf "### *** possible value to return address:              %16d ###\n" $d_trxfee 
      printf "### *** without return address, trxfee will be:        %16d ###\n" $f_trxfee 
    fi
  fi
fi

if [ "$T_PARAM_FLAG" -eq 1 ] ; then
  f_trxfee=$(( $PREV_Amount - $TRX_Amount ))
  # d_trxfee=$(( $PREV_Amount - $TRX_Amount - $c_trxfee ))
  if [ $d_trxfee -lt 0 ] ; then
    printf "### Achieving negative value with this trxfee:         %16d ###\n" $d_trxfee 
    echo "*** ERROR: input insufficient, to cover trx fees, exiting gracefully ..." 
    echo " "
    exit 0
  else
    if [ ${#RETURN_Address} -gt 28 ] ; then
      printf "### value to return address:                           %16d ###\n" $d_trxfee 
    else
      printf "### *** possible value to return address:              %16d ###\n" $d_trxfee 
      printf "### *** without return address, trxfee will be:        %16d ###\n" $f_trxfee 
    fi
  fi
fi

echo "###########################################################################"
echo " "
echo "$RAW_TRX" | tr [:upper:] [:lower:] > $urtx_fn
echo "*** DOUBLE CHECK YOUR MATH! *** "
echo "File '$urtx_fn' contains the unsigned raw transaction. If *YOUR MATH*"
echo "is ok, then take this file on a clean USB stick to the cold storage"
echo "(second computer), and sign it there."
echo " "
echo "you may check output with:"
echo "./trx_2txt.sh -vv -u $RAW_TRX" | tr [:upper:] [:lower:] 
echo " "

################################
### and here we are done :-) ### 
################################

