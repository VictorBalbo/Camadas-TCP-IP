#include <stdio.h>
#include <stdlib.h>
#include <iostream>

#include <netdb.h>
#include <netinet/in.h>

#include <string.h>
#include <unistd.h>

using namespace std;
FILE *openfile;

#define PROTOCOLO_TCP "tcp"
#define PROTOCOLO_UDP "udp"

int main(int argc, char **argv) {
    int sockfd, newsockfd, portno;
    socklen_t clilen;
    char buffer[1024];
    char resultcode[50], fileserver[50];
    struct sockaddr_in serv_addr, cli_addr;
    int  n;

    if (argc < 3) {
        printf("Execução: ./app_sr protocolo porta_escutada\n");
        exit(1);
    }

    /* First call to socket() function */
    sockfd = socket(AF_INET, SOCK_STREAM, 0);

    if (sockfd < 0) {
        perror("ERROR opening socket");
        exit(1);
    }

    /* Initialize socket structure */
    bzero((char *) &serv_addr, sizeof(serv_addr));
    portno = atoi(argv[2]);

    serv_addr.sin_family = AF_INET;
    serv_addr.sin_addr.s_addr = INADDR_ANY;
    serv_addr.sin_port = htons(portno);

    /* Now bind the host address using bind() call.*/
    if (bind(sockfd, (struct sockaddr *) &serv_addr, sizeof(serv_addr)) < 0) {
        perror("ERROR on binding");
        exit(1);
    }

    /* Now start listening for the clients, here process will
    * go in sleep mode and will wait for the incoming connection
    */
    listen(sockfd, 5);
    clilen = sizeof(cli_addr);

    cout << "Aguardando requisição...\n";
    while (1) {
        /* Accept actual connection from the client */
        newsockfd = accept(sockfd, (struct sockaddr *)&cli_addr, &clilen);
        if (newsockfd < 0) {
            perror("ERROR on accept");
            exit(1);
        }

        /* If connection is established then start communicating */
        bzero(buffer, 1024);
        n = read(newsockfd, buffer, 1024);
        //Ignoring favicon requests
        if(strstr(buffer,"favicon")!=NULL){close(newsockfd); continue;}
        if (n < 0) {
            perror("ERROR reading from socket");
            exit(1);
        }
        /****METODO DA REQUISIÇAO**/
        cout << buffer << endl;

        char *metodo  = strtok(buffer, " ");

        /****FILE SERVER**/
        strcpy(fileserver, strtok(NULL, " "));
        
        if (strcmp(fileserver, "/") == 0 ) //arquivo padrao do servidor
            strcpy(fileserver, "/index");

        //remover a '/'
        for(int i=0; fileserver[i] != '\0'; i++)
            fileserver[i] = fileserver[i+1];
        
        /****HOST SERVER**/
        strtok(NULL, "\r\n");
        char *hostname = strtok(NULL, "\r\n");
        strtok(hostname, " ");
        hostname = strtok(NULL, "");

        char temp[20];
        strcpy(temp, hostname);
        char *ip = strtok(temp, ":");
        char *porta = strtok(NULL, ":\r\n ");
    
        cout << "Método: " << metodo << endl;
        cout << "IP: " << ip << endl;
        cout << "Porta: " << porta << endl;
        cout << "Host: " << hostname << endl;
        cout << "Arquivo: " << fileserver << endl;


        
        // escrever o buffer no arquivo mensagem
        FILE* mensagem = fopen ("mensagem", "w+");
        char* ptr = strtok(buffer, "\r\n");
        while (ptr != NULL) {
            fprintf(mensagem, "%s\n", buffer);
            ptr = strtok(NULL, "\r\n");
        }
        fclose(mensagem);

        
// CHAMAR CAMADA FISICA PARA SOLICITAÇÃO DO ARQUIVO HTML
        char protocolo[4];
        char porta_escutada[16]; 
        strcpy(protocolo, argv[1]);
        strcpy(porta_escutada, argv[2]);
        printf("\nProtocolo: %s\n", protocolo);
        printf("\nPorta escutada: %s\n", porta_escutada);
        if (strcmp (protocolo, PROTOCOLO_UDP) == 0){
            //php udp_cl.php acao porta_origem ip_destino porta_destino mensagem qtd_seg(acao=reconstruir) 
            char solicitacao[1024] = "php udp_cl.php dividir ";
            strcat(solicitacao, porta_escutada);
            strcat(solicitacao, " ");
            strcat(solicitacao, ip);
            strcat(solicitacao, " ");
            strcat(solicitacao, porta);
            strcat(solicitacao, " ");
            strcat(solicitacao, "mensagem");
            system(solicitacao);
        } else {
            char solicitacao[1024] = "php tcp_cl.php dividir ";
            strcat(solicitacao, porta_escutada);
            strcat(solicitacao, ip);
            strcat(solicitacao, porta);
            strcat(solicitacao, fileserver);
            system(solicitacao);
        }
// SALVAR EM /index.http


        string caminho = string("./") + string(fileserver);
        char linha[300] = "", result[1024] = "";
        openfile = fopen (caminho.c_str(), "r");
        while (fgets(linha, 300, openfile) != NULL)
                strcat(result, linha);          // append the new data
        fclose(openfile);

      
        n = write(newsockfd, result, strlen(result));

        if (n < 0) {
            perror("ERROR writing to socket");
            exit(1);
        }

        close(newsockfd);   
        cout << "Aguardando requisição...\n";
    }
    return 0;
}