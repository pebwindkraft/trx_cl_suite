#!/bin/sh
# some testcases for the shell script "tcls_key2pem.sh"
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
chksum_verify "$result" "$chksum_ref"
if [ $LOG -eq 1 ] ; then to_logfile ; fi
}

testcase1() {
echo "=============================================================" | tee -a $logfile
echo "=== TESTCASE 1: get the checksums of all necessary files  ===" | tee -a $logfile
echo "=============================================================" | tee -a $logfile

echo "=== TESTCASE 1a: $chksum_cmd tcls_key2pem.sh" | tee -a $logfile
cp tcls_key2pem.sh tmp_tx_cfile
chksum_ref="34cad1c05bb7fd7c4bce56b157c9faf1cdfe92d9076128e493d1b3fe382e0dc5"
chksum_prep

echo "=== TESTCASE 1b: $chksum_cmd tcls_verify_bc_address.awk" | tee -a $logfile
cp tcls_verify_bc_address.awk tmp_tx_cfile
chksum_ref="30f1fabc40cf3725febf28cc267d6a52507033106341f4a0c925ed2df0c55c1e" 
chksum_prep

echo "=== TESTCASE 1c: $chksum_cmd tcls_verify_hexkey.awk" | tee -a $logfile
cp tcls_verify_hexkey.awk tmp_tx_cfile
chksum_ref="055b79074a8f33d0aa9aa7634980d29f4e3eb0248a730ea784c7a88e64aa7cfd" 
chksum_prep
echo " " | tee -a $logfile

}

testcase2() {
# do a testcase with the included example transaction
echo "=============================================================" | tee -a $logfile
echo "=== TESTCASE 2: parameter checking ...                    ===" | tee -a $logfile
echo "=============================================================" | tee -a $logfile
echo "===  do a testcase with the parameters set incorrectly,   ===" >> $logfile
echo "===  and at the end 2 correct settings. This just serves  ===" >> $logfile
echo "===  to verify, that code is executing properly           ===" >> $logfile
echo "=============================================================" >> $logfile

echo "=== TESTCASE 2a: call should fail, cause no param at all" | tee -a $logfile
echo "./tcls_key2pem.sh " >> $logfile
./tcls_key2pem.sh > tmp_tx_cfile
chksum_ref="1ad035232212b66ee02e216af898f5eb1bad451efc8642feee30f74b05901539" 
chksum_prep

echo "=== TESTCASE 2b: call should fail, cause -w has a wrong parameter" | tee -a $logfile
echo "./tcls_key2pem.sh -w abc -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352" >> $logfile
./tcls_key2pem.sh -w abc -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352 > tmp_tx_cfile
chksum_ref="c421146f3ed99302e7934dc5f69e3504375e54d3f323ae244aa13972fa813355"
chksum_prep

echo "=== TESTCASE 2c: call should fail, cause -p has wrong parameter"   | tee -a $logfile
echo "./tcls_key2pem.sh -w 5J1F7GHadZG3sCCKHCwg8Jvys9xUbFsjLnGec4H125Ny1V9nR6V -p abc" >> $logfile
./tcls_key2pem.sh -w 5J1F7GHadZG3sCCKHCwg8Jvys9xUbFsjLnGec4H125Ny1V9nR6V -p abc > tmp_tx_cfile
chksum_ref="d6540deee423f93cf1e40f96b3a7a7e9ebb7032252b1a7d955e09629a147fc72"
chksum_prep

echo "=== TESTCASE 2d: call should fail, cause -x has wrong parameter" | tee -a $logfile
echo "./tcls_key2pem.sh -x abc -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352" >> $logfile
./tcls_key2pem.sh -x abc -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352 > tmp_tx_cfile
chksum_ref="9968e118f84e35b808ddf28529007fa12076fd8219b484ddbb45520b0772ee51"
chksum_prep

echo "=== TESTCASE 2e: call should fail, cause -p with wrong (wif) format" | tee -a $logfile
echo "./tcls_key2pem.sh -w 5J1F7GHadZG3sCCKHCwg8Jvys9xUbFsjLnGec4H125Ny1V9nR6V -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352" >> $logfile
./tcls_key2pem.sh -w 5J1F7GHadZG3sCCKHCwg8Jvys9xUbFsjLnGec4H125Ny1V9nR6V -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352 > tmp_tx_cfile
chksum_ref="31fb1bccf5181bee93c7b66b47eb4511ec095d8860d63a1db9a00d01e59b73a3"
chksum_prep

echo "=== TESTCASE 2f: call should fail, cause -p with wrong (wif-c) format" | tee -a $logfile
echo "./tcls_key2pem.sh -w Kx45GeUBSMPReYQwgXiKhG9FzNXrnCeutJp4yjTd5kKxCitadm3C -p 0450863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b23522cd470243453a299fa9e77237716103abc11a1df38855ed6f2ee187e9c582ba6" >> $logfile
./tcls_key2pem.sh -w Kx45GeUBSMPReYQwgXiKhG9FzNXrnCeutJp4yjTd5kKxCitadm3C -p 0450863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b23522cd470243453a299fa9e77237716103abc11a1df38855ed6f2ee187e9c582ba6 > tmp_tx_cfile
chksum_ref="6d7a590de3d9e805f5223be569d8abb79112dd821181a69190d0cd526f8cc47e"
chksum_prep

echo "=== TESTCASE 2g: call should work, cause param -q provides minimum output" | tee -a $logfile
echo "./tcls_key2pem.sh -q -x 18E14A7B6A307F426A94F8114701E7C8E774E7F9A47E2C2035DB29A206321725 -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352" >> $logfile
./tcls_key2pem.sh -q -x 18E14A7B6A307F426A94F8114701E7C8E774E7F9A47E2C2035DB29A206321725 -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352 > tmp_tx_cfile
if [ $? -eq 0 ] ; then
  echo " " >> $logfile
  echo "as the [-q] parameter is given, the call will produce no output, hence in" >> $logfile
  echo "positive case nothing is displayed, and nothing added to the tmp_tx_cfile." >> $logfile
  echo "what happens, when something goes wrong, and output is produced? " >> $logfile
else
  echo "something went wrong, please check manually" >> $logfile
fi
chksum_ref="e16f1596201850fd4a63680b27f603cb64e67176159be3d8ed78a4403fdb1700"
chksum_prep

echo "=== TESTCASE 2h: call should work, cause -x works with -p <uncompressed> " | tee -a $logfile
echo "./tcls_key2pem.sh -v -x 18E14A7B6A307F426A94F8114701E7C8E774E7F9A47E2C2035DB29A206321725 -p 0450863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b23522cd470243453a299fa9e77237716103abc11a1df38855ed6f2ee187e9c582ba6" >> $logfile
./tcls_key2pem.sh -v -x 18E14A7B6A307F426A94F8114701E7C8E774E7F9A47E2C2035DB29A206321725 -p 0450863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b23522cd470243453a299fa9e77237716103abc11a1df38855ed6f2ee187e9c582ba6 > tmp_tx_cfile 
chksum_ref="72219544dded92eccebb0d3c67b0a8b972fd770ccdbdd4525bb59ce9bf0850fa"
chksum_prep

echo "=== TESTCASE 2i: call should work, cause -x works with -p <compressed>"    | tee -a $logfile
echo "             with '-vv' given, openssl creates new priv/pub key   "    >> $logfile
echo "             pairs. So we only checksum the first 60 lines of output." >> $logfile
./tcls_key2pem.sh -vv -x 18E14A7B6A307F426A94F8114701E7C8E774E7F9A47E2C2035DB29A206321725 -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352 | head -n60 > tmp_tx_cfile 
chksum_ref="33cade63795fc8b305942d46f761de9583361ca805b5b3b0fed749e27ca6edd6"
chksum_prep

echo " " | tee -a $logfile
}

testcase3() {
echo "=============================================================" | tee -a $logfile
echo "=== TESTCASE 3: check with hex privkey, wif and wifc      ===" | tee -a $logfile
echo "=============================================================" | tee -a $logfile
echo "from: http://www.cryptosys.net/pki/ecc-bitcoin-raw-transaction.html" >> $logfile

echo "=== TESTCASE 3a: with a hex privkey, should just work... " | tee -a $logfile
echo "./tcls_key2pem.sh -v -x 0ecd20654c2e2be708495853e8da35c664247040c00bd10b9b13e5e86e6a808d -p 042daa93315eebbe2cb9b5c3505df4c6fb6caca8b756786098567550d4820c09db988fe9997d049d687292f815ccd6e7fb5c1b1a91137999818d17c73d0f80aef9" >> $logfile
./tcls_key2pem.sh -v -x 0ecd20654c2e2be708495853e8da35c664247040c00bd10b9b13e5e86e6a808d -p 042daa93315eebbe2cb9b5c3505df4c6fb6caca8b756786098567550d4820c09db988fe9997d049d687292f815ccd6e7fb5c1b1a91137999818d17c73d0f80aef9 > tmp_tx_cfile
chksum_ref="de52d623558dbac74e67db27149f8b7e07ee6feb4916da826b53a8410234bc95"
chksum_prep

echo "=== TESTCASE 3b: with a wif privkey, should just work... " | tee -a $logfile
echo "./tcls_key2pem.sh -v -w 5HvofFG7K1e2aeWESm5pbCzRHtCSiZNbfLYXBvxyA57DhKHV4U3 -p 042daa93315eebbe2cb9b5c3505df4c6fb6caca8b756786098567550d4820c09db988fe9997d049d687292f815ccd6e7fb5c1b1a91137999818d17c73d0f80aef9" >> $logfile
./tcls_key2pem.sh -v -w 5HvofFG7K1e2aeWESm5pbCzRHtCSiZNbfLYXBvxyA57DhKHV4U3 -p 042daa93315eebbe2cb9b5c3505df4c6fb6caca8b756786098567550d4820c09db988fe9997d049d687292f815ccd6e7fb5c1b1a91137999818d17c73d0f80aef9 > tmp_tx_cfile
chksum_ref="e1cca678d35db62f8afbb4fbbb2b34a106e0d6c56506ecc5b0679ee0f33060a1"
chksum_prep

echo "=== TESTCASE 3c: with a wif-c privkey, should just work... " | tee -a $logfile
echo "./tcls_key2pem.sh -v -w KwiUwowgrVpRyWY2LhaH3yvSDWyWWRtKzDG8FFC2s38T2f6gX2Jb -p 032DAA93315EEBBE2CB9B5C3505DF4C6FB6CACA8B756786098567550D4820C09DB" >> $logfile
./tcls_key2pem.sh -v -w KwiUwowgrVpRyWY2LhaH3yvSDWyWWRtKzDG8FFC2s38T2f6gX2Jb -p 032DAA93315EEBBE2CB9B5C3505DF4C6FB6CACA8B756786098567550D4820C09DB > tmp_tx_cfile
chksum_ref="ecde8a067227fb66a8e0d652e77e88b8bfc5e6eae03d43a30727bb4c8f15c8cc"
chksum_prep

echo " " | tee -a $logfile
}

testcase4() {
echo "=============================================================" | tee -a $logfile
echo "=== TESTCASE 4: another simple testcase, should just work ===" | tee -a $logfile
echo "=============================================================" | tee -a $logfile
echo "from: http://bitcoin.stackexchange.com/questions/32628/redeeming-a-raw-transaction-step-by-step-example-required" >> $logfile

echo "=== TESTCASE 4a: " | tee -a $logfile
echo "./tcls_key2pem.sh -v -x 18E14A7B6A307F426A94F8114701E7C8E774E7F9A47E2C2035DB29A206321725 -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352" >> $logfile
./tcls_key2pem.sh -v -x 18E14A7B6A307F426A94F8114701E7C8E774E7F9A47E2C2035DB29A206321725 -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352 > tmp_tx_cfile
chksum_ref="134b7645b4aef6637d9deb1efa13e06a022133a040d4061dc61801d9d4a1d03a"
chksum_prep

echo "=== TESTCASE 4b: " | tee -a $logfile
echo "./tcls_key2pem.sh -v -w 5J1F7GHadZG3sCCKHCwg8Jvys9xUbFsjLnGec4H125Ny1V9nR6V -p 0450863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b23522cd470243453a299fa9e77237716103abc11a1df38855ed6f2ee187e9c582ba6" >> $logfile
./tcls_key2pem.sh -v -w 5J1F7GHadZG3sCCKHCwg8Jvys9xUbFsjLnGec4H125Ny1V9nR6V -p 0450863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b23522cd470243453a299fa9e77237716103abc11a1df38855ed6f2ee187e9c582ba6 > tmp_tx_cfile
chksum_ref="53bfcf553cd552664c0358bee10558800aae11fe1298df636488382556310891"
chksum_prep

echo "=== TESTCASE 4c: " | tee -a $logfile
echo "./tcls_key2pem.sh -v -w Kx45GeUBSMPReYQwgXiKhG9FzNXrnCeutJp4yjTd5kKxCitadm3C -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352" >> $logfile
./tcls_key2pem.sh -v -w Kx45GeUBSMPReYQwgXiKhG9FzNXrnCeutJp4yjTd5kKxCitadm3C -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352 > tmp_tx_cfile
chksum_ref="73dcdedf8b68af6036c212b95155d55cfcfc38da67006741af6aeba6d15bdab9"
chksum_prep

echo " " | tee -a $logfile
}

echo " "
echo "=============================================="
echo "===           KEYHANDLING TESTCASES       ==="
echo "=============================================="
echo " "

all_testcases() {
  testcase1 
  testcase2 
  testcase3 
  testcase4 
# testcase5 
# testcase6 
# testcase7 
# testcase8 
# testcase9 
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
  -h|--help)
     echo "usage: testcases_tcls_key2pem.sh [-?|-h|-l|1-8]"
     echo "  "
     echo "script does several testcases, mostly with checksums for verification"
     echo "  "
     exit 0
     ;;
  -l|--log)
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

