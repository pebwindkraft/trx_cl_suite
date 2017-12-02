#!/bin/sh
# tool to verify scriptsig of a signed raw transaction
# see: https://github.com/bitcoin/bips/blob/master/bip-0066.mediawiki
# 
# Copyright (c) 2015, 2016 Volker Nowarra 
# Coded in June 2016 following this reference:
#
# Version	by      date    comment
# 0.1		svn     22aug16 initial release, extracted from "trx_create_sign.sh"
# 0.2		svn	03nov17 added check for R value <=N/2
# 0.3		svn	13nov17 load "global vars" from tcls.conf 
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
#
# RULES FOR STRICT SIG CHECKING:
#
#  http://bitcoin-development.narkive.com/OOU2XVSG/bitcoin-development-who-is-creating-non-der-signatures
#  * 2. Signatures are strictly DER-encoded (+ hashtype byte). The format is:
#  0x30 <lenT> 0x02 <lenR> <R> 0x02 <lenS> <S> <hashtype>
#  * R and S are signed integers, encoded as a big-endian byte sequence.
#  They are stored in as few bytes as possible (i.e., no 0x00 padding in
#  front), except that a single 0x00 byte is needed and even required
#  when the byte following it has its highest bit set, to prevent it
#  from being interpreted as a negative number.
#  * lenR and lenS are one byte, containing the length of the R and S
#  records, respectively.
#  * lenT is one byte, containing the length of the complete structure
#  following it, starting from the 0x02, up to the S record. Thus, it
#  must be equal to lenR + lenS + 4.
#  * The hashtype is one byte, and is either 0x01, 0x02, 0x03, 0x81, 0x82
#  or 0x83.
#  * No padding is allowed before or after the hashtype byte, thus lenT
#  is equal to the size of the whole signature minus 3.
#  
#  https://bitcointalk.org/index.php?topic=653313.msg7338853#msg7338853
#  To be correct: R & S usually are 32 or 33 bytes. But can be smaller.
#  If highest bit of 256-bit integer is set we got 33 bytes ( probability is 1/2 )
#  If highest byte is greater than 0 and smaller than 128 we got 32 bytes ( probability 127/256 )
#  If highest byte is 0 - we should take R as 248-bit integer and repeat these steps
#  There are signatures in blockchain where the length of R or S is 29, 30, 31
#  
#  
###########################
# Some variables ...      #
###########################
# typeset -i Quiet=0
# typeset -i Verbose=0
# typeset -i VVerbose=0

# typeset -i sig_min_length_chars=18
# typeset -i sig_max_length_chars=146

# and source the global var's config file
. ./tcls.conf

typeset -i f_param_flag=0
typeset -i o_param_flag=0
infile=''
outfile=$sigtxt_tmp_fn
ScriptSig=''

#################################
# procedure to display helptext #
#################################
proc_help() {
  echo "  "
  echo "usage: $0 [-h|-q|-v|-vv] [-f filename] [-o filename] [signature]"
  echo "  "
  echo " -f  load a signature from a txt file"
  echo " -h  show this HELP text"
  echo " -o  write the signature to a txt file"
  echo " -q  real Quiet mode, don't display anything"
  echo " -v  display Verbose output"
  echo " -vv display VERY Verbose output"
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
}

###########################################################
# to stay with portable code, use zero padding function ###
###########################################################
zero_pad(){
  # for S-Values of signature: sometimes need a zero at the beginning ...
  # zero_pad <string> 
  printf "0$1" 
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
      -f)
         f_param_flag=1
         if [ "$2" == "" ] ; then
           echo "*** you must provide a FILENAME to the -f parameter!"
           exit 1
         fi
         infile=$2
         ScriptSig=$( cat $infile )
         if [ $o_param_flag -eq 1 ] ; then
           if [ "$infile" == "$outfile"  ] ; then
             echo "*** you must provide different FILENAMEs when using -f and -o together"
             exit 1
           fi
         fi
         shift
         shift
         ;;
      -o)
         o_param_flag=1
         if [ "$2" == "" ] ; then
           echo "*** you must provide a FILENAME to the -o parameter!"
           exit 1
         fi
         outfile=$2
         if [ $f_param_flag -eq 1 ] ; then
           if [ "$infile" == "$outfile"  ] ; then
             echo "*** you must provide different FILENAMEs when using -f and -o together"
             exit 1
           fi
         fi
         shift
         shift
         ;;
      -q)
         if [ $Verbose -eq 1 ] ; then
           echo "\nwhat? you want verbose and quiet at the same time? think!"
           proc_help
           exit 1
         fi
         Quiet=1
         shift
         ;;
      -v)
         if [ $Quiet -eq 1 ] ; then
           echo "\nwhat? you want quiet and verbose at the same time? think!"
           proc_help
           exit 1
         fi
         Verbose=1
         shift
         ;;
      -vv)
         if [ $Quiet -eq 1 ] ; then
           echo "\nwhat? you want quiet and verbose at the same time? think!"
           proc_help
           exit 1
         fi
         Verbose=1
         VVerbose=1
         vv_output "VERY Verbose and Verbose output turned on"
         shift
         ;;
      *)
         ScriptSig=$1
         shift
         ;;
    esac
  done
fi

if [ $Quiet -eq 0 ] ; then
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

vv_output $ScriptSig
vv_output "  ################################################"
vv_output "  # strict verification of DER-encoded ScriptSig #"
vv_output "  ################################################"
# A signature exists of: <30> <total len> <02> <len R> <R> <02> <len S> <S> <hashtype>

scriptsig_len_chars=${#ScriptSig}
scriptsig_len=$(( $scriptsig_len_chars / 2 ))

########################################
# Minimum and maximum size constraints #
# 18 chars < scriptsig_len < 146 chars #
########################################
if [ "$scriptsig_len_chars" -gt $sig_min_length_chars ] && \
   [ "$scriptsig_len_chars" -le $sig_max_length_chars ] ; then
  v_output  "    Minimum and maximum size constraints                        - ok"
  vv_output "    Scriptsig length: $scriptsig_len_chars, good ($sig_min_length_chars < scriptsig_len < $sig_max_length_chars )"
else
  echo "*** ERROR: script sig verification:  "
  echo "    scriptsig len ($scriptsig_len_chars) incorrect, expected is:"
  echo "    $sig_min_length_chars < scriptsig_len < $sig_max_length_chars"
  echo "    exiting gracefully ... "
  echo " "
  exit 1
fi

######################################
# scriptsig always starts with 0x30" # 
######################################
ScriptSig=$( echo $ScriptSig | tr [:lower:] [:upper:] )
from=1
to=2
compare_string=$( echo $ScriptSig | cut -b $from-$to )
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
SigRS_len=$( echo $ScriptSig | cut -b $from-$to )
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
compare_string=$( echo $ScriptSig | cut -b $from-$to )
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
compare_string=$( echo $ScriptSig | cut -b $from-$to )
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
R_value_string=$( echo $ScriptSig | cut -b $from-$to )
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
compare_string=$( echo $ScriptSig | cut -b $from-$to )
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
compare_string=$( echo $ScriptSig | cut -b $from-$to )
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
S_value_string=$( echo $ScriptSig | cut -b $from-$to )
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
# if R -gt N/2 ; then R = N - R #
#################################
#  Where R and S are not negative (their first byte has its highest bit not set), and not
#  excessively padded (do not start with a 0 byte, unless an otherwise negative number follows,
#  in which case a single 0 byte is necessary and even required).
#  
#  See https://bitcointalk.org/index.php?topic=8392.msg127623#msg127623
# 
#  This function is consensus-critical since BIP66.
# 
# make sure, SIG has correct parts - this is "Bitcoin" specific... 
# SIG is <r><s> concatenated together. An R or S value greater than N/2 
# is not allowed. Need to add code: if R -gt N/2 ; then R = N - R
# N is the curve order: 
# N hex:   FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141
# N hex/2: 7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
# N dec: 
#   115792089237316195423570985008687907852837564279074904382605163141518161494337
# N dec/2:
#   57896044618658097711785492504343953926418782139537452191302581570759080747168
#         
# also need to check, if first Bytes are "00", this would mean, it has been zero padded 
# (first byte is '00') to protect MSB 1 unsigned int
#
Nhalf_Value_hex=7FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF5D576E7357A4501DDFE92F46681B20A0
value=$( echo "obase=16;ibase=16;$R_value_string < $Nhalf_Value_hex" | bc ) 
R_value=$( echo "$R_value_string" | cut -c 1-2 )

if [ $Verbose -eq 1 ] ; then
  printf "    checking R-value is less than N/2, "
fi
if [ $value -eq 1 ] ; then 
  v_output  "yup...                   - ok"
  vv_output "    cool, R is smaller than N/2"
# if [ $o_param_flag -eq 1 ] ; then
#   printf "$ScriptSig" > $outfile
    printf "$ScriptSig" > $sigtxt_tmp_fn
# fi
elif [ "$R_value" == "00" ] ; then 
  v_output  "R-value is zero padded   - ok"
else
  v_output  "no...                   - nok"
  v_output "    --> R is not smaller than N/2, need new R-Value (new_r = N - r)"
  R_value=$( echo "obase=16;ibase=16;FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141 - $R_value_string" | bc )
  if [ ${#R_value} -ne 64 ] ; then 
    R_value=$( zero_pad $R_value )
  fi
  if [ ${#R_value} -ne 64 ] ; then 
    echo "*** ERROR: script sig verification for R-Value: "
    echo "    something went deadly wrong ..."
    echo "    new R-value must be smaller than N/2:"
    echo "    N/2 (in hex)= $Nhalf_Value_hex"
    echo "    old R-value = $R_value_string"
    echo "    new R-value = $R_value"
    echo "    new R value length ${#R_value} (must be 64 chars)"
    echo "    old scriptsig:"
    echo "    $ScriptSig" 
    echo "    exiting gracefully ... "
    echo " "
    exit 1
  else
    v_output "    new R=$R_value"
    # we are good to assemble a new sig, by concatenating values into $ScriptSig
    # we begin with code '0x30' (sequence identfier)
    ScriptSig=$( echo "30" )
    
    # now length of R-Value and S-Value and codes 
    # R-Value was defined in $R_len_dec, R value = 32 Bytes (0x20) --> 64 chars
    # and 4 hex codes (for R and S: '0x02' + length value)         -->  8 chars
    # value=$( echo "$R_len_dec + 64 + 8" | bc )
    value=$( echo "obase=16;($R_len_dec + 64 + 8) / 2" | bc )
    ScriptSig=$( echo "$ScriptSig$value" )
    
    # this is DER sig code '02', identifiying next hexcode as R-Value length
    value="02"
    ScriptSig=$( echo "$ScriptSig$value" )
    
    # convert $R_len_dec to hex
    value=$( echo "obase=16;$R_len_dec / 2" | bc )
    ScriptSig=$( echo "$ScriptSig$value" )
    
    # and concatenate the original R-Value 
    ScriptSig=$( echo "$ScriptSig$R_value_string" )
    
    # this is code '02' and R value length, which is here exactly 32 bytes, in hex 20 
    value="0220"
    ScriptSig=$( echo "$ScriptSig$value" )
    
    # and concatenate the new R-Value 
    ScriptSig=$( echo "$ScriptSig$R_value" )

    # and bring it into a tmp file, eventually required in other scripts
    if [ -f $sigtxt_tmp_fn ] ; then 
      cp $sigtxt_tmp_fn tmp_sig_old.txt
    fi
    if [ -f $sighex_tmp_fn ] ; then 
      cp $sighex_tmp_fn tmp_sig_old.hex
    fi
    v_output "    new signature=$ScriptSig" 
    printf "$ScriptSig" > $outfile
    result=$( echo $ScriptSig | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
    printf "$result" > $sighex_tmp_fn

  fi
fi

#################################
# if S -gt N/2 ; then S = N - S #
#################################
#  
#  Following the logic from R-Value above ...
#  
value=$( echo "obase=16;ibase=16;$S_value_string < $Nhalf_Value_hex" | bc ) 
S_value=$( echo "$S_value_string" | cut -c 1-2 )

if [ $Verbose -eq 1 ] ; then
  printf "    checking S-value is less than N/2, "
fi
if [ $value -eq 1 ] ; then 
  v_output  "yup...                   - ok"
  vv_output "    cool, S is smaller than N/2"
  v_output  "    strictly check DER-encoded signature                        - ok"
# if [ $o_param_flag -eq 1 ] ; then
#   printf "$ScriptSig" > $outfile
    printf "$ScriptSig" > $sigtxt_tmp_fn
# fi
elif [ "$S_value" == "00" ] ; then 
  v_output  "S-value is zero padded   - ok"
  v_output  "    strictly check DER-encoded signature                        - ok"
else
  v_output  "no...                   - nok"
  v_output "    --> S is not smaller than N/2, need new S-Value (new_s = N - s)"
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
    echo "    $ScriptSig" 
    echo "    exiting gracefully ... "
    echo " "
    exit 1
  else
    v_output "    new S=$S_value"
    # we are good to assemble a new sig, by concatenating values into $ScriptSig
    # we begin with code '0x30' (sequence identfier)
    ScriptSig=$( echo "30" )
    
    # now length of R-Value and S-Value and codes 
    # R-Value was defined in $R_len_dec, S value = 32 Bytes (0x20) --> 64 chars
    # and 4 hex codes (for R and S: '0x02' + length value)         -->  8 chars
    # value=$( echo "$R_len_dec + 64 + 8" | bc )
    value=$( echo "obase=16;($R_len_dec + 64 + 8) / 2" | bc )
    ScriptSig=$( echo "$ScriptSig$value" )
    
    # this is DER sig code '02', identifiying next hexcode as R-Value length
    value="02"
    ScriptSig=$( echo "$ScriptSig$value" )
    
    # convert $R_len_dec to hex
    value=$( echo "obase=16;$R_len_dec / 2" | bc )
    ScriptSig=$( echo "$ScriptSig$value" )
    
    # and concatenate the original R-Value 
    ScriptSig=$( echo "$ScriptSig$R_value_string" )
    
    # this is code '02' and S value length, which is here exactly 32 bytes, in hex 20 
    value="0220"
    ScriptSig=$( echo "$ScriptSig$value" )
    
    # and concatenate the new S-Value 
    ScriptSig=$( echo "$ScriptSig$S_value" )
#   if [ $o_param_flag -eq 1 ] ; then
      printf "$ScriptSig" > $outfile
#   fi

    # and bring it into a tmp file, eventually required in other scripts
    if [ -f $sighex_tmp_fn ] ; then 
      cp $sighex_tmp_fn tmp_tx_sig_old.hex
    fi
    v_output "    new signature=$ScriptSig" 
    ScriptSig=$( echo $ScriptSig | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
    printf "$ScriptSig" > $sighex_tmp_fn

  fi
fi

 v_output "    #########################################################"
vv_output "    ### end of strict verification of ScriptSig           ###"
vv_output "    #########################################################"
vv_output "  "


