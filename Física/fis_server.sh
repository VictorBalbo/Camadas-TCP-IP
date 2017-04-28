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

function toHex(){
    binary="";
    for (( i=0 ; i<${#1} ; i+=4 )); do 
        case ${1:i:4} in
            0000) binary+="0";;
            0001) binary+="1";;
            0010) binary+="2";;
            0011) binary+="3";;
            0100) binary+="4";;
            0101) binary+="5";;
            0110) binary+="6";;
            0111) binary+="7";;
            1000) binary+="8";;
            1001) binary+="9";;
            1010) binary+="a";;
            1011) binary+="b";;
            1100) binary+="c";;
            1101) binary+="d";;
            1110) binary+="e";;
            1111) binary+="f";;
        esac
    done
    echo $binary
}

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

# Espera a conexão do cliente da camada física
while true; do
    echo "Esperando conexão..."
    nc -l $PORT_SERVER > frame_o.txt
    FILE_DATA=`cat frame_o.txt`
    FILE_DATA=`toHex $FILE_DATA` # Cast Binary to HexDump
    echo $FILE_DATA > frame_o.txt
    xxd -p -r frame_o.txt > received.txt # Cast HexDump back to String
    echo "Arquivo recebido."
    rm frame_o.txt &> /dev/null
done;