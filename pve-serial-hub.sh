#!/bin/bash
##################################################

qemu_dir='/var/run/qemu-server'
screen_name_preffix='pve-vm-'
whirptail_opt=('--title' 'PVE Serial console HUB' '--backtitle' 'by AF' '--notags' '--ok-button' 'Select' '--cancel-button' 'Exit')

##################################################

serial=()
vm=()
menu_items=()
result=''
subresult=''
in_submenu=0
nl=$'\n'

function get_menu_items {
    menu_items=()
    local vmid2 vmid item2 sid vm_name

    add_item() {
        [ "$sid" == 'X' ] && menu_items+=( "#$vmid" "${vm_name:="<$vmid>"} ($vmid) -->" ) && return
        [ "$( screen -ls "$screen_name_preffix$item" | wc -l )" == 3 ] && local opened=$'   [opened]'
        [ "${#vmid}" -gt 0 ] && menu_items+=( "$item" "${vm_name:="<$vmid>"} ($vmid#$sid)$opened" )
    }

    serial=( $( ls $qemu_dir | grep -P '^[1-9][0-9]{2,8}\.serial[0-3]$' ) )
    if [[ "${#vm}" -lt 1 || "$1" == '<refresh>' ]]; then
		vm=( $( qm list | awk -F' ' 'NR>1 {print $1 "," $2}' ) )
		result=''
    fi
    for item2 in "${serial[@]}"; do
	[ "`file -b $qemu_dir/$item2`" == 'socket'  ] || continue
	vmid2=$( echo "$item2" | grep -oP '^[0-9]+' )
	[ "$vmid2" == "$vmid" ] && sid='X' && continue
	add_item
	vmid=$vmid2
	item=$item2
	sid=${item2: -1}
	vm_name=$( printf '%s\n' "${vm[@]}" | awk -F',' -v vmid=$vmid 'vmid==$1 {print $2}' )
    done
    add_item
}

function get_submenu_items {
    menu_items=()
    [ "$2" == '<refresh>' ] && serial=( $( ls $qemu_dir | grep -P '^[1-9][0-9]{2,8}\.serial[0-3]$' ) ) && subresult=''
    mapfile -t menu_items < <( printf '%s\n' "${serial[@]}" | awk -F'.serial' -v sid="${1:1}" 'sid==$1 { print $0 "\nSerial #" $2 }' )
}

function get_terminal {
    session="$screen_name_preffix$1"
    if [ "$( screen -ls "$session" | wc -l )" == 2 ]; then
        screen -dmS $session socat UNIX-CONNECT:$qemu_dir/$1 STDIO,raw,echo=0,escape=0x2
        sleep 0.01
        [ "$( screen -ls "$session" | wc -l )" == 2 ] && whiptail --msgbox "Error: Unable to connect to socket.${nl}Screen sesion: $session${nl}Socket: $qemu_dir/$1" 0 0 && return
        screen -XS $session bindkey ^D detach
        screen -XS $session escape ^pp
        screen -XS $session vbell off
        screen -XS $session multiuser on
    fi
    screen -rx $session
}

TERM=ansi whiptail "${whirptail_opt[@]}" --infobox 'Collecting information' 0 0
while true; do
    if [ "$in_submenu" == 0 ]; then
        get_menu_items $result
        result=`whiptail "${whirptail_opt[@]}" --default-item "$result" --menu "Select VM and socket" 0 0 2 "${menu_items[@]}" '<refresh>' ' <Refresh info>' 3>&1 1>&2 2>&3`
        [ $? -eq 1 ] && exit
        [ "${result:0:1}" == '#' ] && in_submenu=1 && continue
        [ "$result" == '<refresh>' ] && TERM=ansi whiptail "${whirptail_opt[@]}" --infobox 'Collecting information' 0 0 &&  continue
        get_terminal $result
    else
        get_submenu_items $result $subresult
        name=$( printf '%s\n' "${vm[@]}" | awk -F',' -v vmid="${result:1}" 'vmid==$1 {print $2}' )
        subresult=`whiptail "${whirptail_opt[@]}" --default-item "$subresult" --menu "${nl}Select VM socket for $name (${result:1})" 0 0 0 '<return_prev>' '<-- main menu' "${menu_items[@]}" '<refresh>' ' <Refresh info>' 3>&1 1>&2 2>&3`
        [ $? -eq 1 ] && exit
        [ "$subresult" == '<return_prev>' ] && in_submenu=0 && continue
        [ "$subresult" == '<refresh>' ] && continue
        get_terminal $subresult
    fi
done
