#!/bin/bash -e

EPS=/dev/sda1
MOUNT=/mnt

#edit to your needs
declare -a BINARIES=(
  "$MOUNT/EFI/kali/vmlinuz"
  "$MOUNT/EFI/arch/vmlinuz-linux"
  "$MOUNT/EFI/refind/refind_x64.efi"
)

function init {
  echo "Mounting EPS to /mnt"
  umount -Rv $MOUNT &> /dev/null || true
  mount $EPS $MOUNT
  mkdir -pv $MOUNT/keys
}

function make_keys {
  # Copyright (c) 2015 by Roderick W. Smith
  # Licensed under the terms of the GPL v3
  
  echo -n "Enter a Common Name to embed in the keys: "
  read NAME
  
  openssl req -new -x509 -newkey rsa:2048 -subj "/CN=$NAME PK/" -keyout PK.key -out PK.crt -days 3650 -nodes -sha256
  openssl req -new -x509 -newkey rsa:2048 -subj "/CN=$NAME KEK/" -keyout KEK.key -out KEK.crt -days 3650 -nodes -sha256
  openssl req -new -x509 -newkey rsa:2048 -subj "/CN=$NAME DB/" -keyout DB.key -out DB.crt -days 3650 -nodes -sha256
  openssl x509 -in PK.crt -out PK.cer -outform DER
  openssl x509 -in KEK.crt -out KEK.cer -outform DER
  openssl x509 -in DB.crt -out DB.cer -outform DER
  
  GUID=`python -c 'import uuid; print(str(uuid.uuid1()))'`
  echo $GUID > myGUID.txt
  
  cert-to-efi-sig-list -g $GUID PK.crt PK.esl
  cert-to-efi-sig-list -g $GUID KEK.crt KEK.esl
  cert-to-efi-sig-list -g $GUID DB.crt DB.esl
  rm -f noPK.esl
  touch noPK.esl
  
  sign-efi-sig-list -t "$(date --date='1 second' +'%Y-%m-%d %H:%M:%S')" -k PK.key -c PK.crt PK PK.esl PK.auth
  sign-efi-sig-list -t "$(date --date='1 second' +'%Y-%m-%d %H:%M:%S')" -k PK.key -c PK.crt PK noPK.esl noPK.auth
  sign-efi-sig-list -t "$(date --date='1 second' +'%Y-%m-%d %H:%M:%S')" -k PK.key -c PK.crt KEK KEK.esl KEK.auth
  sign-efi-sig-list -t "$(date --date='1 second' +'%Y-%m-%d %H:%M:%S')" -k KEK.key -c KEK.crt db DB.esl DB.auth
  
  chmod 0600 *.key
  
  # echo ""
  # echo ""
  # echo "For use with KeyTool, copy the *.auth and *.esl files to a FAT USB"
  # echo "flash drive or to your EFI System Partition (ESP)."
  # echo "For use with most UEFIs' built-in key managers, copy the *.cer files."
  # echo ""

}


init
make_keys

cp -v *.{auth,cer,crt,esl,key} $MOUNT/keys

for BIN in ${BINARIES[@]}; do
  echo "Signing $BIN..."
  sbsign --key $MOUNT/keys/DB.key --cert $MOUNT/keys/DB.crt --output $BIN $BIN
done

rm *.{auth,cer,crt,esl,key} myGUID.txt
