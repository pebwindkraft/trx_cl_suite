#!/bin/sh
# some testcases for the shell script "tx_verify_sig.sh" 
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

echo "=== TESTCASE 1a: $chksum_cmd tcls_verify_sig.sh" | tee -a $logfile
cp tcls_verify_sig.sh tmp_tx_cfile
chksum_ref="2d4cfa45e5de065c3ab101265d0ffa000b43e29268c486ca8f1cd6cccee9e1c0" 
chksum_prep

echo "=== TESTCASE 1b: $chksum_cmd tcls_key2pem.sh" | tee -a $logfile
cp tcls_key2pem.sh tmp_tx_cfile
chksum_ref="0b5fb56e663368f7e011e49b8caf3560aff87c3176c1608b482f398c1deaaf1f" 
chksum_prep

echo "=== TESTCASE 1c: $chksum_cmd tcls_strict_sig_verify.sh" | tee -a $logfile
cp tcls_strict_sig_verify.sh tmp_tx_cfile
chksum_ref="0d9ea108a4cfd61a50969a1bf08fd2f1f94a1acb3f144ebfa235c7449ad70c12"
chksum_prep

echo "=== TESTCASE 1d: $chksum_cmd tcls_verify_hexkey.awk" | tee -a $logfile
cp tcls_verify_hexkey.awk tmp_tx_cfile
chksum_ref="055b79074a8f33d0aa9aa7634980d29f4e3eb0248a730ea784c7a88e64aa7cfd"
chksum_prep

echo " " | tee -a $logfile
}

testcase2() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 2: parameters testing ...                       ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 2a: -d param too short...     "                      | tee -a $logfile
echo "./tcls_verify_sig.sh -v -d 0123456789abcdef -p 042e930f39ba62c6534ee98ed20ca98959d34aa9e057cda01cfd422c6bab3667b76426529382c23f42b9b08d7832d4fee1d6b437a8526e59667ce9c4e9dcebcabb -s 30450221009908144ca6539e09512b9295c8a27050d478fbb96f8addbc3d075544dc41328702201aa528be2b907d316d2da068dd9eb1e23243d97e444d59290d2fddf25269ee0e" >> $logfile
./tcls_verify_sig.sh -v -d 0123456789abcdef -p 042e930f39ba62c6534ee98ed20ca98959d34aa9e057cda01cfd422c6bab3667b76426529382c23f42b9b08d7832d4fee1d6b437a8526e59667ce9c4e9dcebcabb -s 30450221009908144ca6539e09512b9295c8a27050d478fbb96f8addbc3d075544dc41328702201aa528be2b907d316d2da068dd9eb1e23243d97e444d59290d2fddf25269ee0e > tmp_tx_cfile
chksum_ref="0895db88502710dd7e1aa02f7042e3cdfc55cb9f9f260898da29e8dfa819613f"
chksum_prep

echo "=== TESTCASE 2b: -p param too short...     "                      | tee -a $logfile
echo "./tcls_verify_sig.sh -v -d c2d48f45d7fbeff644ddb72b0f60df6c275f0943444d7df8cc851b3d55782669 -p 0123456789abcdef -s 30450221009908144ca6539e09512b9295c8a27050d478fbb96f8addbc3d075544dc41328702201aa528be2b907d316d2da068dd9eb1e23243d97e444d59290d2fddf25269ee0e" >> $logfile
./tcls_verify_sig.sh -v -d c2d48f45d7fbeff644ddb72b0f60df6c275f0943444d7df8cc851b3d55782669 -p 0123456789abcdef -s 30450221009908144ca6539e09512b9295c8a27050d478fbb96f8addbc3d075544dc41328702201aa528be2b907d316d2da068dd9eb1e23243d97e444d59290d2fddf25269ee0e > tmp_tx_cfile
chksum_ref="d39e403b67f013969bab2d50ebf2a0d6804084cb6318d769f249a412512c8be5"
chksum_prep

echo "=== TESTCASE 2c: -s param too short...     "                      | tee -a $logfile
echo "./tcls_verify_sig.sh -v -d c2d48f45d7fbeff644ddb72b0f60df6c275f0943444d7df8cc851b3d55782669 -p 042e930f39ba62c6534ee98ed20ca98959d34aa9e057cda01cfd422c6bab3667b76426529382c23f42b9b08d7832d4fee1d6b437a8526e59667ce9c4e9dcebcabb -s 30450221000123456789abcdef" >> $logfile
./tcls_verify_sig.sh -v -d c2d48f45d7fbeff644ddb72b0f60df6c275f0943444d7df8cc851b3d55782669 -p 042e930f39ba62c6534ee98ed20ca98959d34aa9e057cda01cfd422c6bab3667b76426529382c23f42b9b08d7832d4fee1d6b437a8526e59667ce9c4e9dcebcabb -s 30450221000123456789abcdef > tmp_tx_cfile
chksum_ref="0e411e0df79fa23e4c504b112bcc0353b8f81dbcc95439459bed91daf5d4726b"
chksum_prep

echo " " | tee -a $logfile
}

testcase3() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 3: the pizza transaction ...                    ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 3a: pizza, quiet operation..."                       | tee -a $logfile
echo "http://bitcoin.stackexchange.com/questions/32305/how-does-the-ecdsa-verification-algorithm-work-during-transaction/32308#32308" >> $logfile
echo "./tcls_verify_sig.sh -d c2d48f45d7fbeff644ddb72b0f60df6c275f0943444d7df8cc851b3d55782669 -p 042e930f39ba62c6534ee98ed20ca98959d34aa9e057cda01cfd422c6bab3667b76426529382c23f42b9b08d7832d4fee1d6b437a8526e59667ce9c4e9dcebcabb -s 30450221009908144ca6539e09512b9295c8a27050d478fbb96f8addbc3d075544dc41328702201aa528be2b907d316d2da068dd9eb1e23243d97e444d59290d2fddf25269ee0e" >> $logfile
./tcls_verify_sig.sh -d c2d48f45d7fbeff644ddb72b0f60df6c275f0943444d7df8cc851b3d55782669  -p 042e930f39ba62c6534ee98ed20ca98959d34aa9e057cda01cfd422c6bab3667b76426529382c23f42b9b08d7832d4fee1d6b437a8526e59667ce9c4e9dcebcabb -s 30450221009908144ca6539e09512b9295c8a27050d478fbb96f8addbc3d075544dc41328702201aa528be2b907d316d2da068dd9eb1e23243d97e444d59290d2fddf25269ee0e > tmp_tx_cfile
chksum_ref="0bd65ea014d3210c1b9a7d7d5af78bc4e4b4384b4f3f7f5674e8d6447e4112c3"
chksum_prep

echo "=== TESTCASE 3b: pizza, be a bit more verbose..." | tee -a $logfile
echo "./tcls_verify_sig.sh -v -d c2d48f45d7fbeff644ddb72b0f60df6c275f0943444d7df8cc851b3d55782669 -p 042e930f39ba62c6534ee98ed20ca98959d34aa9e057cda01cfd422c6bab3667b76426529382c23f42b9b08d7832d4fee1d6b437a8526e59667ce9c4e9dcebcabb -s 30450221009908144ca6539e09512b9295c8a27050d478fbb96f8addbc3d075544dc41328702201aa528be2b907d316d2da068dd9eb1e23243d97e444d59290d2fddf25269ee0e" >> $logfile
./tcls_verify_sig.sh -v -d c2d48f45d7fbeff644ddb72b0f60df6c275f0943444d7df8cc851b3d55782669  -p 042e930f39ba62c6534ee98ed20ca98959d34aa9e057cda01cfd422c6bab3667b76426529382c23f42b9b08d7832d4fee1d6b437a8526e59667ce9c4e9dcebcabb -s 30450221009908144ca6539e09512b9295c8a27050d478fbb96f8addbc3d075544dc41328702201aa528be2b907d316d2da068dd9eb1e23243d97e444d59290d2fddf25269ee0e > tmp_tx_cfile 
chksum_ref="4bd3a7543bd8fa3ffd88f639fc568f1f073afc44ceff3beeb301a0e6617b4a80" 
chksum_prep

echo "=== TESTCASE 3c: pizza, be very verbose..." | tee -a $logfile
echo "./tcls_verify_sig.sh -vv -d c2d48f45d7fbeff644ddb72b0f60df6c275f0943444d7df8cc851b3d55782669 -p 042e930f39ba62c6534ee98ed20ca98959d34aa9e057cda01cfd422c6bab3667b76426529382c23f42b9b08d7832d4fee1d6b437a8526e59667ce9c4e9dcebcabb -s 30450221009908144ca6539e09512b9295c8a27050d478fbb96f8addbc3d075544dc41328702201aa528be2b907d316d2da068dd9eb1e23243d97e444d59290d2fddf25269ee0e" >> $logfile
./tcls_verify_sig.sh -vv -d c2d48f45d7fbeff644ddb72b0f60df6c275f0943444d7df8cc851b3d55782669  -p 042e930f39ba62c6534ee98ed20ca98959d34aa9e057cda01cfd422c6bab3667b76426529382c23f42b9b08d7832d4fee1d6b437a8526e59667ce9c4e9dcebcabb -s 30450221009908144ca6539e09512b9295c8a27050d478fbb96f8addbc3d075544dc41328702201aa528be2b907d316d2da068dd9eb1e23243d97e444d59290d2fddf25269ee0e > tmp_tx_cfile 
chksum_ref="3e19c7c9f511f367d138195d780cfbbf92fecc66e166919dc5413253c92667d2" 
chksum_prep

echo " " | tee -a $logfile
}

testcase4() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 4: use quiet mode to check 4 sigs ...           ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 4a: ./tcls_verify_sig.sh -p p1 -s sig1 -d d1 " | tee -a $logfile
echo "./tcls_verify_sig.sh -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0 -s 304502210086199572c8e5879fa610bd244c7b2d054c389ed8b023f0a3d11f25606773e3f5022037086414c32a875fc2d43ec30664edbce447836e25f68ec39a3d04fd03590b57 -d 6f13d86405f2672b98d52e9d5244e133244885c4ce0d4f9087da9433a09f914f" >> $logfile
./tcls_verify_sig.sh -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0 -s 304502210086199572c8e5879fa610bd244c7b2d054c389ed8b023f0a3d11f25606773e3f5022037086414c32a875fc2d43ec30664edbce447836e25f68ec39a3d04fd03590b57 -d 6f13d86405f2672b98d52e9d5244e133244885c4ce0d4f9087da9433a09f914f > tmp_tx_cfile
chksum_ref="0bd65ea014d3210c1b9a7d7d5af78bc4e4b4384b4f3f7f5674e8d6447e4112c3" 
chksum_prep

echo "=== TESTCASE 4b: ./tcls_verify_sig.sh -p p2 -s sig2 -d d2 " | tee -a $logfile
echo "./tcls_verify_sig.sh -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0 -s 3044022069f4f02bd808eb5381a8bc5b6e3a18219089f83b10b25277345439c52dfb42e30220107a09ad1aff0e20fd5c07b71d536943d72ca15c6e86f77282fe75478a64a466 -d e09e861272e2377a4528fbe28d1ee764706ca4b829aad7e08f4a0325e25c9053" >> $logfile
./tcls_verify_sig.sh -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0 -s 3044022069f4f02bd808eb5381a8bc5b6e3a18219089f83b10b25277345439c52dfb42e30220107a09ad1aff0e20fd5c07b71d536943d72ca15c6e86f77282fe75478a64a466 -d e09e861272e2377a4528fbe28d1ee764706ca4b829aad7e08f4a0325e25c9053 > tmp_tx_cfile
chksum_ref="0bd65ea014d3210c1b9a7d7d5af78bc4e4b4384b4f3f7f5674e8d6447e4112c3" 
chksum_prep

echo "=== TESTCASE 4c: ./tcls_verify_sig.sh -p p3 -s sig3 -d d3 " | tee -a $logfile
echo "./tcls_verify_sig.sh -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0 -s 3044022058c884db944e2265f013493d98a56c958a86aeacc6655473a8cf477fac31f375022026b5915ed26e0149effac955ac30ba90ca25919072ab5a20a161575a55a8bc30 -d c5bfe4a6c58fb2e0398006b4109cdea737eb1413a127c5e61039a8858367750b" >> $logfile
./tcls_verify_sig.sh -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0 -s 3044022058c884db944e2265f013493d98a56c958a86aeacc6655473a8cf477fac31f375022026b5915ed26e0149effac955ac30ba90ca25919072ab5a20a161575a55a8bc30 -d c5bfe4a6c58fb2e0398006b4109cdea737eb1413a127c5e61039a8858367750b > tmp_tx_cfile
chksum_ref="0bd65ea014d3210c1b9a7d7d5af78bc4e4b4384b4f3f7f5674e8d6447e4112c3" 
chksum_prep

echo "=== TESTCASE 4d: ./tcls_verify_sig.sh -p p4 -s sig4 -d d4 " | tee -a $logfile
echo "./tcls_verify_sig.sh -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0 -s 304402202adca291dd1c4058f124c01218e6d34e5a968de6fb932a4237fd33c5aa26930a0220493502e86bf6684593d5ea888f112503ed7ae054a1f4fa62d38df76898a6731e -d 64623a854acfc3e9ba5761a1209af9f3162d360b4eaff7f5c2d19010fa30f418" >> $logfile
./tcls_verify_sig.sh -p 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0 -s 304402202adca291dd1c4058f124c01218e6d34e5a968de6fb932a4237fd33c5aa26930a0220493502e86bf6684593d5ea888f112503ed7ae054a1f4fa62d38df76898a6731e -d 64623a854acfc3e9ba5761a1209af9f3162d360b4eaff7f5c2d19010fa30f418 > tmp_tx_cfile
chksum_ref="0bd65ea014d3210c1b9a7d7d5af78bc4e4b4384b4f3f7f5674e8d6447e4112c3" 
chksum_prep

echo "######################################################" | tee -a $logfile
echo "### we cross check with openssl directly           ###" | tee -a $logfile
echo "### openssl pkeyutl <tx_hash.hex -verify -pubin    ###" | tee -a $logfile
echo "###         -inkey pubkey.pem -sigfile tx_sig.hex  ###" | tee -a $logfile
echo "######################################################" | tee -a $logfile
# The pubkey is: 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0 
printf 3036301006072a8648ce3d020106052b8104000a032200 > pubkey.txt
printf 03cc5debc62369bd861900b167bc6add5f1a6249bdab4146d5ce698879988dced0 >> pubkey.txt
printf $(sed 's/[[:xdigit:]]\{2\}/\\x&/g' <pubkey.txt) | openssl pkey -pubin -inform der >pubkey.pem

echo "=== TESTCASE 4a: openssl pkeyutl ... " | tee -a $logfile
echo "TX_IN[0]:" >> $logfile
echo 6f13d86405f2672b98d52e9d5244e133244885c4ce0d4f9087da9433a09f914f > tx_hash.txt
echo 304502210086199572c8e5879fa610bd244c7b2d054c389ed8b023f0a3d11f25606773e3f5022037086414c32a875fc2d43ec30664edbce447836e25f68ec39a3d04fd03590b57 > tx_sig.txt
# xxd -r -p <tx_hash.txt >tx_hash.hex
# xxd -r -p <tx_sig.txt >tx_sig.hex
printf $(sed 's/[[:xdigit:]]\{2\}/\\x&/g' <tx_hash.txt) >tx_hash.hex
printf $(sed 's/[[:xdigit:]]\{2\}/\\x&/g' <tx_sig.txt) >tx_sig.hex
openssl pkeyutl <tx_hash.hex -verify -pubin -inkey pubkey.pem -sigfile tx_sig.hex  | tee -a $logfile
 
echo "=== TESTCASE 4b: openssl pkeyutl ... " | tee -a $logfile
echo e09e861272e2377a4528fbe28d1ee764706ca4b829aad7e08f4a0325e25c9053 > tx_hash.txt
echo 3044022069f4f02bd808eb5381a8bc5b6e3a18219089f83b10b25277345439c52dfb42e30220107a09ad1aff0e20fd5c07b71d536943d72ca15c6e86f77282fe75478a64a466 > tx_sig.txt
printf $(sed 's/[[:xdigit:]]\{2\}/\\x&/g' <tx_hash.txt) >tx_hash.hex
printf $(sed 's/[[:xdigit:]]\{2\}/\\x&/g' <tx_sig.txt) >tx_sig.hex
openssl pkeyutl <tx_hash.hex -verify -pubin -inkey pubkey.pem -sigfile tx_sig.hex  | tee -a $logfile
 
echo "=== TESTCASE 4c: openssl pkeyutl ... " | tee -a $logfile
echo c5bfe4a6c58fb2e0398006b4109cdea737eb1413a127c5e61039a8858367750b > tx_hash.txt
echo 3044022058c884db944e2265f013493d98a56c958a86aeacc6655473a8cf477fac31f375022026b5915ed26e0149effac955ac30ba90ca25919072ab5a20a161575a55a8bc30 > tx_sig.txt
printf $(sed 's/[[:xdigit:]]\{2\}/\\x&/g' <tx_hash.txt) >tx_hash.hex
printf $(sed 's/[[:xdigit:]]\{2\}/\\x&/g' <tx_sig.txt) >tx_sig.hex
openssl pkeyutl <tx_hash.hex -verify -pubin -inkey pubkey.pem -sigfile tx_sig.hex  | tee -a $logfile
 
echo "=== TESTCASE 4d: openssl pkeyutl ... " | tee -a $logfile
echo 64623a854acfc3e9ba5761a1209af9f3162d360b4eaff7f5c2d19010fa30f418 > tx_hash.txt
echo 304402202adca291dd1c4058f124c01218e6d34e5a968de6fb932a4237fd33c5aa26930a0220493502e86bf6684593d5ea888f112503ed7ae054a1f4fa62d38df76898a6731e > tx_sig.txt
printf $(sed 's/[[:xdigit:]]\{2\}/\\x&/g' <tx_hash.txt) >tx_hash.hex
printf $(sed 's/[[:xdigit:]]\{2\}/\\x&/g' <tx_sig.txt) >tx_sig.hex
openssl pkeyutl <tx_hash.hex -verify -pubin -inkey pubkey.pem -sigfile tx_sig.hex  | tee -a $logfile
 
echo " " | tee -a $logfile
}


testcase5() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 5: strictly testing signatures...               ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 5a: R and S-Value of signature <= N/2 ... " | tee -a $logfile
echo "./tcls_strict_sig_verify.sh -v 30440220443ad3e0b7a1ee2e7b2341ef0e9f35664d5a664aefb622f2c686ca4836a2d48902205aef0722370bfe315758f4a6b9c656b07471e33d1b30c7c224e07228c701114501" >> $logfile
./tcls_strict_sig_verify.sh -v 30440220443ad3e0b7a1ee2e7b2341ef0e9f35664d5a664aefb622f2c686ca4836a2d48902205aef0722370bfe315758f4a6b9c656b07471e33d1b30c7c224e07228c701114501 > tmp_tx_cfile
chksum_ref="5b40890a5590e3e5b54e2cce637e2a3788b8354469101254cec2e5d21fc266d7" 
chksum_prep
 
echo "=== TESTCASE 5b: R and S-Value are zero padded ... " | tee -a $logfile
echo "./tcls_strict_sig_verify.sh -v 304602210090c4fc2369cf225559c1141a1e9be3d7598f0fb7affe8a29f86e737972c7587a022100cbd8619ecae3baa40fdb565014fdac28a95deb90c0fcd4adcbd97d58d0e96f98" >> $logfile
./tcls_strict_sig_verify.sh -v 304602210090c4fc2369cf225559c1141a1e9be3d7598f0fb7affe8a29f86e737972c7587a022100cbd8619ecae3baa40fdb565014fdac28a95deb90c0fcd4adcbd97d58d0e96f98> tmp_tx_cfile
chksum_ref="6f6056fa6fbe6cc389cd3e28351c95b14fc05eb60e88475ae9b75f20dbd48efa" 
chksum_prep
 
echo "=== TESTCASE 5c - error: R-Value of signature >= N/2 ... " | tee -a $logfile
echo "./tcls_strict_sig_verify.sh -v 30440220843ad3e0b7a1ee2e7b2341ef0e9f35664d5a664aefb622f2c686ca4836a2d48902205aef0722370bfe315758f4a6b9c656b07471e33d1b30c7c224e07228c701114501" >> $logfile
./tcls_strict_sig_verify.sh -v 30440220843ad3e0b7a1ee2e7b2341ef0e9f35664d5a664aefb622f2c686ca4836a2d48902205aef0722370bfe315758f4a6b9c656b07471e33d1b30c7c224e07228c701114501 > tmp_tx_cfile
chksum_ref="e2236c7ea3ffc39015417fc40d3cd6957111f38fe08f088dad2f2e4045ee5442" 
chksum_prep
 
echo "=== TESTCASE 5d - error: S-Value of signature >= N/2 ... " | tee -a $logfile
echo "./tcls_strict_sig_verify.sh -v 30440220443ad3e0b7a1ee2e7b2341ef0e9f35664d5a664aefb622f2c686ca4836a2d48902208aef0722370bfe315758f4a6b9c656b07471e33d1b30c7c224e07228c701114501" >> $logfile
./tcls_strict_sig_verify.sh -v 30440220443ad3e0b7a1ee2e7b2341ef0e9f35664d5a664aefb622f2c686ca4836a2d48902208aef0722370bfe315758f4a6b9c656b07471e33d1b30c7c224e07228c701114501 > tmp_tx_cfile
chksum_ref="280da6542732fd4d76b81b098ced5f5e4504d5b60599a84bfc6e18b745b93c38" 
chksum_prep
 
echo "=== TESTCASE 5e - error: R and S-Value of signature >= N/2 ... " | tee -a $logfile
echo "./tcls_strict_sig_verify.sh -v 30440220843ad3e0b7a1ee2e7b2341ef0e9f35664d5a664aefb622f2c686ca4836a2d48902208aef0722370bfe315758f4a6b9c656b07471e33d1b30c7c224e07228c701114501" >> $logfile
./tcls_strict_sig_verify.sh -v 30440220843ad3e0b7a1ee2e7b2341ef0e9f35664d5a664aefb622f2c686ca4836a2d48902208aef0722370bfe315758f4a6b9c656b07471e33d1b30c7c224e07228c701114501 > tmp_tx_cfile
chksum_ref="e123adb190118565c39149e6bf77710791bb5fa9715297a70eb1e1534044ddf0" 
chksum_prep
 
echo " " | tee -a $logfile
}


all_testcases() {
  testcase1 
  testcase2 
  testcase3 
  testcase4 
  testcase5 
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
for i in p*; do
  if [ -f "$i" ]; then rm $i ; fi
done
for i in tx*; do
  if [ -f "$i" ]; then rm $i ; fi
done
