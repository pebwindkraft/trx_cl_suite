#!/bin/sh
##############################################################################
# Read the bitcoin script_SIG OPCODES from a transaction's TRX_IN 
# script by Sven-Volker Nowarra 
# 
# Version by	date	comment
# 0.1	  svn	21sep16 initial release, code from trx2txt (discontinued)
# 0.2	  svn	30mar17 added logic for TESTNET
# 0.3	  svn	27jun17 replace "echo xxx | cut -b ..." with ss_array
# 0.4	  svn	16oct17 update for smart contracts with CSV and CLTV
# 
# Copyright (c) 2015, 2016 Volker Nowarra 
# Complete rewrite of code in June 2016 from following reference:
#   https://en.bitcoin.it/wiki/Protocol_specification#tx
#   https://en.bitcoin.it/wiki/Script
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
#  * See https://bitcointalk.org/index.php?topic=8392.0
#  ...
#  a valid bitcoin signature (r,s) is going to look like
#  <30><len><02><len><r bytes><02><len><s bytes><01>
#  where the r and s values are non-negative, and don't exceed 33 bytes 
#  including a possible padding zero byte.
#
# from: https://bitcointalk.org/index.php?topic=1383883.0
#  Unless the bottom 5 bits are 0x02 (SIGHASH_NONE) or 0x03 (SIGHASH_SINGLE), 
#  all the outputs are included.  If the bit for 0x20 is set, then all inputs 
#  are blanked except the current input (SIGHASH_ANYONE_CAN_PAY).
#  SIGHASH_ALL = 1,
#  SIGHASH_NONE = 2,
#  SIGHASH_SINGLE = 3,
#  SIGHASH_ANYONECANPAY = 0x80
# 

typeset -i ss_array_ptr=0
typeset -i sig_offset=0
typeset -i cur_opcode_dec
typeset -i msig_n
offset=1
msig_redeem_str=''
output=''
opcode=''
ret_string=''
sig_string=''

Quiet=0
Verbose=0
VVerbose=0
TESTNET=0
param=483045022100A428348FF55B2B59BC55DDACB1A00F4ECDABE282707BA5185D39FE9CDF05D7F0022074232DAE76965B6311CEA2D9E5708A0F137F4EA2B0E36D0818450C67C9BA259D0121025F95E8A33556E9D7311FA748E9434B333A4ECFB590C773480A196DEAB0DEDEE1

#################################
### Some procedures first ... ###
#################################

v_output() {
  if [ $Verbose -eq 1 ] ; then
    echo "$1"
  fi
}

vv_output() {
  if [ $VVerbose -eq 1 ] ; then
    echo "$1"
  fi
}

#####################
### rmd160_sha256 ###
#####################
# supporting web sites:
# https://en.bitcoin.it/wiki/
# Technical_background_of_version_1_Bitcoin_addresses#How_to_create_Bitcoin_Address
# http://gobittest.appspot.com/Address
rmd160_sha256() {
  result=$( echo $ret_string | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
  result=$( printf "$result" | openssl dgst -sha256 | cut -d " " -f 2 )
  result=$( echo $result | sed 's/[[:xdigit:]]\{2\}/\\x&/g' )
  result=$( printf "$result" | openssl dgst -rmd160 | cut -d " " -f 2 )
}

####################################################################
### procedure to show redeem script properly separted with colon ###
####################################################################
show_redeem_script() {
  result=$( echo "00$1" | sed 's/[[:xdigit:]]\{2\}/& /g' )
  if [ "$shell_string" == "bash" ] ; then
    declare -a rs_array
    rs_array_ptr=0
    for TX_Char in $result; do rs_array[$rs_array_ptr]=$TX_Char; ((rs_array_ptr++)); done
  else 
    set -A rs_array $result
  fi
  rs_array_ptr=1 
  printf "        "
  while [ $rs_array_ptr -lt ${#rs_array[*]} ]
   do
    opcode=${rs_array[$rs_array_ptr]} 
    # modulus 8 and modulus 16 to beautify output:
    if [ $(( $rs_array_ptr % 16 )) -eq 0 ]; then
      printf "%s\n        " $opcode
    elif [ $(( $rs_array_ptr % 8 )) -eq 0 ]; then
      printf "%s:" $opcode
    else
      printf "%s" $opcode
    fi
    rs_array_ptr=$(( $rs_array_ptr + 1 ))
  done 
  printf "\n"
  # echo "*** rs_array_ptr=$rs_array_ptr"
}

############################################################
### procedure to show data separated by colon or newline ###
############################################################
op_data_show() {
  n=1
  ret_string=""
  output=
  while [ $n -le $cur_opcode_dec ]
   do
    opcode=${ss_array[$ss_array_ptr]} 
    ss_array_ptr=$(( $ss_array_ptr + 1 ))
    output=$output$opcode
    sig_string=$sig_string$opcode
    ret_string=$ret_string$opcode
    if [ $n -eq 8 ]  || [ $n -eq 24 ] || [ $n -eq 40 ] || \
       [ $n -eq 56 ] || [ $n -eq 72 ] || [ $n -eq 88 ] || [ $n -eq 104 ] ; then 
      output=$output":"
    elif [ $n -eq 16 ] || [ $n -eq 32 ] || [ $n -eq 48 ] || \
         [ $n -eq 64 ] || [ $n -eq 80 ] || [ $n -eq 96 ] || [ $n -eq 112 ] ; then 
      if [ $Verbose -eq 1 ] ; then
        echo "        $output" 
      fi
      output=
      opcode=
    fi
    n=$(( n + 1 ))
  done 
  if [ "$output" != "" ] && [ $Verbose -eq 1 ] ; then
    echo "        $output" 
  fi
}

#####################
### GET NEXT CODE ###
#####################
get_next_opcode() {
  cur_opcode=$( printf ${ss_array[$ss_array_ptr]} )
  ss_array_ptr=$(( $ss_array_ptr + 1 ))
  cur_hexcode="0x"$cur_opcode
  cur_opcode_dec=$( echo "ibase=16;$cur_opcode" | bc )
  sig_string=$sig_string$cur_opcode
}

#################################
### STATUS 01 (s01_SIG_LEN)   ###
#################################
s01_SIG_LEN() {
  vv_output "s01_SIG_LEN"
  get_next_opcode
  case $cur_opcode in
    30) echo "    $cur_opcode: OP_SEQUENCE_0x30:    type tag indicating SEQUENCE, begin sigscript"
        sig_string=$cur_opcode
        s02_SIGTYPE
        ;;
    *)  s97_NA_or_1TO16
        ;;
  esac
}
#####################################
### STATUS 02 (s02_SIGTYPE)       ###
#####################################
s02_SIGTYPE() {
  vv_output "s02_SIGTYPE"
  get_next_opcode
  case $cur_opcode in
    44) echo "    $cur_opcode: OP_LENGTH_0x44:      length of R + S"
        s03_LENGTH 
        ;;
    45) echo "    $cur_opcode: OP_LENGTH_0x44:      length of R + S"
        s03_LENGTH 
        ;;
    46) echo "    $cur_opcode: OP_LENGTH_0x44:      length of R + S"
        s03_LENGTH 
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 03 (s03_LENGTH)        ###
#####################################
s03_LENGTH() {
  vv_output "s03_LENGTH"
  get_next_opcode
  case $cur_opcode in
    01) echo "    $cur_opcode: OP_SIGHASHALL:       this terminates the ECDSA signature (ASN1-DER structure)"
        s08_SIG 
        ;;
    02) echo "    $cur_opcode: OP_INT_0x02:         type tag INTEGER indicating length"
        s04_R_LENGTH 
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 04 (s04_R_LENGTH)      ###
#####################################
s04_R_LENGTH() {
  vv_output "s04_R_LENGTH"
  get_next_opcode
  case $cur_opcode in
    1F) echo "    $cur_opcode: OP_LENGTH_0x1F:      this is SIG R (31 Bytes)"
        op_data_show
        s05_SIG_R
        ;;
    20) echo "    $cur_opcode: OP_LENGTH_0x20:      this is SIG R (32 Bytes)"
        op_data_show
        s05_SIG_R
        ;;
    21) echo "    $cur_opcode: OP_LENGTH_0x20:      this is SIG R (33 Bytes)"
        op_data_show
        s05_SIG_R
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        if [ $cur_opcode_dec -eq 0 ] ; then 
          echo "*** Zero-length integers are not allowed for R."
        fi
#     // Negative numbers are not allowed for R.
#     if (sig[lenR + 6] & 0x80) return false;
        ;;
  esac
}
#####################################
### STATUS 05 (s05_SIG_R)         ###
#####################################
s05_SIG_R() {
  vv_output "s05_SIG_R"
  get_next_opcode
  case $cur_opcode in
    02) echo "    $cur_opcode: OP_INT_0x02:         type tag INTEGER indicating length"
        s06_LENGTH 
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 06 (s06_LENGTH)        ###
#####################################
s06_LENGTH() {
  vv_output "s06_LENGTH"
  get_next_opcode
  case $cur_opcode in
    20) echo "    $cur_opcode: OP_LENGTH_0x20:      this is SIG S (32 Bytes)"
        op_data_show 
        s07_SIG_S
        ;;
    21) echo "    $cur_opcode: OP_LENGTH_0x21:      this is SIG S (33 Bytes)"
        op_data_show 
        s07_SIG_S
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        if [ $cur_opcode_dec -eq 0 ] ; then 
          echo "*** Zero-length integers are not allowed for S."
        fi
#     // Negative numbers are not allowed for S.
#     if (sig[lenR + 6] & 0x80) return false;
        ;;
  esac
}
#####################################
### STATUS 07 (s07_SIG_S)         ###
#####################################
s07_SIG_S() {
  vv_output "s07_SIG_S"
  get_next_opcode
  case $cur_opcode in
    01) echo "    $cur_opcode: OP_SIGHASHALL:       this terminates the ECDSA signature (ASN1-DER structure)"
        s08_SIG 
        ;;
    02) echo "    $cur_opcode: OP_SIGHASHNONE:      this terminates the ECDSA signature (ASN1-DER structure)"
        s08_SIG 
        ;;
    03) echo "    $cur_opcode: OP_SIGHASHSINGLE:    this terminates the ECDSA signature (ASN1-DER structure)"
        s08_SIG 
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 08 (s08_SIG)           ###
#####################################
s08_SIG() {
  vv_output "s08_SIG"
  if [ $Verbose -eq 1 ] ; then
    ./tcls_strict_sig_verify.sh -v $sig_string
  else
    ./tcls_strict_sig_verify.sh -q $sig_string
  fi
}
#####################################
### STATUS 0a (s0a_SIG_LEN)       ###
#####################################
s0a_SIG_LEN() {
  vv_output "s0a_SIG_LEN"
  get_next_opcode
  case $cur_opcode in
    30) echo "    $cur_opcode: OP_SEQUENCE_0x30:  type tag indicating SEQUENCE, begin sigscript"
        sig_string=$cur_opcode
        s0b_SIGTYPE
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 0b (s0b_SIGTYPE)       ###
#####################################
s0b_SIGTYPE() {
  vv_output "s0b_SIGTYPE"
  get_next_opcode
  case $cur_opcode in
    39) echo "    $cur_opcode: OP_LENGTH_0x39:    length of R + S"
        s0c_LENGTH
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 0c (s0c_LENGTH)        ###
#####################################
s0c_LENGTH() {
  vv_output "s0c_LENGTH"
  get_next_opcode
  case $cur_opcode in
    02) echo "    $cur_opcode: OP_INT_0x02:       type tag indicating INTEGER"
        s0d_X_LENGTH
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 0d (s0d_X_LENGTH)      ###
#####################################
s0d_X_LENGTH() {
  vv_output "s0d_X_LENGTH"
  get_next_opcode
  case $cur_opcode in
    15) echo "    $cur_opcode: OP_INT_0x15:    this is SIG X"
        op_data_show 
        s0e_SIG_X
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 0e (s0e_SIG_X)         ###
#####################################
s0e_SIG_X() {
  vv_output "s0e_SIG_X"
  get_next_opcode
  case $cur_opcode in
    02) echo "    $cur_opcode: OP_LENGTH_0x02"
        s06_S_Length
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 10 (s10_PK_LEN)        ###
#####################################
s10_PK_LEN() {
  vv_output "s10_PK_LEN"
  op_data_show
  if [ $Verbose -eq 1 ] ; then
    printf "        corresponding bitcoin address is:"
    rmd160_sha256
    if [ $TESTNET -eq 1 ] ; then
      ./tcls_base58check_enc.sh -T -q -p2pkh $result
    else
      ./tcls_base58check_enc.sh -q -p2pkh $result
    fi
  fi
  ret_string=''
}
#####################################
### STATUS 20 (s20_DUP)           ###
#####################################
s20_DUP() {
  vv_output "s20_DUP"
  get_next_opcode
  case $cur_opcode in
    A9) echo "    $cur_opcode: OP_HASH160:          input is hashed with SHA-256 and RIPEMD-160"
        s21_HASH160
        ;;
    *)  s98_RET
        ;;
  esac
}
#####################################
### STATUS 21 (s21_HASH160)       ###
#####################################
s21_HASH160() {
  vv_output "s21_HASH160"
  get_next_opcode
  case $cur_opcode in
    14) echo "    $cur_opcode: OP_Data:             $cur_opcode_dec bytes on the stack"
        op_data_show
        if [ $Verbose -eq 1 ] ; then
          echo   "        base58check encoding $ret_string"
          printf "        bitcoin address is"
          if [ $TESTNET -eq 1 ] ; then
            sh ./tcls_base58check_enc.sh -T -q -p2pkh $ret_string
          else
            sh ./tcls_base58check_enc.sh -q -p2pkh $ret_string
          fi
        fi
        s22_DATA20 
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 22 (s22_DATA20)        ###
#####################################
s22_DATA20() {
  vv_output "s22_DATA20"
  get_next_opcode
  case $cur_opcode in
    88) echo "    $cur_opcode: OP_EQUALVERIFY:      same as OP_EQUAL, but runs OP_VERIFY afterward"
        s23_EQ_VRFY 
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 23 (s23_EQ_VRFY)       ###
#####################################
s23_EQ_VRFY() {
  vv_output "s23_EQ_VRFY"
  get_next_opcode
  case $cur_opcode in
    AC) echo "    $cur_opcode: OP_CHECKSIG:         sig must be a valid sig for hash and pubkey"
        echo "        This is a P2PKH script"
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 30 (s30_HASH160)       ###
#####################################
s30_HASH160() {
  vv_output "s30_HASH160"
  get_next_opcode
  case $cur_opcode in
    14) echo "    $cur_opcode: OP_Data:           $cur_opcode_dec bytes on the stack"
        op_data_show
        s31_P2SH
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 31 (s31_P2SH)          ###
#####################################
s31_P2SH() {
  vv_output s31_P2SH 
  get_next_opcode
  case $cur_opcode in
    87) echo "    $cur_opcode: OP_Equal:            Returns 1 if inputs are equal, 0 otherwise"
        echo "        This is a P2SH script:"
        if [ $Verbose -eq 1 ] ; then
          printf "        corresponding bitcoin address is: "
          rmd160_sha256
          if [ $TESTNET -eq 1 ] ; then
            ./tcls_base58check_enc.sh -T -q -p2sh $ret_string
          else
            ./tcls_base58check_enc.sh -q -p2sh $ret_string
          fi
        fi
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
#####################################
### STATUS 40 (s40_OP_1TO16)      ###
#####################################
s40_OP_1TO16() {
  vv_output "s40_OP_1TO16()"
  # in case the prev OpCode was OP_1-16, we save it into msig_n, cause it can be multisig
  msig_n=$cur_opcode_dec
  msig_redeem_str=$cur_opcode
  get_next_opcode
  if [ "$cur_opcode" == "B1" ] ; then
    echo "    $cur_opcode: OP_CHECKLOCKTIMEVERIFY: see documentation..."
    s4a_CLTV
  elif [ "$cur_opcode" == "B2" ] ; then
    echo "    $cur_opcode: OP_CHECKSEQUENCEVERIFY: see documentation..."
    s4b_CSV 
  elif [ "$cur_opcode" == "21" ] || [ "$cur_opcode" == "41" ] || [ $cur_opcode_dec -gt 81 ] && [ $cur_opcode_dec -lt 96 ] ; then
    echo "        ################### we go multisig ####################################"
    rs_loopcounter=1
    ss_array_ptr=$(( $ss_array_ptr - 1 ))
    while [ $rs_loopcounter -le 16 ]  
     do
      get_next_opcode
      msig_redeem_str=$msig_redeem_str$cur_opcode
      case $cur_opcode in
        21) echo "    $cur_opcode: OP_DATA_0x21:        compressed pub key (33 Bytes)"
            op_data_show
            if [ $Verbose -eq 1 ] ; then
              echo "        This is MultiSig's compressed Public Key (X9.63 form)"
              printf "        corresponding bitcoin address is: "
              rmd160_sha256
              if [ $TESTNET -eq 1 ] ; then
                ./tcls_base58check_enc.sh -T -q -p2pkh $result
              else
                ./tcls_base58check_enc.sh -q -p2pkh $result
              fi
              msig_redeem_str=$msig_redeem_str$ret_string
              # vv_output "        msig_redeem_str=$msig_redeem_str"
              ret_string=''
            fi
            ;;
        41) echo "    $cur_opcode: OP_DATA_0x41:        uncompressed pub key (65 Bytes)"
            op_data_show
            if [ $Verbose -eq 1 ] ; then
              echo "        This is MultiSig's uncompressed Public Key (X9.63 form)"
              printf "        corresponding bitcoin address is: "
              rmd160_sha256
              if [ $TESTNET -eq 1 ] ; then
                ./tcls_base58check_enc.sh -T -q -p2pkh $result
              else
                ./tcls_base58check_enc.sh -q -p2pkh $result
              fi
              msig_redeem_str=$msig_redeem_str$ret_string
              # vv_output "        msig_redeem_str=$msig_redeem_str"
              ret_string=''
            fi
            ;;

        *)  cur_opcode_dec=$(( $cur_opcode_dec - 80 ))
            if [ $cur_opcode_dec -lt 10 ] ; then
              printf "    %s: OP_%d:                the number %d is pushed onto stack\n" $cur_opcode $cur_opcode_dec $cur_opcode_dec
            else
              printf "    %s: OP_%d:               the number %d is pushed onto stack\n" $cur_opcode $cur_opcode_dec $cur_opcode_dec
            fi
            echo "        ################### $msig_n-of-$cur_opcode_dec Multisig ###################################"
            break
            ;;
      esac
      rs_loopcounter=$(( rs_loopcounter + 1 ))
    done
    s41_OP_1TO16
  fi
}
################################
### STATUS 41 (s41_OP_1TO16) ###
################################
s41_OP_1TO16() {
  vv_output "s41_OP_1TO16()"
  get_next_opcode
  case $cur_opcode in
    AE) echo "    $cur_opcode: OP_CHECKMULTISIG:    terminating multisig"
        msig_redeem_str=$msig_redeem_str$cur_opcode
        if [ $Verbose -eq 1 ] ; then
          show_redeem_script $msig_redeem_str
          ret_string=$msig_redeem_str
          printf "        corresponding bitcoin address is: "
          rmd160_sha256
          if [ $TESTNET -eq 1 ] ; then
            ./tcls_base58check_enc.sh -T -q -p2sh $result
          else
            ./tcls_base58check_enc.sh -q -p2sh $result
          fi
          ret_string=''
          msig_redeem_str=''
        fi
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
############################
### STATUS 4a (s4a_CLTV) ###
############################
s4a_CLTV() {
  vv_output "s4a_CLTV()"
  get_next_opcode
  case $cur_opcode in
    75) echo "    $cur_opcode: OP_DROP:             Removes the top stack item"
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        s98_RET
        ;;
  esac
}
############################
### STATUS 4b (s4b_CSV)  ###
############################
s4b_CSV() {
  vv_output "s4b_CSV()"
  get_next_opcode
  case $cur_opcode in
    75) echo "    $cur_opcode: OP_DROP:             Removes the top stack item"
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        s98_RET
        ;;
  esac
}
##############################
### STATUS 51 (s51_SHA256) ###
##############################
s51_SHA256() {
  vv_output "s51_SHA256()"
  get_next_opcode
  case $cur_opcode in
    20) echo "    $cur_opcode: OP_Data:             Hash these 32 Bytes"
        op_data_show
        s52_DATA
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        ;;
  esac
}
##############################
### STATUS 52 (s52_DATA)   ###
##############################
s52_DATA() {
  vv_output "s52_DATA()"
  get_next_opcode
  case $cur_opcode in
    87) echo "    $cur_opcode: OP_Equal:            Returns 1 if inputs are equal, 0 otherwise"
        ;;
    *)  echo "    $cur_opcode: unknown opcode "
        s98_RET
        ;;
  esac
}
#################################
### STATUS 5a (s5a_PUSHDATA1) ###
#################################
s5a_PUSHDATA1() {
  vv_output "s5a_PUSHDATA1()"
  get_next_opcode
  if [ $cur_opcode_dec -gt 1 ] && [ $cur_opcode_dec -lt 255 ] ; then
    echo "    $cur_opcode: OP_Int(0x01-0xff):   $cur_opcode_dec bytes onto the stack"
  else
    echo "    $cur_opcode: unknown opcode "
    s98_RET
  fi 
}
#############################################################
### STATUS 97 (OP_N/A (0x01-0x4b) or OP_1-16 (0x51-0x60)) ###
#############################################################
s97_NA_or_1TO16() {
  vv_output "S97_NA_or_1to16()"
  if [ $cur_opcode_dec -gt 0 ] && [ $cur_opcode_dec -lt 75 ] ; then
    echo "    $cur_opcode: OP_Data(0x01-0x4b):  $cur_opcode_dec byte(s) to be pushed to the stack"
    if [ $cur_opcode_dec -ne 25 ] ; then
      op_data_show
    fi
  elif [ $cur_opcode_dec -gt 80 ] && [ $cur_opcode_dec -lt 96 ] ; then
    cur_opcode_dec=$(( $cur_opcode_dec - 80 ))
    if [ $cur_opcode_dec -lt 10 ] ; then
      printf "    %s: OP_%d:                the number %d is pushed onto stack\n" $cur_opcode $cur_opcode_dec $cur_opcode_dec 
    else
      printf "    %s: OP_%d:               the number %d is pushed onto stack\n" $cur_opcode $cur_opcode_dec $cur_opcode_dec 
    fi
    s40_OP_1TO16
  else
    echo "    $cur_opcode: unknown opcode "
    s99_UNKNOWN
  fi
}
###########################
### STATUS 99 (unknown) ###
###########################
s98_RET() {
  vv_output "S98_ret()"
  ss_array_ptr=$(( $ss_array_ptr - 1 ))
}
###########################
### STATUS 99 (unknown) ###
###########################
s99_UNKNOWN() {
  vv_output "S99_Unknown()"
}
	  
#################### 
### LET'S GO ... ###
####################

while [ $# -ge 1 ] 
 do
  case "$1" in
    -q)
       Quiet=1
       shift
       ;;
    -T)
       TESTNET=1
       shift
       ;;
    -v)
       Verbose=1
       shift
       ;;
    -vv)
       Verbose=1
       VVerbose=1
       shift
       ;;
    -?|-h|--help)
       echo "usage: tcls_in_sig_script.sh [-?|-h|--help|-q|-T|-v|-vv] hex_string"
       echo "  "
       echo "convert a raw hex string from a bitcoin tx-out into it's OpCodes. "
       echo "if no hex string is given, the data from a demo tx is used. "
       echo "  "
       exit 0
       ;;
    *)
       param=$( echo $1 | tr "[:lower:]" "[:upper:]" )
       shift
       ;;
  esac
done

if [ $Quiet -eq 0 ] ; then 
  echo "  ##################################################################"
  echo "  ### tcls_in_sig_script.sh: decode SIG_script OPCODES from a TX ###"
  echo "  ##################################################################"
fi

if [ $VVerbose -eq 1 ] ; then 
  echo "  a valid bitcoin signature (r,s) is going to look like:"
  echo "  <30><len><02><len><r bytes><02><len><s bytes><01>"
  echo "  with 9 <= length(sig) <= 73 (18-146 chars)"
  echo "  Multisig is much more complicated :-)"
fi

#################################################################
### set -A or declare ss_array - bash and ksh are different ! ###
#################################################################
result=$( echo "$param" | sed 's/[[:xdigit:]]\{2\}/& /g' )
shell_string=$( echo $SHELL | cut -d / -f 3 )
if [ "$shell_string" == "bash" ] ; then
  declare -a ss_array
  # running this on OpenBSD creates errors, hence a for loop...
  # ss_array=($result)
  # IFS=' ' read -a ss_array <<< "${result}"
  for TX_Char in $result; do ss_array[$n]=$TX_Char; ((n++)); done
elif [ "$shell_string" == "ksh" ] ; then 
  set -A ss_array $result
else
  echo "*** ERROR: could not identify shell, exiting gracefully..."
  echo " "
  exit 1
fi

#####################################
### STATUS 0 - INIT               ###
#####################################
  opcodes_len=${#param}
  # echo "array length=  ${#ss_array[*]}"
  # echo "array content= ${ss_array[@]}"
  while [ $ss_array_ptr -lt ${#ss_array[*]} ]
   do
    get_next_opcode
    # vv_output "S0_INIT, opcode=$cur_opcode, ss_array_ptr=$ss_array_ptr "
    vv_output "S0_INIT, opcode=$cur_opcode" 
    
    case $cur_opcode in
      00) echo "    $cur_opcode: OP_0, OP_FALSE:      an empty array is pushed onto the stack."
          ;;
      21) echo "    $cur_opcode: OP_DATA_0x21:        length compressed Public Key (X9.63 form, $cur_opcode_dec Bytes)"
	  s10_PK_LEN
          ;;
      3C) echo "    $cur_opcode: OP_DATA_0x3C:        type tag indicating LENGTH"
	  s0a_SIG_LEN
          ;;
      41) echo "    $cur_opcode: OP_DATA_0x41:        length uncompressed Public Key (X9.63 form, $cur_opcode_dec Bytes)"
	  s10_PK_LEN
          ;;
      46) echo "    $cur_opcode: OP_DATA_0x46:        push hex 46 (decimal 70) bytes on stack"
          s01_SIG_LEN
          ;;
      47) echo "    $cur_opcode: OP_DATA_0x47:        push hex 47 (decimal 71) bytes on stack"
          s01_SIG_LEN
          ;;
      48) echo "    $cur_opcode: OP_DATA_0x48:        push hex 48 (decimal 72) bytes on stack"
          s01_SIG_LEN
          ;;
      49) echo "    $cur_opcode: OP_DATA_0x49:        push hex 49 (decimal 73) bytes on stack"
          s01_SIG_LEN
          ;;
      4C) echo "    $cur_opcode: OP_PUSHDATA1:        next byte is # of bytes that go onto stack" 
	  s5a_PUSHDATA1
          ;;
      50) echo "    $cur_opcode: OP_RESERVED:         tx is invalid unless occuring in an unexecuted OP_IF branch"
          ;;
      63) echo "    $cur_opcode: OP_IF:               <expr> if [...] [else [...]]* endif"
          ;;
      64) echo "    $cur_opcode: NOT_IF:              <expr> notif [...] [else [...]]* endif"
          ;;
      67) echo "    $cur_opcode: OP_ELSE:             <expr> if [...] [else [...]]* endif"
          ;;
      68) echo "    $cur_opcode: OP_ENDIF:            <expr> if [...] [else [...]]* endif"
          ;;
      75) echo "    $cur_opcode: OP_DROP:             removes the top stack item "
          ;;
      76) echo "    $cur_opcode: OP_DUP:              duplicates the top stack item"
          s20_DUP
          ;;
      87) echo "    $cur_opcode: OP_EQUAL:            Returns 1 if the inputs are exactly equal, 0 otherwise"
          ;;
      88) echo "    $cur_opcode: OP_EQUALVERIFY:      Same as OP_EQUAL, but runs OP_VERIFY afterward"
          ;;
      A8) echo "    $cur_opcode: OP_SHA256:           input is hashed using SHA-256"
          s51_SHA256 
          ;;
      A9) echo "    $cur_opcode: OP_HASH160:          input is hashed with SHA-256 and RIPEMD-160"
          s30_HASH160
          ;;
      AC) echo "    $cur_opcode: OP_CHECKSIG:         sig must be a valid sig for hash and pubkey"
          ;;
      AD) echo "    $cur_opcode: OP_CHECKSIGVERIFY:   Same as OP_CHECKSIG, but OP_VERIFY is executed afterward"
          ;;
      B1) echo "    $cur_opcode: OP_CHECKLOCKTIMEVERIFY: see documentation..."
          s4a_CLTV
          ;;
      B2) echo "    $cur_opcode: OP_CHECKSEQUENCEVERIFY: see documentation..."
          s4b_CSV
          ;;
      *)  s97_NA_or_1TO16
          ;;
    esac

    # https://bitcointalk.org/index.php?topic=585639.0
    # A tx is invalid if any of the following are true
    # Block Size is >1,000 KB (this is a block level check but obviously a tx 
    # which can't fit into a block <=1MB could never be confirmed at least not 
    # until the 1MB limit is raised).
    # A script is >10KB (this is per script so tx can be larger if it contains 
    # multiple scripts each less than 10KB).
    # The size of the value being pushed in a script is >520 bytes (effectively 
    # limits P2SH scripts to 520 bytes as the redeemScript is pushed to the stack).
    #
  done


