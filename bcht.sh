#! /bin/sh
#
# for all hashing activities:
# Bitcoin never does hashes with the hex strings, 
# so need to convert it to hex codes in files. 

tmp_hex_fn=tmp_file.hex
tmp_hex_sha256_fn=tmp_sha256.hex
tmp_txt_sha256_fn=tmp_sha256.txt
tmp_hex_dsha256_fn=tmp_dsha256.hex
tmp_txt_dsha256_fn=tmp_dsha256.txt
tmp_hex_ripemd160_fn=tmp_ripemd160.hex
tmp_txt_ripemd160_fn=tmp_ripemd160.txt

#################################
### here we start ...         ###
#################################
# procedure to display helptext #
#################################
proc_help() {
  echo " "
  echo "usage: $0 option <ascii string>"
  echo " "
  echo "a small tool to help on string manipulation/conversion with bitcoin logic"
  echo "  "
  echo "option can be:"
  echo " -h    show this help text" 
  echo " -an   display only alphanumerics from a string"
  echo " -d2h  convert parameter from decimal to hex"
  echo " -hash show sha256, double sha256 and ripemd hashes, and drop into files"
  echo " -h2d  convert parameter from hex to decimal"
  echo " -len  return length of provided parameter"
  echo " -lenx return length of provided parameter, devided by 2"
  echo " -rev  return the string in reversed form"
  echo "  "
  echo " without parameter(s), show this help text" 
  echo " "
}

#######################################
### procedure to check with openssl ###
####################################### 
o_ssl_vfy() {
  echo "sha256: $3"
  printf $( echo $3 | sed 's/[[:xdigit:]]\{2\}/\\x&/g' ) > tmp_utx_dsha256.hex
  echo "double sha256: "
  hexdump -C tmp_utx_dsha256.hex
  echo "pubkey in HEX: $2"
  echo "pubkey in PEM format:"
  cat pubkey.pem
  echo "ScriptSig:     $1"
  printf $( echo $1 | sed 's/[[:xdigit:]]\{2\}/\\x&/g' ) > tmp_sig.hex
  openssl pkeyutl <tmp_utx_dsha256.hex -verify -pubin -inkey pubkey.pem -sigfile tmp_sig.hex
  echo " "
}
  
an() 
{ 
  echo "$1" | sed 's/[^a-zA-Z0-9]//g' | tr -d '\n'
  echo " "
}

d2h() 
{ 
  echo "obase=16;$1" | bc
}

h2d() 
{ 
  echo "ibase=16;$1" | bc
}

len() 
{ 
  printf "$1" | wc -c
}

lenx() 
{ 
  my_len=$( len $1)
  d2h "$my_len / 2"
}

rev() {
# s=s substr($0,i,1) means, that substr($0,i,1) is appended to the variable s; s=s+something
  echo $1 | awk '{ for(i=length;i!=0;i=i-2)s=s substr($0,i-1,2);}END{print s}'
}

hash() {
printf $( echo $1 | sed 's/[[:xdigit:]]\{2\}/\\x&/g' ) > $tmp_hex_fn
hexdump -C $tmp_hex_fn

# sha256 
openssl dgst -sha256         <$tmp_hex_fn        >$tmp_txt_sha256_fn
openssl dgst -sha256 -binary <$tmp_hex_fn        >$tmp_hex_sha256_fn
openssl dgst -sha256         <$tmp_hex_sha256_fn >$tmp_txt_dsha256_fn
openssl dgst -sha256 -binary <$tmp_hex_sha256_fn >$tmp_hex_dsha256_fn
printf "sha256:    "
cat $tmp_txt_sha256_fn
printf "dsha256:   "
cat $tmp_txt_dsha256_fn

# ripemd160
openssl dgst -binary -ripemd160 <$tmp_hex_fn >$tmp_hex_ripemd160_fn
openssl dgst -ripemd160 <$tmp_hex_fn >$tmp_txt_ripemd160_fn
printf "ripemd160: "
cat $tmp_txt_ripemd160_fn
}

################################
# command line params handling #
################################

if [ $# -eq 0 ] || [ $# -eq 1 ] ; then
  proc_help
  exit 0
fi
case "$1" in
  -h)    proc_help
         exit 0
         ;;
  -an)   an "$2"
         ;;
  -d2h)  d2h $2
         ;;
  -hash) hash $2
         ;;
  -h2d)  h2d $2
         ;;
  -len)  len $2
         ;;
  -lenx) lenx $2
         ;;
  -rev)  rev $2
         ;;
  *)     proc_help
         ;;
esac


