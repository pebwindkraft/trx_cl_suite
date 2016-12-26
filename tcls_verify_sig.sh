#!/bin/sh
# tool to verify a bitcoin tx signature
#
# Copyright (c) 2015, 2016 Volker Nowarra 
#
# Version	by	date	comment
# 0.1		svn	21sep16	initial release
# 
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
# 
# three inputs are required, to analyze the trx signature:
#    1.) the public key 
#        or a bitcoin address, which then needs base58 decoding
#        or the output script hash from trx? 
#    2.) the hash value 
#        this is a double sha256 from any message (e.g. an unsigned raw trx)
#    3.) the signature
#       can be obtained from the trx directly, e.g. blockchain.info
#
# Coded in Sep 2016, using this reference:
# http://bitcoin.stackexchange.com/questions/46455/ \
#        verifying-a-bitcoin-trx-on-the-unix-cmd-line-with-openssl
# 
# Bitcoin works only with binary (hexadecimal) files, so convert to binary first!
# Also the hash txt file must contain the double sha256 of the trx
#   $ xxd -r -p <tx_sig.txt >tx_sig.hex  
#   $ xxd -r -p <tx_pubkey.txt | openssl pkey -pubin -inform der >tx_pubkey.pem
#   $ xxd -r -p <tx_hash.txt >tx_hash.hex  
#   $ openssl pkeyutl <tx_hash.hex -verify -pubin -inkey tx_pubkey.pem -sigfile tx_sig.hex
#
# For the pizza trx, as mentioned in the web link:
#   $ xxd -r -p <pizza.sighex >pizza.sigraw
#   $ xxd -r -p <pizza.keyhex | openssl pkey -pubin -inform der >pizza.keypem
#   $ openssl pkeyutl <pizza.hash2 -verify -pubin -inkey pizza.keypem -sigfile pizza.sigraw
#
#   which results in a "Signatre Verified Successfully" (or not ...)
#   (Hint: OpenBSD does not come with xxd by defaut)
# 

###########################
# Some variables ...      #
###########################
Verbose=0
VVerbose=0

tmp_sig_fn=tmp_sig.hex
tmp_dsha256_fn=tmp_dsah256.hex

pre_string=''
mid_string=''
pubkey_1stchar=''
# for a detailed explanation of these pre pubkey strings, look at the file tcls_sign.sh.
pre_pubstr_uc=3056301006072a8648ce3d020106052b8104000a034200
pre_pubstr_c=3036301006072a8648ce3d020106052b8104000a032200

dsha256hash="9302bda273a887cb40c13e02a50b4071a31fd3aae3ae04021b0b843dd61ad18e"

#################################
# procedure to display helptext #
#################################
proc_help() {
  echo " "
  echo "usage: $0 [-h|-v|-vv] -s signature -p pubkey -d dsha256hash"
  echo " "
  echo "tool to verify a signature (with it's pubkey and a hash value)"
  echo " "
  echo " -d  the sha256 value of the message"
  echo " -h  show this HELP text"
  echo " -p  public key (UNCOMPRESSED or COMPRESSED, or a BitCoin address)"
  echo " -s  the signature" 
  echo " -v  display Verbose output"
  echo " -vv display VERY Verbose output"
  echo " "
  echo "public keys:"
  echo "   UNCOMPRESSED:    65 Bytes HEX (130chars), beginning with '04'"
  echo "   COMPRESSED:      33 Bytes HEX (66chars), beginning with '02' or '03'"
  echo "   BitCoin address: 27-34 chars, beginning with '1' or '3'"
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

##########################################
# procedure to reverse a hex data string #
##########################################
# "s=s substr($0,i,1)" means that substr($0,i,1)
# is appended to the variable s; s=s+something
reverse_hex() {
  echo $1 | awk '{ for(i=length;i!=0;i=i-2)s=s substr($0,i-1,2);}END{print s}'
}

#######################################################################
### procedure to show parameter string properly separted with colon ###
#######################################################################
data_show() {
  output=
  data_len=${#1}
  data_from=1
  data_to=0
  # echo "data_show(), data_len=$data_len, parameter:"
  # echo "$1"
  printf "        "
  while [ $data_to -le $data_len ]
   do
    data_to=$(( data_to + 16 ))
    output=$( echo $1 | cut -b $data_from-$data_to )
    if [ $data_to -eq 32 ]  || [ $data_to -eq 64 ]  || [ $data_to -eq 96 ] || \
       [ $data_to -eq 128 ] || [ $data_to -eq 160 ] || [ $data_to -eq 192 ] ; then  
      printf "%s\n        " $output
    else
      if [ $data_to -gt $data_len ] ; then  
        printf "%s" $output
      else
        printf "%s:" $output
      fi
    fi
    data_from=$(( $data_to + 1 ))
  done 
  printf "\n"
  # echo "    data_len=$data_len, data_to=$data_to"
}

################################
# command line params handling #
################################

if [ "$1" == "-h" ] ; then
  proc_help
  exit 0
fi

if [ $# -lt 3 ] ; then
  echo "not enough parameter(s) given... "
  proc_help
  exit 0
else
  while [ $# -ge 1 ] 
   do
    case "$1" in
      -d) if [ "$2" == ""  ] ; then
             echo "*** you must provide a hash value to the -m parameter!"
             exit 1
           fi
           dsha256hash=$2
           if [ ${#dsha256hash} -ne 64 ] ; then
             echo "we don't seem to have a dsha256 hash value ..."
             exit 1
           fi
           shift
           shift
           ;;
      -p)  if [ "$2" == ""  ] ; then
             echo "*** you must provide a pubkey to the -p parameter!"
             exit 1
           fi
           pubkey=$2
           if [ ${#pubkey} -gt 27 ] && [ ${#pubkey} -lt 34 ] ; then
             echo "we seem to have a bitcoin address, code not yet finished..."
             exit 1
           fi
           if [ ${#pubkey} -ne 66 ] && [ ${#pubkey} -ne 130 ] ; then
             echo "*** wrong pubkey length (${#pubkey}), must be 66 or 130 chars"
             proc_help
             exit 1
           fi
           shift
           shift
           ;;
      -s)  if [ "$2" == ""  ] ; then
             echo "*** you must provide a signature to the -s parameter!"
             exit 1
           fi
           signature=$2
           shift
           shift
           ;;
      -v)  Verbose=1
           shift
           ;;
      -vv) Verbose=1
           VVerbose=1
           shift
           ;;
      *) 
           echo "unknown parameter(s), don't know what to do. Exiting gracefully ..."
           proc_help
           exit 0
           ;;
    esac
  done
fi


############
# Let's go #
############
  echo "######################################################################"
  echo "### verify a BitCoin message (e.g. a trx). 3 Inputs required:      ###"
  echo "### a bitcoin pubkey (or address), a dsha256 hash, a signature     ###"
  echo "######################################################################"
  if [ $Verbose -eq 1 ] ; then
    if [ $VVerbose -eq 1 ] ; then
      echo "VVerbose and Verbose output turned on"
    else 
      echo "Verbose output turned on"
    fi
    echo "bitcoin pubkey: $pubkey"
    echo "dsha256 hash:   $dsha256hash"
    echo "signature:      $signature"
  fi

##############################################
### Hint: the public key calculationis ... ###
##############################################
#
#  Uncompressed public key is:
#    0x04 + x-coordinate + y-coordinate
#  Compressed public key is:
#    0x02 + x-coordinate if y is even
#    0x03 + x-coordinate if y is odd
#  
#  Convert PEM keys to hex:
#  echo "MHQCAQEEILtRuiWi5c1Q+44NZ0dZvHwAwJS14REPxjhlBTkLmuCToAcGBSuBBAAKo\
#        UQDQgAEz7drdgvoakqUlMN+jeLm1lq/QyxOpVfWHYtQyrqH/tBqW3GkkDi2fz+FiE\
#        gDF5EIXBBD7Efn3AwAczXnmLu0Mw==" | base64 -D > tmp_key2pem
#  hexdump -C tmp_key2pem
#

################################
### Verifying the public key ### 
################################
if [ $Verbose -eq 1 ] ; then
  printf "\n### verify public key characteristics"
fi
echo $pubkey | awk -f tcls_verify_hexkey.awk
if [ $? -eq 0 ] ; then
  if [ $Verbose -eq 1 ] ; then
    printf ", pubkey is valid          - ok\n"
  fi
else
  printf "\n*** ERROR: invalid pubkey, exiting gracefully..."
  exit 1
fi

###############################
### Verifying the signature ### 
###############################
if [ $Verbose -eq 1 ] ; then
  echo "### verify signature (using tcls_strict_sig_verify.sh)"
  ./tcls_strict_sig_verify.sh -v $signature   
else
  ./tcls_strict_sig_verify.sh -q $signature
fi
if [ $? -eq 0 ] ; then
  v_output "    signature is valid                                          - ok" 
else
  v_output "*** ERROR: unsuccessful signature check, exiting gracefully..."
  exit 1
fi

#####################################
### manually setup the PEM pubkey ### 
#####################################
v_output "### manually setup the PEM pubkey"
v_output "    use pre defined ASN.1 strings to concatenate pubkey.hex"
# get first 2 chars of pubkey
# must be '03' or '04' for compressed or uncompressed key
pubkey_1stchar=$( echo $pubkey | cut -b 1-2 )
if [ "$pubkey_1stchar" == "04" ] ; then
  if [ $VVerbose -eq 1 ] ; then
    echo "    a pre_pubstr:"
    data_show $pre_pubstr_uc
    echo "    the pubkey:"
    data_show $pubkey
  fi
  echo $pre_pubstr_uc$pubkey > pubkey.hex
  result=$( cat pubkey.hex | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
  printf "$result" > tmp_key2pem
else
  if [ $VVerbose -eq 1 ] ; then
    echo "    a pre_pubstr:"
    data_show $pre_pubstr_c
    echo "    the pubkey:"
    data_show $pubkey
  fi
  echo $pre_pubstr_c$pubkey > pubkey.hex
  result=$( cat pubkey.hex | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
  printf "$result" > tmp_key2pem
fi
v_output  "    base64 pubkey.hex file and put some nice surroundings"
vv_output "    openssl enc -base64 -in tmp_key2pem"
echo "-----BEGIN PUBLIC KEY-----"   >  pubkey.pem
openssl enc -base64 -in tmp_key2pem >> pubkey.pem
echo "-----END PUBLIC KEY-----"     >> pubkey.pem
rm tmp_key2pem
if [ $VVerbose -eq 1 ] ; then
  cat pubkey.pem | sed -e 's/^/    /'
fi
v_output "    openssl asn1parse pubkey"
openssl asn1parse -in pubkey.pem > tmp_asn1parse.txt
# the file tmp_asn1parse.txt should contain these lines,
# to be a valid BitCoin pubkey 
#   4:d=2  hl=2 l=   7 prim: OBJECT            :id-ecPublicKey
#  13:d=2  hl=2 l=   5 prim: OBJECT            :secp256k1
grep -e "secp256k1" -e "id-ecPublicKey" tmp_asn1parse.txt > /dev/null
if [ $? -eq 0 ] ; then
  v_output "    asn1parse and grep secp256k1 successful                     - ok" 
else
  v_output "*** ERROR: unsuccessful asn1parse check, exiting gracefully..."
  exit 1
fi

###############################################
### verify signature with generated pub key ### 
###############################################
if [ $Verbose -eq 1 ] ; then
  echo "### verify the signature with hash and pub key"
fi 
# convert the hex strings to raw data (dump with "hexdump -C <filename>")
result=$( echo $dsha256hash | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
printf $result > $tmp_dsha256_fn
result=$( echo $signature | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
printf $result > $tmp_sig_fn
vv_output "openssl pkeyutl -verify -pubin -inkey pubkey.pem -sigfile $tmp_sig_fn -in $tmp_dsha256_fn"
openssl pkeyutl -verify -pubin -inkey pubkey.pem -sigfile $tmp_sig_fn -in $tmp_dsha256_fn

exit 0

rm tmp_*
rm pubkey.*
echo " "
exit 0

