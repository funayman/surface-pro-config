#!/bin/bash -e

EPS=/dev/sda1
MOUNT=/mnt

function init {
  echo "Mounting EPS to /mnt"
  umount -Rv $MOUNT &> /dev/null || true
  mount $EPS $MOUNT
}

function save_keys {
  echo "Attempting to backup current Secure Boot Keys"

  mkdir -v backup-keys && cd backup-keys
  efi-readvar -v PK -o old_PK.esl
  efi-readvar -v KEK -o old_KEK.esl
  efi-readvar -v db -o old_db.esl
  efi-readvar -v dbx -o old_dbx.esl
  cd ..
}

function make_keys {
  # Original code credit for this function goes to:
  # Copyright (c) 2015 by Roderick W. Smith
  # Licensed under the terms of the GPL v3
  # Modifications by drt

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

  ## combine Microsoft Windows Data
  cat backup-keys/old_KEK.esl KEK.esl > compound_KEK.esl
  cat backup-keys/old_db.esl DB.esl > compound_db.esl

  sign-efi-sig-list -t "$(date --date='1 second' +'%Y-%m-%d %H:%M:%S')" -k PK.key -c PK.crt PK PK.esl PK.auth
  sign-efi-sig-list -t "$(date --date='1 second' +'%Y-%m-%d %H:%M:%S')" -k PK.key -c PK.crt PK noPK.esl noPK.auth
  sign-efi-sig-list -t "$(date --date='1 second' +'%Y-%m-%d %H:%M:%S')" -k PK.key -c PK.crt KEK compound_KEK.esl compound_KEK.auth
  sign-efi-sig-list -t "$(date --date='1 second' +'%Y-%m-%d %H:%M:%S')" -k KEK.key -c KEK.crt db compound_db.esl compound_db.auth

  chmod 0400 *.key
}

function reboot_and_delete {
  echo ""
  echo ""
  echo "Sucessfully created Secure Boot Keys!"
  echo "You'll need to manually delete your current Secure Boot Keys in your BIOS/UEIF"
  echo "Make sure to delete, and then re-enable Secure Boot to put it into"
  echo "Setup Mode. This is necessary for the next step. After run the next script."
  echo ""
  echo -n "Your machine will automatically reboot (Press CTRL-Z to cancel) in"
  for i in {10..1}
  do
    echo -n ...$i
    sleep 1
  done
  echo ""
  echo ""
  echo "REBOOT!"
  reboot
}


init
save_keys
make_keys
reboot_and_delete
