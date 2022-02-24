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

-h, --help      Print this help and exit
-c, --cmd       Select command to run
-u, --user      To send VPN username
-p, --pass      To send VPN password
-x, --exp       To send VPN expired duration
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
    # echo -e ""
    # echo -e "Informasi SSH & OpenVPN"
    # echo -e "=============================="
    # echo -e "IP/Host       : $IP"
    # echo -e "Domain        : ${domain}"
    # echo -e "Username      : $Login"
    # echo -e "Password      : $Pass"
    # echo -e "Dropbear      : 109, 143"
    # echo -e "SSL/TLS       : $ssl"
    # echo -e "Port Squid    : $sqd"
    # echo -e "OHP SSH       : 8181"
    # echo -e "OHP Dropbear  : 8282"
    # echo -e "OHP OpenVPN   : 8383"
    # echo -e "Ssh Ws SSL    : $ws"
    # echo -e "Ssh Ws No SSL : $ws2"
    # echo -e "Ovpn Ws       : 2086"
    # echo -e "Port TCP      : $ovpn"
    # echo -e "Port UDP      : $ovpn2"
    # echo -e "Port SSL      : 990"
    # echo -e "OVPN TCP      : http://$IP:89/tcp.ovpn"
    # echo -e "OVPN UDP      : http://$IP:89/udp.ovpn"
    # echo -e "OVPN SSL      : http://$IP:89/ssl.ovpn"
    # echo -e "BadVpn        : 7100-7200-7300"
    # echo -e "Created       : $hariini"
    # echo -e "Expired       : $expi"
    # echo -e "=============================="
    # echo -e "Payload Websocket TLS"
    # echo -e "=============================="
    # echo -e "GET wss://bug.com [protocol][crlf]Host: ${domain}[crlf]Upgrade: websocket[crlf][crlf]"
    # echo -e "=============================="
    # echo -e "Payload Websocket No TLS"
    # echo -e "=============================="
    # echo -e "GET / HTTP/1.1[crlf]Host: ${domain}[crlf]Upgrade: websocket[crlf][crlf]"
    # echo -e "=============================="

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
    # echo -e ""
    # echo -e "======-XRAYS/VMESS-======"
    # echo -e "Remarks     : ${user}"
    # echo -e "IP/Host     : ${MYIP}"
    # echo -e "Address     : ${domain}"
    # echo -e "Port TLS    : ${tls}"
    # echo -e "Port No TLS : ${nontls}"
    # echo -e "User ID     : ${uuid}"
    # echo -e "Alter ID    : 0"
    # echo -e "Security    : auto"
    # echo -e "Network     : ws"
    # echo -e "Path        : /vmess/"
    # echo -e "Created     : $hariini"
    # echo -e "Expired     : $exp"
    # echo -e "========================="
    # echo -e "Link TLS    : ${xrayv2ray1}"
    # echo -e "========================="
    # echo -e "Link No TLS : ${xrayv2ray2}"
    # echo -e "========================="

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
    # echo -e ""
    # echo -e "=======-TROJAN-GO-======="
    # echo -e "Remarks    : ${user}"
    # echo -e "IP/Host    : ${MYIP}"
    # echo -e "Address    : ${domain}"
    # echo -e "Port       : ${trgo}"
    # echo -e "Key        : ${user}"
    # echo -e "Encryption : none"
    # echo -e "Path       : /trojango"
    # echo -e "Created    : $hariini"
    # echo -e "Expired    : $exp"
    # echo -e "========================="
    # echo -e "Link TrGo  : ${link}"
    # echo -e "========================="
    # echo -e "Script By Akbar Maulana"

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
