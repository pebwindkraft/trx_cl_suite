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

echo "=== TESTCASE 1a: $chksum_cmd tcls_sign.sh" | tee -a $logfile
cp tcls_sign.sh tmp_tx_cfile
chksum_ref="1ef2f84900b06a1a19e537636cadbba95ac2f91e3581a3ec62043603fc117cdd" 
chksum_prep

echo "=== TESTCASE 1b: $chksum_cmd tcls_key2pem.sh" | tee -a $logfile
cp tcls_key2pem.sh tmp_tx_cfile
chksum_ref="0b5fb56e663368f7e011e49b8caf3560aff87c3176c1608b482f398c1deaaf1f" 
chksum_prep

echo "=== TESTCASE 1c: $chksum_cmd tcls_strict_sig_verify.sh" | tee -a $logfile
cp tcls_strict_sig_verify.sh tmp_tx_cfile
chksum_ref="18423e6270685705eba8fdbb853601a43510a351618e326a7d8ee50b986203cd" 
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
./tcls_sign.sh -f tmp_utx.txt -w XXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXXQPcN4 -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0 > tmp_tx_cfile
chksum_ref="597b2e5e247ed2da1d3b94b1d2026dc9c760617127737d22f4403730a82890b5" 
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
echo "./tcls_sign.sh -v -f tmp_c_utx.txt -w KyP5KEp6DCmF222YM5EB9yGeMFxdVK1QWgtGvWnLRnDmiCtQPcN4 -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0" >> $logfile

printf "010000000174fb6858c31a292d20c9744187032bddb7ddea02a3aa3ef523c8524a21481881010000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88acffffffff01b08f0600000000001976a91418ec49b27624086a2b6f35f263d951d25dbe24b688ac0000000001000000" > tmp_c_utx.txt

./tcls_sign.sh -v -f tmp_c_utx.txt -w KyP5KEp6DCmF222YM5EB9yGeMFxdVK1QWgtGvWnLRnDmiCtQPcN4 -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0 > tmp_cfile
head -n 38 tmp_cfile > tmp_tx_cfile
echo " " >> tmp_tx_cfile
echo "###############################################" >> tmp_tx_cfile
echo "### signatures and hashes change every time ###" >> tmp_tx_cfile
echo "### for better verification, we add output  ###" >> tmp_tx_cfile
echo "### from ./tcls_tx2txt.sh -vv -r ...        ###" >> tmp_tx_cfile
echo "### but this cannot be part of the checksum ###" >> tmp_tx_cfile
echo "### --> it is itself changing everytime ... ###" >> tmp_tx_cfile
echo "###############################################" >> tmp_tx_cfile
echo " " >> tmp_tx_cfile
chksum_ref="62b9241ce41dc9c59ead71dfc76abb89720481bafd6dab02ca3fbc1cc69822a8" 
chksum_prep
./tcls_tx2txt.sh -vv -f tmp_stx.txt > tmp_tcls_tx2txt.out
#cat tmp_tcls_tx2txt.out >> $tmp_tx_cfile
cat tmp_tcls_tx2txt.out >> $logfile

echo "=== TESTCASE 3b: use 4 TX-In and 1 TX-Out " | tee -a $logfile
echo "===  4 inputs from: 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM ===" >> $logfile
echo "===  1 output to:   13GnHB51piDBf1avocPL7tSKLugK4F7U2B ===" >> $logfile
echo "./tcls_sign.sh -v -f tmp_c_utx.txt -w KyP5KEp6DCmF222YM5EB9yGeMFxdVK1QWgtGvWnLRnDmiCtQPcN4 -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0" >> $logfile
printf "0100000004b0772e6ef46c2d3c60418bb7d5c2c015d6b943e5fca07570eb82c26dc7c9d248010000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88acffffffff74fb6858c31a292d20c9744187032bddb7ddea02a3aa3ef523c8524a21481881010000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88acffffffffcc21e36eedb509c660681c1e949dd294bd4c11692439221004c2235d565b74bb000000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88acffffffffea919487e04ed509d6cb9c7297c277b9be3a68f3836c7d86df378714a75949e8000000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88acffffffff01b08f0600000000001976a91418ec49b27624086a2b6f35f263d951d25dbe24b688ac0000000001000000" > tmp_c_utx.txt
./tcls_sign.sh -v -f tmp_c_utx.txt -w KyP5KEp6DCmF222YM5EB9yGeMFxdVK1QWgtGvWnLRnDmiCtQPcN4 -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0 > tmp_cfile
head -n 69 tmp_cfile > tmp_tx_cfile
echo " " >> tmp_tx_cfile
echo "###############################################" >> tmp_tx_cfile
echo "### signatures and hashes change every time ###" >> tmp_tx_cfile
echo "### for better verification, we add output  ###" >> tmp_tx_cfile
echo "### from ./tcls_tx2txt.sh -vv -r ...        ###" >> tmp_tx_cfile
echo "### but this cannot be part of the checksum ###" >> tmp_tx_cfile
echo "### --> it is itself changing everytime ... ###" >> tmp_tx_cfile
echo "###############################################" >> tmp_tx_cfile
echo " " >> tmp_tx_cfile
chksum_ref="310688cf83edff3e9e6f3e689f80341e6f0cdcdd888b58e4eb5557df479c4c3a" 
chksum_prep
./tcls_tx2txt.sh -vv -f tmp_stx.txt > tmp_tcls_tx2txt.out
#cat tmp_tcls_tx2txt.out >> $tmp_tx_cfile
cat tmp_tcls_tx2txt.out >> $logfile

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
chksum_ref="93eb5edd55334c515a76adb824267328457489e55a4ffa5623005ccc8046f79b" 
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
# get some data into the compare file, without signature (which is changing everytime)
echo "  ..." > tmp_tx_cfile
cat tmp_svn | grep -A7 -B1 "decode SIG_script OPCODES" | sed 's/47/XX/g;s/48/XX/g;s/49/XX/g;s/71/xx/g;s/72/xx/g;s/73/xx/g;s/44/XX/g;s/45/XX/g;s/20/XX/g;s/21/XX/g;s/32/xx/g;s/33/xx/g' >> tmp_tx_cfile
echo "        <SIG R>" >> tmp_tx_cfile
cat tmp_svn | grep "this is SIG S" | sed 's/20/XX/g;s/21/XX/g;s/32/xx/g;s/33/xx/g' >> tmp_tx_cfile
echo "        <SIG S>" >> tmp_tx_cfile
echo "        strict sig checks ..." >> tmp_tx_cfile
cat tmp_svn  | tail -n 65 >> tmp_tx_cfile
echo " " >> tmp_tx_cfile
# cat tmp_tx_cfile >> $logfile

chksum_ref="adc4aae1fd92d3547a5184e4f6274b380af79b526a8e25de97941954c17889ce" 
chksum_prep

echo " " | tee -a $logfile
}

all_testcases() {
  testcase1 
  testcase2 
  testcase3 
  testcase4 
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
# for i in tmp*; do
#   if [ -f "$i" ]; then rm $i ; fi
# done
# for i in *hex; do
#   if [ -f "$i" ]; then rm $i ; fi
# done
for i in priv*; do
  if [ -f "$i" ]; then rm $i ; fi
done
for i in pub*; do
  if [ -f "$i" ]; then rm $i ; fi
done


