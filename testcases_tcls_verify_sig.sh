#!/bin/sh
# some testcases for the shell script "trx_verify_sig.sh" 
#
# Copyright (c) 2015, 2016 Volker Nowarra 
# initial release in Nov 2016
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
  cat tmp_trx_cfile >> $logfile
  echo " " >> $logfile
}

chksum_prep() {
result=$( $chksum_cmd tmp_trx_cfile | cut -d " " -f 2 )
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
echo "=== TESTCASE 1a: $chksum_cmd tcls_verify_sig.sh" | tee -a $logfile
echo "================================================================" | tee -a $logfile
cp tcls_verify_sig.sh tmp_trx_cfile
chksum_ref="c34a6f50f56d8d712f70c3c4103c643b0e9d883941f36227dc4d71d113737896" 
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 1b: $chksum_cmd trx_key2pem.sh" | tee -a $logfile
echo "================================================================" | tee -a $logfile
cp trx_key2pem.sh tmp_trx_cfile
chksum_ref="ed600c2acb39c75eac530cd2c1f7687ccb341eb05fc459ce5164ec454044b63b" 
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 1c: $chksum_cmd trx_strict_sig_verify.sh" | tee -a $logfile
echo "================================================================" | tee -a $logfile
cp trx_strict_sig_verify.sh tmp_trx_cfile
chksum_ref="ed600c2acb39c75eac530cd2c1f7687ccb341eb05fc459ce5164ec454044b63b"
chksum_prep

echo " " | tee -a $logfile
}

testcase2() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 2: parameters testing ...                       ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 2a: check -p, -s and -d params"                      | tee -a $logfile
echo "================================================================" | tee -a $logfile

echo " " | tee -a $logfile
}

testcase3() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 3: the pizza transaction ...                    ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 3a: quiet operation..."                              | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./tcls_verify_sig.sh -d c2d48f45d7fbeff644ddb72b0f60df6c275f0943444d7df8cc851b3d55782669 -p 042e930f39ba62c6534ee98ed20ca98959d34aa9e057cda01cfd422c6bab3667b76426529382c23f42b9b08d7832d4fee1d6b437a8526e59667ce9c4e9dcebcabb -s 30450221009908144ca6539e09512b9295c8a27050d478fbb96f8addbc3d075544dc41328702201aa528be2b907d316d2da068dd9eb1e23243d97e444d59290d2fddf25269ee0e" >> $logfile
./tcls_verify_sig.sh -d c2d48f45d7fbeff644ddb72b0f60df6c275f0943444d7df8cc851b3d55782669  -p 042e930f39ba62c6534ee98ed20ca98959d34aa9e057cda01cfd422c6bab3667b76426529382c23f42b9b08d7832d4fee1d6b437a8526e59667ce9c4e9dcebcabb -s 30450221009908144ca6539e09512b9295c8a27050d478fbb96f8addbc3d075544dc41328702201aa528be2b907d316d2da068dd9eb1e23243d97e444d59290d2fddf25269ee0e > tmp_trx_cfile
chksum_ref="0bd65ea014d3210c1b9a7d7d5af78bc4e4b4384b4f3f7f5674e8d6447e4112c3"
chksum_prep

echo "=== TESTCASE 3b: be a bit more verbose..." | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./tcls_verify_sig.sh -v -d c2d48f45d7fbeff644ddb72b0f60df6c275f0943444d7df8cc851b3d55782669 -p 042e930f39ba62c6534ee98ed20ca98959d34aa9e057cda01cfd422c6bab3667b76426529382c23f42b9b08d7832d4fee1d6b437a8526e59667ce9c4e9dcebcabb -s 30450221009908144ca6539e09512b9295c8a27050d478fbb96f8addbc3d075544dc41328702201aa528be2b907d316d2da068dd9eb1e23243d97e444d59290d2fddf25269ee0e" >> $logfile
./tcls_verify_sig.sh -v -d c2d48f45d7fbeff644ddb72b0f60df6c275f0943444d7df8cc851b3d55782669  -p 042e930f39ba62c6534ee98ed20ca98959d34aa9e057cda01cfd422c6bab3667b76426529382c23f42b9b08d7832d4fee1d6b437a8526e59667ce9c4e9dcebcabb -s 30450221009908144ca6539e09512b9295c8a27050d478fbb96f8addbc3d075544dc41328702201aa528be2b907d316d2da068dd9eb1e23243d97e444d59290d2fddf25269ee0e > tmp_trx_cfile 
chksum_ref="89fda5b2d0d818c65b39f9790af4076235ee62b58282a6e704750ac63d9809d7" 
chksum_prep

echo "=== TESTCASE 3c: be very verbose..." | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./tcls_verify_sig.sh -vv -d c2d48f45d7fbeff644ddb72b0f60df6c275f0943444d7df8cc851b3d55782669 -p 042e930f39ba62c6534ee98ed20ca98959d34aa9e057cda01cfd422c6bab3667b76426529382c23f42b9b08d7832d4fee1d6b437a8526e59667ce9c4e9dcebcabb -s 30450221009908144ca6539e09512b9295c8a27050d478fbb96f8addbc3d075544dc41328702201aa528be2b907d316d2da068dd9eb1e23243d97e444d59290d2fddf25269ee0e" >> $logfile
./tcls_verify_sig.sh -vv -d c2d48f45d7fbeff644ddb72b0f60df6c275f0943444d7df8cc851b3d55782669  -p 042e930f39ba62c6534ee98ed20ca98959d34aa9e057cda01cfd422c6bab3667b76426529382c23f42b9b08d7832d4fee1d6b437a8526e59667ce9c4e9dcebcabb -s 30450221009908144ca6539e09512b9295c8a27050d478fbb96f8addbc3d075544dc41328702201aa528be2b907d316d2da068dd9eb1e23243d97e444d59290d2fddf25269ee0e > tmp_trx_cfile 
chksum_ref="331c305ac2269bb865b68b7ec6a01765beb916ec8a1da5f20d65d58c81d0bd40" 
chksum_prep

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
for i in *pem; do
  if [ -f "$i" ]; then rm $i ; fi
done

