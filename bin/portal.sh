#! /bin/bash -e

CONFIG_REP="$HOME/.config/portal"
VAR_REP=".portal/var"
SAFE_FILE="$VAR_REP/lastSyncNotSafe"

TREE_REP=".portal/common/tree"
DATA_REP=".portal/common/data"

DEBUG="false"

if ! rsync > /dev/null; then
    if sudo > /dev/null; then
	sudo apt-get install rsync
    else
	su -c 'apt-get install rsync'
    fi
fi

function print_color() {
    [ $# -eq 2 ] || exit 1
    echo -e "\033[$1"m"$2\033[0m"
}

function father() {
    [ $# -eq 1 ]

    if echo $1 | grep / > /dev/null 2>&1
    then
	echo "$1" | sed "s/\/$(basename $1).*/\//"
    fi
}
# REP_VAR=".portal/var"

# TMP_REP="/tmp/$0"
# mkdir -p $TMP_REP
# trap "rm -rf $TMP_REP" 0 1 2 15

# DIALOG=${DIALOG=dialog}

#TODO no default dialog on debian or raspbian
#TODO no tree command 
#ssh failed ip

function init() {
    if [ -e .portal ]; then
	print_color "1;32" "portal already open"
	exit 0
    fi
    #
    # if [ ! -e ~/.ssh ]; then
    # echo "connect to your sync server with ssh before init portal"
    # exit 8
    # fi
    #
    # mkdir -p $REP_VAR
    #
    #
    # ipPort="$TMP_REP/ipPort"
    # cat ~/.ssh/known_hosts | awk '{print $1}' | tr ',' '\n' | tr -d '[]' | tr ':' ' ' \
	# | awk '{if($2) print $0; else print $1, "22"}' | tr ' ' ':' > $ipPort
    #
    #
    # #TODO : dialog on debian failed
    # ret=$($DIALOG --title "portal init" --column-separator ":" \
	# --menu "\nmachine is not below -> connect it with ssh" 0 0 0 \
	# $(cat -n $ipPort) 3>&2 2>&1 1>&3)
    # clear
    #
    # line=$(sed "$ret""q;d" $ipPort)
    # ip=$(echo $line | awk -F: '{print $1}')
    # port=$(echo $line | awk -F: '{print $2}')
    #
    #
    # user=$($DIALOG --title "portal init" \
	# --inputbox "distant machine username" 0 0 \
	# 3>&2 2>&1 1>&3)
    # clear
    #
    # if ! ssh -p $port $user@$ip mkdir -p ".portal/"; then
    # echo -e "\\033[1;31mlog on machine failed\\033[0m"
    # exit 2
    # fi
    #
    # echo $ip > $REP_VAR/ip
    # echo $port > $REP_VAR/port
    # echo $user > $REP_VAR/user
    # mkdir -p .portal/tree

    # echo "portal list :"
    # ssh $user@$ip -p $port ls .portal/ | grep -v backup
    mkdir -p .portal/common/{tree,data}
    mkdir -p $VAR_REP

    repoName=$(basename "$(pwd)")
    print_color "1;45" "$repoName"

    if ssh $user@$ip -p $port [ -e .common/$repoName ]
    then
	sync in
    else
	sync out
    fi
}


function push() {
    if $DEBUG; then
	print_color "1;35" "push"
    fi

    backup="--backup-dir=/home/$user/.common/backup/"

    if $safe; then
	option="--delete"
    else
	option=""
    fi

    # echo "rsync -arvu -e "ssh -p $port" $option --backup "$backup" .portal/common/ "$user"@"$ip":~/.portal/"$repoName"/"
    rsync -arvu -e "ssh -p $port" $option --backup "$backup" .portal/common/ "$user"@"$ip":~/.common/"$repoName"/
}

function pull() {
    if $DEBUG; then
	print_color "1;35" "pull"
    fi
    backup="--backup-dir=../backup/"

    # echo "rsync -arvu -e "ssh -p $port" --delete --backup $backup $user@$ip:~/.portal/"$repoName"/ .portal/common/"
    rsync -arvu -e "ssh -p $port" --delete --backup $backup $user@$ip:~/.common/"$repoName"/ .portal/common/

    # echo -e "\\033[1;33m"
    # find ../backup -amin 1
    # echo -e "\\033[0m"
}

function status() {
    print_color 33 "url server"
    echo "$user@$ip:$port"
    # echo
    # echo -e "\033[33mportal list\033[0m"
    # ssh $user@$ip -p $port ls .portal/ | grep -v backup | grep -v var | grep -v common
    echo
    print_color 33 "data list"
    cd $TREE_REP/
    for f in $(find -empty | cut -c 1-2 --complement | sort); do
	if [ -d $f ]; then
	    print_color "1;34" $f
	else
	    echo $f
	fi
    done
}


#TODO : vararg argument
function add() {
    # echo "$dirRootSuppressed"
    dirFile="$dirRootSuppressed""$1"
    # absolute="$repoName/$dirFile"
    # print_color 33 "dirFile : $dirFile"
    if [ $# -ne 1 ]; then
	echo "usage: $0 add file|repository" 2>&1
	exit 4
    fi

    # dir=$(pwd)
    if [ -e $TREE_REP/$dirFile ]; then
	print_color "1;33" "'tree/$dirFile' already exist"
	exit 0
    fi

    if [ ! -e $dirFile ]; then
	print_color "1;31" "'$dirFile' not exist in your filesystem"
	exit 1
    fi

    if [ -d $dirFile ]; then
	# mkdir -pv $TREE_REP/$1
	mkdir -p $TREE_REP/$dirFile
    else
	touch $TREE_REP/$dirFile
    fi
    print_color "1;32" "successfuly added in tree/$dirFile"
}

function del() {
    dirFile="$dirRootSuppressed""$1"
    # absolute="$repoName/$dirFile"
    # print_color 33 "dirFile : $dirFile"

    if [ $# -ne 1 ]; then
	echo "usage: $0 del file|repository" 2>&1
	exit 4
    fi

    if [ ! -e $TREE_REP/$dirFile ]; then
	print_color "1;33" "'tree/$dirFile' not exist"
	exit 0
    fi
    # dir=$(pwd)
    if [ -d $dirFile ]; then
	rm -rf $TREE_REP/$dirFile
	rm -rf $DATA_REP/$dirFile
    else
	rm -f $TREE_REP/$dirFile
	rm -f $DATA_REP/$dirFile
    fi
    print_color "1;32" "successfuly deleted"
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
    backup="--backup-dir=$home/.portal/backup/"
    # backup="--backup-dir=../backup/"
    # rsync -arvu . ../data/

    # own_bar "merge $1"

    if [ $1 = "branch" ]
    then
	# own_bar "merge branch"
	# pwd
	if $DEBUG; then
	    print_color "1;36" "merge branch"
	fi

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
		if [ -e $home/$proper ]; then
		    cmd="rsync -arvu $option --backup $backup $home/$proper $dataRep"
		    # own_printColor "$cmd" 33
		    # pwd
		    if $DEBUG; then
			print_color 33 "$cmd"
			$cmd
		    else
			$cmd > /dev/null
		    fi

		else
		    # print_color "1;31" "can't merge file '$proper' because not exists in your filesystem"
		    print_color "1;32" "remove tree/$proper because not exists in your filesystem"
		    rm -r $proper
		fi
	    fi
	done

    elif [ $1 = "master" ]
    then
	# own_bar "merge master"
	if $DEBUG; then
	    print_color "1;36" "merge master"
	fi

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
		if [ -e $dataFile ]; then
		    cmd="rsync -arvu $option --backup $backup $dataFile $home/$properRep"
		    # own_printColor "$cmd" 33
		    if $DEBUG; then
			print_color 33 "$cmd"
			$cmd
		    else
			$cmd > /dev/null
		    fi
		else
		    # print_color "1;31" "can't merge file '$proper' because not exists in common"
		    print_color "1;32" "remove tree/$proper because not exists in common"
		    rm -r $proper
		fi
	    fi

	done

    else
	echo "unknown parameter" 2>&1
	exit 1
    fi


    cd $home

    echo -en "\\033[1;33m"
    find .portal/backup -amin 0.1
    echo -en "\\033[0m"
    # barStatus "merge ok"
}

function sync() {
    if [ -e $SAFE_FILE ]; then
	safe="false"
    else
	safe="true"
    fi
    # rm -f $VAR_REP/safe
    touch $SAFE_FILE

    # own_isConnected
    if ! ping -c1 8.8.8.8 > /dev/null; then
	print_color "1;31" "not connected on internet"
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

	# merge branch > /dev/null
	merge branch
	# own_common_merge branch

	print_color "1;31" "bad last sync"
	print_color 33 "safe push"
	push
	# own_common_push safe

	print_color 32 "pull"
	pull

	# merge master > /dev/null
	merge master


    elif [ $1 = "out" ]
    then
	# own_bar "sync out"

	# merge branch > /dev/null
	merge branch

	push
	# own_common_push safe


    elif [ $1 = "in" ]
    then
	# own_bar "sync in"

	# temp="/tmp/temp.txt"
	# own_common_pull $option > $temp
	pull

	# cat $temp

	# merge master > /dev/null
	merge master

	# cat $temp
	# rm $temp

    else
	echo "unknown parameter" 2>&1
	exit 1
    fi

    # own_barStatus "sync ok"
    # touch -r "$HOME/var/$(cat /etc/hostname)" $lastSync
    # touch $lastSync
    # touch $VAR_REP/safe
    rm $SAFE_FILE
}

function clean_backup() {
    rm -frv .portal/backup/
    ssh -p $port $user@$ip rm -frv .common/backup/
}

function clean() {
    if [ -e $SAFE_FILE ]; then
	print_color "1;31" "not safe last sync"
	exit 1
    fi

    rm -frv $DATA_REP
    print_color "33" "merge all branch newly clean"
    sync out
}

function connect() {
    ssh $user@$ip -p $port
}

function save() {
    if [ ! -e $HOME/.common ]; then
	print_color "1;31" "this machine is not a server with common file"
	exit 0
    fi

    lsblk
    echo -n "usb device (default sda): "
    read device
    if [ ! $device ]
    then
	device="sda"
    fi

    [ -e /dev/$device ]

    sudo mount /dev/$device /mnt

    rsync -arvu --delete $HOME/.common /mnt/

    # rm /mnt/install
    # ln -sv /mnt/common/data/root/bin/own_archlinux_install /mnt/install

    df -h | grep --color $device
    sudo umount /mnt
}




if [ $# -eq 0 ]; then
    echo "usage: portal <command> [<args>]"
    echo
    echo "command:"
    echo "    init               open portal on current repository"
    echo "    sync in|out        synchronize your data to the server"
    echo "        +----------+              +----------+              +----------+"
    echo "        |          |      out     |          |      in      |  other   |"
    echo "        |  portal  |  --------->  |  server  |  --------->  |  portal  |"
    echo "        |   ....   |  <---------  |          |  <---------  |   ....   |"
    echo "        ............      in      +----------+      out     ............"
    echo "            .portal/                ~/.common/                  .portal/"
    echo
    echo "    add <filename>     add sync file or repository"
    echo "    del <filename>     delete sync file or repository"
    echo "    status             show status"
    echo "    clean              clean backup and hide file in common/data"
    echo "    save               save all common file on server to external disk"

	
    exit 0
fi

if [ $1 = "save" ]; then
    save
    exit 0
fi

if [ ! -e $CONFIG_REP ]; then
    print_color 33 "need to initialize url of your save server data"

    echo -n "ip (default localhost): "
    read ip
    [ -z $ip ] && ip=localhost

    me=$(whoami)
    echo -n "user (default $me): "
    read user
    [ -z $user ] && user=$me

    echo -n "port (default 22): "
    read port
    [ -z $port ] && port=22

    [ ! -e $HOME/.ssh/id_rsa ] && ssh-keygen
    ssh-copy-id -p $port $user@$ip

    if ! ssh -p $port $user@$ip mkdir -p ".common/"; then
	print_color "1;31" "log on machine failed"
	exit 2
    fi

    mkdir -p $CONFIG_REP
    echo $port > $CONFIG_REP/port.var
    echo $user > $CONFIG_REP/user.var
    echo $ip > $CONFIG_REP/ip.var
fi
# if [ $1 != "init" ] && [ ! -e .portal ]; then
#     echo -e "\\033[1;31mnot a portal repo\\033[0m"
#     echo "use <portal init>"
#     exit 7
# fi

function initVar() {
    port=$(cat $CONFIG_REP/port.var)
    user=$(cat $CONFIG_REP/user.var)
    ip=$(cat $CONFIG_REP/ip.var)
}
initVar


#first case not need root directory function
did="true"
case $1 in
    "init")
	init
	;;

    "connect")
	connect
	;;

    *)
	did="false"
	;;
esac

if $did ; then
    exit 0
fi

function root() {
    while [ ! -d .portal/ ]; do
	dirRootSuppressed="$(basename $PWD)/$dirRootSuppressed"
	cd ..

	if [ $PWD = "/" ]; then
	    print_color "1;33" "no portal open on this machine"
	    exit 0
	fi
    done
}
root

if [ -e $VAR_REP/lock ]; then
    print_color "1;31" "portal locked"
    exit 0
fi
touch $VAR_REP/lock
trap "rm $PWD/$VAR_REP/lock" 0 1 2 15


repoName=$(basename "$(pwd)")
print_color "1;45" "$repoName"


case $1 in
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

    # "clean_backup")
	# clean_backup
	# ;;

    "clean")
	clean
	clean_backup
	;;

    *)
	echo "unknown parameter"
	;;
esac
