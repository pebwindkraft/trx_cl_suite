#!/bin/sh
# tool to create a raw, unsigned bitcoin transaction or msig addresses and redeem script
# 
# Copyright (c) 2015, 2016 Volker Nowarra 
# Coded in June 2016 following this reference:
#   https://en.bitcoin.it/wiki/Protocol_specification#tx
#   http://bitcoin.stackexchange.com/questions/3374/how-to-redeem-a-basic-tx
# 
# Version by      date    comment
# 0.1	  svn     13jul16 initial release from previous "trx2txt" (discontinued) code
# 0.2	  svn     20dec16 rework of fee calculation
# 0.3     svn     05feb17 multisig function included
# 0.4     svn     19may17 improved fee handling and presentation at the end
# 0.5     svn     06jul17 if creating a tx to an address beginning with "3", the script
#                         should detect this (p2sh), and use OP_HASH160 OP_DATA_20 OP_EQUAL ...
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

# flags used when calling the script with different parameters
typeset -i c_param_flag=0       # create a new TX
typeset -i f_param_flag=0       # create TX with inputs from file
typeset -i m_param_flag=0       # multisig adress and redeemscripthash
typeset -i t_param_flag=0       # fetch TX Input data from blockchain
typeset -i T_param_flag=0       # Testnet
typeset -i std_sig_chars=90     # expected chars that need to be added, to calculate txfee

# values from previous transaction
utxo_TX_ID=''
utxo_OutPoint=''
utxo_PKScript=''
utxo_Amount=''

# variables for output and txfee calculation
typeset -i amount=0
typeset -i txfee_param_flag=0       # to calculate tx fee
typeset -i txfee_per_byte=0         # txfee from the parameter to the script
typeset -i a_txfee_per_byte=0       # adjusted tx fee in Satoshi per byte
typeset -i a_txfee=0                # calculated adjusted tx fee
typeset -i c_txfee=0                # calculated tx fee
typeset -i f_txfee=0                # file tx fee
typeset -i BF21_txfee_per_byte=0    # bitcoinfees.21.co/api/v1/fees/recommended
typeset -i BF21_txfee=0             # calculated txfees based on bitcoinfees.21.co
typeset -i TX_amount=0              # the requested TX amount
typeset -i prev_tx_utxo_amount=0    # to calculate tx fee
typeset -i file_utxo_amount=0       # utxo amounts from a file
typeset -i d_amount=0               # delta amount (input - output - txfees)
RETURN_Address=''

# multisig vars 
typeset -i msig_reqsigs=0
typeset -i msig_reqkeys=0
typeset -i msig_identifyer=0
msig_cs_pubkeys=''

RAW_TX=''
RAW_TX_LINK2HEX="?format=hex"

filename=''
typeset -r c_utx_fn=tmp_c_utx.txt   # create unsigned, raw tx file (for later signing)
typeset -r prawtx_fn=tmp_rawtx.txt  # partial raw tx file, used to extract data

StepCode=''
typeset -i StepCode_decimal=0
typeset -i P2PKH_leading1_cnt=0

address_1st_char=""
address_hash=""
leading_zero=""
address_hash_nb=""
redeemscripthash=""

# and source the global var's config file
. ./tcls.conf

#################################
# procedure to display helptext #
#################################
proc_help() {
  echo " "
  echo "usage: $0 [-h|-T|-v|-vv] <options>"
  echo " -h  show this HELP text"
  echo " -T  use Testnet"
  echo " -v  display Verbose output"
  echo " -vv display VERY Verbose output"
  echo " "
  echo "Create a transaction from command line where <options> are:"
  echo " -c <prevtx_id> <prevtx_output_idx> <prevtx_PKscript | redeem_script>"
  echo "    <prevtx_amount> <amount> <address> [txfee] [ret_address]"
  echo " -f <filename> <amount> <address> [txfee] [ret_address]"
  echo "    read inputs from a file, use -f help for more details"
  echo " -m <n> <m> <comma separated list of pubkeys (66 or 130 hex chars)>" 
  echo "    create a MULTISIG address and corresponding redeem script"
  echo " -t <prevtx_id> <prevtx_output_idx>" 
  echo "    <amount> <address> [txfee] [ret_address]"
  echo "    like -c, but fetch previous pubkey script from blockchain.info"
  echo " "
  echo " Description of parameters:"
  echo "  <prevtx_id>         : the transaction, from which we want to spend"
  echo "  <prevtx_output_idx> : output index from previous TX"
  echo "  <prevtx_PKscript>   : (not with '-t') the PK SCRIPT from previous TX"
  echo "  <redeem_script>     : when spending from a P2SH (multisig) TX"
  echo "  <prevtx_amount>     : the amount from previous TX"
  echo "  <amount>            : the amount to spend (decimal, in Satoshi)"
  echo "                        *** careful: input - output = TX fee !!!"
  echo "  <address>           : the target Bitcoin address"
  echo "  [txfee]             : optional tx fee in Satoshis per bytes"
  echo "  [ret_address]       : optional adress for the change"
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

################################################
# procedure to concatenate string for a raw tx #
################################################
tx_concatenate() {
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

##################################
# Check length of provided tx ID #
##################################
chk_tx_len() {
  if [ $VVerbose -eq 1 ]; then
    printf "        checking length of tx ID (32Bytes/64chars)"
  fi
  if [ ${#utxo_TX_ID} -ne 64 ] ; then
    echo " "
    echo "*** ERROR: expecting a proper formatted Bitcoin TRANSACTION_ID."
    echo "    Please provide a 64 bytes string (aka 32 hex chars)"
    echo "    Hint: empty lines in file are not allowed!"
    echo "    current length: ${#utxo_TX_ID}, utxo_TX_ID:"
    echo "    $utxo_TX_ID"
    exit 1 
  fi
  if [ $VVerbose -eq 1 ]; then
    printf " - ok \n" 
  fi
}

###################################################
### GET_TX_VALUES() - fetch required tx values  ###
###################################################
#  if param "-t" or "-f" is given, we fetch values from prev transactions. 
#  This shall be executed:
#    ./tcls_tx2txt.sh -vv -r $RAW_TX | grep -A7 TX_OUT[$utxo_OutPoint] > $prawtx_fn
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
#  1--> used to be in the right output ($utxo_OutPoint)
#  2--> used with -f flag, adding up all the amounts 
#  3--> used for STEP 5, need to grep and cut
#  4--> used for STEP 6, need to grep -A1 -B1 pk_script[$utxo_OutPoint]
#  
get_tx_values() {
  vv_output "./tcls_tx2txt.sh -vv -r $RAW_TX | grep -A7 TX_OUT[$utxo_OutPoint] > $prawtx_fn"
  ./tcls_tx2txt.sh -vv -r $RAW_TX | grep -A7 TX_OUT[[]$utxo_OutPoint[]] > $prawtx_fn
  #
  # is it better to use grep / cut / tr or a simple awk ???
  # awk is 30% faster, and uses only half the system and usr CPU cycles
  #
  # prev_tx_utxo_amount=$( grep -m1 bitcoin $prawtx_fn | cut -d "=" -f 4 | cut -d "," -f 1 )
  # STEP5_SCRIPT_LEN=$( grep -A1 -B1 pk_script $prawtx_fn | head -n1 | cut -b 7,8 )
  # STEP6_SCRIPTSIG=$( grep -A1 -B1 pk_script $prawtx_fn | tail -n1 | tr -d "[:space:]" )
  #
  prev_tx_utxo_amount=$( awk -F "=|," '/bitcoin/ { print $6 }' $prawtx_fn )
  STEP5_SCRIPT_LEN=$( awk -F ",|=" 'NR==5 { print $2 }' $prawtx_fn )
  STEP6_SCRIPTSIG=$( awk '/pk_script/ { getline;print $1}' $prawtx_fn )
  RAW_TX=''
  vv_output "   prev_tx_utxo_amount=$prev_tx_utxo_amount"
  vv_output "   STEP5_SCRIPT_LEN=$STEP5_SCRIPT_LEN"
  vv_output "   STEP6_SCRIPTSIG=$STEP6_SCRIPTSIG"
  
  if [ "$prev_tx_utxo_amount" == "" ] && [ "$STEP5_SCRIPT_LEN" == "" ] ; then 
    echo " "
    echo "*** ERROR: inconsistant data from www.blockchain.info"
    echo "           don't know how to continue without values." 
    echo "           exiting gracefully ... "
    exit 1
  fi
}

##################################################
# procedure to check even length of address_hash #
##################################################
# https://bitcointalk.org/index.php?topic=1026.0
leading_zeros() {
  # get the length of the string h, and if not 'even', add a beginning 
  # zero. Background: we need to convert the hex characters to a hex value, 
  # and need to have an even amount of characters... 
  len=${#address_hash}
  s=$(( $len % 2 ))
  if [ $s -ne 0 ] ; then
    address_hash=$( echo "0$address_hash" )
  fi
  len=${#address_hash}
  # echo "after mod 2 calc, address_hash=$address_hash"
} 

##################################################################
# procedure to calculate the checksum (of hex values) of address #
##################################################################
get_chksum() {
  # this is not working properly on other UNIXs, made it more portable:
  # variable h = address_hash
  # chksum_f8=$( xxd -p -r <<<"00$h" |
  #     openssl dgst -sha256 -binary |
  #     openssl dgst -sha256 -binary |
  #     xxd -p -c 80 |
  #     head -c 8 |
  #     tr [:lower:] [:upper:] )
  #
  # This becomes a bit ugly here: we need to convert address_hash to  
  # hex values, so that openssl can work on it (more precisely: bitcoin 
  # works with binary data, that is sha256'd). Without "xxd" the use 
  # of sed will convert data in "\0x00" type hex values, that can be 
  # written to as file. 
  # There must be a better way of doing this :-)
  #
  # vv_output " address_hash before double sha256: $address_hash"
  chksum_f8=$( printf "%s" $address_hash_nb | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
  # Step 5 - hash 256
  printf $chksum_f8 > tmp_plusnetworkbyte.txt
  openssl dgst -sha256 -binary tmp_plusnetworkbyte.txt > tmp_sha256.hex
  rm tmp_plusnetworkbyte.txt
  # Step 6 - another hash 256
  openssl dgst -sha256 -binary tmp_sha256.hex > tmp_dsha256.hex
  # Step 7 - get first 4 Bytes (8 chars) as the checksum
  chksum_f8=$( od -An -t x1 tmp_dsha256.hex | tr -d [[:blank:]] | tr -d "\n" | 
               cut -b 1-8 | tr [:lower:] [:upper:] )
}

##################################
### Check bitcoin address hash ###
##################################
# see also here: https://bitcointalk.org/index.php?topic=1543429.0
# bitcoin-tools.sh has this logic, which only works in bash. I changed
# it to be a bit more POISX compliant (also work in ksh). 
# in this example variable $1 is the target address
# decodeBase58() {
#     echo -n "$1" | sed -e's/^\(1*\).*/\1/' -e's/1/00/g' | tr -d '\n'
#     dc -e "$dcr 16o0$(sed 's/./ 58*l&+/g' <<<$1)p" |
#     while read n; do echo -n ${n/\\/}; done
# }
#
chk_bc_address_hash() {
  echo $TARGET_Address | awk -f tcls_verify_bc_address.awk > /dev/null
  if [ $? -eq 1 ] ; then
    echo "*** ERROR: invalid address: $s"
    echo "    exiting gracefully ..."
    exit 1
  fi 
  
  s=$( echo $TARGET_Address | awk -f tcls_verify_bc_address.awk )
  vv_output "$s"
  s=$( echo $s | sed 's/[0-9]*/ 58*&+ /g' )
  vv_output "$s"
  #                     16o -> base is 16 for output
  #                      | 0d -> duplicate stack
  #                      | |   put out all the base58 remainders
  #                      | |   | sum everything up and "f" prints the content of the stack
  #                      | |   | |
  address_hash=$( echo "16o0d $s +f" | dc )
  leading_zeros
  vv_output " address_hash after leading 0s:     $address_hash"

  # checksum verification: 
  # get last 8 chars of address_hash (the reference checksum)
  # remove last 8 chars, double sha256 the string, 
  # and the first 8 chars should match the reference checksum
  len=${#address_hash}
  from=$(( $len - 7 ))
  chksum_l8=$( echo $address_hash | cut -b $from-$len )
  to=$(( $len - 8 ))
  address_hash=$( echo $address_hash | cut -b 1-$to )
  vv_output " address_hash without last 8 chars: $address_hash, chksum=$chksum_l8"

  # only for P2PKH adresses, verify leading "1s" 
  # https://bitcointalk.org/index.php?topic=1026.0
  # --> each additional leading 1 in an original address needs a "00" hex at the beginning
  if [ $T_param_flag -eq 0 ] && [ $msig_identifyer -eq 0 ] ; then
    from=2
    to=2
    address_1st_char=$( echo $TARGET_Address | cut -b $from-$to )
    while [ "$address_1st_char" == "1" ]
     do
      # echo $address_1st_char
      leading_zero=$( echo "00$leading_zero" )
      from=$(( $from + 1 ))
      to=$(( $to + 1 ))
      address_1st_char=$( echo $TARGET_Address | cut -b $from-$to )
    done
    address_hash=$( echo "$leading_zero$address_hash" )
    vv_output " address_hash after leading1_cnt:   $address_hash"
  fi
   
  # get network bytes in front ... (only for P2PKH addresses?)
  if [ $msig_identifyer -eq 0 ] ; then 
    if [ $T_param_flag -eq 0 ] ; then 
      address_hash_nb=$( echo "00$address_hash" )
    else
      # address_hash_nb=$( echo "6f$address_hash" )
      address_hash_nb=$( echo "$address_hash" )
    fi
  else
    address_hash_nb=$( echo "$address_hash" )
  fi
  vv_output " address_hash + network byte:       $address_hash_nb"
  get_chksum

  if [ "$chksum_l8" != "$chksum_f8" ] ; then
    vv_output " chksum_l8 (last 8 chars):  $chksum_l8"
    vv_output " chksum_f8 (first 8 chars): $chksum_f8"
    echo "*** ERROR: checksum mismatch for target address $TARGET_Address"
    echo "  * Exiting gracefully..."
    exit 1
  fi
}

step3to7() {
  ##############################################################################
  ### STEP 3 - TX_IN, previous transaction hash: 32hex = 64 chars            ###
  ##############################################################################
  v_output "###  3. TX_IN[$line_items], previous transaction hash"
  vv_output "###     org tx:   $utxo_TX_ID"
  StepCode=$( reverse_hex $utxo_TX_ID )
  vv_output "###     reversed: $StepCode"
  tx_concatenate
  
  ##############################################################################
  ### STEP 4 - TX_IN, the output index we want to redeem from                ###
  ##############################################################################
  v_output "###  4. TX_IN[$line_items], the output index we want to redeem from"
  # check that we have a number, not a char...
  StepCode=$( echo "obase=16;$utxo_OutPoint"|bc -l)
  StepCode=$( zero_pad $StepCode 8 )
  StepCode=$( reverse_hex $StepCode )
  vv_output "###     convert from $utxo_OutPoint to reversed hex: $StepCode"
  tx_concatenate
  
  ##############################################################################
  ### STEP 5 - TX_IN, scriptsig length: first hex Byte is length (2 chars)   ###
  ##############################################################################
  # For the purpose of signing the transaction, this is temporarily filled 
  # with the scriptPubKey of the output we want to redeem. 
  v_output "###  5. TX_IN[$line_items], scriptsig length"
  if [ $t_param_flag -eq 0 ] ; then
    StepCode=${#utxo_PKScript}
    StepCode=$(( $StepCode / 2 ))
    StepCode=$( echo "obase=16;$StepCode"|bc ) 
    if [ ${#StepCode} -eq 1 ] ; then
      StepCode=0$StepCode
    fi
  else
    StepCode=$STEP5_SCRIPT_LEN
  fi 
  vv_output "###     ScriptSig length=$StepCode"
  tx_concatenate
  
  ##############################################################################
  ### STEP 6 - TX_IN, signature script, uchar[] - variable length            ###
  ##############################################################################
  # the actual scriptSig (which is the scriptPubKey of the utxo_TX_ID
  v_output "###  6. TX_IN[$line_items], signature script"
  if [ $t_param_flag -eq 0 ] ; then
    StepCode=$utxo_PKScript
    vv_output "$StepCode"
  else
    vv_output "StepCode=$STEP6_SCRIPTSIG"
    StepCode=$STEP6_SCRIPTSIG
  fi 
  if [ "$StepCode" == "0" ] ; then
    vv_output "$RAW_TX"
    vv_output " "
  else
    tx_concatenate
  fi
  
  ##############################################################################
  ### STEP 7 - TX_IN, SEQUENCE: This is currently always set to 0xffffffff   ###
  ##############################################################################
  # This is currently always set to 0xffffffff
  v_output "###  7. TX_IN[$line_items], concatenate sequence number (currently always 0xffffffff)"
  StepCode="ffffffff"
  tx_concatenate
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
  tx_concatenate
}


##############################################################################
### STEP 10 - TX_OUT, LENGTH: Number of bytes in the PK script (var_int)   ###
### STEP 11 - TX_OUT, PUBLIC KEY SCRIPT: the OP Codes of the PK script     ###
##############################################################################
# convert parameter TARGET_Address to the pubkey script.
# the P2PKH script is preceeded with "76A914" and ends with "88AC".
# the P2SH script is preceeded with "a914" and ends with "87".
##############################################################################
# pubkey script length
step10_11() {
  v_output "### 10 & 11. TX_OUT, LENGTH (var_int) and PK Script OpCodes"
  # length of P2PKH script (76 A9 14 <20 Bytes> 88 AC) will be 25 Bytes (hex 0x19): 
  # length of P2SH script (A9 14 <20 Bytes> 87) will be 23 Bytes (hex 0x17) 

  # when address starts with "1", do P2PKH on main net
  # when address starts with "m", do P2PKH on test net
  # when address starts with "n", do P2PKH on test net
  # when address starts with "2", do P2SH on test net
  # when address starts with "3", do P2SH on main net
  address_1st_char=$( echo $TARGET_Address | cut -b 1 )
  if [ "$address_1st_char" == "2" ] || [ "$address_1st_char" == "3" ] ; then
    msig_identifyer=1
  fi
  chk_bc_address_hash

  # observation:
  # after base58 decode of a multisig address, the network byte (05) is 
  # automatically included, need to remove it here...
  # same for testnet addresses - what is the underlying logic?
  # needs further investigation... 
  #
  if [ $msig_identifyer -eq 1 ] || [ $T_param_flag -eq 1 ] ; then 
    address_hash=$( echo $address_hash | cut -b 3-42 )
    # echo $address_hash
  fi

  # first check length of address hash. It is always 20 Bytes (40 chars), in hex 0x14, right?
  if [ ${#address_hash} -ne 40 ] ; then
    echo "*** ERROR: an address in Bitcoin is always 20 Bytes"
    echo "***        check address length. Exiting gracefully ... "
    exit 1
  fi
  redeemscripthash=$address_hash
  tmpvar="14"

  address_1st_char=$( echo $TARGET_Address | cut -b 1 )
  case $address_1st_char in 
   1) StepCode="19"
      StepCode=$( echo $StepCode$OP_DUP$OP_HASH160$tmpvar$address_hash$OP_EQUALVERIFY$OP_CHECKSIG )
      ;;
   2|3) StepCode="17"
      StepCode=$( echo $StepCode$OP_HASH160$tmpvar$redeemscripthash$OP_EQUAL )
      ;;
   m|n) T_param_flag=1
      StepCode="19"
      StepCode=$( echo $StepCode$OP_DUP$OP_HASH160$tmpvar$address_hash$OP_EQUALVERIFY$OP_CHECKSIG )
      ;;
   *) echo "*** ERROR: could not check address type, unrecognized format for $TARGET_Address"
      echo "    don't know what to do, exiting gracefully ..."
      exit
      ;;
  esac
  tx_concatenate
}


##########################
### adjust the tx fees ###
##########################
# ... THIS NEEDS FURTHER ANALYSIS !!!
# tx fees are calculated with a tx fee per byte, which is changing...
# Exact length can only be determined during signing process, but here is 
# a rough calc: 
# if TX_script in this unsigned TX is 
#    P2PKH (1 input, 1 output), then sig length will be ~227 Bytes 
#    P2SH can be much longer
#    SegWit and MerkleTrees can be much shorter
# on default tx fees, proposal:
#    if TX size <=   1000 bytes then use a standard txfee, or manually provided txfee
#    if TX size <=   5000 bytes then use standard txfee / 2
#    if TX size <=  10000 bytes then use standard txfee / 4
#    if TX size <= 100000 bytes then use standard txfee / 8
# 
# calc_txfee needs to know the length of our RAW_TX
# each input requires later on a signature (length=70 Bytes/140 chars), 
# which replaces the existing PKSCRIPT (length 25 Bytes, 50 chars). 
# Each input must be signed, so roughly 90 chars signature are added ($std_sig_chars). 
# $line_items below is the current TX_IN, so if we have a multi input TX, 
# this can be more than 1, and we need a txfee calc for each UTXO 
#
# for a later improvement:
# eventually it makes sense, to verify TX_Fee calcs AFTER the signing process?
# just to double check?
#
calc_adjusted_amount() {
  a_txfee_per_byte=$txfee_per_byte
  echo $RAW_TX > $c_utx_fn
  TX_chars=$( wc -c $c_utx_fn | awk '{ print $1 }' )
  TX_bytes=$(( $line_items * $std_sig_chars + $TX_chars ))
  if [ $TX_bytes -le 1000 ] ; then
    a_txfee=$(( $txfee_per_byte * $TX_bytes ))
  elif [ $TX_bytes -le 10000 ] ; then
    a_txfee_per_byte=$(( $txfee_per_byte / 2 ))
    a_txfee=$(( $a_txfee_per_byte * $TX_bytes ))
  elif [ $TX_bytes -le 100000 ] ; then
    a_txfee_per_byte=$(( $txfee_per_byte / 3 ))
    a_txfee=$(( $a_txfee_per_byte * $TX_bytes ))
  else
    a_txfee_per_byte=$(( $txfee_per_byte / 4 ))
    a_txfee=$(( $a_txfee_per_byte $TX_bytes ))
  fi
}


#################################################################
### Multisig: create msig address and redeemscript, then exit ###
#################################################################
# validity rules require that the P2SH redeem script is at most 520 bytes. 
# As the redeem script is [m pubkey1 pubkey2 ... n OP_CHECKMULTISIG], it 
# follows that the length of all public keys together plus the number of 
# public keys must not be over 517. Usually sigs are 73 chars:
#   For compressed public keys, this means up to n=15
#     m*73 + n*34 <= 496 (up to 1-of-12, 2-of-10, 3-of-8 or 4-of-6).
#   For uncompressed ones, up to n=7
#     m*73 + n*66 <= 496 (up to 1-of-6, 2-of-5, 3-of-4).
#
proc_msig() {
  # 0.) verify, that $opcode_msig_reqkeys is not greater max, and sigs <= keys
  # 1.) convert msig_reqsigs into OP1-OP15 (dez 81-96, hex 0x51-0x60) for redeemscript
  # 2.) parse msig_cs_pubkeys, and separate into single public keys
  # 3.) verify, that we have amount of $msig_reqkeys in $msig_cs_pubkeys
  # 4.) verify each pubkey for validity 
  # 5.) get each pubkey's length
  # 6.) assemble redeemscript (example 2of3)
  #     <OP_2><len pubkey_A><pubkey_A><len PK_B><PKB><len PK_C><PK_C><OP_3><OP_CHECKMULTISIG>
  # 7.) create P2SH adress from redeem script
  #     RIPEMD160(SHA256(redeemscript))
  #     base58_encode("05", redeemscriptHash)
  # 8.) check for these max values:
  #     msig_redeemscript_maxlen=520
  #     msig_max_uncompressed_keys=7
  #     msig_max_compressed_keys=15

  i=0
  len_pubkey=0
  opcode_msig_reqsigs=0
  opcode_msig_reqkeys=0
  v_output " msig: required signatures:      $msig_reqsigs"
  v_output " msig: required keys:            $msig_reqkeys"
  v_output " msig: comma separated pubkeys:  $msig_cs_pubkeys"

  # STEP 0: verify we don't have more than x of 15 ...
  if [ $msig_reqkeys -gt $msig_max_compressed_keys ] ; then
    echo "*** ERROR: required msig keys ($msig_reqkeys) is greater than possible max value ($msig_max_compressed_keys)."
    echo "  * Exiting gracefully..."
    exit 1
  fi 
  if [ $msig_reqsigs -gt $msig_reqkeys ] ; then
    echo "*** ERROR: required signatures ($msig_reqsigs) must be less or equal required keys ($msig_reqkeys)."
    echo "  * Exiting gracefully..."
    exit 1
  fi 

  # STEP 1: convert msig_reqsigs in OP_Code
  # (80 + msig_reqsigs) = Op_code in decimal, convert to hex ...
  opcode_msig_reqsigs=$( echo "obase=16;$opcode_numericis_offset+$msig_reqsigs" | bc )
  opcode_msig_reqkeys=$( echo "obase=16;$opcode_numericis_offset+$msig_reqkeys" | bc )
  redeemscript=$opcode_msig_reqsigs

  # STEP 2: verify, that we have amount of $msig_reqkeys in $msig_cs_pubkeys
  for pubkey in $(echo $msig_cs_pubkeys | tr "," " "); do
    i=$(( $i + 1 ))
  done  
  if [ $i -ne $msig_reqkeys ] ; then
    echo "*** Mismatch: comma separated key list does not contain $msig_reqkeys required keys."
    echo "  * found only $i key(s). Exiting gracefully..."
    exit 1
  else
    v_output " msig: found $i of $msig_reqkeys required keys in comma separated key list - good"
  fi

  # STEP 3: parse msig_cs_pubkeys
  for pubkey in $(echo $msig_cs_pubkeys | tr "," " "); do

    # STEP 4: verify each pubkey
    printf "%s" $pubkey | awk -f tcls_verify_hexkey.awk
    if [ $? -gt 0 ] ; then
      echo "  * Exiting gracefully..."
      exit 1
    fi

    # STEP 5: get each pubkey's length
    # echo $pubkey
    # printf "%s" $pubkey | wc -c 
    len_pubkey=$( printf "%s" $pubkey | wc -c )
    len_hex=$( echo "obase=16;$len_pubkey/2" | bc )

    # STEP 6: assemble redeemscript
    redeemscript=$redeemscript$len_hex$pubkey
  done

  redeemscript=$redeemscript$opcode_msig_reqkeys$OP_CHECKMULTISIG
  echo " "
  echo "The redeemscript:"
  echo "$redeemscript"
  echo " "
  echo "WARNING: YOU MUST NOT LOSE THE REDEEM SCRIPT, especially"
  echo "if you don’t have a record of which public keys you used"
  echo "to create the P2SH multisig address. You need the redeem"
  echo "script to spend any bitcoins sent to the P2SH address."
  echo "(https://bitcoin.org/en/developer-examples#p2sh-multisig)"
  echo "The redeem script can be recreated with all public keys "
  echo "listed in the same order."
  echo "HINT: once you've spent from a P2SH address, the redeem "
  echo "script is permanently visible in the blockchain."
  echo " "

  # STEP 7a: RIPEMD160(SHA256(redeemscript))
  tmpvar=$( echo $redeemscript | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
  result=$( printf "$tmpvar" | openssl dgst -sha256 | cut -d " " -f 2 )
  result=$( echo $result | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
  result=$( printf "$result" | openssl dgst -rmd160 | cut -d " " -f 2 )
  param=$result

  # STEP 7b: base58_encode("05", redeemscriptHash)
  echo "The P2SH address:"
  if [ $T_param_flag -eq 0 ] ; then ./tcls_base58check_enc.sh -q -p2sh $result; fi
  if [ $T_param_flag -eq 1 ] ; then ./tcls_base58check_enc.sh -q -T -p2sh $result; fi

# STEP 8: check against these values:
# msig_redeemscript_maxlen=520
# msig_max_uncompressed_keys=7
# msig_max_compressed_keys=15
  exit 0

}


###########################################################
### check numeric values of utxo_OutPoint and TX_amount ###
###########################################################
chk_numeric() {
  if ! expr "$1" : '[0-9]*$'>/dev/null; then
    echo "Non numeric parameter $1 for $2. Please fix. Exiting gracefully ..."
    exit 1
  fi
}


echo "#########################################################"
echo "### tcls_create.sh: create a raw, unsigned Bitcoin tx ###"
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
  echo " -f <filename> <amount> <address> [txfee] [ret_address]"
  echo "    <filename>:    prev tx params line by line separated by blanks, containing:"
  echo "                   <prev_tx-id> <prev_output-index> <prev_PK-script> <prev_utxo_amount>"
  echo "    <amount>:      amount to spend in Satoshis"
  echo "    <address>:     the target address for this transaction"
  echo "    [txfee]:       numeric amount for tx fees (Satoshi/Byte)"
  echo "    [ret_address]: a return address"
  echo " "
  echo "    <prev_tx-id> <prev_output-index> <prev_pubkey-script> <prev_utxo_amount>, see:"
  echo "     blockchain.info/de/unspent?active=<address>"
  echo "    more detailed with bitcoin core CLI:"
  echo "     listunspent 6 9999999 \"[\\\"<address>\\\"]\""
  echo "    1) fetch only the lines of interest:"
  echo "     grep -e txid -e vout -e scriptPubKey -e amount bitcoin_cli_utxo.txt > test1"
  echo "    2) bring them in record, remove quotes and commas"
  echo "     awk 'ORS=NR%4?\" \":\"\\\n\" {gsub(/\"|,/, \"\")};1 { print \$2 }' test1 > test2"
  echo "    3) convert amount into Satoshis:"
  echo "     LC_ALL=ISO_8859-1 awk '{ \$NF=\$NF*100000000; print }' test2"
  echo " "
  echo "    *** careful: input - output = tx fee !!!"
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
      -c)
         c_param_flag=1
         shift 
         if [ "$1" == "-f" ] || [ "$1" == "-m" ] || [ "$1" == "-t" ] ; then
           echo "*** you cannot use -c with -f or -m or -t at the same time."
           echo "    Exiting gracefully ... "
           exit 0
         fi
         if [ $# -lt 6 ] ; then
           echo "*** you must provide correct number of parameters"
           proc_help
           exit 0
         fi
         utxo_TX_ID=$1
         shift 
         chk_numeric $1 utxo_OutPoint
         utxo_OutPoint=$1
         shift 
         utxo_PKScript=$1
         shift 
         chk_numeric $1 utxo_Amount
         utxo_Amount=$1
         shift 
         chk_numeric $1 TX_amount
         TX_amount=$1
         shift 
         TARGET_Address=$1
         shift 
         # if there is only one parameter left, it can be tx_fee or return_address
         # if length of param is less then 9 chars, then it is for sure tx_fee. 
         # TX fees shouldn't have 9 digits of satoshis (aka more than a bitcoin)...
         # otherwise it is the return address, and txfee needs to get calculated automatically.
         if [ $# -eq 1 ] ; then
           if [ ${#txfee_per_byte} -lt 10 ] ; then
             txfee_param_flag=1
             chk_numeric $1 txfee_per_byte
             txfee_per_byte=$1
             shift
           else
             RETURN_Address=$1
             shift
           fi
         fi
         if [ $# -eq 2 ] ; then
           txfee_param_flag=1
           chk_numeric $1 txfee_per_byte
           txfee_per_byte=$1
           RETURN_Address=$2
           shift
           shift
         fi
         if [ $# -gt 0 ] ; then
           echo "*** already detected last parameter as return address, don't know what to do"
           echo "    with the following parameter(s). Exiting gracefully ... "
           exit 0
         fi
         ;;
      -f)
         f_param_flag=1
         shift 
         if [ $# -lt 3 ] ; then
           echo "*** you must provide correct number of parameters"
           proc_help
           exit 1
         fi
         if [ "$1" == ""  ] ; then
           echo "*** you must provide a FILENAME to the -f parameter!"
           exit 1
         fi
         if [ "$1" == "-c" ] || [ "$1" == "-m" ] || [ "$1" == "-t" ] ; then
           echo "*** you cannot use -f with -c or -m or -t at the same time."
           echo "    Exiting gracefully ... "
           exit 1
         fi
         filename=$1
         shift 
         chk_numeric $1 TX_amount
         TX_amount=$1
         shift 
         TARGET_Address=$1
         shift 
         # if there is only one parameter left, it can be tx_fee or return_address
         # if length of param is less then 9 chars, then it is for sure tx_fee. 
         # TX fees shouldn't have 9 digits of satoshis (aka more than a bitcoin)...
         # otherwise it is the return address, and txfee needs to get calculated automatically.
         if [ $# -eq 1 ] ; then
           if [ ${#txfee_per_byte} -lt 9 ] ; then
             txfee_param_flag=1
             txfee_per_byte=$1
             shift
           else
             RETURN_Address=$1
             shift
           fi
         fi
         if [ $# -eq 2 ] ; then
           txfee_param_flag=1
           txfee_per_byte=$1
           RETURN_Address=$2
           shift
           shift
         fi
         if [ $# -gt 0 ] ; then
           echo "*** already detected last parameter as return address, don't know what to do"
           echo "    with the following parameter(s). Exiting gracefully ... "
           exit 0
         fi
         ;;
      -m)
         m_param_flag=1
         shift 
         if [ "$1" == "-c" ] || [ "$1" == "-f" ] || [ "$1" == "-t" ] ; then
           echo "*** you cannot use -m with -c or -f or -t at the same time."
           echo "    Exiting gracefully ... "
           exit 1
         fi
         if [ $# -lt 3 ] ; then
           echo "*** you must provide correct number of parameters"
           proc_help
           exit 1
         fi
         chk_numeric $1 msig_reqsig
         msig_reqsigs=$1
         shift 
         chk_numeric $1 msig_reqkeys
         msig_reqkeys=$1
         shift 
         msig_cs_pubkeys=$1
         shift 
         proc_msig
         ;;
      -t)
         t_param_flag=1
         shift 
         if [ "$1" == "-c" ] || [ "$1" == "-f" ] || [ "$1" == "-m" ] ; then
           echo "*** you cannot use -t with -c or -f or -m at the same time."
           echo "    Exiting gracefully ... "
           exit 0
         fi
         if [ $# -lt 4 ] ; then
           echo "*** you must provide correct number of parameters"
           proc_help
           exit 0
         fi
         if [ "$1" == ""  ] ; then
           echo "*** you must provide a Bitcoin TRANSACTION_ID to the -t parameter!"
           exit 0
         fi
         utxo_TX_ID=$1
         shift 
         utxo_OutPoint=$1
         chk_numeric $1 utxo_OutPoint
         shift 
         TX_amount=$1
         chk_numeric $1 TX_amount
         shift 
         TARGET_Address=$1
         shift 
         # if there is only one parameter left, it can be tx_fee or return_address
         # if length of param is less then 9 chars, then it is for sure tx_fee. 
         # TX fees shouldn't have 9 digits of satoshis (aka more than a bitcoin)...
         # otherwise it is the return address, and txfee needs to get calculated automatically.
         if [ $# -eq 1 ] ; then
           if [ ${#txfee_per_byte} -lt 9 ] ; then
             txfee_param_flag=1
             txfee_per_byte=$1
             shift
           else
             RETURN_Address=$1
             shift
           fi
         fi
         if [ $# -eq 2 ] ; then
           txfee_param_flag=1
           txfee_per_byte=$1
           RETURN_Address=$2
           shift
           shift
         fi
         if [ $# -gt 0 ] ; then
           echo "*** already detected last parameter as return address, don't know what to do"
           echo "    with the following parameter(s). Exiting gracefully ... "
           exit 0
         fi
         ;;
      -T)
         T_param_flag=1
         echo "TESTNET output "
         shift
         ;;
      -v)
         Verbose=1
         echo "Verbose output turned on"
         shift
         ;;
      -vv)
         Verbose=1
         VVerbose=1
         echo "VERY Verbose and Verbose output turned on"
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
v_output " PARAM_COUNT     $param_count"
if [ "$f_param_flag" -eq 1 ] ; then
  v_output " FILENAME        $filename"
else
  v_output " utxo_TX_ID      $utxo_TX_ID"
  v_output " utxo_OutPoint   $utxo_OutPoint"
fi
if [ "$c_param_flag" -eq 1 ] ; then
  v_output " utxo_PKScript   $utxo_PKScript"
  v_output " utxo_Amount     $utxo_Amount"
fi
v_output " TX_AMOUNT       $TX_amount"
v_output " TARGET_Address  $TARGET_Address"
if [ $txfee_per_byte -ne 0 ] ; then
  v_output " txfee_per_byte  $txfee_per_byte"
fi
if [ "$RETURN_Address" != "" ] ; then
  v_output " RETURN_Address  $RETURN_Address"
fi

#######################################
### verify operating system, cause: ###
#######################################
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

# we have at last one line item, when using "-c", or more than one using "-f"
line_items=1

###############################################
### Check if network is required and active ###
###############################################
# check if network interface is active ...
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
if [ $? -eq 0 ]; then
  vv_output " - yes"
  # when there was no parameter given for txfee:
  if [ $txfee_param_flag -eq 0 ] ; then
    BF21_txfee_per_byte=$( $http_get_cmd https://bitcoinfees.21.co/api/v1/fees/recommended | head -n1 | awk ' BEGIN {FS="[:}]"} { print $4 }' )
  fi
  # if we create a tx, and param -t was given, then a 
  # Bitcoin TRANSACTION_ID should be in variable "utxo_TX_ID":
  if [ "$t_param_flag" -eq 1 ] ; then
    # 
    # 1.) go to the network, like this:
    #     https://blockchain.info/de/rawtx/cc8a279b07...3c1ad84408?format=hex
    # 2.) use OS specific calls:
    #     OpenBSD: ftp -M -V -o - https://blockchain.info/de/rawtx/...
    # 3.) pass everything into the variable "RAW_TX"
    # 
    vv_output " going for this TX: $utxo_TX_ID"
    chk_tx_len 
    if [ $VVerbose -eq 1 ]; then
      printf " check if we can reach www.blockchain.info (ping)" 
    fi
    ping -c1 www.blockchain.info > /dev/zero
    if [ $? -ne 0 ] ; then
      echo " "
      echo "*** ERROR: www.blockchain.info not reachable"
      echo "    verify your network settings, or assemble tx manually [-m]"
      echo "    exiting gracefully ... "
      exit 1
    else
      if [ $VVerbose -eq 1 ]; then
        printf " - yes \n fetch data from blockchain.info \n"
      fi
      RAW_TX=$( $http_get_cmd https://blockchain.info/de/rawtx/$utxo_TX_ID$RAW_TX_LINK2HEX )
      if [ $? -ne 0 ] ; then
        echo " "
        echo "*** ERROR: fetching RAW_TX data:"
        echo "    $http_get_cmd https://blockchain.info/de/rawtx/$utxo_TX_ID$RAW_TX_LINK2HEX"
        echo "    downoad manually, and call 'tcls_tx2txt.sh -r ...'"
        exit 1
      fi
      if [ ${#RAW_TX} -eq 0 ] ; then
          echo "*** ERROR: the raw tx has a length of 0. Something failed."
          echo "    downoad manually, and call 'tcls_tx2txt.sh -r ...'"
          exit 1
        fi
      fi
    get_tx_values 
  fi
else
  vv_output " - no "
  if [ "$t_param_flag" -eq 1 ] ; then
    echo "*** ERROR: param '-t' was given, but could not establish network connection"
    echo "           please make sure, network is ok, and retry. Exiting gracefully."
    exit 1
  fi
fi

##############################################################################
### STEP 1 - VERSION (8 chars) - Add four-byte version field               ###
##############################################################################
v_output " "
v_output "###  1. VERSION"
StepCode="01000000"
tx_concatenate

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
    if [ $StepCode_decimal -gt 1024 ] ; then
      echo "*** not yet prepared to work with more than 1000 lines."
      echo "    need to wait for next release - sorry!"
      echo "    exiting gracefully"
      exit 1
    fi
    if [ $StepCode_decimal -lt 10 ] ; then
      StepCode=0$( echo "obase=16;$StepCode_decimal"|bc ) 
    else
      StepCode=$( echo "obase=16;$StepCode_decimal"|bc ) 
    fi   
    vv_output "lines in file equals tx inputs: $StepCode_decimal, hex: 0x$StepCode"
  else
    echo "*** ERROR: file $filename does not exist"
    echo " "
    exit 1
  fi
fi
tx_concatenate

############################
### TX_IN: call STEP 3-7 ### 
############################
if [ "$f_param_flag" -eq 1 ] ; then
  # each line item is a references to the previous transaction:
  # utxo_TX_ID            --> the tx number
  # utxo_OutPoint         --> the outpoint, from which to spend 
  # utxo_PKScript         --> the corresponding public key script
  # prev_tx_utxo_amount   --> and the amount from all inputs
  # if only utxo_TX_ID is given, need to connect to network and do s.th. like
  # listunspend(tx_number) ?
  while IFS=" " read utxo_TX_ID utxo_OutPoint utxo_PKScript prev_tx_utxo_amount
   do
    v_output  "####### TX_IN: line item $line_items"
    # for every line item we need to check the tx, and get the values:
    chk_tx_len 
    # if only utxo_TX_ID is given, we could fetch remaining items with 'get_tx_values' ?
    vv_output "        utxo_TX_ID=$utxo_TX_ID"
    vv_output "        utxo_OutPoint=$utxo_OutPoint"
    vv_output "        utxo_PKScript=$utxo_PKScript"
    vv_output "        prev_tx_utxo_amount=$prev_tx_utxo_amount"
    step3to7 
    line_items=$(( $line_items + 1 ))
    file_utxo_amount=$(( $file_utxo_amount + $prev_tx_utxo_amount ))
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
tx_concatenate

##############################
### TX_OUT: call STEP 9-11 ### 
##############################
# this is for the first TX_out 
amount=$TX_amount
step9
step10_11

############################################
### TX_OUT: if there is a return address ###
############################################
# if we have a return address (which is between 28 and 34 chars...), 
# then make sure, money gets back to us ... so we add a second address in TX_out.
# but before, we need to calculate txfees, and deduct the return amounts 
calc_adjusted_amount
if [ "$f_param_flag" -eq 1 ] ; then
  d_amount=$(( $file_utxo_amount - $TX_amount - $a_txfee ))
fi
if [ "$t_param_flag" -eq 1 ] ; then
  d_amount=$(( $prev_tx_utxo_amount - $TX_amount - $a_txfee ))
fi

if [ ${#RETURN_Address} -gt 28 ] ; then
  TARGET_Address=$RETURN_Address
  amount=$d_amount 
  step9
  step10_11
fi 

###########################################################################
### STEP 12 - LOCK_TIME: block nor timestamp at which this tx is locked ###
###########################################################################
v_output "### 12. LOCK_TIME: block or timestamp at which this tx is locked"
StepCode="00000000" 
tx_concatenate

##############################################################################
### STEP 13 - HASH CODE TYPE                                               ###
##############################################################################
v_output "### 13. HASH CODE TYPE"
StepCode="01000000" 
tx_concatenate
echo $RAW_TX > $c_utx_fn

##############################################################################
### Finished, presenting results ...                                       ###
##############################################################################
echo " "

##########################################
### verifying input and output amounts ###
##########################################

echo "###########################################################################"
echo "### amount(utxo) - amount(requested) = TXFEE. *Double check YOUR MATH!* ###"
if [ "$t_param_flag" -eq 1 ] ; then
  printf "### amount of tx input(s) (in Satoshis):               %16d ###\n" $prev_tx_utxo_amount
  printf "### requested amount to spend (in Satoshis):           %16d ###\n" $TX_amount
  if [ $prev_tx_utxo_amount -lt $TX_amount ] ; then
    echo "*** ERROR: input insufficient, please verify amount(s)."
    echo " "
    exit 0 
  fi
elif [ "$f_param_flag" -eq 1 ] ; then
  printf "### utxo amount in file (in Satoshis):                 %16d ###\n" $file_utxo_amount
  printf "### requested amount to spend (in Satoshis):           %16d ###\n" $TX_amount
  if [ $file_utxo_amount -lt $TX_amount ] ; then
    echo "*** ERROR: input insufficient, please verify amount(s)."
    echo " "
    exit 0 
  fi
else
  printf "### amount in previous transacton (in Satoshis):       %16d ###\n" $utxo_Amount
  printf "### requested amount to spend (in Satoshis):           %16d ###\n" $TX_amount
fi

#########################
### checking TRX FEEs ###
#########################
calc_adjusted_amount

BF21_txfee=$(( $TX_bytes * $BF21_txfee_per_byte ))
if [ $txfee_param_flag -eq 0 ] ; then
  printf "### bitcoinfees.21.co (@ $BF21_txfee_per_byte Satoshi/Byte * $TX_bytes TX_bytes):"
  line_length=$(( ${#txfee_per_byte} + ${#TX_bytes} ))
  case $line_length in
   3) printf "     %10d" $BF21_txfee
      ;;
   4) printf "    %10d" $BF21_txfee
      ;;
   5) printf "   %10d" $BF21_txfee
      ;;
   6) printf "  %10d" $BF21_txfee
      ;;
   7) printf " %10d" $BF21_txfee
      ;;
   8) printf "%10d" $BF21_txfee
      ;;
  esac
  printf " ###\n" $BF21_txfee
fi

c_txfee=$(( $txfee_per_byte * $TX_bytes ))
printf "### calculated TX-FEE (@ $txfee_per_byte Satoshi/Byte * $TX_bytes TX_bytes):"
line_length=$(( ${#txfee_per_byte} + ${#TX_bytes} ))
case $line_length in
 3) printf "      %10d" $c_txfee
    ;;
 4) printf "     %10d" $c_txfee
    ;;
 5) printf "    %10d" $c_txfee
    ;;
 6) printf "   %10d" $c_txfee
    ;;
 7) printf "  %10d" $c_txfee
    ;;
 8) printf " %10d" $c_txfee
    ;;
 9) printf "%10d" $c_txfee
    ;;
esac
printf " ###\n" $c_txfee

if [ "$f_param_flag" -eq 1 ] ; then
  f_txfee=$(( $file_utxo_amount - $TX_amount ))
  d_amount=$(( $file_utxo_amount - $TX_amount - $c_txfee ))
elif [ "$t_param_flag" -eq 1 ] ; then
  f_txfee=$(( $prev_tx_utxo_amount - $TX_amount ))
  d_amount=$(( $prev_tx_utxo_amount - $TX_amount - $c_txfee ))
else
  f_txfee=$(( $utxo_Amount - $TX_amount ))
  d_amount=$(( $utxo_Amount - $TX_amount - $c_txfee ))
fi

if [ $d_amount -lt 0 ] ; then
  printf "### Achieving negative value with this txfee:          %16d ###\n" $d_amount 
  if [ $a_txfee_per_byte -lt $txfee_per_byte ] ; then
    printf "### adjusted TX-FEE (@ $a_txfee_per_byte Satoshi/Byte * $TX_bytes TX_bytes):"
    line_length=$(( ${#a_txfee_per_byte} + ${#TX_bytes} ))
    case $line_length in
       5) printf "      %10d" $a_txfee
          ;;
       6) printf "     %10d" $a_txfee
          ;;
       7) printf "    %10d" $a_txfee
          ;;
       8) printf "   %10d" $a_txfee
          ;;
       9) printf "  %10d" $a_txfee
          ;;
      10) printf " %10d" $a_txfee
          ;;
      11) printf "%10d" $a_txfee
          ;;
    esac
    printf " ###\n" $a_txfee
  fi
  if [ "$f_param_flag" -eq 1 ] ; then
    f_txfee=$(( $file_utxo_amount - $TX_amount ))
    d_amount=$(( $file_utxo_amount - $TX_amount - $a_txfee ))
  elif [ "$t_param_flag" -eq 1 ] ; then
    f_txfee=$(( $prev_tx_utxo_amount - $TX_amount ))
    d_amount=$(( $prev_tx_utxo_amount - $TX_amount - $a_txfee ))
  else
    f_txfee=$(( $utxo_Amount - $TX_amount ))
    d_amount=$(( $utxo_Amount - $TX_amount - $a_txfee ))
  fi
fi
if [ $d_amount -lt 0 ] ; then
  echo "*** ERROR: input insufficient, to cover amount and tx fees"
  echo "           please adjust, and retry. Exiting gracefully ..." 
  echo " "
  exit 0
fi


if [ ${#RETURN_Address} -gt 28 ] ; then
  printf "### value to return address:                           %16d ###\n" $d_amount 
else
  printf "### *** possible value to return address:              %16d ###\n" $d_amount 
  printf "### *** without return address, txfee will be:         %16d ###\n" $f_txfee 
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


