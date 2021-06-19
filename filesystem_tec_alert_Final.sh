#!/bin/bash
#filesystem_tec_alert.sh
########################################################################################
#PURPOSE: Script performs File system usage checks for the SUSE Linux servers
#OVERVIEW: Can be used during File system Tech alerts investigation
#USAGE: <script name> <Directory to search for usage>
#CREATED BY: Anvesh Reddy <anveshr@dxc.com>
#Version: 1.1
#Date:7th June 2021
########################################################################################
###Variables###
DIR=$1
HASH="########################################"
DOTS="---------->"

###Main Funtion ###
main() {
        if [[ $DIR == / ]] ; then
                 echo " '/' is not accepted, please try Example: '/.snaphots' '/usr' '/var/tmp' '/tmp' '/var/log' '/var' 'home' etc., "
        else
                if [[ $DIR == /.snapshots || $DIR == /.snapshots/ ]] ; then
                        echo "$HASH"
                        echo "### checking for snapper on `uname -n` ###" && rpm -qa | grep -i snapper
	                echo "If you see snapper is installed , please follow server installation document and disable snapper" && echo "https://dxcportal.sharepoint.com/:w:/r/sites/Nestle1/TT/GLS/Deployment%20and%20Tracking/Nestle%20SR%20-%20Server%20Installation%20Document.docx"
                        echo -e "#### Looking for huge files under $DIR ####"
                        find $DIR -xdev -type f -exec du -sh {} ';' | sort -rh | head -n20 | while read output;
                        do
                        file=$(echo $output | awk '{print $2}')
                        { echo "$output" ; echo "$DOTS"; echo "Dated:$(ls -ltr $file | awk '{print $6 " " $7 " " $8}')" ; echo "$DOTS"; echo "Owner:$(ls -ltr $file | awk '{print $3 " " $4}')"; } | sed ':a;N;s/\n/ /;ba'
                        done
                        echo "$HASH"
                else
                       echo "$HASH"
                       echo -e "#### Looking for huge files under $DIR ####"
                       find $DIR -xdev -type f -exec du -sh {} ';' | sort -rh | head -n20 | while read output;
                        do
                        file=$(echo $output | awk '{print $2}')
                        { echo "$output" ; echo "$DOTS"; echo "Dated:$(ls -ltr $file | awk '{print $6 " " $7 " " $8}')" ; echo "$DOTS"; echo "Owner:$(ls -ltr $file | awk '{print $3 " " $4}')"; } | sed ':a;N;s/\n/ /;ba'
                        done
                        echo "$HASH"
                fi

        fi

}

###Verify Arguments Passed to Script###
Check_Argument () {
    if [[ $# -eq 0 ]]  ; then
           echo "Usage: Please provide a directory as script argument."
           echo "Example:'$0 /tmp' "
           exit;
    else 
        if [[ ! -d "$DIR"  ]] ; then 
            echo "Error: '$1' directory not found"
        else
             main "$1"
        fi
    fi
    
}
Check_Argument "$@"

###Verify high utilized mounts and provide as suggestion###
Check_Filesystems_Size () {
echo "$HASH"
echo "Checking for directories/mount with hig utilization..."
df -Th | grep -i btrfs | grep -v boot | awk '{print $7}' | sed -n '1!p' > /tmp/akr_output.txt

for i in `cat /tmp/akr_output.txt`
do
du -sh $i >>/tmp/akr_result.txt
done

cat /tmp/akr_result.txt | sort -rh | head -n5
rm -rf /tmp/akr_output.txt /tmp/akr_result.txt
echo "$HASH"
}
while true; do
    read -p "Suggest the directories using huge space? [y/n]:" yn
    case $yn in
        [Yy]* ) Check_Filesystems_Size; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac 
done

###Verify for Read-Only File systems, if any ###
Check_ReadOnlyFilesystems () {
        echo "$HASH"
        echo "Checking for Read-Only File systems:"
        output=$(grep "[[:space:]]ro[[:space:],]" /proc/mounts)
        echo "$output" | grep -w ro | grep -vE ":|nfs|tmpfs" && echo "Read-only File system/s found" || echo "No Read-only File systems found"
        echo "$HASH"
}
while true; do
    read -p "Check for Read-Only Filesystems(if any)? [y/n]:" yn
    case $yn in
        [Yy]* ) Check_ReadOnlyFilesystems; break;;
        [Nn]* ) exit;;
        * ) echo "Please answer yes or no.";;
    esac
done