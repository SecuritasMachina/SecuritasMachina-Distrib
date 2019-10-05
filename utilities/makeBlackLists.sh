#!/bin/bash
export curDir="$PWD"
#echo $curDir
cd ../sources/blackLists/squidguard
tar -czf $curDir/../distrib/blacklists/securitasmachina.tgz *
tar -tzf $curDir/../distrib/blacklists/securitasmachina.tgz
cd $curDir 
 