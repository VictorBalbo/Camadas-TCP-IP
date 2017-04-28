#!/bin/bash

#############################################################################################
#       Trabalho Prático de Redes de Computadores I - Implementação da camada física        #
#                                                                                           #
# 2017/2 - 6º período                                                                       #
#                                                                                           #
# Gabriel Pires Miranda de Magalhães    -                                                   #
# Thayane Pessoa Duarte                 -                                                   #
# Victor de Oliveira Balbo              -                                                   #
# Vinícius Magalhães D'Assunção         -   201422040232                                    #
#############################################################################################

function toBinary(){
    binary="";
    for (( i=0 ; i<${#1} ; i++ )); do 
        case ${1:i:1} in
            0) binary+="0000";;
            1) binary+="0001";;
            2) binary+="0010";;
            3) binary+="0011";;
            4) binary+="0100";;
            5) binary+="0101";;
            6) binary+="0110";;
            7) binary+="0111";;
            8) binary+="1000";;
            9) binary+="1001";;
            a) binary+="1010";;
            b) binary+="1011";;
            c) binary+="1100";;
            d) binary+="1101";;
            e) binary+="1110";;
            f) binary+="1111";;
        esac
    done
    echo $binary
}


# Componentes do quadro segundo o RFC
function montaQuadro() {
    dados=$1
    IP_SERVER=$2
    IFACE=`ip route show default | awk '/default/ {print $5}'`

    # PREAMBULO(hex), são 7 bytes. 10101010....
    PREAMBULO='aaaaaaaaaaaaaa'
    # SFD - Start of Frame(hex)- 1 byte
    SFD='ab'
    # Tamanho/tipo, neste caso, tipo ETHERNET 
    TAM_TIPO='0800'

    # MAC origem e destino - 6 bytes cada (pegar do ifconfig)
    MAC_ORIG=`cat /sys/class/net/${IFACE}/address`

    #Se não encontrar o MAC de origem
    if [ -z "$MAC_ORIG" ]; then
        MAC_ORIG="00:00:00:00:00:00"
    fi
    echo "MAC da Origem: $MAC_ORIG"

    #Ping para poder fazer o ARP
    ping -c 1 $IP_SERVER &>/dev/null

    MAC_DEST=`arp $IP_SERVER | grep -E -o -e "([A-Za-z0-9]{2}:?){6}"`
    #Se não encontrar o MAC de destino
    if [ -z "$MAC_DEST" ]; then
        MAC_DEST="00:00:00:00:00:00"
    fi
    echo "MAC do Destino: $MAC_DEST"

    #Remove os ':' dos MACs
    MAC_ORIG=`echo $MAC_ORIG | sed "s/://g"`
    MAC_DEST=`echo $MAC_DEST | sed "s/://g"`

    #Monta o quadro Ethernet
    echo -n "${PREAMBULO}${SFD}${MAC_DEST}${MAC_ORIG}${TAM_TIPO}${dados}" | xxd -p > frame_e.hex
    #Calcula o CRC e adiciona no final do quadro
    crc32 frame_e.hex | xxd -p >> frame_e.hex
}


#Informações da Entidade Par
IP_SERVER=`echo -n $1`
PORT_SERVER=`echo -n $2`

#Se não informar o IP_SERVER
if [ -z "$IP_SERVER" ]; then
    echo "O IP do servidor deve ser informado"
    exit
fi

#Se não informar o PORT_SERVER
if [ -z "$PORT_SERVER" ]; then
    echo "A porta do servidor deve ser informada"
    exit
fi

dados=`cat pacote.txt`

echo "Montando o quadro..."
rm frame_i.txt &> /dev/null
montaQuadro "$dados" "$IP_SERVER"
quadro=`cat frame_e.hex`
arq_bin=`toBinary "$quadro"`

echo "$arq_bin" > frame_i.txt
echo "Enviando o pacote IP..."
#Envia o quadro Ethernet no formato binário textual para o servidor da camada física
nc "$IP_SERVER" "$PORT_SERVER" < frame_i.txt
echo "Pacote Enviado."

rm frame_i.txt &> /dev/null