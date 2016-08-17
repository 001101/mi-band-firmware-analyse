#!/bin/bash

set -e

APK_HOST="http://www.apkmirror.com"
APK_LIST="/uploads/?q=mi-fit"

APK_DIR="./apps/"
FW_DIR="./fw/"
TMP_DIR=".temp"

TMP_LIST="${TMP_DIR}/apk_list"
TMP_APK_SITE="${TMP_DIR}/apk_download_site"

FORCE=1 # default 1 (false)
UNZIP=1 # default 1 (false)

function download_apk {    
    echo -e "\nDownload apk site"
    curl -# -L "${APK_HOST}${1}" > "${TMP_APK_SITE}"
    FULL_NAME_APK=`xidel ${TMP_APK_SITE} -s --extract  '//h1/@title'`
    APK_VERSION=`echo ${FULL_NAME_APK} | sed 's#Mi Fit ##g'`
    DL_PAGE_URL=`xidel ${TMP_APK_SITE} -s --extract '//a[@type="button" and matches(@class, "downloadButton")]/@href'`
    THIS_APK_DIR="${APK_DIR}${APK_VERSION}"
    APK_FILE="${THIS_APK_DIR}/base_${APK_VERSION}.apk"
    if [ -e ${APK_FILE} ] && [ ${FORCE} -eq 1 ]; then
        echo "APK ${APK_FILE} already exist - skipping downloading..."
    elif [ ! -e ${APK_FILE} ] || [ ${FORCE} -eq 0 ]; then
        echo "Fetching download link for ${FULL_NAME_APK} from ${APK_HOST}${DL_PAGE_URL}"
		curl -# -L "${APK_HOST}${DL_PAGE_URL}" > "${TMP_APK_SITE}"
		APK_URL=`xidel ${TMP_APK_SITE} -s --extract '//a[matches(@data-google-vignette, "false")]/@href'`
        echo "Download ${FULL_NAME_APK} from ${APK_HOST}${APK_URL}"
        mkdir -p "${THIS_APK_DIR}"
        curl -# -L "${APK_HOST}${APK_URL}" > "${APK_FILE}"
    fi

	if [ ${UNZIP} -eq 0 ]; then
		echo "Unzip base_${APK_VERSION}.apk"
		do_unzip $APK_FILE "${THIS_APK_DIR}/unziped/"
		copy_fw "${THIS_APK_DIR}/unziped" $APK_VERSION
	fi
    echo -e "Done for ${FULL_NAME_APK}\n"
}

function do_unzip {
    FILE_PATH=$1
    EXTRACT_PATH=$2
    mkdir -p $EXTRACT_PATH
    # -n - never overwrite files during unzip
    unzip -n -q $FILE_PATH -d $EXTRACT_PATH
}

function copy_fw {
    UNZIP_APK_DIR=$1
    APK_VERSION=$2
    DIR_FOR_FW="${FW_DIR}${APK_VERSION}"
    mkdir -p "${DIR_FOR_FW}"
    echo "copy all firmwares to ${DIR_FOR_FW}"
    cp -n ${UNZIP_APK_DIR}/assets/*.fw $DIR_FOR_FW
}

function usage {
	echo "Usage: $0 [-u | -f]"
	echo -e "\t-u|--unzip - auto-unzip each APK and copy FW to separate directory"
	echo -e "\t-f|--force - Download APK even when corresponding file for this version already exist"
}

while [[ $# -gt 0 ]]; do
	case $1 in
		-u|--unzip)
			UNZIP=0 # set to 0 (true)
			shift
			;;
		-f|--force)
			FORCE=0 # set to 0 (true)
			shift
			;;
		*)
			usage
			exit
			;;
	esac

done
[ ${FORCE} -eq 0 ] && echo -e "FORCE is \e[4menabled\e[24m" || echo -e "FORCE is disabled - for enable, set --force"
[ ${UNZIP} -eq 0 ] && echo -e "UNZIP is \e[4menabled\e[24m" || echo -e "UNZIP is disabled - for enable, set --unzip"

mkdir -p "${TMP_DIR}"
echo "Downloading APK list" 
curl -# -L "${APK_HOST}${APK_LIST}" > "${TMP_LIST}"
echo "Parse APK list"
LIST_OF_APK=`xidel ${TMP_LIST} -s --extract '//h5[starts-with(@title, "Mi Fit")]/a/@href'`
for i in $LIST_OF_APK; do
    download_apk $i
done
