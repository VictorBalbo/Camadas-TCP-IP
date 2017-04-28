#!/bin/bash

#############################################################################################
#       Trabalho Prático de Redes de Computadores I - Implementação da camada física        #
#                                                                                           #
# 2017/2 - 6º período                                                                       #
#                                                                                           #
# Gabriel Pires Miranda de Magalhães    -   201422040011                                    #
# Thayane Pessoa Duarte                 -   201312040408                                    #
# Victor de Oliveira Balbo              -   201422040178                                    #
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
PORT_SERVER=$1
#TMQ
TMQ=$2

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
if [ "$TMQ" -lt "46" ] || [ "$TMQ" -gt "1500" ]; then
    echo "O TMQ deve estar entre 46 e 1500"
    exit
fi


rm received.txt &> /dev/null
# Espera a conexão do cliente da camada física
while true; do
    echo "Esperando conexão..."
    res=`nc -l $PORT_SERVER`
    # Verifica se o cliente está solicitando o TMQ
    if [ "$res" = "TMQ" ]; then
    	echo "Cliente solicitou o TMQ. Enviando TMQ = ${TMQ}..."
    	# Envia o TMQ para o cliente
    	echo "$TMQ" | nc -l $PORT_SERVER
    else 
	    FILE_DATA=`echo "$res"`
	    # Converte de binario para HexDump
	    FILE_DATA=`toHex $FILE_DATA` 
	    echo $FILE_DATA > "quadro_out.txt"
	    # Converte de HexDump para string
	    xxd -p -r "quadro_out.txt" >> received.txt
	    echo "Arquivo recebido."
	fi
	echo -e "\n--------\n"
done