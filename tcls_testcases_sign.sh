#!/bin/sh
# some testcases for the shell script "tcls_sign.sh" 
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
  # echo $result | cut -d " " -f 2 >> $logfile
  chksum_verify "$result" "$chksum_ref" 
  if [ $LOG -eq 1 ] ; then to_logfile ; fi
}

proc_help() {
  echo "  "
  echo "usage: $0 -h|-k|-l [1-9]"
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
  for i in priv*; do
    if [ -f "$i" ]; then rm $i ; fi
  done
  for i in pub*; do
    if [ -f "$i" ]; then rm $i ; fi
  done
}

testcase1() {
# first get the checksums of all necessary files
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 1: get the checksums of all necessary files     ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile

echo "=== TESTCASE 1a: $chksum_cmd tcls_sign.sh" | tee -a $logfile
cp tcls_sign.sh tmp_tx_cfile
chksum_ref="eff95bc71786f6eafd5c219a04f0404f383edf1bcb3e3573b5bb7998705886ec" 
chksum_prep

echo "=== TESTCASE 1b: $chksum_cmd tcls_key2pem.sh" | tee -a $logfile
cp tcls_key2pem.sh tmp_tx_cfile
chksum_ref="0b5fb56e663368f7e011e49b8caf3560aff87c3176c1608b482f398c1deaaf1f" 
chksum_prep

echo "=== TESTCASE 1c: $chksum_cmd tcls_strict_sig_verify.sh" | tee -a $logfile
cp tcls_strict_sig_verify.sh tmp_tx_cfile
chksum_ref="50bf08de6166ebbb3ca520ae92f93360aad48f5a4c6d3fa0f71575736b0b9169" 
chksum_prep

echo " " | tee -a $logfile
}


testcase2() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 2: parameters testing                           ===" | tee -a $logfile
echo "=== do several testcases with parameters set incorrectly     ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile

echo "=== TESTCASE 2a: file tmp_utx.txt is missing, show correct hint ..." | tee -a $logfile
echo "./tcls_sign.sh -f tmp_utx.txt -w XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXQPcN4 -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0" >> $logfile 
printf "010000000174fb6858c31a292d20c9744187032bddb7ddea02a3aa3ef523c8524a21481881010000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88acffffffff01b08f0600000000001976a91418ec49b27624086a2b6f35f263d951d25dbe24b688ac0000000001000000" > tmp_utx.txt
./tcls_sign.sh -f tmp_utx.txt -w XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXQPcN4 -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0 > tmp_tx_cfile
chksum_ref="ccd4c93a3f68e788cf5a784ce21475e8075b5905d74c4f98e73f06b0a0cba55c" 
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
echo "=== TESTCASE 3a: use one TX-In and one TX-Out         " | tee -a $logfile
echo "===  1 input from: 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM " >> $logfile
echo "===  1 output to:  13GnHB51piDBf1avocPL7tSKLugK4F7U2B " >> $logfile
echo "printf 010000000174fb6858c31a292d20c9744187032bddb7ddea02a3aa3ef523c8524a21481881010000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88acffffffff01b08f0600000000001976a91418ec49b27624086a2b6f35f263d951d25dbe24b688ac0000000001000000 > tmp_c_utx.txt" >> $logfile
echo "./tcls_sign.sh -v -f tmp_c_utx.txt -w KyP5KEp6DCmF222YM5EB9yGeMFxdVK1QWgtGvWnLRnDmiCtQPcN4 -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0" >> $logfile

printf "010000000174fb6858c31a292d20c9744187032bddb7ddea02a3aa3ef523c8524a21481881010000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88acffffffff01b08f0600000000001976a91418ec49b27624086a2b6f35f263d951d25dbe24b688ac0000000001000000" > tmp_c_utx.txt

./tcls_sign.sh -v -f tmp_c_utx.txt -w KyP5KEp6DCmF222YM5EB9yGeMFxdVK1QWgtGvWnLRnDmiCtQPcN4 -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0 > tmp_cfile
head -n 38 tmp_cfile > tmp_tx_cfile
echo " " >> tmp_tx_cfile
echo "###############################################" >> tmp_tx_cfile
echo "### signatures and hashes change every time ###" >> tmp_tx_cfile
echo "### for better verification, we search and  ###" >> tmp_tx_cfile
echo "### replace some data of the sigs (0xXX...) ###" >> tmp_tx_cfile
echo "###############################################" >> tmp_tx_cfile
echo " " >> tmp_tx_cfile

./tcls_tx2txt.sh -vv -f tmp_stx.txt > tmp_svn
# get some data into the compare file, without signature (which is changing everytime)
echo "  ..." > tmp_tx_cfile
cat tmp_svn | grep -A6 -B1 "decode SIG_script OPCODES" | sed 's/20/XX/g;s/21/XX/g;s/32/xx/g;s/33/xx/g;s/44/XX/g;s/45/XX/g;s/46/XX/g;s/47/XX/g;s/48/XX/g;s/49/XX/g;s/70/xx/g;s/71/xx/g;s/72/xx/g' >> tmp_tx_cfile
echo "        <SIG R>" >> tmp_tx_cfile
cat tmp_svn | grep "this is SIG S" | sed 's/20/XX/g;s/21/XX/g;s/32/xx/g;s/33/xx/g' >> tmp_tx_cfile
echo "        <SIG S>" >> tmp_tx_cfile
echo "        strict sig checks ..." >> tmp_tx_cfile
cat tmp_svn  | tail -n 32 >> tmp_tx_cfile
echo " " >> tmp_tx_cfile
# we verify the signature with the script tmp_vfy.sh, which is created by tcls_sign.sh 
# again, we take only the last line, to avoid ever changing signature data
echo "### tmp_vfy.sh:" >> tmp_tx_cfile
./tmp_vfy.sh | tail -n2 >> tmp_tx_cfile
echo " " >> tmp_tx_cfile
chksum_ref="d7747f8dfeed8a6150a2d0520233e0ab4668d311256defa0ed438ee0f1a488d9" 
chksum_prep

echo " " >> $logfile
echo "=== TESTCASE 3b: use 4 TX-In and 1 TX-Out " | tee -a $logfile
echo "===  4 inputs from: 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM ===" >> $logfile
echo "===  1 output to:   13GnHB51piDBf1avocPL7tSKLugK4F7U2B ===" >> $logfile
echo "printf 0100000004b0772e6ef46c2d3c60418bb7d5c2c015d6b943e5fca07570eb82c26dc7c9d248010000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88acffffffff74fb6858c31a292d20c9744187032bddb7ddea02a3aa3ef523c8524a21481881010000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88acffffffffcc21e36eedb509c660681c1e949dd294bd4c11692439221004c2235d565b74bb000000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88acffffffffea919487e04ed509d6cb9c7297c277b9be3a68f3836c7d86df378714a75949e8000000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88acffffffff01b08f0600000000001976a91418ec49b27624086a2b6f35f263d951d25dbe24b688ac0000000001000000 > tmp_c_utx.txt" >> $logfile
echo "./tcls_sign.sh -v -f tmp_c_utx.txt -w KyP5KEp6DCmF222YM5EB9yGeMFxdVK1QWgtGvWnLRnDmiCtQPcN4 -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0" >> $logfile
printf "0100000004b0772e6ef46c2d3c60418bb7d5c2c015d6b943e5fca07570eb82c26dc7c9d248010000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88acffffffff74fb6858c31a292d20c9744187032bddb7ddea02a3aa3ef523c8524a21481881010000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88acffffffffcc21e36eedb509c660681c1e949dd294bd4c11692439221004c2235d565b74bb000000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88acffffffffea919487e04ed509d6cb9c7297c277b9be3a68f3836c7d86df378714a75949e8000000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88acffffffff01b08f0600000000001976a91418ec49b27624086a2b6f35f263d951d25dbe24b688ac0000000001000000" > tmp_c_utx.txt
./tcls_sign.sh -v -f tmp_c_utx.txt -w KyP5KEp6DCmF222YM5EB9yGeMFxdVK1QWgtGvWnLRnDmiCtQPcN4 -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0 > tmp_cfile
head -n 69 tmp_cfile > tmp_tx_cfile
echo " " >> tmp_tx_cfile
echo "###############################################" >> tmp_tx_cfile
echo "### signatures and hashes change every time ###" >> tmp_tx_cfile
echo "### for better verification, we search and  ###" >> tmp_tx_cfile
echo "### replace some data of the sigs (0xXX...) ###" >> tmp_tx_cfile
echo "###############################################" >> tmp_tx_cfile
echo " " >> tmp_tx_cfile

./tcls_tx2txt.sh -vv -f tmp_stx.txt > tmp_svn
# get some data into the compare file, without signature (which is changing everytime)
echo "  ..." > tmp_tx_cfile
# cat tmp_svn | grep -A6 -B1 "decode SIG_script OPCODES" | sed 's/20/XX/g;s/21/XX/g;s/32/xx/g;s/33/xx/g;s/44/XX/g;s/45/XX/g;s/46/XX/g;s/47/XX/g;s/48/XX/g;s/49/XX/g;s/70/xx/g;s/71/xx/g;s/72/xx/g' >> tmp_tx_cfile
fgrep -A6 -B1 "decode SIG_script OPCODES" tmp_svn |sed '/^--$/d;s/20/XX/g;s/21/XX/g;s/32/xx/g;s/33/xx/g;s/44/XX/g;s/45/XX/g;s/46/XX/g;s/47/XX/g;s/48/XX/g;s/49/XX/g;s/70/xx/g;s/71/xx/g;s/72/xx/g' >> tmp_tx_cfile
echo "        <SIG R> and <SIG S>" >> tmp_tx_cfile
echo "        strict sig checks ..." >> tmp_tx_cfile
cat tmp_svn  | tail -n 32 >> tmp_tx_cfile
echo " " >> tmp_tx_cfile
# we verify the signature with the script tmp_vfy.sh, which is created by tcls_sign.sh 
# again, we take only the last line, to avoid ever changing signature data
echo "### tmp_vfy.sh:" >> tmp_tx_cfile
./tmp_vfy.sh | tail -n2 >> tmp_tx_cfile
echo " " >> tmp_tx_cfile
chksum_ref="b0494f107ec82adf0c92bda0a7dc94a54eddd445e9772cc33aae2f35618e7995"
chksum_prep

echo " " | tee -a $logfile
}


testcase4() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 4: create multisigs and check assembly          ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 4a: create multisig and check assembly via hash"     | tee -a $logfile
echo "https://bitcoin.stackexchange.com/questions/60468/signature-scheme-for-p2sh" >> $logfile
echo "The link in this message to https://pastebin.com/raw/21ucHYW7 shows:" >> $logfile
echo " " >> $logfile

echo "./tcls_create.sh -v -c 267c6d75851efa18afb7edeb2da00c09afc575231db84b3277fc7ea3e174ecbd 1 512102930a11e92103daefde0d30b552f57d303e94a128e763ca9e69ff2006446934442103e74d2113dec75d75cde09a5b46297b1067e4b8b35e63c4c32b8cdbadfdffda1e2103067fcc39ee36d2417684511d1055fdc7d35e54911cb9de9ae30c988b666f675c2102dfb1c2a1c3456c8cb76714706dba77b3f4e7fe5afffc2503b121323a48ebbdcf54ae 51150 24000 3Mxb2PtkzPBxF7cXzERJVyJ9TaDzeAeMyH ..." >> $logfile
echo "./tcls_sign.sh -vv -m -f tmp_c_utx.txt -w KyP5KEp6DCmF222YM5EB9yGeMFxdVK1QWgtGvWnLRnDmiCtQPcN4 -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0 | grep -A2 'single sha256 and double sha256'" >> $logfile

./tcls_create.sh -v -c 267c6d75851efa18afb7edeb2da00c09afc575231db84b3277fc7ea3e174ecbd 1 512102930a11e92103daefde0d30b552f57d303e94a128e763ca9e69ff2006446934442103e74d2113dec75d75cde09a5b46297b1067e4b8b35e63c4c32b8cdbadfdffda1e2103067fcc39ee36d2417684511d1055fdc7d35e54911cb9de9ae30c988b666f675c2102dfb1c2a1c3456c8cb76714706dba77b3f4e7fe5afffc2503b121323a48ebbdcf54ae 51150 24000 3Mxb2PtkzPBxF7cXzERJVyJ9TaDzeAeMyH  >> /dev/null 
echo "    ..." > tmp_tx_cfile
./tcls_sign.sh -vv -m -f tmp_c_utx.txt -w KyP5KEp6DCmF222YM5EB9yGeMFxdVK1QWgtGvWnLRnDmiCtQPcN4 -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0 | grep -A2 "double hash the raw unsigned TX" >> tmp_tx_cfile
chksum_ref="3dcd18005e39b534898ec4273497b3a23c3bf25113c02b934f4a64e6ccc1761c" 
chksum_prep
echo " dsha256 expected: 2bfbf441d056cd300de0a51c055da349beecfc6ae0d215590b662c5e1da81d79" >> $logfile
echo " " >> $logfile
echo " " >> $logfile

echo "=== TESTCASE 4b: same as 4a, but sign assembled structure" | tee -a $logfile
echo "expected result is:" >> $logfile
echo "0100000001bdec74e1a37efc77324bb81d2375c5af090ca02debedb7af18fa1e85756d7c2601000000<length><fill_Byte00><sig><OP_SIGHASHALL>4c8b512102930a11e92103daefde0d30b552f57d303e94a128e763ca9e69ff2006446934442103e74d2113dec75d75cde09a5b46297b1067e4b8b35e63c4c32b8cdbadfdffda1e2103067fcc39ee36d2417684511d1055fdc7d35e54911cb9de9ae30c988b666f675c2102dfb1c2a1c3456c8cb76714706dba77b3f4e7fe5afffc2503b121323a48ebbdcf54aeffffffff01c05d00000000000017a914de5462e6e84cdab5064220343b9331a3af6dbbf18700000000" >> $logfile
echo " " >> $logfile
./tcls_sign.sh -vv -m -f tmp_c_utx.txt -w KyP5KEp6DCmF222YM5EB9yGeMFxdVK1QWgtGvWnLRnDmiCtQPcN4 -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0 | tail -n10 | head -n9 >> $logfile

./tcls_tx2txt.sh -vv -f tmp_stx.txt > tmp_svn
# get some data into the compare file, without signature (which is changing everytime)
echo "  ..." > tmp_tx_cfile
cat tmp_svn | grep -A7 -B1 "decode SIG_script OPCODES" | sed 's/46/XX/g;s/47/XX/g;s/48/XX/g;s/49/XX/g;s/70/xx/g;s/71/xx/g;s/72/xx/g;s/73/xx/g;s/44/XX/g;s/45/XX/g;s/20/XX/g;s/21/XX/g;s/32/xx/g;s/33/xx/g' >> tmp_tx_cfile
echo "        <SIG R>" >> tmp_tx_cfile
cat tmp_svn | grep "this is SIG S" | sed 's/20/XX/g;s/21/XX/g;s/32/xx/g;s/33/xx/g' >> tmp_tx_cfile
echo "        <SIG S>" >> tmp_tx_cfile
echo "        strict sig checks ..." >> tmp_tx_cfile
cat tmp_svn  | tail -n 61 >> tmp_tx_cfile
echo " " >> tmp_tx_cfile
# cat tmp_tx_cfile >> $logfile

chksum_ref="7c335940392771a86057d126036b17b0c53c962e74182c56ff43c0590797b9fc" 
chksum_prep

echo " " | tee -a $logfile
}

testcase5() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 5: create multisig as per Gavin example         ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 5a: create redeem script"                            | tee -a $logfile
echo "=== https://gist.githubusercontent.com/gavinandresen/3966071/  "  >> $logfile
echo "===  raw/1f6cfa4208bc82ee5039876b4f065a705ce64df7/TwoOfThree.sh"  >> $logfile

echo " " >> $logfile
echo "./tcls_create.sh -m 2 3 0491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f86,04865c40293a680cb9c020e7b1e106d8c1916d3cef99aa431a56d253e69256dac09ef122b1a986818a7cb624532f062c1d1f8722084861c5c3291ccffef4ec6874,048d2455d2403e08708fc1f556002f1b6cd83f992d085097f9974ab08a28838f07896fbab08f39495e15fa6fad6edbfb1e754e35fa1c7844c41f322a1863d46213" >> $logfile
./tcls_create.sh -m 2 3 0491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f86,04865c40293a680cb9c020e7b1e106d8c1916d3cef99aa431a56d253e69256dac09ef122b1a986818a7cb624532f062c1d1f8722084861c5c3291ccffef4ec6874,048d2455d2403e08708fc1f556002f1b6cd83f992d085097f9974ab08a28838f07896fbab08f39495e15fa6fad6edbfb1e754e35fa1c7844c41f322a1863d46213 > tmp_tx_cfile
echo "  expected address: 3QJmV3qfvL9SuYo34YihAf3sRCW3qSinyC" >> $logfile
printf "  found address: " >> $logfile
grep -A1 "The P2SH address" tmp_tx_cfile | tail -n1 >> $logfile
echo " " >> $logfile
echo "  expected redeemScript: 52410491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f864104865c40293a680cb9c020e7b1e106d8c1916d3cef99aa431a56d253e69256dac09ef122b1a986818a7cb624532f062c1d1f8722084861c5c3291ccffef4ec687441048d2455d2403e08708fc1f556002f1b6cd83f992d085097f9974ab08a28838f07896fbab08f39495e15fa6fad6edbfb1e754e35fa1c7844c41f322a1863d4621353ae" >> $logfile
printf "  found redeemScript:    " >> $logfile
grep -A1 "The redeemscript" tmp_tx_cfile  | tail -n1 >> $logfile
echo " " >> $logfile
chksum_ref="912c6862f98dcdfa895432492671ddccb54aeaaefb10a3e10108c39c953df1d1" 
chksum_prep
echo " " >> $logfile

echo "=== TESTCASE 5b: check dsha256 of the fund-the-multisig tx" | tee -a $logfile
echo "  expected dsha256: 3c9018e8d5615c306d72397f8f5eef44308c98fb576a88e030c25456b4f3a7ac" >> $logfile
tmpvar=010000000189632848f99722915727c5c75da8db2dbf194342a0429828f66ff88fab2af7d6000000008b483045022100abbc8a73fe2054480bda3f3281da2d0c51e2841391abd4c09f4f908a2034c18d02205bc9e4d68eafb918f3e9662338647a4419c0de1a650ab8983f1d216e2a31d8e30141046f55d7adeff6011c7eac294fe540c57830be80e9355c83869c9260a4b8bf4767a66bacbd70b804dc63d5beeb14180292ad7f3b083372b1d02d7a37dd97ff5c9effffffff0140420f000000000017a914f815b036d9bbbce5e9f2a00abd1bf3dc91e955108700000000 
printf $(echo $tmpvar | sed 's/[[:xdigit:]]\{2\}/\\x&/g' ) >tmp_file
openssl dgst -binary -sha256 <tmp_file            >tmp_tcsign5b_sha256  
openssl dgst -binary -sha256 <tmp_tcsign5b_sha256 >tmp_tcsign5b_dsha256 
tmpvar=$( od -An -t x1 tmp_tcsign5b_dsha256 | tr -d [:blank:] | tr -d "\n" )
printf "     found dsha256: " >> $logfile
echo $tmpvar | awk '{ for(i=length;i!=0;i=i-2)s=s substr($0,i-1,2);}END{print s}' > tmp_tx_cfile
chksum_ref="3dfe23ff5cbc898f2890988206c59dca0f83a7edbb4a3cc7c3d06c3d9d300ba1" 
chksum_prep
echo " " >> $logfile

echo "=== TESTCASE 5c: Create the spend-from-multisig tx, sign with first sig" | tee -a $logfile
echo "./tcls_create.sh -v -c 3c9018e8d5615c306d72397f8f5eef44308c98fb576a88e030c25456b4f3a7ac 0 52410491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f864104865c40293a680cb9c020e7b1e106d8c1916d3cef99aa431a56d253e69256dac09ef122b1a986818a7cb624532f062c1d1f8722084861c5c3291ccffef4ec687441048d2455d2403e08708fc1f556002f1b6cd83f992d085097f9974ab08a28838f07896fbab08f39495e15fa6fad6edbfb1e754e35fa1c7844c41f322a1863d4621353ae 1134000 1000000 1GtpSrGhRGY5kkrNz4RykoqRQoJuG2L6DS" >> $logfile
echo "./tcls_sign.sh -vv -m -f tmp_c_utx.txt -w 5JaTXbAUmfPYZFRwrYaALK48fN6sFJp4rHqq2QSXs8ucfpE4yQU -p 0491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f86" >> $logfile
./tcls_create.sh -v -c 3c9018e8d5615c306d72397f8f5eef44308c98fb576a88e030c25456b4f3a7ac 0 52410491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f864104865c40293a680cb9c020e7b1e106d8c1916d3cef99aa431a56d253e69256dac09ef122b1a986818a7cb624532f062c1d1f8722084861c5c3291ccffef4ec687441048d2455d2403e08708fc1f556002f1b6cd83f992d085097f9974ab08a28838f07896fbab08f39495e15fa6fad6edbfb1e754e35fa1c7844c41f322a1863d4621353ae 1134000 1000000 1GtpSrGhRGY5kkrNz4RykoqRQoJuG2L6DS >> /dev/null
./tcls_sign.sh -vv -m -f tmp_c_utx.txt -w 5JaTXbAUmfPYZFRwrYaALK48fN6sFJp4rHqq2QSXs8ucfpE4yQU -p 0491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f86 >> /dev/null

./tcls_tx2txt.sh -vv -f tmp_stx.txt -u > tmp_svn_5c
# get some data into the compare file, without signature (which is changing everytime)
echo "  ..." > tmp_tx_cfile
cat tmp_svn_5c | grep -A7 -B1 "decode SIG_script OPCODES" | sed 's/44/XX/g;s/45/XX/g;s/46/XX/g;s/47/XX/g;s/48/XX/g;s/49/XX/g;s/70/xx/g;s/71/xx/g;s/72/xx/g;s/73/xx/g;s/20/XX/g;s/21/XX/g;s/32/xx/g;s/33/xx/g' >> tmp_tx_cfile
echo "        <SIG R>" >> tmp_tx_cfile
cat tmp_svn_5c | grep "this is SIG S" | sed 's/20/XX/g;s/21/XX/g;s/32/xx/g;s/33/xx/g' >> tmp_tx_cfile
echo "        <SIG S>" >> tmp_tx_cfile
echo "        strict sig checks ..." >> tmp_tx_cfile
cat tmp_svn_5c  | tail -n 66 >> tmp_tx_cfile
echo " " >> tmp_tx_cfile
chksum_ref="e170c8c03f5b807f5b9255e77a7da0bd178e6bdfe7da1f9e6df67bcd7a3e730b"
chksum_prep

echo "=== TESTCASE 5d: ... and sign again with second sig" | tee -a $logfile
# we take the last two lines of the tcls_sign.sh script into the file, which 
# will be checksummed. This way we assure that the script went through successfully.
echo "./tcls_sign.sh -vv -m -f tmp_stx.txt -w 5JFjmGo5Fww9p8gvx48qBYDJNAzR9pmH5S389axMtDyPT8ddqmw -p 048d2455d2403e08708fc1f556002f1b6cd83f992d085097f9974ab08a28838f07896fbab08f39495e15fa6fad6edbfb1e754e35fa1c7844c41f322a1863d46213 | tail -n2 > tmp_tx_cfile" >> $logfile
./tcls_sign.sh -vv -m -f tmp_stx.txt -w 5JFjmGo5Fww9p8gvx48qBYDJNAzR9pmH5S389axMtDyPT8ddqmw -p 048d2455d2403e08708fc1f556002f1b6cd83f992d085097f9974ab08a28838f07896fbab08f39495e15fa6fad6edbfb1e754e35fa1c7844c41f322a1863d46213 | tail -n2 > tmp_tx_cfile
# we verify the output with tcls_tx2txt.sh, and search and replace numbers, 
# where signature's data is included (which is changing everytime).
# the first sig was already checked in testcase 5c, so only need to check 2nd sig
./tcls_tx2txt.sh -vv -f tmp_stx.txt > tmp_svn_5d
echo "  ..." >> tmp_tx_cfile
cat tmp_svn_5d | grep -A7 -B1 "decode SIG_script OPCODES" | sed 's/44/XX/g;s/45/XX/g;s/46/XX/g;s/47/XX/g;s/48/XX/g;s/49/XX/g;s/70/xx/g;s/71/xx/g;s/72/xx/g;s/73/xx/g;s/20/XX/g;s/21/XX/g;s/32/xx/g;s/33/xx/g' >> tmp_tx_cfile
echo "        <SIG R>" >> tmp_tx_cfile
cat tmp_svn_5d | grep "this is SIG S" | sed 's/20/XX/g;s/21/XX/g;s/32/xx/g;s/33/xx/g' >> tmp_tx_cfile
echo "        <SIG S>" >> tmp_tx_cfile
echo "        strict sig checks ..." >> tmp_tx_cfile
cat tmp_svn_5d  | tail -n 66 >> tmp_tx_cfile
echo " " >> tmp_tx_cfile
# we verify the signature with the script tmp_vfy.sh, which is created by tcls_sign.sh 
# again, we take only the last line, to avoid ever changing signature data
echo "### tmp_vfy.sh:" >> tmp_tx_cfile
./tmp_vfy.sh | tail -n2 >> tmp_tx_cfile
echo " " >> tmp_tx_cfile
chksum_ref="6d296943903c2bf3125b86ac46a10a17a0684e9f12d484a9124bbbc58541791b"
chksum_prep

echo " " | tee -a $logfile
}


testcase6() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 6: 3 TX_IN with 2-of-2 Multisig and 1 TX_OUT    ===" | tee -a $logfile
echo "===             this is a test of functionality only.        ===" >> $logfile
echo "===             the priv keys don't exist to fully verify    ===" >> $logfile
echo "===             using my own priv keys from somewhere else   ===" >> $logfile
echo "===             At the end the structure must be the same,   ===" >> $logfile
echo "===             when comparing with tcls_tx2txt.sh           ===" >> $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 6a: assemble the raw tx with tcls_create.sh"         | tee -a $logfile
echo "=== https://bitcoin.stackexchange.com/questions/35799/         "  >> $logfile
echo "===  how-to-find-z-value-of-multisig-transaction/35802#35802   "  >> $logfile
# the original transaction is this: 
# 0100000003fdb1fe0b4506f8d412f8498a0d747701bc5ed8c009e779ee670c82361c1d1dd501000000da00473044022025332b6dabf11e493fbc62c93e7302c48666512e1cf88157c26176f4af6d064702201ee7ec25d0917244e514c402e8751f112dfd1bef2b22ec5e496fbafabb52bf0101483045022100fa1f17bf59bee0ac33ae5f682711c5471c73a4aeb898aee218478289a4c7aa6e02207b40dfeae3fa4a50dc147bd42be40370d76a35d72c0b27b27c4ba2439a565fb90147522102cebf6ab580948d146b7cc771d8e646974349d3d7b11f3e03287d0997a477d3b921037ba651485b7a2cb222191eb64a55926e62bbabfe9b5ed2a9488aad547b20428252aeffffffffa614d26f1878078a00a3c296085576cd7e6361234ea82c865681041fcfdacea801000000d900473044021f0efe211b1ad84bbfea1be567aaab6b6767ef38c7ef464faec0e4dd233ced31022100cecae44897214d5c72caa7a2f2209f6930e6c2cd774fc7964bbde3dcda8713280147304402200b610566cfb0795d42eb0fa81b5ed0049720da74ffa672fe41a3575a8d01554f02201ac6c998e7a0fd1b5436895b9e3c036f282877205fe1cd6eda36d142b31fe9890147522102cebf6ab580948d146b7cc771d8e646974349d3d7b11f3e03287d0997a477d3b921037ba651485b7a2cb222191eb64a55926e62bbabfe9b5ed2a9488aad547b20428252aeffffffffd064d2f9cf9e5196a9d81dd87718c9cfbec97f3ccac7164946d956421597c7f101000000da0048304502203c67f2a1c8d7c460b80efb40c2ce4e6735166c0ad1ecf5b5ed04cb4b86f2883e0221009906df06f2ab889c5460475a2b41d8c3d12a3ea781f540af7c18a4ef30925b7801473044022052477b7949b3909bcce38913dc7f91b691948cbd524e9f083e59586090d62e4a0220046b7ef6e2c634a9fb814dd0f2df8df3257db1caef6caf3c09dc88125911805b0147522102cebf6ab580948d146b7cc771d8e646974349d3d7b11f3e03287d0997a477d3b921037ba651485b7a2cb222191eb64a55926e62bbabfe9b5ed2a9488aad547b20428252aeffffffff01e0687046000000001976a9142c76e6fdd1a81c902afa62e78ec71435708d9d9d88ac00000000
# we start from scratch, and create the raw tx:
echo "echo \"D51D1D1C36820C67EE79E709C0D85EBC0177740D8A49F812D4F806450BFEB1FD 1 522102CEBF6AB580948D146B7CC771D8E646974349D3D7B11F3E03287D0997A477D3B921037BA651485B7A2CB222191EB64A55926E62BBABFE9B5ED2A9488AAD547B20428252AE 1180000000\" > tmp_create" >> $logfile
echo "echo \"A8CEDACF1F048156862CA84E2361637ECD76550896C2A3008A0778186FD214A6 1 522102CEBF6AB580948D146B7CC771D8E646974349D3D7B11F3E03287D0997A477D3B921037BA651485B7A2CB222191EB64A55926E62BBABFE9B5ED2A9488AAD547B20428252AE 1770000\" > tmp_create" >> $logfile
echo "echo \"F1C797154256D9464916C7CA3C7FC9BECFC91877D81DD8A996519ECFF9D264D0 1 522102CEBF6AB580948D146B7CC771D8E646974349D3D7B11F3E03287D0997A477D3B921037BA651485B7A2CB222191EB64A55926E62BBABFE9B5ED2A9488AAD547B20428252AE 100000\" > tmp_create" >> $logfile
echo "./tcls_create.sh -f tmp_create 1181772000 1547AvEpxff6A63yU9UGXwC8GMDKQVeVZP" >> $logfile
echo "D51D1D1C36820C67EE79E709C0D85EBC0177740D8A49F812D4F806450BFEB1FD 1 522102CEBF6AB580948D146B7CC771D8E646974349D3D7B11F3E03287D0997A477D3B921037BA651485B7A2CB222191EB64A55926E62BBABFE9B5ED2A9488AAD547B20428252AE 1180000000" > tmp_create
echo "A8CEDACF1F048156862CA84E2361637ECD76550896C2A3008A0778186FD214A6 1 522102CEBF6AB580948D146B7CC771D8E646974349D3D7B11F3E03287D0997A477D3B921037BA651485B7A2CB222191EB64A55926E62BBABFE9B5ED2A9488AAD547B20428252AE 1770000" >> tmp_create
echo "F1C797154256D9464916C7CA3C7FC9BECFC91877D81DD8A996519ECFF9D264D0 1 522102CEBF6AB580948D146B7CC771D8E646974349D3D7B11F3E03287D0997A477D3B921037BA651485B7A2CB222191EB64A55926E62BBABFE9B5ED2A9488AAD547B20428252AE 100000" >> tmp_create
./tcls_create.sh -f tmp_create 1181772000 1547AvEpxff6A63yU9UGXwC8GMDKQVeVZP >> $logfile
./tcls_sign.sh -vv -m -f tmp_c_utx.txt -w KyP5KEp6DCmF222YM5EB9yGeMFxdVK1QWgtGvWnLRnDmiCtQPcN4 -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0 | grep -A2 "double hash the raw unsigned TX" | sed '/--$/d' > tmp_tx_cfile
chksum_ref="770c8781e1770d1d86fb69609bbf74f101092530837d4ef70debff36873f08f6" 
chksum_prep
echo "expected double sha256 values: " >> $logfile
echo "  14. TX_IN Sig[1]:9c4b551f37f4b383af9216045d80b2fcd4ed57bddca8df388ec29601cbd2a4f1" >> $logfile
echo "  14. TX_IN Sig[2]:ed00e8901618c5a9bc4fb9f18734bb11a43b6a2f2798ff631b5f960e95f7e74e" >> $logfile
echo "  14. TX_IN Sig[3]:cb58f6ea759d32c3e1683b8ba070c3c1a3fc5d773cda532e075d3540742685d8" >> $logfile
echo " " >> $logfile
echo " " >> $logfile

echo "=== TESTCASE 6b: sign the tx with signature1 "   | tee -a $logfile
./tcls_sign.sh -vv -m -f tmp_c_utx.txt -w KyP5KEp6DCmF222YM5EB9yGeMFxdVK1QWgtGvWnLRnDmiCtQPcN4 -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0 > tmp_tx_cfile
# we verify the output with tcls_tx2txt.sh, and search and replace numbers, 
# where signature's data is included (which is changing everytime).
./tcls_tx2txt.sh -v -f tmp_stx.txt > tmp_svn
echo "  ..." > tmp_tx_cfile
tail -n50 tmp_svn | sed 's/^[ ][ ][0][0][4].*$/  *** replaced with "sed". This would be a signature ***/;s/=9[234]/=[92][93][94]/;s/=14[678]/=[146][147][148]/' >> tmp_tx_cfile
echo " " >> tmp_tx_cfile
# we verify the signature with the script tmp_vfy.sh, which is created by tcls_sign.sh
# again, we take only the last line, to avoid ever changing signature data
echo "### tmp_vfy.sh:" >> tmp_tx_cfile
./tmp_vfy.sh | tail -n2 >> tmp_tx_cfile
echo " " >> tmp_tx_cfile
chksum_ref="31e579d1b3395b235eb74e69d1433ed59cf105d7b51d4fe5dc3684813275e999" 
chksum_prep

echo "=== TESTCASE 6c: sign the tx with signature2 "   | tee -a $logfile
./tcls_sign.sh -vv -m -f tmp_stx.txt -x 18E14A7B6A307F426A94F8114701E7C8E774E7F9A47E2C2035DB29A206321725 -p 0250863AD64A87AE8A2FE83C1AF1A8403CB53F53E486D8511DAD8A04887E5B2352 > tmp_tx_cfile 2>&1
cp tmp_tx_cfile tmp_tx_svn
# we verify the output with tcls_tx2txt.sh, and search and replace numbers, 
# where signature's data is included (which is changing everytime).
./tcls_tx2txt.sh -v -f tmp_stx.txt > tmp_svn
echo "  ..." > tmp_tx_cfile
tail -n50 tmp_svn | sed 's/^[ ][ ][0][0][4].*$/  *** Sigs always change, check for both sigs with .\/tcls_tx2txt.sh -vv -f tmp_stx.txt/;s/=D[ABCDE]/=[DA][DB][DC][DD][DE]/g;s/=21[89]/=[218][219][220][221][222]/g;s/=22[012]/=[218][219][220][221][222]/g' >> tmp_tx_cfile
echo " " >> tmp_tx_cfile
# we verify the three signatures with the script tmp_vfy.sh, which is created by 
# tcls_sign.sha again, we grep specific lines, to avoid ever changing signature data
echo "### tmp_vfy.sh:" >> tmp_tx_cfile
./tmp_vfy.sh | grep -e "Signature Verified Successfully" -e "unsigned raw tx" >> tmp_tx_cfile
echo " " >> tmp_tx_cfile
chksum_ref="c17131d6b7cd2eff8928a2e20b130d9b90544051dfc58d43cb874eb841860178" 
chksum_prep

echo "=== TESTCASE 6d: sign the already completed sig"  | tee -a $logfile
echo "this should give an error - tbd"
echo " " | tee -a $logfile
}



all_testcases() {
  testcase1 
  testcase2 
  testcase3 
  testcase4 
  testcase5 
  testcase6 
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
     proc_help
     echo " "
     echo "unknown parameter(s), exiting gracefully ..."
     exit 0
     ;;
  esac
done

# clean up?
if [ $no_cleanup -eq 0 ] ; then 
  cleanup
fi

