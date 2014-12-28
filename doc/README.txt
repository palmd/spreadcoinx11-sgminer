This is improved version by girino.
Source code: https://github.com/girino/spreadcoinx11-sgminer

Please tell us about your experience in our thread: https://bitcointalk.org/index.php?topic=715435

******************************
*      Driver version        *
******************************
For AMD GPU you must have driver version 14.9 or higher. Previous versions have some bug which prevent 
compilation of the kernel, you will get error starting with the following words: "LLVM ERROR: Cannot select".

If you want to use older version of drivers for some reason you can first install newer version, run
miner once to compile kernels, then install older drivers and run miner again with the same settings.

******************************
*      Starting miner        *
******************************

IMPORTANT: you must you use wallet version 0.9.14.4 or newer.
F

If your wallet is password-ptotected than you will need either to unlock your wallet or explicitly specify mining address (see below).

Launch the miner using the following command:

    sgminer -o "http://127.0.0.1:41677" -u user -p pass --thread-concurrency 8192 --lookup-gap 2 --worksize 256 -g 2 -I 17

There is start.bat to do this, just edit it and enter your username and password that you specified in spreadcoin.conf.

For me it was also necessary to add
--gpu-platform 1
to the argument list to make it work. You may or may not need this.

******************************
*    Mining parameters       *
******************************
If you will try to experiment with parameters you may be able to increase your hashrate. Increasing intensity (-I) should
have large impact on hashrate but I can't do this because my desktop becomes unusable with high inensity.

girino uses the following command line for his miner:

    sgminer -o "http://127.0.0.1:41677" -u xxx -p xxx --thread-concurrency 8192 --lookup-gap 2 --auto-fan --temp-target 65 --gpu-engine 1100 --worksize 256 -I 21

******************************
* Mining to specific address *
******************************
Also you can mine to a specific address. To do so:

1. Use existing or better generate a new address.
2. Open debug console (Tools -> Debug Console) and enter:

    dumpprivkey SYourSpreadCoinAddress

3. You will get your private key. Open spreadcoin.conf and add the following line:
(C:\Users\<user>\AppData\Roaming\SpreadCoin\spreadcoin.conf on Windows 7, create it if it doesn't exist):

    miningprivkey=YourPrivateKey

4. Restart your wallet if it was running. In the Mining tab you will now see notification that all mined coins will go to this address.