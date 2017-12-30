#!/bin/sh
# some testcases for the shell script "tcls_key2pem.sh"
#
# Copyright (c) 2015, 2016 Volker Nowarra 
# updated regularly with the root shell script
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
typeset -i no_cleanup=0
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

proc_help() {
  echo "  "
  echo "usage: $0 -h|-k|-l [1-4]"
  echo "  "
  echo "script does several testcases, mostly with checksums for verification"
  echo "  "
  echo "  -h help"
  echo "  -k keep all the temp files (don't do cleanup)"
  echo "  -l log output to file $0.log"
  echo "  "
}

cleanup() {
  for i in tmp*; do
    if [ -f "$i" ]; then rm $i ; fi
  done
  for i in *hex; do
    if [ -f "$i" ]; then rm $i ; fi
  done
  for i in ossl*; do
    if [ -f "$i" ]; then rm $i ; fi
  done
  for i in *pem; do
    if [ -f "$i" ]; then rm $i ; fi
  done
  for i in priv*; do
    if [ -f "$i" ]; then rm $i ; fi
  done
  for i in pub*; do
    if [ -f "$i" ]; then rm $i ; fi
  done
}


testcase1() {
echo "=============================================================" | tee -a $logfile
echo "=== TESTCASE 1: get the checksums of all necessary files  ===" | tee -a $logfile
echo "=============================================================" | tee -a $logfile

echo "TESTCASE 1a: $chksum_cmd tcls_key2pem.sh" | tee -a $logfile
cp tcls_key2pem.sh tmp_tx_cfile
chksum_ref="aab5ccc4d4d9329039ea08ef13e6cbc63642e1af19c3111d95f4ac708b7040e3"
chksum_prep

echo "TESTCASE 1b: $chksum_cmd tcls_verify_bc_address.awk" | tee -a $logfile
cp tcls_verify_bc_address.awk tmp_tx_cfile
chksum_ref="c944ff89ff49454ca03b0ea8f3ce8ebbd44e33e8d87ab48ae00ad4d6544099f6" 
chksum_prep

echo "TESTCASE 1c: $chksum_cmd tcls_verify_hexkey.awk" | tee -a $logfile
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

echo "TESTCASE 2a: call should fail, cause no param at all" | tee -a $logfile
echo "./tcls_key2pem.sh " >> $logfile
./tcls_key2pem.sh > tmp_tx_cfile
chksum_ref="dab9fd3828a3902487a905101779ddbc2001a4290d9f5259953c52438dd731a8" 
chksum_prep

echo "TESTCASE 2b: call should fail, cause -w has a wrong parameter" | tee -a $logfile
echo "./tcls_key2pem.sh -w abc -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352" >> $logfile
./tcls_key2pem.sh -w abc -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352 > tmp_tx_cfile
chksum_ref="ab158867d386a098bf47e1d632c1013e3267a05ad6360f1d83da6fedd49e33a7"
chksum_prep

echo "TESTCASE 2c: call should fail, cause -p has wrong parameter"   | tee -a $logfile
echo "./tcls_key2pem.sh -w 5J1F7GHadZG3sCCKHCwg8Jvys9xUbFsjLnGec4H125Ny1V9nR6V -p abc" >> $logfile
./tcls_key2pem.sh -w 5J1F7GHadZG3sCCKHCwg8Jvys9xUbFsjLnGec4H125Ny1V9nR6V -p abc > tmp_tx_cfile
chksum_ref="a6bc46d3fb043166c83256c500e486079bcf6d3bc525c37c15f5d1c29baf6e7b"
chksum_prep

echo "TESTCASE 2d: call should fail, cause -x has wrong parameter" | tee -a $logfile
echo "./tcls_key2pem.sh -x abc -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352" >> $logfile
./tcls_key2pem.sh -x abc -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352 > tmp_tx_cfile
chksum_ref="2a6797b8c5f60fb9c6a3cd5606462a3785f349069e2429f40a8b7d8d773bf1af"
chksum_prep

echo "TESTCASE 2e: call should fail, cause -p with wrong (wif) format" | tee -a $logfile
echo "./tcls_key2pem.sh -w 5J1F7GHadZG3sCCKHCwg8Jvys9xUbFsjLnGec4H125Ny1V9nR6V -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352" >> $logfile
./tcls_key2pem.sh -w 5J1F7GHadZG3sCCKHCwg8Jvys9xUbFsjLnGec4H125Ny1V9nR6V -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352 > tmp_tx_cfile
chksum_ref="31fb1bccf5181bee93c7b66b47eb4511ec095d8860d63a1db9a00d01e59b73a3"
chksum_prep

echo "TESTCASE 2f: call should fail, cause -p with wrong (wif-c) format" | tee -a $logfile
echo "./tcls_key2pem.sh -w Kx45GeUBSMPReYQwgXiKhG9FzNXrnCeutJp4yjTd5kKxCitadm3C -p 0450863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b23522cd470243453a299fa9e77237716103abc11a1df38855ed6f2ee187e9c582ba6" >> $logfile
./tcls_key2pem.sh -w Kx45GeUBSMPReYQwgXiKhG9FzNXrnCeutJp4yjTd5kKxCitadm3C -p 0450863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b23522cd470243453a299fa9e77237716103abc11a1df38855ed6f2ee187e9c582ba6 > tmp_tx_cfile
chksum_ref="6d7a590de3d9e805f5223be569d8abb79112dd821181a69190d0cd526f8cc47e"
chksum_prep

echo "TESTCASE 2g: call should work, cause param -q provides minimum output" | tee -a $logfile
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

echo "TESTCASE 2h: call should work, cause -x works with -p <uncompressed> " | tee -a $logfile
echo "./tcls_key2pem.sh -v -x 18E14A7B6A307F426A94F8114701E7C8E774E7F9A47E2C2035DB29A206321725 -p 0450863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b23522cd470243453a299fa9e77237716103abc11a1df38855ed6f2ee187e9c582ba6" >> $logfile
./tcls_key2pem.sh -v -x 18E14A7B6A307F426A94F8114701E7C8E774E7F9A47E2C2035DB29A206321725 -p 0450863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b23522cd470243453a299fa9e77237716103abc11a1df38855ed6f2ee187e9c582ba6 > tmp_tx_cfile 
chksum_ref="69fd939a7babeb89584a035d0de76d54cba837128ac49c7b9f88d53354e8e220"
chksum_prep

echo "TESTCASE 2i: call should work, cause -x works with -p <compressed>"    | tee -a $logfile
echo "             with '-vv' given, openssl creates new priv/pub key   "    >> $logfile
echo "             pairs. So we only checksum the first 60 lines of output." >> $logfile
./tcls_key2pem.sh -vv -x 18E14A7B6A307F426A94F8114701E7C8E774E7F9A47E2C2035DB29A206321725 -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352 | head -n60 > tmp_tx_cfile 
chksum_ref="e1d088e11e92219d422c3ee48baf1c72c324d065dbc05adb7e23c124e0b94219"
chksum_prep

echo " " | tee -a $logfile
}

testcase3() {
echo "=============================================================" | tee -a $logfile
echo "=== TESTCASE 3: check with hex privkey, wif and wifc      ===" | tee -a $logfile
echo "=============================================================" | tee -a $logfile
echo "from: http://www.cryptosys.net/pki/ecc-bitcoin-raw-transaction.html" >> $logfile

echo "TESTCASE 3a: with a hex privkey, should just work... " | tee -a $logfile
echo "./tcls_key2pem.sh -v -x 0ecd20654c2e2be708495853e8da35c664247040c00bd10b9b13e5e86e6a808d -p 042daa93315eebbe2cb9b5c3505df4c6fb6caca8b756786098567550d4820c09db988fe9997d049d687292f815ccd6e7fb5c1b1a91137999818d17c73d0f80aef9" >> $logfile
./tcls_key2pem.sh -v -x 0ecd20654c2e2be708495853e8da35c664247040c00bd10b9b13e5e86e6a808d -p 042daa93315eebbe2cb9b5c3505df4c6fb6caca8b756786098567550d4820c09db988fe9997d049d687292f815ccd6e7fb5c1b1a91137999818d17c73d0f80aef9 > tmp_tx_cfile
chksum_ref="5f0a3295bc8108816241ca5b1efae4e424d501f73294dd51bbdbae2ba2aa12f5"
chksum_prep

echo "TESTCASE 3b: with a wif privkey, should just work... " | tee -a $logfile
echo "./tcls_key2pem.sh -v -w 5HvofFG7K1e2aeWESm5pbCzRHtCSiZNbfLYXBvxyA57DhKHV4U3 -p 042daa93315eebbe2cb9b5c3505df4c6fb6caca8b756786098567550d4820c09db988fe9997d049d687292f815ccd6e7fb5c1b1a91137999818d17c73d0f80aef9" >> $logfile
./tcls_key2pem.sh -v -w 5HvofFG7K1e2aeWESm5pbCzRHtCSiZNbfLYXBvxyA57DhKHV4U3 -p 042daa93315eebbe2cb9b5c3505df4c6fb6caca8b756786098567550d4820c09db988fe9997d049d687292f815ccd6e7fb5c1b1a91137999818d17c73d0f80aef9 > tmp_tx_cfile
chksum_ref="a88e8153b468f9e9aa94a4e89999e468674b91cb464bf59700d641a09df7f719"
chksum_prep

echo "TESTCASE 3c: with a wif-c privkey, should just work... " | tee -a $logfile
echo "./tcls_key2pem.sh -v -w KwiUwowgrVpRyWY2LhaH3yvSDWyWWRtKzDG8FFC2s38T2f6gX2Jb -p 032DAA93315EEBBE2CB9B5C3505DF4C6FB6CACA8B756786098567550D4820C09DB" >> $logfile
./tcls_key2pem.sh -v -w KwiUwowgrVpRyWY2LhaH3yvSDWyWWRtKzDG8FFC2s38T2f6gX2Jb -p 032DAA93315EEBBE2CB9B5C3505DF4C6FB6CACA8B756786098567550D4820C09DB > tmp_tx_cfile
chksum_ref="16a633b87e29f1fbce9269bc8d6653354c377bfa6c6f1b0b160f6e9966210c12"
chksum_prep

echo " " | tee -a $logfile
}

testcase4() {
echo "=============================================================" | tee -a $logfile
echo "=== TESTCASE 4: another simple testcase, should just work ===" | tee -a $logfile
echo "=============================================================" | tee -a $logfile
echo "from: http://bitcoin.stackexchange.com/questions/32628/redeeming-a-raw-transaction-step-by-step-example-required" >> $logfile

echo "TESTCASE 4a: with param -v -x" | tee -a $logfile
echo "./tcls_key2pem.sh -v -x 18E14A7B6A307F426A94F8114701E7C8E774E7F9A47E2C2035DB29A206321725 -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352" >> $logfile
./tcls_key2pem.sh -v -x 18E14A7B6A307F426A94F8114701E7C8E774E7F9A47E2C2035DB29A206321725 -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352 > tmp_tx_cfile
chksum_ref="0e915e5f11d0f753bfe8713d8497649ab79c3c2199db28798aa5b9a54f979045"
chksum_prep

echo "TESTCASE 4b: with param -v -w" | tee -a $logfile
echo "./tcls_key2pem.sh -v -w 5J1F7GHadZG3sCCKHCwg8Jvys9xUbFsjLnGec4H125Ny1V9nR6V -p 0450863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b23522cd470243453a299fa9e77237716103abc11a1df38855ed6f2ee187e9c582ba6" >> $logfile
./tcls_key2pem.sh -v -w 5J1F7GHadZG3sCCKHCwg8Jvys9xUbFsjLnGec4H125Ny1V9nR6V -p 0450863ad64a87ae8a2fe83c1af1a8403cb53f53e486d8511dad8a04887e5b23522cd470243453a299fa9e77237716103abc11a1df38855ed6f2ee187e9c582ba6 > tmp_tx_cfile
chksum_ref="f6b85f6b60ff9d482853c0a9bee80f9dd4a11e4dde54df3019f05e15bb6cdb60"
chksum_prep

echo "TESTCASE 4c: with param -v -w" | tee -a $logfile
echo "./tcls_key2pem.sh -v -w Kx45GeUBSMPReYQwgXiKhG9FzNXrnCeutJp4yjTd5kKxCitadm3C -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352" >> $logfile
./tcls_key2pem.sh -v -w Kx45GeUBSMPReYQwgXiKhG9FzNXrnCeutJp4yjTd5kKxCitadm3C -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352 > tmp_tx_cfile
chksum_ref="a0cb46f651eef358e5bf4bfb97c425110c748e9f963036fa0e88c33bf95e665f"
chksum_prep

echo "TESTCASE 4d: with param -vv, no chksum, cause signature changes everytime" | tee -a $logfile
echo "./tcls_key2pem.sh -vv -w Kx45GeUBSMPReYQwgXiKhG9FzNXrnCeutJp4yjTd5kKxCitadm3C -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352" >> $logfile
./tcls_key2pem.sh -vv -w Kx45GeUBSMPReYQwgXiKhG9FzNXrnCeutJp4yjTd5kKxCitadm3C -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352 > tmp_tx_cfile

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
  -h)
     proc_help
     exit 0
     ;;
  -k)
     # keep all the temp files = no_cleanup!
     no_cleanup=1
     shift
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

# clean up?
if [ $no_cleanup -eq 0 ] ; then 
  cleanup
fi

