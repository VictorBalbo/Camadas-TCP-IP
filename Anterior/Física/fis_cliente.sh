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
    echo "PREAMBULO(hex): $PREAMBULO"

    # SFD - Start of Frame(hex)- 1 byte
    SFD='ab'
    echo "SFD(hex): $SFD"

    # Tamanho/tipo, neste caso, tipo ETHERNET 
    TAM_TIPO='0800'
    echo "Tamanho/Tipo(hex): $TAM_TIPO"

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
        MAC_DEST=$MAC_ORIG
    fi
    echo "MAC do Destino: $MAC_DEST"

    #Remove os ':' dos MACs
    MAC_ORIG=`echo $MAC_ORIG | sed "s/://g"`
    MAC_DEST=`echo $MAC_DEST | sed "s/://g"`

    #Monta o quadro Ethernet
    echo -n "${PREAMBULO}${SFD}${MAC_DEST}${MAC_ORIG}${TAM_TIPO}${dados}" | xxd -p > quadroHex.hex
    #Calcula o CRC e adiciona no final do quadro
    CRC=`crc32 quadroHex.hex`
    echo "$CRC" | xxd -p >> quadroHex.hex
    echo "CRC(hex): $CRC"
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

# Remetente solicita TMQ enviando a mensagem TMQ ao destinatário.
echo "Solicitando o TMQ..."
sleep 1
echo "TMQ" | nc "$IP_SERVER" "$PORT_SERVER"
# Destinatário responde com o valor em bytes
TMQ=`nc "$IP_SERVER" "$PORT_SERVER"`
echo "TMQ recebido. TMQ = $TMQ bytes"
echo -e "\n--------\n"
# Conta quantos bytes tem o arquivo
tamanho=`echo "$dados" | wc -c`
n_quadros=$(( tamanho / TMQ ))
# Envia n_envios quadros
if [ "$tamanho" == "0" ]; then
	n_quadros=1
fi

for(( i=1; i <= $(( n_quadros )); i++ )); do
	# Remetente verifica se há colisão (probabilidade). 
	COLISAO=2
	# Verifica se houve colisão
	while [ "$COLISAO" = $(( RANDOM % 4 )) ]; do
		echo "Verificando Colisão..."
		echo "Houve Colisão! Aguardando..."
		# Aguarda tempo aleatório
		sleep $((( RANDOM % 3 ) + 1))
	done
	# Parte o arquivo
	parte=`echo -n "$dados" | cut -c"$i"-"$(( i * TMQ ))"`
	echo "Montando o quadro..."
	sleep 1
	# monta o quadro
	montaQuadro "$parte" "$IP_SERVER"
	quadro=`cat quadroHex.hex`
	# converte pra binário
	arq_bin=`toBinary "$quadro"`
	echo "$arq_bin" > "quadro_in${i}.txt"
	echo "Enviando o quadro..."
	#Envia o quadro Ethernet no formato binário textual para o servidor da camada física
	nc "$IP_SERVER" "$PORT_SERVER" < "quadro_in${i}.txt"
	sleep 2
	echo "Quadro Enviado."
	echo -e "\n--------\n"
done