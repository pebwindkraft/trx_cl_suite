#!/bin/sh
# some testcases for the shell script "tcls_sign.sh" 
#
# Copyright (c) 2015, 2016 Volker Nowarra 
# updated regularly with the root shell script
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

typeset -i LOG=0
logfile=$0.log

chksum_verify() {
if [ "$1" == "$2" ] ; then
  echo "ok"
else
  echo $1 | tee -a $logfile
  echo "*************** checksum  mismatch, ref is: ********************" | tee -a $logfile
  echo $2 | tee -a $logfile
  echo " " | tee -a $logfile
fi
}

to_logfile() {
  # echo $chksum_ref >> $logfile
  cat tmp_tx_cfile >> $logfile
  echo " " >> $logfile
}

chksum_prep() {
result=$( $chksum_cmd tmp_tx_cfile | cut -d " " -f 2 )
# echo $result | cut -d " " -f 2 >> $logfile
chksum_verify "$result" "$chksum_ref" 
if [ $LOG -eq 1 ] ; then to_logfile ; fi
}

testcase1() {
# first get the checksums of all necessary files
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 1: get the checksums of all necessary files     ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile

echo "   " | tee -a $logfile
echo "=== TESTCASE 1a: $chksum_cmd tcls_sign.sh" | tee -a $logfile
echo "================================================================" | tee -a $logfile
cp tcls_sign.sh tmp_tx_cfile
chksum_ref="eeda73b75d2b347246852adecb257f8af496670f430ce7a647cc9dd4606d6a60" 
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 1b: $chksum_cmd tcls_key2pem.sh" | tee -a $logfile
echo "================================================================" | tee -a $logfile
cp tcls_key2pem.sh tmp_tx_cfile
chksum_ref="c761104dc86dfc5705377a45e368fd1337cc0bc400b9cab13f735485a4409b89" 
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 1c: $chksum_cmd tcls_strict_sig_verify.sh" | tee -a $logfile
echo "================================================================" | tee -a $logfile
cp tcls_strict_sig_verify.sh tmp_tx_cfile
chksum_ref="6ab63138c0458b37998335aba0b86e41cc4e0213f6dec3875530e5e0983944b1" 
chksum_prep

echo " " | tee -a $logfile
}


testcase2() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 2: parameters testing                           ===" | tee -a $logfile
echo "=== do several testcases with parameters set incorrectly     ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile

echo "=== TESTCASE 2a: param file is missing, show correct hint ..."    | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./tcls_sign.sh -f tmp_utx.txt -w XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXQPcN4 -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0" >> $logfile 
./tcls_sign.sh -f tmp_utx.txt -w XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXQPcN4 -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0 > tmp_tx_cfile
chksum_ref="66258cdef1cba9a4538ec12cf6a1894d7b13bf389e04dd75a236ad4b2808f546" 
chksum_prep
echo " " | tee -a $logfile
}
 

testcase3() {
###
### the script sigs are changing on every call, need to filter result!!
###
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 3: sign a tx, prepared from tcls_create.sh      ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 3a: use one TX-In and one TX-Out                ===" | tee -a $logfile
echo "===  1 input from: 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM        ===" | tee -a $logfile
echo "===  1 output to:  13GnHB51piDBf1avocPL7tSKLugK4F7U2B        ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./tcls_sign.sh -v -f tmp_c_utx.txt -w KyP5KEp6DCmF222YM5EB9yGeMFxdVK1QWgtGvWnLRnDmiCtQPcN4 -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0" >> $logfile
printf "010000000174fb6858c31a292d20c9744187032bddb7ddea02a3aa3ef523c8524a21481881010000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88acffffffff01b08f0600000000001976a91418ec49b27624086a2b6f35f263d951d25dbe24b688ac0000000001000000" > tmp_c_utx.txt
./tcls_sign.sh -v -f tmp_c_utx.txt -w KyP5KEp6DCmF222YM5EB9yGeMFxdVK1QWgtGvWnLRnDmiCtQPcN4 -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0 > tmp_cfile
head -n 38 tmp_cfile > tmp_tx_cfile
echo " " >> tmp_tx_cfile
echo "###############################################" >> tmp_tx_cfile
echo "### signatures and hashes change every time ###" >> tmp_tx_cfile
echo "### for better verification, we add output  ###" >> tmp_tx_cfile
echo "### from ./tcls_tx2txt.sh -vv -r ...        ###" >> tmp_tx_cfile
echo "### but this is not part of checksum check! ###" >> tmp_tx_cfile
echo "###############################################" >> tmp_tx_cfile
echo " " >> tmp_tx_cfile
chksum_ref="708251ae719a70dfde9db2c776896d3a8dba7376ba9d47461cd2bdb0da486d44" 
chksum_prep
result=$( cat tmp_stx.txt )
./tcls_tx2txt.sh -vv -r $result >> $logfile

echo " " | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 3b: same as 3a, use 1 TX-In and 1 TX-Out        ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "===  4 inputs from: 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM       ===" | tee -a $logfile
echo "===  1 output to:   13GnHB51piDBf1avocPL7tSKLugK4F7U2B       ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./tcls_sign.sh -v -f tmp_c_utx.txt -w KyP5KEp6DCmF222YM5EB9yGeMFxdVK1QWgtGvWnLRnDmiCtQPcN4 -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0" >> $logfile
printf "0100000004b0772e6ef46c2d3c60418bb7d5c2c015d6b943e5fca07570eb82c26dc7c9d248010000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88acffffffff74fb6858c31a292d20c9744187032bddb7ddea02a3aa3ef523c8524a21481881010000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88acffffffffcc21e36eedb509c660681c1e949dd294bd4c11692439221004c2235d565b74bb000000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88acffffffffea919487e04ed509d6cb9c7297c277b9be3a68f3836c7d86df378714a75949e8000000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88acffffffff01b08f0600000000001976a91418ec49b27624086a2b6f35f263d951d25dbe24b688ac0000000001000000" > tmp_c_utx.txt
./tcls_sign.sh -v -f tmp_c_utx.txt -w KyP5KEp6DCmF222YM5EB9yGeMFxdVK1QWgtGvWnLRnDmiCtQPcN4 -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0 > tmp_cfile
head -n 69 tmp_cfile > tmp_tx_cfile
echo " " >> tmp_tx_cfile
echo "###############################################" >> tmp_tx_cfile
echo "### signatures and hashes change every time ###" >> tmp_tx_cfile
echo "### for better verification, we add output  ###" >> tmp_tx_cfile
echo "### from ./tcls_tx2txt.sh -vv -r ...        ###" >> tmp_tx_cfile
echo "### but this is not part of checksum check! ###" >> tmp_tx_cfile
echo "###############################################" >> tmp_tx_cfile
echo " " >> tmp_tx_cfile
chksum_ref="e903b2dd44989409e86392fea6e6c13200a74b6be2748e71148dc3f8f7c46d83" 
chksum_prep
result=$( cat tmp_stx.txt )
./tcls_tx2txt.sh -vv -r $result >> tmp_tx_cfile

echo " " | tee -a $logfile
}


all_testcases() {
  testcase1 
  testcase2 
  testcase3 
}

#####################
### here we start ###
#####################
logfile=$0.log
if [ -f "$logfile" ] ; then rm $logfile; fi
echo $date > $logfile

###################################################################
# verify our operating system, cause checksum commands differ ... #
###################################################################
OS=$(uname) 
if [ OS="OpenBSD" ] ; then
  chksum_cmd=sha256
fi
if [ OS="Linux" ] ; then
  chksum_cmd="openssl sha256"
fi
if [ OS="Darwin" ] ; then
  chksum_cmd="openssl dgst -sha256"
fi

################################
# command line params handling #
################################

if [ $# -eq 0 ] ; then
  all_testcases
fi

if [ $# -eq 1 ] && [ "$1" == "-l" ] ; then
  LOG=1
  shift
  all_testcases
fi

while [ $# -ge 1 ] 
 do
  case "$1" in
  -h)
     echo "usage: $0 -h|-l [1-9]"
     echo "  "
     echo "script does several testcases, mostly with checksums for verification"
     echo "  "
     exit 0
     ;;
  -l)
     LOG=1
     shift
     ;;
  1|2|3|4|5|6|7|8|9)
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
for i in tmp*; do
  if [ -f "$i" ]; then rm $i ; fi
done
for i in *hex; do
  if [ -f "$i" ]; then rm $i ; fi
done
for i in priv*; do
  if [ -f "$i" ]; then rm $i ; fi
done
for i in pub*; do
  if [ -f "$i" ]; then rm $i ; fi
done


