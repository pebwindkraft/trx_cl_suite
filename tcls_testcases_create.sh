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
chksum_ref="e00bc2c4b1080570fd1ae17ff2b750def840dd2626ddf845fa596187ba60f822" 
chksum_prep

echo "=== TESTCASE 1b: $chksum_cmd tcls_key2pem.sh" | tee -a $logfile
cp tcls_key2pem.sh tmp_cfile
chksum_ref="0b5fb56e663368f7e011e49b8caf3560aff87c3176c1608b482f398c1deaaf1f" 
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
echo "=== ATTENTION:  THIS SCRIPT REMOVES THE BITCOIN.21.CO LINES  ===" | tee -a $logfile
echo "===             they would change the chksums all the time,  ===" | tee -a $logfile
echo "===             and make verification impossible.            ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 2a: manually create a simple unsigned, raw trx"      >> $logfile
echo "./$create_cmd -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
chksum_ref="4c33752818ea4161273fd623e24be36758f871b0f06a8b9c70c0dd65ed87464e" 
chksum_prep

echo "=== TESTCASE 2b: -c and -f params - that clashes" | tee -a $logfile
echo "./$create_cmd -c -f 76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -c -f 76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_cfile
chksum_ref="f6fba22a6f9159c66bb4a237182246135260bc1b6cf67cdf00c99978abd191d0" 
chksum_prep

echo "=== TESTCASE 2c: -c and -m params - that clashes" | tee -a $logfile
echo "./$create_cmd -c -m 76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -c -m 76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_cfile
chksum_ref="f6fba22a6f9159c66bb4a237182246135260bc1b6cf67cdf00c99978abd191d0" 
chksum_prep

echo "=== TESTCASE 2d: -c and -t params - that clashes" | tee -a $logfile
echo "./$create_cmd -c -t 76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -c -t 76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_cfile
chksum_ref="f6fba22a6f9159c66bb4a237182246135260bc1b6cf67cdf00c99978abd191d0" 
chksum_prep

echo "=== TESTCASE 2e: TX fee value is non numeric" | tee -a $logfile
echo "./$create_cmd -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm 50a 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm 50a > tmp_cfile
chksum_ref="7821bec085fcfc41ec44b20176836d905c1f18a174fbb3cfb4bb647bdeca1900" 
chksum_prep

echo "=== TESTCASE 2f: Return address is invalid ('x' at the end)" | tee -a $logfile
echo "./$create_cmd -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm 50 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdMx" >> $logfile
./$create_cmd -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm 50 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdMx > tmp_cfile
chksum_ref="86b6dfc9028a8de7d1aafd56b9fbe8f7895d9e209befbac97b1a884bd7f48896" 
chksum_prep

echo "=== TESTCASE 2g: same as 2a, with verbose output"          | tee -a $logfile
echo "=== ATTENTION:   THIS SCRIPT REMOVES THE BITCOIN.21.CO LINES" >> $logfile
echo "===              they would change the chksums all the time," >> $logfile
echo "===              and make verification impossible.          " >> $logfile
echo "./$create_cmd -v -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -v -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
chksum_ref="3f52f3cb3a49c3a47efe826d6fe3b4d41246b634a160229fe466449192ba8d81" 
chksum_prep

echo "=== TESTCASE 2h: same as 2a, with very verbose output"    | tee -a $logfile
echo "=== ATTENTION:   THIS SCRIPT REMOVES THE BITCOIN.21.CO LINES" >> $logfile
echo "===              they would change the chksums all the time," >> $logfile
echo "===              and make verification impossible.          " >> $logfile
echo "./$create_cmd -vv -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -vv -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99990000 99900000 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
chksum_ref="b1a0c6e44ada4d13fcb60f468e694e713c16605b97a4bbf3b6fd504f9bec9ab2" 
chksum_prep

echo " " | tee -a $logfile
}

testcase3() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 3: intensive params testing ...                 ===" | tee -a $logfile
echo "=== ATTENTION:  THIS SCRIPT REMOVES THE BITCOIN.21.CO LINES  ===" | tee -a $logfile
echo "===             they would change the chksums all the time,  ===" | tee -a $logfile
echo "===             and make verification impossible.            ===" | tee -a $logfile
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
./$create_cmd -c 96534da2f213367a6d589f18d7d6d1689748cd911f8c33a9aee754a80de166be 0 1976a914dd6cce9f255a8cc17bda8ba0373df8e861cb866e88ac 135000 118307 14zWNsgUMmHhYx4suzc2tZD6HieGbkQi5s | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
chksum_ref="87d160b872ac30b7020ce9e9fe20b4b040877adf57784c99e5e41bc7784797f8"
chksum_prep

echo " " | tee -a $logfile
}

testcase4() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 4: 4a, 4b and 4c not ok, 4d ok                  ===" | tee -a $logfile
echo "=== ATTENTION:  THIS SCRIPT REMOVES THE BITCOIN.21.CO LINES  ===" | tee -a $logfile
echo "===             they would change the chksums all the time,  ===" | tee -a $logfile
echo "===             and make verification impossible.            ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 4a: wrong bitcoin adress hash (x at end)"            | tee -a $logfile
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
chksum_ref="7f8a04af6ad90d2c28e4dbc3d1aa83eb69574a6650c3ef320f45079a126fc1f1" 
chksum_prep

echo "=== TESTCASE 4d: and now with correct bitcoin adress hash" | tee -a $logfile
echo "./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
chksum_ref="ff682c883648956bbeb40a2104974d327e37d7eb2b2132482081be7f8ac4f99c" 
chksum_prep
echo " " | tee -a $logfile
}

testcase5() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 5: Addresses with leading 1s ...                ===" | tee -a $logfile
echo "=== ATTENTION:  THIS SCRIPT REMOVES THE BITCOIN.21.CO LINES  ===" | tee -a $logfile
echo "===             they would change the chksums all the time,  ===" | tee -a $logfile
echo "===             and make verification impossible.            ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 5a: 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM " | tee -a $logfile
echo "./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
chksum_ref="3dffff007a8f712f52c3489aff0da6bc5d0f200997715c56bb094b2f3705382f"
chksum_prep

echo "=== TESTCASE 5b: 112ZbzFcSpcCoY2EfPNmgxFmv4tVuLSoB4 " | tee -a $logfile
echo "./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 112ZbzFcSpcCoY2EfPNmgxFmv4tVuLSoB4 " >> $logfile
./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 112ZbzFcSpcCoY2EfPNmgxFmv4tVuLSoB4 | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
chksum_ref="b9c755f2c0faafdd895f9959735af9b30237bc66a584e56cc8a8adc4b38787de"
chksum_prep

echo "=== TESTCASE 5c: 1111DAYXhoxZx2tsRnzimfozo783x1yC2" | tee -a $logfile
echo "./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 1111DAYXhoxZx2tsRnzimfozo783x1yC2 " >> $logfile
./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 1111DAYXhoxZx2tsRnzimfozo783x1yC2 | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
chksum_ref="a8294b72a350276036d515fcdaa7b1de27e4e5f4c520ee5b7dd553aa8eb0bdf3"
chksum_prep

echo "=== TESTCASE 5d: 1111VHuXEzHaRCgXbVwojtaP7Co3QABb" | tee -a $logfile
echo "./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 1111VHuXEzHaRCgXbVwojtaP7Co3QABb " >> $logfile
./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 1111VHuXEzHaRCgXbVwojtaP7Co3QABb | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
chksum_ref="073acbdd5c00310c59b8c290bdfaabe4795e14ea1bbc9150cc63d6ab438c9134"
chksum_prep

echo "=== TESTCASE 5e: 1111KiuFyqUXJFji8KQnoHC5Rtqa5d5e" | tee -a $logfile
echo "./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 1111KiuFyqUXJFji8KQnoHC5Rtqa5d5e " >> $logfile
./$create_cmd -v -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 1111KiuFyqUXJFji8KQnoHC5Rtqa5d5e | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
echo "./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u" >> $logfile
./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u >> tmp_cfile
chksum_ref="4ad1915d7f87b6f17ad800f72295c39cd3bcdf0ffd35cd705cd1550161f00bd7"
chksum_prep

echo "=== TESTCASE 5f: 1111LexYVhKvaQY69Paj774F9gnjhDrr " | tee -a $logfile
echo "./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 1111LexYVhKvaQY69Paj774F9gnjhDrr" >> $logfile
./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 1111LexYVhKvaQY69Paj774F9gnjhDrr | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
echo "./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u" >> $logfile
./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u >> tmp_cfile
chksum_ref="370838b91d2e23a19c2ff91528a1991cafcacda5be1931d6eaf357e1e521f4b5"
chksum_prep

echo "=== TESTCASE 5g: 111113CRATaaDmCcWzokzTGhM886kj2bs" | tee -a $logfile
echo "./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 111113CRATaaDmCcWzokzTGhM886kj2bs " >> $logfile
./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 111113CRATaaDmCcWzokzTGhM886kj2bs | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
echo "./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u" >> $logfile
./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u >> tmp_cfile
chksum_ref="9a6dd2bf9ff2f4a671b309219c79c87a75566d66c50cb8e0f0ef75af586305d0"
chksum_prep

echo "=== TESTCASE 5h: 1111111111111111111114oLvT2 " | tee -a $logfile
echo "./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 1111111111111111111114oLvT2 " >> $logfile
./$create_cmd -vv -c 7423fd7c2c135958e3417bb4d192c33680bcda2c5cb8549209d36323275338f9 1 1976a9147A8911A06EF9A75A6CB6AF47D72A99A9B6ECB77988ac 117000 100000 1111111111111111111114oLvT2 | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
echo "./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u" >> $logfile
./tcls_tx2txt.sh -vv -f tmp_c_utx.txt -u >> tmp_cfile
chksum_ref="41b09e9f9b1b78a6865f83275ac195f7e2248fd8ed5e8ddbcf7c3897a3b9714f" 
chksum_prep

echo " " | tee -a $logfile
}

testcase6() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 6: usage of param '-t' (read tx from network)   ===" | tee -a $logfile
echo "=== ATTENTION:  THIS SCRIPT REMOVES THE BITCOIN.21.CO LINES  ===" | tee -a $logfile
echo "===             they would change the chksums all the time,  ===" | tee -a $logfile
echo "===             and make verification impossible.            ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 6a: TX has insufficient amount"                      | tee -a $logfile

echo "./$create_cmd -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1070000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1070000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
chksum_ref="6a8c20be3342b4d40b64657d78d52a7dde71d340cd6807f55379ce03bbd2cade"
chksum_prep

echo "=== TESTCASE 6b: same as 6a, verbose output" | tee -a $logfile
echo "./$create_cmd -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1070000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1070000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
chksum_ref="c273e54ba8d7b1b1d1cf4e87945e88a62c6d711570510f32040c7402650f8fb0" 
chksum_prep

echo "=== TESTCASE 6c: same as 6b, ok, and with 77 Satoshi per Byte TXFEE" | tee -a $logfile
echo "./$create_cmd -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1070000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 77" >> $logfile
./$create_cmd -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1070000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 77 > tmp_cfile
chksum_ref="9f8a22f7aea931243ea40bef962981e9cd3b32dce7b7b1367e103d8aadb3f7ba" 
chksum_prep

echo "=== TESTCASE 6d: same as 6c, with parameter for a return address" | tee -a $logfile
echo "./$create_cmd -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1070000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 77 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -v -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1070000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 77 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_cfile
chksum_ref="8cf73afc63743f79e561ca9f5ea1334a7fd7a8a640944568bb471ccfaf139b39" 
chksum_prep

echo "=== TESTCASE 6e: same as 6d, VERY VERBOSE output" | tee -a $logfile
echo "./$create_cmd -vv -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1070000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 77 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm" >> $logfile
./$create_cmd -vv -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 1070000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM 77 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm > tmp_cfile
chksum_ref="8689230556c2803d0e1318563c777a3c8f4fd8efbea619b4c75287c28f97f674" 
chksum_prep

echo "=== TESTCASE 6f: fetch also Satoshi/Byte from bitcoinfees.21.co " | tee -a $logfile
echo "./$create_cmd -vv -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 999999 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -vv -t 1de803fe2e3795f7b92d5acc113d3e452939ec003ce83309386ce4213c6812bc 0 999999 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
chksum_ref="6bf61e3f3a9176e66d5d1d6dd8fec97ab6322b3b3de88eab8d5a35cf4ca77b1d" 
chksum_prep

echo " " | tee -a $logfile
}

testcase7() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 7: several trx with wrong parameters:           ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 7a: insufficient input" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 19235" > tmp_3inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 16197" >> tmp_3inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 23940" >> tmp_3inputs.txt
echo "./$create_cmd -v -f tmp_3inputs.txt 70000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
./$create_cmd -v -f tmp_3inputs.txt 70000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM > tmp_cfile
chksum_ref="6eb2717bba507572ce4258cd332db715aeb419dc4ab9bb8301400135a0a2080e" 
chksum_prep

echo "=== TESTCASE 7b: wrong output address (x at the end)" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 19235" > tmp_3inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 16197" >> tmp_3inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 23940" >> tmp_3inputs.txt
echo "./$create_cmd -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcx" >> $logfile
./$create_cmd -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcx > tmp_cfile
chksum_ref="4473c47405f3b2d91d36b81308554900c20e89c4de45f94d73f633709831d7b4" 
chksum_prep

echo "=== TESTCASE 7c: wrong length of trx hash (63 chars)" | tee -a $logfile
echo "4fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 39235" > tmp_3inputs.txt
echo "3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 16197" >> tmp_3inputs.txt
echo "74cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 23940" >> tmp_3inputs.txt
echo "./$create_cmd -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
./$create_cmd -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM > tmp_cfile
chksum_ref="a177b1f63af94a8436b1acd4bf23fb3af56f4c3b48e1a484854c5f7587a022e4" 
chksum_prep

echo "=== TESTCASE 7d: insufficient trx fee" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 39255" > tmp_3inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 19999" >> tmp_3inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 27996" >> tmp_3inputs.txt
echo "./$create_cmd -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 50" >> $logfile
./$create_cmd -v -f tmp_3inputs.txt 50000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM 50 > tmp_cfile
chksum_ref="10542ab9ea032851fd0949efe30a522917dcd14f6aee8d35497e0f5aba1a4d49" 
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
chksum_ref="803d9713d8772c2a5638351cdb8b8f82fdef0a81f5de24e9f4951bab00108020"
chksum_prep

echo " " | tee -a $logfile
}

testcase8() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 8: some multi input trx with 3, 5 and 20 inputs ===" | tee -a $logfile
echo "=== ATTENTION:  THIS SCRIPT REMOVES THE BITCOIN.21.CO LINES  ===" | tee -a $logfile
echo "===             they would change the chksums all the time,  ===" | tee -a $logfile
echo "===             and make verification impossible.            ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 8a: 3 inputs to a trx"                               | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 49265" > tmp_3inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 18887" >> tmp_3inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 50000" >> tmp_3inputs.txt
echo "./$create_cmd -vv -f tmp_3inputs.txt 80000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
./$create_cmd -vv -f tmp_3inputs.txt 80000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
chksum_ref="a8ac7b9f08b99099e5bc2492b5f4641e517b95ee7cc122327db912f97156fbca" 
chksum_prep

echo "=== TESTCASE 8b: 5 inputs to a trx" | tee -a $logfile
echo "94fae0ac28792796063f23f4a4ba4f977a9599d1579c5aae7ce6dda4f8a6b1bb 1044 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 39235" > tmp_5inputs.txt
echo "a3e719b12275357b15fc5decd9088a0964fe860d49f026f2152e71f681ac3fa4 1073 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 48197" >> tmp_5inputs.txt
echo "874cd4c4e1683c43a98a9daa0926bea37c10616f165ac35481e8181bfd449c65 480 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 26940" >> tmp_5inputs.txt
echo "722a2ad4daa66382abe4c54676cfe1299ac52a239b4b79b6c6f66e5c5fefe32c 475 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 6886" >> tmp_5inputs.txt
echo "0d87c9c4146452dd8f97f646b52a9dda5a6645d068aca5f1a2a214d37507c5b5 989 76A914A438060482FCD835754EA4518C70CC2085AF48FA88AC 19099" >> tmp_5inputs.txt
echo "./$create_cmd -v -f tmp_5inputs.txt 110180 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM" >> $logfile
./$create_cmd -v -f tmp_5inputs.txt 110180 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
chksum_ref="88c47e6515f61c18e3917f194a0520543f42dff71f1ed52cc87e4123bb19a525"
chksum_prep

echo "=== TESTCASE 8c: 23 inputs to a trx" | tee -a $logfile
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
./$create_cmd -f tmp_23inputs.txt 450000 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
chksum_ref="a2d6cc5615b1542a2fc3977af22ac63c4e5dd99252a35d69f86762bcbc850884" 
chksum_prep


echo "=== TESTCASE 8d: 53 inputs to a trx" | tee -a $logfile
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
./$create_cmd -f tmp_53inputs.txt 1017840 1JmPRDELzWZqRBKtdiak3iiyZrPQT3gxcM | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
chksum_ref="3d14cd803ef11eb0578d3a709f55368da0e6c6489bbd2b36ca3d6efdac91adc0" 
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
chksum_ref="fd4bdec669f3bb7662411b8e302b4a73333e254a76d68c5c4bf14bcb8eff1249"
chksum_prep

echo "=== TESTCASE 9b: msig, 2of3, only 2 addresses" | tee -a $logfile 
echo "./$create_cmd -m 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM" >> $logfile 
./$create_cmd -m 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM > tmp_cfile
chksum_ref="7358768f3bdd03de24d5457c02aaaa476b220cac7518ad9558865a4cd8ebacbb"
chksum_prep

echo "=== TESTCASE 9c: msig, 2of16, invalid, max=15" | tee -a $logfile
echo "./$create_cmd -m 2 16 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -m 2 16 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="519dc5ceeaa85193fe0667d20b14c53b620d7f1b82faea3f66855e86ea2862c9"
chksum_prep

echo "=== TESTCASE 9d: msig, 3of2, invalid, 3of2 does not work :-)" | tee -a $logfile
echo "./$create_cmd -v -m 3 2 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -v -m 3 2 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="b1fbc0198b8c2afd362631fc59a4db3c9438d45e564bb99d937cddaf214f27da"
chksum_prep

echo "=== TESTCASE 9e: -m and -f params - that clashes!" | tee -a $logfile
echo "./$create_cmd -v -m -f 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -v -m -f 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="f078cb8b0b8915a9bc9d5d0f4e80b3b8d8649c26bb584bec79fa96985d6ae934"
chksum_prep

echo "=== TESTCASE 9f: -m and -c params - that clashes!" | tee -a $logfile
echo "./$create_cmd -v -m -c 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -v -m -c 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="f078cb8b0b8915a9bc9d5d0f4e80b3b8d8649c26bb584bec79fa96985d6ae934"
chksum_prep

echo "=== TESTCASE 9g: -m and -t params - that clashes!" | tee -a $logfile
echo "./$create_cmd -v -m -t 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -v -m -t 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="f078cb8b0b8915a9bc9d5d0f4e80b3b8d8649c26bb584bec79fa96985d6ae934"
chksum_prep

echo "=== TESTCASE 9h: msig, 2of3, but wrong bitcoin pubkeys" | tee -a $logfile
echo "./$create_cmd -m 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM" >> $logfile
./$create_cmd -m 2 3 1runeksijzfVxyrpiyCY2LCBvYsSiFsCm,16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM,12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM > tmp_cfile
chksum_ref="233c0a616e2e8690ce886fb9ed415a73adf0aaa278a92181660e2c071165ec75"
chksum_prep

echo "=== TESTCASE 9i: msig 2of3, uncompressed pubkeys, ok ..."          | tee -a $logfile
echo "    https://gist.githubusercontent.com/gavinandresen/3966071/raw/" >> $logfile
echo "    1f6cfa4208bc82ee5039876b4f065a705ce64df7/TwoOfThree.sh"        >> $logfile
echo "./$create_cmd -v -m 2 3 0491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f86,04865c40293a680cb9c020e7b1e106d8c1916d3cef99aa431a56d253e69256dac09ef122b1a986818a7cb624532f062c1d1f8722084861c5c3291ccffef4ec6874,048d2455d2403e08708fc1f556002f1b6cd83f992d085097f9974ab08a28838f07896fbab08f39495e15fa6fad6edbfb1e754e35fa1c7844c41f322a1863d46213" >> $logfile
./$create_cmd -v -m 2 3 0491bba2510912a5bd37da1fb5b1673010e43d2c6d812c514e91bfa9f2eb129e1c183329db55bd868e209aac2fbc02cb33d98fe74bf23f0c235d6126b1d8334f86,04865c40293a680cb9c020e7b1e106d8c1916d3cef99aa431a56d253e69256dac09ef122b1a986818a7cb624532f062c1d1f8722084861c5c3291ccffef4ec6874,048d2455d2403e08708fc1f556002f1b6cd83f992d085097f9974ab08a28838f07896fbab08f39495e15fa6fad6edbfb1e754e35fa1c7844c41f322a1863d46213 > tmp_cfile
chksum_ref="d68b3d83ece6eec5462da55087d0f2246c945f4467c025b625b35f985635964a"
chksum_prep

echo "=== TESTCASE 9j: msig 2of3, uncompressed pubkeys, ok ..."          | tee -a $logfile
echo "    https://bitcointalk.org/index.php?topic=82213.msg906833#msg906833" >> $logfile
echo "./$create_cmd -v -m 2 3 0446fc07bc99bef8e7a875249657c65e1f1793fd0bf45e2c39d539b6f8fcd44676acc552ab886c11eb08f4a275e7bb7dc4fdaf9c4b2228856f168a69df7d216fbc,04df70eb0107ed08e1ddcd4b4d85d26bf8cca301f5c98fd15f5efef12ba4de72bfef7287f964e304207164c003029449740aaae2d6af1ff7ae3f6bb27f3012296c,046003581a3ff5bc3dedaa6da4834ce7bcd49d3f114ce15791f6b5de8b0cec81a46db2eb8cf84d2db845854c57788c7283ab4040aeb3595bc5c68303a17fdde7c8" >> $logfile
./$create_cmd -v -m 2 3 0446fc07bc99bef8e7a875249657c65e1f1793fd0bf45e2c39d539b6f8fcd44676acc552ab886c11eb08f4a275e7bb7dc4fdaf9c4b2228856f168a69df7d216fbc,04df70eb0107ed08e1ddcd4b4d85d26bf8cca301f5c98fd15f5efef12ba4de72bfef7287f964e304207164c003029449740aaae2d6af1ff7ae3f6bb27f3012296c,046003581a3ff5bc3dedaa6da4834ce7bcd49d3f114ce15791f6b5de8b0cec81a46db2eb8cf84d2db845854c57788c7283ab4040aeb3595bc5c68303a17fdde7c8 > tmp_cfile
chksum_ref="acb5aeb10e01e3c106ad7065212e62f3c69f595448520d7a3ad98dc051072a2b"
chksum_prep

echo "=== TESTCASE 9k: msig 2of3, uncompressed pubkeys, ok ..." | tee -a $logfile
echo "./$create_cmd -v -m 2 3 04a882d414e478039cd5b52a92ffb13dd5e6bd4515497439dffd691a0f12af9575fa349b5694ed3155b136f09e63975a1700c9f4d4df849323dac06cf3bd6458cd,046ce31db9bdd543e72fe3039a1f1c047dab87037c36a669ff90e28da1848f640de68c2fe913d363a51154a0c62d7adea1b822d05035077418267b1a1379790187,0411ffd36c70776538d079fbae117dc38effafb33304af83ce4894589747aee1ef992f63280567f52f5ba870678b4ab4ff6c8ea600bd217870a8b4f1f09f3a8e83" >> $logfile
./$create_cmd -v -m 2 3 04a882d414e478039cd5b52a92ffb13dd5e6bd4515497439dffd691a0f12af9575fa349b5694ed3155b136f09e63975a1700c9f4d4df849323dac06cf3bd6458cd,046ce31db9bdd543e72fe3039a1f1c047dab87037c36a669ff90e28da1848f640de68c2fe913d363a51154a0c62d7adea1b822d05035077418267b1a1379790187,0411ffd36c70776538d079fbae117dc38effafb33304af83ce4894589747aee1ef992f63280567f52f5ba870678b4ab4ff6c8ea600bd217870a8b4f1f09f3a8e83 > tmp_cfile
chksum_ref="03fcccb51d0079b4d39588ae6e686bd0d1ae1483398b04e1c100204be4981ebb"
chksum_prep

echo "=== TESTCASE 9l: msig with testnet 2of3, ok ..." | tee -a $logfile
echo "./$create_cmd -T -v -m 2 3 03834bd129bf0a2e03d53b74bc2eef8d9a5faed93f37b4938ae7127d430804a3cf,03fae2fa202fbfd9d0a8650f537df154158761ce9ad2460793aed74b946babb9f4,038cbc733032dcbed878c727840bef9c2aeb01447e1701c372c46a2ef00f48e02c" >> $logfile
./$create_cmd -T -v -m 2 3 03834bd129bf0a2e03d53b74bc2eef8d9a5faed93f37b4938ae7127d430804a3cf,03fae2fa202fbfd9d0a8650f537df154158761ce9ad2460793aed74b946babb9f4,038cbc733032dcbed878c727840bef9c2aeb01447e1701c372c46a2ef00f48e02c > tmp_cfile
chksum_ref="fb8cd92c1654d8a33b4c8a302982b85d49cf93128f1244ec108814f41c2cd48f"
chksum_prep

echo "=== TESTCASE 9m: msig: https://bitcoin.org/en/developer-examples#p2sh-multisig" | tee -a $logfile
echo "./$create_cmd -T -v -m 2 3 03310188e911026cf18c3ce274e0ebb5f95b007f230d8cb7d09879d96dbeab1aff,0243930746e6ed6552e03359db521b088134652905bd2d1541fa9124303a41e956,029e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255" >> $logfile
./$create_cmd -T -v -m 2 3 03310188e911026cf18c3ce274e0ebb5f95b007f230d8cb7d09879d96dbeab1aff,0243930746e6ed6552e03359db521b088134652905bd2d1541fa9124303a41e956,029e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255 > tmp_cfile
chksum_ref="fcc424c693eccb492410f4e510da152155b43b9c1cd085861294d8099d0dade7"
chksum_prep

echo "=== TESTCASE 9n: msig: tbd ..." | tee -a $logfile
echo "./$create_cmd -T -v -m 2 3 ..." >> $logfile
./$create_cmd -T -v -m 2 3 ... > tmp_cfile
chksum_ref="ac11872b9eb8e4caab4f6e819892251a006467c02ef249c26795abf675702ade"
chksum_prep

echo " " | tee -a $logfile
}

testcase10() {
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 10: creating multisig TX (P2SH)                 ===" | tee -a $logfile
echo "=== ATTENTION:  THIS SCRIPT REMOVES THE BITCOIN.21.CO LINES  ===" | tee -a $logfile
echo "===             they would change the chksums all the time,  ===" | tee -a $logfile
echo "===             and make verification impossible.            ===" | tee -a $logfile
echo "================================================================" | tee -a $logfile
echo "=== TESTCASE 10a: msig, to adress of 9i ... " | tee -a $logfile
echo "./$create_cmd -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 3QJmV3qfvL9SuYo34YihAf3sRCW3qSinyC" >> $logfile
./$create_cmd -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 99000000 3QJmV3qfvL9SuYo34YihAf3sRCW3qSinyC | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
chksum_ref="6579b1e49e0cd7217654771a73845cca09aefef37e7e60a3e8454db3f95f6ac8"
chksum_prep

echo "=== TESTCASE 10b: msig, to adress of 9j ... " | tee -a $logfile
echo "./$create_cmd -v -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 3EffXJKyYB9zWh2dhx2hcccqBK8DGC7x2x" >> $logfile
./$create_cmd -v -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 99000000 3EffXJKyYB9zWh2dhx2hcccqBK8DGC7x2x | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
chksum_ref="1e35895b0a83075df6f0dae1b427e01b15e3ea5ad62ea78484cb9872652e2b31"
chksum_prep

echo "=== TESTCASE 10c: msig, to adress of 9k ... " | tee -a $logfile
echo "./$create_cmd -vv -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 347N1Thc213QqfYCz3PZkjoJpNv5b14kBd" >> $logfile
./$create_cmd -vv -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 99000000 347N1Thc213QqfYCz3PZkjoJpNv5b14kBd | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
chksum_ref="2a5c83ad7d2ea8b102ac6040463a2084157fa49cdc6d1606dc86c2825aed1f2e"
chksum_prep

echo "=== TESTCASE 10d: msig, to adress of 9l ... " | tee -a $logfile
echo "./$create_cmd -v -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 2N6X3w3uG7Nrd56kkYJSMgSahKbRD5fHnVh" >> $logfile
./$create_cmd -v -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 99000000 2N6X3w3uG7Nrd56kkYJSMgSahKbRD5fHnVh | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
chksum_ref="428b97f978b9c832657a1314ab7488bacb0423c72af548cd2c38a986423542c0"
chksum_prep

echo "=== TESTCASE 10e: msig, to adress of 9m ... " | tee -a $logfile
echo "./$create_cmd -vv -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 2N7NaqSKYQUeM8VNgBy8D9xQQbiA8yiJayk" >> $logfile
./$create_cmd -vv -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 99000000 2N7NaqSKYQUeM8VNgBy8D9xQQbiA8yiJayk | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
chksum_ref="c2a8f1aa23ab37b14f4b097f7beef6b4ba972748b55187159a88242f39592436"
chksum_prep

# echo "=== TESTCASE 10l: msig, copy of 9l, executing with -T -v -m "     | tee -a $logfile
# echo "./$create_cmd -T -v -m 2 3 03310188e911026cf18c3ce274e0ebb5f95b007f230d8cb7d09879d96dbeab1aff,0243930746e6ed6552e03359db521b088134652905bd2d1541fa9124303a41e956,029e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255" >> $logfile
# ./$create_cmd -T -v -m 2 3 03310188e911026cf18c3ce274e0ebb5f95b007f230d8cb7d09879d96dbeab1aff,0243930746e6ed6552e03359db521b088134652905bd2d1541fa9124303a41e956,029e03a901b85534ff1e92c43c74431f7ce72046060fcf7a95c37e148f78c77255 | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
# ref_redeemscripthash=$( tail -n3 tmp_cfile | head -n1 )
# ref_P2SH_address=$( tail -n1 tmp_cfile )
# echo "./$create_cmd -T -vv -r -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 $ref_redeemscripthash" >> $logfile
# ./$create_cmd -T -vv -r -c F2B3EB2DEB76566E7324307CD47C35EEB88413F971D88519859B1834307ECFEC 1 76a914010966776006953d5567439e5e39f86a0d273bee88ac 99900000 $ref_redeemscripthash | sed 's/bitcoinfees.*/bitcoinfees.21.co: LINE REPLACED BY TESTCASE SCRIPT, SEE HEADER ... ###/' > tmp_cfile
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
chksum_ref="3a0f51a3cc45d2a9c24c63d38a70a66cc5b74c3cd290a59f3d90001c29b1e08b"
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
chksum_ref="02b24b4854cdf7e27c3514b192bc146b79d8d9cedfe80780ab19a01cb2136984"
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

