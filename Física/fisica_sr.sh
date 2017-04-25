#!/bin/bash

#Porta do servidor
PORT_SERVER=`echo -n $1`

#TMQ
TMQ=`echo -n $2`

#Se não informar a porta
if [ -z "$PORT_SERVER" ]; then
    echo "A porta que será escutada deve ser informada"
    exit
fi

#Se não informar o TMQ
if [ -z "$TMQ" ]; then
    echo "O TMQ deve ser informado"
    exit
fi

#Faixa de valores para o TMQ
if [ "$TMQ" -lt "88" ] || [ "$TMQ" -gt "1542" ]; then
    echo "O TMQ deve estar entre 88 e 1542"
    exit
fi

#Espera a conexão do cliente da camada física
echo "Esperando conexão..."
nc -l $PORT_SERVER > frame_o.txt
xxd -p -r frame_o.txt > received.txt 
cat frame_o.txt
rm frame_o.txt &> /dev/null