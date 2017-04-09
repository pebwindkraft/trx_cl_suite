##############################################################################
#
# awk script by Sven-Volker Nowarra 
#
# Version	by	date	comment
# 0.1		svn	15jul16	initial release
#
# verify if the provided parameter ("the bitcoin address") and base58 decode it.
# The length of the bitcoin address must be 33 or 34 chars.
# The chars of the bitcoin address must be a part of the base58 charset.
# 
# This is done to stay POSIX compliant, cause the different shell 
# comparisons with regexp(s) are not really portable. Also code 
# is more "readable" :-)
#

BEGIN {
  base58str="123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"
  bc_address_offset=1
  base58str_offset=1 
  found=0
  }

##########################################################################
### AND HERE WE GO ...                                                 ###
##########################################################################
# adress length: https://en.bitcoin.it/wiki/Address --> 26-35!!
{
if (length($0) >= "26" && length($0) <= "35" || length($0) == "51" || length($0) == "52")
  { 
  # loop through the bitcoin adress, fetch each char
  while ( bc_address_offset <= length($0) ) {
    bc_address_char = substr($0, bc_address_offset, 1) 

    # loop through the base58str, and see if bitcoin address char is included
    while ( base58str_offset <= length(base58str) ) {
      found=0
      base58str_char = substr(base58str, base58str_offset, 1) 
      if ( bc_address_char == base58str_char )
        {
        printf " %d", base58str_offset-1
        base58str_offset=1 
        found=1
        break
        }
      base58str_offset=base58str_offset+1 
      }
    bc_address_offset=bc_address_offset+1 
    }
  if ( found == 1 )
    {
    # printf "found valid bitcoin string"
    printf "\n" 
    exit 0
    }
  else
    {
    printf "*** Error: no valid bitcoin string found \n"
    exit 1
    }
  }
else
  {
  printf "*** Error: length of parameter != 33 or 34 \n"
  exit 1
  }
}

# END {
#     printf("\ndone ...")
# }

