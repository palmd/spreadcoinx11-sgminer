This is improved version by girino.
Source code: https://github.com/spreadcoin-project/spreadcoinx11-sgminer

SpreadCoin thread: https://bitcointalk.org/index.php?topic=715435

******************************
*      Driver version        *
******************************
For AMD GPU you must have driver version 14.9 or higher. Previous versions have some bug which prevent 
compilation of the kernel, you will get error starting with the following words: "LLVM ERROR: Cannot select".

If you want to use older version of the drivers you can first install newer version, run
miner once to compile kernels, then install older drivers and run miner again with the same settings.

******************************
*          Wallet            *
******************************
You must you use wallet version 0.9.15.2 or newer.
If your wallet is password-ptotected than you will need either to unlock your wallet or explicitly specify mining address (see below).

******************************
*      Starting miner        *
******************************
Launch the miner using start.bat.

Edit start.bat to change mining parameters. 
For me it was also necessary to add
--gpu-platform 1
to start.bat to make it work (otherwise it was trying to mine on integrated Intel GPU). You may or may not need this.

******************************
*    Mining parameters       *
******************************
If you will try to experiment with parameters you may be able to increase your hashrate. Increasing intensity (-I) should
have large impact on the hashrate but your desktop may become unusable with high inensity.

******************************
* Mining to specific address *
******************************
Also you can mine to a specific address. To do so:

1. Use existing or better generate a new address.
2. Open debug console (Tools -> Debug Console) and enter:

    dumpprivkey SYourSpreadCoinAddress

3. You will get your private key. Open spreadcoin.conf
(C:\Users\<user>\AppData\Roaming\SpreadCoin\spreadcoin.conf on Windows 7, create it if it doesn't exist)
and add the following line:

    miningprivkey=YourPrivateKey

4. Restart your wallet if it was running. In the Mining tab you will now see notification that all mined coins will go to this address.
