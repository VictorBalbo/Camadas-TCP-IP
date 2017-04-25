#!/bin/bash

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

#Exibe o pacote IP no formato HEX Dump
echo "Enviando o pacote IP:"
echo $FILE_DATA > frame_i.txt

#Envia o quadro Ethernet no formato binário textual para o servidor da camada física
nc $IP_SERVER $PORT_SERVER < frame_i.txt

rm frame_i.txt &> /dev/null
