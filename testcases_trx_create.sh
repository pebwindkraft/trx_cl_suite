#!/bin/sh
# some testcases for the shell script "trx_create.sh" 
#
# Copyright (c) 2015, 2016 Volker Nowarra 
# updated regularly with the root script
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
  echo "********************* checksum  mismatch: **********************" | tee -a $logfile
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
echo "=== TESTCASE 1:                                              ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
# first get the checksums of all necessary files 
# based on: http://bitcoin.stackexchange.com/questions/3374/how-to-redeem-a-basic-tx

echo "   " | tee -a $logfile
echo "=== TESTCASE 1a: $chksum_cmd trx_create.sh" | tee -a $logfile
echo "================================================================" | tee -a $logfile
chksum_ref="c17ba8fed0d79da5829980f2e8015f2b658d6b29bb0cb13f30dce24988fcedcf" 
cp trx_create.sh tmp_trx_cfile
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 1b: $chksum_cmd trx_key2pem.sh" | tee -a $logfile
echo "================================================================" | tee -a $logfile
chksum_ref="ed600c2acb39c75eac530cd2c1f7687ccb341eb05fc459ce5164ec454044b63b" 
cp trx_key2pem.sh tmp_trx_cfile
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 1c: $chksum_cmd trx_verify_bc_address.awk" | tee -a $logfile
echo "================================================================" | tee -a $logfile
chksum_ref="30f1fabc40cf3725febf28cc267d6a52507033106341f4a0c925ed2df0c55c1e" 
cp trx_verify_bc_address.awk tmp_trx_cfile
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 1d: $chksum_cmd trx_verify_hexkey.awk" | tee -a $logfile
echo "================================================================" | tee -a $logfile
chksum_ref="055b79074a8f33d0aa9aa7634980d29f4e3eb0248a730ea784c7a88e64aa7cfd" 
cp trx_verify_hexkey.awk tmp_trx_cfile
chksum_prep

echo " " | tee -a $logfile
}

testcase2() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 2: param '-m' testing ...                       ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 2a: manually create a simple unsigned, raw trx" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./trx_create.sh -m F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./trx_create.sh -m F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_trx_cfile
chksum_ref="453d8f3432aeec8565c7f13e0c0be69c2a183691093b5bc588b32109fb761abc" 
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 2b: same as 2a, with verbose output" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./trx_create.sh -v -m F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./trx_create.sh -v -m F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_trx_cfile
chksum_ref="244dae2326df33d44ff110f031e7676495f27b95d500f98a578a44f232bcf14e" 
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 2c: same as 2a, with very verbose output" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./trx_create.sh -vv -m F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./trx_create.sh -vv -m F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_trx_cfile
chksum_ref="4d955441fd5623e65c3023746204d135c11fb349f90ef1d2119c5657136bf820" 
chksum_prep
echo " " | tee -a $logfile
}

testcase3() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 3: param '-m' testing ...                       ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 3a: same as testcase 2, different parameters" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./trx_create.sh -v -m 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac 118307 14zWNsgUMmHhYx4suzc2tZD6HieGbkQi5s" >> $logfile
./trx_create.sh -v -m 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac 118307 14zWNsgUMmHhYx4suzc2tZD6HieGbkQi5s > tmp_trx_cfile
chksum_ref="c122d9429f868dc788b2f24775810186f5cc4c6276a5fb5e5c6924e7efff97a0"
chksum_prep
echo " " | tee -a $logfile
}

testcase4() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 4: 4a, 4b and 4c not ok, 4d ok                  ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 4a: wrong bitcoin adress hash (x at end)" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./trx_create.sh -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdx" >> $logfile
./trx_create.sh -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdx > tmp_trx_cfile
chksum_ref="c723f102158d956605ffc3cdaa9fbf0d2bf2a99fa1af90e61dd9a870ec4c9775" 
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 4b: same as 4a, with verbose output" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./trx_create.sh -v -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdx" >> $logfile
./trx_create.sh -v -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdx > tmp_trx_cfile
chksum_ref="9d2ee9b8cfc7da4fc6745e763062cea4080e125cde1f417ddd96ce15f385a3e6" 
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 4c: same as 4a, with very verbose output" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./trx_create.sh -vv -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdx" >> $logfile
./trx_create.sh -vv -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdx > tmp_trx_cfile
chksum_ref="f779f81d6568d4ac6fe92fa354621d348539d176eb356e1b6d954ec4379ffdb6" 
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 4d: and now with correct bitcoin adress hash" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./trx_create.sh -vv -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./trx_create.sh -vv -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_trx_cfile
chksum_ref="e1ffb8679710b3ecda09e535f0e00d48c5b37700388824df5664a409146ec100" 
chksum_prep
echo " " | tee -a $logfile
}

testcase5() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 5: zero pad testing of bitcoin address hashes   ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 5a: zero padding: invalid bitcoin adress hash " | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./trx_create.sh -v -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 6UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM" >> $logfile
./trx_create.sh -v -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 6UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM > tmp_trx_cfile
chksum_ref="57f62bdad483fb54efb7852811b8eb9e571d3942ff713a2341e91653f6c9431d"
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 5b: zero pad of 16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM  " | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./trx_create.sh -v -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM" >> $logfile
./trx_create.sh -v -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM > tmp_trx_cfile
chksum_ref="4b3e0de012acb53b2ac36006fdd244e70e838e063c116d1176daf28bf15675a5" 
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 5c: zero pad of 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM " | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./trx_create.sh -vv -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 112ZbzFcSpcCoY2EfPNmgxFmv4tVuLSoB4" >> $logfile
./trx_create.sh -vv -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 112ZbzFcSpcCoY2EfPNmgxFmv4tVuLSoB4 > tmp_trx_cfile
chksum_ref="abaea92811844ed9dc6cccc6963e10a2cd13c1c57a2d6d600dff61774e52c7f8" 
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 5d: zero pad of 112ZbzFcSpcCoY2EfPNmgxFmv4tVuLSoB4 " | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./trx_create.sh -vv -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./trx_create.sh -vv -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_trx_cfile
chksum_ref="69110e055bcdf92feef22f56fad6a89428e71b471866f7c15a068a153aba925b" 
chksum_prep
echo " " | tee -a $logfile
}

testcase6() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 6: usage of param '-t'                          ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 6a: read a transaction from the network"  | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./trx_create.sh -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1084000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./trx_create.sh -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1084000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_trx_cfile
chksum_ref="d40996da4d8ca886d90c710e3b1cca77603d35888c6399c25abead699b75c32b" 
chksum_prep

echo "=== TESTCASE 6b: same as 6a, VERBOSE output" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./trx_create.sh -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1084000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./trx_create.sh -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1084000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_trx_cfile
chksum_ref="b7cba9772047686662ff0487a3819868caa7e32d5655b9421e2d2f35dd22f83c" 
chksum_prep

echo "=== TESTCASE 6c: same as 6b, with parameter for TRXFEE" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./trx_create.sh -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1075000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 77" >> $logfile
./trx_create.sh -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1075000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 77 > tmp_trx_cfile
chksum_ref="929225cdd5461fe4a32d28ec28153dfada96ac708ee0db23332acbf593956543" 
chksum_prep

echo "=== TESTCASE 6d: same as 6a, with parameter for a return address" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./trx_create.sh -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1084000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 50 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./trx_create.sh -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1084000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 50 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_trx_cfile
chksum_ref="d40996da4d8ca886d90c710e3b1cca77603d35888c6399c25abead699b75c32b" 
chksum_prep

echo "=== TESTCASE 6e: same as 6c, VERBOSE output" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./trx_create.sh -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1084000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 50 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./trx_create.sh -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1084000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 50 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_trx_cfile
chksum_ref="6c55433a9f50ed2456abd1ba246575db80a3560702aa9e0b7d74c86d73c604df" 
chksum_prep

echo "=== TESTCASE 6f: same as 6c, VERY VERBOSE output" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./trx_create.sh -vv -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1084000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 50 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./trx_create.sh -vv -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1084000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 50 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_trx_cfile
chksum_ref="0fc4f41457ffb4e7170f93d19b3b8d2deadb15f5a6ce20d2b00fe8c284077de1" 
chksum_prep

echo " " | tee -a $logfile
}

testcase7() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 7: several trx with wrong parameters:           ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 7a: insufficient input" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 19235" > tmp_3inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 16197" >> tmp_3inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 23940" >> tmp_3inputs.txt
echo "./trx_create.sh -v -f tmp_3inputs.txt 70000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
./trx_create.sh -v -f tmp_3inputs.txt 70000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM > tmp_trx_cfile
chksum_ref="eb1d6519bdd32236c02e3a4003dd84da019c6fdc99d9a87a583459a66d102d9d" 
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 7b: wrong output address (x at the end)" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 19235" > tmp_3inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 16197" >> tmp_3inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 23940" >> tmp_3inputs.txt
echo "./trx_create.sh -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcx" >> $logfile
./trx_create.sh -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcx > tmp_trx_cfile
chksum_ref="59c7134c19d01d21dd4db7e5bb3f12094c61e021f6aaaa9978a7908da4098ce7" 
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 7c: wrong length of trx hash (31 bytes)" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "4fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 39235" > tmp_3inputs.txt
echo "3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 16197" >> tmp_3inputs.txt
echo "74cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 23940" >> tmp_3inputs.txt
echo "./trx_create.sh -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
./trx_create.sh -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM > tmp_trx_cfile
chksum_ref="5549ca1b8c8b918033a344cfc61d6ac18de97e9d9971ec091643b8c6f6ecf09b" 
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 7d: insufficient trx fee" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 39235" > tmp_3inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 16197" >> tmp_3inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 23940" >> tmp_3inputs.txt
echo "./trx_create.sh -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 50" >> $logfile
./trx_create.sh -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 50 > tmp_trx_cfile
chksum_ref="9ce37c8622aa740b1e0e3bdaee1d5a21009cd374aed6350c2b444938e326624f" 
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 7e: wrong return address (x at the end)" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 39235" > tmp_3inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 16197" >> tmp_3inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 23940" >> tmp_3inputs.txt
echo "./trx_create.sh -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 50 16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvx" >> $logfile
./trx_create.sh -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 50 16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvx > tmp_trx_cfile
chksum_ref="65b0dc77b5cb8340dbd78eb13eece3539cf96ea38fd9803a5bfaeebf7a3af2de"
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 7f: planned spend from 1JmPRD_unspent.txt" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "bb745b565d23c2041022392469114cbd94d29d941e1c6860c609b5ed6ee321cc 0 76a914c2df275d78e506e17691fd6f0c63c43d15c897fc88ac 113000" > tmp_3inputs.txt
echo "48d2c9c76dc282eb7075a0fce543b9d615c0c2d5b78b41603c2d6cf46e2e77b0 1 76a914c2df275d78e506e17691fd6f0c63c43d15c897fc88ac 120000" > tmp_3inputs.txt
echo "e84959a7148737df867d6c83f3683abeb977c297729ccbd609d54ee0879491ea 0 76a914c2df275d78e506e17691fd6f0c63c43d15c897fc88ac 120000" > tmp_3inputs.txt
echo "811848214a52c823f53eaaa302eaddb7dd2b03874174c9202d291ac35868fb74 1 76a914c2df275d78e506e17691fd6f0c63c43d15c897fc88ac 500000" > tmp_3inputs.txt
echo "./trx_create.sh -vv -f tmp_3inputs.txt 484000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./trx_create.sh -vv -f tmp_3inputs.txt 484000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_trx_cfile
chksum_ref="29e5585717e5378e8b85f94090fe045816867fd4d4ee7b6f3f1e3c557b022d8f"
chksum_prep

echo " " | tee -a $logfile
}

testcase8() {
# this is a multi input trx, several inputs, 1 output
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 8:                                              ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== 3 multi input trx, reading from file                     ===" >> $logfile
echo "================================================================" >> $logfile

echo "   " | tee -a $logfile
echo "=== TESTCASE 8a: 3 inputs to a trx " | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 49265" > tmp_3inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 18887" >> tmp_3inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 50000" >> tmp_3inputs.txt
echo "./trx_create.sh -vv -f tmp_3inputs.txt 80000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
./trx_create.sh -vv -f tmp_3inputs.txt 80000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM > tmp_trx_cfile
chksum_ref="bd7302dd52980df3719aded5bd1b0f1ad17ef7f5cfa8a0526199d0e51cdc31fe" 
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 8b: 5 inputs to a trx" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 39235" >> tmp_5inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 48197" >> tmp_5inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 26940" >> tmp_5inputs.txt
echo "722a2ad4daa66382abe4c54676cfe1299ac52a239b4b79b6c6f66e5c5fefe32c 475 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 6886" >> tmp_5inputs.txt
echo "0d87c9c4146452dd8f97f646b52a9dda5a6645d068aca5f1a2a214d37507c5b5 989 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 19099" >> tmp_5inputs.txt
echo "./trx_create.sh -v -f tmp_5inputs.txt 80000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
./trx_create.sh -v -f tmp_5inputs.txt 80000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM > tmp_trx_cfile
chksum_ref="a91caacd7db84d4edb2a53d174d3436e51c7045facd2c5538b978d6d679d4ccb"
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 8c: 20 inputs to a trx" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 119235" >> tmp_20inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 16197" >> tmp_20inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 23940" >> tmp_20inputs.txt
echo "722a2ad4daa66382abe4c54676cfe1299ac52a239b4b79b6c6f66e5c5fefe32c 475 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 6816" >> tmp_20inputs.txt
echo "0d87c9c4146452dd8f97f646b52a9dda5a6645d068aca5f1a2a214d37507c5b5 989 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 19099" >> tmp_20inputs.txt
echo "e90fb95d397c965f4bb7f25e3efc9554aa73b0692b114de5375955fdc7b0308d 771 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 42128" >> tmp_20inputs.txt
echo "c1e162bdd8b2c2e0c68e144b116686e230a1ac2b1cae886fedb8eae4a0b9b4d5 1243 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 11186" >> tmp_20inputs.txt
echo "1dfd30d0ef6c710baff303dc30e056233a9d18e06043471fbf2f364ce203a16d 1063 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 15511" >> tmp_20inputs.txt
echo "a31870644f16e0751fbb8df753e7076755366fe711e9b18ab9ac7696ed47419d 544 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 2730" >> tmp_20inputs.txt
echo "9bfe95cd84bc1adad42d2eb76e605ec587f3308d969e582c7fd00d7d00c0bc93 831 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 16532" >> tmp_20inputs.txt
echo "8b7bd94fa11297f59fdf82923f5e548aa31d9e2a73a2aadb0865dccf3cde6b10 532 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 18588" >> tmp_20inputs.txt
echo "a96ded3a7af074535e58f6ce9b5fadcc9cd4e5a28672c97389b1094c1b8cdfe6 1114 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 22115" >> tmp_20inputs.txt
echo "aece8ad19c4c88906c9bee181a4c021828a5eaf4f5001435989d07a2fe1acaac 513 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 6640" >> tmp_20inputs.txt
echo "fd0faeffc7105159e1ac21f052dd84d2f35e07bf3f897562cdf1d6b914453e1c 1247 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 24986" >> tmp_20inputs.txt
echo "5c31fb9784dc34004664c19a77dac96f08375942fcd058769f46df3fa45420a7 466 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 4285" >> tmp_20inputs.txt
echo "d6dd6411750c74de83babc3cd2188c692c8bab812a50a3ae9ca996f269fdf7c0 520 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 8207" >> tmp_20inputs.txt
echo "7821677c830cad4205d463f781bd068a6bb92382faf21b1a6c7975548a0fc9f5 713 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 5697" >> tmp_20inputs.txt
echo "4aa7a3ad6a56d6afee991ec67ae9b75d7264c484be8dc44fbe32ca200c4fe58f 468 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 29790" >> tmp_20inputs.txt
echo "09b1f67adcc5acb4ec3acd025c6c1dab79efd010b2208a097aa6eefd4fc3be95 508 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 105693" >> tmp_20inputs.txt
echo "c19479c4147c359b9c48fcaeabee5ac77cc7b6ca68f86803d48b051f84804a2f 1174 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 27499" >> tmp_20inputs.txt
echo "./trx_create.sh -f tmp_20inputs.txt 300000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
./trx_create.sh -f tmp_20inputs.txt 300000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM > tmp_trx_cfile
chksum_ref="f71aa092c3a3ebd3a490e60aeb03d4fc33b65afa37000493aaee3b31750ab174" 
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

