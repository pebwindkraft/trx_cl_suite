#!/bin/sh
# base58encode a hex string to the final bitcoin address.
# basically implementing steps 4 - 9 from:
# https://en.bitcoin.it/wiki/Technical_background_of_version_1_Bitcoin_addresses
# created with support from bitcoin_tools by "grondilu@yahoo.fr"
# http://rosettacode.org/wiki/Category:UNIX_Shell
# 
# Copyright (c) 2015, 2016 Volker Nowarra 
# Complete rewrite of code in Nov/Dec 2015 from following reference:
#   https://en.bitcoin.it/wiki/Protocol_specification#tx
# 
# Version	by	date	comment
# 0.1		svn	01jun16	initial release
# 0.2		svn	17jul16	simplified code in step 9
# 0.3		svn	11nov16	rework for compressed pub keys
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
 
ECDSA_PK=0
ECDSA_PKH=0
P2SH=0
QUIET=0
VERBOSE=0
param=010966776006953D5567439E5E39F86A0D273BEE
base58str="123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"

#################################
# procedure to display helptext #
#################################
proc_help() {
  echo "  "
  echo "usage: base58check_enc.sh [-h|-P2SH|-pk|-pkh|-q|-v] hex_string"
  echo "  "
  echo "convert a public key to a bitcoin address"
  echo "basically implementing steps 1-9 (-pk) or 4-9 (-pkh) from:"
  echo "https://en.bitcoin.it/wiki/Technical_background_of_version_1_Bitcoin_addresses"
  echo "http://rosettacode.org/wiki/Category:UNIX_Shell"
  echo "  "
  echo " -h    show this HELP text"
  echo " -P2SH parameter string shall be converted to P2SH address"
  echo " -pk   requires a pubkey in [un]compressed format ([65] 33 hex Bytes)"
  echo " -pkh  requires a pubkey hash (40 hex Bytes)"
  echo " -q    quiet, do only show the final address"
  echo " -v    display verbose output"
  echo "  "
}

#######################################
# procedure to display verbose output #
#######################################
v_output() {
  if [ $VERBOSE -eq 1 ] ; then
    echo "$1"
  fi
}

################################
# command line params handling #
################################

if [ "$1" == "-h" ] ; then
  proc_help
  exit 0
fi  

if [ $# -lt 2 ] ; then
  echo "insufficient parameter(s) given... "
  echo " "
  proc_help
  exit 0
else
  while [ $# -ge 1 ] 
   do
    case "$1" in
      -h)
         proc_help
         exit 0
         ;;
      -P2SH)
         P2SH=1
         param=$2
         shift
         shift
         ;;
      -pk)
         ECDSA_PK=1
         param=$2
         shift
         shift 
         ;;
      -pkh)
         ECDSA_PKH=1
         param=$2
         shift
         shift 
         ;;
      -q | --quiet)
         QUIET=1
         if [ $VERBOSE -eq 1 ] ; then
           echo "*** you cannot use -q (QUIET) and -v (VERBOSE) at the same time!"
           echo " "
           exit 0
         fi
         shift
         ;;
      -v)
         VERBOSE=1
         if [ $QUIET -eq 1 ] ; then
           echo "*** you cannot use -v (VERBOSE) and -q (QUIET) at the same time!"
           echo " "
           exit 0
         fi
         echo "VERBOSE output turned on"
         shift
         ;;
      *) # No more options
         echo "incorrect number of parameter(s), don't know what to do... "
         echo " "
         proc_help
         exit 0
         ;;
    esac
  done
fi

if [ $QUIET -eq 0 ] ; then 
  echo "##################################################################"
  echo "### base58check_enc: convert a hex string to a bitcoin address ###"
  echo "##################################################################"
  echo "  "
  echo "using $param"
  echo " "
fi

len_result=${#param} 
if [ $ECDSA_PK -eq 1 ] ; then 
  ####################################
  ### 1: ECDSA pubkey              ###
  ####################################
  ### ECDSA Pubkeys uncompressed are 65hex Bytes (130 decimal)
  ### ECDSA Pubkeys compressed are 33hex Bytes (66 decimal)
  if [ $VERBOSE -eq 1 ] ; then
    printf "   length of Public ECDSA Key: $len_result chars, "
  fi
  if [ $len_result -eq 66 ] ; then
    v_output " 33 hex codes, a compressed public key"
  elif [ $len_result -eq 130 ] ; then
    v_output " 65 hex codes, an uncompressed public key"
  else
    echo "*** ERROR: string does not match expected length"
    echo "           uncompressed public keys start with '04' and have 130 chars"
    echo "           compressed public keys start with '02' or '03' and have 66 chars"
    exit 1
  fi
  ####################################
  ### 2: do sha on ECDSA pubkey    ###
  ####################################
  v_output "2. SHA256 hash of public ECDSA key"
  tmpvar=$( echo $param | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
  result=$( printf "$tmpvar" | openssl dgst -sha256 | cut -d " " -f 2 )
  v_output "   $result"
  ##############################################
  ### 3: do ripemd160 on sha of ECDSA pubkey ###
  ##############################################
  v_output "3. RIPEMD160 hash of SHA256[ECDSA Key]"
  result=$( echo $result | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
  result=$( printf "$result" | openssl dgst -rmd160 | cut -d " " -f 2 )
  param=$result
  v_output "   $result"
fi
####################################
### 4: add zero at the beginning ###
####################################
if [ $ECDSA_PKH -eq 1 ] ; then 
  ### ECDSA Public Key Hash are 20 hex Bytes (40 decimal)
  if [ $VERBOSE -eq 1 ] ; then
    printf "   length of parameter: $len_result chars, "
  fi
  if [ $len_result -eq 40 ] ; then
    v_output " 20 hex codes, a public key hash"
  else
    echo "*** ERROR: string does not match expected length"
    echo "           public key hashes start with '01' and have 40 chars"
    exit 1
  fi
fi
v_output "4: add 0x00 [or 0x05 for P2SH] at the beginning" 
if [ $P2SH -eq 1 ] ; then 
  result="05$param"
else
  result="00$param"
fi
result4=$result
v_output "   $result"

### verify result string: check, that string is a 
### hex field (length of chars must be divisible by 2)
len_result=${#result} 
result_mod2=$(( $len_result % 2 ))
if [ $result_mod2 -ne 0 ] ; then
  echo "*** ERROR: string does not look like hex, not divisible by 2"
  exit 1
fi
####################################################
### echo "5. sha256"                             ###
### Bitcoin never does sha256 with the hex codes ###
####################################################
v_output "5. sha256"
result=$( echo $result | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
result=$( printf "$result" | openssl dgst -sha256 | cut -d " " -f 2 )
v_output "   $result"
####################################################
### 6. another sha256                            ###
### Bitcoin never does sha256 with the hex codes ###
####################################################
v_output "6. another sha256"
result=$( echo $result | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
result=$( printf "$result" | openssl dgst -sha256 | cut -d " " -f 2 )
v_output "   $result"
################################
### 7. take first four Bytes ### 
################################
v_output "7. take first four Bytes from step 6 as checksum"
checksum=$( echo $result | cut -b 1-8 )
v_output "   $checksum"
############################################################
### 8. add the checksum to the address result from step4 ###
############################################################
v_output "8. append checksum from step 7 to the result from step4"
result=$result4$checksum
v_output "   $result"
###########################################
### 9. encodeBase58 result from step 8: ### 
###    dc 58=0x3A                       ###
###########################################
v_output "9. encode Base58"
tmpvar=$( echo $result | tr "[:lower:]" "[:upper:]" )
pretmpvar=$( echo "$tmpvar" | sed -e's/^\(\(00\)*\).*/\1/' -e's/00/1/g' | tr -d '\n' )

  #  -e execute script
  #      16i = base 
  #        i pops value off the top of the stack and uses it to set the input radix.
  #          $tmpvar=the string that dc will work on ...
  #                  | [...] STRING in brackets on stack
  #                   | dec 58 = hex 0x3A on Stack
  #                      | top two values on the stack are divided and remaindered (~) 
  #                         | duplicates the top of the stack
  #                          | value "0" is put on stack
  #                           | top two elements of the stack are popped and compared.
  #                             | [...] STRING in brackets on stack
  #                              | duplicates the top of the stack
  #                               | remove it from the stack (s)
  #                                | execute
  #                                 | execute
  #                                   | f=display stack
  outstring=$( 
  dc -e "16i $tmpvar [3A ~r d0<x]dsxx +f" | while read -r n; do 
    j=$(( n + 1 ))
    echo $base58str | cut -b $j 
  done | tr -d '\n' )
  echo "   $pretmpvar$outstring"
  # for the GURUs: "man dc" 
  # http://wiki.bash-hackers.org/howto/calculate-dc
  # https://en.wikipedia.org/wiki/Dc_%28Unix%29

if [ $QUIET -eq 0 ] ; then 
  echo " "
fi
exit 0


