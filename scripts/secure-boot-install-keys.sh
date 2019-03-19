#!/bin/bash -e

# edit to your needs
declare -a BINARIES=(
"$MOUNT/EFI/kali/vmlinuz"
"$MOUNT/EFI/arch/vmlinuz-linux"
"$MOUNT/EFI/refind/refind_x64.efi"
)

function init {
  echo "Mounting EPS to /mnt"
  umount -Rv $MOUNT &> /dev/null || true
  mount $EPS $MOUNT
}

function save_keys {
  echo "Attempting to backup current Secure Boot Keys"

  mkdir -v current-keys && cd current-keys
  efi-readvar -v PK -o old_PK.esl
  efi-readvar -v KEK -o old_KEK.esl
  efi-readvar -v db -o old_db.esl
  efi-readvar -v dbx -o old_dbx.esl
  cd ..
}

function write_to_efi {
  efi-updatevar -e -f old_dbx.esl dbx
  efi-updatevar -e -f compound_db.esl db
  efi-updatevar -e -f compound_KEK.esl KEK
  efi-updatevar -f PK.auth PK
}

function sign_binaries {
  for BIN in ${BINARIES[@]}; do
    echo "Signing $BIN..."
    sbsign --key $MOUNT/keys/DB.key --cert $MOUNT/keys/DB.crt --output $BIN $BIN
  done
}


init
write_to_efi
sign_binaries

rm *.{auth,cer,crt,esl,key} myGUID.txt
