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
typeset -i no_cleanup=0
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
  for i in *pem; do
    if [ -f "$i" ]; then rm $i ; fi
  done
}


testcase1() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 1: get the checksums of all necessary files     ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile

echo "=== TESTCASE 1a: $chksum_cmd tcls_create.sh" | tee -a $logfile
cp tcls_create.sh tmp_cfile
chksum_ref="52d654f9ad121b0e6ef77b8a43fa64c3d6ac4e13dcd5fa762f4dcb27697d8f6a" 
chksum_prep

echo "=== TESTCASE 1b: $chksum_cmd tcls_key2pem.sh" | tee -a $logfile
cp tcls_key2pem.sh tmp_cfile
chksum_ref="aab5ccc4d4d9329039ea08ef13e6cbc63642e1af19c3111d95f4ac708b7040e3" 
chksum_prep

echo "=== TESTCASE 1c: $chksum_cmd tcls_base58check_enc.sh" | tee -a $logfile
cp tcls_base58check_enc.sh tmp_cfile
chksum_ref="9edf43a7e7aad6ae511c2dd9bc311a9b63792d0b669c7e72d7d1321887213179" 
chksum_prep " " | tee -a $logfile

echo "=== TESTCASE 1d: $chksum_cmd tcls_verify_bc_address.awk" | tee -a $logfile
cp tcls_verify_bc_address.awk tmp_cfile
chksum_ref="c944ff89ff49454ca03b0ea8f3ce8ebbd44e33e8d87ab48ae00ad4d6544099f6" 
chksum_prep

echo "=== TESTCASE 1e: $chksum_cmd tcls_verify_hexkey.awk" | tee -a $logfile
cp tcls_verify_hexkey.awk tmp_cfile
chksum_ref="055b79074a8f33d0aa9aa7634980d29f4e3eb0248a730ea784c7a88e64aa7cfd" 
chksum_prep " " | tee -a $logfile

echo "   " | tee -a $logfile
}

testcase2() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 2: -c parameters testing ...                    ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 2a: manually create a simple unsigned, raw tx"       | tee -a $logfile 
echo "./$create_cmd -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_cfile
chksum_ref="550b9da1c7b079fa3a2372b8d71dc915ebe455260f4420feb81e06f59c59cb7f" 
chksum_prep

echo "=== TESTCASE 2b: same as 2a, with verbose output" | tee -a $logfile
echo "./$create_cmd -v -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -v -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_cfile
chksum_ref="acbb9d909e469c63fd2cb9057d2bc54004c6040b16a491e3ee0e3f4acb3abcd5" 
chksum_prep

echo "=== TESTCASE 2c: same as 2a, with very verbose output" | tee -a $logfile
echo "./$create_cmd -vv -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -vv -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_cfile
chksum_ref="77a17bad9591bbade6783989a84489528050869b766787b406c45cf697464fb8" 
chksum_prep

echo "=== TESTCASE 2d: -c and -f params - that clashes" | tee -a $logfile
echo "./$create_cmd -c -f 76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -c -f 76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_cfile
chksum_ref="f6fba22a6f9159c66bb4a237182246135260bc1b6cf67cdf00c99978abd191d0" 
chksum_prep

echo "=== TESTCASE 2e: -c and -m params - that clashes" | tee -a $logfile
echo "./$create_cmd -c -m 76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -c -m 76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_cfile
chksum_ref="f6fba22a6f9159c66bb4a237182246135260bc1b6cf67cdf00c99978abd191d0" 
chksum_prep

echo "=== TESTCASE 2f: -c and -t params - that clashes" | tee -a $logfile
echo "./$create_cmd -c -t 76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -c -t 76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_cfile
chksum_ref="f6fba22a6f9159c66bb4a237182246135260bc1b6cf67cdf00c99978abd191d0" 
chksum_prep

echo " " | tee -a $logfile
}

testcase3() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 3: intensive params testing ...                 ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 3a: only 1 param... " | tee -a $logfile
echo "$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be" >> $logfile
./$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be > tmp_cfile
chksum_ref="8ee5aa7a5af97ee4ddc5dba08ac3d0af0e7e73ce7b98815bc491a2a8affc5cff"
chksum_prep

echo "=== TESTCASE 3b: only 2 params... " | tee -a $logfile
echo "$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0" >> $logfile
./$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0 > tmp_cfile
chksum_ref="417d069077fa22183f85329361c2920a3b20af935bb2ac2d797fcfccb77c67b9"
chksum_prep

echo "=== TESTCASE 3c: only 3 params... " | tee -a $logfile
echo "$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac" >> $logfile
./$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac > tmp_cfile
chksum_ref="417d069077fa22183f85329361c2920a3b20af935bb2ac2d797fcfccb77c67b9"
chksum_prep

echo "=== TESTCASE 3d: only 4 params... " | tee -a $logfile
echo "$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac 118307" >> $logfile
./$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac 118307 > tmp_cfile
chksum_ref="417d069077fa22183f85329361c2920a3b20af935bb2ac2d797fcfccb77c67b9"
chksum_prep

echo "=== TESTCASE 3e: all params, but TX_IN is char, not numeric... " | tee -a $logfile
echo "$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be A 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac 118307 14zWNsgUMmHhYx4suzc2tZD6HieGbkQi5s" >> $logfile
./$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be A 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac 118307 14zWNsgUMmHhYx4suzc2tZD6HieGbkQi5s > tmp_cfile
chksum_ref="417d069077fa22183f85329361c2920a3b20af935bb2ac2d797fcfccb77c67b9"
chksum_prep

echo "=== TESTCASE 3f: all params, but AMOUNT is char, not numeric... " | tee -a $logfile
echo "$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac AMOUNT 14zWNsgUMmHhYx4suzc2tZD6HieGbkQi5s" >> $logfile
./$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac AMOUNT 14zWNsgUMmHhYx4suzc2tZD6HieGbkQi5s > tmp_cfile
chksum_ref="417d069077fa22183f85329361c2920a3b20af935bb2ac2d797fcfccb77c67b9"
chksum_prep

echo "=== TESTCASE 3g: all params, all correct, should run ok ... " | tee -a $logfile
echo "$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac 135000 118307 14zWNsgUMmHhYx4suzc2tZD6HieGbkQi5s" >> $logfile
./$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac 135000 118307 14zWNsgUMmHhYx4suzc2tZD6HieGbkQi5s > tmp_cfile
chksum_ref="4fee0f3208ff62657625e08e2e8031bf1c1de85176cf6b9a66f66a5c4a945d57"
chksum_prep

echo " " | tee -a $logfile
}

testcase4() {
echo "===================================================================" | tee -a $logfile
echo "=== TESTCASE 4: Testing tx correctness. Proper address, tx max  ===" | tee -a $logfile
echo "===             size, max amounts, tx ID alphanum, empty inputs ===" | tee -a $logfile
echo "===             4a, 4b, 4c wrong address, 4d ok.                ===" | tee -a $logfile
echo "===================================================================" | tee -a $logfile
echo "=== TESTCASE 4a: wrong bitcoin adress hash (x at end)" | tee -a $logfile
echo "./$create_cmd -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdMx" >> $logfile
./$create_cmd -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdMx > tmp_cfile
chksum_ref="86b6dfc9028a8de7d1aafd56b9fbe8f7895d9e209befbac97b1a884bd7f48896" 
chksum_prep

echo "=== TESTCASE 4b: same as 4a, with verbose output" | tee -a $logfile
echo "./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdMx" >> $logfile
./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdMx > tmp_cfile
chksum_ref="7a19ee5b7a1a76576ef6913247f9e3702564d7fe219bf34ef19d976f32a39b35" 
chksum_prep

echo "=== TESTCASE 4c: same as 4a, with very verbose output" | tee -a $logfile
echo "./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdMx" >> $logfile
./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdMx > tmp_cfile
chksum_ref="3663f0076b2388b6b9ef20914da1c656b4ea4a04bb2cb07ffcb9fd02c2e82596" 
chksum_prep

echo "=== TESTCASE 4d: and now with correct bitcoin adress hash" | tee -a $logfile
echo "./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="9a226e525548fb6e03c73931ccd3f000e5c343a771690bc257041b2985f9baea" 
chksum_prep

echo "=== TESTCASE 4e: Size in bytes <= max_tx_size, ok"  | tee -a $logfile
echo "./$create_cmd -f tcls_testcases_vin071_ok.txt 3000000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 27" >> $logfile
./$create_cmd -f tcls_testcases_vin071_ok.txt 3000000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 27 > tmp_cfile
chksum_ref="5fe2410dea3a16bbb62f88322abadbdf36d20ed9e9290ac6f67d2b20dbe138e8"
chksum_prep
echo " " >> $logfile

echo "=== TESTCASE 4f: Size in bytes >= max_tx_size, false"  | tee -a $logfile
echo "./$create_cmd -f tcls_testcases_vin107_false.txt 3000000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 27" >> $logfile
./$create_cmd -f tcls_testcases_vin107_false.txt 3000000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 27 > tmp_cfile
chksum_ref="f832e166d2c5350d764d2461e759872f14614364214fa5112da307c46ba2a154"
chksum_prep
echo " " >> $logfile

echo "=== TESTCASE 4g: input amount out of limits (! <= 21mio BTC)"  | tee -a $logfile
echo "./$create_cmd -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 2100000000000007 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 50 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
./$create_cmd -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 2100000000000007 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 50 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM > tmp_cfile
chksum_ref="0327905775597ee609667b56e00deedf8de19abe0ee5fcda094f1c68ff92a121"
chksum_prep
echo " " >> $logfile

echo "=== TESTCASE 4h: input amount from file out of limits (! <= 21mio BTC)"  | tee -a $logfile
echo "214DEA00252168FD2EDFB752FF140CBFF325BC96D54EF32D193F69AA3CAE80A0 00000000 A914B0303ECB9E26AD262DA3C986D1256965897EEF6287 272727" > tmp_file_amountlimit
echo "E8188CF03B824BC517C9FCF692A276C36C20251504530EF10EEF4CB36A678DE0 03000000 A914B0303ECB9E26AD262DA3C986D1256965897EEF6287 2727700000000000" >> tmp_file_amountlimit
echo "74379D4C787B1B6AD0EBB9BAC977D2D2951083D30EF232ADC94F2B0DBF90919F 02000000 A9147E89B532389C565F7A8598F62928BC487A9A8FC287 272727" >> tmp_file_amountlimit
echo "./$create_cmd -f tmp_file_amountlimit 3000000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 27" >> $logfile
./$create_cmd -f tmp_file_amountlimit 3000000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 27 > tmp_cfile
chksum_ref="4f4b12ceb44fe7fa8233cc6eccfa53dda048354068559faa0b4827d0f18bbba6"
chksum_prep
echo " " >> $logfile

echo "=== TESTCASE 4i: txfee amount out of limits (! <= 21mio BTC)"  | tee -a $logfile
echo "./$create_cmd -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 2100000000000007 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 2100000000000007 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="2aa2c8b100d1607a683e50888754793b320953eeaf6885344fb47842cd0c8952"
chksum_prep
echo " " >> $logfile

echo "=== TESTCASE 4j: tx_ID hash length = 64"  | tee -a $logfile
echo "./$create_cmd -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 190000 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 21 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 190000 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 21 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="27a3ca7a63f7f769213ba92c5db5c9d10478cc103a3c790322d23b7c640ff40d"
chksum_prep
echo " " >> $logfile

echo "=== TESTCASE 4k: tx_ID hash length != 64"  | tee -a $logfile
echo "./$create_cmd -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 27 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 27 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="6edc5ffd662368d5b125868077a2fa724f4ca584f86d85ccdbf2050171d34ca5"
chksum_prep
echo " " >> $logfile

echo "=== TESTCASE 4l: tx_ID hash != alphanumeric"  | tee -a $logfile
echo "./$create_cmd -c x423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 27 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -c x423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 100000 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 27 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="52272674a8e9b9a4bdeba94dda31abb9eeeca88f0659a710d5450075ffac01d6"
chksum_prep
echo " " >> $logfile

echo "=== TESTCASE 4m: none of the inputs have n<=0"  | tee -a $logfile
echo "./$create_cmd -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 -1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 190000 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 21 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 -1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 190000 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 21 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="d03a39320cd20ddc9981a6479fd31996b3df7f9a5ddac63938f9b882ba3df37e"
chksum_prep
echo " " >> $logfile

echo "=== TESTCASE 4n: Reject if sum of input values < sum of output values" | tee -a $logfile
echo "./$create_cmd -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 270000 272727 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 21 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 270000 272727 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 21 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="498dc4cd3fbc9db1c686bcb50dbcc7df5d64e2653003074dba5427b1243f1bf9"
chksum_prep
echo " " >> $logfile

echo "=== TESTCASE 4o: Reject if input values in file < sum of output values" | tee -a $logfile
echo "214DEA00252168FD2EDFB752FF140CBFF325BC96D54EF32D193F69AA3CAE80A0 00000000 A914B0303ECB9E26AD262DA3C986D1256965897EEF6287 272727" > tmp_file_amountlimit
echo "E8188CF03B824BC517C9FCF692A276C36C20251504530EF10EEF4CB36A678DE0 03000000 A914B0303ECB9E26AD262DA3C986D1256965897EEF6287 272727" >> tmp_file_amountlimit
echo "74379D4C787B1B6AD0EBB9BAC977D2D2951083D30EF232ADC94F2B0DBF90919F 02000000 A9147E89B532389C565F7A8598F62928BC487A9A8FC287 272727" >> tmp_file_amountlimit
echo "./$create_cmd -f tmp_file_amountlimit 900000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 27" >> $logfile
./$create_cmd -f tmp_file_amountlimit 900000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 27 > tmp_cfile
chksum_ref="ffcae6e1ca5fe8c72071c7e1a13393e341c48d586b782ed0de6ea27d136f548a"
chksum_prep
echo " " >> $logfile

echo "=== TESTCASE 4r: nLockTime <= INT_MAX (=uint32_t=2^32 numbers: 0-4294967295)" | tee -a $logfile
echo "                 there is no variable for nLockTime in the code (yet), tbd later ..." | tee -a $logfile
echo " " >> $logfile


echo " " | tee -a $logfile
}


testcase5() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 5: Addresses with leading 1s ...                ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 5a: 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM " | tee -a $logfile
echo "./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="d65190b49767f8cb96a2fe81ca5e54f35441bba8fe00ab02c11654d5a85f5b46"
chksum_prep

echo "=== TESTCASE 5b: 112ZbzFcSpcCoY2EfPNmgxFmv4tVuLSoB4 " | tee -a $logfile
echo "./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 112ZbzFcSpcCoY2EfPNmgxFmv4tVuLSoB4 " >> $logfile
./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 112ZbzFcSpcCoY2EfPNmgxFmv4tVuLSoB4 > tmp_cfile
chksum_ref="aa3397bdbb4e875153b30b13248f87393af34b38c1f9d2c283111f55cde09acd"
chksum_prep

echo "=== TESTCASE 5c: 1111DAYXhoxZx2tsRnzimfozo783x1yC2" | tee -a $logfile
echo "./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 1111DAYXhoxZx2tsRnzimfozo783x1yC2 " >> $logfile
./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 1111DAYXhoxZx2tsRnzimfozo783x1yC2 > tmp_cfile
chksum_ref="254ee88e35f1928dc23f0ddc7d1566a8e838f8e1804975db01a57a195ed0a64f"
chksum_prep

echo "=== TESTCASE 5d: 1111VHuXEzHaRCgXbVwojtaP7Co3QABb" | tee -a $logfile
echo "./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 1111VHuXEzHaRCgXbVwojtaP7Co3QABb " >> $logfile
./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 1111VHuXEzHaRCgXbVwojtaP7Co3QABb > tmp_cfile
chksum_ref="862fb147b9e87b58d331862c8b0d523ae41e5512468651fcba7c6b84823d8862"
chksum_prep

echo "=== TESTCASE 5e: 1111KiuFyqUXJFji8KQnoHC5Rtqa5d5e" | tee -a $logfile
echo "./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 1111KiuFyqUXJFji8KQnoHC5Rtqa5d5e " >> $logfile
./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 1111KiuFyqUXJFji8KQnoHC5Rtqa5d5e > tmp_cfile
echo "./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u" >> $logfile
./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u >> tmp_cfile
chksum_ref="2f576f55cc8d56aa9f617593a2930346772fdc4407bdd237d993dae62e9087ac"
chksum_prep

echo "=== TESTCASE 5f: 1111LexYVhKvaQY69Paj774F9gnjhDrr " | tee -a $logfile
echo "./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 1111LexYVhKvaQY69Paj774F9gnjhDrr" >> $logfile
./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 1111LexYVhKvaQY69Paj774F9gnjhDrr > tmp_cfile
echo "./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u" >> $logfile
./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u >> tmp_cfile
chksum_ref="faaf902b3f70a65b5b6df7119d388a8d697db3efb4a253513020f656f2232225"
chksum_prep

echo "=== TESTCASE 5g: 111113CRATaaDmCcWzokzTGhM886kj2bs" | tee -a $logfile
echo "./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 111113CRATaaDmCcWzokzTGhM886kj2bs " >> $logfile
./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 111113CRATaaDmCcWzokzTGhM886kj2bs > tmp_cfile
echo "./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u" >> $logfile
./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u >> tmp_cfile
chksum_ref="4409acf46aa07244b0cc1498e9e726d60b5869fa459ba32446db3e3121d68bb9"
chksum_prep

echo "=== TESTCASE 5h: 1111111111111111111114oLvT2 " | tee -a $logfile
echo "./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 1111111111111111111114oLvT2 " >> $logfile
./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 1111111111111111111114oLvT2 > tmp_cfile
echo "./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u" >> $logfile
./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u >> tmp_cfile
chksum_ref="b40a5def41680ba0c9c627bafaa8a57d69aa4958c8342059078ea0c5d188b072"
chksum_prep

echo " " | tee -a $logfile
}

testcase6() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 6: usage of param '-t' (read tx from network)   ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 6a: TX has insufficient amount"                      | tee -a $logfile

echo "./$create_cmd -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1070000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1070000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="ad5d2a4d62799c6cc4cfaaec2e314e6dbe70f1a66834fc96ecffd3bdb7002df6"
chksum_prep

echo "=== TESTCASE 6b: same as 6a, verbose output" | tee -a $logfile
echo "./$create_cmd -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1070000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1070000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="dd6e6a77552087186e609b07ddde35777421347927c5b0212d3729c0b3346779"
chksum_prep

echo "=== TESTCASE 6c: same as 6b, ok, and with 77 Satoshi per Byte TXFEE" | tee -a $logfile
echo "./$create_cmd -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1070000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 77" >> $logfile
./$create_cmd -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1070000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 77 > tmp_cfile
chksum_ref="09557f7d91b8d1f2fba3db6635b9d0a13ae61903e1530fc5936f87f9b48df959"
chksum_prep

echo "=== TESTCASE 6d: same as 6c, with parameter for a return address" | tee -a $logfile
echo "./$create_cmd -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1070000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 77 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1070000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 77 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_cfile
chksum_ref="60d1453008a788f9e3223dadb44beeec8db4f3a2b581f63945eda39c528e9031"
chksum_prep

echo "=== TESTCASE 6e: same as 6d, VERY VERBOSE output" | tee -a $logfile
echo "./$create_cmd -vv -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1070000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 77 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -vv -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1070000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 77 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_cfile
chksum_ref="d665a199d4c62d240d9c0de7579482ab15061243cdff09abf18fcf551cd98a3d"
chksum_prep

echo "=== TESTCASE 6f: fetch data from network " | tee -a $logfile
echo "./$create_cmd -vv -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 999999 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -vv -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 999999 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="58c5c7a755af02fc680967f244406eb661f4ce3798333cec0ea11158f51057c9"
chksum_prep

echo " " | tee -a $logfile
}

testcase7() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 7: several tx with wrong parameters:            ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 7a: insufficient input" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 19235" > tmp_3inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 16197" >> tmp_3inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 23940" >> tmp_3inputs.txt
echo "./$create_cmd -v -f tmp_3inputs.txt 70000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
./$create_cmd -v -f tmp_3inputs.txt 70000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM > tmp_cfile
chksum_ref="1657cb7d246ab2f1f49dc333db62b79a915d51d179ce021275897a2351dd337c" 
chksum_prep

echo "=== TESTCASE 7b: wrong output address (x at the end)" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 19235" > tmp_3inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 16197" >> tmp_3inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 23940" >> tmp_3inputs.txt
echo "./$create_cmd -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcx" >> $logfile
./$create_cmd -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcx > tmp_cfile
chksum_ref="4473c47405f3b2d91d36b81308554900c20e89c4de45f94d73f633709831d7b4" 
chksum_prep

echo "=== TESTCASE 7c: wrong length of tx hash (63 chars)" | tee -a $logfile
echo "4fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 39235" > tmp_3inputs.txt
echo "3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 16197" >> tmp_3inputs.txt
echo "74cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 23940" >> tmp_3inputs.txt
echo "./$create_cmd -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
./$create_cmd -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM > tmp_cfile
chksum_ref="589ad48f4835a7fed6928066df192115a5c8b3104fe90774275101ead65660f6" 
chksum_prep

echo "=== TESTCASE 7d: insufficient tx fee" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 39255" > tmp_3inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 19999" >> tmp_3inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 27996" >> tmp_3inputs.txt
echo "./$create_cmd -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 50" >> $logfile
./$create_cmd -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 50 > tmp_cfile
chksum_ref="9571ee5dc8fcf631db1e82293f542d50a1e1b6f08e94d6b74f6e0e5fce1bb332" 
chksum_prep

echo "=== TESTCASE 7e: wrong return address (x at the end)" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 39235" > tmp_3inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 26197" >> tmp_3inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 23940" >> tmp_3inputs.txt
echo "./$create_cmd -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 50 16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvx" >> $logfile
./$create_cmd -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 50 16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvx > tmp_cfile
chksum_ref="c079c8626a4e50bcfded301a4ebc0d806ab9817f2a075a2133322b2d3f11f6a4"
chksum_prep

echo "=== TESTCASE 7f: a spend from 1JmPRD_unspent.txt - ok" | tee -a $logfile
echo "48d2c9c76dc282eb7075a0fce543b9d615c0c2d5b78b41603c2d6cf46e2e77b0 1 76a914c2df275d78e506e17691fd6f0c63c43d15c897fc88ac 120000" > tmp_4inputs.txt
echo "811848214a52c823f53eaaa302eaddb7dd2b03874174c9202d291ac35868fb74 1 76a914c2df275d78e506e17691fd6f0c63c43d15c897fc88ac 500000" >> tmp_4inputs.txt
echo "bb745b565d23c2041022392469114cbd94d29d941e1c6860c609b5ed6ee321cc 0 76a914c2df275d78e506e17691fd6f0c63c43d15c897fc88ac 113000" >> tmp_4inputs.txt
echo "e84959a7148737df867d6c83f3683abeb977c297729ccbd609d54ee0879491ea 0 76a914c2df275d78e506e17691fd6f0c63c43d15c897fc88ac 120000" >> tmp_4inputs.txt
echo "./$create_cmd -vv -f tmp_4inputs.txt 821000 13GnHB51piDBf1avocPL7tSKLugK4F7U2B 32" >> $logfile
./$create_cmd -vv -f tmp_4inputs.txt 821000 13GnHB51piDBf1avocPL7tSKLugK4F7U2B 32 > tmp_cfile
chksum_ref="a24f719c1701f7f541e1e1589af5c15625954fce1e3dfa2b1f2ebd33cfc0548f"
chksum_prep

echo " " | tee -a $logfile
}

testcase8() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 8: some multi input tx with 3, 5 and 20 inputs  ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 8a: 3 inputs to a tx"                               | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 49265" > tmp_3inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 18887" >> tmp_3inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 50000" >> tmp_3inputs.txt
echo "./$create_cmd -vv -f tmp_3inputs.txt 80000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
./$create_cmd -vv -f tmp_3inputs.txt 80000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM > tmp_cfile
chksum_ref="90219539a8f2a69e6d31336fa490d743522e4b9de34730fc0cd8593091d6bbe3"
chksum_prep

echo "=== TESTCASE 8b: 5 inputs to a tx" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 39235" > tmp_5inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 48197" >> tmp_5inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 26940" >> tmp_5inputs.txt
echo "722a2ad4daa66382abe4c54676cfe1299ac52a239b4b79b6c6f66e5c5fefe32c 475 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 6886" >> tmp_5inputs.txt
echo "0d87c9c4146452dd8f97f646b52a9dda5a6645d068aca5f1a2a214d37507c5b5 989 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 19099" >> tmp_5inputs.txt
echo "./$create_cmd -v -f tmp_5inputs.txt 110180 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
./$create_cmd -v -f tmp_5inputs.txt 110180 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM > tmp_cfile
chksum_ref="68137a008e9f8170e231c4ff378a05e54cdcc614dcf5b3d385990772b2ff73e2"
chksum_prep

echo "=== TESTCASE 8c: 23 inputs to a tx" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 119235" > tmp_23inputs.txt
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
chksum_ref="fc45eb83113b3175ed2f0f6124104230f02ae3ed503cc6ec983a5f529aa791bc"
chksum_prep


echo "=== TESTCASE 8d: 53 inputs to a tx" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 119235" > tmp_53inputs.txt
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
chksum_ref="940efdaaacf590093f64b6c024f83e4fd02fda15ed0691a0aad410d29e051bf3" 
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
chksum_ref="823c57a3b40eab50a0a2df5332c0152f6a29b149cf2a22f3d8644f1b1a87dfda"
chksum_prep

echo "=== TESTCASE 9b: msig, 2of3, only 2 addresses" | tee -a $logfile 
echo "./$create_cmd -m 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM" >> $logfile 
./$create_cmd -m 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM > tmp_cfile
chksum_ref="2b78bc9570b165b7e68d4e207b2f73df3bcab32cad22b84d3d700469adb51cc0"
chksum_prep

echo "=== TESTCASE 9c: msig, 3of2, invalid, 3of2 does not work :-)" | tee -a $logfile
echo "./$create_cmd -v -m 3 2 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -v -m 3 2 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="b1fbc0198b8c2afd362631fc59a4db3c9438d45e564bb99d937cddaf214f27da"
chksum_prep

echo "=== TESTCASE 9d: -m and -f params - that clashes!" | tee -a $logfile
echo "./$create_cmd -v -m -f 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -v -m -f 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="f078cb8b0b8915a9bc9d5d0f4e80b3b8d8649c26bb584bec79fa96985d6ae934"
chksum_prep

echo "=== TESTCASE 9e: -m and -c params - that clashes!" | tee -a $logfile
echo "./$create_cmd -v -m -c 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -v -m -c 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="f078cb8b0b8915a9bc9d5d0f4e80b3b8d8649c26bb584bec79fa96985d6ae934"
chksum_prep

echo "=== TESTCASE 9f: -m and -t params - that clashes!" | tee -a $logfile
echo "./$create_cmd -v -m -t 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -v -m -t 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="f078cb8b0b8915a9bc9d5d0f4e80b3b8d8649c26bb584bec79fa96985d6ae934"
chksum_prep

echo "=== TESTCASE 9g: msig, 2of3, but wrong bitcoin pubkeys" | tee -a $logfile
echo "./$create_cmd -m 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -m 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="233c0a616e2e8690ce886fb9ed415a73adf0aaa278a92181660e2c071165ec75"
chksum_prep

echo "=== TESTCASE 9h: 4 x msig tests, exceeding max keys and max length of redeem script" | tee -a $logfile
echo "$create_cmd -m 1 13 <pubkey 1> ... <pubkey 13>" >> $logfile
./$create_cmd -m 1 13 03310188e911026cf18c3ce274e0ebb5f95b007f230d8cb7d09879d96dbeab1aff,0243930746e6ed6552e03359db521b088134652905bd2d1541fa9124303a41e956,029e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255,03310188e911026cf18c3ce274e0ebb5f95b007f230d8cb7d09879d96dbeab1aff,0243930746e6ed6552e03359db521b088134652905bd2d1541fa9124303a41e956,029e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255,03310188e911026cf18c3ce274e0ebb5f95b007f230d8cb7d09879d96dbeab1aff,0243930746e6ed6552e03359db521b088134652905bd2d1541fa9124303a41e956,029e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255,03310188e911026cf18c3ce274e0ebb5f95b007f230d8cb7d09879d96dbeab1aff,0243930746e6ed6552e03359db521b088134652905bd2d1541fa9124303a41e956,029e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255,03310188e911026cf18c3ce274e0ebb5f95b007f230d8cb7d09879d96dbeab1aff > tmp_cfile

echo "$create_cmd -m 1 7 <pubkey 1> ... <pubkey 7>" >> $logfile
./$create_cmd -m 1 7 0491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f86,04865c40293a680cb9c020e7b1e106d8c1916d3cef99aa431a56d253e69256dac09ef122b1a986818a7cb624532f062c1d1f8722084861c5c3291ccffef4ec6874,048d2455d2403e08708fc1f556002f1b6cd83f992d085097f9974ab08a28838f07896fbab08f39495e15fa6fad6edbfb1e754e35fa1c7844c41f322a1863d46213,0491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f86,0491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f86,0491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f86,0491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f86 >> tmp_cfile

echo "$create_cmd -m 2 12 <compr. pubkey 1> ... <compr. pubkey 12>" >> $logfile
./$create_cmd -m 2 12 03310188e911026cf18c3ce274e0ebb5f95b007f230d8cb7d09879d96dbeab1aff,0243930746e6ed6552e03359db521b088134652905bd2d1541fa9124303a41e956,029e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255,03310188e911026cf18c3ce274e0ebb5f95b007f230d8cb7d09879d96dbeab1aff,0243930746e6ed6552e03359db521b088134652905bd2d1541fa9124303a41e956,029e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255,03310188e911026cf18c3ce274e0ebb5f95b007f230d8cb7d09879d96dbeab1aff,0243930746e6ed6552e03359db521b088134652905bd2d1541fa9124303a41e956,029e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255,03310188e911026cf18c3ce274e0ebb5f95b007f230d8cb7d09879d96dbeab1aff,0243930746e6ed6552e03359db521b088134652905bd2d1541fa9124303a41e956,029e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255 >> tmp_cfile

echo "$create_cmd -m 2 6 <uncompr. pubkey 1> ... <uncompr. pubkey 6>" >> $logfile
./$create_cmd -m 2 6 0491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f86,04865c40293a680cb9c020e7b1e106d8c1916d3cef99aa431a56d253e69256dac09ef122b1a986818a7cb624532f062c1d1f8722084861c5c3291ccffef4ec6874,048d2455d2403e08708fc1f556002f1b6cd83f992d085097f9974ab08a28838f07896fbab08f39495e15fa6fad6edbfb1e754e35fa1c7844c41f322a1863d46213,0491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f86,0491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f86,0491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f86 >> tmp_cfile
echo "the four results are: " >> $logfile
chksum_ref="d4a2e9882a8617a10e0d24f0342ab257c5bc6987240af8484de985a949a31fdd"
chksum_prep

echo "=== TESTCASE 9i: msig 2of3, uncompressed pubkeys, ok ..."          | tee -a $logfile
echo "    https://gist.githubusercontent.com/gavinandresen/3966071/raw/" >> $logfile
echo "    1f6cfa4208bc82ee5039876b4f065a705ce64df7/TwoOfThree.sh"        >> $logfile
echo "./$create_cmd -v -m 2 3 0491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f86,04865c40293a680cb9c020e7b1e106d8c1916d3cef99aa431a56d253e69256dac09ef122b1a986818a7cb624532f062c1d1f8722084861c5c3291ccffef4ec6874,048d2455d2403e08708fc1f556002f1b6cd83f992d085097f9974ab08a28838f07896fbab08f39495e15fa6fad6edbfb1e754e35fa1c7844c41f322a1863d46213" >> $logfile
./$create_cmd -v -m 2 3 0491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f86,04865c40293a680cb9c020e7b1e106d8c1916d3cef99aa431a56d253e69256dac09ef122b1a986818a7cb624532f062c1d1f8722084861c5c3291ccffef4ec6874,048d2455d2403e08708fc1f556002f1b6cd83f992d085097f9974ab08a28838f07896fbab08f39495e15fa6fad6edbfb1e754e35fa1c7844c41f322a1863d46213 > tmp_cfile
chksum_ref="556e0f91c0c313807ca0bb02e3cc7313639779d14c031d2a11dd926035316d65"

chksum_prep

echo "=== TESTCASE 9j: msig 2of3, uncompressed pubkeys, ok ..."          | tee -a $logfile
echo "    https://bitcointalk.org/index.php?topic=82213.msg906833#msg906833" >> $logfile
echo "./$create_cmd -v -m 2 3 0446fc07bc99bef8e7a875249657c65e1f1793fd0bf45e2c39d539b6f8fcd44676acc552ab886c11eb08f4a275e7bb7dc4fdaf9c4b2228856f168a69df7d216fbc,04df70eb0107ed08e1ddcd4b4d85d26bf8cca301f5c98fd15f5efef12ba4de72bfef7287f964e304207164c003029449740aaae2d6af1ff7ae3f6bb27f3012296c,046003581a3ff5bc3dedaa6da4834ce7bcd49d3f114ce15791f6b5de8b0cec81a46db2eb8cf84d2db845854c57788c7283ab4040aeb3595bc5c68303a17fdde7c8" >> $logfile
./$create_cmd -v -m 2 3 0446fc07bc99bef8e7a875249657c65e1f1793fd0bf45e2c39d539b6f8fcd44676acc552ab886c11eb08f4a275e7bb7dc4fdaf9c4b2228856f168a69df7d216fbc,04df70eb0107ed08e1ddcd4b4d85d26bf8cca301f5c98fd15f5efef12ba4de72bfef7287f964e304207164c003029449740aaae2d6af1ff7ae3f6bb27f3012296c,046003581a3ff5bc3dedaa6da4834ce7bcd49d3f114ce15791f6b5de8b0cec81a46db2eb8cf84d2db845854c57788c7283ab4040aeb3595bc5c68303a17fdde7c8 > tmp_cfile
chksum_ref="aa475c26b3b4cb1f8dbbdae57111b2558cf25ccb81167e9a445ac79146120ad1"
chksum_prep

echo "=== TESTCASE 9k: msig 2of3, uncompressed pubkeys, ok ..." | tee -a $logfile
echo "./$create_cmd -v -m 2 3 04a882d414e478039cd5b52a92ffb13dd5e6bd4515497439dffd691a0f12af9575fa349b5694ed3155b136f09e63975a1700c9f4d4df849323dac06cf3bd6458cd,046ce31db9bdd543e72fe3039a1f1c047dab87037c36a669ff90e28da1848f640de68c2fe913d363a51154a0c62d7adea1b822d05035077418267b1a1379790187,0411ffd36c70776538d079fbae117dc38effafb33304af83ce4894589747aee1ef992f63280567f52f5ba870678b4ab4ff6c8ea600bd217870a8b4f1f09f3a8e83" >> $logfile
./$create_cmd -v -m 2 3 04a882d414e478039cd5b52a92ffb13dd5e6bd4515497439dffd691a0f12af9575fa349b5694ed3155b136f09e63975a1700c9f4d4df849323dac06cf3bd6458cd,046ce31db9bdd543e72fe3039a1f1c047dab87037c36a669ff90e28da1848f640de68c2fe913d363a51154a0c62d7adea1b822d05035077418267b1a1379790187,0411ffd36c70776538d079fbae117dc38effafb33304af83ce4894589747aee1ef992f63280567f52f5ba870678b4ab4ff6c8ea600bd217870a8b4f1f09f3a8e83 > tmp_cfile
chksum_ref="84e1e32a04e58ccc38ca08da51f31be3b6a9de642b3e55e159472b149155339b"
chksum_prep

echo "=== TESTCASE 9l: msig with testnet 2of3, ok ..." | tee -a $logfile
echo "./$create_cmd -T -v -m 2 3 03834bd129bf0a2e03d53b74bc2eef8d9a5faed93f37b4938ae7127d430804a3cf,03fae2fa202fbfd9d0a8650f537df154158761ce9ad2460793aed74b946babb9f4,038cbc733032dcbed878c727840bef9c2aeb01447e1701c372c46a2ef00f48e02c" >> $logfile
./$create_cmd -T -v -m 2 3 03834bd129bf0a2e03d53b74bc2eef8d9a5faed93f37b4938ae7127d430804a3cf,03fae2fa202fbfd9d0a8650f537df154158761ce9ad2460793aed74b946babb9f4,038cbc733032dcbed878c727840bef9c2aeb01447e1701c372c46a2ef00f48e02c > tmp_cfile
chksum_ref="0036216f998ff6a294429753b9dd8c54d30fbd63153f6b6939e64478d34b4449"
chksum_prep

echo "=== TESTCASE 9m: msig: https://bitcoin.org/en/developer-examples#p2sh-multisig" | tee -a $logfile
echo "./$create_cmd -T -v -m 2 3 03310188e911026cf18c3ce274e0ebb5f95b007f230d8cb7d09879d96dbeab1aff,0243930746e6ed6552e03359db521b088134652905bd2d1541fa9124303a41e956,029e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255" >> $logfile
./$create_cmd -T -v -m 2 3 03310188e911026cf18c3ce274e0ebb5f95b007f230d8cb7d09879d96dbeab1aff,0243930746e6ed6552e03359db521b088134652905bd2d1541fa9124303a41e956,029e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255 > tmp_cfile
chksum_ref="cd6564b769ec203bf632d00698ad2bedd0e62dd73a3b6c589f416a2ae6e9ff46"
chksum_prep

echo "=== TESTCASE 9n: msig: tbd ..." | tee -a $logfile
echo "./$create_cmd -T -v -m 2 3 ..." >> $logfile
./$create_cmd -T -v -m 2 3 ... > tmp_cfile
chksum_ref="3b15a2cc976acea85075f5aeeabbe749cab498370ade538fa0ea7ce3ead60b05"
chksum_prep

echo " " | tee -a $logfile
}

testcase10() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 10: creating multisig TX (P2SH)                 ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 10a: msig, to adress of 9i ... " | tee -a $logfile
echo "./$create_cmd -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 3QJmV3qfvL9SuYo34YihAf3sRCW3qSinyC" >> $logfile
./$create_cmd -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 99000000 3QJmV3qfvL9SuYo34YihAf3sRCW3qSinyC > tmp_cfile
chksum_ref="33c95407d7f453b9b90beca072abfbf1c4fc4f902548a578406d647876f4b989"
chksum_prep

echo "=== TESTCASE 10b: msig, to adress of 9j ... " | tee -a $logfile
echo "./$create_cmd -v -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 3EffXJKyYB9zWh2dhx2hcccqBK8DGC7x2x" >> $logfile
./$create_cmd -v -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 99000000 3EffXJKyYB9zWh2dhx2hcccqBK8DGC7x2x > tmp_cfile
chksum_ref="4192935fe456e3ff7983a559613b4af240692c6f730079d07278867ff5a2b7a6"
chksum_prep

echo "=== TESTCASE 10c: msig, to adress of 9k ... " | tee -a $logfile
echo "./$create_cmd -vv -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 347N1Thc213QqfYCz3PZkjoJpNv5b14kBd" >> $logfile
./$create_cmd -vv -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 99000000 347N1Thc213QqfYCz3PZkjoJpNv5b14kBd > tmp_cfile
chksum_ref="5dfae738b29a6711f1c4a483b8a4b72ed7e321bd93210fb45ce412acd68f2546"
chksum_prep

echo "=== TESTCASE 10d: msig, to adress of 9l ... " | tee -a $logfile
echo "./$create_cmd -v -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 2N6X3w3uG7Nrd56kkYJSMgSahKbRD5fHnVh" >> $logfile
./$create_cmd -v -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 99000000 2N6X3w3uG7Nrd56kkYJSMgSahKbRD5fHnVh > tmp_cfile
chksum_ref="4dd1b1e9aee5238f61e4752162f32ab054c52c8547dfc2ffe8c7faee716b3c34"
chksum_prep

echo "=== TESTCASE 10e: msig, to adress of 9m ... " | tee -a $logfile
echo "./$create_cmd -vv -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 2N7NaqSKYQUeM8VNgBy8D9xQQbiA8yiJayk" >> $logfile
./$create_cmd -vv -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 99000000 2N7NaqSKYQUeM8VNgBy8D9xQQbiA8yiJayk > tmp_cfile
chksum_ref="550cdfbe738db93b38cb8d8bc42c5e1db7c1c95db003190d0147e6ca9180f6a0"
chksum_prep

# echo "=== TESTCASE 10f: msig, copy of 9l, executing with -T -v -m "     | tee -a $logfile
# echo "./$create_cmd -T -v -m 2 3 03310188e911026cf18c3ce274e0ebb5f95b007f230d8cb7d09879d96dbeab1aff,0243930746e6ed6552e03359db521b088134652905bd2d1541fa9124303a41e956,029e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255" >> $logfile
# ./$create_cmd -T -v -m 2 3 03310188e911026cf18c3ce274e0ebb5f95b007f230d8cb7d09879d96dbeab1aff,0243930746e6ed6552e03359db521b088134652905bd2d1541fa9124303a41e956,029e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255 > tmp_cfile
# ref_redeemscripthash=$( tail -n3 tmp_cfile | head -n1 )
# ref_P2SH_address=$( tail -n1 tmp_cfile )
# echo "./$create_cmd -T -vv -r -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 $ref_redeemscripthash" >> $logfile
# ./$create_cmd -T -vv -r -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 $ref_redeemscripthash > tmp_cfile
# echo "./tcls_tx2txt.sh -T -vv -f tmp_c_utx.txt -u" >> $logfile
# ./tcls_tx2txt.sh -T -vv -f tmp_c_utx.txt -u > tmp_cfile
# redeemscripthash=$( tail -n6 tmp_cfile | head -n 1 | cut -f 5 -d " " )
# P2SH_address=$( tail -n4 tmp_cfile | head -n 1 )
# echo "reference: $ref_redeemscripthash" > tmp_cfile
# echo "reference: $ref_P2SH_address"    >> tmp_cfile
# echo "result:    $redeemscripthash"    >> tmp_cfile
# echo "result:    $P2SH_address"        >> tmp_cfile
# if [ "$ref_P2SH_address" == "$P2SH_address" ] ; then
#   echo "ok" >> tmp_cfile
# else
#   echo "fail" >> tmp_cfile
# fi
# chksum_ref="7b29169e5b53d0977709f18cc302e4a8202bc7a3f604a369987a62f3d8281bd9"
# chksum_prep

echo " " | tee -a $logfile
}


testcase11() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 11: Testnet multisig (carbide 80 and 81)        ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 11a: create redeemscript and multisig address"       | tee -a $logfile
echo "https://people.xiph.org/~greg/escrowexample.txt"
echo "carbide80: " >> $logfile
echo "   pubkey:  0343947d178f20b8267488e488442650c27e1e9956c824077f646d6ce13a285d84" >> $logfile
echo "   address: mirQLRn6ciqa3WwJSSe7RSJNVfAE9zLkS5" >> $logfile
echo "carbide81: " >> $logfile
echo "   pubkey:  0287f9169e265380a87cfd717ec543683f572db8b5a6d06231ff59c43429063ae4" >> $logfile
echo "   address: mpzXCDpitVhGe1WofQXjzC1zgxGA5GCfg5" >> $logfile
echo "redeemscript: <2><pk carbide81><pk carbide80><2>: " >> $logfile
echo "   address: 2MxKEf2su6FGAUfCEAHreGFQvEYrfYNHvL7" >> $logfile
echo "./tcls_create.sh -T -m 2 2 0287f9169e265380a87cfd717ec543683f572db8b5a6d06231ff59c43429063ae4,0343947d178f20b8267488e488442650c27e1e9956c824077f646d6ce13a285d84" >> $logfile
./tcls_create.sh -T -m 2 2 0287f9169e265380a87cfd717ec543683f572db8b5a6d06231ff59c43429063ae4,0343947d178f20b8267488e488442650c27e1e9956c824077f646d6ce13a285d84 > tmp_cfile 
chksum_ref="0b17df1f53ef9b7ed69c35bdde915a6550433070588bd091302b360fa14e16de"
chksum_prep
echo " " >> $logfile

echo "=== TESTCASE 11b: create the multisig spending tx"  | tee -a $logfile
echo "carbide80:" >> $logfile
echo " TX_IN address:   7649b33b6d80f7b5c866fbdb413419e04223974b0a5d6a3ca54944f30474d2bf" >> $logfile
echo " TX_IN vout:      0" >> $logfile
echo " TX_OUT address:  mirQLRn6ciqa3WwJSSe7RSJNVfAE9zLkS5" >> $logfile
echo " TX_OUT amount:   50" >> $logfile
echo "./tcls_create.sh -T -vv -c 7649b33b6d80f7b5c866fbdb413419e04223974b0a5d6a3ca54944f30474d2bf 0 4752210287f9169e265380a87cfd717ec543683f572db8b5a6d06231ff59c43429063ae4210343947d178f20b8267488e488442650c27e1e9956c824077f646d6ce13a285d8452ae 5000022000 5000000000 mirQLRn6ciqa3WwJSSe7RSJNVfAE9zLkS5" >> $logfile
./tcls_create.sh -T -vv -c 7649b33b6d80f7b5c866fbdb413419e04223974b0a5d6a3ca54944f30474d2bf 0 4752210287f9169e265380a87cfd717ec543683f572db8b5a6d06231ff59c43429063ae4210343947d178f20b8267488e488442650c27e1e9956c824077f646d6ce13a285d8452ae 5000022000 5000000000 mirQLRn6ciqa3WwJSSe7RSJNVfAE9zLkS5 > tmp_cfile
chksum_ref="c3d30d177a190a71e3ed0757050ddf11b6c666d9d552f133acac3dc5566d6691"
chksum_prep
echo " " >> $logfile

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
     no_cleanup=1
     shift
     ;;
  -l)
     LOG=1
     shift
     ;;
  1|2|3|4|5|6|7|8|9|10|11)
     testcase$1 
     shift
     ;;
  *)
     proc_help
     echo "unknown parameter(s), exiting gracefully ..."
     exit 0
     ;;
  esac
done

# clean up?
if [ $no_cleanup -eq 0 ] ; then 
  cleanup
fi

