#! /bin/bash -e

REP_VAR=".portal/var"
REP_TEMP="/tmp/$0"
mkdir -p $REP_TEMP
# trap "rm -rf $REP_TEMP" 0 1 2 15

DIALOG=${DIALOG=dialog}


function init() {
    if [ -e $REP_VAR/ip ]; then
	echo -e "\\033[1;31mportal already open\\033[0m"
	exit 6
    fi

    if [ ! -e ~/.ssh ]; then
	echo "connect to your sync server with ssh before init portal"
	exit 8
    fi

    mkdir -p $REP_VAR


    ipPort="$REP_TEMP/ipPort"
    cat ~/.ssh/known_hosts | awk '{print $1}' | tr ',' '\n' | tr -d '[]' | tr ':' ' ' \
	| awk '{if($2) print $0; else print $1, "22"}' | tr ' ' ':' > $ipPort


    #TODO: dialog on debian failed
    ret=$($DIALOG --title "portal init" --column-separator ":" \
	--menu "\nmachine is not below -> connect it with ssh" 0 0 0 \
	$(cat -n $ipPort) 3>&2 2>&1 1>&3)
    clear

    line=$(sed "$ret""q;d" $ipPort)
    ip=$(echo $line | awk -F: '{print $1}')
    port=$(echo $line | awk -F: '{print $2}')


    user=$($DIALOG --title "portal init" \
	--inputbox "distant machine username" 0 0 \
	3>&2 2>&1 1>&3)
    clear

    if ! ssh -p $port $user@$ip mkdir -p ".portal/"; then
	echo -e "\\033[1;31mlog on machine failed\\033[0m"
	exit 2
    fi

    echo $ip > $REP_VAR/ip
    echo $port > $REP_VAR/port
    echo $user > $REP_VAR/user
    # mkdir -p .portal/tree
    mkdir -p .portal/common/{tree,data}


    # echo "portal list :"
    # ssh $user@$ip -p $port ls .portal/ | grep -v backup
}

function initVar() {
    port=$(cat .portal/var/port)
    user=$(cat .portal/var/user)
    ip=$(cat .portal/var/ip)
    repoName=$(basename "$(pwd)")
}

function push() {
    # own_bar "push"
    initVar
    backup="--backup-dir=/home/$user/.portal/backup/"

    if $safe; then
	option="--delete"
    else
	option=""
    fi

    # echo "rsync -arvu -e ssh -p $port $option --backup $backup .portal/ $user@$ip:~/.portal/$repoName/"
    rsync -arvu -e "ssh -p $port" $option --backup "$backup" .portal/common/ "$user"@"$ip":~/.portal/"$repoName"/
}

function pull() {
    # own_bar "pull"
    initVar 
    backup="--backup-dir=../backup/"

    # echo "rsync -arvu -e ssh -p $port --delete --backup $backup $user@$ip:~/.portal/$repoName/ .portal/"
    rsync -arvu -e "ssh -p $port" --delete --backup $backup $user@$ip:~/.portal/"$repoName"/ .portal/common/
}

function status() {
    initVar

    echo sync server : "$user@$ip:$port"
    echo
    echo "portal list :"
    ssh $user@$ip -p $port ls .portal/ | grep -v backup | grep -v var | grep -v common
    echo
    echo "actual portal :"
    cd .portal/common/tree/
    find . -empty | cut -c 1-2 --complement | sort
}

function father() {
    [ $# -eq 1 ]

    if echo $1 | grep / > /dev/null 2>&1
    then
	echo "$1" | sed "s/\/$(basename $1).*/\//"
    fi
}

function add() {
    if [ $# -ne 1 ]; then
	echo "usage: $0 add file|repository" 2>&1
	exit 4
    fi

    # dir=$(pwd)
    if [ -d $1 ]; then
	mkdir -pv .portal/common/tree/$1
    else
	touch .portal/common/tree/$1
    fi
}

function del() {
    if [ $# -ne 1 ]; then
	echo "usage: $0 del file|repository" 2>&1
	exit 4
    fi

    # dir=$(pwd)
    if [ -d $1 ]; then
	rm -rv .portal/common/tree/$1
	rm -rv .portal/common/data/$1
    else
	rm -v .portal/common/tree/$1
	rm -v .portal/common/data/$1
    fi
}

function merge() {
    if [ $# -ne 1 ]
    then
	echo "usage: $0 merge branch|master" 2>&1
	exit 3
    fi

    home=$(pwd)
    cd .portal/common/tree/


    if [ $1 = "master" ] && [ ! -d ../data/ ]
    then
	echo "empty master, merge branch first" 2>&1
	exit 1
    fi


    option="--delete"
    backup="--backup-dir=../../backup"
    # rsync -arvu . ../data/

    # own_bar "merge $1"

    if [ $1 = "branch" ]
    then
	# own_bar "merge branch"
	# pwd

	find -empty | while read file
	do
	    # echo "file =$file"
	    if [ $file != "." ]; then
		proper=$(echo $file | cut -c1-2 --complement)
		# echo "proper =$proper"
		# dataRep="../data/${proper%/*}"
		dataRep=$(father "../data/$proper")
		mkdir -pv $dataRep
		# cmd="rsync -arvu $option --backup $backup $home/$proper $dataRep"
		cmd="rsync -arvu $option $home/$proper $dataRep"
		echo -e "\\033[33m$cmd\\033[0m"
		# own_printColor "$cmd" 33
		# pwd
		$cmd
	    fi
	done

    elif [ $1 = "master" ]
    then
	# own_bar "merge master"

	find -empty | while read file
	do
	    if [ $file != "." ]; then
		proper=$(echo $file | cut -c1-2 --complement)
		# dataFile="~${proper%/*}/"
		dataFile="../data/$proper"

		properRep=$(father $proper)
		mkdir -pv $home/$properRep

		# if ! [ -d "$dataFile" ]
		# then
		#     rep=$dataFile
		#     while ! [ -d $rep ]
		#     do
		#         rep=$(own_father $rep)
		#     done
		#
		#     # user=$(stat -c "%U" $rep)
		#     # group=$(stat -c "%G" $rep)
		#     mkdir -pv $dataFile
		#     # chown $user:$group $rep -R
		# fi

		# user=$(stat -c "%U" $dataFile)
		# group=$(stat -c "%G" $dataFile)
		# cmd="rsync -arvu $option --backup $backup $dataFile $home/$properRep"
		cmd="rsync -arvu $option $dataFile $home/$properRep"
		echo -e "\\033[33m$cmd\\033[0m"
		# own_printColor "$cmd" 33
		$cmd
	    fi

	done

    else
	echo "unknown parameter" 2>&1
	exit 1
    fi

    cd $home
    # barStatus "merge ok"
}

function sync() {

    if [ -e $REP_VAR/safe ]; then
	safe="true"
    else
	safe="false"
    fi
    rm -f $REP_VAR/safe

    # own_isConnected
    if ! ping -c1 8.8.8.8 > /dev/null; then
	echo -e "\\033[1;31mnot connected on internet\\033[0m"
	exit 1
    fi

    if [ $# -ne 1 ]
    then
	echo "usage: sync in|out" 2>&1
	exit 1
    fi


    if ! $safe
    then
	# own_bar "sync out"
	# own_barStatus "safe mode" 31

	merge branch > /dev/null
	# own_common_merge branch

	echo -e "\\033[1;31mbad last sync\\033[0m"
	echo -e "\\033[1;33msafe push\\033[0m"
	push
	# own_common_push safe

	echo -e "\\033[1;32mpull\\033[0m"
	pull

	merge master > /dev/null
	# merge master


    elif [ $1 = "out" ]
    then
	# own_bar "sync out"

	merge branch > /dev/null
	# merge branch

	push
	# own_common_push safe


    elif [ $1 = "in" ]
    then
	# own_bar "sync in"

	# temp="/tmp/temp.txt"
	# own_common_pull $option > $temp
	pull

	# cat $temp
	merge master > /dev/null
	# merge master
	# cat $temp
	# rm $temp

    else
	echo "unknown parameter" 2>&1
	exit 1
    fi

    touch $REP_VAR/safe
    # own_barStatus "sync ok"
    # touch -r "$HOME/var/$(cat /etc/hostname)" $lastSync
    # touch $lastSync
}

function backup() {
    initVar

    if [ $# -ne 1 ]
    then
	echo "usage: $0 backup clean" 2>&1
	exit 1
    fi

    rm -frv .portal/backup/
    ssh -p $port $user@$ip rm -frv .portal/backup/
}

function connect() {
    initVar
    ssh $user@$ip -p $port
}





if [ $# -eq 0 ]; then
    echo "usage: portal <command> [<args>]"
    echo
    echo "options:"
    echo "    init          Open portal on current repository"

    exit 0
fi

if [ $1 != "init" ] && [ ! -e .portal ]; then
    echo -e "\\033[1;31mnot a portal repo\\033[0m"
    echo "use <portal init>"
    exit 7
fi

case $1 in
    "init")
	init
	;;

    "push")
	push
	;;

    "pull")
	pull
	;;

    "merge")
	merge $2
	;;

    "add")
	add $2
	;;

    "del")
	del $2
	;;

    "sync")
	sync $2
	;;

    "status")
	status
	;;

    "backup")
	backup $2
	;;

    "connect")
	connect
	;;

    *)
	echo "unknown parameter"
	exit 1
	;;
esac