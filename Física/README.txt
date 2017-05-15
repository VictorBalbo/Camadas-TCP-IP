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


*** Visão Geral

	- A linguagem utilizada foi o Shell Script. 
	- O código só poderá ser executado em sistemas Linux.
	- Foi utilizado o comando nc. É necessário ter o mesmo instalado. (sudo apt-get install netcat) 
	- O nc por padrão faz conexões tcp, não sendo necessário passar algum parâmetro para especificar o uso do TCP.
	- O arquivo é convertido para HexDump e depois convertido para binário para ser enviado.
	- Os arquivos enviados correspondentes aos quadros enviados estão no mesmo diretório dos scripts e seguem o padrão "quadro_in<seguencia>.txt"



*** Tutorial de execução

1 - Coloque um texto para ser enviado no arquivo "pacote.txt"

2 - Abra um terminal para o cliente e outro para o servidor

3 - Rode o servidor com comando:
./fisica_sr.sh PORTA TMQ

4 - Rode o cliente com o comando:
./fisica_cl.sh IP_SERVIDOR PORTA



*** Teste

------------------------------------------------- Cliente ------------------------------------------------------------
./fis_cliente.sh 192.168.0.2 8080
Solicitando o TMQ...
TMQ recebido. TMQ = 1000 bytes

--------

Verificando Colisão...
Houve Colisão! Aguardando...
Montando o quadro...
PREAMBULO(hex): aaaaaaaaaaaaaa
SFD(hex): ab
Tamanho/Tipo(hex): 0800
MAC da Origem: 70:2c:1f:0a:31:97
MAC do Destino: 70:2c:1f:0a:31:97
CRC(hex): 36a587b2
Enviando o quadro...
Quadro Enviado.

--------

Montando o quadro...
PREAMBULO(hex): aaaaaaaaaaaaaa
SFD(hex): ab
Tamanho/Tipo(hex): 0800
MAC da Origem: 70:2c:1f:0a:31:97
MAC do Destino: 70:2c:1f:0a:31:97
CRC(hex): bf14dd56
Enviando o quadro...
Quadro Enviado.

--------

Montando o quadro...
PREAMBULO(hex): aaaaaaaaaaaaaa
SFD(hex): ab
Tamanho/Tipo(hex): 0800
MAC da Origem: 70:2c:1f:0a:31:97
MAC do Destino: 70:2c:1f:0a:31:97
CRC(hex): 05471056
Enviando o quadro...
Quadro Enviado.

--------
 
------------------------------------------------- Servidor -----------------------------------------------------------
./fis_server.sh 8080 1000
Esperando conexão...
Cliente solicitou o TMQ. Enviando TMQ = 1000...

--------

Esperando conexão...
Arquivo recebido.

--------

Esperando conexão...
Arquivo recebido.

--------

Esperando conexão...
Arquivo recebido.

--------

Esperando conexão...



