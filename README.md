GITHUB messes with the text and newlines, please view in "raw" mode...

#######################################
### 1. TX_CL_SUITE -  description: ###
#######################################
A suite of shell scripts to work with Bitcoin transactions. Primary goal is to analyze a transaction. Display it in plain text, similiar to the Bitcoin core client or "www.blockchain.info" JSON output, just in plain text. Second goal is to create or sign transactions (and cold storage usage). 
This suite is based on the previous „trx2txt“ tool, which is now discontinued.

Scripts are written to run on OpenBSD and OSX and Linux systems at the command shell (ksh, bash). OthereExisting tools on the web (Bitcoin CLI tools and others), are written to work only with BASHv4. In this suite, all scripts are coded with the intention, to be (nearly) POSIX compliant. Tested on OpenBSD korn shell, MAC OSX BASHv3 and SuSE Linux BASHv4. 

Main dependency: openssl 1.0.2x is required for the signing procedures.
Other dependencies: awk, sed, bc, od ... those tools are normally installed by default on unixoid sytems.

Main program (shell script) to display contents of a transaction is „tcls_tx2txt.sh". It refers to:
   https://en.bitcoin.it/wiki/Protocol_specification#tx 
The TX_IN and TX_OUT parts are shown, with the decoded sig script and pk pubkey script details, and it's corresponding bitcoin address(es). 
Script "tcls_tx2txt.sh" has several command line options (just open with "-h" or "--help").

Code is not (yet?) written for best performance: there are many calls to shell functions (which always fork during shell execution). And also several external (Unix standard) programs are called. Code was written with the intention to understand Bitcoin TX, and not to provide run time optimized code. Anyhow, suggestions are always appreciated.
On readability: current version of programs are heavily commented, to be able to follow/understand the Bitcoin and program’s logic. 


###########################
### file tcls_tx2txt.sh ###
###########################
The main script. You'll want to start here :-) 
The program checks the parameters, checks the version of the shell (for cases where POSIX compliance can not be achieved, in particular with arrays), checks availability for all necessary sub-programs (openssl, awk, bc, ...) to decode a transaction, and then begins to break down the transactions.

Usecases:
./tcls_tx2txt.sh 
  Without parameters, the details of a sample transaction are shown, line by line.

./tcls_tx2txt.sh -f 
  read the transaction data from a file 

./tcls_tx2txt.sh -r 
  pass the hex code of a RAW TRANSACTION as option, for example the output of:
  https://blockchain.info/de/rawtx/cc8a279b0736e6a2cc20b324acc5aa688b3af7b63bbb002f46f6573c1ad84408?format=hex
  which would give some lines of hexcode. Simply cut&paste, and add after the -r parameter:
  ./tcls_tx2txt.sh -r 010000000253603b3fdb9d5e10de2172305ff68f4b5227310ba6bd81d4e1bf60c0de6183...

./tcls_tx2txt.sh -t
  pass the hex code of a TRANSACTION HASH as option, e.g.: 
  ./tcls_tx2txt.sh -t cc8a279b0736e6a2cc20b324acc5aa688b3af7b63bbb002f46f6573c1ad84408
  The script will check for network connectivity, and will then try to download the raw trx data from the given trx number.

./tcls_tx2txt.sh -u 
  pass the hex code of an UNSIGNED RAW TX as option.
  This is an advanced option, so if you created your unsigned raw trx (eventually with 'tcls_create_sign.sh' of this suite), it can be double checked.

./tcls_tx2txt.sh -v
with parameter -v, a more detailed view is provided, along the guidelines of the bitcoin wiki.

./tcls_tx2txt.sh -vv
with parameter -vv, a very detailed view is provided, including the decoding of the sig script and the public key script. Two png files are provided, which show the state machine. The script verification/decoding is supported by four helper scripts (description below): 
 tcls_in_sig_script.sh     - to decode the TX_IN script
 tcls_out_pk_script.sh     - to decode the TX_OUT script
 tcls_base58check_enc.sh   - to convert to "human readable" bitcoin addresses
 tcls_strict_sig_verify.sh - to do strict DER sig verification

to understand the particular steps to decode a transaction, run this command:
 cat tcls_tx2txt.sh | grep STEP -A 2 -B 1 
The displayed steps are derived from: https://en.bitcoin.it/wiki/Protocol_specification#tx


###########################
### 2. Supporting files ###
###########################
The supporting scripts are used by the main program (tcls_tx2txt.sh), but can also be used independantly, when provided with the correct parameters. Use the '-h' parameters with these scripts to explain. 

##################################
### file tcls_in_sig_script.sh ###
##################################
This shell script tries to decode the TX-IN sig script via it's internal simple state diagram. The way the OPCodes are processed follows the picture "tcls_in_sig_state_machine.png". At anytime the script can be used "stand alone". Without parameters, it displays as per below, alternativly just provide a sig script as parameter (or as usual, use '-h'). 

   48: OP_DATA_0x48
   30: OP_LENGTH_0x30
   45: OP_LENGTH_0x45
   02: OP_INT_0x02
   21: OP_LENGTH_0x21 *** this is SIG R
       00A428348FF55B2B:59BC55DDACB1A00F
       4ECDABE282707BA5:185D39FE9CDF05D7
       F0
   02: OP_INT_0x02
   20: OP_LENGTH_0x20 *** this is SIG S
       74232DAE76965B63:11CEA2D9E5708A0F
       137F4EA2B0E36D08:18450C67C9BA259D
       
   01: OP_SIGHASHALL *** This terminates the ECDSA signature (ASN1-DER structure)
 
   21: OP_DATA_0x21
   02: OP_INT_0x02
       025F95E8A33556E9:D7311FA748E9434B
       333A4ECFB590C773:480A196DEAB0DEDE
       E1
* This terminates the Public Key (X9.63 COMPRESSED form)
* corresponding bitcoin address is:
1HTNtayFkoBV28wqDygMbW33qSnRjxAuNR 


##################################
### file tcls_out_pk_script.sh ###
##################################
This shell script tries to decode the TX-OUT public key script via it's internal simple state diagram. The way the OPCodes are processed follows the picture "tcls_out_pk_state_machine.png". At anytime the script can be used "stand alone". Without parameters, it displays as per below, alternativly just provide a sig script as parameter (or as usual, use '-h'). 

76A9146AF1D17462C6146A8A61217E8648903ACD3335F188AC
   76: OP_DUP
   A9: OP_HASH160
   14: OP_Data14 (= decimal 20)
       6AF1D17462C6146A:8A61217E8648903A
       CD3335F1
   88: OP_EQUALVERIFY
   AC: OP_CHECKSIG
* This is a P2PKH script
6AF1D17462C6146A8A61217E8648903ACD3335F1

The string of the 20 bytes at the end of this output is the hexadecimal representation of the Bitcoin address. To show the "human readable" chars, a third script is used:

####################################
### file tcls_base58check_enc.sh ###
####################################
This shell script tries to decode the addresses in BITCOIN SCRIPTs. It reads the hex codes, does a base58 conversion, and displays the bitcoin address. At anytime the file can be used "stand alone". Without parameters, it displays as per below, alternativly just provide a sig script as parameter (or as usual, use '-h').

./tcls_base58check_enc.sh
using 010966776006953D5567439E5E39F86A0D273BEE
 
4: add 0x00 or 0x05 [P2SH] at the beginning
5. sha256
445c7a8007a93d8733188288bb320a8fe2debd2ae1b47f0f50bc10bae845c094
6. another sha256
d61967f63c7dd183914a4ae452c9f6ad5d462ce3d277798075b107615c1a8a30
7. take first four Bytes from step 6 as checksum
d61967f63c7dd183914a4ae452c9f6ad5d462ce3d277798075b107615c1a8a30
8. append checksum from step 7 to the result from step4
00010966776006953D5567439E5E39F86A0D273BEEd61967f6
9. encode Base58
16UwLL9Risc3QfPqBUvKofHmBQ7wMtjvM 


#####################################
### file tcls_testcases_tx2txt.sh ###
#####################################
This shell script supports the development process, and verifies the script output(s).
1.) creates sha256 checksums of the involved source code scripts
2.) runs script "tcls_tx2txt.sh" with different parameters and transactions
3.) sends output into a file, and calculate it’s SHA256 hash value
4.) compare checksums 

Most easily it is used like this:

  ./tcls_testcases_tx2txt.sh 

which runs all tests (time consuming). This can be easily compared on all platforms. When hash is equal on all (UNIX/POSIX type of) platforms, code is ready to be uploaded to GITHUB (or similiar). 

  ./tcls_testcases.sh -l
  "-l", a log file ("tcls_testcases.sh.log") is created. All checks are performed.

  ./tcls_testcases.sh -h
  "-h" displays a help text

  ./tcls_testcases.sh 1|2|3|4|5|6|7|8|9
  [1-9] runs only the mentioned testcases, to get quicker results

###########################
### file tcls_create.sh ###
###########################
Simple usage: create an unsigned transaction (p2pkh), and sign it later with tcls_sign.sh. Also this script contains the option to create multisig addresses and their redeem scripts.

Advanced usage 1: understanding the idea of cold storage, this is for you! The script will create a raw, unsigned transaction, as a basis for an online/cold storage combination. On the Internet connected system you would create a raw transaction, copy it to your USB stick, and run tcls_sign on the cold standby machine to sign the transaction. Then copy the signed trx back to USB, bring it back to the Internet connected machine, and send the trx to the network. 

Advanced usage 2: create a multisig redeemscript, and then the corresponding transaction (2 steps, see 2nd example below).

Usage example 1:
(You will need to know the first three parameters from the previous trx, from which you want to redeem. Start with '-h' to better understand. Also do not try this unless previous transaction is confirmed!)

  ./tcls_create.sh -c <trx hash> <output> <pubkey script> <amount> <address> 

translates into something like this:
  ./tcls_create.sh -c c3434be....5c5b7a310cc67 0 76A9141FE307887696CF781DA237DBE2E12DB05C10986A88AC 110000 12GTF5ARSrqJ2kZd4C9XyGPesoVgP5qCdM

Usage example 2 (multisig):
Assume we have a previous transaction:

         VERSION
          01000000
         TX_IN COUNT [var_int]: hex=01, decimal=1
         TX_IN[0]
          TX_IN[0] OutPoint hash (char[32])
 (1) -->   A4EF5465835CA422D1666A24083B2893C3E065273...
          TX_IN[0] OutPoint index (uint32_t)
 (2) -->   hex=01000000, reversed=00000001, decimal=1
          TX_IN[0] Script Length (var_int)
           hex=6B, decimal=107
          TX_IN[0] Script Sig (uchar[])
           47304402202E733DD23EB16130C3AA705CD04FFA3...
          TX_IN[1] Sequence (uint32_t)
           FFFFFFFF
         TX_OUT COUNT, hex=01, decimal=1
          TX_OUT[0] Value (uint64_t)
 (3) -->   hex=A6EA170000000000, bitcoin=0.01567398
          TX_OUT[0] PK_Script Length (var_int)
           hex=17, dec=23
          TX_OUT[0] pk_script (uchar[])
 (4) -->   76A914FF57CB19528C04096067B8DB38D18ECD0B37789388AC
          LOCK_TIME
         00000000

First we need to create a redeemscripthash:
./tcls_create.sh -m <n> <m> <comma separated list of pubkeys>
--> returns multisig address (starting with "3") and redeem script hash (5)

Then we would create the transaction (notice the redeemscripthash at the end):
./tcls_create.sh -p -c <prev tx id (1)> <prev output index (2)> <prev pubkey script (4)>
                       <amount (3)> <redeemscripthash (5)> 
--> creates the transaction (6)

./tcls_sign.sh <raw_trx (6)> -w|-x <privkey> -p <pubkey>
--> signs the transaction (n times of an "n of m" msig tx, with the corresponding priv/pub key) 

#####################################
### file tcls_testcases_create.sh ###
#####################################
This shell script supports the development process, and verifies the script output(s).
It is setup the exactly same way as 'tcls_testcases_tx2txt.sh'. Details up there ...
Most easily it is used like this:

  ./tcls_testcases_create.sh 

#########################
### file tcls_sign.sh ###
#########################
Advanced usage! As per above (tcls_create.sh), this is the script that follows logically after the creation of an unsigned raw transaction, and will sign it (preferably on a cold storage system). 

Usage example:
  ./tcls_sign.sh -v <raw_trx> -w <privkey> -p <pubkey>

translates into something like this:
  ./tcls_sign.sh -v 0100000003bbb...ac0000000001000000 -w KyP5KE...tQPcN4 -p 03cc5d...8dced0

Hint: in this version the sign process allows for many inputs, which can also be read from file. 
See ./tcls_sign.sh -h for more info.

###################################
### file tcls_testcases_sign.sh ###
###################################
This shell script supports the development process, and verifies the script output(s).
It is setup the exactly same way as 'tcls_testcases_tx2txt.sh'. Details up there ...
Most easily it is used like this:

  ./tcls_testcases_create.sh 

############################
### file tcls_key2pem.sh ### 
############################
This shell script is necessary when the signing process is executed. The signature is done using the 'openssl' suite, which requires PEM keys. This script helps to convert from wif, wif-c or hex to PEM. At anytime the file can be used "stand alone", or as usual, use '-h'.

Hint: this tool is now extended with strict DER checks for the signature (see below 'tcls_strict_sig_verify.sh').

######################################
### file tcls_testcases_key2pem.sh ###
######################################
This shell script supports the development process, and verifies the script output(s).
It is setup the exactly same way as 'tcls_testcases_tx2txt.sh'. Details up there ...
Most easily it is used like this:

  ./tcls_testcases_key2pem.sh 

######################################
### file tcls_strict_sig_verify.sh ### 
######################################
This shell script contains the logic to verify strictly the DER signatures. Script is used by tcls_tx2txt.sh and tcls_create.sh, but can be used standalone as well. When used standalone, just provide the transaction input signature (beginning with hex code 30) as parameter (or as usual, use '-h').

#######################################
### file tcls_verify_bc_address.awk ###
#######################################
This awk script is a little helper tool, to make the code be more transportable. It is used by 
tcls_create.sh and tcls_key2pem.sh.

###################################
### file tcls_verify_hexkey.awk ###
###################################
This awk script is a little helper tool, to make the code be more transportable. It is used by 
tcls_create.sh and tcls_key2pem.sh.

#########################
### 3. Documentation: ###
#########################
README.md                         - this file :-)
Changelog.txt                     - view changes over the files 
tcls.conf                         - a global config file for all scripts 
tcls_in_sig_state_machine.graphml - graphics source file for the state machine
                                    (java based app: "yEd Graph Editor")
tcls_in_sig_state_machine.png     - the exported png for script sig part
tcls_out_pk_state_machine.graphml - graphics source file for the state machine
                                    (java based app: "yEd Graph Editor")
tcls_out_pk_state_machine.png     - the exported png for PUBKEY script
todos.txt                         - what needs to be done (in the future)

Documentation files are not included in the hashing with any testcases.


