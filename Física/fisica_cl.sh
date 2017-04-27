#!/bin/bash

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

echo "Montando o frame..."
FILE_DATA=`cat packet.txt | xxd -p `
FILE_BINARY=`toBinary $FILE_DATA`

#Exibe o pacote IP no formato HEX Dump
echo "Enviando o pacote IP..."
echo $FILE_BINARY > frame_i.txt

#Envia o quadro Ethernet no formato binário textual para o servidor da camada física
nc $IP_SERVER $PORT_SERVER < frame_i.txt
echo "Pacote Enviado."

rm frame_i.txt &> /dev/null
