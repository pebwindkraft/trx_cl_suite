#!/bin/sh
# 
# test script to verify timing (speed) of different operation(s)
#
# Copyright (c) 2016 Volker Nowarra
# Complete rewrite in Nov/Dec 2016
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
# ########################################################################################
# profiling the shell scripts, using strace:
#
#   strace -f -o strace.log <program> 
# 
# Output is a file called "strace.log"containing every single system call issued by 
# the script and any forked programs. 
# then grep for the execve() system call and gather the counts of the programs executed, 
# (excluding “execve resumed” events which aren’t actual execve() calls):
# 
#   grep execve strace.txt | sed 's/.*execve/execve/' | \
#     cut -d\" -f2 | grep -v resumed | sort | uniq -c | sort -g
# 
# The resulting output looks like this:
# ...
# 157 /bin/tail
# 227 /usr/bin/cut
# 
# ########################################################################################

rawtx_fn=tmp_rawtx.txt
typeset -i i=0
typeset -i max=100


fill_line() {
  char_length=${#max}
  case $char_length in
   1) printf "                       ===" | tee -a $logfile
      ;;
   2) printf "                      ===" | tee -a $logfile
      ;;
   3) printf "                     ===" | tee -a $logfile
      ;;
   4) printf "                    ===" | tee -a $logfile
      ;;
   5) printf "                   ===" | tee -a $logfile
      ;;
  esac
  printf "\n" | tee -a $logfile
}
  
prepdata() {
  echo "./trx_2txt.sh -vv -r 010000000117a14c047d5bcc8c39a5335821c4461d7f737bacb0734db289f0240113372f9f010000006a47304402200e7f6e5b0089770f3bce07c3e71cf239184dcd13b43ab8ac6639b10d6433ffdd0220034e6e45f3f2f791e716ff81761169a7f38f962670e7125ccff787a9c2afeb7d0121020d0fb39080eea3fa2223003c219a16e5e3f050933a7b36db6cbd16d728cb1fceffffffff02e0c81000000000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88aca44d2200000000001976a91447ac42e612ea7eae770bac6ff3c0157e94ca00d488ac00000000 | grep -A7 TX_OUT[0] > $rawtx_fn"
  ./trx_2txt.sh -vv -r 010000000117a14c047d5bcc8c39a5335821c4461d7f737bacb0734db289f0240113372f9f010000006a47304402200e7f6e5b0089770f3bce07c3e71cf239184dcd13b43ab8ac6639b10d6433ffdd0220034e6e45f3f2f791e716ff81761169a7f38f962670e7125ccff787a9c2afeb7d0121020d0fb39080eea3fa2223003c219a16e5e3f050933a7b36db6cbd16d728cb1fceffffffff02e0c81000000000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88aca44d2200000000001976a91447ac42e612ea7eae770bac6ff3c0157e94ca00d488ac00000000 | grep -A7 TX_OUT[[]0[]] > $rawtx_fn
}

testcase1() {
echo "================================================================" | tee -a $logfile
printf "=== TESTCASE 1: loop with $max iterations" | tee -a $logfile
fill_line
echo "================================================================" | tee -a $logfile
i=0
START=`date +%s`
echo "=== TESTCASE 1a: using grep/cut/tr, start time: $START   ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
while [ $i -lt $max ]
do
  PREV_Amount=$( grep -m1 bitcoin $rawtx_fn | cut -d "=" -f 4 | cut -d "," -f 1 )
  STEP5_SCRIPT_LEN=$( grep -A1 -B1 pk_script $rawtx_fn | head -n1 | cut -b 7,8 )
  STEP6_SCRIPTSIG=$( grep -A1 -B1 pk_script $rawtx_fn | tail -n1 | tr -d "[:space:]" )
  RAW_TRX=''
  i=$(( i + 1 ))
done
echo "   PREV_Amount=$PREV_Amount"
echo "   STEP5_SCRIPT_LEN=$STEP5_SCRIPT_LEN"
echo "   STEP6_SCRIPTSIG=$STEP6_SCRIPTSIG"
END=`date +%s`
echo "loop finished, with end time=$END"
# ELAPSED=`echo "scale=4 ($END - $START) / 1000000000" | bc`
ELAPSED=$(( $END - $START ))
echo "Elapsed time: $ELAPSED"
}

testcase2() {
echo "================================================================" | tee -a $logfile
printf "=== TESTCASE 2: loop with $max iterations" | tee -a $logfile
fill_line
echo "================================================================" | tee -a $logfile
i=0
START=`date +%s`
echo "=== TESTCASE 2a: using awk, start time: $START           ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "loop with $max iterations using awk, start time=$START:"
while [ $i -lt $max ]
do
  PREV_Amount=$( awk -F "=|," '/bitcoin/ { print $6 }' $rawtx_fn )
  STEP5_SCRIPT_LEN=$( awk -F ",|=" 'NR==5 { print $2 }' $rawtx_fn )
  STEP6_SCRIPTSIG=$( awk '/pk_script/ { getline;print $1}' $rawtx_fn )
  RAW_TRX=''
  i=$(( i + 1 ))
done
echo "   PREV_Amount=$PREV_Amount"
echo "   STEP5_SCRIPT_LEN=$STEP5_SCRIPT_LEN"
echo "   STEP6_SCRIPTSIG=$STEP6_SCRIPTSIG"
END=`date +%s`
echo "loop finished, with end time=$END"
# ELAPSED=`echo "scale=4 ($END - $START) / 1000000000" | bc`
ELAPSED=$(( $END - $START ))
echo "Elapsed time: $ELAPSED"
}

all_testcases() {
  testcase1 
  testcase2 
}

#####################
### here we start ###
#####################



if [ $# -eq 0 ] ; then
  prepdata
  all_testcases
fi

while [ $# -ge 1 ] 
 do
  case "$1" in
  -h)
     echo "usage: $0 -h [1-9]"
     echo "  "
     echo "script does several timing testcases"
     echo "  "
     exit 0
     ;;
  1|2|3|4|5|6|7|8|9)
     prepdata
     testcase$1 
     shift
     ;;
  *)
     echo "unknown parameter(s), try -h, exiting gracefully ..."
     exit 0
     ;;
  esac
done

# clean up
for f in tmp*; do
  if [ -f "$f" ]; then rm $f ; fi
done


