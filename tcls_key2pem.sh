#!/bin/sh
# tool to convert bitcoin keys to PEM format, to be able to use OPENSSL to sign
#
# extract the priv key from your wallet, provide as wif priv key or as hex priv key.
# the public key must be provided as hex
# (why? cause you cannot convert from hashed "bitcon address" back to hex values.
# The hex values need to come from the previous transaction's signature!
#
#
# Copyright (c) 2015, 2016 Volker Nowarra 
# Coded in June 2016 following this reference:
#    https://en.bitcoin.it/wiki/Wallet_import_format
#    http://rosettacode.org/wiki/Category:UNIX_Shell
#    https://www.bitaddress.org/ 
#    http://gobittest.appspot.com/Address
#    http://www.offlinebitcoins.com/
#    http://bitcoin.stackexchange.com/questions/46455/verifying-a-bitcoin-trx-on-the-unix-cmd-line-with-openssl
# 
#
# Version	by	date	comment
# 0.1		svn	21jul16	initial release
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
# http://bitcoin.stackexchange.com/questions/46455/\
# verifying-a-bitcoin-trx-on-the-unix-cmd-line-with-openssl?noredirect=1
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
Quiet=0
Verbose=0
VVerbose=0
hex_privkey=''
wif_privkey=''
pre_string=''
mid_string=''
pre_pubstr_uc=''
pre_pubstr_c=''

# ASN.1 structures explained: 
# openssl ecparam -name secp256k1
# -----BEGIN EC PARAMETERS-----
# BgUrgQQACg==
# -----END EC PARAMETERS-----
# 
# The BgUrgQQACg== is a Base64 encoded representation of the ASN.1 
# encoding of the compressed 7-byte Object Identifier 1.2.840.10045.2.1: 
# the ANSI designation of the ANSI standard Elliptic curve secp256k1.
#
#   2a 86 48 ce 3d 02 01 <-- Object Identifier: 1.2.840.10045.2.1
#                            = ecPublicKey, ANSI X9.62 public key typeA
#   
# ASN.1 STRUCTURE FOR PRIVATE KEY:
#   30  <-- declares the start of an ASN.1 sequence
#   74  <-- length of following sequence 
#   02  <-- declares the start of an integer
#   01  <-- length of integer in bytes (1 byte)
#   01  <-- value of integer (1)
#   04  <-- declares the start of an "octet string"
#   20  <-- length of string to follow (32 bytes)
#           7d 86 0c 9a 9b 19 47 9b 19 1f 99 23 a7 12 ... df f9 43 43 58 f2 26 23 bc 
#           \----------------------------------------------------------------------/
#            this is the private key 
#   a0   <-- declares the start of context-specific tag 0
#   07   <-- length of context-specific tag 
#   06   <-- declares the start of an object ID
#   05   <-- length of object ID to follow 
#   2b 81 04 00 0a <-- the object ID of the curve secp256k1
#   a1   <-- declares the start of context-specific tag 1
#   44   <-- declares the length of context-sepcifc tag (68 bytes)
#   03   <-- declares the start of a bit string
#   42   <-- length of bit string to follow (66 bytes)
#   00   <-- ??
#            04 f1 44 f0 dc 00 80 af d2 b7 3f 13 37 6c ... 05 49 cd 83 f4 58 56 1e
#            \-------------------------------------------------------------------/
#             this is the public key
#   

pre_string_uc=$( echo "30740201010420" )
mid_string_uc=$( echo "a00706052b8104000aa144034200" )
pre_string_c=$( echo "30540201010420" )
mid_string_c=$( echo "a00706052b8104000aa124032200" )

# PUBKEY pre-String:
# ASN.1 STRUCTURE FOR PUBKEY (uncompressed and compressed):
#   30  <-- declares the start of an ASN.1 sequence
#   56  <-- length of following sequence (dez 86)
#   30  <-- length declaration is following  
#   10  <-- length of integer in bytes (dez 16)
#   06  <-- declares the start of an "octet string"
#   07  <-- length of integer in bytes (dez 7)
#   2a 86 48 ce 3d 02 01 <-- Object Identifier: 1.2.840.10045.2.1
#                            = ecPublicKey, ANSI X9.62 public key type
#   06  <-- declares the start of an "octet string"
#   05  <-- length of integer in bytes (dez 5)
#   2b 81 04 00 0a <-- Object Identifier: 1.3.132.0.10 
#                      = secp256k1, SECG (Certicom) named eliptic curve
#   03  <-- declares the start of an "octet string"  
#   42  <-- length of bit string to follow (66 bytes)
#   00  <-- Start pubkey??
#
# for uncompressed pubkeys:
pre_pubstr_uc=3056301006072a8648ce3d020106052b8104000a034200
# for compressed pubkeys:
pre_pubstr_c=3036301006072a8648ce3d020106052b8104000a032200
#
# example for setup of 'pre' public key strings above:
#   openssl ecparam -name secp256k1 -genkey -out ec-priv.pem
#   openssl ec -in ec-priv.pem -pubout -out ec-pub.pem
#   openssl ec -in ec-priv.pem -pubout -conv_form compressed -out ec-pub_c.pem 
#   cat ec-pub.pem 
#   cat ec-pub_c.pem 
#   echo "MFYwEAYHKoZIzj0CAQYFK4EEAAoDQgAEAd+5gxspjAfO7HA8qq0/    \
#         7NbHrtTA3z9QNeI5TZ8v0l1pMJ1+mkg3d6zZVUXzMQZ/Y41iID+JAx/ \
#         sQrY+wqVU/g==" | base64 -D - > ec-pub_uc.hex
#   echo "MDYwEAYHKoZIzj0CAQYFK4EEAAoDIgACAd+5gxspjAfO7HA8qq0/7Nb \
#         HrtTA3z9QNeI5TZ8v0l0=" | base64 -D - > ec-pub_c.hex
#   hexdump -C ec-pub_uc.hex 
#   hexdump -C ec-pub_c.hex 
#

# base58=({1..9} {A..H} {J..N} {P..Z} {a..k} {m..z})
# base58="123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
# base58regex="^[$(printf "%s" "${base58[@]}")]{51,52}$"
sha256_string="9302bda273a887cb40c13e02a50b4071a31fd3aae3ae04021b0b843dd61ad18e"

#################################
# procedure to display helptext #
#################################
proc_help() {
  echo " "
  echo "usage: $0 [-h|-q|-v|-vv|-w|-x] privkey [-p] pubkey"
  echo " "
  echo "tool to convert hex private or public keys to PEM format"
  echo "(to be able to sign with openssl). Help can be found here:"
  echo " --> Dump privkey from your wallet. Alternative format conversion(s):"
  echo "     https://www.bitaddress.org/"
  echo "     http://gobittest.appspot.com/Address"
  echo "     http://www.offlinebitcoins.com/"
  echo " "
  echo " -h  show this HELP text"
  echo " -p  public key (UNCOMPRESSED or COMPRESSED) in hex format"
  echo " -q  real Quiet mode, don't display anything"
  echo " -v  display Verbose output"
  echo " -vv display VERY Verbose output"
  echo " -w  next param is a WIF or WIF-C encoded private key (51 or 52 chars)"
  echo " -x  next param is a HEX encoded private key (32Bytes=64chars)"
  echo " "
  echo "public keys:"
  echo "   UNCOMPRESSED: 65 Bytes HEX (130chars), beginning with '04'"
  echo "   COMPRESSED:   33 Bytes HEX (66chars), beginning with "02" or '03'"
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

#################################################
# procedure to convert from wif (base58) to hex #
#################################################
wif2hex() {
  s=$( echo $wif_privkey | awk -f tcls_verify_bc_address.awk )
  vv_output "$s"
  s=$( echo $s | sed 's/[0-9]*/ 58*&+ /g' )
  vv_output "$s"
  h=$( echo "16o0d $s +f" | dc )
  hex_privkey=$( echo $h | tr -d '\\' | tr -d ' ' | cut -b 3-66 )
  vv_output "$hex_privkey"
}
  
################################
# command line params handling #
################################

if [ "$1" == "-h" ] ; then
  proc_help
  exit 0
fi

if [ $# -lt 4 ] ; then
  echo "not enough parameter(s) given... "
  proc_help
  exit 0
else
  while [ $# -ge 1 ] 
   do
    case "$1" in
      -p)
         if [ "$2" == ""  ] ; then
           echo "*** you must provide a pubkey in hex to the -p parameter!"
           exit 1
         fi
         pubkey=$2
         if [ ${#pubkey} -ne 66 ] && [ ${#pubkey} -ne 130 ] ; then
           echo "*** wrong pubkey length (${#pubkey}), must be 66 or 130 chars"
           proc_help
           exit 1
         else
           printf $pubkey > pubkey_hex.txt
         fi
         shift
         shift
         ;;
      -q)
         if [ $Verbose -eq 1 ] ; then
           echo "you cannot use -q and -v or -vv at the same time. Exiting gracefully ..."
           exit 1
         fi
         Quiet=1
         shift
         ;;
      -v)
         if [ $Quiet -eq 1 ] ; then
           echo "you cannot use -v and -q at the same time. Exiting gracefully ..."
           exit 1
         fi
         Verbose=1
         echo "Verbose output turned on"
         shift
         ;;
      -vv)
         if [ $Quiet -eq 1 ] ; then
           echo "you cannot use -vv and -q at the same time. Exiting gracefully ..."
           exit 1
         fi
         Verbose=1
         VVerbose=1
         echo "VVerbose and Verbose output turned on"
         shift
         ;;
      -w) 
         if [ "$2" == ""  ] ; then
           echo "*** you must provide a privkey to the -w parameter!"
           exit 1
         fi
         wif_privkey=$2
         if [ ${#wif_privkey} -ne 51 ] && [ ${#wif_privkey} -ne 52 ] ; then 
           echo "*** wrong privkey length (${#wif_privkey}), must be 51 or 52 chars"
           proc_help
           exit 1
         fi
         shift
         shift
         ;;
      -x)
         if [ "$2" == ""  ] ; then
           echo "*** you must provide a privkey in hex to the -x parameter!"
           exit 1
         fi
         hex_privkey=$2
         if [ ${#hex_privkey} -ne 64 ] ; then
           echo "*** wrong hex privkey length (${#hex_privkey}), must 64 chars"
           proc_help
           exit 1
         fi
         shift
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

if [ $Quiet -eq 0 ] ; then
  echo " "
  echo "######################################################################"
  echo "### Bitcoin (hex) keys to PEM format (to sign with openssl):       ###"
  echo "### --> convert private and public keys from wallet to PEM format. ###"
  echo "### --> Dump keys from your wallet. Convert keys to hex via:       ###"
  echo "### https://www.bitaddress.org/                                    ###"
  echo "### http://gobittest.appspot.com/Address                           ###"
  echo "### http://www.offlinebitcoins.com/                                ###"
  echo "######################################################################"
fi

#############################################################
### the public key calculation ...                        ###
#############################################################
#
# https://en.bitcoin.it/wiki/Elliptic_Curve_Digital_Signature_Algorithm:
#  In Bitcoin, public keys are either compressed or uncompressed. Compressed 
#  public keys are 33 bytes, consisting of a prefix either 0x02 or 0x03, and 
#  a 256-bit integer called x. The older uncompressed keys are 65 bytes, 
#  consisting of constant prefix (0x04), followed by two 256-bit integers 
#  called x and y (2 * 32 bytes). The prefix of a compressed key allows for 
#  the y value to be derived from the x value.
#
#  Hint 1:
#  From the same private key data, a compressed public key makes a different address. 
#  address. You cannot spend bitcoins sent to a compressed address/public key with an 
#  uncompressed version.
# 
#  Hint 2:
#  Be mindful that there is no practical reason to "convert" between uncompressed and 
#  compressed public keys. Each has their own Bitcoin address - you cannot spend funds 
#  sent to the uncompressed public key's address with the compressed public key.
# 
#  Hint 3:
#  A public key (uncompressed) is simply an x and y coordinate of a point on a graph.
#  A compressed public key is just the x coordinate. Using the x coordinate you should 
#  be able to calculate the y coordinate if you really want it:
#  Example 1, an uncompressed pubkey (0x04):
#     047D5B52B82B782C:62CBB7A46E13DB48
#     D987BC0284981018:3B0FA87722C8EAE3
#     C1D12532B60D5307:BF25836F99793910
#     F0F2474A78DF2A70:2FAA321CD2E43120
#     67
#  Find last byte from Y co-ordinate, LSB is set:
#  0x6D (to binary) => 0b1100111 (extracting LSB) => 0b00000011
#     037D5B52B82B782C:62CBB7A46E13DB48
#     D987BC0284981018:3B0FA87722C8EAE3
#     C1
#   
#  Example 2, an uncompressed pubkey (0x04)
#     04D5A76989897EE6:72FD4A2F2088C7A2
#     FDABEBA47901E548:B474CB0ADFAF0646
#     511B22B9F58A8C2D:24085B4727B5C6C8
#     062D52DEEEB41FB2:371DFAE2F1BA2B31
#     A6
#  Find last byte from Y co-ordinate, LSB is not set
#  0xA6 => 0b10100110 => 0b00000010
#     02d5a76989897ee672fd4a2f2088c7
#     a2fdabeba47901e548b474cb0adfaf
#     064651
#   
#  Hint 4:
#  The client parses for payments according to the hash160 of the pubkey, 
#  but it doesn't check for both forms. 
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
############
# Let's go #
############

##############################
### Verifying the privkeys ### 
##############################
v_output " "
v_output "### Verify private key characteristics"
if [ ! "$wif_privkey" ] ; then
  v_output "hex privkey: $hex_privkey"
  echo $hex_privkey | awk -f tcls_verify_hexkey.awk 
  if [ $? -eq 0 ] ; then
    v_output "  valid hex privkey found"
  else
    echo "  *** Exiting gracefully..."
    exit 1
  fi
fi

if [ ! "$hex_privkey" ] ; then
  v_output "  verify wif or wifc privkey"
  first_char=$( echo $wif_privkey | cut -b 1 )
  case "$first_char" in
   5)
      if [ "${#wif_privkey}" -eq 51 ] ; then
        v_output "  valid wif privkey found"
        vv_output "  length($wif_privkey) = ${#wif_privkey}, hex = " 
        wif2hex 
      else
        v_output "  length($wif_privkey) = ${#wif_privkey}" 
        echo "  *** invalid length. WIF privkeys = 51. Exiting gracefully..."
        exit 1
      fi
      ;;
   K)
      if [ "${#wif_privkey}" -eq 52 ] ; then
        v_output "  valid compressed wif privkey found"
        vv_output "  length($wif_privkey) = ${#wif_privkey}, hex = " 
        wif2hex 
      else
        v_output "  length($wif_privkey) = ${#wif_privkey}" 
        echo "  *** invalid length. Compressed WIF privkeys are 52 chars long. Exiting gracefully..."
        exit 1
      fi
      ;;
   L)
      if [ "${#wif_privkey}" -eq 52 ] ; then
        v_output "  valid compressed wif privkey found"
        vv_output "  length($wif_privkey) = ${#wif_privkey}, hex = " 
        wif2hex 
      else
        v_output "  length($wif_privkey) = ${#wif_privkey}" 
        echo "  *** invalid length. Compressed WIF privkeys are 52 chars long. Exiting gracefully..."
        exit 1
      fi
      ;;
   *)
      echo "  *** wif privkeys need to have '5' as first char"
      echo "      compressed wif privkeys need to have 'K' or 'L' as first char"
      echo "      Exiting gracefully..."
      exit 1
      ;;
  esac
fi

################################
### Verifying the public key ### 
################################
v_output " "
v_output "### Verify public key characteristics"
v_output "hex pubkey: $pubkey"
echo $pubkey | awk -f tcls_verify_hexkey.awk
if [ $? -eq 0 ] ; then
  v_output "  valid hex pubkey found"
else
  echo "  *** Exiting gracefully..."
  exit 1
fi

###############################################################
### Priv/Pub keys need to match (compressed/uncompressed)   ### 
###############################################################
v_output " "
v_output "### Verify, if priv and pub key match"
pubkey_char=$( echo $pubkey | cut -b 1,2 )

if [ "${#hex_privkey}" -eq 64 ] ; then
  if [ "$pubkey_char" == "04" ] ; then
    pre_string=$pre_string_uc
    mid_string=$mid_string_uc
  else
    pre_string=$pre_string_c
    mid_string=$mid_string_c
  fi
fi 

if [ "${#wif_privkey}" -eq 51 ] ; then
  if [ "$pubkey_char" == "04" ] ; then
    pre_string=$pre_string_uc
    mid_string=$mid_string_uc
  else
    echo "  *** UNCOMPRESSED wif privkeys require uncompressed pubkeys."
    echo "      Exiting gracefully..."
    exit 1
  fi
fi 
if [ "${#wif_privkey}" -eq 52 ] ; then
  if [ "$pubkey_char" == "02" ] || [ "$pubkey_char" == "03" ] ; then
    pre_string=$pre_string_c
    mid_string=$mid_string_c
  else
    echo "  *** COMPRESSED wif privkeys require compressed pubkeys."
    echo "      Exiting gracefully..."
    exit 1
  fi
fi 
v_output "  yes... "

############################
### Creating PEM privkey ### 
############################
v_output " "
v_output "### use pre defined ASN.1 strings to concatenate PEM privkey"
v_output "  a pre_string : $pre_string" 
v_output "  the privkey  : $hex_privkey"
v_output "  a mid_string : $mid_string"
if [ "$pubkey_char" == "04" ] ; then
  result=$( echo $pubkey | cut -b 1-65 )
  v_output "  the pubkey   : $result"
  result=$( echo $pubkey | cut -b 66- )
  v_output "                 $result"
else
  v_output "  the pubkey   : $pubkey"
fi
echo $pre_string$hex_privkey$mid_string$pubkey > privkey_hex.txt
printf $( echo $pre_string$hex_privkey$mid_string$pubkey | sed 's/[[:xdigit:]]\{2\}/\\x&/g' ) > tmp_key2pem

v_output " "
v_output "### base64 privkey file and put some nice surroundings"
echo "-----BEGIN EC PRIVATE KEY-----" >  privkey.pem
openssl enc -base64 -in tmp_key2pem   >> privkey.pem
echo "-----END EC PRIVATE KEY-----"   >> privkey.pem
rm tmp_key2pem

if [ $Quiet -eq 0 ] ; then
  cat privkey.pem
fi

##########################
### Verify PEM privkey ### 
##########################
if [ $VVerbose -eq 1 ] ; then
  echo " "
  echo "openssl asn1parse -in privkey.pem"
  openssl asn1parse -in privkey.pem 
fi

######################################
### derive PEM pubkey from privkey ### 
######################################
v_output  " "
v_output  "### use openssl to derive pubkey.pem from privkey"
if [ "$pubkey_char" == "04" ] ; then
  openssl ec -in privkey.pem -pubout -out pubkey.pem -conv_form uncompressed > /dev/null 2>&1 
else
  openssl ec -in privkey.pem -pubout -out pubkey.pem -conv_form compressed > /dev/null 2>&1 
fi

if [ $Verbose -eq 1 ] ; then
  cat pubkey.pem
fi

######################################
### manually setup a second pubkey ### 
######################################
if [ $VVerbose -eq 1 ] ; then
  echo " "
  echo "### use pre defined ASN.1 strings to concatenate pubkey_m_hex.txt"
  if [ "$pubkey_char" == "04" ] ; then
    echo   "  a pre_pubstr: $pre_pubstr_uc" 
    echo   "  the pubkey  : $pubkey"
    echo $pre_pubstr_uc$pubkey > pubkey_m_hex.txt
  else
    echo   "  a pre_pubstr: $pre_pubstr_c" 
    echo   "  the pubkey  : $pubkey"
    echo $pre_pubstr_c$pubkey > pubkey_m_hex.txt
  fi
  printf $( sed 's/[[:xdigit:]]\{2\}/\\x&/g' pubkey_m_hex.txt ) > tmp_key2pem
  vv_output " "
  vv_output "### base64 pubkey_m_hex.txt file and put some nice surroundings"
  vv_output "openssl enc -base64 -in tmp_key2pem"
  echo "-----BEGIN PUBLIC KEY-----"   >  pubkey_m.pem
  openssl enc -base64 -in tmp_key2pem >> pubkey_m.pem
  echo "-----END PUBLIC KEY-----"     >> pubkey_m.pem
  cat pubkey_m.pem
  echo " "
  echo "openssl asn1parse -in pubkey.pem"
  openssl asn1parse -in pubkey.pem 
  echo " "
  echo "openssl asn1parse -in pubkey_m.pem"
  openssl asn1parse -in pubkey_m.pem 
  rm tmp_key2pem

fi

###################################################
### 1: verify/sign with generated priv/pub keys ### 
###################################################
if [ $Verbose -eq 1 ] ; then
  echo " "
  echo "############################################################"
  echo "### 1: verifying the signing process with generated keys ###"
  echo "############################################################"
  echo " "

  printf $( echo $sha256_string | sed 's/[[:xdigit:]]\{2\}/\\x&/g' ) > tmp_urtx.sha

  echo "sign with privkey (openssl pkeyutl ... )"
  vv_output "  -sign -in tmp_urtx.sha -inkey privkey.pem -keyform PEM > tmp_pkeyutl_sig.hex"
  openssl pkeyutl -sign -in tmp_urtx.sha -inkey privkey.pem -keyform PEM > tmp_pkeyutl_sig.hex
  echo "verify with pubkey:"
  vv_output "  -verify -pubin -inkey pubkey.pem -sigfile tmp_pkeyutl_sig.hex -in tmp_urtx.sha"
  openssl pkeyutl -verify -pubin -inkey pubkey.pem -sigfile tmp_pkeyutl_sig.hex -in tmp_urtx.sha
  if [ $VVerbose -eq 1 ] ; then
    echo "verify with (pre defined ASN.1 strings) assembled pubkey_m.pem:"
    vv_output "  -verify -pubin -inkey pubkey_m.pem -sigfile tmp_pkeyutl_sig.hex -in tmp_urtx.sha"
    openssl pkeyutl -verify -pubin -inkey pubkey_m.pem -sigfile tmp_pkeyutl_sig.hex -in tmp_urtx.sha
  fi

  echo " "
  echo "sign with privkey (openssl dgst -sha256 ... )"
  vv_output "  -sign privkey.pem -out tmp_dgst256_sig.hex tmp_urtx.sha"
  openssl dgst -sha256 -sign privkey.pem -out tmp_dgst256_sig.hex tmp_urtx.sha
  echo "verify with pubkey:"
  vv_output "  -verify pubkey.pem -signature tmp_dgst256_sig.hex tmp_urtx.sha"
  openssl dgst -sha256 -verify pubkey.pem -signature tmp_dgst256_sig.hex tmp_urtx.sha
  if [ $VVerbose -eq 1 ] ; then
    echo "verify with (pre defined ASN.1 strings) assembled pubkey_m.pem:"
    vv_output "  -verify pubkey_m.pem -signature tmp_dgst256_sig.hex tmp_urtx.sha"
    openssl dgst -sha256 -verify pubkey_m.pem -signature tmp_dgst256_sig.hex tmp_urtx.sha
  fi
fi

##########################################################
### 2: verify/sign with OPENSSL generated priv/pubkeys ###
##########################################################
if [ $VVerbose -eq 1 ] ; then
  echo " "
  echo "##########################################################"
  echo "### 2: verify/sign with OPENSSL generated priv/pubkeys ###"
  echo "##########################################################"
  if [ "$pubkey_char" == "04" ] ; then
    echo "### verifying the signing process with OPENSSL UNCOMPRESSED key (ec_key.pem)"
  else
    echo "### verifying the signing process with OPENSSL COMPRESSED (ecc_key.pem)"
  fi
  echo "prepare openssl environment for (bitcoin) elliptic curves:"
  echo " ->openssl ecparam -name secp256k1 -out secp256k1.pem"
  openssl ecparam -name secp256k1 -out secp256k1.pem
  echo " ->openssl ecparam -genkey -in secp256k1.pem -noout -out secp256k1-key.pem"
  openssl ecparam -genkey -in secp256k1.pem -noout -out secp256k1-key.pem
  if [ "$pubkey_char" == "04" ] ; then
    echo " ->openssl ec -in secp256k1-key.pem -conv_form uncompressed -out ossl_ec_privkey.pem"
    openssl ec -in secp256k1-key.pem -conv_form uncompressed -out ossl_ec_privkey.pem > /dev/null 2>&1
    echo " ->openssl ec -in ossl_ec_privkey.pem -text -noout"
    openssl ec -in ossl_ec_privkey.pem -text -noout
    echo " ->openssl asn1parse -in ossl_ec_privkey.pem"
    openssl asn1parse < ossl_ec_privkey.pem
    echo " ->openssl ec -in ossl_ec_privkey.pem -pubout -out ossl_ec_pubkey.pem"
    openssl ec -in ossl_ec_privkey.pem -pubout -out ossl_ec_pubkey.pem > /dev/null 2>&1

    echo " "
    echo "sign with privkey (via openssl pkeyutl)"
    echo "   -sign -in tmp_urtx.sha -inkey ossl_ec_privkey.pem -keyform PEM > ossl_srtx.sig"
    openssl pkeyutl -sign -in tmp_urtx.sha -inkey ossl_ec_privkey.pem -keyform PEM > ossl_srtx.sig
    echo "verify with pubkey:"
    echo "   -verify -pubin -inkey ossl_ec_pubkey.pem -sigfile ossl_srtx.sig -in tmp_urtx.sha"
    openssl pkeyutl -verify -pubin -inkey ossl_ec_pubkey.pem -sigfile ossl_srtx.sig -in tmp_urtx.sha

    echo " "
    echo "sign with privkey (via openssl dgst -sha256)"
    vv_output "   -sign ossl_ec_privkey.pem -out ossl_srtx_dgst256.sig tmp_urtx.sha"
    openssl dgst -sha256 -sign ossl_ec_privkey.pem -out ossl_srtx_dgst256.sig tmp_urtx.sha
    echo "verify with pubkey:"
    vv_output "   -verify ossl_ec_pubkey.pem -signature ossl_srtx_dgst256.sig tmp_urtx.sha"
    openssl dgst -sha256 -verify ossl_ec_pubkey.pem -signature ossl_srtx_dgst256.sig tmp_urtx.sha
    echo " "
  else
    echo " ->openssl ec -in secp256k1-key.pem -conv_form compressed -out ossl_ecc_privkey.pem"
    openssl ec -in secp256k1-key.pem -conv_form compressed -out ossl_ecc_privkey.pem > /dev/null 2>&1
    echo " ->openssl ec -in ossl_ecc_privkey.pem -text -noout"
    openssl ec -in ossl_ecc_privkey.pem -text -noout
    echo " ->openssl asn1parse -in ossl_ecc_privkey.pem"
    openssl asn1parse < ossl_ecc_privkey.pem
    echo " ->openssl ec -in ossl_ecc_privkey.pem -pubout -out ossl_ecc_pubkey.pem"
    openssl ec -in ossl_ecc_privkey.pem -pubout -out ossl_ecc_pubkey.pem > /dev/null 2>&1

    echo " "
    echo "sign with privkey (via openssl pkeyutl)"
    echo "    -sign -in tmp_urtx.sha -inkey ossl_ecc_privkey.pem -keyform PEM > ossl_srtx.sig"
    openssl pkeyutl -sign -in tmp_urtx.sha -inkey ossl_ecc_privkey.pem -keyform PEM > ossl_srtx.sig
    echo "verify with pubkey:" 
    echo "   -verify -pubin -inkey ossl_ecc_pubkey.pem -sigfile ossl_srtx.sig -in tmp_urtx.sha"
    openssl pkeyutl -verify -pubin -inkey ossl_ecc_pubkey.pem -sigfile ossl_srtx.sig -in tmp_urtx.sha

    echo " "
    echo "sign with privkey (via openssl dgst -sha256)"
    vv_output "   -sign ossl_ecc_privkey.pem -out ossl_srtx_dgst256.sig tmp_urtx.sha"
    openssl dgst -sha256 -sign ossl_ecc_privkey.pem -out ossl_srtx_dgst256.sig tmp_urtx.sha
    echo "verify with privkey:"
    vv_output "   -verify ossl_ecc_pubkey.pem -signature ossl_srtx_dgst256.sig tmp_urtx.sha"
    openssl dgst -sha256 -verify ossl_ecc_pubkey.pem -signature ossl_srtx_dgst256.sig tmp_urtx.sha
  fi
  rm tmp_urtx.sha
  rm secp256k1.pem 
  rm secp256k1-key.pem
fi

echo " "
exit 0

