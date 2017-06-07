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


#Informações da Entidade Par
IP_SERVER=`echo -n $1`
PORT_SERVER=`echo -n $2`
PORT_CLIENT=`echo -n $3`
PORT_WEB=`echo -n $4`
TMQ=128
ARQ_SOLICITADO=`echo -n $5`               # Nome do arquivo solicitado pela camada Fisica
IP_CLIENT=`ip route show default | grep "src" | awk '{print $9}'`
PROTOCOLO=`echo -n $6`
QTD_SEG=`echo -n $7`



#Se não informar o IP_SERVER
if [ -z "$IP_SERVER" ]; then
    echo "O IP do servidor deve ser informado"
    exit
fi

#Se não informar a porta
if [ -z "$PORT_SERVER" ]; then
    echo "A porta que será escutada pelo servidor deve ser informada"
    exit
fi

#Se não informar a porta
if [ -z "$PORT_CLIENT" ]; then
    echo "A porta que será escutada pelo cliente deve ser informada"
    exit
fi




function envia() {
	#-------------------------------------------------------------

	# Estabelece Conexão com o servidor e envia seu IP
	sleep 0.1
	echo "$IP_CLIENT" | nc "$IP_SERVER" "$PORT_SERVER"


	# Envia sua Porta para o servidor
	sleep 0.1
	echo "$PORT_CLIENT" | nc "$IP_SERVER" "$PORT_SERVER"


	# Recebe confirmação do IP pelo servidor
	RESPOSTA=`nc -l "$PORT_CLIENT"`

	# Caso a confirmação do IP seja realizada, continua a execuçao
	if [ "$RESPOSTA" = "$IP_CLIENT" ]; then
		echo "IP Ok!"
		sleep 0.1
		echo "1" | nc "$IP_SERVER" "$PORT_SERVER"

		# Recebe confirmação da Porta pelo servidor
		RESPOSTA=`nc -l "$PORT_CLIENT"`

		# Caso a confirmação da Porta seja realizada, continua a execuçao
		if [ "$RESPOSTA" = "$PORT_CLIENT" ]; then
			echo "Porta Ok!"
			sleep 0.1
			echo "1" | nc "$IP_SERVER" "$PORT_SERVER"

			# Envia TMQ para o servidor
			sleep 0.1
			echo "$TMQ" | nc "$IP_SERVER" "$PORT_SERVER"
			# Recebe confirmação da TMQ pelo servidor
			RESPOSTA=`nc -l "$PORT_CLIENT"`
			# Caso a confirmação do TMQ seja realizada, continua a execuçao
			if [ "$RESPOSTA" = "$TMQ" ]; then
				echo "TMQ OK!"
				sleep 0.1
				echo "1" | nc "$IP_SERVER" "$PORT_SERVER"

				# Envia nome do arquivo
				sleep 0.1
				echo "$ARQ_SOLICITADO" | nc "$IP_SERVER" "$PORT_SERVER"

				# Recebe confirmação do Nome do arquivo pelo servidor
				RESPOSTA=`nc -l "$PORT_CLIENT"`
				# Caso a confirmação do Nome do arquivo seja realizada, continua a execuçao
				if [ "$RESPOSTA" = "$ARQ_SOLICITADO" ]; then
					echo "Nome do arquivo OK!"
					sleep 0.1
					echo $PORT_WEB | nc "$IP_SERVER" "$PORT_SERVER"

					# Espera a solicitacao da Qtd de quadros
	                QTD=`nc -l $PORT_CLIENT`

	                # Envia confirmação da Qtd de quadros ao cliente
	                sleep 0.1
	                echo "$QTD" | nc "$IP_SERVER" "$PORT_SERVER" 

	                # Espera confirmação da Qtd de quadros
	                OK=`nc -l $PORT_CLIENT`

	                if [ "$OK" = "1" ]; then
	                    echo "Qtd de quadros Ok!"

						# Recebe os arquivos
						for(( i=1; i <= $(( QTD )); i++ )); do
						    # Recebe o arquivo
						    quadro=`nc -l $PORT_CLIENT`
						    
						    # Envia confirmação do recebimento do quadro ao cliente
	                		sleep 0.1
	                		echo "1" | nc "$IP_SERVER" "$PORT_SERVER" 

							# Espera confirmação da Qtd de quadros
			                OK=`nc -l $PORT_CLIENT`

			                if [ "$OK" = "1" ]; then
			                    echo "Quadro Ok!"

							    # Converte de binario para HexDump
							    FILE_DATA=`toHex "$quadro"` 
							    echo "$FILE_DATA" > "quadro_in.txt"
											    
							    # Converte de HexDump para string
							    xxd -p -r "quadro_in.txt" > aux.txt
							    aux=`cat aux.txt`
							    aux=`echo "${aux:44}"` 	# Remove campos do RFC do inicio do quadro 
							    aux=`echo "${aux::-8}"` 	# Remove o CRC do final do quadro

			                    # Apaga o arquivo desatualizado se existir
							    rm $ARQ_SOLICITADO &> /dev/null

							    echo "$aux" >> $ARQ_SOLICITADO 
							    
							    echo -e "\n--------\n"
							    rm aux.txt &> /dev/null
							    rm quadro_in.txt &> /dev/null

							# Caso a confirmação do quadro não seja realizada, finaliza a execuçao
			                else
			                    echo "Falha na conexão Envio de quadro"
			                fi
						done


	                # Caso a confirmação da Qtd de quadros não seja realizada, finaliza a execuçao
	                else
	                    echo "Falha na conexão Qtd de quadros diverge"
	                fi

				else
					echo "Falha na conexão Nome do arquivo diverge"
					sleep 0.1
					echo "0" | nc "$IP_SERVER" "$PORT_SERVER"
				fi

			else
				echo "Falha na conexão TMQ diverge"
				sleep 0.1
				echo "0" | nc "$IP_SERVER" "$PORT_SERVER"
			fi

		# Caso a confirmação da Porta não seja realizada, finaliza a execuçao
		else
			echo "Falha na conexão Porta diverge"
			sleep 0.1
			echo "0" | nc "$IP_SERVER" "$PORT_SERVER"
		fi

	# Caso a confirmação do IP não seja realizada, finaliza a execuçao
	else
		echo "Falha na conexão IP diverge"
		sleep 0.1
		echo "0" | nc "$IP_SERVER" "$PORT_SERVER"
	fi
}


if [ "$PROTOCOLO" = "udp" ]; then
	for (( i=0 ; i<${QTD_SEG} ; i+=1 )); do 
		segmento=`cat segmento"$i"`
		$ARQ_SOLICITADO
	done
fi
