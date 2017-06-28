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


# Componentes do quadro segundo o RFC
function montaQuadro() {
    dados=$1
    IP_SERVER=$2
    arquivo_solicitado=$3
    
    IFACE=`ip route show default | awk '/default/ {print $5}' | head -1`

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
    echo -n "${PREAMBULO}${SFD}${MAC_DEST}${MAC_ORIG}${TAM_TIPO}${dados}" | xxd -p > quadro_hex.hex
    #Calcula o CRC e adiciona no final do quadro
    CRC=`crc32 quadro_hex.hex`
    echo "$CRC" | xxd -p >> quadro_hex.hex
    echo "CRC(hex): $CRC"
}


function enviaPacotes() {
    PORTA_ORIGEM=`echo -n $1`
    IP_DESTINO=`echo -n $2`
    PORTA_DESTINO=`echo -n $3`

    echo "$PORTA_ORIGEM $IP_DESTINO $PORTA_DESTINO"

    pacotes=`ls | grep -h ^pacote[0-9]*$`

    # Comando para pegar a quantidade de palavras na string
    set -- $pacotes
    qtd_pacotes=`echo $#`

    # Envia a quantidade de pacotes
    sleep 0.1
    echo "$qtd_pacotes" | nc "$IP_DESTINO" "$PORTA_DESTINO"
    echo "echo 2"
    # Recebe confirmação da qtd_pacotes pelo servidor

    RESPOSTA=`nc -l "$PORTA_ORIGEM"`
    # Caso a confirmação da quantidade de pacotes seja realizada, continua a execuçao
    if [ "$RESPOSTA" = "$qtd_pacotes" ]; then
        echo "Quantidade de Pacotes OK!"
        sleep 0.1
        echo "1" | nc "$IP_DESTINO" "$PORTA_DESTINO"

        for pct in "$pacotes"; do
            pacote=`cat $pct`

            # Calcula quantos quadros serao enviados
            tamanho=`echo "$pacote" | wc -c`
            QTD=$(( (tamanho / TMQ) + 1 ))

            # Envia Qtd de quadros para o servidor
            sleep 0.1
            echo "$QTD" | nc "$IP_DESTINO" "$PORTA_DESTINO"

            # Recebe confirmação da Qtd de quadros pelo servidor
            RESPOSTA=`nc -l "$PORTA_ORIGEM"`

            # Caso a confirmação da Qtd de quadros seja realizada, continua a execuçao
            if [ "$RESPOSTA" = "$QTD" ]; then
                echo "Qtd de quadros OK"                        
                sleep 0.1
                echo "1" | nc "$IP_DESTINO" "$PORTA_DESTINO"
                echo -e "\n--------\n"                          

                # Recebe quantidade QTD de quadros
                for(( i=1; i <= $(( QTD )); i++ )); do
                    # Remetente verifica se há colisão (probabilidade). 
                    COLISAO=2
                    # Verifica se houve colisão
                    while [ "$COLISAO" = $(( RANDOM % 10 )) ]; do
                        echo "Verificando Colisão..."
                        echo "Houve Colisão! Aguardando..."
                        # Aguarda tempo aleatório
                        sleep $((( RANDOM % 3 ) + 1))
                    done
                    
                    # Parte o arquivo
                    parte=`echo "$pacote" | cut -c"$i"-"$(( i * TMQ ))"`
                    
                    # Monta o quadro
                    montaQuadro "$parte" "$IP_SERVER"
                    quadro=`cat quadro_hex.hex`
                    rm "quadro_hex.hex" &> /dev/null
                    
                    # converte pra binário
                    arq_bin=`toBinary "$quadro"`
                    echo "$arq_bin" > "quadro_out${i}.txt"

                    # Salva quadro em uma variavel
                    quadro=`cat "quadro_out${i}.txt"`
                    # Apaga arquivo temporario
                    rm "quadro_out${i}.txt" &> /dev/null
                    #Envia o quadro para o cliente
                    sleep 0.1
                    echo "$quadro" | nc "$IP_DESTINO" "$PORTA_DESTINO"
                    
                    # Recebe confirmação de recebimento do quadro pelo servidor
                    RESPOSTA=`nc -l "$PORTA_ORIGEM"`

                    # Caso a confirmação da Qtd de quadros seja realizada, continua a execuçao
                    if [ "$RESPOSTA" = "1" ]; then
                        echo "Quadro OK"
                        sleep 0.1
                        echo "1" | nc "$IP_DESTINO" "$PORTA_DESTINO"
                    else
                        echo "Falha na conexão Envio de quadro"
                        sleep 0.1
                        echo "0" | nc "$IP_DESTINO" "$PORTA_DESTINO"
                    fi
                    echo -e "\n--------\n"
                    
                done        # fim for quadros de um pacote
            else
                echo "Falha na conexão Qtd de quadros diverge"
                sleep 0.1
                echo "0" | nc "$IP_DESTINO" "$PORTA_DESTINO"
            fi
            # apaga pacotes
            rm "$pct" &> /dev/null
        done        # fim for pacotes
    else
        echo "Falha na conexão Qtd de pacotes diverge"
    fi
}

function recebePacotes() {
    PORTA_ORIGEM=`echo -n $1`
    IP_DESTINO=`echo -n $2`
    PORTA_DESTINO=`echo -n $3`

    # Espera a solicitacao da quantidade de pacotes
    qtd_pacotes=`nc -l "$PORTA_ORIGEM"`

    # Envia confirmação do nome do arquivo ao cliente
    sleep 0.1
    echo "$qtd_pacotes" | nc "$IP_DESTINO" "$PORTA_DESTINO"

    # Espera confirmação do nome do arquivo
    OK=`nc -l "$PORTA_ORIGEM"`

    if [ "$OK" = "1" ]; then
        echo "Quantidade de pacotes OK"
        
        for(( j=0; j < $(( qtd_pacotes )); j++ )); do
            # Espera a solicitacao da Qtd de quadros
            QTD=`nc -l "$PORTA_ORIGEM"`

            # Envia confirmação da Qtd de quadros ao cliente
            sleep 0.1
            echo "$QTD" | nc "$IP_DESTINO" "$PORTA_DESTINO"

            # Espera confirmação da Qtd de quadros
            OK=`nc -l "$PORTA_ORIGEM"`

            if [ "$OK" = "1" ]; then
                echo "Qtd de quadros Ok!"

                # Recebe os arquivos
                for(( i=0; i < $(( QTD )); i++ )); do
                    # Recebe o arquivo
                    quadro=`nc -l "$PORTA_ORIGEM"`
                    
                    # Envia confirmação do recebimento do quadro ao cliente
                    sleep 0.1
                    echo "1" | nc "$IP_DESTINO" "$PORTA_DESTINO"

                    # Espera confirmação da Qtd de quadros
                    OK=`nc -l "$PORTA_ORIGEM"`

                    if [ "$OK" = "1" ]; then
                        echo "Quadro Ok!"

                        # Converte de binario para HexDump
                        FILE_DATA=`toHex "$quadro"` 
                        echo "$FILE_DATA" > "quadro_in.txt"
                                        
                        # Converte de HexDump para string
                        xxd -p -r "quadro_in.txt" > aux.txt
                        aux=`cat aux.txt`
                        aux=`echo "${aux:44}"`  # Remove campos do RFC do inicio do quadro 
                        aux=`echo "${aux::-8}"`     # Remove o CRC do final do quadro

                        # Apaga o arquivo desatualizado se existir
                        #rm $ARQ_SOLICITADO &> /dev/null

                        echo "$aux" >> "pacote""$j"
                        echo "Pacote $j"                        
                        echo -e "\n--------\n"
                        rm aux.txt &> /dev/null
                        rm quadro_in.txt &> /dev/null

                    # Caso a confirmação do quadro não seja realizada, finaliza a execuçao
                    else
                        echo "Falha na conexão Envio de quadro"
                    fi
                done    # fim dos quadros

            # Caso a confirmação da Qtd de quadros não seja realizada, finaliza a execuçao
            else
                echo "Falha na conexão Qtd de quadros diverge"
            fi
        done        # fim dos pacotes
    else
        echo "Falha na conexão Qtd de pacotes diverge"
    fi
}


PORT_SERVER=`echo -n $1`                # Porta do servidor


while true; do
    echo "Esperando conexão..."

    # Recebe o ip de solicitacao de conexão
    IP_CLIENT=`nc -l $PORT_SERVER`
    echo "IP Recebido $IP_CLIENT"

    # Recebe a porta para resposta ao cliente
    PORT_CLIENT=`nc -l $PORT_SERVER`    
    echo "Porta Recebido $PORT_CLIENT"

    # Envia confirmação do IP ao cliente
    sleep 0.1
    echo "$IP_CLIENT" | nc "$IP_CLIENT" "$PORT_CLIENT"

    # Espera confirmação do IP
    OK=`nc -l $PORT_SERVER`
    if [ "$OK" = "1" ]; then
        echo "IP Ok!"

        # Envia confirmação da Porta ao cliente
        sleep 0.1
        echo "$PORT_CLIENT" | nc "$IP_CLIENT" "$PORT_CLIENT"
        
        # Espera confirmação da Porta
        OK=`nc -l $PORT_SERVER`
        
        # Caso a confirmação da Porta seja realizada, continua a execuçao
        if [ "$OK" = "1" ]; then
            echo "Porta Ok!"

            # Solicita TMQ
            TMQ=`nc -l $PORT_SERVER`
            
            # Envia confirmação do TMQ ao cliente
            sleep 0.1
            echo "$TMQ" | nc "$IP_CLIENT" "$PORT_CLIENT" 

            # Espera confirmação do TMQ
            OK=`nc -l $PORT_SERVER`

            if [ "$OK" = "1" ]; then
                echo "TMQ Ok!"

                # Espera a solicitacao do nome do arquivo
                ARQ=`nc -l $PORT_SERVER`

                # Envia confirmação do nome do arquivo ao cliente
                sleep 0.1
                echo "$ARQ" | nc "$IP_CLIENT" "$PORT_CLIENT" 

                # Espera confirmação do nome do arquivo
                OK=`nc -l $PORT_SERVER`

                if [ "$OK" = "1" ]; then
                    echo "Nome arquivo OK!"

                    # Solicita o protocolo
                    PROTOCOLO=`nc -l $PORT_SERVER`

                    # Envia confirmação do protocolo ao cliente
                    sleep 0.1
                    echo "$PROTOCOLO" | nc "$IP_CLIENT" "$PORT_CLIENT" 

                    # Espera confirmação do protocolo
                    OK=`nc -l $PORT_SERVER`

                    if [ "$OK" = "1" ]; then
                        echo "Protocolo OK!"

        #---------------------------------------------------------------------------------
                        recebePacotes "$PORT_SERVER" "$IP_CLIENT" "$PORT_CLIENT"
                        #./teste.sh
                        enviaPacotes "$PORT_SERVER" "$IP_CLIENT" "$PORT_CLIENT"
        #---------------------------------------------------------------------------------

                    # Caso a confirmação do Protocolo não seja realizada, finaliza a execuçao
                    else
                        echo "Falha na conexão Protocolo diverge"
                    fi

                # Caso a confirmação do Nome do arquivo não seja realizada, finaliza a execuçao
                else
                    echo "Falha na conexão Nome do arquivo diverge"
                fi

            # Caso a confirmação do TMQ não seja realizada, finaliza a execuçao
            else
                echo "Falha na conexão TMQ diverge"
            fi
        # Caso a confirmação da Porta não seja realizada, finaliza a execuçao
        else
            echo "Falha na conexão Porta diverge"
        fi

    # Caso a confirmação do IP não seja realizada, finaliza a execuçao
    else
        echo "Falha na conexão IP diverge"
    fi
done