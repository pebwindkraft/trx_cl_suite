#!/bin/sh
# tool to sign any unsigned raw transaction
# 
# Copyright (c) 2015, 2016 Volker Nowarra 
# Coded in June 2016 following this reference:
#   https://en.bitcoin.it/wiki/Protocol_specification#tx
#   http://bitcoin.stackexchange.com/questions/3374/how-to-redeem-a-basic-tx
# 
#
# Version	by      date    comment
# 0.1		svn     26sep16 initial release from trx2txt (which is now discontinued)
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
# https://en.bitcoin.it/wiki/Elliptic_Curve_Digital_Signature_Algorithm:
# signature: A number that proves that a signing operation took place. A signature 
# is mathematically generated from a hash of something to be signed, plus a private 
# key. The signature itself is two numbers known as r and s. With the public key, a 
# mathematical algorithm can be used on the signature to determine that it was 
# originally produced from the hash and the private key, without needing to know 
# the private key. Signatures are either 73, 72, or 71 bytes long, with probabilities
# approximately 25%, 50% and 25% respectively, although sizes even smaller than that
# are possible with exponentially decreasing probability.
#
#
###########################
# Some variables ...      #
###########################
QUIET=0
VERBOSE=0
VVERBOSE=0

typeset -r srtx_fn=tmp_srtx.txt
typeset -r urtx_fn=tmp_urtx.txt
typeset -r urtx_raw_fn=tmp_urtx.raw
typeset -r urtx_sha256_raw_fn=tmp_urtx_sha256.raw 
typeset -r urtx_dsha256_raw_fn=tmp_urtx_dsha256.raw

typeset -r Version=01000000
typeset -r TX_IN_Sequence=ffffffff
typeset -r LockTime=00000000

typeset -i TX_IN_Count=0
typeset -i TX_OUT_Count=0
typeset -i TX_IN_ScriptBytes=0
typeset -i TX_OUT_PKScriptBytes=0
typeset -i i=0
typeset -i from=0
typeset -i to=0
typeset -i F_PARAM_FLAG=0

TX_IN_Count_hex=''
TX_IN_PrevOutput_Hash=''
TX_IN_PrevOutput_Index=''
TX_IN_Sig_Script=''
TX_OUT_Count_hex=''
TX_OUT_Value=''
TX_OUT_PKScriptBytes_hex=''
TX_OUT_PKScript=''

SIGNED_TRX=''

filename=''
hex_privkey=''
wif_privkey=''
STEPCODE=''
SCRIPTSIG=''

#################################
# procedure to display helptext #
#################################
proc_help() {
  echo " "
  echo "sign usage:   $0 [-h|-q|-v|-vv] [-f <filename>]|[<raw_trx>] -w|-x <privkey> -p <pubkey>"
  echo " "
  echo " -h  show this HELP text"
  echo " -q  real QUIET mode, don't display anything"
  echo " -v  display VERBOSE output"
  echo " -vv display VERY VERBOSE output"
  echo " "
  echo " -f  next param is a filename with an unsigned raw transaction"
  echo " -p  next param is a public key (UNCOMPRESSED or COMPRESSED) in hex format"
  echo " -w  next param is a WIF or WIF-C encoded private key (51 or 52 chars)"
  echo " -x  next param is a HEX encoded private key (32Bytes=64chars)"
  echo " "
}

###########################################################################
### procedure to indent data, to avoid ugly line breaks ...             ###
###########################################################################
indent_data() {
  output=''
  indent_string="    "
  if [ ${#1} -gt 150 ] ; then
    echo "$1" | cut -b 1-75
    output=$( echo "$1" | cut -b 76-146 )
    echo "$indent_string$output"
    output=$( echo "$1" | cut -b 147- )
    echo "$indent_string$output"
  elif [ ${#1} -gt 75 ] ; then
    echo "$1" | cut -b 1-75
    output=$( echo "$1" | cut -b 76- )
    echo "$indent_string$output"
  else
    echo "$1"
  fi
}

#######################################
# procedure to display verbose output #
#######################################
v_output() {
  if [ $VERBOSE -eq 1 ] ; then
    indent_data "$1"
  fi
}

#################################################
# procedure to display even more verbose output #
#################################################
vv_output() {
  if [ $VVERBOSE -eq 1 ] ; then
    indent_data "$1"
  fi
}

#################################################
# procedure to concatenate string for raw trx   #
#################################################
trx_concatenate() {
  SIGNED_TRX=$SIGNED_TRX$STEPCODE
  vv_output "$SIGNED_TRX"
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

echo "#######################################################"
echo "### tcls_sign.sh: sign an unsigned, raw Bitcoin trx ###"
echo "#######################################################"

################################
# command line params handling #
################################

if [ "$1" == "-h" ] ; then
  proc_help
  exit 0
fi  

if [ "$1" == "-f" ] && [ "$2" == "help" ] ; then
  echo " provide the following parameters:"
  echo " -f <filename>: the filename with an unsigned, raw transaction"
  echo " "
  exit 0
fi  

if [ $# -lt 3 ] ; then
  echo "insufficient parameter(s) given... "
  echo " "
  proc_help
  exit 0
else
  while [ $# -ge 1 ] 
   do
    case "$1" in
      -f)
         F_PARAM_FLAG=1
         if [ "$2" == ""  ] ; then
           echo "*** you must provide a FILENAME to the -f parameter!"
           exit 1
         fi
         filename=$2
         shift 
         shift 
         ;;
      -p)
         pubkey=$2
         shift
         shift
         ;;
      -q)
         QUIET=1
         shift
         ;;
      -v)
         VERBOSE=1
         echo "VERBOSE output turned on"
         echo " "
         shift
         ;;
      -vv)
         VERBOSE=1
         VVERBOSE=1
         echo "VERY VERBOSE and VERBOSE output turned on"
         echo " "
         shift
         ;;
      -w)
         if [ "$hex_privkey" ] ; then 
           echo "*** cannot use -w and -x at the same time, exiting gracefully ..."
           exit 1
         fi
         wif_privkey=$2
         if [ ${#wif_privkey} -ne 51 ] && [ ${#wif_privkey} -ne 52 ] ; then 
           echo "*** wrong privkey length (${#wif_privkey}), must be 51 or 52 chars"
           exit 1
         fi
         shift
         shift
         ;;
      -x)
         if [ "$wif_privkey" ] ; then 
           echo "*** cannot use -x and -w at the same time, exiting gracefully ..."
           exit 1
         fi
         hex_privkey=$2
         if [ ${#hex_privkey} -ne 64 ] ; then 
           echo "*** wrong privkey length (${#hex_privkey}), must be 64 chars (32 Bytes)"
           exit 1
         fi
         shift
         shift
         ;;
      *)
         UR_TRX=$1
         shift
#        echo "unknown parameter(s), don't know what to do. Exiting gracefully ..."
#        proc_help
#        exit 1
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
check_tool cut
check_tool od
check_tool openssl
check_tool sed
check_tool tr

###################
### so let's go ###
###################

if [ $F_PARAM_FLAG -eq 1 ] ; then
  vv_output "reading data from file $filename"
  UR_TRX=$( cat $filename )
fi
UR_TRX=$( printf "$UR_TRX" | tr [:upper:] [:lower:] )

v_output "#######################################################"
v_output "### collect all tx_in data into array variables...  ###"
v_output "#######################################################"

##############################################################################
### STEP 1 - VERSION - this is currently set to 01000000 (4 Bytes)         ###
##############################################################################
v_output "1.  Version, currently set to 01000000"
from=1
to=8
STEPCODE=$( echo $UR_TRX | cut -b $from-$to )
if [ "$STEPCODE" != "$Version" ] ; then 
  echo "*** Error: unsigned raw transaction normally begins with Version '01000000'"
  echo "           here we have $STEPCODE. Please adjust, and try again. "
  echo "           Exiting gracefully"
  exit 1
fi
v_output "    $STEPCODE"

##############################################################################
### STEP 2 - TX_IN_Count, a var_int                                        ###
##############################################################################
v_output "2.  TX_IN_COUNT, the number of input trx "
from=$(( $to + 1 ))
to=$(( $from + 1 ))
TX_IN_Count_hex=$( echo $UR_TRX | cut -b $from-$to)
# need to do a var_int check here ...
TX_IN_Count=$( echo "ibase=16;$TX_IN_Count_hex" | bc )
v_output "    $TX_IN_Count_hex (decimal $TX_IN_Count)"

#######################################################
### collect all tx_in data into array variables...  ###
#######################################################
# here we know, how many TX_IN structures will follow, 
# so we collect all TX_IN data into simple arrays
i=1
while [ $i -le $TX_IN_Count ] 
 do
  # Arrays: difference between BASH and KSH !
  # below works in bash 3 and 4, and in ksh. BUT (!): do not declare the arrays
  # at the beginning. BASH uses "declare", ksh uses "typeset -a" ...
  # arr_var[0]="0"
  # echo ${arr_var[@]}
  # echo "arr_var[0]=${arr_var[0]}"
  # v_output "    TX_IN[$i] ########## "
  ##############################################################################
  ### STEP 3 - TX_IN_PrevOutput_Hash, previous transaction hash (32Bytes)    ###
  ##############################################################################
  v_output "3.  TX_IN[$i] PrevOutput_Hash: a transaction hash"
  from=$(( $to + 1 ))
  to=$(( $from + 63 ))
  STEPCODE=$( echo $UR_TRX | cut -b $from-$to )
  TX_IN_PrevOutput_Hash[$i]="$STEPCODE"
  v_output "    ${TX_IN_PrevOutput_Hash[$i]}"
  
  ##############################################################################
  ### STEP 4 - TX_IN_PrevOutput_Index, the output index we want to use       ###
  ##############################################################################
  v_output "4.  TX_IN[$i] PrevOutput_Index: the output index, we want to redeem from"
  from=$(( $to + 1 ))
  to=$(( $from + 7 ))
  TX_IN_PrevOutput_Index[$i]=$( echo $UR_TRX | cut -b $from-$to )
  v_output "    ${TX_IN_PrevOutput_Index[$i]}"
  
  ##############################################################################
  ### STEP 5 - TX_IN, script bytes: length of following uchar[] (2 chars)    ###
  ##############################################################################
  # For the purpose of signing the transaction, this is temporarily filled 
  # with the scriptPubKey of the output we want to redeem. 
  v_output "5.  TX_IN[$i] ScriptBytes: length of prev trx PK Script"
  from=$(( $to + 1 ))
  to=$(( $from + 1 ))
  TX_IN_ScriptBytes_hex[$i]="$( echo $UR_TRX | cut -b $from-$to )"
  # need to do a var_int check here ...
  TX_IN_ScriptBytes[$i]=$( echo "ibase=16;${TX_IN_ScriptBytes_hex[$i]}" | bc )
  v_output "    ${TX_IN_ScriptBytes_hex[$i]} (decimal ${TX_IN_ScriptBytes[$i]})"
  
  ##############################################################################
  ### STEP 6 - TX_IN_Sig_Script, uchar[] - variable length                   ###
  ##############################################################################
  # the actual scriptSig (which is the PubKey script of the PREV_TRX)
  v_output "6.  TX_IN[$i] Sig_Script, uchar[]: variable length"
  from=$(( $to + 1 ))
  STEPCODE=$(( ${TX_IN_ScriptBytes[$i]} * 2 ))
  to=$(( $from - 1 + $STEPCODE ))
  STEPCODE=$( echo $UR_TRX | cut -b $from-$to )
  TX_IN_Sig_Script[$i]="$STEPCODE"
  v_output "    ${TX_IN_Sig_Script[$i]}"
  
  ##############################################################################
  ### STEP 7 - TX_IN_Sequence: This is currently always set to 0xffffffff    ###
  ##############################################################################
  # This is currently always set to 0xffffffff
  v_output "7.  TX_IN[$i] Sequence, this is currently always set to 0xffffffff"
  from=$(( $to + 1 ))
  to=$(( $from + 7 ))
  STEPCODE=$( echo $UR_TRX | cut -b $from-$to )
  if [ "$STEPCODE" != "$TX_IN_Sequence" ] ; then 
    echo "*** Error: TX_IN_Sequence normally is 'ffffffff'"
    echo "           here we have $STEPCODE. Please adjust, and try again. "
    echo "           Exiting gracefully"
    exit 1
  fi
  v_output "    $STEPCODE"
  i=$(( i + 1 ))
done

##############################################################################
### STEP 8 - TX_OUT_COUNT (var_int): the number of output trx              ###
##############################################################################
v_output "8.  TX_OUT_COUNT, the number of output trx"
from=$(( $to + 1 ))
to=$(( $from + 1 ))
TX_OUT_Count_hex=$( echo $UR_TRX | cut -b $from-$to )
# need to do a var_int check here ...
TX_OUT_Count=$( echo "ibase=16;$TX_OUT_Count_hex" | bc )
v_output "    $TX_OUT_Count_hex (decimal $TX_OUT_Count)"


##############################################################################
### STEP 9 - TX_OUT_Value, the value in hex that will be transferred       ###
##############################################################################
v_output "9.  TX_OUT_Value, the value in hex that will be transferred"
from=$(( $to + 1 ))
to=$(( $from + 15 ))
STEPCODE=$( echo $UR_TRX | cut -b $from-$to )
TX_OUT_Value="$STEPCODE"
v_output "    $TX_OUT_Value"

##############################################################################
### STEP 10 - TX_OUT_PKScriptBytes: length of following uchar[] (2 chars)  ###
##############################################################################
v_output "10. TX_OUT_PKScriptBytes: length of PK Script"
from=$(( $to + 1 ))
to=$(( $from + 1 ))
TX_OUT_PKScriptBytes_hex=$( echo $UR_TRX | cut -b $from-$to )
TX_OUT_PKScriptBytes=$( echo "ibase=16;$TX_OUT_PKScriptBytes_hex" | bc )
v_output "    $TX_OUT_PKScriptBytes_hex (decimal $TX_OUT_PKScriptBytes)"
  
##############################################################################
### STEP 11 - TX_OUT_PKScript, uchar[] - variable length                   ###
##############################################################################
# the actual PKScript where the trx value will go to ...
v_output "11. TX_OUT_PKScript, uchar[]: variable length"
from=$(( $to + 1 ))
STEPCODE=$(( $TX_OUT_PKScriptBytes * 2 ))
to=$(( $from - 1 + $STEPCODE ))
TX_OUT_PKScript=$( echo $UR_TRX | cut -b $from-$to )
v_output "    $TX_OUT_PKScript"

##############################################################################
### STEP 12 - LOCKTIME: this is currently set to 00000000 (4 Bytes)        ###
##############################################################################
v_output "12. LockTime, currently always set to 00000000"
from=$(( $to + 1 ))
to=$(( $from + 7 ))
STEPCODE=$( echo $UR_TRX | cut -b $from-$to)
if [ "$STEPCODE" != "$LockTime" ] ; then 
  echo "*** Error: unsigned raw transaction normally ends with LockTime '00000000'"
  echo "           here we have $STEPCODE. Please adjust, and try again. "
  echo "           Exiting gracefully"
  exit 1
fi
v_output "    $STEPCODE"

v_output " "
v_output "#####################################"
v_output "### create signed raw transaction ###"
v_output "#####################################"

##############################################################################
### STEP 13 - create the unsigned, raw trx for each input                  ###
##############################################################################
v_output "13. create the unsigned raw tx(s), hash it(14), sign it(15), check it(16)"

# if [ -f $urtx_fn ] ; then 
#   rm $urtx_fn
# fi
i=1
j=1
while [ $j -le $TX_IN_Count ] 
 do
  printf $Version > $urtx_fn
  # need to do a var_int check here ...
  printf $TX_IN_Count_hex >> $urtx_fn

  # manage all the TX_INs
  while [ $i -le $TX_IN_Count ] 
   do
    printf ${TX_IN_PrevOutput_Hash[$i]} >> $urtx_fn
    printf ${TX_IN_PrevOutput_Index[$i]} >> $urtx_fn
    if [ $i -eq $j ] ; then
      printf ${TX_IN_ScriptBytes_hex[$i]} >> $urtx_fn
      printf ${TX_IN_Sig_Script[$i]} >> $urtx_fn
    fi
    printf $TX_IN_Sequence >> $urtx_fn
    i=$(( i + 1 ))
  done

  # manage all the TX_OUTs
  printf $TX_OUT_Count_hex >> $urtx_fn
  printf $TX_OUT_Value >> $urtx_fn
  printf $TX_OUT_PKScriptBytes_hex >> $urtx_fn
  printf $TX_OUT_PKScript >> $urtx_fn
  printf $LockTime >> $urtx_fn

  ##############################################################################
  ### STEP 14 - HASH the raw unsigned trx                                    ###
  ##############################################################################
  v_output "14. TX_IN[$j]: double hash the raw unsigned TX"
  
  # Bitcoin never does sha256 with the hex chars, so need to convert it to hex codes first
  cat $urtx_fn | tr [:upper:] [:lower:] > $urtx_raw_fn
  result=$( cat $urtx_raw_fn | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
  printf $result > $urtx_raw_fn

  openssl dgst -binary -sha256 >$urtx_sha256_raw_fn  <$urtx_raw_fn 
  openssl dgst -binary -sha256 >$urtx_dsha256_raw_fn <$urtx_sha256_raw_fn 
  
  if [ "$VVERBOSE" -eq 1 ] ; then 
    echo "    the unsigned raw trx, sha256'd ($urtx_sha256_raw_fn):"
    hexdump -C $urtx_sha256_raw_fn | sed -e 's/^/    /'
    echo "    the unsigned raw trx, double sha256'd ($urtx_dsha256_raw_fn):"
    hexdump -C $urtx_dsha256_raw_fn | sed -e 's/^/    /'
  fi
  
  ##############################################################################
  ### STEP 15 - OpenSSL sign the hash from step 14 with the private key      ###
  ##############################################################################
  # 15. We then create a public/private key pair out of the provided private key. 
  #     We sign the hash from step 14 with the private key. 
  #     and add the one byte hash code "01" to it's end.
  v_output "15. TX_IN[$j]: sign the hash from step 14 with the private key"
  # verify keys are working correctly ...
  if [ "$hex_privkey" ] ; then 
    ./trx_key2pem.sh -q -x $hex_privkey -p $pubkey 
    if [ $? -eq 1 ] ; then 
      echo "*** error in key handling, exiting gracefully ..."
      exit 1
    fi
  else
    ./trx_key2pem.sh -q -w $wif_privkey -p $pubkey 
    if [ $? -eq 1 ] ; then 
      echo "*** error in key handling, exiting gracefully ..."
      exit 1
    fi
  fi
  v_output "     -->openssl dgst -sha256 -sign privkey.pem -out tmp_trx.sig $urtx_dsha256_raw_fn"
  openssl dgst -sha256 -sign privkey.pem -out tmp_trx.sig $urtx_dsha256_raw_fn
  SCRIPTSIG=$( od -An -t x1 tmp_trx.sig | tr -d [:blank:] | tr -d "\n" )
  vv_output "    $SCRIPTSIG"
 
  # the strict DER checking puts the SCRIPTSIG into file "tmp_trx.sig"
  if [ $VERBOSE -eq 1 ] ; then
    ./tcls_strict_sig_verify.sh -v $SCRIPTSIG
    if [ $? -eq 1 ] ; then 
      echo "*** ERROR in ScriptSig verification, exiting gracefully ..."
      exit 1
    fi
  else 
    ./tcls_strict_sig_verify.sh -q $SCRIPTSIG
    if [ $? -eq 1 ] ; then 
      echo "*** ERROR in ScriptSig verification, exiting gracefully ..."
      exit 1
    fi
  fi

  ##############################################################################
  ### STEP 16 - construct the final scriptSig                                ###
  ##############################################################################
  # 16. We construct the final scriptSig by concatenating: 
  v_output "16. TX_IN[$j]: construct the final scriptSig[$j]"
  # a: <One-byte script OPCODE containing the length of the DER-encoded signature plus 1>
  #       (for the one byte len code itself)
  STEPCODE=$( wc -c < "tmp_trx.sig" )
  STEPCODE=$( echo "obase=16;$STEPCODE + 1" | bc )
  SCRIPTSIG[$j]=$STEPCODE

  # b: <we add the the actual DER-encoded signature, and a '01' as hex code>
  vv_output "    Add a '01' as end identifier to sig"
  # Strict DER checking had it's output in file "tmp_trx.sig" 
  #  - need to convert file to a string first:
  STEPCODE=$( od -An -t x1 tmp_trx.sig | tr -d [[:blank:]] | tr -d "\n" )
  SCRIPTSIG[$j]=${SCRIPTSIG[$j]}$STEPCODE
  STEPCODE=01
  SCRIPTSIG[$j]=${SCRIPTSIG[$j]}$STEPCODE
  vv_output "    ${SCRIPTSIG[$j]}"

  # c: <One-byte script OPCODE containing the length of the public key>
  STEPCODE=${#pubkey}
  STEPCODE=$( echo "obase=16;$STEPCODE / 2" | bc )
  vv_output "    len pubkey in hex=$STEPCODE (Bytes)"
  SCRIPTSIG[$j]=${SCRIPTSIG[$j]}$STEPCODE

  # d: <The actual public key>
  SCRIPTSIG[$j]=${SCRIPTSIG[$j]}$pubkey
  vv_output "    ${SCRIPTSIG[$j]}"
  vv_output " "
    
  i=1
  j=$(( j + 1 ))

done

##############################################################################
### STEP 17 - concat the new transacton - we have all data in variables    ###
##############################################################################
# 17. We then replace the one-byte, varint length-field from step 5 with the length of 
#     the data from step 16. The length is in chars, devide it by 2 and convert to hex.
# 
v_output "17. concatenate the final transaction for all inputs and outputs"
#   STEP1  = Version (4 bytes)               -->  4  Bytes -->  8 chars
# / STEP2  = TX_IN_Count (var_int!)          -->  1+ Byte  -->  2 chars
# | STEP3  = TX_IN_PrevOutput_Hash           --> 32  Bytes --> 64 chars
# | STEP4  = TX_IN_PrevOutput_Index          -->  4  Bytes -->  8 chars
# | STEP5  = TX_IN_ScriptBytes (var_int!)    -->  1+ Bytes -->  8 chars
# | STEP6  = TX_IN_Sig_Script (uchar[])      --> 10+ Bytes -->  8 chars
# \ STEP7  = TX_IN_Sequence                  -->  4  Bytes -->  8 chars
# 
# / STEP8  = TX_OUT_Count (var_int!)         -->  1+ Bytes -->  8 chars
# | STEP9  = TX_OUT_Value                    -->  8  Bytes --> 16 chars
# | STEP10 = TX_OUT_PKScriptBytes (var_int!) -->  1+ Bytes -->  8 chars
# \ STEP11 = TX_OUT_PKScript (uchar[])       --> 10+ Bytes -->  8 chars
#   STEP12 = LockTime                        -->  4  Bytes -->  8 chars

vv_output "    Version"
STEPCODE=$Version
trx_concatenate
vv_output "    TX_IN_Count"
STEPCODE=$TX_IN_Count_hex
trx_concatenate
j=1
while [ $j -le $TX_IN_Count ] 
 do
  vv_output "    TX_IN[$j] PrevOutput_Hash"
  STEPCODE=${TX_IN_PrevOutput_Hash[$j]}
  trx_concatenate

  vv_output "    TX_IN[$j] PrevOutput_Index"
  STEPCODE=${TX_IN_PrevOutput_Index[$j]}
  trx_concatenate

  # TX_IN_ScriptBytes[$j] 
  vv_output "    TX_IN[$j] ScriptBytes"
  STEPCODE=${#SCRIPTSIG[$j]}
  STEPCODE=$( echo "obase=16;$STEPCODE / 2" | bc )
  trx_concatenate

  vv_output "    TX_IN[$j] SCRIPTSIG"
  STEPCODE=${SCRIPTSIG[$j]}
  trx_concatenate

  vv_output "    TX_IN[$j] Sequence"
  STEPCODE=$TX_IN_Sequence
  trx_concatenate
  j=$(( j + 1 ))
 done

# here we would need to create a TX_OUT loop, not yet implemented...
# j=1
# while [ $j -le $TX_OUT_Count ] 
#  do
  vv_output "    TX_OUT_Count_hex"
  STEPCODE=$TX_OUT_Count_hex
  trx_concatenate
  vv_output "    TX_OUT_Value"
  STEPCODE=$TX_OUT_Value
  trx_concatenate
  vv_output "    TX_OUT_PKScriptBytes"
  STEPCODE=$TX_OUT_PKScriptBytes_hex
  trx_concatenate
  vv_output "    TX_OUT_PKScript"
  STEPCODE=$TX_OUT_PKScript
  trx_concatenate
  vv_output "    LockTime"
  STEPCODE=$LockTime
  trx_concatenate
# done

echo $SIGNED_TRX > tmp_srtx.txt
vv_output $SIGNED_TRX
vv_output " "

################################
### and here we are done :-) ### 
################################


