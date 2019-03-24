#!/bin/bash -e

EPS=/dev/sda1
MOUNT=/mnt

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
  efi-updatevar -e -f backup-keys/old_dbx.esl dbx
  efi-updatevar -e -f compound_db.esl db
  efi-updatevar -e -f compound_KEK.esl KEK
  efi-updatevar -f PK.auth PK
}

function sign_binaries {
  for BIN in ${BINARIES[@]}; do
    echo "Signing $BIN..."
    sbsign --key DB.key --cert DB.crt --output $BIN $BIN
  done
}


init
save_keys
write_to_efi
sign_binaries

mkdir -pv $MOUNT/keys
mv -v *.{auth,cer,crt,esl,key} myGUID.txt backup-keys current-keys $MOUNT/keys/.

umount -Rv $MOUNT

echo ""
echo ""
echo "Installation complete!"
echo "You can find all the *.auth, *.cer, *.crt, *.esl, *.key files"
echo "inside your ESP/keys directory. Copy these and keep them in a"
echo "safe place. If you need to remake or reinstall your keys,"
echo "make sure to go into BIOS/UEFI and delete all current keys,"
echo "add the Microsoft Keys, and disable Secure Boot beforehand."
