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
# the signing process in short:
#  prepare keys:
#   openssl ecparam -genkey -name secp256k1 -noout -out privkey.pem
#   openssl ec -in privkey.pem -pubout -out pubkey.pem
#   openssl ec -in privkey.pem -pubout -out pubkey.pem -conv_form compressed
#  sign:
#   openssl dgst -sign privkey.pem  -sha256 -hex tmp_c_urtx.txt
#   openssl dgst -sign privkey.pem  -sha256 tmp_c_urtx.txt > tmp_sig.hex
#  verify:
#   openssl dgst -verify pubkey.pem -sha256 -signature tmp_sig.hex tmp_c_urtx.txt
# 
# echo "MDYwEAYHKo...BASE64_PART_OF_PEM...3txRPk8bqOWhIkprA=" | base64 -D - | hexdump -C
# 
###########################
# Some variables ...      #
###########################
QUIET=0
VERBOSE=0
VVERBOSE=0

typeset -r stx_fn=tmp_stx.txt                  # signed trx file after the end of this script
typeset -r utxhex_tmp_fn=tmp_utx.txt           # the txt assembled, unsigned tx per tx input
typeset -r utxtxt_tmp_fn=tmp_utx.hex           # the hex assembled, unsigned tx per tx input
typeset -r sighex_tmp_fn=tmp_sig.hex           # openssl's signature per tx input in hex
typeset -r sigtxt_tmp_if=tmp_tssv_in.txt       # txt input file for tcls_strict_sig_verify
typeset -r sigtxt_tmp_of=tmp_tssv_out.txt      # txt output file for tcls_strict_sig_verify
typeset -r utx_sha256_fn=tmp_utx_sha256.hex    # the sha256 hashed tx 
typeset -r utx_dsha256_fn=tmp_utx_dsha256.hex  # the double sha256 hashed tx
typeset -r tmp_vfy_fn=tmp_vfy.txt              # for all tx inputs, put sig, hash and pubkey here

typeset -r Version=01000000
typeset -r TX_IN_Sequence=ffffffff
typeset -r LockTime=00000000
typeset -r SIGHASH_ALL=01000000

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

script_key2pem=tcls_key2pem.sh
script_ssvfy=tcls_strict_sig_verify.sh

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
  offset=75
  ifrom=1
  ito=$offset

  # echo "ifrom=$ifrom, ito=$ito"
  echo "$1" | cut -b $ifrom-$ito
  while [ $ito -le ${#1} ] 
   do
    ifrom=$(( $ito + 1 ))
    ito=$(( $ifrom + $offset ))
    output=$( echo "$1" | cut -b $ifrom-$ito )
    echo "$indent_string$output"
  done

# if [ ${#1} -gt 150 ] ; then
#   echo "$1" | cut -b 1-75
#   output=$( echo "$1" | cut -b 76-146 )
#   echo "$indent_string$output"
#   output=$( echo "$1" | cut -b 147- )
#   echo "$indent_string$output"
# elif [ ${#1} -gt 75 ] ; then
#   echo "$1" | cut -b 1-75
#   output=$( echo "$1" | cut -b 76- )
#   echo "$indent_string$output"
# else
#   echo "$1"
# fi
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
         UNSIGNED_TX=$1
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

if [ $QUIET -ne 1 ] ; then
  echo "let's go ..."
fi

if [ $F_PARAM_FLAG -eq 1 ] ; then
  if [ ! -r $filename ] ; then
    echo "*** Error: the file $filename could not be read"
    echo "           make sure file exists, or change filename acordingly"
    echo "           Exiting gracefully"
    exit 1
  fi
  vv_output "reading data from file $filename"
  UNSIGNED_TX=$( cat $filename )
fi
UNSIGNED_TX=$( printf "$UNSIGNED_TX" | tr [:upper:] [:lower:] )

v_output "#######################################################"
v_output "### collect all tx_in data into array variables...  ###"
v_output "#######################################################"

##############################################################################
### STEP 1 - VERSION - this is currently set to 01000000 (4 Bytes)         ###
##############################################################################
v_output "1.  Version, currently set to 01000000"
from=1
to=8
STEPCODE=$( echo $UNSIGNED_TX | cut -b $from-$to )
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
TX_IN_Count_hex=$( echo $UNSIGNED_TX | cut -b $from-$to)
# need to do a var_int check here ...
TX_IN_Count=$( echo "ibase=16;$TX_IN_Count_hex" | bc )
v_output "    $TX_IN_Count_hex (decimal $TX_IN_Count)"

#######################################################
### collect all tx_in data into array variables...  ###
#######################################################
# here we know, how many TX_IN structures will follow, 
# so we collect all TX_IN data into simple arrays
i=1
while [ $i -le $TX_IN_Count ] 
 do
  j=$(( i - 1 )) # just to make the output headlines correct in their counter
  # Arrays: difference between BASH and KSH !
  # below works in bash 3 and 4, and in ksh. BUT (!): do not declare the arrays
  # at the beginning. BASH uses "declare", ksh uses "typeset -a" ...
  # arr_var[0]="0"
  # echo ${arr_var[@]}
  # echo "arr_var[0]=${arr_var[0]}"
  # v_output "    TX_IN[$i] ########## "
  ##############################################################################
  ### STEP 3 - TX_IN_PrevOutput_Hash, previous transaction hash (32Bytes)    ###
  ##############################################################################
  v_output "3.  TX_IN[$j] PrevOutput_Hash: a transaction hash"
  from=$(( $to + 1 ))
  to=$(( $from + 63 ))
  STEPCODE=$( echo $UNSIGNED_TX | cut -b $from-$to )
  TX_IN_PrevOutput_Hash[$i]="$STEPCODE"
  v_output "    ${TX_IN_PrevOutput_Hash[$i]}"
  
  ##############################################################################
  ### STEP 4 - TX_IN_PrevOutput_Index, the output index we want to use       ###
  ##############################################################################
  v_output "4.  TX_IN[$j] PrevOutput_Index: the output index, we want to redeem from"
  from=$(( $to + 1 ))
  to=$(( $from + 7 ))
  TX_IN_PrevOutput_Index[$i]=$( echo $UNSIGNED_TX | cut -b $from-$to )
  v_output "    ${TX_IN_PrevOutput_Index[$i]}"
  
  ##############################################################################
  ### STEP 5 - TX_IN, script bytes: length of following uchar[] (2 chars)    ###
  ##############################################################################
  # For the purpose of signing the transaction, this is temporarily filled 
  # with the scriptPubKey of the output we want to redeem. 
  v_output "5.  TX_IN[$j] ScriptBytes: length of prev trx PK Script"
  from=$(( $to + 1 ))
  to=$(( $from + 1 ))
  TX_IN_ScriptBytes_hex[$i]="$( echo $UNSIGNED_TX | cut -b $from-$to )"
  # need to do a var_int check here ...
  TX_IN_ScriptBytes[$i]=$( echo "ibase=16;${TX_IN_ScriptBytes_hex[$i]}" | bc )
  v_output "    ${TX_IN_ScriptBytes_hex[$i]} (decimal ${TX_IN_ScriptBytes[$i]})"
  
  ##############################################################################
  ### STEP 6 - TX_IN_Sig_Script, uchar[] - variable length                   ###
  ##############################################################################
  # the actual scriptSig (which is the PubKey script of the PREV_TRX)
  v_output "6.  TX_IN[$j] Sig_Script, uchar[]: variable length"
  from=$(( $to + 1 ))
  STEPCODE=$(( ${TX_IN_ScriptBytes[$i]} * 2 ))
  to=$(( $from - 1 + $STEPCODE ))
  STEPCODE=$( echo $UNSIGNED_TX | cut -b $from-$to )
  TX_IN_Sig_Script[$i]="$STEPCODE"
  v_output "    ${TX_IN_Sig_Script[$i]}"
  
  ##############################################################################
  ### STEP 7 - TX_IN_Sequence: This is currently always set to 0xffffffff    ###
  ##############################################################################
  # This is currently always set to 0xffffffff
  v_output "7.  TX_IN[$j] Sequence, this is currently always set to 0xffffffff"
  from=$(( $to + 1 ))
  to=$(( $from + 7 ))
  STEPCODE=$( echo $UNSIGNED_TX | cut -b $from-$to )
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
TX_OUT_Count_hex=$( echo $UNSIGNED_TX | cut -b $from-$to )
# need to do a var_int check here ...
TX_OUT_Count=$( echo "ibase=16;$TX_OUT_Count_hex" | bc )
v_output "    $TX_OUT_Count_hex (decimal $TX_OUT_Count)"


##############################################################################
### STEP 9 - TX_OUT_Value, the value in hex that will be transferred       ###
##############################################################################
v_output "9.  TX_OUT_Value, the value in hex that will be transferred"
from=$(( $to + 1 ))
to=$(( $from + 15 ))
STEPCODE=$( echo $UNSIGNED_TX | cut -b $from-$to )
TX_OUT_Value="$STEPCODE"
v_output "    $TX_OUT_Value"

##############################################################################
### STEP 10 - TX_OUT_PKScriptBytes: length of following uchar[] (2 chars)  ###
##############################################################################
v_output "10. TX_OUT_PKScriptBytes: length of PK Script"
from=$(( $to + 1 ))
to=$(( $from + 1 ))
TX_OUT_PKScriptBytes_hex=$( echo $UNSIGNED_TX | cut -b $from-$to )
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
TX_OUT_PKScript=$( echo $UNSIGNED_TX | cut -b $from-$to )
v_output "    $TX_OUT_PKScript"

##############################################################################
### STEP 12 - LOCKTIME: this is currently set to 00000000 (4 Bytes)        ###
##############################################################################
v_output "12. LockTime, currently always set to 00000000"
from=$(( $to + 1 ))
to=$(( $from + 7 ))
STEPCODE=$( echo $UNSIGNED_TX | cut -b $from-$to)
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
### STEP 13 - serialize the unsigned raw tx and add 01000000 (SIGHASH_ALL) ###
##############################################################################
v_output "13. serialize the unsigned raw tx and add 01000000 (SIGHASH_ALL)"

i=1
j=1
k=1
echo "##############################################" > $tmp_vfy_fn
echo "### Bitcoin prep file to verify signatures ###" >> $tmp_vfy_fn
echo "##############################################" >> $tmp_vfy_fn
if [ "$VERBOSE" -eq 1 ] ; then 
  echo "# Bitcoin (and so here openssl) works only on binary files. TX hash files" >> $tmp_vfy_fn
  echo "# must be double sha256'd. For each input, need to convert to binary." >> $tmp_vfy_fn
  echo "# The pubkey is: $pubkey " >> $tmp_vfy_fn
  echo "# The pubkey.pem file is provided from here: $script_key2pem" >> $tmp_vfy_fn
  echo "# If you need YOUR OWN pubkey, you need to convert it first:" >> $tmp_vfy_fn
  echo "# UNCOMPRESSED pubkey:" >> $tmp_vfy_fn
  echo "#   echo 3056301006072a8648ce3d020106052b8104000a034200 > pubkey.txt" >> $tmp_vfy_fn
  echo "#   echo 04...your PUBKEY with 130 hexchars... > pubkey.txt" >> $tmp_vfy_fn
  echo "# COMPRESSED pubkey:" >> $tmp_vfy_fn
  echo "#   echo 3036301006072a8648ce3d020106052b8104000a032200 > pubkey.txt" >> $tmp_vfy_fn
  echo "#   echo 03...your PUBKEY with 66 hexchars... > pubkey.txt" >> $tmp_vfy_fn
  echo "# And then:" >> $tmp_vfy_fn
  echo "#   xxd -r -p <pubkey.txt | openssl pkey -pubin -inform der >pubkey.pem" >> $tmp_vfy_fn
  echo "#  " >> $tmp_vfy_fn
fi

while [ $j -le $TX_IN_Count ] 
 do
  k=$(( j - 1 ))
  printf $Version > $utxhex_tmp_fn
  # need to do a var_int check here ...
  printf $TX_IN_Count_hex >> $utxhex_tmp_fn

  # manage all the TX_INs
  while [ $i -le $TX_IN_Count ] 
   do
    printf ${TX_IN_PrevOutput_Hash[$i]} >> $utxhex_tmp_fn
    printf ${TX_IN_PrevOutput_Index[$i]} >> $utxhex_tmp_fn
    if [ $i -eq $j ] ; then
      printf ${TX_IN_ScriptBytes_hex[$i]} >> $utxhex_tmp_fn
      printf ${TX_IN_Sig_Script[$i]} >> $utxhex_tmp_fn
    else
      printf 00 >> $utxhex_tmp_fn
    fi
    printf $TX_IN_Sequence >> $utxhex_tmp_fn
    i=$(( i + 1 ))
  done

  # manage all the TX_OUTs
  printf $TX_OUT_Count_hex >> $utxhex_tmp_fn
  printf $TX_OUT_Value >> $utxhex_tmp_fn
  printf $TX_OUT_PKScriptBytes_hex >> $utxhex_tmp_fn
  printf $TX_OUT_PKScript >> $utxhex_tmp_fn
  printf $LockTime >> $utxhex_tmp_fn
  printf $SIGHASH_ALL >> $utxhex_tmp_fn

  ##############################################################################
  ### STEP 14 - double sha256 that structure from 13                         ###
  ##############################################################################
  v_output "14. TX_IN[$k]: double hash the raw unsigned TX"
  
  if [ "$VVERBOSE" -eq 1 ] ; then 
    echo "TX_IN[$k], the unsigned raw tx:" >> $tmp_vfy_fn
    result=$( cat $utxhex_tmp_fn )
    indent_data "    $result" >> $tmp_vfy_fn
  fi

  # Bitcoin never does sha256 with the hex chars, so need to convert it to hex codes first
  cat $utxhex_tmp_fn | tr [:upper:] [:lower:] > $utxtxt_tmp_fn
  result=$( cat $utxtxt_tmp_fn | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
  printf $result > $utxtxt_tmp_fn

  openssl dgst -binary -sha256 >$utx_sha256_fn  <$utxtxt_tmp_fn 
  openssl dgst -binary -sha256 >$utx_dsha256_fn <$utx_sha256_fn 
 
  if [ "$VVERBOSE" -eq 1 ] ; then 
    od -An -t x1 $utx_sha256_fn | tr -d [:blank:] | tr -d "\n" | sed -e 's/^/    /'
  fi
  # echo "#!/bin/sh" >> $tmp_vfy_fn
  echo "# TX_IN[$k], double sha256 and signature:" >> $tmp_vfy_fn
  result=$( od -An -t x1 $utx_dsha256_fn | tr -d [:blank:] | tr -d "\n" )
  echo "echo $result > tx_hash.txt" >> $tmp_vfy_fn 
  if [ "$VERBOSE" -eq 1 ] ; then 
    echo $result | sed -e 's/^/    /'
  fi
  
  ##############################################################################
  ### STEP 15 - prepare signature and pubkey string with OpenSSL             ###
  ##############################################################################
  # 15: prepare signature and pubkey string
  #     sign structure from 14 (with openssl, DER-encoded)
  #     add 01 (the one byte hash code terminates signature) to signature
  #     add pubkey (hex chars)
  v_output "15. TX_IN[$k]: sign the hash from step 14 with the private key"
  # verify keys are working correctly ...
  if [ "$hex_privkey" ] ; then 
    ./$script_key2pem -q -x $hex_privkey -p $pubkey 
    if [ $? -eq 1 ] ; then 
      echo "*** error in key handling, exiting gracefully ..."
      exit 1
    fi
  else
    ./$script_key2pem -q -w $wif_privkey -p $pubkey 
    if [ $? -eq 1 ] ; then 
      echo "*** error in key handling, exiting gracefully ..."
      exit 1
    fi
  fi
  # v_output "     openssl dgst -sign privkey.pem -sha256 \\"
  # v_output "             -out $sighex_tmp_fn $utx_dsha256_fn"
  # openssl dgst -sign privkey.pem -sha256 -out $sighex_tmp_fn $utx_dsha256_fn
  # SCRIPTSIG=$( od -An -t x1 $sighex_tmp_fn | tr -d [:blank:] | tr -d "\n" )
  # v_output "    $SCRIPTSIG"

  v_output "     openssl pkeyutl -sign -in $utx_dsha256_fn \\"
  v_output "             -inkey privkey.pem -keyform PEM > $sighex_tmp_fn"
  openssl pkeyutl -sign -in $utx_dsha256_fn -inkey privkey.pem -keyform PEM > $sighex_tmp_fn
  SCRIPTSIG=$( od -An -t x1 $sighex_tmp_fn | tr -d [:blank:] | tr -d "\n" )
  v_output "    $SCRIPTSIG"
  printf $SCRIPTSIG > $sigtxt_tmp_if
  if [ $VVERBOSE -eq 1 ] ; then
    ./$script_ssvfy -v -f $sigtxt_tmp_if -o $sigtxt_tmp_of
  elif [ $VERBOSE -eq 1 ] ; then 
    ./$script_ssvfy -f $sigtxt_tmp_if -o $sigtxt_tmp_of
  else
    ./$script_ssvfy -q -f $sigtxt_tmp_if -o $sigtxt_tmp_of
  fi
  if [ $? -eq 1 ] ; then 
    echo "*** ERROR in ScriptSig verification, exiting gracefully ..."
    exit 1
  fi

  echo "echo $SCRIPTSIG > tx_sig.txt" >> $tmp_vfy_fn
  result=$( cat $sigtxt_tmp_of | tr [:upper:] [:lower:] )
  if [ "$SCRIPTSIG" != "$result" ] ; then 
    echo "# *** signature replaced after strict DER sig verification with:" >> $tmp_vfy_fn
    echo "echo $result > tx_sig.txt" >> $tmp_vfy_fn
  fi

  ##############################################################################
  ### STEP 16 - construct the final scriptSig                                ###
  ##############################################################################
  #     calculate length of DER-sgnature from step 15, and concatenate:
  #     - one byte script OPCODE 
  #     - the actual DER-encoded signature plus the one-byte hash code type
  #     - one byte script OPCODE containing the length of the public key
  #     - the actual public key
  v_output "16. TX_IN[$k]: construct the final scriptSig[$k]"
  
  # Strict DER checking (in step 15) had it's output in file "$sigtxt_tmp_of" 
  vv_output "    the one byte script length OPCODE"
  STEPCODE=$( wc -c < "$sigtxt_tmp_of" )
  STEPCODE=$( echo "obase=16;($STEPCODE + 2) / 2" | bc )
  SCRIPTSIG[$j]=$STEPCODE

  vv_output "    the actual DER-encoded signature plus the one-byte hash code type"
  STEPCODE=$( cat $sigtxt_tmp_of ) 
  SCRIPTSIG[$j]=${SCRIPTSIG[$j]}$STEPCODE
  STEPCODE=01
  SCRIPTSIG[$j]=${SCRIPTSIG[$j]}$STEPCODE
  vv_output "    ${SCRIPTSIG[$k]}"

  vv_output "    one byte script OPCODE containing the length of the public key"
  STEPCODE=${#pubkey}
  STEPCODE=$( echo "obase=16;$STEPCODE / 2" | bc )
  vv_output "    len pubkey in hex=$STEPCODE (Bytes)"
  SCRIPTSIG[$j]=${SCRIPTSIG[$j]}$STEPCODE

  vv_output "    the actual public key"
  SCRIPTSIG[$j]=${SCRIPTSIG[$j]}$pubkey
  vv_output "    ${SCRIPTSIG[$k]}"
  vv_output " "

  if [ $VERBOSE -eq 1 ] ; then 
    echo "xxd -r -p <tx_hash.txt >tx_hash.hex" >> $tmp_vfy_fn
    echo "xxd -r -p <tx_sig.txt >tx_sig.hex" >> $tmp_vfy_fn
    echo "openssl pkeyutl <tx_hash.hex -verify -pubin -inkey pubkey.pem -sigfile tx_sig.hex" >> $tmp_vfy_fn
    echo " " >> $tmp_vfy_fn
  fi

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
  k=$(( j - 1 ))
  vv_output "    TX_IN[$k] PrevOutput_Hash"
  STEPCODE=${TX_IN_PrevOutput_Hash[$j]}
  trx_concatenate

  vv_output "    TX_IN[$k] PrevOutput_Index"
  STEPCODE=${TX_IN_PrevOutput_Index[$j]}
  trx_concatenate

  # TX_IN_ScriptBytes[$k] 
  vv_output "    TX_IN[$k] ScriptBytes"
  STEPCODE=${#SCRIPTSIG[$j]}
  STEPCODE=$( echo "obase=16;$STEPCODE / 2" | bc )
  trx_concatenate

  vv_output "    TX_IN[$k] SCRIPTSIG"
  STEPCODE=${SCRIPTSIG[$j]}
  trx_concatenate

  vv_output "    TX_IN[$k] Sequence"
  STEPCODE=$TX_IN_Sequence
  trx_concatenate
  j=$(( j + 1 ))
 done

# here we would need to create a TX_OUT loop, not yet implemented...
# j=1
# while [ $j -le $TX_OUT_Count ] 
#  do
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
# done

echo $SIGNED_TRX > $stx_fn
vv_output $SIGNED_TRX
vv_output " "
echo "the signed trx is in file $stx_fn"

################################
### and here we are done :-) ### 
################################


