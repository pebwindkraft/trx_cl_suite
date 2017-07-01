#!/bin/sh
# some testcases for the shell script "tcls_create.sh" 
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

create_cmd=tcls_create.sh

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
  cat tmp_cfile >> $logfile
  echo " " >> $logfile
}

chksum_prep() {
result=$( $chksum_cmd tmp_cfile | cut -d " " -f 2 )
chksum_verify "$result" "$chksum_ref" 
if [ $LOG -eq 1 ] ; then to_logfile ; fi
}

testcase1() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 1: get the checksums of all necessary files     ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile

echo "=== TESTCASE 1a: $chksum_cmd tcls_create.sh" | tee -a $logfile
cp tcls_create.sh tmp_cfile
chksum_ref="8be77a2366aa8eb1c215dc47a01757661d7a89a62132124391ae19dfedc59d7f" 
chksum_prep

echo "=== TESTCASE 1b: $chksum_cmd tcls_key2pem.sh" | tee -a $logfile
cp tcls_key2pem.sh tmp_cfile
chksum_ref="736af2ceeb382639f271abfe8cde580ebce816b98ae149037a95a2268ba7d893" 
chksum_prep

echo "=== TESTCASE 1c: $chksum_cmd tcls_verify_bc_address.awk" | tee -a $logfile
cp tcls_verify_bc_address.awk tmp_cfile
chksum_ref="c944ff89ff49454ca03b0ea8f3ce8ebbd44e33e8d87ab48ae00ad4d6544099f6" 
chksum_prep

echo "=== TESTCASE 1d: $chksum_cmd tcls_verify_hexkey.awk" | tee -a $logfile
cp tcls_verify_hexkey.awk tmp_cfile
chksum_ref="055b79074a8f33d0aa9aa7634980d29f4e3eb0248a730ea784c7a88e64aa7cfd" 
chksum_prep " " | tee -a $logfile

echo "   " | tee -a $logfile
}

testcase2() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 2: -c parameters testing ...                    ===" | tee -a $logfile
echo "=== spend from: 16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM            ===" >> $logfile
echo "=== spend to:   1runeksijzfVxyrpiyCY2LCBvYsSiFsCm            ===" >> $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 2a: manually create a simple unsigned, raw trx"      | tee -a $logfile
echo "./$create_cmd -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_cfile
chksum_ref="4306ec5d3ccc1292257889721ffe0d3c563d906a40368e9b16faa37bf5778cf2" 
chksum_prep

echo "=== TESTCASE 2b: -c and -f params - that clashes" | tee -a $logfile
echo "./$create_cmd -v -c -f 76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -v -c -f 76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_cfile
chksum_ref="bd3bc223b2e274b0f634aaffc1c6584c330e94ebfd42cc647d153428c1b1186a" 
chksum_prep

echo "=== TESTCASE 2c: -c and -m params - that clashes" | tee -a $logfile
echo "./$create_cmd -v -c -m 76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -v -c -m 76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_cfile
chksum_ref="bd3bc223b2e274b0f634aaffc1c6584c330e94ebfd42cc647d153428c1b1186a" 
chksum_prep

echo "=== TESTCASE 2d: -c and -t params - that clashes" | tee -a $logfile
echo "./$create_cmd -v -c -t 76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -v -c -t 76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_cfile
chksum_ref="bd3bc223b2e274b0f634aaffc1c6584c330e94ebfd42cc647d153428c1b1186a" 
chksum_prep

echo "=== TESTCASE 2e: same as 2a, with verbose output" | tee -a $logfile
echo "./$create_cmd -v -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -v -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_cfile
chksum_ref="f6fccfdd8997dda8304c7a79fe3b4d2d25c0e03d71c73c1dd53db53ce28effe9" 
chksum_prep

echo "=== TESTCASE 2f: same as 2a, with very verbose output" | tee -a $logfile
echo "### amount to spend (trx_output, in Satoshis):         99900000 ###" >> $logfile
echo "### proposed TX-FEE (@ 50 Satoshi/Byte * 319 TX_bytes):   15950 ###" >> $logfile
echo "./$create_cmd -vv -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -vv -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_cfile
chksum_ref="0e75fab45b51a94c491e53c1c9c8e29d0c79a4677e5aa9f6720334b517117606" 
chksum_prep

echo " " | tee -a $logfile
}

testcase3() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 3: intensive param '-r' testing ...             ===" | tee -a $logfile
echo "=== spend from: 1MBngSqZbMydscpzSoehjP8kznMaHAzh9y           ===" >> $logfile
echo "=== spend to:   14zWNsgUMmHhYx4suzc2tZD6HieGbkQi5s           ===" >> $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 3a: only 1 param ... " | tee -a $logfile
echo "$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be" >> $logfile
./$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be > tmp_cfile
chksum_ref="c980c484e62cd55b8e242db360b20c48a5e66cc1a7c19004c94c54d1ff2ec308"
chksum_prep

echo "=== TESTCASE 3b: only 2 params... " | tee -a $logfile
echo "$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0" >> $logfile
./$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0 > tmp_cfile
chksum_ref="c03a11c1be69150245ea756be59298820bad9e2a9a3f41a15a45f29341700626"
chksum_prep

echo "=== TESTCASE 3c: only 3 params... " | tee -a $logfile
echo "$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac" >> $logfile
./$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac > tmp_cfile
chksum_ref="c03a11c1be69150245ea756be59298820bad9e2a9a3f41a15a45f29341700626"
chksum_prep

echo "=== TESTCASE 3d: only 4 params... " | tee -a $logfile
echo "$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac 118307" >> $logfile
./$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac 118307 > tmp_cfile
chksum_ref="c03a11c1be69150245ea756be59298820bad9e2a9a3f41a15a45f29341700626"
chksum_prep

echo "=== TESTCASE 3e: all params, but TX_IN is char, not numeric... " | tee -a $logfile
echo "$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be A 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac 118307 14zWNsgUMmHhYx4suzc2tZD6HieGbkQi5s" >> $logfile
./$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be A 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac 118307 14zWNsgUMmHhYx4suzc2tZD6HieGbkQi5s > tmp_cfile
chksum_ref="968a532af30367f572bacd5d06f16cdb19f09966c6b14af87630b0f5dd566fa1"
chksum_prep

echo "=== TESTCASE 3f: all params, but AMOUNT is char, not numeric... " | tee -a $logfile
echo "$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac AMOUNT 14zWNsgUMmHhYx4suzc2tZD6HieGbkQi5s" >> $logfile
./$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac AMOUNT 14zWNsgUMmHhYx4suzc2tZD6HieGbkQi5s > tmp_cfile
chksum_ref="6825e38208a876fe8f0c34671d6fe7353be2b9b990bceef72f80dd698610f0df"
chksum_prep

echo "=== TESTCASE 3g: all params, all correct, should run ok ... " | tee -a $logfile
echo "$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac 118307 14zWNsgUMmHhYx4suzc2tZD6HieGbkQi5s" >> $logfile
./$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac 118307 14zWNsgUMmHhYx4suzc2tZD6HieGbkQi5s > tmp_cfile
chksum_ref="6c3341a2e4e945684d8c95e164a63cb0207f6e84882f066c4f50d1aa745c273e"
chksum_prep

echo " " | tee -a $logfile
}

testcase4() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 4: 4a, 4b and 4c not ok, 4d ok                  ===" | tee -a $logfile
echo "=== spend from: 1CAue7dQ2ASD6Wj9ZUWJABdC2zteiCe5cK           ===" >> $logfile
echo "=== spend to:   12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM           ===" >> $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 4a: wrong bitcoin adress hash (x at end)"            | tee -a $logfile
echo "./$create_cmd -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdMx" >> $logfile
./$create_cmd -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdMx > tmp_cfile
chksum_ref="28b7b946f9221044c71ec09d3b3c1b16c4fff26f089931a9d568763d1aa9421a" 
chksum_prep

echo "=== TESTCASE 4b: same as 4a, with verbose output" | tee -a $logfile
echo "./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdMx" >> $logfile
./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdMx > tmp_cfile
chksum_ref="c40ed54979f0629df03ed0343a1533597a95c6094863610a2e5244456f429463" 
chksum_prep

echo "=== TESTCASE 4c: same as 4a, with very verbose output" | tee -a $logfile
echo "./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdMx" >> $logfile
./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdMx > tmp_cfile
chksum_ref="e64bb0797032e18a9c720086cefa78dbe876b205316209ff347a06edaf9d14ec" 
chksum_prep

echo "=== TESTCASE 4d: and now with correct bitcoin adress hash" | tee -a $logfile
echo "### amount to spend (trx_output, in Satoshis):           100000 ###" >> $logfile 
echo "### proposed TX-FEE (@ 50 Satoshi/Byte * 321 TX_bytes):   16050 ###" >> $logfile
echo "./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="507f1e00bcf4fccd78466842a21f6e8f2ffeffcfa0de8ffbe9b38489336ceaac" 
chksum_prep
echo " " | tee -a $logfile
}

testcase5() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 5: Addresses with leading 1s ...                ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 5a: 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM " | tee -a $logfile
echo "./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="50bcb094a96df626bad9917350578f4b19afebb506814d9c603351094be53a06"
chksum_prep

echo "=== TESTCASE 5b: 112ZbzFcSpcCoY2EfPNmgxFmv4tVuLSoB4 " | tee -a $logfile
echo "./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 112ZbzFcSpcCoY2EfPNmgxFmv4tVuLSoB4" >> $logfile
./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 112ZbzFcSpcCoY2EfPNmgxFmv4tVuLSoB4 > tmp_cfile
chksum_ref="4aac7ca086ff6fbef81a6f92ce960af6396f15bf522027b8db3eb643d29941bc"
chksum_prep

echo "=== TESTCASE 5c: 1111DAYXhoxZx2tsRnzimfozo783x1yC2" | tee -a $logfile
echo "./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 1111DAYXhoxZx2tsRnzimfozo783x1yC2 " >> $logfile
./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 1111DAYXhoxZx2tsRnzimfozo783x1yC2 > tmp_cfile
chksum_ref="39ba2900c21dc80808d65fcbc23dee497ab59cd19e0a26a0132a663ae830fd21"
chksum_prep

echo "=== TESTCASE 5d: 1111VHuXEzHaRCgXbVwojtaP7Co3QABb" | tee -a $logfile
echo "./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 1111VHuXEzHaRCgXbVwojtaP7Co3QABb " >> $logfile
./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 1111VHuXEzHaRCgXbVwojtaP7Co3QABb > tmp_cfile
chksum_ref="7e08fafeebf112d5036f9f210ce3176718c8764f5692f9f4b8bf8d9a6f4ea81e"
chksum_prep

echo "=== TESTCASE 5e: 1111KiuFyqUXJFji8KQnoHC5Rtqa5d5e" | tee -a $logfile
echo "./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 1111KiuFyqUXJFji8KQnoHC5Rtqa5d5e " >> $logfile
./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 1111KiuFyqUXJFji8KQnoHC5Rtqa5d5e > tmp_cfile
echo "./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u" >> $logfile
./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u >> tmp_cfile
chksum_ref="02156c1fe47e2cf18ee9b7b4ff2feeb3517c9955a1a409dce0bed7350bb0e54c"
chksum_prep

echo "=== TESTCASE 5f: 1111LexYVhKvaQY69Paj774F9gnjhDrr " | tee -a $logfile
echo "./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 1111LexYVhKvaQY69Paj774F9gnjhDrr" >> $logfile
./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 1111LexYVhKvaQY69Paj774F9gnjhDrr > tmp_cfile
echo "./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u" >> $logfile
./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u >> tmp_cfile
chksum_ref="ef458fbe660f988ff6feb367339645efd25bd562b416fbd6ad190adedded9c1c"
chksum_prep

echo "=== TESTCASE 5g: 111113CRATaaDmCcWzokzTGhM886kj2bs" | tee -a $logfile
echo "./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 111113CRATaaDmCcWzokzTGhM886kj2bs " >> $logfile
./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 111113CRATaaDmCcWzokzTGhM886kj2bs > tmp_cfile
echo "./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u" >> $logfile
./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u >> tmp_cfile
chksum_ref="bdd5dad56d6a8f3ef8129d85884c3549d9ba869b8f6814bf8ac23c8ae7176b96"
chksum_prep

echo "=== TESTCASE 5h: 1111111111111111111114oLvT2 " | tee -a $logfile
echo "./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 1111111111111111111114oLvT2 " >> $logfile
./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 1111111111111111111114oLvT2 > tmp_cfile
echo "./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u" >> $logfile
./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u >> tmp_cfile
chksum_ref="8ae89d769148ead7e8f68a7865b34d015193364dbcf3b7e1aa2c3cf4d5faabd3" 
chksum_prep

echo " " | tee -a $logfile
}

testcase6() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 6: usage of param '-t'                          ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 6a: read a transaction from the network"             | tee -a $logfile
echo "=== when reading from network (-t), then the txfees must change." >> $logfile
echo "=== fee value from bitcoinfees.21.co is different than program  " >> $logfile
echo "=== defaults (50 Satoshi/byte), e.g.:"                            >> $logfile
echo "## amount of trx input(s) (in Satoshis):              1100000 ##" >> $logfile
echo "## amount to spend (trx_output, in Satoshis):         1099999 ##" >> $logfile
echo "## proposed TX-FEE (@ 140 Satoshi/Byte * 319 TX_bytes): 44660 ##" >> $logfile
echo "##                  ^^^^^^^^^^^^^^^^^ this must have changed!   " >> $logfile
echo "## and last line should be:"                                      >> $logfile
echo "## ... ERROR: input insufficient, to cover trx fees, ..."         >> $logfile

echo "./$create_cmd -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1099999 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1099999 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="0000000000000000000000000000000000000000000000000000000000000000" 
head -n8 tmp_cfile > tmp_cfile1
grep "proposed TX-FEE (@ 50 Satoshi/Byte" tmp_cfile
if [ $? -eq 1 ] ; then 
  tail -n 2 tmp_cfile | grep "ERROR: input insufficient" > /dev/null
  if [ $? -eq 0 ] ; then 
    echo "   ### good, Satoshi/Bytes value is different," >> $logfile
    echo "   ### and we have the error at the end"        >> $logfile
    chksum_ref="b0f3f3a5282a2ea18b00c020494afeb3a34ddf67d6df7a0cd4a64b05b59efcd5"
  fi
fi
mv tmp_cfile1 tmp_cfile
chksum_prep

echo "=== TESTCASE 6b: nearly same as 6a, different value" | tee -a $logfile
echo "===   from: 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM"      >> $logfile
echo "===   to:   12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM"      >> $logfile
echo "./$create_cmd -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1099999 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1099999 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile1
head -n32 tmp_cfile1 > tmp_cfile
echo "## need to remove last three lines, cause parameter "     >> $logfile
echo "## for txfee can change on network. Last line should be:" >> $logfile
echo "## ... ERROR: input insufficient, to cover trx fees, ..." >> $logfile
chksum_ref="9f2c963d825c87473f11587d19766d9e7266c1840639720665705da9d4c4530c" 
chksum_prep

echo "=== TESTCASE 6c: same as 6b, with parameter for TRXFEE" | tee -a $logfile
echo "===   proposed TX-FEE (@ 77 Satoshi/Byte * 319 tx_bytes): 24563"  >> $logfile
echo "===   *** possible value to return address:                 437"  >> $logfile
echo "===   *** without return address, txfee will be:          25000"  >> $logfile
echo "./$create_cmd -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1075000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 77" >> $logfile
./$create_cmd -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1075000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 77 > tmp_cfile
chksum_ref="5168db68ffd262998daa8b7d5a6d803cb2985751fdd78692987fec1dd154a0cb" 
chksum_prep

echo "=== TESTCASE 6d: same as 6b, with parameter for a return address" | tee -a $logfile
echo "===   proposed TX-FEE (@ 50 Satoshi/Byte * 387 tx_bytes): 19350 " >> $logfile
echo "===   value to return address:                             2873 " >> $logfile
echo "===   return address: 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm         " >> $logfile
echo "./$create_cmd -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 999999 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 50 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 999999 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 50 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_cfile
chksum_ref="ccea1cf04c4a482a13ee3deb71d6e1e39dc7a366b1728a35d1abf4c403086fd5" 
chksum_prep

echo "=== TESTCASE 6e: same as 6d, VERBOSE output" | tee -a $logfile
echo "=== proposed TX-FEE (@ 50 Satoshi/Byte * 387 TX_bytes):  19350" >> $logfile
echo "=== value to return address:                             80651" >> $logfile
echo "./$create_cmd -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 999999 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 50 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 999999 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 50 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_cfile
chksum_ref="660b99d1fb18804f0ad368866138a40dfa1cd6dffe299b8329f68580442a4f31" 
chksum_prep

echo "=== TESTCASE 6f: same as 6d, VERY VERBOSE output" | tee -a $logfile
echo "=== proposed TX-FEE (@ 50 Satoshi/Byte * 387 TX_bytes):  19350" >> $logfile
echo "=== value to return address:                             80651" >> $logfile
echo "./$create_cmd -vv -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 999999 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 50 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -vv -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 999999 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 50 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_cfile
chksum_ref="14737c3b0bd2e854db8baa16b71a5e89d410144b9ec0409b487c5becfddb611e" 
chksum_prep

echo " " | tee -a $logfile
}

testcase7() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 7: several trx with wrong parameters:           ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 7a: insufficient input" | tee -a $logfile
echo "===              amount of trx input(s) (in Satoshis):    59372 " >> $logfile
echo "===              desired amount to spend (in Satoshis):   70000 " >> $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 19235" > tmp_3inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 16197" >> tmp_3inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 23940" >> tmp_3inputs.txt
echo "./$create_cmd -v -f tmp_3inputs.txt 70000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
./$create_cmd -v -f tmp_3inputs.txt 70000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM > tmp_cfile
chksum_ref="e8837815cf2f44e47f4f57ba9288c608825a90b8ed0adedc9b302946e9573c72" 
chksum_prep

echo "=== TESTCASE 7b: wrong output address (x at the end)" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 19235" > tmp_3inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 16197" >> tmp_3inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 23940" >> tmp_3inputs.txt
echo "./$create_cmd -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcx" >> $logfile
./$create_cmd -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcx > tmp_cfile
chksum_ref="2a56205032858fe92365032175fb04dd23c4150f5742a5d2512b590b3e443c64" 
chksum_prep

echo "=== TESTCASE 7c: wrong length of trx hash (63 chars)" | tee -a $logfile
echo "4fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 39235" > tmp_3inputs.txt
echo "3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 16197" >> tmp_3inputs.txt
echo "74cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 23940" >> tmp_3inputs.txt
echo "./$create_cmd -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
./$create_cmd -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM > tmp_cfile
chksum_ref="5ab2b820286469f40a4d61039d8060662eec04af4b18629304350db11e7c832a" 
chksum_prep

echo "=== TESTCASE 7d: insufficient trx fee" | tee -a $logfile
echo "=== proposed TX-FEE (@ 50 Satoshi/Byte * 763 tx_bytes):    38150" >> $logfile
echo "=== Achieving negative value with this txfee:               -900" >> $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 39255" > tmp_3inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 19999" >> tmp_3inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 27996" >> tmp_3inputs.txt
echo "./$create_cmd -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 50" >> $logfile
./$create_cmd -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 50 > tmp_cfile
chksum_ref="805e5cc495c567838b707be3f999a751e47c40f73f9ae6f0a81cee3d833debc3" 
chksum_prep

echo "=== TESTCASE 7e: wrong return address (x at the end)" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 39235" > tmp_3inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 26197" >> tmp_3inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 23940" >> tmp_3inputs.txt
echo "./$create_cmd -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 50 16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvx" >> $logfile
./$create_cmd -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 50 16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvx > tmp_cfile
chksum_ref="e15f11c9940fbfe6f54edf26bf8bf01017aa096e483b487a5835c9e73f9ff073"
chksum_prep

echo "=== TESTCASE 7f: a spend from 1JmPRD_unspent.txt     " | tee -a $logfile
echo "=== 4 inputs from: 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
echo "===            to: 13GnHB51piDBf1avocPL7tSKLugK4F7U2B" >> $logfile
echo "=== proposed TX-FEE (@ 32 Satoshi/Byte * 985 tx_bytes):    31520" >> $logfile
echo "=== *** possible value to return address:                    480" >> $logfile
echo "=== *** without return address, txfee will be:             32000" >> $logfile
echo "48d2c9c76dc282eb7075a0fce543b9d615c0c2d5b78b41603c2d6cf46e2e77b0 1 76a914c2df275d78e506e17691fd6f0c63c43d15c897fc88ac 120000" > tmp_4inputs.txt
echo "811848214a52c823f53eaaa302eaddb7dd2b03874174c9202d291ac35868fb74 1 76a914c2df275d78e506e17691fd6f0c63c43d15c897fc88ac 500000" >> tmp_4inputs.txt
echo "bb745b565d23c2041022392469114cbd94d29d941e1c6860c609b5ed6ee321cc 0 76a914c2df275d78e506e17691fd6f0c63c43d15c897fc88ac 113000" >> tmp_4inputs.txt
echo "e84959a7148737df867d6c83f3683abeb977c297729ccbd609d54ee0879491ea 0 76a914c2df275d78e506e17691fd6f0c63c43d15c897fc88ac 120000" >> tmp_4inputs.txt
echo "./$create_cmd -vv -f tmp_4inputs.txt 821000 13GnHB51piDBf1avocPL7tSKLugK4F7U2B 32" >> $logfile
./$create_cmd -vv -f tmp_4inputs.txt 821000 13GnHB51piDBf1avocPL7tSKLugK4F7U2B 32 > tmp_cfile
chksum_ref="456dc2d75a500b630a774f36ffe4108dac58bf879a9eacb0f27d934075923044"
chksum_prep

echo " " | tee -a $logfile
}

testcase8() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 8: some multi input trx with 3, 5 and 20 inputs ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 8a: 3 inputs to a trx"                               | tee -a $logfile
echo "=== proposed TX-FEE (@ 25 Satoshi/Byte * 1207 TX_bytes):   38150" >> $logfile
echo "=== *** possible value to return address:                      2" >> $logfile
echo "=== *** without return address, txfee will be:             38152" >> $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 49265" > tmp_3inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 18887" >> tmp_3inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 50000" >> tmp_3inputs.txt
echo "./$create_cmd -vv -f tmp_3inputs.txt 80000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
./$create_cmd -vv -f tmp_3inputs.txt 80000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM > tmp_cfile
chksum_ref="196f44365abea755565119bf93875bb644cb5f67c70ebfaee4f6c471246110c7" 
chksum_prep

echo "=== TESTCASE 8b: 5 inputs to a trx" | tee -a $logfile
echo "=== proposed TX-FEE (@ 50 Satoshi/Byte * 1207 TX_bytes):   30175" >> $logfile
echo "=== *** possible value to return address:                      2" >> $logfile
echo "=== *** without return address, txfee will be:             30177" >> $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 39235" >> tmp_5inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 48197" >> tmp_5inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 26940" >> tmp_5inputs.txt
echo "722a2ad4daa66382abe4c54676cfe1299ac52a239b4b79b6c6f66e5c5fefe32c 475 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 6886" >> tmp_5inputs.txt
echo "0d87c9c4146452dd8f97f646b52a9dda5a6645d068aca5f1a2a214d37507c5b5 989 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 19099" >> tmp_5inputs.txt
echo "./$create_cmd -v -f tmp_5inputs.txt 110180 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
./$create_cmd -v -f tmp_5inputs.txt 110180 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM > tmp_cfile
chksum_ref="a193916eb612a40583f0ec491aeeb7950b964f163cebab5617e9d7ec30d4ec0a"
chksum_prep

echo "=== TESTCASE 8c: 23 inputs to a trx" | tee -a $logfile
echo "===  from: 1FyJw3R7cs9TrSXPhh1FnnGmgTMdptPSE7  " >> $logfile
echo "===    to: 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM  " >> $logfile
echo "=== proposed TX-FEE (@ 25 Satoshi/Byte * 5203 TX_bytes):  130075" >> $logfile
echo "=== *** possible value to return address:                      1" >> $logfile
echo "=== *** without return address, txfee will be:            130076" >> $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 119235" >> tmp_23inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 16197" >> tmp_23inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 23940" >> tmp_23inputs.txt
echo "722a2ad4daa66382abe4c54676cfe1299ac52a239b4b79b6c6f66e5c5fefe32c 475 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 6816" >> tmp_23inputs.txt
echo "0d87c9c4146452dd8f97f646b52a9dda5a6645d068aca5f1a2a214d37507c5b5 989 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 19099" >> tmp_23inputs.txt
echo "e90fb95d397c965f4bb7f25e3efc9554aa73b0692b114de5375955fdc7b0308d 771 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 42128" >> tmp_23inputs.txt
echo "c1e162bdd8b2c2e0c68e144b116686e230a1ac2b1cae886fedb8eae4a0b9b4d5 1243 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 11186" >> tmp_23inputs.txt
echo "1dfd30d0ef6c710baff303dc30e056233a9d18e06043471fbf2f364ce203a16d 1063 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 15511" >> tmp_23inputs.txt
echo "a31870644f16e0751fbb8df753e7076755366fe711e9b18ab9ac7696ed47419d 544 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 2730" >> tmp_23inputs.txt
echo "9bfe95cd84bc1adad42d2eb76e605ec587f3308d969e582c7fd00d7d00c0bc93 831 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 16532" >> tmp_23inputs.txt
echo "8b7bd94fa11297f59fdf82923f5e548aa31d9e2a73a2aadb0865dccf3cde6b10 532 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 18588" >> tmp_23inputs.txt
echo "a96ded3a7af074535e58f6ce9b5fadcc9cd4e5a28672c97389b1094c1b8cdfe6 1114 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 22115" >> tmp_23inputs.txt
echo "aece8ad19c4c88906c9bee181a4c021828a5eaf4f5001435989d07a2fe1acaac 513 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 6640" >> tmp_23inputs.txt
echo "fd0faeffc7105159e1ac21f052dd84d2f35e07bf3f897562cdf1d6b914453e1c 1247 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 24986" >> tmp_23inputs.txt
echo "5c31fb9784dc34004664c19a77dac96f08375942fcd058769f46df3fa45420a7 466 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 4285" >> tmp_23inputs.txt
echo "d6dd6411750c74de83babc3cd2188c692c8bab812a50a3ae9ca996f269fdf7c0 520 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 8207" >> tmp_23inputs.txt
echo "7821677c830cad4205d463f781bd068a6bb92382faf21b1a6c7975548a0fc9f5 713 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 5697" >> tmp_23inputs.txt
echo "4aa7a3ad6a56d6afee991ec67ae9b75d7264c484be8dc44fbe32ca200c4fe58f 468 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 29790" >> tmp_23inputs.txt
echo "09b1f67adcc5acb4ec3acd025c6c1dab79efd010b2208a097aa6eefd4fc3be95 508 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 105693" >> tmp_23inputs.txt
echo "c19479c4147c359b9c48fcaeabee5ac77cc7b6ca68f86803d48b051f84804a2f 1174 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 27499" >> tmp_23inputs.txt
echo "64d0d67f0df58f8001b555b3fd02863e3e5a9e1bd69976fd722ee579426ec1f6 592 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 27972" >> tmp_23inputs.txt
echo "8ff75867f8ef344d6ce97053296d21c79ac85b6431aebb5f6abd2eba628b9094 573 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 19729" >> tmp_23inputs.txt
echo "2aaaaaaaaaaaaaad6ce97053296d21c79ac85b6431aebb5f6abd2eba628b9094 111 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 5501" >> tmp_23inputs.txt
echo "./$create_cmd -f tmp_23inputs.txt 450000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
./$create_cmd -f tmp_23inputs.txt 450000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM > tmp_cfile
chksum_ref="b712cc24f4e22deb7193df0c319eb107fc9eb79fdd86cd22d9e64ddc2cd7023a" 
chksum_prep


echo "=== TESTCASE 8d: 53 inputs to a trx" | tee -a $logfile
echo "===  from: 1FyJw3R7cs9TrSXPhh1FnnGmgTMdptPSE7  " >> $logfile
echo "===    to: 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM  " >> $logfile
echo "=== proposed TX-FEE (@ 16 Satoshi/Byte * 12085 TX_bytes): 193360" >> $logfile
echo "=== *** possible value to return address:                      5" >> $logfile
echo "=== *** without return address, txfee will be:            193365" >> $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 119235" >> tmp_53inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 16197" >> tmp_53inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 23940" >> tmp_53inputs.txt
echo "722a2ad4daa66382abe4c54676cfe1299ac52a239b4b79b6c6f66e5c5fefe32c 475 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 6816" >> tmp_53inputs.txt
echo "0d87c9c4146452dd8f97f646b52a9dda5a6645d068aca5f1a2a214d37507c5b5 989 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 19099" >> tmp_53inputs.txt
echo "e90fb95d397c965f4bb7f25e3efc9554aa73b0692b114de5375955fdc7b0308d 771 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 42128" >> tmp_53inputs.txt
echo "c1e162bdd8b2c2e0c68e144b116686e230a1ac2b1cae886fedb8eae4a0b9b4d5 1243 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 11186" >> tmp_53inputs.txt
echo "1dfd30d0ef6c710baff303dc30e056233a9d18e06043471fbf2f364ce203a16d 1063 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 15511" >> tmp_53inputs.txt
echo "a31870644f16e0751fbb8df753e7076755366fe711e9b18ab9ac7696ed47419d 544 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 2730" >> tmp_53inputs.txt
echo "9bfe95cd84bc1adad42d2eb76e605ec587f3308d969e582c7fd00d7d00c0bc93 831 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 16532" >> tmp_53inputs.txt
echo "8b7bd94fa11297f59fdf82923f5e548aa31d9e2a73a2aadb0865dccf3cde6b10 532 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 18588" >> tmp_53inputs.txt
echo "a96ded3a7af074535e58f6ce9b5fadcc9cd4e5a28672c97389b1094c1b8cdfe6 1114 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 22115" >> tmp_53inputs.txt
echo "aece8ad19c4c88906c9bee181a4c021828a5eaf4f5001435989d07a2fe1acaac 513 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 6640" >> tmp_53inputs.txt
echo "fd0faeffc7105159e1ac21f052dd84d2f35e07bf3f897562cdf1d6b914453e1c 1247 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 24986" >> tmp_53inputs.txt
echo "5c31fb9784dc34004664c19a77dac96f08375942fcd058769f46df3fa45420a7 466 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 4285" >> tmp_53inputs.txt
echo "d6dd6411750c74de83babc3cd2188c692c8bab812a50a3ae9ca996f269fdf7c0 520 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 8207" >> tmp_53inputs.txt
echo "7821677c830cad4205d463f781bd068a6bb92382faf21b1a6c7975548a0fc9f5 713 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 5697" >> tmp_53inputs.txt
echo "4aa7a3ad6a56d6afee991ec67ae9b75d7264c484be8dc44fbe32ca200c4fe58f 468 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 29790" >> tmp_53inputs.txt
echo "09b1f67adcc5acb4ec3acd025c6c1dab79efd010b2208a097aa6eefd4fc3be95 508 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 105693" >> tmp_53inputs.txt
echo "c19479c4147c359b9c48fcaeabee5ac77cc7b6ca68f86803d48b051f84804a2f 1174 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 27499" >> tmp_53inputs.txt
echo "64d0d67f0df58f8001b555b3fd02863e3e5a9e1bd69976fd722ee579426ec1f6 592 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 27972" >> tmp_53inputs.txt
echo "8ff75867f8ef344d6ce97053296d21c79ac85b6431aebb5f6abd2eba628b9094 573 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 19729" >> tmp_53inputs.txt
echo "7514be159a9ea2e3c8008af8004b1e83c7680ca38032c487a8e81231c3af4142 476 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 4264" >> tmp_53inputs.txt
echo "1e0126bd3c400347aee4b05893e6d8fd47d2baa106b5426c433482cd61143d49 709 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 41415" >> tmp_53inputs.txt
echo "53dd658c40fbe6adac20064936f2dbc2d705e6e1ab59a123246373b3285d2a79 623 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 21704" >> tmp_53inputs.txt
echo "2541df7a81b1906dc3f9adb64bc2beb4430282d545fa8606d34e89c09264c2d6 698 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 5210" >> tmp_53inputs.txt
echo "edbcab3fd7782568fd4b17fc61bcd546dbb31cb1b035f9092bd3df6f8a2bdfd3 718 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 3398" >> tmp_53inputs.txt
echo "9a4bfa0913dd35b3fe8798e611370d5fc2bdfd2d4015fcb9321295074766ebfd 849 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 15521" >> tmp_53inputs.txt
echo "38647492766f7a0c6c9dce81a5f3f4a11a80db55efa1720025b8314fb2dc8d6c 1213 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 14191" >> tmp_53inputs.txt
echo "38148eb25e5e06d5f033671cbfa9b2e3ca86edb18d92707207583b3791b7f489 1257 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 14425" >> tmp_53inputs.txt
echo "8d0b534b240a2fcb9164bab5009c9a58cca408ef62511e5f0a8d6782699fa1bd 602 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 23361" >> tmp_53inputs.txt
echo "d12c3a79f3f6bbe6d57a148e5d6961d3ae10791f970596e2a40d747461292ab7 439 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 4365" >> tmp_53inputs.txt
echo "9dcadf0f65abd725bde93491e10d47b4b80ebeb4ebf2e9481791f7d903414cfe 268 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 100483" >> tmp_53inputs.txt
echo "2048cdb7230ee02db29d9b02e06ee7dda51a64818ed6714c6b1e1d35cb20d66a 404 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 28144" >> tmp_53inputs.txt
echo "09c9297d076667cc45d3241b19e7bdfad3d5a8878749a80f0f968093e20f22d9 571 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 24716" >> tmp_53inputs.txt
echo "5f4012583ea210db6e201da20777240b32b21086105f65c117a7afe0f43ef1b1 1153 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 15844" >> tmp_53inputs.txt
echo "aa41f537c086b7a8286601b89810900985d9f3aea17d27c1db4c5dfdae4721a6 733 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 3033" >> tmp_53inputs.txt
echo "9fb7bd72bad3b82097bb65243e01e5ab45ec549c4b155b9bdd9ffe8ad7887c48 406 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 15580" >> tmp_53inputs.txt
echo "b14b007c4a384fcf4073e4f05edb1cc7074b3f0160009107c265047e39c6da5b 792 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 16708" >> tmp_53inputs.txt
echo "3ca28bbacf76cb4ef002b2141381cd450a9c6bea01f86b31c681928fc1389517 406 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 11580" >> tmp_53inputs.txt
echo "e79d423f32ff7786fd89ad68f711fdadc68e3efc0727395e197b7a5260365b6b 709 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 40822" >> tmp_53inputs.txt
echo "194518262a5280d4352d1553f64e343caeb2e602c279fd9cf594ccb523eb87bd 1058 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 15240" >> tmp_53inputs.txt
echo "f275ba9db842a034fd08a51dca8042e45056fde0981674bf43648e4b1f1cb534 676 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 40003" >> tmp_53inputs.txt
echo "d25fed56d5cf68a31150b451ad3bc74e43ae8623bd138af1fa949e166aaa0ca7 1160 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 11916" >> tmp_53inputs.txt
echo "4e0b10d608c534e03b2f499ecc07d958567100c1bb082b7d54cd16de389b69fe 737 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 37593" >> tmp_53inputs.txt
echo "7f9f29d762a575405dc79f820607ef5b306bd67051d9900e076044a0ed799f0b 1243 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 11332" >> tmp_53inputs.txt
echo "f47db0ec4fb39256eab313e77b9ee5ec3561fba4ae2557da0b8f96c0470ab48a 427 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 3837" >> tmp_53inputs.txt
echo "8d718b1f1982e8fd40fe6431b2aa91c8754983005991024a9e6681953930a444 417 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 3286" >> tmp_53inputs.txt
echo "fde20ff6f219e203ca567c6ac60c16ae4b35301cbb7aa388715d300226665ed3 423 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 22730" >> tmp_53inputs.txt
echo "02cbaeda78066dc12d273caef84c74dd54f732d489691cf1d213c5b34719cca3 614 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 5191" >> tmp_53inputs.txt
echo "835a00e11146d0130489f7be116da9e836b3adbfa5b375b50dba57785b13cbd5 591 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 24138" >> tmp_53inputs.txt
echo "fbf1d6df19021c6dddad3f35d19b6da3b485fbaa84d9ca77f9580ebdb232eea8 1166 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 15293" >> tmp_53inputs.txt
echo "f46d6ad7b7bef16e65aecae962d96b731a2b638eeb9835382e8bfad8b6224b93 424 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 16020" >> tmp_53inputs.txt
echo "a3b13803b6bce97cfb5d37008d13e686fc5c8ffeca0078e2f49f9da2165576a6 1250 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 25287" >> tmp_53inputs.txt
echo "./$create_cmd -f tmp_53inputs.txt 1017840 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
./$create_cmd -f tmp_53inputs.txt 1017840 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM > tmp_cfile
chksum_ref="655b28d1a7b9c372901d1196d6e966e983460fed854c8d851bf4c30d5e8b1204" 
chksum_prep

echo " " | tee -a $logfile
}

testcase9() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 9: -m parameters testing, for multisig preps    ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 9a: msig, 2of3, only 1 address"                      | tee -a $logfile
echo "./$create_cmd -m 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -m 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_cfile
chksum_ref="d620c60622281751fcdaf04626979282391c6334ef561c60304301abbf883d20"
chksum_prep

echo "=== TESTCASE 9b: msig, 2of3, only 2 addresses" | tee -a $logfile 
echo "./$create_cmd -m 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM" >> $logfile 
./$create_cmd -m 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM > tmp_cfile
chksum_ref="da05d426f21e377f44ef369e2d40ef94aec44921d17e94358800e54a93ff5085"
chksum_prep

echo "=== TESTCASE 9c: msig, 2of16, invalid, max=15" | tee -a $logfile
echo "./$create_cmd -m 2 16 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -m 2 16 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="5b677a956e465008b297f1b490df5fe033de9749674fba11a4ed99445c6963ee"
chksum_prep

echo "=== TESTCASE 9d: msig, 3of2, invalid, 3of2 does not work :-)" | tee -a $logfile
echo "./$create_cmd -v -m 3 2 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -v -m 3 2 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="5fdd9da7e6fb314c8a6cf6eb411d318c5f33cdd643593feabd47056278f1a643"
chksum_prep

echo "=== TESTCASE 9e: -m and -f params - that clashes!" | tee -a $logfile
echo "./$create_cmd -v -m -f 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -v -m -f 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="62710f06f1629cc01a7c5fe1886672bd1540d92450d58f7d4cb5ba2db55f22db"
chksum_prep

echo "=== TESTCASE 9f: -m and -c params - that clashes!" | tee -a $logfile
echo "./$create_cmd -v -m -c 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -v -m -c 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="62710f06f1629cc01a7c5fe1886672bd1540d92450d58f7d4cb5ba2db55f22db"
chksum_prep

echo "=== TESTCASE 9g: -m and -t params - that clashes!" | tee -a $logfile
echo "./$create_cmd -v -m -t 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -v -m -t 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="62710f06f1629cc01a7c5fe1886672bd1540d92450d58f7d4cb5ba2db55f22db"
chksum_prep

echo "=== TESTCASE 9h: msig, 2of3, but wrong bitcoin pubkeys" | tee -a $logfile
echo "./$create_cmd -m 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -m 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="a153effcf31d88179ba8c85ebb4af9e99637f783e823086e852d8741e5cfa36e"
chksum_prep

echo "=== TESTCASE 9i: msig 2of3, uncompressed pubkeys, ok ..."          | tee -a $logfile
echo "    https://gist.githubusercontent.com/gavinandresen/3966071/raw/" >> $logfile
echo "    1f6cfa4208bc82ee5039876b4f065a705ce64df7/TwoOfThree.sh"        >> $logfile
echo "./$create_cmd -v -m 2 3 0491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f86,04865c40293a680cb9c020e7b1e106d8c1916d3cef99aa431a56d253e69256dac09ef122b1a986818a7cb624532f062c1d1f8722084861c5c3291ccffef4ec6874,048d2455d2403e08708fc1f556002f1b6cd83f992d085097f9974ab08a28838f07896fbab08f39495e15fa6fad6edbfb1e754e35fa1c7844c41f322a1863d46213" >> $logfile
./$create_cmd -v -m 2 3 0491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f86,04865c40293a680cb9c020e7b1e106d8c1916d3cef99aa431a56d253e69256dac09ef122b1a986818a7cb624532f062c1d1f8722084861c5c3291ccffef4ec6874,048d2455d2403e08708fc1f556002f1b6cd83f992d085097f9974ab08a28838f07896fbab08f39495e15fa6fad6edbfb1e754e35fa1c7844c41f322a1863d46213 > tmp_cfile
chksum_ref="85cd6861acd8ed8f7a14d399891e10dc04171093e59751d81f5ca9e9a989b87a"
chksum_prep

echo "=== TESTCASE 9j: msig 2of3, uncompressed pubkeys, ok ..." | tee -a $logfile
echo "./$create_cmd -v -m 2 3 04a882d414e478039cd5b52a92ffb13dd5e6bd4515497439dffd691a0f12af9575fa349b5694ed3155b136f09e63975a1700c9f4d4df849323dac06cf3bd6458cd,046ce31db9bdd543e72fe3039a1f1c047dab87037c36a669ff90e28da1848f640de68c2fe913d363a51154a0c62d7adea1b822d05035077418267b1a1379790187,0411ffd36c70776538d079fbae117dc38effafb33304af83ce4894589747aee1ef992f63280567f52f5ba870678b4ab4ff6c8ea600bd217870a8b4f1f09f3a8e83" >> $logfile
./$create_cmd -v -m 2 3 04a882d414e478039cd5b52a92ffb13dd5e6bd4515497439dffd691a0f12af9575fa349b5694ed3155b136f09e63975a1700c9f4d4df849323dac06cf3bd6458cd,046ce31db9bdd543e72fe3039a1f1c047dab87037c36a669ff90e28da1848f640de68c2fe913d363a51154a0c62d7adea1b822d05035077418267b1a1379790187,0411ffd36c70776538d079fbae117dc38effafb33304af83ce4894589747aee1ef992f63280567f52f5ba870678b4ab4ff6c8ea600bd217870a8b4f1f09f3a8e83 > tmp_cfile
chksum_ref="68e5db4aa70e55884e6a673a7f4724393a32b2692e3718ef163b7100b34e0550"
chksum_prep

echo "=== TESTCASE 9k: msig with testnet 2of3, ok ..." | tee -a $logfile
echo "./$create_cmd -T -v -m 2 3 03834bd129bf0a2e03d53b74bc2eef8d9a5faed93f37b4938ae7127d430804a3cf,03fae2fa202fbfd9d0a8650f537df154158761ce9ad2460793aed74b946babb9f4,038cbc733032dcbed878c727840bef9c2aeb01447e1701c372c46a2ef00f48e02c" >> $logfile
./$create_cmd -T -v -m 2 3 03834bd129bf0a2e03d53b74bc2eef8d9a5faed93f37b4938ae7127d430804a3cf,03fae2fa202fbfd9d0a8650f537df154158761ce9ad2460793aed74b946babb9f4,038cbc733032dcbed878c727840bef9c2aeb01447e1701c372c46a2ef00f48e02c > tmp_cfile
chksum_ref="2be34869270668ea187a889fa58ada8e0fa18c939c7f004517b4a7a84c64dffb"
chksum_prep

echo "=== TESTCASE 9l: msig: https://bitcoin.org/en/developer-examples#p2sh-multisig" | tee -a $logfile
echo "./$create_cmd -T -v -m 2 3 03310188e911026cf18c3ce274e0ebb5f95b007f230d8cb7d09879d96dbeab1aff,0243930746e6ed6552e03359db521b088134652905bd2d1541fa9124303a41e956,029e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255" >> $logfile
./$create_cmd -T -v -m 2 3 03310188e911026cf18c3ce274e0ebb5f95b007f230d8cb7d09879d96dbeab1aff,0243930746e6ed6552e03359db521b088134652905bd2d1541fa9124303a41e956,029e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255 > tmp_cfile
chksum_ref="f695a0759c67db60aafded1baa4d577f1073bb0e49b67db876f6aa71afeaaa0a"
chksum_prep

echo "=== TESTCASE 9m: msig: tbd ..." | tee -a $logfile
echo "./$create_cmd -T -v -m 2 3 ..." >> $logfile
./$create_cmd -T -v -m 2 3 ... > tmp_cfile
chksum_ref="b1e36ee999653b286a9dd3854ce822ce266008c398b3df79bf348724314115d8"
chksum_prep

echo " " | tee -a $logfile
}

testcase10() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 10: -r testing, for multisig TX creation (P2SH) ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 10a: msig, -r -c, missing redeem script"             | tee -a $logfile
echo "./$create_cmd -vv -r -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 " >> $logfile
./$create_cmd -vv -r -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 > tmp_cfile
chksum_ref="3a113d66d0eca765a9a643e29d6666660743cd6bf351717743c40ac72ef0f630"
chksum_prep

echo "=== TESTCASE 10b: msig, -r -c, short redeem script (<=20 Bytes)"  | tee -a $logfile
echo "./$create_cmd -vv -r -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1234567890 " >> $logfile
./$create_cmd -vv -r -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1234567890 > tmp_cfile
chksum_ref="2397e5005abae805d4a9526ab1774a52ef80babeb19b5ab719a8f1ae6341c37f"
chksum_prep


echo "=== TESTCASE 10i: msig, copy of 9i, executing with -r ..."        | tee -a $logfile
echo "    https://gist.githubusercontent.com/gavinandresen/3966071/raw/" >> $logfile
echo "    1f6cfa4208bc82ee5039876b4f065a705ce64df7/TwoOfThree.sh"        >> $logfile
echo "./$create_cmd -v -m 2 3 0491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f86,04865c40293a680cb9c020e7b1e106d8c1916d3cef99aa431a56d253e69256dac09ef122b1a986818a7cb624532f062c1d1f8722084861c5c3291ccffef4ec6874,048d2455d2403e08708fc1f556002f1b6cd83f992d085097f9974ab08a28838f07896fbab08f39495e15fa6fad6edbfb1e754e35fa1c7844c41f322a1863d46213" >> $logfile
./$create_cmd -v -m 2 3 0491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f86,04865c40293a680cb9c020e7b1e106d8c1916d3cef99aa431a56d253e69256dac09ef122b1a986818a7cb624532f062c1d1f8722084861c5c3291ccffef4ec6874,048d2455d2403e08708fc1f556002f1b6cd83f992d085097f9974ab08a28838f07896fbab08f39495e15fa6fad6edbfb1e754e35fa1c7844c41f322a1863d46213 > tmp_cfile
ref_redeemscripthash=$( tail -n3 tmp_cfile | head -n1 )
ref_P2SH_address=$( tail -n1 tmp_cfile )
echo "./$create_cmd -vv -r -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 $ref_redeemscripthash " >> $logfile
./$create_cmd -vv -r -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 $ref_redeemscripthash > tmp_cfile
echo "./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u" >> $logfile
./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u > tmp_cfile
redeemscripthash=$( tail -n6 tmp_cfile | head -n 1 | cut -f 5 -d " " )
P2SH_address=$( tail -n4 tmp_cfile | head -n 1 )
echo "reference: $ref_redeemscripthash" > tmp_cfile
echo "reference: $ref_P2SH_address"    >> tmp_cfile
echo "result:    $redeemscripthash"    >> tmp_cfile
echo "result:    $P2SH_address"        >> tmp_cfile
if [ "$ref_P2SH_address" == "$P2SH_address" ] ; then
  echo "ok" >> tmp_cfile
else
  echo "fail" >> tmp_cfile
fi
chksum_ref="ce1999f3d24690da82c17bde52ac0d414e69c8c5c630f2ca9342f1895a662208"
chksum_prep

echo "=== TESTCASE 10j: msig, copy of 9j, executing with -p ..."        | tee -a $logfile
echo "./$create_cmd -v -m 2 3 04a882d414e478039cd5b52a92ffb13dd5e6bd4515497439dffd691a0f12af9575fa349b5694ed3155b136f09e63975a1700c9f4d4df849323dac06cf3bd6458cd,046ce31db9bdd543e72fe3039a1f1c047dab87037c36a669ff90e28da1848f640de68c2fe913d363a51154a0c62d7adea1b822d05035077418267b1a1379790187,0411ffd36c70776538d079fbae117dc38effafb33304af83ce4894589747aee1ef992f63280567f52f5ba870678b4ab4ff6c8ea600bd217870a8b4f1f09f3a8e83" >> $logfile
./$create_cmd -v -m 2 3 04a882d414e478039cd5b52a92ffb13dd5e6bd4515497439dffd691a0f12af9575fa349b5694ed3155b136f09e63975a1700c9f4d4df849323dac06cf3bd6458cd,046ce31db9bdd543e72fe3039a1f1c047dab87037c36a669ff90e28da1848f640de68c2fe913d363a51154a0c62d7adea1b822d05035077418267b1a1379790187,0411ffd36c70776538d079fbae117dc38effafb33304af83ce4894589747aee1ef992f63280567f52f5ba870678b4ab4ff6c8ea600bd217870a8b4f1f09f3a8e83 > tmp_cfile
ref_redeemscripthash=$( tail -n3 tmp_cfile | head -n1 )
ref_P2SH_address=$( tail -n1 tmp_cfile )
echo "./$create_cmd -vv -r -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 $ref_redeemscripthash" >> $logfile
./$create_cmd -vv -r -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 $ref_redeemscripthash > tmp_cfile
echo "./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u" >> $logfile
./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u > tmp_cfile
redeemscripthash=$( tail -n6 tmp_cfile | head -n 1 | cut -f 5 -d " " )
P2SH_address=$( tail -n4 tmp_cfile | head -n 1 )
echo "reference: $ref_redeemscripthash" > tmp_cfile
echo "reference: $ref_P2SH_address"    >> tmp_cfile
echo "result:    $redeemscripthash"    >> tmp_cfile
echo "result:    $P2SH_address"        >> tmp_cfile
if [ "$ref_P2SH_address" == "$P2SH_address" ] ; then
  echo "ok" >> tmp_cfile
else
  echo "fail" >> tmp_cfile
fi
chksum_ref="4583880713530f43f4612a51ed03205f3a7e84ae9b97b762b1f88161b484515f"
chksum_prep

echo "=== TESTCASE 10k: msig, copy of 9k, executing with -p ..."        | tee -a $logfile
echo "./$create_cmd -T -v -m 2 3 03834bd129bf0a2e03d53b74bc2eef8d9a5faed93f37b4938ae7127d430804a3cf,03fae2fa202fbfd9d0a8650f537df154158761ce9ad2460793aed74b946babb9f4,038cbc733032dcbed878c727840bef9c2aeb01447e1701c372c46a2ef00f48e02c" >> $logfile
./$create_cmd -T -v -m 2 3 03834bd129bf0a2e03d53b74bc2eef8d9a5faed93f37b4938ae7127d430804a3cf,03fae2fa202fbfd9d0a8650f537df154158761ce9ad2460793aed74b946babb9f4,038cbc733032dcbed878c727840bef9c2aeb01447e1701c372c46a2ef00f48e02c > tmp_cfile
ref_redeemscripthash=$( tail -n3 tmp_cfile | head -n1 )
ref_P2SH_address=$( tail -n1 tmp_cfile )
echo "./$create_cmd -T -vv -r -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 $ref_redeemscripthash" >> $logfile
./$create_cmd -T -vv -r -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 $ref_redeemscripthash > tmp_cfile
echo "./tcls_tx2txt.sh -T -vv -f tmp_c_utx.txt -u" >> $logfile
./tcls_tx2txt.sh -T -vv -f tmp_c_utx.txt -u > tmp_cfile
redeemscripthash=$( tail -n6 tmp_cfile | head -n 1 | cut -f 5 -d " " )
P2SH_address=$( tail -n4 tmp_cfile | head -n 1 )
echo "reference: $ref_redeemscripthash" > tmp_cfile
echo "reference: $ref_P2SH_address"    >> tmp_cfile
echo "result:    $redeemscripthash"    >> tmp_cfile
echo "result:    $P2SH_address"        >> tmp_cfile
if [ "$ref_P2SH_address" == "$P2SH_address" ] ; then
  echo "ok" >> tmp_cfile
else
  echo "fail" >> tmp_cfile
fi
chksum_ref="fa779abdfa215fa1cabb27654928f9f5dba4089909f407c19fb132cf811384ad" 
chksum_prep

echo "=== TESTCASE 10l: msig, copy of 9l, executing with -p ..."        | tee -a $logfile
echo "./$create_cmd -T -v -m 2 3 03310188e911026cf18c3ce274e0ebb5f95b007f230d8cb7d09879d96dbeab1aff,0243930746e6ed6552e03359db521b088134652905bd2d1541fa9124303a41e956,029e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255" >> $logfile
./$create_cmd -T -v -m 2 3 03310188e911026cf18c3ce274e0ebb5f95b007f230d8cb7d09879d96dbeab1aff,0243930746e6ed6552e03359db521b088134652905bd2d1541fa9124303a41e956,029e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255 > tmp_cfile
ref_redeemscripthash=$( tail -n3 tmp_cfile | head -n1 )
ref_P2SH_address=$( tail -n1 tmp_cfile )
echo "./$create_cmd -T -vv -r -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 $ref_redeemscripthash" >> $logfile
./$create_cmd -T -vv -r -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 $ref_redeemscripthash > tmp_cfile
echo "./tcls_tx2txt.sh -T -vv -f tmp_c_utx.txt -u" >> $logfile
./tcls_tx2txt.sh -T -vv -f tmp_c_utx.txt -u > tmp_cfile
redeemscripthash=$( tail -n6 tmp_cfile | head -n 1 | cut -f 5 -d " " )
P2SH_address=$( tail -n4 tmp_cfile | head -n 1 )
echo "reference: $ref_redeemscripthash" > tmp_cfile
echo "reference: $ref_P2SH_address"    >> tmp_cfile
echo "result:    $redeemscripthash"    >> tmp_cfile
echo "result:    $P2SH_address"        >> tmp_cfile
if [ "$ref_P2SH_address" == "$P2SH_address" ] ; then
  echo "ok" >> tmp_cfile
else
  echo "fail" >> tmp_cfile
fi
chksum_ref="7b29169e5b53d0977709f18cc302e4a8202bc7a3f604a369987a62f3d8281bd9"
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
  1|2|3|4|5|6|7|8|9|10)
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

