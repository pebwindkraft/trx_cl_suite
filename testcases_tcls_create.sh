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
chksum_verify "$result" "$chksum_ref" 
if [ $LOG -eq 1 ] ; then to_logfile ; fi
}

testcase1() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 1: get the checksums of all necessary files     ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile

echo "=== TESTCASE 1a: $chksum_cmd tcls_create.sh" | tee -a $logfile
echo "================================================================" | tee -a $logfile
cp tcls_create.sh tmp_trx_cfile
chksum_ref="35c0e0046428d86e7fdf423065b8b50491b911b1fcaeb1fc6897c639a35b5b2e" 
chksum_prep

echo "=== TESTCASE 1b: $chksum_cmd tcls_key2pem.sh" | tee -a $logfile
echo "================================================================" | tee -a $logfile
cp tcls_key2pem.sh tmp_trx_cfile
chksum_ref="c761104dc86dfc5705377a45e368fd1337cc0bc400b9cab13f735485a4409b89" 
chksum_prep

echo "=== TESTCASE 1c: $chksum_cmd tcls_verify_bc_address.awk" | tee -a $logfile
echo "================================================================" | tee -a $logfile
cp tcls_verify_bc_address.awk tmp_trx_cfile
chksum_ref="30f1fabc40cf3725febf28cc267d6a52507033106341f4a0c925ed2df0c55c1e" 
chksum_prep

echo "=== TESTCASE 1d: $chksum_cmd tcls_verify_hexkey.awk" | tee -a $logfile
echo "================================================================" | tee -a $logfile
cp tcls_verify_hexkey.awk tmp_trx_cfile
chksum_ref="055b79074a8f33d0aa9aa7634980d29f4e3eb0248a730ea784c7a88e64aa7cfd" 
chksum_prep " " | tee -a $logfile

echo "   " | tee -a $logfile
}

testcase2() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 2: parameters testing ...                       ===" | tee -a $logfile
echo "=== spend from: 16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM            ===" | tee -a $logfile
echo "=== spend to:   1runeksijzfVxyrpiyCY2LCBvYsSiFsCm            ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 2a: manually create a simple unsigned, raw trx"      | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./tcls_create.sh -m F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./tcls_create.sh -m F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_trx_cfile
chksum_ref="d0c021c15f3e5009fa5c1f90769f94bb3247f9276cd8d67e41897dfd8fbc7022" 
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 2b: same as 2a, with verbose output" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./tcls_create.sh -v -m F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./tcls_create.sh -v -m F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_trx_cfile
chksum_ref="fcfa50096d87e6e823109f8e32e05110adfc0dec90098a704b4744d9bd224f3f" 
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 2c: same as 2a, with very verbose output" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./tcls_create.sh -vv -m F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./tcls_create.sh -vv -m F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_trx_cfile
chksum_ref="72268067616cc04e638eb2649a94f2cd62cff096da7ea405cac4c75fee38aa60" 
chksum_prep

echo " " | tee -a $logfile
}

testcase3() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 3: param '-m' testing ...                       ===" | tee -a $logfile
echo "=== spend from: 1MBngSqZbMydscpzSoehjP8kznMaHAzh9y           ===" | tee -a $logfile
echo "=== spend to:   14zWNsgUMmHhYx4suzc2tZD6HieGbkQi5s           ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 3a: same as testcase 2, different parameters" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./tcls_create.sh -v -m 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac 118307 14zWNsgUMmHhYx4suzc2tZD6HieGbkQi5s" >> $logfile
./tcls_create.sh -v -m 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac 118307 14zWNsgUMmHhYx4suzc2tZD6HieGbkQi5s > tmp_trx_cfile
chksum_ref="7a0e5490872c827541063768d7677df718ed91bd6bac0b776093e6fee0298900"
chksum_prep
echo " " | tee -a $logfile
}

testcase4() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 4: 4a, 4b and 4c not ok, 4d ok                  ===" | tee -a $logfile
echo "=== spend from: 1CAue7dQ2ASD6Wj9ZUWJABdC2zteiCe5cK           ===" | tee -a $logfile
echo "=== spend to:   12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM           ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 4a: wrong bitcoin adress hash (x at end)" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./tcls_create.sh -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdx" >> $logfile
./tcls_create.sh -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdx > tmp_trx_cfile
chksum_ref="eacceefa91f51acb6d80486b5992f2d04ad51234ac30b15daa7da80c4d414227" 
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 4b: same as 4a, with verbose output" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./tcls_create.sh -v -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdx" >> $logfile
./tcls_create.sh -v -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdx > tmp_trx_cfile
chksum_ref="81ec212123a3f8188a72a864a911c73bd8f17daba21806c45b0a0abfd45877da" 
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 4c: same as 4a, with very verbose output" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./tcls_create.sh -vv -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdx" >> $logfile
./tcls_create.sh -vv -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdx > tmp_trx_cfile
chksum_ref="7e467afc2fd3658a2f3516d13dba42d816c8919ad1d48b64266e4c5fd88a656b" 
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 4d: and now with correct bitcoin adress hash" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./tcls_create.sh -vv -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./tcls_create.sh -vv -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_trx_cfile
chksum_ref="f34d1da68f53cc9592ee1c8237bd9fda2fd5e5c96bb34b52afdc27f1330a8c4c" 
chksum_prep
echo " " | tee -a $logfile
}

testcase5() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 5: zero pad testing of bitcoin address hashes   ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 5a: zero padding:  invalid bitcoin adress hash " | tee -a $logfile
echo "===              wrong address: 6UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./tcls_create.sh -v -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 6UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM" >> $logfile
./tcls_create.sh -v -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 6UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM > tmp_trx_cfile
chksum_ref="2708366c8ebac89c3277b95a071923ddc7f6248ed3c1ea663a2ad7de1502178c"
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 5b: zero pad of 16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM  " | tee -a $logfile
echo "===              from: 1CAue7dQ2ASD6Wj9ZUWJABdC2zteiCe5cK" | tee -a $logfile
echo "===              to:   16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvMK" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./tcls_create.sh -v -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM" >> $logfile
./tcls_create.sh -v -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM > tmp_trx_cfile
chksum_ref="ee5b653916de644774f12dd1b6466369f52ccb8d0ae3b5af7ae6aabb761b1f8c" 
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 5c: zero pad of 112Zbz... " | tee -a $logfile
echo "===              from: 1CAue7dQ2ASD6Wj9ZUWJABdC2zteiCe5cK" | tee -a $logfile
echo "===              to:   112ZbzFcSpcCoY2EfPNmgxFmv4tVuLSoB4" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./tcls_create.sh -vv -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 112ZbzFcSpcCoY2EfPNmgxFmv4tVuLSoB4" >> $logfile
./tcls_create.sh -vv -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 112ZbzFcSpcCoY2EfPNmgxFmv4tVuLSoB4 > tmp_trx_cfile
chksum_ref="b4100edb8d5dfb8598d461133c237600e9ef29c2d6ab5886bfc8932fb4616b6c" 
chksum_prep

echo "   " | tee -a $logfile
echo "=== TESTCASE 5d: zero pad of 12GTF5ARS... " | tee -a $logfile
echo "===              from: 1CAue7dQ2ASD6Wj9ZUWJABdC2zteiCe5cK" | tee -a $logfile
echo "===              to:   12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./tcls_create.sh -vv -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./tcls_create.sh -vv -m 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 110000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_trx_cfile
chksum_ref="1a67ec2ccf6f1f5b485ead87b47d934e75ed5010dd4bd55e4f0f66624b6f28b8" 
chksum_prep
echo " " | tee -a $logfile
}

testcase6() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 6: usage of param '-t'                          ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 6a: read a transaction from the network"  | tee -a $logfile
echo "===   from: 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" | tee -a $logfile
echo "===   to:   12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" | tee -a $logfile
echo "===   proposed TX-FEE (@ 50 Satoshi/Byte * 319 tx_bytes): 15950"  | tee -a $logfile
echo "===   *** possible value to return address:                  50"  | tee -a $logfile
echo "===   *** without return address, txfee will be:          16000"  | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./tcls_create.sh -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1084000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./tcls_create.sh -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1084000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_trx_cfile
chksum_ref="17c3d87e3bffa16bfab79324a5425fbeccf469616f94dfd1b026ca6a1d59ac62" 
chksum_prep

echo "=== TESTCASE 6b: same as 6a, VERBOSE output" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./tcls_create.sh -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1084000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./tcls_create.sh -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1084000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_trx_cfile
chksum_ref="3a0f57d7944e8e51143032599df2a76457e2f4bc255663444bdaebbee22f49aa" 
chksum_prep

echo "=== TESTCASE 6c: same as 6b, with parameter for TRXFEE" | tee -a $logfile
echo "===   proposed TX-FEE (@ 50 Satoshi/Byte * 319 tx_bytes): 24563"  | tee -a $logfile
echo "===   *** possible value to return address:                 437"  | tee -a $logfile
echo "===   *** without return address, txfee will be:          25000"  | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./tcls_create.sh -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1075000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 77" >> $logfile
./tcls_create.sh -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1075000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 77 > tmp_trx_cfile
chksum_ref="0e165c07f59298d3b762e5c251b1d9c4d5ab15cc192ef093f6cbcd4e01c53ed0" 
chksum_prep

echo "=== TESTCASE 6d: same as 6a, with parameter for a return address" | tee -a $logfile
echo "===   proposed TX-FEE (@ 50 Satoshi/Byte * 387 tx_bytes): 19350 " | tee -a $logfile
echo "===   value to return address:                             2873 " | tee -a $logfile
echo "===   return address: 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm         " | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./tcls_create.sh -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1077777 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 50 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./tcls_create.sh -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1077777 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 50 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_trx_cfile
chksum_ref="d87cdaa159c4614cd56c8adc90bf1a036f6b864e0ea47e1b347d218a35fee22d" 
chksum_prep

echo "=== TESTCASE 6e: same as 6c, VERBOSE output" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./tcls_create.sh -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1077777 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 50 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./tcls_create.sh -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1077777 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 50 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_trx_cfile
chksum_ref="e98b5eed9907d0e80699759cb7f32f3d604a4b1280001a9bd3939d4805ce94de" 
chksum_prep

echo "=== TESTCASE 6f: same as 6c, VERY VERBOSE output" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "./tcls_create.sh -vv -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1077777 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 50 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./tcls_create.sh -vv -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1077777 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 50 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_trx_cfile
chksum_ref="dce052a2f04671a7dbed28fa646d110243c0c461bc688c50bdf61f4d43546cd8" 
chksum_prep

echo " " | tee -a $logfile
}

testcase7() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 7: several trx with wrong parameters:           ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 7a: insufficient input" | tee -a $logfile
echo "===              amount of trx input(s) (in Satoshis):    59372 " | tee -a $logfile
echo "===              desired amount to spend (in Satoshis):   70000 " | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 19235" > tmp_3inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 16197" >> tmp_3inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 23940" >> tmp_3inputs.txt
echo "./tcls_create.sh -v -f tmp_3inputs.txt 70000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
./tcls_create.sh -v -f tmp_3inputs.txt 70000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM > tmp_trx_cfile
chksum_ref="2ad6af869f45ca94106e257ae13174968d53b542bccaa79716642a7d28a9de92" 
chksum_prep

echo "=== TESTCASE 7b: wrong output address (x at the end)" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 19235" > tmp_3inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 16197" >> tmp_3inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 23940" >> tmp_3inputs.txt
echo "./tcls_create.sh -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcx" >> $logfile
./tcls_create.sh -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcx > tmp_trx_cfile
chksum_ref="db61c4ca4df8c7e151996d33150631fb290a6336d008d2bfd300ab67463160f0" 
chksum_prep

echo "=== TESTCASE 7c: wrong length of trx hash (63 chars)" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "4fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 39235" > tmp_3inputs.txt
echo "3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 16197" >> tmp_3inputs.txt
echo "74cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 23940" >> tmp_3inputs.txt
echo "./tcls_create.sh -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
./tcls_create.sh -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM > tmp_trx_cfile
chksum_ref="72248aec6d419800473c6b5f21350d87b04c22e3c5743a8da106c41456854ecf" 
chksum_prep

echo "=== TESTCASE 7d: insufficient trx fee" | tee -a $logfile
echo "=== proposed TX-FEE (@ 50 Satoshi/Byte * 763 tx_bytes):    38150" | tee -a $logfile
echo "=== Achieving negative value with this txfee:               -900" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 39255" > tmp_3inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 19999" >> tmp_3inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 27996" >> tmp_3inputs.txt
echo "./tcls_create.sh -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 50" >> $logfile
./tcls_create.sh -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 50 > tmp_trx_cfile
chksum_ref="678d34e094052b407506bc6b36d5ee372eb7488053bc10f79d45c42dff3e6667" 
chksum_prep

echo "=== TESTCASE 7e: wrong return address (x at the end)" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 39235" > tmp_3inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 26197" >> tmp_3inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 23940" >> tmp_3inputs.txt
echo "./tcls_create.sh -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 50 16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvx" >> $logfile
./tcls_create.sh -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 50 16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvx > tmp_trx_cfile
chksum_ref="2f76d308665b2303392388ec051f8eca10b5ab3865e4c3229e29e71de4c8b888"
chksum_prep

echo "=== TESTCASE 7f: a spend from 1JmPRD_unspent.txt     " | tee -a $logfile
echo "=== 4 inputs from: 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" | tee -a $logfile
echo "===            to: 13GnHB51piDBf1avocPL7tSKLugK4F7U2B" | tee -a $logfile
echo "=== proposed TX-FEE (@ 23 Satoshi/Byte * 985 tx_bytes):    31520" | tee -a $logfile
echo "=== *** possible value to return address:                    480" | tee -a $logfile
echo "=== *** without return address, txfee will be:             32000" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "48d2c9c76dc282eb7075a0fce543b9d615c0c2d5b78b41603c2d6cf46e2e77b0 1 76a914c2df275d78e506e17691fd6f0c63c43d15c897fc88ac 120000" > tmp_4inputs.txt
echo "811848214a52c823f53eaaa302eaddb7dd2b03874174c9202d291ac35868fb74 1 76a914c2df275d78e506e17691fd6f0c63c43d15c897fc88ac 500000" >> tmp_4inputs.txt
echo "bb745b565d23c2041022392469114cbd94d29d941e1c6860c609b5ed6ee321cc 0 76a914c2df275d78e506e17691fd6f0c63c43d15c897fc88ac 113000" >> tmp_4inputs.txt
echo "e84959a7148737df867d6c83f3683abeb977c297729ccbd609d54ee0879491ea 0 76a914c2df275d78e506e17691fd6f0c63c43d15c897fc88ac 120000" >> tmp_4inputs.txt
echo "./tcls_create.sh -vv -f tmp_4inputs.txt 821000 13GnHB51piDBf1avocPL7tSKLugK4F7U2B 32" >> $logfile
./tcls_create.sh -vv -f tmp_4inputs.txt 821000 13GnHB51piDBf1avocPL7tSKLugK4F7U2B 32 > tmp_trx_cfile
chksum_ref="435e57c39f6dbb8b72a43200102b7eedff718d7d4a5a781ee0c3049b727d76a6"
chksum_prep

echo " " | tee -a $logfile
}

testcase8() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 8: some multi input trx with 3, 5 and 20 inputs ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 8a: 3 inputs to a trx"                               | tee -a $logfile
echo "=== proposed TX-FEE (@ 50 Satoshi/Byte * 763 tx_bytes):    38150" | tee -a $logfile
echo "=== *** possible value to return address:                      2" | tee -a $logfile
echo "=== *** without return address, txfee will be:             38152" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 49265" > tmp_3inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 18887" >> tmp_3inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 50000" >> tmp_3inputs.txt
echo "./tcls_create.sh -vv -f tmp_3inputs.txt 80000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
./tcls_create.sh -vv -f tmp_3inputs.txt 80000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM > tmp_trx_cfile
chksum_ref="8921203b656e6db3e10764a2abdb27402c846641629263d0ddac66c4973a82fa" 
chksum_prep

echo "=== TESTCASE 8b: 5 inputs to a trx" | tee -a $logfile
echo "=== proposed TX-FEE (@ 50 Satoshi/Byte * 1207 tx_bytes):   60350" | tee -a $logfile
echo "=== *** possible value to return address:                      7" | tee -a $logfile
echo "=== *** without return address, txfee will be:             60357" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 39235" >> tmp_5inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 48197" >> tmp_5inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 26940" >> tmp_5inputs.txt
echo "722a2ad4daa66382abe4c54676cfe1299ac52a239b4b79b6c6f66e5c5fefe32c 475 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 6886" >> tmp_5inputs.txt
echo "0d87c9c4146452dd8f97f646b52a9dda5a6645d068aca5f1a2a214d37507c5b5 989 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 19099" >> tmp_5inputs.txt
echo "./tcls_create.sh -v -f tmp_5inputs.txt 80000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
./tcls_create.sh -v -f tmp_5inputs.txt 80000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM > tmp_trx_cfile
chksum_ref="22445784e72a35712aba8019addbd91f027fb89cbfb1e87d50f79f0886e2cf66"
chksum_prep

echo "=== TESTCASE 8c: 20 inputs to a trx" | tee -a $logfile
echo "=== proposed TX-FEE (@ 50 Satoshi/Byte * 4537 tx_bytes):  226850" | tee -a $logfile
echo "=== *** possible value to return address:                     24" | tee -a $logfile
echo "=== *** without return address, txfee will be:            226874" | tee -a $logfile
echo "===     all 22 inputs from: 1FyJw3R7cs9TrSXPhh1FnnGmgTMdptPSE7  " | tee -a $logfile
echo "===                     to: 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM  " | tee -a $logfile
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
echo "./tcls_create.sh -f tmp_20inputs.txt 300000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
./tcls_create.sh -f tmp_20inputs.txt 300000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM > tmp_trx_cfile
chksum_ref="3b15afdb819bb1b7fc912f1d3e2745b1e57697fc965f6448947560fc7ad86315" 
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

