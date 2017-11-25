#!/bin/sh
# command line tool to sign an unsigned raw transaction
# 
# Copyright (c) 2015, 2016 Volker Nowarra 
# Coded in June 2016 following this reference:
#   https://en.bitcoin.it/wiki/Protocol_specification#tx
#   http://bitcoin.stackexchange.com/questions/3374/how-to-redeem-a-basic-tx
# 
# Version by      date    comment
# 0.1	  svn     26sep16 initial release from trx2txt (which is now discontinued)
# 0.2	  svn     04apr17 preparations for multisig tx
# 0.3	  svn     12jun17 remove 'tr' and 'cut', replace by array
# 0.4	  svn     05nov17 finalize unfinished multisig, 
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
# Multisig=0
# Quiet=0
# Verbose=0
# VVerbose=0

# typeset -r stx_fn=tmp_stx.txt                  # signed TX after the end of this script
# typeset -r utxhex_tmp_fn=tmp_utx.hex           # assembled, unsigned TX in hex
# typeset -r utxtxt_tmp_fn=tmp_utx.txt           # assembled, unsigned TX as txt 
# typeset -r utx_sha256_fn=tmp_utx_sha256.hex    # the sha256 hashed TX
# typeset -r utx_dsha256_fn=tmp_utx_dsha256.hex  # the double sha256 hashed TX
typeset -r tmp_vfy_fn=tmp_vfy.sh               # for all TX inputs, put sig, hash and pubkey here

typeset -r Version=01000000
typeset -r TX_IN_Sequence=FFFFFFFF
typeset -r LockTime=00000000
typeset -r SIGHASH_ALL=01000000

typeset -i i=0
typeset -i j=0
typeset -i loopcounter=0
typeset -i n=0
typeset -i F_PARAM_FLAG=0
typeset -i from=0
typeset -i to=0
typeset -i TX_Array_ptr=0
typeset -i TX_Array_bytes=0
typeset -i TX_SIG_Current=0
typeset -i TX_IN_Current=0
typeset -i TX_IN_Count=0
typeset -i TX_IN_ScriptBytes=0
typeset -i TX_OUT_Count=0
typeset -i TX_OUT_Current=0
typeset -i TX_OUT_PKScriptBytes=0
typeset -i script_len_dec=0

TX_Char=''
TX_IN_Count_hex=''
TX_IN_PrevOutput_Hash=''
TX_IN_PrevOutput_Index=''
TX_IN_Sig_Script=''
TX_OUT_Count_hex=''
TX_OUT_Value=''
TX_OUT_PKScriptBytes_hex=''
TX_OUT_PKScript=''
TX_SigHashTypeValue=''

filename=''
hex_privkey=''
Multisig_Status=''
Redeem_Script=''
result=''
STEPCODE=''
Script_Sig=''
SIGNED_TX=''
wif_privkey=''

# and source the global var's config file
. ./tcls.conf

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
  echo " "
  echo "sign usage:   $0 [-h|-m|-q|-v|-vv] [-f <filename>]|[<raw_tx>] -w|-x <privkey> -p <pubkey>"
  echo " "
  echo " -f  next param is a filename with an unsigned raw transaction"
  echo " -h  show this HELP text"
  echo " -m  sign a multisig (spending) tx" 
  echo " -p  next param is a public key (UNCOMPRESSED or COMPRESSED) in hex format"
  echo " -q  real Quiet mode, don't display anything"
  echo " -v  display Verbose output"
  echo " -vv display VERY Verbose output"
  echo " -w  next param is a WIF or WIF-C encoded private key (51 or 52 chars)"
  echo " -x  next param is a HEX encoded private key (32Bytes=64chars)"
  echo " "
}

###################################
# procedure to display tx section #
###################################
get_TX_section() {
  tx_array_from=$TX_Array_ptr
  tx_array_to=$(( $TX_Array_ptr + $TX_Array_bytes ))
  result=""
  until [ $tx_array_from -eq $tx_array_to ]
   do 
    printf "${tx_array[$tx_array_from]}"
    tx_array_from=$(( $tx_array_from + 1 ))
  done 
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
}

#######################################
# procedure to display verbose output #
#######################################
v_output() {
  if [ $Verbose -eq 1 ] ; then
    indent_data "$1"
  fi
}

#################################################
# procedure to display even more verbose output #
#################################################
vv_output() {
  if [ $VVerbose -eq 1 ] ; then
    indent_data "$1"
  fi
}

##############################################
# procedure to concatenate string for raw tx #
##############################################
tx_concatenate() {
  SIGNED_TX=$SIGNED_TX$STEPCODE
  vv_output "    $SIGNED_TX"
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
  var_int=${tx_array[$TX_Array_ptr]}
  if [ "$var_int" == "FD" ] ; then
    TX_Array_ptr=$(( $TX_Array_ptr + 1 ))
    TX_Array_bytes=2
    var_int=$( get_TX_section )
    # big endian conversion!
    var_int=$( reverse_hex $var_int )
  elif [ "$var_int" == "FE" ] ; then
    TX_Array_ptr=$(( $TX_Array_ptr + 1 ))
    TX_Array_bytes=4
    var_int=$( get_TX_section )
    # big endian conversion!
    var_int=$( reverse_hex $var_int )
  elif [ "$var_int" == "FF" ] ; then
    TX_Array_ptr=$(( $TX_Array_ptr + 1 ))
    TX_Array_bytes=8
    var_int=$( get_TX_section )
    # big endian conversion!
    var_int=$( reverse_hex $var_int )
  else
    var_int=${tx_array[$TX_Array_ptr]}
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

#####################################################
# procedure to extract redeem script from sigscript #
#####################################################
separate_sig() {
  # save previous sig to $sig_prev_fn, and get status of multisig
  # a multisig tx can have 3 states: unsigned, partially and complete
  # the script shows status in it's last line (only with param '-m'), 
  # and puts the redeem script and/or sig at the same time into a file
  vv_output "    TX_IN[$TX_IN_Current] ScriptBytes_hex:    ${TX_IN_ScriptBytes_hex[$TX_IN_Current]}"
  vv_output "    TX_IN[$TX_IN_Current] Sig_Script:         ${TX_IN_Sig_Script[$TX_IN_Current]}"
  printf "%s" ${TX_IN_Sig_Script[$TX_IN_Current]}     > $sig_prev_fn
  Multisig_Status=$( ./$script_sig_fn -m -q ${TX_IN_Sig_Script[$TX_IN_Current]} | tail -n1 | tr -d " " )
  if [ "$Multisig_Status" == "complete" ] ; then 
    echo "*** ERROR: trying to sign an already completed multisig tx"
    echo "           exiting gracefully ..." 
    echo " "
    exit 0
  fi
}


echo "##################################################"
echo "### tcls_sign.sh: sign a serialized Bitcoin tx ###"
echo "##################################################"

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
      -m)
         Multisig=1
         shift
         ;;
      -p)
         pubkey=$2
         shift
         shift
         ;;
      -q)
         Quiet=1
         shift
         ;;
      -v)
         Verbose=1
         echo "Verbose output turned on"
         echo " "
         shift
         ;;
      -vv)
         Verbose=1
         VVerbose=1
         echo "VERY Verbose and Verbose output turned on"
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
         ;;
    esac
  done
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

###################
### so let's go ###
###################

if [ $Quiet -ne 1 ] ; then
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

############################################
### normalize tx and bring into an array ###
############################################
# need to bring the chars in the array to upper, so 'bc' can work with hex chars
UNSIGNED_TX=$( printf "$UNSIGNED_TX" | tr [:lower:] [:upper:] )
result=$( echo "$UNSIGNED_TX" | sed 's/[[:xdigit:]]\{2\}/& /g' )
if [ "$shell_string" == "bash" ] ; then
  # running this on OpenBSD creates errors, hence a for loop...
  # tx_array=($result)
  # IFS=' ' read -a tx_array <<< "${result}"
  for TX_Char in $result; do tx_array[$n]=$TX_Char; ((n++)); done
else [ "$shell_string" == "ksh" ] 
  set -A tx_array $result
fi
v_output "unsigned tx is this:"
# v_output "number of tx_array elements: ${#tx_array[*]}, raw tx is this:"
result=$( echo ${tx_array[*]} | tr -d " " )
v_output "$result"

##############################################################################
### STEP 1 - VERSION - this is currently set to 01000000 (4 Bytes)         ###
##############################################################################
v_output "1.  Version, usually set to 01000000 (some CSV/CLTV/SegWit have 02000000)"

TX_Array_ptr=0
TX_Array_bytes=4
result=$( get_TX_section )
TX_Array_ptr=$(( $TX_Array_ptr + $TX_Array_bytes ))

if [ "$result" != "$Version" ] ; then 
  echo "*** Error: unsigned raw transaction normally begins with Version '01000000'"
  echo "           here we have $result. Please adjust, and try again. "
  echo "           Exiting gracefully"
  exit 1
fi
v_output "     $result"

##############################################################################
### STEP 2 - TX_IN_Count, a var_int                                        ###
##############################################################################
v_output "2.  TX_IN_COUNT, the number of input tx [var_int]"
TX_Array_bytes=1
proc_var_int
TX_Array_ptr=$(( $TX_Array_ptr + $TX_Array_bytes ))
TX_IN_Count_hex=$( echo $var_int | tr -d " " )
TX_IN_Count_dec=$( echo "ibase=16; $TX_IN_Count_hex"|bc) 
v_output "     hex=$TX_IN_Count_hex, decimal=$TX_IN_Count_dec"

#######################################################
### collect all tx_in data into array variables...  ###
#######################################################
# here we know, how many TX_IN structures will follow, 
# so we collect all TX_IN data into simple arrays
while [ $TX_IN_Current -lt $TX_IN_Count_dec ] 
 do
  ##############################################################################
  ### STEP 3 - TX_IN_PrevOutput_Hash, previous transaction hash (32Bytes)    ###
  ##############################################################################
  v_output "3.  TX_IN[$TX_IN_Current] PrevOutput_Hash: a transaction hash"
  TX_Array_bytes=32
  TX_IN_PrevOutput_Hash[$TX_IN_Current]=$( get_TX_section )
  TX_Array_ptr=$(( $TX_Array_ptr + $TX_Array_bytes ))
  result=$( reverse_hex $result )
  v_output "     ${TX_IN_PrevOutput_Hash[$TX_IN_Current]}"
  
  ##############################################################################
  ### STEP 4 - TX_IN_PrevOutput_Index, the output index we want to use       ###
  ##############################################################################
  v_output "4.  TX_IN[$TX_IN_Current] PrevOutput_Index: the output index, we want to redeem from"
  TX_Array_bytes=4
  TX_IN_PrevOutput_Index[$TX_IN_Current]=$( get_TX_section )
  TX_Array_ptr=$(( $TX_Array_ptr + $TX_Array_bytes ))
  result=$( reverse_hex ${TX_IN_PrevOutput_Index[$TX_IN_Current]} )
  # and convert into decimal
  tx_value_dec=$( echo "ibase=16; $result"|bc) 
  v_output "     hex=${TX_IN_PrevOutput_Index[$TX_IN_Current]}, reversed $result, decimal=$tx_value_dec"

  ##############################################################################
  ### STEP 5 - TX_IN, script bytes: length of following uchar[] (var_int)    ###
  ##############################################################################
  # The length of the following scriptsig
  v_output "5.  TX_IN[$TX_IN_Current] ScriptBytes: length of prev tx script content"
  TX_Array_bytes=1
  proc_var_int
  TX_Array_ptr=$(( $TX_Array_ptr + $TX_Array_bytes ))
  script_len_dec=$( echo "ibase=16; $var_int"|bc) 
  TX_IN_ScriptBytes_hex[$TX_IN_Current]=$var_int
  v_output "     script_len_hex[$TX_IN_Current]: hex=$var_int, decimal=$script_len_dec"
  
  ##############################################################################
  ### STEP 6 - TX_IN_Sig_Script, uchar[] - variable length                   ###
  ##############################################################################
  # the actual scriptSig 
  # for unsigned raw tx, this is temporarily filled:
  #   if p2sh/p2pkh, then the PubKey script of the PREV_TX
  #   if unsigned multisig, then the redeemscript goes in here
  #   if partially signed multisig, then a signature should appear 
  # 
  v_output "6.  TX_IN[$TX_IN_Current] Sig_Script, uchar[]: variable length"
  TX_Array_bytes=$script_len_dec
  TX_IN_Sig_Script[$TX_IN_Current]=$( get_TX_section )
  TX_Array_ptr=$(( $TX_Array_ptr + $TX_Array_bytes ))
  v_output "     ${TX_IN_Sig_Script[$TX_IN_Current]}"

  ##############################################################################
  ### STEP 7 - TX_IN_Sequence: usually 0xffffffff                            ###
  ##############################################################################
  # Sequence is normally set to 0xffffffff (might differ with CSV/CLTV and SegWit tx)
  v_output "7.  TX_IN[$TX_IN_Current] Sequence, usually 0xffffffff"
  TX_Array_bytes=4
  result=$( get_TX_section )
  TX_Array_ptr=$(( $TX_Array_ptr + $TX_Array_bytes ))
  if [ "$result" != "$TX_IN_Sequence" ] ; then 
    echo "*** Error: TX_IN_Sequence normally is 'ffffffff'"
    echo "           here we have $result. Please adjust, and try again. "
    echo "           Exiting gracefully"
    exit 1
  fi
  v_output "     $result"
  TX_IN_Current=$(( TX_IN_Current + 1 ))
done

##############################################################################
### STEP 8 - TX_OUT_COUNT (var_int): the number of output tx               ###
##############################################################################
v_output "8.  TX_OUT_COUNT, the number of output tx [var_int]"
TX_Array_bytes=1
proc_var_int
TX_Array_ptr=$(( $TX_Array_ptr + $TX_Array_bytes ))
TX_OUT_Count_hex=$( echo $var_int | tr -d " " )
TX_OUT_Count_dec=$( echo "ibase=16; $TX_OUT_Count_hex"|bc) 
v_output "     TX_OUT_COUNT: hex=$TX_OUT_Count_hex, decimal=$TX_OUT_Count_dec"


#######################################################
### collect all tx_out data into array variables... ###
#######################################################
# here we know, how many TX_OUT structures will follow, 
# so we collect all TX_OUT data into simple arrays
while [ $TX_OUT_Current -lt $TX_OUT_Count_dec ] 
 do
  # loopcounter=$(( i - 1 )) # just to make the output headlines correct in their counter

  ##############################################################################
  ### STEP 9 - TX_OUT_Value, the value in hex that will be transferred       ###
  ##############################################################################
  v_output "9.  TX_OUT_Value[$TX_OUT_Current], the value in hex that will be transferred"
  TX_Array_bytes=$TX_OUT_Value_len
  TX_OUT_Value[$TX_OUT_Current]=$( get_TX_section )
  result=$( reverse_hex ${TX_OUT_Value[$TX_OUT_Current]} )
  TX_Array_ptr=$(( $TX_Array_ptr + $TX_Array_bytes ))
  # and convert into decimal
  tx_value_dec=$( echo "ibase=16; $result"|bc) 
  v_output "     hex=${TX_OUT_Value[$TX_OUT_Current]}, reversed=$result, decimal=$tx_value_dec"

  ##############################################################################
  ### STEP 10 - TX_OUT_PKScriptBytes: length of following uchar[] (var_int)  ###
  ##############################################################################
  v_output "10. TX_OUT_PKScriptBytes[$TX_OUT_Current]: length of PK Script [var_int]"
  TX_Array_bytes=1
  proc_var_int
  TX_Array_ptr=$(( $TX_Array_ptr + $TX_Array_bytes ))
  TX_OUT_PKScriptBytes_hex[$TX_OUT_Current]=$( echo $var_int | tr -d " " )
  TX_OUT_PKScriptBytes_dec=$( echo "ibase=16; ${TX_OUT_PKScriptBytes_hex[$TX_OUT_Current]}"|bc) 
  v_output "     hex=${TX_OUT_PKScriptBytes_hex[$TX_OUT_Current]}, decimal=$TX_OUT_PKScriptBytes_dec"
  
  ##############################################################################
  ### STEP 11 - TX_OUT_PKScript, uchar[] - variable length                   ###
  ##############################################################################
  # the actual PKScript where the tx value will go to ...
  v_output "11. TX_OUT_PKScript[$TX_OUT_Current], uchar[]: variable length"
  TX_Array_bytes=$TX_OUT_PKScriptBytes_dec
  TX_OUT_PKScript[$TX_OUT_Current]=$( get_TX_section )
  TX_Array_ptr=$(( $TX_Array_ptr + $TX_Array_bytes ))
  v_output "     ${TX_OUT_PKScript[$TX_OUT_Current]}"

  TX_OUT_Current=$(( TX_OUT_Current + 1 ))
done

##############################################################################
### STEP 12 - LOCKTIME: this is currently set to 00000000 (4 Bytes)        ###
##############################################################################
v_output "12. LockTime, usually set to 00000000, (CSV/CLTV have different values)"
TX_Array_bytes=4
result=$( get_TX_section )
TX_Array_ptr=$(( $TX_Array_ptr + $TX_Array_bytes ))
if [ "$result" != "$LockTime" ] ; then 
  echo "*** Error: unsigned raw transaction normally ends with LockTime '00000000'"
  echo "           here we have $result. Please adjust, and try again. "
  echo "           Exiting gracefully"
  exit 1
fi
v_output "     $result"

##############################################################################
### STEP 13 - Sig Hashtype Value; the last 8 chars (4 bytes)               ###
##############################################################################

v_output "13. Sig Hashtype Value (8 chars, 4 Bytes"
# we set the hash value to default (SIGHASH_ALL), if s.th. else 
# appears in the original tx, it is overwritten.
TX_SigHashTypeValue=$TX_SigHash_all_Value
if [ $TX_Array_ptr -lt ${#tx_array[@]} ] ; then 
  TX_Array_bytes=4
  TX_SigHashTypeValue=$( get_TX_section )
  TX_Array_ptr=$(( $TX_Array_ptr + $TX_Array_bytes ))
fi
v_output "     $TX_SigHashTypeValue"
if [ $TX_Array_ptr -gt ${#tx_array[@]} ] ; then 
  echo "*** Error: current pointer into array does not match array length:"
  echo "           current position in array: $TX_Array_ptr"
  echo "           length of array: ${#tx_array[@]}"
  echo "           Exiting gracefully"
  exit 1
fi

v_output " "
v_output "###############################################################"
v_output "### collected all data, now creating signed raw transaction ###"
v_output "###############################################################"

##############################################################################
### STEP 14 - serialize the unsigned raw tx and add 01000000 (SIGHASH_ALL) ###
##############################################################################

echo "#!/bin/sh " > $tmp_vfy_fn
echo "###############################################" >> $tmp_vfy_fn
echo "### Bitcoin prep file to verify signatures  ###" >> $tmp_vfy_fn
echo "###############################################" >> $tmp_vfy_fn
echo "### Result for each input should be:        ###" >> $tmp_vfy_fn
echo "### Signature Verified Successfully         ###" >> $tmp_vfy_fn
echo "###############################################" >> $tmp_vfy_fn
if [ $VVerbose -eq 1 ] ; then 
  echo "# For each input, need to convert to binary. The pubkey is: " >> $tmp_vfy_fn
  echo "# $pubkey " >> $tmp_vfy_fn
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

# for every tx_in assemble a tx with the pubkey script in the 
# sigscript section, hash it, and only then sign it...
#   STEP1  = Version
# / STEP2  = TX_IN_Count
# | STEP3  = TX_IN_PrevOutput_Hash
# | STEP4  = TX_IN_PrevOutput_Index
# | STEP5  = TX_IN_ScriptBytes
# | STEP6  = TX_IN_Sig_Script  <-- here the pubkey script from prevoius tx's output 
# \ STEP7  = TX_IN_Sequence 
# 
# / STEP8  = TX_OUT_Count
# | STEP9  = TX_OUT_Value
# | STEP10 = TX_OUT_PKScriptBytes (var_int!)
# \ STEP11 = TX_OUT_PKScript (uchar[])
#   STEP12a = LockTime 
#   STEP12b = TX_SigHashTypeValue

# for each input create it's own signature (TX_SIG_Current), with one input 
# having the sigscript filled, the others set to null. 
# outer loop = TX_SIG_Current, inner loop = TX_IN_Current and TX_OUT_Current
TX_IN_Current=0
TX_OUT_Current=0
TX_SIG_Current=1
while [ $TX_SIG_Current -le $TX_IN_Count_dec ] 
 do
  printf $Version > $utxtxt_tmp_fn
  # need to do a var_int check here ...
  printf $TX_IN_Count_hex >> $utxtxt_tmp_fn

  # append all the TX_INs
  v_output "14. TX_IN Sig[$TX_SIG_Current]: serialize unsigned tx and add 01000000 (SIGHASH_ALL)" 
  while [ $TX_IN_Current -lt $TX_IN_Count_dec ] 
   do
    if [ $VVerbose -eq 1 ] ; then 
      echo "    TX_IN[$TX_IN_Current] PrevOutput_Hash:    ${TX_IN_PrevOutput_Hash[$TX_IN_Current]}"
      echo "    TX_IN[$TX_IN_Current] PrevOutput_Index:   ${TX_IN_PrevOutput_Index[$TX_IN_Current]}"
    fi
    printf ${TX_IN_PrevOutput_Hash[$TX_IN_Current]} >> $utxtxt_tmp_fn
    printf ${TX_IN_PrevOutput_Index[$TX_IN_Current]} >> $utxtxt_tmp_fn
    if [ $TX_SIG_Current -eq $(( TX_IN_Current + 1 )) ] ; then
      if [ $Multisig -eq 1 ] ; then 
        separate_sig
        if [ "$Multisig_Status" == "incomplete" ] ; then 
          TX_IN_Sig_Script[$TX_IN_Current]=$( cat $redeemscript_fn )
        fi
        vv_output "      ### changed length and redeem script"
        vv_output "      ### as new TX_IN_SigScipt: "
        # convert length of redeem script into hex 
        result=${#TX_IN_Sig_Script[$TX_IN_Current]}
        TX_IN_ScriptBytes_hex[$TX_IN_Current]=$( echo "obase=16;$result / 2" | bc )
      fi
      vv_output "    TX_IN[$TX_IN_Current] ScriptBytes_hex:    ${TX_IN_ScriptBytes_hex[$TX_IN_Current]}"
      vv_output "    TX_IN[$TX_IN_Current] Sig_Script:         ${TX_IN_Sig_Script[$TX_IN_Current]}"
      printf ${TX_IN_ScriptBytes_hex[$TX_IN_Current]} >> $utxtxt_tmp_fn
      if [ ${#TX_IN_Sig_Script[$TX_IN_Current]} -gt 0 ] ; then
        printf ${TX_IN_Sig_Script[$TX_IN_Current]} >> $utxtxt_tmp_fn
      fi
    else
      printf "00" >> $utxtxt_tmp_fn
    fi
    printf $TX_IN_Sequence >> $utxtxt_tmp_fn
    TX_IN_Current=$(( TX_IN_Current + 1 ))
  done
  # append all the TX_OUTs
  printf $TX_OUT_Count_hex >> $utxtxt_tmp_fn
  while [ $TX_OUT_Current -lt $TX_OUT_Count_dec ] 
   do
    printf ${TX_OUT_Value[$TX_OUT_Current]} >> $utxtxt_tmp_fn
    printf ${TX_OUT_PKScriptBytes_hex[$TX_OUT_Current]} >> $utxtxt_tmp_fn
    printf ${TX_OUT_PKScript[$TX_OUT_Current]} >> $utxtxt_tmp_fn
    if [ $VVerbose -eq 1 ] ; then 
      echo "    TX_OUT[$TX_OUT_Current] Value:             ${TX_OUT_Value[$TX_OUT_Current]}"
      echo "    TX_OUT[$TX_OUT_Current] PKScriptBytes_hex: ${TX_OUT_PKScriptBytes_hex[$TX_OUT_Current]}"
      echo "    TX_OUT[$TX_OUT_Current] PKScript:          ${TX_OUT_PKScript[$TX_OUT_Current]}"
    fi
    TX_OUT_Current=$(( TX_OUT_Current + 1 ))
  done
  printf $LockTime >> $utxtxt_tmp_fn
  printf $TX_SigHashTypeValue >> $utxtxt_tmp_fn
  if [ $VVerbose -eq 1 ] ; then 
    echo "    the unsigned raw tx is this:"
    cat $utxtxt_tmp_fn
    echo " "
  fi

  ##############################################################################
  ### STEP 15 - double sha256 that structure from 13                         ###
  ##############################################################################
  v_output "15. TX_IN Sig[$TX_SIG_Current]: double hash the raw unsigned TX"
  if [ $VVerbose -eq 1 ] ; then 
    echo "# Bitcoin (and so here openssl) works only on binary files. " >> $tmp_vfy_fn
    echo "# TX hash files must be double sha256'd. " >> $tmp_vfy_fn
    echo "echo \"TX_IN Sig[$TX_SIG_Current], the unsigned raw tx:\"" >> $tmp_vfy_fn
    printf "echo \" \"" >> $tmp_vfy_fn
    cat $utxtxt_tmp_fn >> $tmp_vfy_fn
    echo " " >> $tmp_vfy_fn
  fi

  # Bitcoin never does sha256 with the hex chars, so need to convert it to hex codes first
  printf "$(sed 's/[[:xdigit:]]\{2\}/\\x&/g' <$utxtxt_tmp_fn)" > $utxhex_tmp_fn

  openssl dgst -binary -sha256 >$utx_sha256_fn  <$utxhex_tmp_fn 
  openssl dgst -binary -sha256 >$utx_dsha256_fn <$utx_sha256_fn 

  result=$( od -An -t x1 $utx_sha256_fn | tr -d [:blank:] | tr -d "\n" )
  if [ $VVerbose -eq 1 ] ; then 
    echo "    single sha256: $result"
  fi
  result=$( od -An -t x1 $utx_dsha256_fn | tr -d [:blank:] | tr -d "\n" )
  if [ $VVerbose -eq 1 ] ; then 
    echo "    double sha256: $result"
  fi

  echo "echo \"TX_IN Sig[$TX_SIG_Current], double sha256, pubkey and signature:\"" >> $tmp_vfy_fn
  echo "echo $result" >> $tmp_vfy_fn 
  printf '%s\n' "printf \$( echo $result | sed 's/[[:xdigit:]]\{2\}/\\\\x&/g' ) > $utx_dsha256_fn" >> $tmp_vfy_fn

  ##############################################################################
  ### STEP 16 - prepare signature and pubkey string with OpenSSL             ###
  ##############################################################################
  # 16: prepare signature and pubkey string
  #     sign structure from 14 (with openssl, DER-encoded)
  #     add 01 (the one byte hash code terminates signature) to signature
  #     add pubkey (hex chars)
  v_output "16. TX_IN Sig[$TX_SIG_Current]: sign the hash from step 14 with the private key"
  # verify keys are working correctly ...

  if [ "$hex_privkey" ] ; then 
    ./$script_key2pem -q -x $hex_privkey -p $pubkey > /dev/null
    if [ $? -eq 1 ] ; then 
      echo "*** error in key handling, exiting gracefully ..."
      exit 1
    fi
  else
    ./$script_key2pem -q -w $wif_privkey -p $pubkey > /dev/null
    if [ $? -eq 1 ] ; then 
      echo "*** error in key handling, exiting gracefully ..."
      exit 1
    fi
  fi
  echo "echo \"The public key in HEX format: \"" >> $tmp_vfy_fn
  echo "echo $pubkey" >> $tmp_vfy_fn
  echo "echo \"The public key in PEM format: \"" >> $tmp_vfy_fn
  result=$( cat pubkey.pem )
  echo "echo \"$result\" > pubkey.pem" >> $tmp_vfy_fn
  echo "cat pubkey.pem" >> $tmp_vfy_fn

  vv_output "     openssl pkeyutl -sign -in $utx_dsha256_fn \\"
  vv_output "             -inkey privkey.pem -keyform PEM > $sighex_tmp_fn"
  openssl pkeyutl -sign -in $utx_dsha256_fn -inkey privkey.pem -keyform PEM > $sighex_tmp_fn

  Script_Sig=$( od -An -t x1 $sighex_tmp_fn | tr -d [:blank:] | tr -d "\n" )
  vv_output "    $Script_Sig"
  echo "echo \"ScriptSig: \"" >> $tmp_vfy_fn
  echo "echo $Script_Sig" >> $tmp_vfy_fn
  printf '%s\n' "printf \$( echo $Script_Sig | sed 's/[[:xdigit:]]\{2\}/\\\\x&/g' ) > $sighex_tmp_fn" >> $tmp_vfy_fn
  printf $Script_Sig > $sigtxt_tmp_fn

  if [ $VVerbose -eq 1 ] ; then
    ./$script_ssvfy -v -f $sigtxt_tmp_fn -o $sighex_tmp_fn
  else
    ./$script_ssvfy -q -f $sigtxt_tmp_fn -o $sighex_tmp_fn
  fi
  if [ $? -eq 1 ] ; then 
    echo "*** ERROR in ScriptSig verification, exiting gracefully ..."
    exit 1
  fi

  result=$( cat $sigtxt_tmp_fn | tr [:upper:] [:lower:] )
  if [ "$Script_Sig" != "$result" ] ; then 
    echo "# *** signature replaced after strict DER sig verification with:" >> $tmp_vfy_fn
    echo $result > $sigtxt_tmp_fn
    echo "echo $result" >> $tmp_vfy_fn
  fi

  echo "openssl pkeyutl <$utx_dsha256_fn -verify -pubin -inkey pubkey.pem -sigfile $sighex_tmp_fn" >> $tmp_vfy_fn
  echo "echo \" \"" >> $tmp_vfy_fn
  echo " " >> $tmp_vfy_fn
  chmod 755 $tmp_vfy_fn

  ##############################################################################
  ### STEP 17 - prepare the scriptSig(s)                                     ###
  ##############################################################################
  # P2PKH/P2SH tx:
  #     calculate length of DER-signature from step 16, and concatenate:
  #     - one byte script OPCODE 
  #     - the actual DER-encoded signature plus the one-byte hash code type
  #     - one byte script OPCODE containing the length of the public key
  #     - the actual public key
  # MULTISIG - logic as per above, but some special cases:
  #     - a leading "0" due to a bug in the consensus rules in CHECKMULTISIG
  #     - the signatures ...
  #     - the redeem script ...
  v_output "17. TX_IN Sig[$TX_SIG_Current]: prepare scriptSig[$TX_SIG_Current]"
  
  # Strict DER checking (in step 16) had it's output in file "$sigtxt_tmp_fn"
  # if multisig, need to add the "00" as two chars to the length
  # and of course we convert to hex
  result=$( cat $sigtxt_tmp_fn | wc -c )
  if [ $Multisig -eq 1 ] ; then 
    result=$( echo "obase=16;($result + 2) / 2" | bc )
  else
    result=$( echo "obase=16;$result / 2" | bc )
  fi
  vv_output "     a:) the one byte length OPCODE: $result "
  Script_Sig[$TX_SIG_Current]=$result
  result=$( cat $sigtxt_tmp_fn ) 
  Script_Sig[$TX_SIG_Current]=${Script_Sig[$TX_SIG_Current]}$result
  result=01
  Script_Sig[$TX_SIG_Current]=${Script_Sig[$TX_SIG_Current]}$result

  if [ $Multisig -eq 1 ] ; then
    if [ "$Multisig_Status" == "unsigned" ] ; then 
      result=00
      Script_Sig[$TX_SIG_Current]=$result${Script_Sig[$TX_SIG_Current]}
      vv_output "     b:) a leading '00', the DER-encoded sig and the 1-byte hash code:"
    else
      vv_output "     b:) tx is partially signed, concat previous sig and new sig:"
    fi
    if [ "$Multisig_Status" == "incomplete" ] ; then 
      result=$( cat $sig_prev_fn )
      Script_Sig[$TX_SIG_Current]=$result${Script_Sig[$TX_SIG_Current]}
    fi

    # TX_IN_Current was increased before, here we need to set it back
    # to the value which belongs to the redeemscript of TX_IN for current TX_SIG
    TX_IN_Current=$(( TX_SIG_Current - 1 ))

    vv_output "     ${Script_Sig[$TX_SIG_Current]}"
    vv_output "     c:) the redeem script of TX_IN[$TX_IN_Current]: "
    vv_output "      ${TX_IN_Sig_Script[$TX_IN_Current]}"
    result="4C"
    vv_output "     d:) Multisig requires a OP_PUSHDATA1: $result "
    Script_Sig[$TX_SIG_Current]=${Script_Sig[$TX_SIG_Current]}$result
    result=${#TX_IN_Sig_Script[$TX_IN_Current]}
    result=$( echo "obase=16;$result / 2" | bc )
    vv_output "     e:) the length of the redeem script: $result "
    Script_Sig[$TX_SIG_Current]=${Script_Sig[$TX_SIG_Current]}$result
    Script_Sig[$TX_SIG_Current]=${Script_Sig[$TX_SIG_Current]}${TX_IN_Sig_Script[$TX_IN_Current]}
  else
    vv_output "     the actual DER-encoded signature plus the 1-byte hash code type:"
    vv_output "     ${Script_Sig[$TX_SIG_Current]}"
    result=${#pubkey}
    result=$( echo "obase=16;$result / 2" | bc )
    vv_output "     the length of pubkey: $result "
    vv_output "     the pubkey: $pubkey"
    Script_Sig[$TX_SIG_Current]=${Script_Sig[$TX_SIG_Current]}$result
    Script_Sig[$TX_SIG_Current]=${Script_Sig[$TX_SIG_Current]}$pubkey
  fi
  vv_output "     f:) Script_Sig[$TX_SIG_Current]:"
  vv_output "     ${Script_Sig[$TX_SIG_Current]}"
  vv_output " "
  TX_IN_Current=0
  TX_OUT_Current=0
  TX_SIG_Current=$(( TX_SIG_Current + 1 ))
done

##############################################################################
### STEP 18 - concat the new transacton - we have all data in variables    ###
##############################################################################
# 18. We then replace the one-byte, varint length-field from step 5 with the length of 
#     the data from step 16. The length is in chars, devide it by 2 and convert to hex.
# 
v_output "18. concatenate the final transaction for all inputs and outputs"
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
tx_concatenate
vv_output "    TX_IN_Count"
STEPCODE=$TX_IN_Count_hex
tx_concatenate
TX_SIG_Current=1
TX_IN_Current=0
while [ $TX_IN_Current -lt $TX_IN_Count_dec ] 
 do
  vv_output "    TX_IN[$TX_IN_Current] PrevOutput_Hash"
  STEPCODE=${TX_IN_PrevOutput_Hash[$TX_IN_Current]}
  tx_concatenate

  vv_output "    TX_IN[$TX_IN_Current] PrevOutput_Index"
  STEPCODE=${TX_IN_PrevOutput_Index[$TX_IN_Current]}
  tx_concatenate

  # TX_IN_ScriptBytes[$TX_IN_Current] 
  # take var-int into consideration!
  # Value 		dec	Storage length	Format
  # < 0xFD		253	1		uint8_t
  # <= 0xFFFF		65535	3		0xFD followed by the length as uint16_t
  # <= 0xFFFF FFFF	...	5		0xFE followed by the length as uint32_t
  # -			...	9		0xFF followed by the length as uint64_t

  vv_output "    TX_IN[$TX_IN_Current] ScriptBytes "
  STEPCODE=${#Script_Sig[$TX_SIG_Current]}
  script_len_dec=$(( $STEPCODE / 2 ))
  # echo $script_len_dec
  if [ $script_len_dec -gt $max_script_size ] ; then 
    printf " \n" 
    echo "*** ERROR: script len is > 10kB, currently unsupported in protocol rules"
    echo "           exiting gracefully ..." 
    echo " " 
    exit 0
  elif [ $script_len_dec -gt 253 ] ; then 
    vv_output "    (VAR_INT 0xFD + reverse length)"
    STEPCODE=$( echo "obase=16;$script_len_dec" | bc )
    if [ $script_len_dec -gt 253 ] ; then 
      result=0$STEPCODE
    else
      result=00$STEPCODE
    fi
    # echo $result 
    STEPCODE=$( reverse_hex $result )
    STEPCODE=FD$STEPCODE
    # echo $STEPCODE
    tx_concatenate
  else
    STEPCODE=$( echo "obase=16;$script_len_dec" | bc )
    tx_concatenate
  fi
  vv_output "    TX_IN[$TX_IN_Current] Script_Sig"
  STEPCODE=${Script_Sig[$TX_SIG_Current]}
  tx_concatenate

  vv_output "    TX_IN[$TX_IN_Current] Sequence"
  STEPCODE=$TX_IN_Sequence
  tx_concatenate
  TX_IN_Current=$(( TX_IN_Current + 1 ))
 done

vv_output "    TX_OUT_Count_hex"
STEPCODE=$TX_OUT_Count_hex
tx_concatenate
TX_IN_Current=0
while [ $TX_IN_Current -lt $TX_OUT_Count_dec ] 
 do
  vv_output "    TX_OUT_Value[$TX_IN_Current]"
  STEPCODE=${TX_OUT_Value[$TX_IN_Current]}
  tx_concatenate
  vv_output "    TX_OUT_PKScriptBytes[$TX_IN_Current]"
  STEPCODE=${TX_OUT_PKScriptBytes_hex[$TX_IN_Current]}
  tx_concatenate
  vv_output "    TX_OUT_PKScript[$TX_IN_Current]"
  STEPCODE=${TX_OUT_PKScript[$TX_IN_Current]}
  tx_concatenate
  vv_output "    LockTime"
  STEPCODE=$LockTime
  tx_concatenate
  TX_IN_Current=$(( TX_IN_Current + 1 ))
done

echo $SIGNED_TX > $stx_fn
vv_output "    the signed tx:"
vv_output "    $SIGNED_TX"
vv_output " "
if [ $Quiet -ne 1 ] ; then
  echo "the signed tx is in file $stx_fn, check with: ./tcls_tx2txt.sh -vv -f $stx_fn"
  echo "a script to check the signatures is here:         ./tmp_vfy.sh" 
fi

################################
### and here we are done :-) ### 
################################


