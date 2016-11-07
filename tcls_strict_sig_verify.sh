#!/bin/sh
# tool to verify scriptsig of a signed raw transaction
# see: https://github.com/bitcoin/bips/blob/master/bip-0066.mediawiki
# 
# Copyright (c) 2015, 2016 Volker Nowarra 
# Coded in June 2016 following this reference:
#
# Version	by      date    comment
# 0.1		svn     22aug16 initial release, extracted from "trx_create_sign.sh"
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

###########################
# Some variables ...      #
###########################
QUIET=0
VERBOSE=0
VVERBOSE=0

typeset -i SIG_MIN_LENGTH_CHARS=18
typeset -i SIG_MAX_LENGTH_CHARS=146

Q_PARAM_FLAG=0
V_PARAM_FLAG=0
SCRIPTSIG=''

#################################
# procedure to display helptext #
#################################
proc_help() {
  echo "  "
  echo "usage: $0 [-h|-q|-v|-vv] <scriptsig>"
  echo "  "
  echo " -h  show this HELP text"
  echo " -q  real QUIET mode, don't display anything"
  echo " -v  display VERBOSE output"
  echo " -vv display VERY VERBOSE output"
  echo " "
  echo " <scriptsig> is the hex string from an existing, signed raw trx"
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

###########################################################
# to stay with portable code, use zero padding function ###
###########################################################
zero_pad(){
  # for S-Values of signature: sometimes need a zero at the beginning ...
  # zero_pad <string> 
  printf "0$1" 
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

################################
# command line params handling #
################################

if [ "$1" == "-h" ] ; then
  proc_help
  exit 0
fi  

if [ $# -lt 1 ] ; then
  echo "insufficient parameter(s) given... "
  echo " "
  proc_help
  exit 1
else
  while [ $# -ge 1 ] 
   do
    case "$1" in
      -q)
         if [ $VERBOSE -eq 1 ] ; then
           echo "\nwhat? you want verbose and quiet at the same time? think!"
           proc_help
           exit 1
         fi
         QUIET=1
         shift
         ;;
      -v)
         if [ $QUIET -eq 1 ] ; then
           echo "\nwhat? you want quiet and verbose at the same time? think!"
           proc_help
           exit 1
         fi
         VERBOSE=1
         shift
         ;;
      -vv)
         if [ $QUIET -eq 1 ] ; then
           echo "\nwhat? you want quiet and verbose at the same time? think!"
           proc_help
           exit 1
         fi
         VERBOSE=1
         VVERBOSE=1
         vv_output "VERY VERBOSE and VERBOSE output turned on"
         shift
         ;;
      *)
         SCRIPTSIG=$1
         shift
         ;;
    esac
  done
fi

if [ $QUIET -eq 0 ] ; then
  echo "    #########################################################"
  echo "    ### procedure to strictly check DER-encoded signature ###"
  echo "    #########################################################"
fi

vv_output "##########################################"
vv_output "### Check if necessary tools are there ###"
vv_output "##########################################"
check_tool bc
check_tool cut
check_tool tr

vv_output $SCRIPTSIG
vv_output "  ################################################"
vv_output "  # strict verification of DER-encoded SCRIPTSIG #"
vv_output "  ################################################"

scriptsig_len_chars=${#SCRIPTSIG}
scriptsig_len=$(( $scriptsig_len_chars / 2 ))

########################################
# Minimum and maximum size constraints #
# 18 chars < scriptsig_len < 146 chars #
########################################
if [ "$scriptsig_len_chars" -gt $SIG_MIN_LENGTH_CHARS ] && \
   [ "$scriptsig_len_chars" -lt $SIG_MAX_LENGTH_CHARS ] ; then
  v_output  "    Minimum and maximum size constraints                        - ok"
  vv_output "    Scriptsig length: $scriptsig_len_chars, good ($SIG_MIN_LENGTH_CHARS < scriptsig_len < $SIG_MAX_LENGTH_CHARS )"
else
  echo "*** ERROR: script sig verification:  "
  echo "    scriptsig len ($scriptsig_len_chars) incorrect, expected is:"
  echo "    $SIG_MIN_LENGTH_CHARS < scriptsig_len < $SIG_MAX_LENGTH_CHARS"
  echo "    exiting gracefully ... "
  echo " "
  exit 1
fi

######################################
# scriptsig always starts with 0x30" # 
######################################
SCRIPTSIG=$( echo $SCRIPTSIG | tr [:lower:] [:upper:] )
from=1
to=2
compare_string=$( echo $SCRIPTSIG | cut -b $from-$to )
if [ "$compare_string" == "30" ] ; then
  v_output  "    scriptsig always starts with 0x30                           - ok"
  vv_output "  0x30: scriptsig always starts with 0x30"
else
  echo "*** ERROR: script sig verification:  "
  echo "    scriptsig starts with 0x$compare_string, expected is 0x30"
  echo "    wrong header byte (indicating a compound structure)"
  echo "    exiting gracefully ... "
  echo " "
  exit 1
fi

###################################################
# a 1-byte length descriptor for all what follows #
###################################################
from=$(( $from + 2 ))
to=$(( $to + 2 ))
SigRS_len=$( echo $SCRIPTSIG | cut -b $from-$to )
SigRS_len_dec=$( echo "ibase=16;$SigRS_len" | bc )
SigRS_len_chars=$(( $SigRS_len_dec * 2 ))
vv_output "  0x$SigRS_len: a 1-byte length descriptor; must be equal or less than actual sig len ($scriptsig_len_chars)"
if [ $SigRS_len_dec -lt $scriptsig_len ] ; then
  v_output "    length $SigRS_len_chars chars is less than actual sig length ($scriptsig_len_chars chars) - ok"
  v_output "           (hex 0x$SigRS_len, decimal $SigRS_len_dec, $SigRS_len_chars chars)"
else
  echo "*** ERROR: script sig verification: "
  echo "    length (0x$SigRS_len, decimal $SigRS_len_dec, equals $SigRS_len_chars chars) is >= actual sig length ($scriptsig_len_chars chars)"
  echo "    exiting gracefully ... "
  echo " "
  exit 1
fi

#########################################
# 0x02 header byte for the R-coordinate #
#########################################
from=$(( $from + 2 ))
to=$(( $to + 2 ))
compare_string=$( echo $SCRIPTSIG | cut -b $from-$to )
if [ "$compare_string" == "02" ] ; then
  vv_output "  0x02: a header byte indicating an integer follows"
else
  echo "*** ERROR: script sig verification:  "
  echo "    scriptsig[$from-$to] is 0x$compare_string, expected is 0x02"
  echo "    0x02 is a header byte indicating an integer follows"
  echo "    exiting gracefully ... "
  echo " "
  exit 1
fi

#############################################
# length of R coordinate (<= 0 not allowed) #
#############################################
from=$(( $from + 2 ))
to=$(( $to + 2 ))
compare_string=$( echo $SCRIPTSIG | cut -b $from-$to )
R_len_dec=$( echo "ibase=16;$compare_string * 2" | bc )
vv_output "  0x$compare_string: a 1-byte length descriptor for the R-value (must be >= 0)"
if [ $R_len_dec -le 0 ] ; then
  echo "*** ERROR: script sig verification:  "
  echo "    length of R coordinate <= 0; not allowed!"
  echo "    exiting gracefully ... "
  echo " "
  exit 1
else
  v_output "    length of R coordinate ($R_len_dec) >= 0                            - ok"
fi

########################################
# 
########################################
#        // Null bytes at the start of R are not allowed, unless R would
#        // otherwise be interpreted as a negative number.
#        if (lenR > 1 && (sig[4] == 0x00) && !(sig[5] & 0x80)) return false;
#    

#############################################
# the R coordinate, as a big-endian integer #
#############################################
from=$(( $from + 2 ))
to=$(( $from + $R_len_dec - 1 ))
R_value_string=$( echo $SCRIPTSIG | cut -b $from-$to )
vv_output "    the R coordinate, as a big-endian integer"
vv_output "    0x$R_value_string"
# in case we need to replace later the S values (if s -gt N/2 ; then s = N - s),
# we save start position of S coordinates
R_string_end=$(( $to ))

#########################################
# 0x02 header byte for the S-coordinate #
#########################################
from=$(( $from + $R_len_dec ))
to=$(( $from + 1 ))
compare_string=$( echo $SCRIPTSIG | cut -b $from-$to )
if [ "$compare_string" == "02" ] ; then
  vv_output "  0x02: a header byte indicating an integer follows"
else
  echo "*** ERROR: script sig verification:  "
  echo "    scriptsig[$from-$to] is 0x$compare_string, expected is 0x02"
  echo "    0x02 is a header byte indicating an integer follows"
  echo "    exiting gracefully ... "
  echo " "
  exit 1
fi

#############################################
# length of S coordinate (<= 0 not allowed) #
#############################################
from=$(( $from + 2 ))
to=$(( $to + 2 ))
compare_string=$( echo $SCRIPTSIG | cut -b $from-$to )
S_len_dec=$( echo "ibase=16;$compare_string * 2" | bc )
vv_output "  0x$compare_string: a 1-byte length descriptor for the S-value (must be >= 0)"
if [ $S_len_dec -le 0 ] ; then
  echo "*** ERROR: script sig verification: "
  echo "    length of S coordinate <= 0 not allowed"
  echo "    exiting gracefully ... "
  echo " "
  exit 1
else
  v_output "    length of S coordinate ($S_len_dec) >= 0                            - ok"
fi

########################################
# 
########################################
#        // Null bytes at the start of S are not allowed, unless S would otherwise be
#        // interpreted as a negative number.
#        if (lenS > 1 && (sig[lenR + 6] == 0x00) && !(sig[lenR + 7] & 0x80)) return false;
#    

###############################################
# script sig S element and outside boundaries #
###############################################
# Make sure the length of the S element is still inside the signature.
value=$(( $S_len_dec + $from ))
if [ $value -lt $scriptsig_len_chars ] ; then
  v_output "    S-Value is within scriptsig boundaries                      - ok"
else
  echo "*** ERROR: script sig verification for S element boundaries: "
  echo "    script sig S element is outside boundaries"
  echo "    scriptsig_len=$scriptsig_len"
  echo "    current position=$from"
  echo "    S-Value length=$S_len_dec"
  echo "    new pos=$value"
  echo "    exiting gracefully ... "
  echo " "
  exit 1
fi

#############################################
# the S coordinate, as a big-endian integer #
#############################################
from=$(( $from + 2 ))
to=$(( $from + $S_len_dec - 1 ))
S_value_string=$( echo $SCRIPTSIG | cut -b $from-$to )
vv_output "    the S coordinate, as a big-endian integer"
vv_output "    0x$S_value_string"

##########################################################
# Make sure the R & S length covers the entire signature #
##########################################################
# Make sure the length covers the entire signature.
# add 8 to the length, for the header and length bytes of R and S 
value=$(( $R_len_dec + $S_len_dec + 8 ))
if [ $value -eq $SigRS_len_chars ] ; then
  v_output  "    Make sure the R & S length covers the entire signature      - ok"
  vv_output "    lenR($R_len_dec chars) + lenS($S_len_dec chars) + 8 = len signature($SigRS_len_chars chars)"
else
  echo "*** ERROR: script sig verification for R & S length:"
  echo "    R-Value + S-Value != SigRS_len (sigscript[3-4)"
  echo "    scriptsig[3-4]=$SigRS_len_dec chars"
  echo "    R-Value length=$R_len_dec chars"
  echo "    S-Value length=$S_len_dec chars"
  echo "    exiting gracefully ... "
  echo " "
  exit 1
fi

#################################
# if s -gt N/2 ; then s = N - s #
#################################
# make sure, SIG has correct parts - this is "Bitcoin" specific... 
# SIG is <r><s> concatenated together. An s value greater than N/2 
# is not allowed. Need to add code: if s -gt N/2 ; then s = N - s
# N is the curve order: 
# N hex:   FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
# N hex/2: 7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
# N dec: 
#   115792089237316195423570985008687907852837564279074904382605163141518161494337
# N dec/2:
#   57896044618658097711785492504343953926418782139537452191302581570759080747168
#         
Nhalf_Value_hex=7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
value=$( echo "obase=16;ibase=16;$S_value_string < $Nhalf_Value_hex" | bc ) 

if [ $value -eq 1 ] ; then 
  v_output  "    S-value must be smaller than N/2                            - ok"
  vv_output "    cool, S is smaller than N/2"
  v_output  "    strictly check DER-encoded signature                        - ok"
else
  v_output "    *** S is not smaller than N/2, need new S-Value (new_s = N - s)"
  S_value=$( echo "obase=16;ibase=16;FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - $S_value_string" | bc )

  if [ ${#S_value} -ne 64 ] ; then 
    S_value=$( zero_pad $S_value )
  fi
  if [ ${#S_value} -ne 64 ] ; then 
    echo "*** ERROR: script sig verification for S-Value: "
    echo "    something went deadly wrong ..."
    echo "    new S-value must be smaller than N/2:"
    echo "    N/2 (in hex)= $Nhalf_Value_hex"
    echo "    old S-value = $S_value_string"
    echo "    new S-value = $S_value"
    echo "    new S value length ${#S_value} (must be 64 chars)"
    echo "    old scriptsig:"
    echo "    $SCRIPTSIG" 
    echo "    exiting gracefully ... "
    echo " "
    exit 1
  else
    v_output "    new S_value=$S_value"
    # we are good to assemble a new sig, by concatenating values into $SCRIPTSIG
    # we begin with code '0x30' (sequence identfier)
    SCRIPTSIG=$( echo "30" )
    
    # now length of R-Value and S-Value and codes 
    # R-Value was defined in $R_len_dec, S value = 32 Bytes (0x20) --> 64 chars
    # and 4 hex codes (for R and S: '0x02' + length value)         -->  8 chars
    # value=$( echo "$R_len_dec + 64 + 8" | bc )
    value=$( echo "obase=16;($R_len_dec + 64 + 8) / 2" | bc )
    SCRIPTSIG=$( echo "$SCRIPTSIG$value" )
    
    # this is DER sig code '02', identifiying next hexcode as R-Value length
    value="02"
    SCRIPTSIG=$( echo "$SCRIPTSIG$value" )
    
    # convert $R_len_dec to hex
    value=$( echo "obase=16;$R_len_dec / 2" | bc )
    SCRIPTSIG=$( echo "$SCRIPTSIG$value" )
    
    # and concatenate the original R-Value 
    SCRIPTSIG=$( echo "$SCRIPTSIG$R_value_string" )
    
    # this is code '02' and S value length, which is here exactly 32 bytes, in hex 20 
    value="0220"
    SCRIPTSIG=$( echo "$SCRIPTSIG$value" )
    
    # and concatenate the new S-Value 
    SCRIPTSIG=$( echo "$SCRIPTSIG$S_value" )

    # and bring it into a tmp file, eventually required in other scripts
    if [ -f tmp_trx_sig.hex ] ; then 
      cp tmp_trx_sig.hex tmp_trx_sig_old.hex
    fi
    v_output "    new scriptsig=$SCRIPTSIG" 
    SCRIPTSIG=$( echo $SCRIPTSIG | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
    printf "$SCRIPTSIG" > tmp_trx_sig.hex

  fi
fi

# if [ $QUIET -eq 0 ] ; then
#   echo "    #########################################################"
# fi
 v_output "    #########################################################"
vv_output "    ### end of strict verification of SCRIPTSIG           ###"
vv_output "    #########################################################"
vv_output "  "


