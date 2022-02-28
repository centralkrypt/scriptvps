#!/bin/bash

# Define Function
usage(){
    cat<<EOF
Usage: $(basename "${BASH_SOURCE[0]}") [-h] [-c command] [-u username] [-p password] [-x expire]
Example:
> getdata -c addSsh -u baco -p b123 -x 7
> getdata -c addVmess -u baco -x 30

Script for VPN account management.

Available options:

-h  # print this help and exit
-c  # select command to run
-u  # send VPN username
-p  # send VPN password
-x  # send VPN expired duration
EOF
    exit
}
addSsh(){
    ws="$(cat ~/log-install.txt | grep -w "Websocket TLS" | cut -d: -f2|sed 's/ //g')"
    ws2="$(cat ~/log-install.txt | grep -w "Websocket None TLS" | cut -d: -f2|sed 's/ //g')"

    ssl="$(cat ~/log-install.txt | grep -w "Stunnel5" | cut -d: -f2)"
    sqd="$(cat ~/log-install.txt | grep -w "Squid" | cut -d: -f2)"
    ovpn="$(netstat -nlpt | grep -i openvpn | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2)"
    ovpn2="$(netstat -nlpu | grep -i openvpn | grep -i 0.0.0.0 | awk '{print $4}' | cut -d: -f2)"
    clear
    systemctl restart ws-tls
    systemctl restart ws-nontls
    systemctl restart ssh-ohp
    systemctl restart dropbear-ohp
    systemctl restart openvpn-ohp
    useradd -e `date -d "$masaaktif days" +"%Y-%m-%d"` -s /bin/false -M $user
    # expi="$(chage -l $user | grep "Account expires" | awk -F": " '{print $2}')"
    echo -e "$pass\n$pass\n"|passwd $user &> /dev/null

    jo -p ip-host=$MYIP \
        domain=$domain \
        username=$user \
        password=$pass \
        dropbear="109, 143" \
        ssl=$ssl \
        squid=$squid \
        ohp-ssh=8181 \
        ohp-dropbear=8282 \
        ohp-openvpn=8383 \
        ssh-ws-ssl=$ws \
        ssh-ws=$ws2 \
        ovpn-ws=2086 \
        port-tcp=$ovpn \
        port-udp=$ovpn2 \
        port-ssl=990 \
        ovpn-tcp=http://$MYIP:89/tcp.ovpn \
        ovpn-udp=http://$MYIP:89/udp.ovpn \
        ovpn-ssl=http://$MYIP:89/ssl.ovpn \
        badvpn="7100-7200-7300" \
        created=$hariini \
        expired=$exp \
        payload-ws-tls="GET wss://bug.com [protocol][crlf]Host: ${domain}[crlf]Upgrade: websocket[crlf][crlf]" \
        payload-ws="GET / HTTP/1.1[crlf]Host: ${domain}[crlf]Upgrade: websocket[crlf][crlf]"
}
getMember(){
    arrMem=()
    arrExp=()
    arrStat=()
    while read expired
    do
    AKUN="$(echo $expired | cut -d: -f1)"
    ID="$(echo $expired | grep -v nobody | cut -d: -f3)"
    exp="$(chage -l $AKUN | grep "Account expires" | awk -F": " '{print $2}')"
    status="$(passwd -S $AKUN | awk '{print $2}' )"
    if [[ $ID -ge 1000 ]]; then
    arrMem+=("${AKUN}")
    arrExp+=("${exp}")
    if [[ "$status" = "L" ]]; then
    # printf "%-17s %2s %-17s %2s \n" "$AKUN" "$exp     " "${RED}LOCKED${NORMAL}"
    arrStat+=("LOCKED")
    else
    # printf "%-17s %2s %-17s %2s \n" "$AKUN" "$exp     " "${GREEN}UNLOCKED${NORMAL}"
    arrStat+=("UNLOCKED")
    fi
    fi
    done < /etc/passwd

    jo -p member=$(jo -a ${arrMem[@]}) expire=$(jo -a ${arrExp[@]}) status=$(jo -a ${arrStat[@]})
}
addVmess(){
    tls="$(cat ~/log-install.txt | grep -w "Vmess TLS" | cut -d: -f2|sed 's/ //g')"
    nontls="$(cat ~/log-install.txt | grep -w "Vmess None TLS" | cut -d: -f2|sed 's/ //g')"
    # until [[ $user =~ ^[a-zA-Z0-9_]+$ && ${CLIENT_EXISTS} == '0' ]]; do
    #         read -rp "Username : " -e user
    #         CLIENT_EXISTS=$(grep -w $user /etc/xray/config.json | wc -l)

    #         if [[ ${CLIENT_EXISTS} == '1' ]]; then
    #             echo ""
    #             echo -e "Username ${RED}${CLIENT_NAME}${NC} Already On VPS Please Choose Another"
    #             exit 1
    #         fi
    #     done
    uuid=$(cat /proc/sys/kernel/random/uuid)
    sed -i '/#xray-vmess-tls$/a\### '"$user $exp"'\
    },{"id": "'""$uuid""'"' /etc/xray/config.json
    sed -i '/#xray-vmess-nontls$/a\### '"$user $exp"'\
    },{"id": "'""$uuid""'"' /etc/xray/config.json
    cat>/etc/xray/vmess-$user-tls.json<<EOF
        {
        "v": "2",
        "ps": "${user}",
        "add": "${domain}",
        "port": "${tls}",
        "id": "${uuid}",
        "aid": "0",
        "net": "ws",
        "path": "/vmess/",
        "type": "none",
        "host": "",
        "tls": "tls"
    }
EOF
    cat>/etc/xray/vmess-$user-nontls.json<<EOF
        {
        "v": "2",
        "ps": "${user}",
        "add": "${domain}",
        "port": "${nontls}",
        "id": "${uuid}",
        "aid": "0",
        "net": "ws",
        "path": "/vmess/",
        "type": "none",
        "host": "",
        "tls": "none"
    }
EOF
    vmess_base641=$( base64 -w 0 <<< $vmess_json1)
    vmess_base642=$( base64 -w 0 <<< $vmess_json2)
    xrayv2ray1="vmess://$(base64 -w 0 /etc/xray/vmess-$user-tls.json)"
    xrayv2ray2="vmess://$(base64 -w 0 /etc/xray/vmess-$user-nontls.json)"
    rm -rf /etc/xray/vmess-$user-tls.json
    rm -rf /etc/xray/vmess-$user-nontls.json
    systemctl restart xray.service
    service cron restart
    clear

    jo -p remarks=$user \
        ip-host=$MYIP \
        address=$domain \
        port-tls=$tls \
        port=$nontls \
        uuid=$uuid \
        alter-id=0 \
        security=auto \
        network=ws \
        path=/vmess/ \
        created=$hariini \
        expired=$exp \
        link-tls=$xrayv2ray1 \
        link=$xrayv2ray2
}
addTrgo(){
    uuid=$(cat /etc/trojan-go/uuid.txt)
    trgo="$(cat ~/log-install.txt | grep -w "Tr Go" | cut -d: -f2|sed 's/ //g')"
    # until [[ $user =~ ^[a-zA-Z0-9_]+$ && ${user_EXISTS} == '0' ]]; do
    #         read -rp "Password : " -e user
    #         user_EXISTS=$(grep -w $user /etc/trojan-go/akun.conf | wc -l)

    #         if [[ ${user_EXISTS} == '1' ]]; then
    #             echo ""
    #             echo -e "Username ${RED}${user}${NC} Already On VPS Please Choose Another"
    #             exit 1
    #         fi
    #     done

    sed -i '/"'""$uuid""'"$/a\,"'""$user""'"' /etc/trojan-go/config.json
    echo -e "### $user $exp" >> /etc/trojan-go/akun.conf
    systemctl restart trojan-go.service
    link="trojan-go://${user}@${domain}:${trgo}/?sni=${domain}&type=ws&host=${domain}&path=/trojango&encryption=none#$user"
    clear

    jo -p remarks=$user \
        ip-host=$MYIP \
        address=$domain \
        port=$trgo \
        key=$user \
        encryption=none \
        path=/trojango \
        created=$hariini \
        expired=$exp \
        link=$link
}



# Set variables
MYIP=$(wget -qO- ipinfo.io/ip)
domain=$(cat /etc/xray/domain)
hariini=`date -d "0 days" +"%Y-%m-%d"`
exp=`date -d "$masaaktif days" +"%Y-%m-%d"`

# Get the options
while getopts "c:u:p:x:h" option; do
    case $option in
        c) # Run fuction
            command=$OPTARG;;
        u) # get user
            user=$OPTARG;;
        p) # get pass
            pass=$OPTARG;;
        x) # get exp
            masaaktif=$OPTARG;;
        h) # show view
            usage;;
        \?) # Invalid option
            echo "Error: Invalid option"
            exit;;
    esac
done

if [ -z "$1" ]
    then
    echo "See the following list of command options!"
    usage
else
    $command
fi
