#!/bin/sh
# some testcases for the shell script "trx_2txt.sh" 
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

typeset -i LOG=0
logfile=$0.log

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
 
to_logfile() {
  # echo $chksum_ref >> $logfile
  cat tmpfile >> $logfile
  echo " " >> $logfile
}

chksum_prep() {
  result=$( $chksum_cmd tmpfile | cut -d " " -f 2 )
  # echo $result | cut -d " " -f 2 >> $logfile
  chksum_verify "$result" "$chksum_ref" 
  if [ $LOG -eq 1 ] ; then to_logfile ; fi
}


testcase1() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 1: checksums of all necessary files             ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 1a: $chksum_cmd trx_2txt.sh" | tee -a $logfile
echo "================================================================" | tee -a $logfile
chksum_ref="0222c3f386876643f74d322650efce7e9bf8f244c8a6ab03559e834aecf0a22c"
cp trx_2txt.sh tmpfile
chksum_prep
 
echo "=== TESTCASE 1b: $chksum_cmd trx_in_sig_script.sh" | tee -a $logfile
echo "================================================================" | tee -a $logfile
chksum_ref="fb074b676d5c643c80479ee8a857db61caf491e374048370154c774db44647c4" 
cp trx_in_sig_script.sh tmpfile
chksum_prep

echo "=== TESTCASE 1c: $chksum_cmd trx_out_pk_script.sh" | tee -a $logfile
echo "================================================================" | tee -a $logfile
chksum_ref="acd1c748b67dcccd0e22f0c5ec4a010a4852ff5b1e17a772a2916284051e8ecf" 
cp trx_out_pk_script.sh tmpfile
chksum_prep

echo "=== TESTCASE 1d: $chksum_cmd trx_base58check_enc.sh" | tee -a $logfile
echo "================================================================" | tee -a $logfile
chksum_ref="81c105c548b02b9f808e887c3af09d4106b30450b0d7fc31292e76f1b1b722e1" 
cp trx_base58check_enc.sh tmpfile
chksum_prep
echo " " | tee -a $logfile
}

testcase2() {
# do a testcase with the included example transaction
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 2: parameters testing                           ===" | tee -a $logfile
echo "=== do several testcases with parameters set incorrectly,    ===" | tee -a $logfile
echo "=== and at the end 3 correct settings. This just serves      ===" | tee -a $logfile
echo "=== to verify, that code is executing properly               ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile

echo "=== TESTCASE 2a: wrong parameter: ./trx_2txt.sh xyz" | tee -a $logfile
echo "================================================================" | tee -a $logfile
./trx_2txt.sh xyz > tmpfile
chksum_ref="8f9d3b18dff5afd430a8dc43c0da7944850f0b340b5fbb89aec5089685dd2f44" 
chksum_prep

echo "=== TESTCASE 2b: wrong parameter: ./trx_2txt.sh -r" | tee -a $logfile
echo "================================================================" | tee -a $logfile
./trx_2txt.sh -r > tmpfile
chksum_ref="1721533bfee0e85be0466297b6fed058a627f32ced833b4f399295ccb72fe3c3" 
chksum_prep

echo "=== TESTCASE 2c: wrong parameter: ./trx_2txt.sh -t" | tee -a $logfile
echo "================================================================" | tee -a $logfile
./trx_2txt.sh -t > tmpfile
chksum_ref="e74a2df6df2e49962dcc4783d9baf4cae81fb150a175dc4d3b9d7827e104336c" 
chksum_prep

echo "=== TESTCASE 2d: wrong parameter: ./trx_2txt.sh -r abc -t def" | tee -a $logfile
echo "================================================================" | tee -a $logfile
./trx_2txt.sh -r abc -t def > tmpfile
chksum_ref="47a0407ae190461ba05c725bb4cce836dfeb21b4029394ea27fd6560b42d8be3" 
chksum_prep

echo "=== TESTCASE 2e: wrong parameter: ./trx_2txt.sh -t abc" | tee -a $logfile
echo "================================================================" | tee -a $logfile
./trx_2txt.sh -t abc > tmpfile
chksum_ref="1aeba053570d87694751cfadea5c4728d723afc635ffc3241210634de2ac8952"
chksum_prep

echo "=== TESTCASE 2f: wrong parameter: ./trx_2txt.sh -v abc" | tee -a $logfile
echo "================================================================" | tee -a $logfile
./trx_2txt.sh -v abc > tmpfile
chksum_ref="edbda2f2fdc8479a4c119b2c02031bed01f9e5b85ee2a53e9e2364d73e6a4503" 
chksum_prep
 
echo "=== TESTCASE 2g: show help: ./trx_2txt.sh -h" | tee -a $logfile
echo "================================================================" | tee -a $logfile
./trx_2txt.sh -h > tmpfile
chksum_ref="1b062ba10cc27e9910f7b4e13111007a8d8274532e710bebd01e0ab192ea648b" 
chksum_prep

echo "=== TESTCASE 2h: show default: ./trx_2txt.sh" | tee -a $logfile
echo "================================================================" | tee -a $logfile
./trx_2txt.sh > tmpfile
chksum_ref="1bbc6403fb61c7ceccb845eed5bae8ea75e68ec7c73e343b7cda1daf647c08cf" 
chksum_prep

echo "=== TESTCASE 2i: show default: ./trx_2txt.sh -v" | tee -a $logfile
echo "================================================================" | tee -a $logfile
./trx_2txt.sh -v > tmpfile
chksum_ref="5351ae139948737d28d997230ce808f7c2819719c8361ecb59f4946222b4542f" 
chksum_prep

echo "=== TESTCASE 2j: show default: ./trx_2txt.sh -vv" | tee -a $logfile
echo "================================================================" | tee -a $logfile
./trx_2txt.sh -vv > tmpfile
chksum_ref="c5de9b468e9ea04a3f24159fa232c963d4b073418c41198d9eb1822483a3a125" 
chksum_prep
echo " " | tee -a $logfile
}

testcase3() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 3: a fairly simple trx, 1 input, 1 output       ===" | tee -a $logfile
echo "===  we check functionality to load data via -t parameter    ===" | tee -a $logfile
echo "===  from https://blockchain.info ...                        ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "https://blockchain.info/de/rawtx/30375f40adcf361f5b2a5074b615ca75e5696909e8bc2f8e553c69631826fcf6" | tee -a $logfile

echo "=== TESTCASE 3a: ./trx_2txt.sh -t 30375f40ad... " | tee -a $logfile
echo "================================================================" | tee -a $logfile
./trx_2txt.sh -t 30375f40adcf361f5b2a5074b615ca75e5696909e8bc2f8e553c69631826fcf6 > tmpfile
chksum_ref="59b6b4771fd931bc5668d55984e2cab47d33fa35cfd0b14e04d342fa99ecd3bf" 
chksum_prep

echo "=== TESTCASE 3b: ./trx_2txt.sh -v -t 30375f40ad... " | tee -a $logfile
echo "================================================================" | tee -a $logfile
./trx_2txt.sh -v -t 30375f40adcf361f5b2a5074b615ca75e5696909e8bc2f8e553c69631826fcf6 > tmpfile
chksum_ref="c4f5af62662148d9b12fe39582143299bdc851e17ddfebbf82c83df3d2ce4d08" 
chksum_prep

echo "=== TESTCASE 3c: ./trx_2txt.sh -v -t 30375f40ad... " | tee -a $logfile
echo "================================================================" | tee -a $logfile
./trx_2txt.sh -vv -t 30375f40adcf361f5b2a5074b615ca75e5696909e8bc2f8e553c69631826fcf6 > tmpfile
chksum_ref="ee0986eeb03cd1423f2b901acd854cc1a3eae2e3951f577d0828e569ff1698d1" 
chksum_prep
echo " " | tee -a $logfile
}


testcase4() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 4: a fairly simple trx, 1 input, 2 outputs      ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "https://blockchain.info/de/rawtx/91c91f31b7586b807d0ddc7a1670d10cc34bdef326affc945d4987704c7eed62" | tee -a $logfile

echo "=== TESTCASE 4a: ./trx_2txt.sh -r 010000000117f83..." | tee -a $logfile
echo "================================================================" | tee -a $logfile
./trx_2txt.sh -r 010000000117f83daeec34cca28b90390b691d278f658b85b20fae29983acda10273cc7d32010000006b483045022100b95be9ab9148d85d47d51d069923272ad5131505b40b8e27211475305c546c6e02202ae8f2386e0d7afa6ab0acfafa78b0e23e669972d6e656b345b69c6d268aecbd0121020b2b582ca9333957cf8457a4a1b46e5337471cc98582fdf37c58a201dba50dd2feffffff0210201600000000001976a91407ddfbe06b04f3867cae654448174ea2f9a173ea88acda924700000000001976a9143940dcd0bfb7ad9bff322405954949c450742cd588accd3d0600 > tmpfile
chksum_ref="aa81629808f058edbff6a79651ce365b5184cfc9c39dbed8617c9e3a7218e6b5"
chksum_prep

echo "=== TESTCASE 4b: ./trx_2txt.sh -v -r 010000000117f83..." | tee -a $logfile
echo "================================================================" | tee -a $logfile
./trx_2txt.sh -v -r 010000000117f83daeec34cca28b90390b691d278f658b85b20fae29983acda10273cc7d32010000006b483045022100b95be9ab9148d85d47d51d069923272ad5131505b40b8e27211475305c546c6e02202ae8f2386e0d7afa6ab0acfafa78b0e23e669972d6e656b345b69c6d268aecbd0121020b2b582ca9333957cf8457a4a1b46e5337471cc98582fdf37c58a201dba50dd2feffffff0210201600000000001976a91407ddfbe06b04f3867cae654448174ea2f9a173ea88acda924700000000001976a9143940dcd0bfb7ad9bff322405954949c450742cd588accd3d0600 > tmpfile
chksum_ref="18836084afa8b327ec17c09671e660ce2702884930a08fc9ec73dc9bca19b3d5"
chksum_prep

echo "=== TESTCASE 4c:./trx_2txt.sh -vv -r 010000000117f83..." | tee -a $logfile
echo "================================================================" | tee -a $logfile
./trx_2txt.sh -vv -r 010000000117f83daeec34cca28b90390b691d278f658b85b20fae29983acda10273cc7d32010000006b483045022100b95be9ab9148d85d47d51d069923272ad5131505b40b8e27211475305c546c6e02202ae8f2386e0d7afa6ab0acfafa78b0e23e669972d6e656b345b69c6d268aecbd0121020b2b582ca9333957cf8457a4a1b46e5337471cc98582fdf37c58a201dba50dd2feffffff0210201600000000001976a91407ddfbe06b04f3867cae654448174ea2f9a173ea88acda924700000000001976a9143940dcd0bfb7ad9bff322405954949c450742cd588accd3d0600 > tmpfile
chksum_ref="b8763f58af011300c693b6b16f98ec1e36cfd7179e4460ebc3bc26ab06fdb6e4"
chksum_prep
echo " " | tee -a $logfile
}

testcase5() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 5: a fairly simple trx, 3 inputs, 1 P2SH output ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "https://blockchain.info/de/rawtx/4f292aeff2ad2da37b5d5719bf34846938cf96ea7e75c8715bc3edac01b39589" | tee -a $logfile

echo "=== TESTCASE 5a: ./trx_2txt.sh -r 010000000301de569ae..." | tee -a $logfile
echo "================================================================" | tee -a $logfile
./trx_2txt.sh -r 010000000301de569ae0b3d49dff80f79f7953f87f17f61ca1f6d523e815a58e2b8863d098000000006a47304402203930d1ba339c9692367ae37836b1f21c1431ecb4522e7ce0caa356b9813722dc02204086f7ad81d5d656ab1b6d0fd4709b5759c22c44a0aeb1969c1cdb7c463912fa012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffff97e60e0bec78cf5114238678f0b5eab617ca770752796b4c795c9d3ada772da5000000006a473044022046412e2b3f820f846a5e8f1cc92529cb694cf0d09d35cf0b5128cc7b9bf32a0802207f736b322727babd41793aeedfad41cc0541c0a1693e88b2a620bcd664da8551012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffffce559734242e6a6e0608caa07ee1178d5b9e53e0814d61f002930d78422e8402000000006b4830450221009fab428713fa76057e1bd87381614abc270089ddb23c345b0a56114db0fb8fd30220187a80bedfbb6b23bcf4eaf25017be2efdd64f02a732be9f4846142ad3408798012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffff011005d0010000000017a91469545b58fd41a120da3f606be313e061ea818edf8700000000 > tmpfile
chksum_ref="5d30679968d2215cdb519a77b5d84a3474e2455a6abffe286f7488405b0da398"
chksum_prep

echo "=== TESTCASE 5b: ./trx_2txt.sh -v -r 010000000301de569ae..." | tee -a $logfile
echo "================================================================" | tee -a $logfile
./trx_2txt.sh -v -r 010000000301de569ae0b3d49dff80f79f7953f87f17f61ca1f6d523e815a58e2b8863d098000000006a47304402203930d1ba339c9692367ae37836b1f21c1431ecb4522e7ce0caa356b9813722dc02204086f7ad81d5d656ab1b6d0fd4709b5759c22c44a0aeb1969c1cdb7c463912fa012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffff97e60e0bec78cf5114238678f0b5eab617ca770752796b4c795c9d3ada772da5000000006a473044022046412e2b3f820f846a5e8f1cc92529cb694cf0d09d35cf0b5128cc7b9bf32a0802207f736b322727babd41793aeedfad41cc0541c0a1693e88b2a620bcd664da8551012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffffce559734242e6a6e0608caa07ee1178d5b9e53e0814d61f002930d78422e8402000000006b4830450221009fab428713fa76057e1bd87381614abc270089ddb23c345b0a56114db0fb8fd30220187a80bedfbb6b23bcf4eaf25017be2efdd64f02a732be9f4846142ad3408798012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffff011005d0010000000017a91469545b58fd41a120da3f606be313e061ea818edf8700000000 > tmpfile
chksum_ref="901e0aa7c14542e2434f4cccdb5d1cf311087151da28a50296d94b4e83f59cfa"
chksum_prep

echo "=== TESTCASE 5c: ./trx_2txt.sh -vv -r 010000000301de569ae..." | tee -a $logfile
echo "================================================================" | tee -a $logfile
./trx_2txt.sh -vv -r 010000000301de569ae0b3d49dff80f79f7953f87f17f61ca1f6d523e815a58e2b8863d098000000006a47304402203930d1ba339c9692367ae37836b1f21c1431ecb4522e7ce0caa356b9813722dc02204086f7ad81d5d656ab1b6d0fd4709b5759c22c44a0aeb1969c1cdb7c463912fa012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffff97e60e0bec78cf5114238678f0b5eab617ca770752796b4c795c9d3ada772da5000000006a473044022046412e2b3f820f846a5e8f1cc92529cb694cf0d09d35cf0b5128cc7b9bf32a0802207f736b322727babd41793aeedfad41cc0541c0a1693e88b2a620bcd664da8551012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffffce559734242e6a6e0608caa07ee1178d5b9e53e0814d61f002930d78422e8402000000006b4830450221009fab428713fa76057e1bd87381614abc270089ddb23c345b0a56114db0fb8fd30220187a80bedfbb6b23bcf4eaf25017be2efdd64f02a732be9f4846142ad3408798012103f6bfdba31cf7e059e19a2b0e60670864d24d7dfe0d7f11045756991271dda237ffffffff011005d0010000000017a91469545b58fd41a120da3f606be313e061ea818edf8700000000 > tmpfile
chksum_ref="3e03fb192056db8b79071e8b4a65d3765c326c49e9e8081f6543eb4a37d9e0b9"
chksum_prep
echo " " | tee -a $logfile
}

testcase6() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 6: this trx has 1 input, and 4 outputs          ===" | tee -a $logfile
echo "===  trx-in sequence = feffffff - what does this mean?       ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "https://blockchain.info/de/rawtx/7264f8ba4a85a4780c549bf04a98e8de4c9cb1120cb1dfe8ab85ff6832eff864" | tee -a $logfile

echo "=== TESTCASE 6a: ./trx_2txt.sh -r 0100000001df64d3e79..." | tee -a $logfile
echo "================================================================" | tee -a $logfile
./trx_2txt.sh -r 0100000001df64d3e790779777de937eea18884e9b131c9910bdb860b1a5cea225b61e3510020000006b48304502210082e594fdd17f4f2995edc180e5373a664eb56f56420f0c8761a27fa612db2a2b02206bcd4763303661c9ccaac3e4e7f6bfc062f17ce4b6b1b479ee067a05e5a578b10121036932969ec8c5cecebc1ff6fc07126f8cb5589ada69db8ca97a4f1291ead8c06bfeffffff04d130ab00000000001976a9141f59b78ccc26b6d84a65b0d362185ac4683197ed88acf0fcf300000000001976a914f12d85961d3a36119c2eaed5ad0e728a789ab59c88acb70aa700000000001976a9142baaf47baf1bd1e3dad3956db536c3f2e87c237b88ac94804707000000001976a914cb1b1d3c8be7db6416c16a1d29db170930970a3088acce3d0600 > tmpfile
chksum_ref="337e47767fd18c4fa3de97e5e6746e282cc5027a25ee52affa5c3ca6dba9ef05"
chksum_prep

echo "=== TESTCASE 6b: ./trx_2txt.sh -v -r 0100000001df64d3e79..." | tee -a $logfile
echo "================================================================" | tee -a $logfile
./trx_2txt.sh -v -r 0100000001df64d3e790779777de937eea18884e9b131c9910bdb860b1a5cea225b61e3510020000006b48304502210082e594fdd17f4f2995edc180e5373a664eb56f56420f0c8761a27fa612db2a2b02206bcd4763303661c9ccaac3e4e7f6bfc062f17ce4b6b1b479ee067a05e5a578b10121036932969ec8c5cecebc1ff6fc07126f8cb5589ada69db8ca97a4f1291ead8c06bfeffffff04d130ab00000000001976a9141f59b78ccc26b6d84a65b0d362185ac4683197ed88acf0fcf300000000001976a914f12d85961d3a36119c2eaed5ad0e728a789ab59c88acb70aa700000000001976a9142baaf47baf1bd1e3dad3956db536c3f2e87c237b88ac94804707000000001976a914cb1b1d3c8be7db6416c16a1d29db170930970a3088acce3d0600 > tmpfile
chksum_ref="72337fa91301e1192471b034026b2d30ee59c77d4f89127dde52a5b536f3c542"
chksum_prep

echo "=== TESTCASE 6c: ./trx_2txt.sh -vv -r 0100000001df64d3e79..." | tee -a $logfile
echo "================================================================" | tee -a $logfile
./trx_2txt.sh -vv -r 0100000001df64d3e790779777de937eea18884e9b131c9910bdb860b1a5cea225b61e3510020000006b48304502210082e594fdd17f4f2995edc180e5373a664eb56f56420f0c8761a27fa612db2a2b02206bcd4763303661c9ccaac3e4e7f6bfc062f17ce4b6b1b479ee067a05e5a578b10121036932969ec8c5cecebc1ff6fc07126f8cb5589ada69db8ca97a4f1291ead8c06bfeffffff04d130ab00000000001976a9141f59b78ccc26b6d84a65b0d362185ac4683197ed88acf0fcf300000000001976a914f12d85961d3a36119c2eaed5ad0e728a789ab59c88acb70aa700000000001976a9142baaf47baf1bd1e3dad3956db536c3f2e87c237b88ac94804707000000001976a914cb1b1d3c8be7db6416c16a1d29db170930970a3088acce3d0600 > tmpfile
chksum_ref="521df19dd96c1167c8f06c1468e2f8093d28a2876aa741919d9b6f8771a8706b"
chksum_prep
echo " " | tee -a $logfile
}


testcase7() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 7: this is a transaction to a multisig address  ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "https://blockchain.info/de/rawtx/51f7fc9899b068c4a501ffa9b37368fd7c09b3e72e893e989c40c89095f74b79" | tee -a $logfile

echo "=== TESTCASE 7a: " | tee -a $logfile
echo "================================================================" | tee -a $logfile
./trx_2txt.sh -r 010000000216f7342825c156476c430f3e2765e0c393283b08246a66d122a45c836554ef03010000006b483045022100dd55b040174c90e85f0d33417dfccd96fa4f6b5ef50c32a1b720c24efc097f73022018d8a6b003b46c578d42ff4221af46068b64dd4e55d2d074175038a6e620e66b012103a86d6cd289a76d1b2b13d362d9f58d1753dd4252be1ef8a404831dd1de45f6c2ffffffffe18f73b450139de5c7375dcd2bd249ef6a42ad19661104df796dccdc98d34722000000006a47304402202e733dd23eb16130c3aa705cd04ffa31928616f2558063281cf642d786bf3eef022010a4d48968c504391c19c1cf67163d5618809bacb644d797a24a05f2130aa9f7012103a86d6cd289a76d1b2b13d362d9f58d1753dd4252be1ef8a404831dd1de45f6c2ffffffff02a6ea17000000000017a914f815b036d9bbbce5e9f2a00abd1bf3dc91e9551087413c0200000000001976a914ff57cb19528c04096067b8db38d18ecd0b37789388ac00000000 > tmpfile
chksum_ref="b3e0b22ac9014bcca7f1066943bb45edead04549d49b05a743ae48f2e435ba26"
chksum_prep

echo "=== TESTCASE 7b: " | tee -a $logfile
echo "================================================================" | tee -a $logfile
./trx_2txt.sh -v -r 010000000216f7342825c156476c430f3e2765e0c393283b08246a66d122a45c836554ef03010000006b483045022100dd55b040174c90e85f0d33417dfccd96fa4f6b5ef50c32a1b720c24efc097f73022018d8a6b003b46c578d42ff4221af46068b64dd4e55d2d074175038a6e620e66b012103a86d6cd289a76d1b2b13d362d9f58d1753dd4252be1ef8a404831dd1de45f6c2ffffffffe18f73b450139de5c7375dcd2bd249ef6a42ad19661104df796dccdc98d34722000000006a47304402202e733dd23eb16130c3aa705cd04ffa31928616f2558063281cf642d786bf3eef022010a4d48968c504391c19c1cf67163d5618809bacb644d797a24a05f2130aa9f7012103a86d6cd289a76d1b2b13d362d9f58d1753dd4252be1ef8a404831dd1de45f6c2ffffffff02a6ea17000000000017a914f815b036d9bbbce5e9f2a00abd1bf3dc91e9551087413c0200000000001976a914ff57cb19528c04096067b8db38d18ecd0b37789388ac00000000 > tmpfile
chksum_ref="1cb6476e645474175e1242089a5c0d47de79d3129d89d7ae071bef7cdcbc1221"
chksum_prep

echo "=== TESTCASE 7c: " | tee -a $logfile
echo "================================================================" | tee -a $logfile
./trx_2txt.sh -vv -r 010000000216f7342825c156476c430f3e2765e0c393283b08246a66d122a45c836554ef03010000006b483045022100dd55b040174c90e85f0d33417dfccd96fa4f6b5ef50c32a1b720c24efc097f73022018d8a6b003b46c578d42ff4221af46068b64dd4e55d2d074175038a6e620e66b012103a86d6cd289a76d1b2b13d362d9f58d1753dd4252be1ef8a404831dd1de45f6c2ffffffffe18f73b450139de5c7375dcd2bd249ef6a42ad19661104df796dccdc98d34722000000006a47304402202e733dd23eb16130c3aa705cd04ffa31928616f2558063281cf642d786bf3eef022010a4d48968c504391c19c1cf67163d5618809bacb644d797a24a05f2130aa9f7012103a86d6cd289a76d1b2b13d362d9f58d1753dd4252be1ef8a404831dd1de45f6c2ffffffff02a6ea17000000000017a914f815b036d9bbbce5e9f2a00abd1bf3dc91e9551087413c0200000000001976a914ff57cb19528c04096067b8db38d18ecd0b37789388ac00000000 > tmpfile
chksum_ref="6d30025edd73308384f9bd56e49106fadbd1b91669b10cd706a51045443de92c"
chksum_prep
echo " " | tee -a $logfile
}


testcase8() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 8: just another multisig trx                    ===" | tee -a $logfile
echo "===  Here we have a multisig in and out address ...          ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "https://blockchain.info/de/rawtx/c0889855c93eed67d1f5a6b8a31e446e3327ce03bc267f2db958e79802941c73" | tee -a $logfile

echo "=== TESTCASE 8a: " | tee -a $logfile
./trx_2txt.sh -r 0100000001b9c6777f2d8d710f1e0e3bb5fbffa7cdfd6c814a2257a7cfced9a2205448dd0601000000da0048304502210083a93c7611f5aeee6b0b4d1cbff2d31556af4cd1f951de8341c768ae03f780730220063b5e6dfb461291b1fbd93d58a8111d04fd03c7098834bac5cdf1d3c5fa90d0014730440220137c7320e03b73da66e9cf89e5f5ed0d5743ebc65e776707b8385ff93039408802202c30bc57010b3dd20507393ebc79affc653473a7baf03c5abf19c14e2136c646014752210285cb139a82dd9062b9ac1091cb1f91a01c11ab9c6a46bd09d0754dab86a38cc9210328c37f938748dcbbf15a0e5a9d1ba20f93f2c2d0ead63c7c14a5a10959b5ce8952aeffffffff0280c42b03000000001976a914d199925b52d367220b1e2a2d8815e635b571512f88ac65a7b3010000000017a9145c4dd14b9df138840b34237fdbe9159c420edbbe8700000000 > tmpfile
chksum_ref="eed10df64c287bc6028466dcb878b1cf2ab49082219c969dcc2134a0525a1c29"
chksum_prep

echo "=== TESTCASE 8b: " | tee -a $logfile
./trx_2txt.sh -v -r 0100000001b9c6777f2d8d710f1e0e3bb5fbffa7cdfd6c814a2257a7cfced9a2205448dd0601000000da0048304502210083a93c7611f5aeee6b0b4d1cbff2d31556af4cd1f951de8341c768ae03f780730220063b5e6dfb461291b1fbd93d58a8111d04fd03c7098834bac5cdf1d3c5fa90d0014730440220137c7320e03b73da66e9cf89e5f5ed0d5743ebc65e776707b8385ff93039408802202c30bc57010b3dd20507393ebc79affc653473a7baf03c5abf19c14e2136c646014752210285cb139a82dd9062b9ac1091cb1f91a01c11ab9c6a46bd09d0754dab86a38cc9210328c37f938748dcbbf15a0e5a9d1ba20f93f2c2d0ead63c7c14a5a10959b5ce8952aeffffffff0280c42b03000000001976a914d199925b52d367220b1e2a2d8815e635b571512f88ac65a7b3010000000017a9145c4dd14b9df138840b34237fdbe9159c420edbbe8700000000 > tmpfile
chksum_ref="a4da0c9fb428b931e51eafc508d3e2f00be05610cc567749511d21ed6a95d380"
chksum_prep

echo "=== TESTCASE 8c: " | tee -a $logfile
./trx_2txt.sh -vv -r 0100000001b9c6777f2d8d710f1e0e3bb5fbffa7cdfd6c814a2257a7cfced9a2205448dd0601000000da0048304502210083a93c7611f5aeee6b0b4d1cbff2d31556af4cd1f951de8341c768ae03f780730220063b5e6dfb461291b1fbd93d58a8111d04fd03c7098834bac5cdf1d3c5fa90d0014730440220137c7320e03b73da66e9cf89e5f5ed0d5743ebc65e776707b8385ff93039408802202c30bc57010b3dd20507393ebc79affc653473a7baf03c5abf19c14e2136c646014752210285cb139a82dd9062b9ac1091cb1f91a01c11ab9c6a46bd09d0754dab86a38cc9210328c37f938748dcbbf15a0e5a9d1ba20f93f2c2d0ead63c7c14a5a10959b5ce8952aeffffffff0280c42b03000000001976a914d199925b52d367220b1e2a2d8815e635b571512f88ac65a7b3010000000017a9145c4dd14b9df138840b34237fdbe9159c420edbbe8700000000 > tmpfile
chksum_ref="947c1028249be6c378be2bca7c7aafae46d3e8d317a654deed58ead39ad1535d"
chksum_prep
echo " " | tee -a $logfile
}


testcase9() {
echo "=============================================================" | tee -a $logfile
echo "=== TESTCASE 9: 4 inputs and 2 outputs (P2SH multisig!)   ===" | tee -a $logfile
echo "===  This is a long transaction, which is fetched via     ===" | tee -a $logfile
echo "===  the -t parameter.                                    ===" | tee -a $logfile
echo "=============================================================" | tee -a $logfile
echo "https://blockchain.info/de/rawtx/734c48124d391bfff5750bbc39bd18e6988e8ac873c418d64d31cfdc31cc64ac" | tee -a $logfile

echo "=== TESTCASE 9a: " | tee -a $logfile
echo "=============================================================" | tee -a $logfile
./trx_2txt.sh -t 734c48124d391bfff5750bbc39bd18e6988e8ac873c418d64d31cfdc31cc64ac > tmpfile
chksum_ref="d954cf5b566d2734beecb7a5307f7ae2477e15823f95ebf81962d07e10470ff0"
chksum_prep

echo "=== TESTCASE 9b: " | tee -a $logfile
echo "=============================================================" | tee -a $logfile
./trx_2txt.sh -v -t 734c48124d391bfff5750bbc39bd18e6988e8ac873c418d64d31cfdc31cc64ac > tmpfile
chksum_ref="b510f9fdc8e9432143d3851a01651e9aee66d9f645cb3c544b02a3993828da14"
chksum_prep

echo "=== TESTCASE 9c: " | tee -a $logfile
echo "=============================================================" | tee -a $logfile
./trx_2txt.sh -vv -t 734c48124d391bfff5750bbc39bd18e6988e8ac873c418d64d31cfdc31cc64ac > tmpfile
chksum_ref="760535ffdcf067b6cbfbfcd19b84ef1ef5a9dd28252051184f018140527b3444"
chksum_prep
echo " " | tee -a $logfile
}


testcase10() {
echo "=============================================================" | tee -a $logfile
echo "=== TESTCASE 10: 1 input, 4 outputs (one is P2SH script)  ===" | tee -a $logfile
echo "=============================================================" | tee -a $logfile
echo "https://blockchain.info/de/rawtx/ea9462053d74024ec46dac07c450200194051020698e8640a5a024d8ac085590" | tee -a $logfile

echo "=== TESTCASE 10a: " | tee -a $logfile
echo "=============================================================" | tee -a $logfile
./trx_2txt.sh -r 01000000013153f60f294bc14d0481138c1c9627ff71a580b596987a82e9eebf2ae3de232202000000fc0047304402200c2f9e8805de97fa785b93dcc9072197bf5c1095ea536320ed26c645ec3bfafc02202882258f394449f1b1365ce80eed26fbe01217657729664af6827d041e7e98510147304402206d5cbef275b6972bd8cc00aff666a6ca18f09a5b1d1bf49e6966ad815db7119a0220340e49d4b747c9bd8ac80dbe073525c57da43dc4d2727b789be7e66bed9c6d02014c695221037b7c16024e2e6f6575b7a8c55c581dce7effcd6045bdf196461be8ff88db24f1210223eefa59f9b51ca96e1f4710df3639c58aae32c4cef1dd0333e7478de3dd4c6321034d03a7e6806e734c171be535999239aac76822427c217ee7564ab752cdc12dde53aeffffffff048d40ad120100000017a914fb8e0ce6d2f35c566908fd225b7f96e72df603d3872d5f0000000000001976a914768ac2a2530b2987d2e6506edc71dcf9f0a7b6e688ac00350c00000000001976a91452f28673c5aed9126b91d9eac5cbe1e02276a2cb88ac18b30700000000001976a914f3678c60ec389c7b132b5e5b0e1434b6dcd48f4188ac00000000 > tmpfile
chksum_ref="b7ffaf82b646f61d61d630437294bd2ac330b1f8bffe2fabb8a39904d7cd0265"
chksum_prep

echo "=== TESTCASE 10b: " | tee -a $logfile
echo "=============================================================" | tee -a $logfile
./trx_2txt.sh -v -r 01000000013153f60f294bc14d0481138c1c9627ff71a580b596987a82e9eebf2ae3de232202000000fc0047304402200c2f9e8805de97fa785b93dcc9072197bf5c1095ea536320ed26c645ec3bfafc02202882258f394449f1b1365ce80eed26fbe01217657729664af6827d041e7e98510147304402206d5cbef275b6972bd8cc00aff666a6ca18f09a5b1d1bf49e6966ad815db7119a0220340e49d4b747c9bd8ac80dbe073525c57da43dc4d2727b789be7e66bed9c6d02014c695221037b7c16024e2e6f6575b7a8c55c581dce7effcd6045bdf196461be8ff88db24f1210223eefa59f9b51ca96e1f4710df3639c58aae32c4cef1dd0333e7478de3dd4c6321034d03a7e6806e734c171be535999239aac76822427c217ee7564ab752cdc12dde53aeffffffff048d40ad120100000017a914fb8e0ce6d2f35c566908fd225b7f96e72df603d3872d5f0000000000001976a914768ac2a2530b2987d2e6506edc71dcf9f0a7b6e688ac00350c00000000001976a91452f28673c5aed9126b91d9eac5cbe1e02276a2cb88ac18b30700000000001976a914f3678c60ec389c7b132b5e5b0e1434b6dcd48f4188ac00000000 > tmpfile
chksum_ref="60d67676bfa0cccefb3aaa8898651f43da41b1235095de5690e1e5aaf8ed0c0b"
chksum_prep

echo "=== TESTCASE 10c: " | tee -a $logfile
echo "=============================================================" | tee -a $logfile
./trx_2txt.sh -vv -r 01000000013153f60f294bc14d0481138c1c9627ff71a580b596987a82e9eebf2ae3de232202000000fc0047304402200c2f9e8805de97fa785b93dcc9072197bf5c1095ea536320ed26c645ec3bfafc02202882258f394449f1b1365ce80eed26fbe01217657729664af6827d041e7e98510147304402206d5cbef275b6972bd8cc00aff666a6ca18f09a5b1d1bf49e6966ad815db7119a0220340e49d4b747c9bd8ac80dbe073525c57da43dc4d2727b789be7e66bed9c6d02014c695221037b7c16024e2e6f6575b7a8c55c581dce7effcd6045bdf196461be8ff88db24f1210223eefa59f9b51ca96e1f4710df3639c58aae32c4cef1dd0333e7478de3dd4c6321034d03a7e6806e734c171be535999239aac76822427c217ee7564ab752cdc12dde53aeffffffff048d40ad120100000017a914fb8e0ce6d2f35c566908fd225b7f96e72df603d3872d5f0000000000001976a914768ac2a2530b2987d2e6506edc71dcf9f0a7b6e688ac00350c00000000001976a91452f28673c5aed9126b91d9eac5cbe1e02276a2cb88ac18b30700000000001976a914f3678c60ec389c7b132b5e5b0e1434b6dcd48f4188ac00000000 > tmpfile
chksum_ref="26d8a4d8a54270320c2f23b071e70f0fc3271b649172b34c2c1c9f8560b224da"
chksum_prep
echo " " | tee -a $logfile
}

testcase11() {
echo "=============================================================" | tee -a $logfile
echo "=== TESTCASE 11: *** worum geht's ? Referenz ??? ***      ===" | tee -a $logfile
echo "=============================================================" | tee -a $logfile
echo "=== TESTCASE 11a: " | tee -a $logfile
echo "=============================================================" | tee -a $logfile
./trx_2txt.sh -u 0100000001bc12683c21e46c380933e83c00ec3929453e3d11cc5a2db9f795372efe03e81d000000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88acffffffff01d0a11000000000001976a9140de4457d577bb45dee513bb695bdfdc3b34d467d88ac0000000001000000 > tmpfile
chksum_ref="005562b2c1bc36a28aa32650c08985875e3262acad2c7256a49b1426f73572a3"
chksum_prep

echo "=== TESTCASE 11b: " | tee -a $logfile
echo "=============================================================" | tee -a $logfile
./trx_2txt.sh -v -u 0100000001bc12683c21e46c380933e83c00ec3929453e3d11cc5a2db9f795372efe03e81d000000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88acffffffff01d0a11000000000001976a9140de4457d577bb45dee513bb695bdfdc3b34d467d88ac0000000001000000 > tmpfile
chksum_ref="25e93fe8fbb9ce1ff4a51e876fb45c2651f5f31a5a3003bdad5dff03559a061b"
chksum_prep

echo "=== TESTCASE 11c: " | tee -a $logfile
echo "=============================================================" | tee -a $logfile
./trx_2txt.sh -vv -u 0100000001bc12683c21e46c380933e83c00ec3929453e3d11cc5a2db9f795372efe03e81d000000001976a914c2df275d78e506e17691fd6f0c63c43d15c897fc88acffffffff01d0a11000000000001976a9140de4457d577bb45dee513bb695bdfdc3b34d467d88ac0000000001000000 > tmpfile
chksum_ref="20114216728df24fcef9539de0f36b3bff6a79b1fd303565f75a59d70bf7d7c7"
chksum_prep
echo " " | tee -a $logfile
}

testcase12() {
echo "=== TESTCASE 11a: " | tee -a $logfile
chksum_ref="df9fe79f8380e40d083766f7f0e754d5eb9af5ea910fc33e7ff1597f543263a7"
./trx_2txt.sh > tmpfile
chksum_prep

echo "=== TESTCASE 12b: " | tee -a $logfile
chksum_ref="df9fe79f8380e40d083766f7f0e754d5eb9af5ea910fc33e7ff1597f543263a7"
./trx_2txt.sh -v > tmpfile
chksum_prep

echo "=== TESTCASE 12c: " | tee -a $logfile
chksum_ref="df9fe79f8380e40d083766f7f0e754d5eb9af5ea910fc33e7ff1597f543263a7"
./trx_2txt.sh -vv > tmpfile
chksum_prep
echo " " | tee -a $logfile
}

testcase20() {
# this trx has a complicated input script (PK script?)
echo "=============================================================" | tee -a $logfile
echo "=== TESTCASE 20:                                          ===" | tee -a $logfile
echo "=============================================================" | tee -a $logfile
echo "===  this trx has 35 output scripts ...                   ===" >> $logfile
echo "=============================================================" >> $logfile
echo "https://blockchain.info/de/rawtx/7c83fe5ba301e655973e9de8eb9fb5e20ef3a6dd9b46c503679c858399eda50f" | tee -a $logfile

echo "=== TESTCASE 20a: " | tee -a $logfile
chksum_verify "$result" "SHA256(tmpfile)= 0a1f0b6c5dce37e107665674fdc38eb786f7b1c434989ea1ce8b0c4658240fc7"
  ./trx_2txt.sh -r 01000000014675ab74e5c496c8eecaaa87c6136bc68ebaaac7a25e70ee29b7bbaffad6810f000000008b4830450220296d4f4869a63efdee4c5ea31dcad559b4e03332462ba5442bfdf00a662cb77102210088a7f10361eae3e159ae6a8b5b7a569bf6bfa2de64fb3f5d0552f8be568ba6f50141042a9a97b2109ef496ffb1033576a5635cecc6ab679ad0b7c43d33ddf38b1f44c22ea42d5c01ac2752094ff81e79dda77d8b501a64102207c45fb89ea1ad9229ddffffffff23e8030000000000001976a914801314cd462b98c64dd4c3f4d6474cad11ea39d588ace8030000000000001976a9145bb7d22851413e1d61e8db5395a8c7c537256ea088ace8030000000000001976a914371f197d5ba5e32bd98260eec7f0e51227b6969088ace8030000000000001976a9143e546d0acc0de5aa3d66d7a920900ecbc66c203188ace8030000000000001976a9140337e0710056f114c9c469a68775498df9f9fa1688ace8030000000000001976a9149c628c82aa7b81da7c6a235049eb2979c4a65cfc88ace8030000000000001976a914cd1d7e863f891c493e093ada840ef5a67ad2d6cc88ace8030000000000001976a91476f074340381e6f8a40aec4a6e2d92485679412c88ace8030000000000001976a9140fb87a5071385b6976397d1c53ee16f09139a33488ace8030000000000001976a9143d37873ffd2964a1a4c8bade4852020ec5426d3688ace8030000000000001976a9145d14a857fce8da8edfb8f7d1c4bbc316622b722788ace8030000000000001976a9140a77fdb4cc81631b6ea2991ff60b47d57812d8e788ace8030000000000001976a91454514fe9251b5e381d13171cd6fca63f61d8b72688ace8030000000000001976a914cffe3e032a686cc3f2c9e417865afa8a52ed962b88ace8030000000000001976a914fd9dc3525076c1ffe9c33389ea157d07af2e41d488ace8030000000000001976a9143bedfe927d55a8c8adfe5e4b5dddd4ea3487b4c988ace8030000000000001976a914e49275e86ece605f271f26a9559520eb9c0ae8d888ace8030000000000001976a91469256ba90b0d7e406d86a51d343d157ff0aab7bd88ace8030000000000001976a9148ab0cb809cd893cb0cb16f647d024db94f09d76588ace8030000000000001976a9140688e383f02b528c92e25caae5785ffaa81a26aa88ace8030000000000001976a914d959be6c92037995558f43a55b1c271628f96e8d88ac8038f240000000001976a914d15e54e341d538ce3e9e7596e0dbcda8c12cc08988ace8030000000000001976a91495019a8168e8dcd2ef2d47ca57c1bf49358eb6fe88ace8030000000000001976a914caf67cfe28b511498b0d1792bedeec6b6e8a3c8d88ace8030000000000001976a914082a3adf4c8497fbd7d90f21cbec318b0dfdd2b288ace8030000000000001976a9144c53722fd5b0bc8a5b23ae4efc6233142b69d8ee88ace8030000000000001976a9146abd1edce61a7fdd2d134e8468560ecffb45334e88ace8030000000000001976a914dc3343b674cf2016b8968e6146ba5cc9228f14a488ace8030000000000001976a9145f395a91d07712604d7cd6fabd685b9bfd3900dd88ace8030000000000001976a914fc35239072cd5c19d9f761996951679fb03bb43188ace8030000000000001976a914b1ec1d5e0591abbbe3134c94c37e74d034b9312288ace8030000000000001976a9142d6351944aa38af6aa46d4a74cbb9016cf19ee7e88ace8030000000000001976a914879a49b3822806e0322565d457ce2b5989adaa6188ace8030000000000001976a9145ff26e3f8d542c5bb612e539649eaec0222afc3c88ace8030000000000001976a914105d54a4edcbe114a50bb01c79d230b7ed74a3e488ac00000000 > tmpfile
chksum_prep

echo "=== TESTCASE 20b: " | tee -a $logfile
chksum_ref="27cdb3f64ffe133ddb80602efb9f53c2369cde8a25aa8d4b22d33643388cd4c1"
  ./trx_2txt.sh -v -r 01000000014675ab74e5c496c8eecaaa87c6136bc68ebaaac7a25e70ee29b7bbaffad6810f000000008b4830450220296d4f4869a63efdee4c5ea31dcad559b4e03332462ba5442bfdf00a662cb77102210088a7f10361eae3e159ae6a8b5b7a569bf6bfa2de64fb3f5d0552f8be568ba6f50141042a9a97b2109ef496ffb1033576a5635cecc6ab679ad0b7c43d33ddf38b1f44c22ea42d5c01ac2752094ff81e79dda77d8b501a64102207c45fb89ea1ad9229ddffffffff23e8030000000000001976a914801314cd462b98c64dd4c3f4d6474cad11ea39d588ace8030000000000001976a9145bb7d22851413e1d61e8db5395a8c7c537256ea088ace8030000000000001976a914371f197d5ba5e32bd98260eec7f0e51227b6969088ace8030000000000001976a9143e546d0acc0de5aa3d66d7a920900ecbc66c203188ace8030000000000001976a9140337e0710056f114c9c469a68775498df9f9fa1688ace8030000000000001976a9149c628c82aa7b81da7c6a235049eb2979c4a65cfc88ace8030000000000001976a914cd1d7e863f891c493e093ada840ef5a67ad2d6cc88ace8030000000000001976a91476f074340381e6f8a40aec4a6e2d92485679412c88ace8030000000000001976a9140fb87a5071385b6976397d1c53ee16f09139a33488ace8030000000000001976a9143d37873ffd2964a1a4c8bade4852020ec5426d3688ace8030000000000001976a9145d14a857fce8da8edfb8f7d1c4bbc316622b722788ace8030000000000001976a9140a77fdb4cc81631b6ea2991ff60b47d57812d8e788ace8030000000000001976a91454514fe9251b5e381d13171cd6fca63f61d8b72688ace8030000000000001976a914cffe3e032a686cc3f2c9e417865afa8a52ed962b88ace8030000000000001976a914fd9dc3525076c1ffe9c33389ea157d07af2e41d488ace8030000000000001976a9143bedfe927d55a8c8adfe5e4b5dddd4ea3487b4c988ace8030000000000001976a914e49275e86ece605f271f26a9559520eb9c0ae8d888ace8030000000000001976a91469256ba90b0d7e406d86a51d343d157ff0aab7bd88ace8030000000000001976a9148ab0cb809cd893cb0cb16f647d024db94f09d76588ace8030000000000001976a9140688e383f02b528c92e25caae5785ffaa81a26aa88ace8030000000000001976a914d959be6c92037995558f43a55b1c271628f96e8d88ac8038f240000000001976a914d15e54e341d538ce3e9e7596e0dbcda8c12cc08988ace8030000000000001976a91495019a8168e8dcd2ef2d47ca57c1bf49358eb6fe88ace8030000000000001976a914caf67cfe28b511498b0d1792bedeec6b6e8a3c8d88ace8030000000000001976a914082a3adf4c8497fbd7d90f21cbec318b0dfdd2b288ace8030000000000001976a9144c53722fd5b0bc8a5b23ae4efc6233142b69d8ee88ace8030000000000001976a9146abd1edce61a7fdd2d134e8468560ecffb45334e88ace8030000000000001976a914dc3343b674cf2016b8968e6146ba5cc9228f14a488ace8030000000000001976a9145f395a91d07712604d7cd6fabd685b9bfd3900dd88ace8030000000000001976a914fc35239072cd5c19d9f761996951679fb03bb43188ace8030000000000001976a914b1ec1d5e0591abbbe3134c94c37e74d034b9312288ace8030000000000001976a9142d6351944aa38af6aa46d4a74cbb9016cf19ee7e88ace8030000000000001976a914879a49b3822806e0322565d457ce2b5989adaa6188ace8030000000000001976a9145ff26e3f8d542c5bb612e539649eaec0222afc3c88ace8030000000000001976a914105d54a4edcbe114a50bb01c79d230b7ed74a3e488ac00000000 > tmpfile
chksum_prep

echo "=== TESTCASE 20c: " | tee -a $logfile
chksum_ref="df9fe79f8380e40d083766f7f0e754d5eb9af5ea910fc33e7ff1597f543263a7"
  ./trx_2txt.sh -vv -r 01000000014675ab74e5c496c8eecaaa87c6136bc68ebaaac7a25e70ee29b7bbaffad6810f000000008b4830450220296d4f4869a63efdee4c5ea31dcad559b4e03332462ba5442bfdf00a662cb77102210088a7f10361eae3e159ae6a8b5b7a569bf6bfa2de64fb3f5d0552f8be568ba6f50141042a9a97b2109ef496ffb1033576a5635cecc6ab679ad0b7c43d33ddf38b1f44c22ea42d5c01ac2752094ff81e79dda77d8b501a64102207c45fb89ea1ad9229ddffffffff23e8030000000000001976a914801314cd462b98c64dd4c3f4d6474cad11ea39d588ace8030000000000001976a9145bb7d22851413e1d61e8db5395a8c7c537256ea088ace8030000000000001976a914371f197d5ba5e32bd98260eec7f0e51227b6969088ace8030000000000001976a9143e546d0acc0de5aa3d66d7a920900ecbc66c203188ace8030000000000001976a9140337e0710056f114c9c469a68775498df9f9fa1688ace8030000000000001976a9149c628c82aa7b81da7c6a235049eb2979c4a65cfc88ace8030000000000001976a914cd1d7e863f891c493e093ada840ef5a67ad2d6cc88ace8030000000000001976a91476f074340381e6f8a40aec4a6e2d92485679412c88ace8030000000000001976a9140fb87a5071385b6976397d1c53ee16f09139a33488ace8030000000000001976a9143d37873ffd2964a1a4c8bade4852020ec5426d3688ace8030000000000001976a9145d14a857fce8da8edfb8f7d1c4bbc316622b722788ace8030000000000001976a9140a77fdb4cc81631b6ea2991ff60b47d57812d8e788ace8030000000000001976a91454514fe9251b5e381d13171cd6fca63f61d8b72688ace8030000000000001976a914cffe3e032a686cc3f2c9e417865afa8a52ed962b88ace8030000000000001976a914fd9dc3525076c1ffe9c33389ea157d07af2e41d488ace8030000000000001976a9143bedfe927d55a8c8adfe5e4b5dddd4ea3487b4c988ace8030000000000001976a914e49275e86ece605f271f26a9559520eb9c0ae8d888ace8030000000000001976a91469256ba90b0d7e406d86a51d343d157ff0aab7bd88ace8030000000000001976a9148ab0cb809cd893cb0cb16f647d024db94f09d76588ace8030000000000001976a9140688e383f02b528c92e25caae5785ffaa81a26aa88ace8030000000000001976a914d959be6c92037995558f43a55b1c271628f96e8d88ac8038f240000000001976a914d15e54e341d538ce3e9e7596e0dbcda8c12cc08988ace8030000000000001976a91495019a8168e8dcd2ef2d47ca57c1bf49358eb6fe88ace8030000000000001976a914caf67cfe28b511498b0d1792bedeec6b6e8a3c8d88ace8030000000000001976a914082a3adf4c8497fbd7d90f21cbec318b0dfdd2b288ace8030000000000001976a9144c53722fd5b0bc8a5b23ae4efc6233142b69d8ee88ace8030000000000001976a9146abd1edce61a7fdd2d134e8468560ecffb45334e88ace8030000000000001976a914dc3343b674cf2016b8968e6146ba5cc9228f14a488ace8030000000000001976a9145f395a91d07712604d7cd6fabd685b9bfd3900dd88ace8030000000000001976a914fc35239072cd5c19d9f761996951679fb03bb43188ace8030000000000001976a914b1ec1d5e0591abbbe3134c94c37e74d034b9312288ace8030000000000001976a9142d6351944aa38af6aa46d4a74cbb9016cf19ee7e88ace8030000000000001976a914879a49b3822806e0322565d457ce2b5989adaa6188ace8030000000000001976a9145ff26e3f8d542c5bb612e539649eaec0222afc3c88ace8030000000000001976a914105d54a4edcbe114a50bb01c79d230b7ed74a3e488ac00000000 > tmpfile
chksum_prep
echo " " | tee -a $logfile
}




all_testcases() {
  testcase1 
  testcase2 
  testcase3 
  testcase4 
  testcase5 
  testcase6 
  testcase7 
  testcase8 
  testcase9 
  testcase10
  testcase11
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
  chksum_cmd="openssl sha256"
fi

################################
# command line params handling #
################################

if [ $# -eq 0 ] ; then
  all_testcases
fi

while [ $# -ge 1 ] 
 do
  case "$1" in
  -h)
     echo "usage: trx_testcases.sh -h|-l [1-9]"
     echo "  "
     echo "script does several testcases, mostly with checksums for verification"
     echo "  "
     exit 0
     ;;
  -l)
     LOG=1
     shift
     if [ $# -eq 0 ] ; then
       all_testcases
     fi
     ;;
  1|2|3|4|5|6|7|8|9|10|11)
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

