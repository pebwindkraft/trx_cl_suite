#!/bin/sh
# some testcases for the shell script "trx_key2pem.sh"
#
# Copyright (c) 2015, 2016 Volker Nowarra 
# Complete rewrite in Nov/Dec 2015 
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

LOG=0
logfile=$0.log

to_logfile() {
  echo $chksum_ref >> $logfile
  cat tmpfile >> $logfile
  echo "=================================================================="  >> $logfile
  echo " " | tee -a $logfile
}

chksum_verify() {
if [ "$1" == "$2" ] ; then
  echo "ok"
else
  echo $1 | tee -a $logfile
  echo "********************   checksum  mismatch:  ********************"  | tee -a $logfile
  echo $2 | tee -a $logfile
  echo " " | tee -a $logfile
fi
}

chksum_prep() {
result=$( $chksum_cmd tmpfile | cut -d " " -f 2 )
echo $result | cut -d " " -f 2 >> $logfile
chksum_verify "$result" "$chksum_ref"
if [ $LOG -eq 1 ] ; then to_logfile ; fi
}

testcase1() {
# first get the checksums of all necessary files
echo "#############################################################" | tee -a $logfile
echo "### TESTCASE 1:                                           ###" | tee -a $logfile
echo "#############################################################" | tee -a $logfile
echo "###  first get the checksums of all necessary files       ###" >> $logfile
echo "#############################################################" >> $logfile

echo "TESTCASE 1a: $chksum_cmd trx_key2pem.sh" | tee -a $logfile
chksum_ref="3f7ad1a5f3a9dd436d12c8040f0c721de8f0a7a6fcd50ee7b734af5b15b16b92"
cp trx_key2pem.sh tmpfile
chksum_prep

echo "TESTCASE 1b: $chksum_cmd trx_verify_bc_address.awk" | tee -a $logfile
chksum_ref="eb7e79feeba3f1181291ce39620d93b1b8cf807cdfbe911b42e1d6cdbfecfbdc" 
cp trx_verify_bc_address.awk tmpfile
chksum_prep
echo " " | tee -a $logfile
}

testcase2() {
# do a testcase with the included example transaction
echo "#############################################################" | tee -a $logfile
echo "### TESTCASE 2:                                           ###" | tee -a $logfile
echo "#############################################################" | tee -a $logfile
echo "###  do a testcase with the parameters set incorrectly,   ###" >> $logfile
echo "###  and at the end 2 correct settings. This just serves  ###" >> $logfile
echo "###  to verify, that code is executing properly           ###" >> $logfile
echo "#############################################################" >> $logfile

echo "TESTCASE 2a: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  echo "#######################" | tee -a $logfile
  echo "This call should fail, cause no param at all" | tee -a $logfile
  echo " " | tee -a $logfile
fi
chksum_ref="a209f252cb851d64f9739832da2456e996f17f4fc656fb95b1ba3b5686ec7908" 
./trx_key2pem.sh > tmpfile
chksum_prep

echo "TESTCASE 2b: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  echo "#######################" | tee -a $logfile
  echo "This call should fail, cause -w has a wrong parameter" | tee -a $logfile
  echo " " | tee -a $logfile
fi 
chksum_ref="c0669fe1ef5bdf5fdd40689d3541ee6b93f1a6f40256e17d9a03eede0b095cb4"
./trx_key2pem.sh -w abc -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352 > tmpfile
chksum_prep

echo "TESTCASE 2c: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  echo "#######################" | tee -a $logfile
  echo "This call should fail, cause -p has wrong parameter" | tee -a $logfile
  echo " " | tee -a $logfile
fi
chksum_ref="5b8c5367f3925f958306d1ab41e5789dfe0b3104a5e2fcf03c52b2a0d5bd8834"
./trx_key2pem.sh -w 5J1F7GHadZG3sCCKHCwg8Jvys9xUbFsjLnGec4H125Ny1V9nR6V -p abc > tmpfile
chksum_prep

echo "TESTCASE 2d: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  echo "#######################" | tee -a $logfile
  echo "This call should fail, cause -x has wrong parameter" | tee -a $logfile
  echo " " | tee -a $logfile
fi
chksum_ref="907174ebe0e31aa71abecc013836ee5dab66bb5c174b21ee73d6fb30572236c6"
./trx_key2pem.sh -x abc -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352 > tmpfile
chksum_prep

echo "TESTCASE 2e: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  echo "#######################" | tee -a $logfile
  echo "This call should fail, cause param -p does not match wif format" | tee -a $logfile
  echo " " | tee -a $logfile
fi
chksum_ref="31fb1bccf5181bee93c7b66b47eb4511ec095d8860d63a1db9a00d01e59b73a3"
./trx_key2pem.sh -w 5J1F7GHadZG3sCCKHCwg8Jvys9xUbFsjLnGec4H125Ny1V9nR6V -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352 > tmpfile
chksum_prep

echo "TESTCASE 2f: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  echo "#######################" | tee -a $logfile
  echo "This call should fail, cause param -p does not match wif-c format" | tee -a $logfile
  echo " " | tee -a $logfile
fi
chksum_ref="6d7a590de3d9e805f5223be569d8abb79112dd821181a69190d0cd526f8cc47e"
./trx_key2pem.sh -w Kx45GeUBSMPReYQwgXiKhG9FzNXrnCeutJp4yjTd5kKxCitadm3C -p 0450863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b23522cd470243453a299fa9e77237716103abc11a1df38855ed6f2ee187e9c582ba6 > tmpfile
chksum_prep

echo "TESTCASE 2g: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  echo "#######################" | tee -a $logfile
  echo "This call should work, cause param -q provides minimum output" | tee -a $logfile
  echo " " | tee -a $logfile
fi
chksum_ref="e3e263df8ffadb28414ccb3e3d6c1d3d3410e789dea84c793be1b82714009203"
./trx_key2pem.sh -q -x 18E14A7B6A307F426A94F8114701E7C8E774E7F9A47E2C2035DB29A206321725 -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352 > tmpfile
if [ $? -eq 0 ] ; then
  echo "TESTCASE 2g: " >> tmpfile
  echo "============ " >> tmpfile
  echo "./trx_key2pem.sh -q -x 18E14A7B6A307F426A94F8114701E7C8E774E7F9A47E2C2035DB29A206321725 -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352" >> tmpfile
  echo " " >> tmpfile
  echo "as the [-q] parameter is given, the call will produce no output, hence"   >> tmpfile
  echo "in positive case nothing is displayed, and nothing added to the tmpfile." >> tmpfile
  echo "what happens, when something gors wrong, and output is produced? "        >> tmpfile
else
  echo "something went wrong, please check manually" >> tmpfile
fi
chksum_prep

echo "TESTCASE 2h: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  echo "#######################" | tee -a $logfile
  echo "This call should work, cause -x works with -p <uncompressed> " | tee -a $logfile
  echo " " | tee -a $logfile
fi
chksum_ref="72219544dded92eccebb0d3c67b0a8b972fd770ccdbdd4525bb59ce9bf0850fa"
./trx_key2pem.sh -v -x 18E14A7B6A307F426A94F8114701E7C8E774E7F9A47E2C2035DB29A206321725 -p 0450863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b23522cd470243453a299fa9e77237716103abc11a1df38855ed6f2ee187e9c582ba6 > tmpfile 
chksum_prep

echo "TESTCASE 2i: " | tee -a $logfile
if [ $LOG -eq 1 ] ; then
  echo "#######################" | tee -a $logfile
  echo "This call should work, cause -x works with -p <compressed> " | tee -a $logfile
  echo "as '-vv' is given, openssl creates new priv/pub key pairs. " | tee -a $logfile
  echo "So we only checksum the first 60 lines of output ...       " | tee -a $logfile
  echo " " | tee -a $logfile
fi
chksum_ref="cd7763ef111450f1eecefb553480c1398f9f7e7fc2e34bae9534a362274b17a9"
./trx_key2pem.sh -vv -x 18E14A7B6A307F426A94F8114701E7C8E774E7F9A47E2C2035DB29A206321725 -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352 | head -n60 > tmpfile 
chksum_prep
echo " " | tee -a $logfile
}

testcase3() {
echo "#############################################################" | tee -a $logfile
echo "### TESTCASE 3:                                           ###" | tee -a $logfile
echo "#############################################################" | tee -a $logfile
echo "###  we have hex privkey, wif and wifc, and a hex public  ###" >> $logfile
echo "###  key. This is a simple example, and should just work  ###" >> $logfile
echo "#############################################################" >> $logfile
echo "from: http://www.cryptosys.net/pki/ecc-bitcoin-raw-transaction.html" | tee -a $logfile

echo "TESTCASE 3a: " | tee -a $logfile
chksum_ref="de52d623558dbac74e67db27149f8b7e07ee6feb4916da826b53a8410234bc95"
./trx_key2pem.sh -v -x 0ecd20654c2e2be708495853e8da35c664247040c00bd10b9b13e5e86e6a808d -p 042daa93315eebbe2cb9b5c3505df4c6fb6caca8b756786098567550d4820c09db988fe9997d049d687292f815ccd6e7fb5c1b1a91137999818d17c73d0f80aef9 > tmpfile
chksum_prep

echo "TESTCASE 3b: " | tee -a $logfile
chksum_ref="e1cca678d35db62f8afbb4fbbb2b34a106e0d6c56506ecc5b0679ee0f33060a1"
./trx_key2pem.sh -v -w 5HvofFG7K1e2aeWESm5pbCzRHtCSiZNbfLYXBvxyA57DhKHV4U3 -p 042daa93315eebbe2cb9b5c3505df4c6fb6caca8b756786098567550d4820c09db988fe9997d049d687292f815ccd6e7fb5c1b1a91137999818d17c73d0f80aef9 > tmpfile
chksum_prep

echo "TESTCASE 3c: " | tee -a $logfile
chksum_ref="ecde8a067227fb66a8e0d652e77e88b8bfc5e6eae03d43a30727bb4c8f15c8cc"
./trx_key2pem.sh -v -w KwiUwowgrVpRyWY2LhaH3yvSDWyWWRtKzDG8FFC2s38T2f6gX2Jb -p 032DAA93315EEBBE2CB9B5C3505DF4C6FB6CACA8B756786098567550D4820C09DB > tmpfile
chksum_prep
echo " " | tee -a $logfile
}

testcase4() {
echo "#############################################################" | tee -a $logfile
echo "### TESTCASE 4:                                           ###" | tee -a $logfile
echo "#############################################################" | tee -a $logfile
echo "###  another simple testcase, should just work :-)        ###" >> $logfile
echo "#############################################################" >> $logfile
echo "from: http://bitcoin.stackexchange.com/questions/32628/redeeming-a-raw-transaction-step-by-step-example-required" | tee -a $logfile

echo "TESTCASE 4a: " | tee -a $logfile
chksum_ref="134b7645b4aef6637d9deb1efa13e06a022133a040d4061dc61801d9d4a1d03a"
./trx_key2pem.sh -v -x 18E14A7B6A307F426A94F8114701E7C8E774E7F9A47E2C2035DB29A206321725 -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352 > tmpfile
chksum_prep

echo "TESTCASE 4b: " | tee -a $logfile
chksum_ref="53bfcf553cd552664c0358bee10558800aae11fe1298df636488382556310891"
./trx_key2pem.sh -v -w 5J1F7GHadZG3sCCKHCwg8Jvys9xUbFsjLnGec4H125Ny1V9nR6V -p 0450863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b23522cd470243453a299fa9e77237716103abc11a1df38855ed6f2ee187e9c582ba6 > tmpfile
chksum_prep

echo "TESTCASE 4c: " | tee -a $logfile
chksum_ref="73dcdedf8b68af6036c212b95155d55cfcfc38da67006741af6aeba6d15bdab9"
./trx_key2pem.sh -v -w Kx45GeUBSMPReYQwgXiKhG9FzNXrnCeutJp4yjTd5kKxCitadm3C -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352 > tmpfile
chksum_prep
echo " " | tee -a $logfile
}

echo " "
echo "##############################################"
echo "###           KEYHANDLING TESTCASES       ###"
echo "##############################################"
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

###############################################################
# verify our operating system, cause checksum commands differ ... #
###############################################################
OS=$(uname) 
if [ OS="OpenBSD" ] ; then
  chksum_cmd=sha256
fi
if [ OS="Linux" ] ; then
  chksum_cmd="openssl sha256"
fi
if [ OS="Darwin" ] ; then
  chksum_cmd="openssl sha256"
fi

case "$1" in
  -l|--log)
     LOG=1
     shift
     all_testcases
     ;;
  -?|-h|--help)
     echo "usage: trx_testcases.sh [1-8|-?|-h|--help|-l|--log]"
     echo "  "
     echo "script does several testcases, mostly with checksums for verification"
     echo "script accepts max one parameter !" 
     echo "  "
     exit 0
     ;;
  1|2|3|4|5|6|7|8|9)
     testcase$1 
     shift
     ;;
  *)
     all_testcases
     ;;
esac

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

