cd ../indri_stuff || exit
rm -rf tmp
rm -f email_v1.kch
kchashmgr create email_v1.kch
mkdir tmp
FOLDERSDIR=$HOME/mutt_mail/OracleIMAP
ls $FOLDERSDIR | while read folder ; do
	echo Reading $folder
	email_v1/transform_emails.pl "$FOLDERSDIR/$folder" `pwd`/tmp || exit
done || exit
rm -rf email_v1_index
IndriBuildIndex email_v1/build_index.xml 
dumpindex email_v1_index s
