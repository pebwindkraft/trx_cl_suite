##############################################################################
#
# awk script by Sven-Volker Nowarra 
#
# Version	by	date	comment
# 0.1		svn	14jul16	initial release
#
# Usage:
# echo "bitcoin hex key" | awk -f trx_verify_hexkey.awk
#
# Parameters: 
# "bitcoin hex key": a hex string, that is verified against the rules
#
# verify if the provided parameter (the bitcoin private or public key in hex)
# is valid. The chars of a bitcoin hex key must be a part of these:
#   [0123456789ABCDEFabcdef]
# The characteristics of a bitcoin hex key must be:
#   - 64 chars for private keys
#   - 66 chars for a COMPRESSED public key, beginning with "0x02" or "0x03"
#   - 130 chars for an UNCOMPRESSED public key, beginning with "0x04"
# 
# This is realized with awk, to stay a POSIX compliant, cause the different 
# shell comparisons with regexp(s) are not really portable. Also code 
# is more "readable" :-)
#

BEGIN {
  hexchars="0123456789ABCDEFabcdef"
  hexchars_offset=1 
  bitcoin_key_offset=1
  found=0
  }

##########################################################################
### function to validate characters of hexkey string                   ###
##########################################################################
function validate() {
  # loop through the bitcoin key, fetch each char
  while ( bitcoin_key_offset <= length($0) ) {
    bitcoin_key_char = substr($1, bitcoin_key_offset, 1) 
  
    # loop through the hexchars, and see if bitcoin address char is included
    while ( hexchars_offset <= length(hexchars) ) {
      found=0
      hexchar = substr(hexchars, hexchars_offset, 1) 
      if ( bitcoin_key_char == hexchar )
        {
        # printf "  bitcoin_key_char %s = hexchar %s \n", bitcoin_key_char, hexchar 
        hexchars_offset=1 
        found=1
        break
        }
      hexchars_offset=hexchars_offset+1 
      }
    bitcoin_key_offset=bitcoin_key_offset+1 
    }

  if ( found == 1 )
    {
    # printf " found valid bitcoin hex key string\n"
    return 0
    }
  else
    {
    printf "*** Error: invalid bitcoin hex key string\n"
    exit 1
    }
} 


##########################################################################
### AND HERE WE GO ...                                                 ###
##########################################################################
{
  hex_key_len=length($0)
  if ( hex_key_len == 64 )
    { 
    validate() 
    exit 0
    }

  if ( hex_key_len == 66 )
    { 
    # check, if first hex code is "02" or "03"
    bitcoin_key_char = substr($1, bitcoin_key_offset, 2) 
    if (bitcoin_key_char != "02" && bitcoin_key_char != "03")
      {
      printf "*** Error: pubkey does not start with '0x02' or '0x03' \n"
      exit 1
      }
    else
      {
      validate() 
      exit 0
      }
    }

  if ( hex_key_len == 130 )
    { 
    # check, if first hex code is "04" 
    bitcoin_key_char = substr($1, bitcoin_key_offset, 2) 
    if (bitcoin_key_char != "04")
      {
      printf "*** Error: pubkey does not start with '0x04' \n"
      exit 1
      }
    else
      {
      validate() 
      exit 0
      }
    }
  
  printf "*** Error: hex key string is of unknown length (%d) \n", hex_key_len
  exit 1
 
}

# END {
#     printf("\ndone ...")
# }

