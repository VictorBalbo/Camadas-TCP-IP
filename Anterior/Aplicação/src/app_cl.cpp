#include <stdio.h>
#include <stdlib.h>
#include <iostream>
#include <iomanip>

#include <netdb.h>
#include <netinet/in.h>

#include <string.h>
#include <unistd.h>

using namespace std;

int main(int argc, char **argv) {
    int sockfd, port, n;
    struct sockaddr_in server_end;
    struct hostent *server;
    char buffer[1024];

    if (argc < 2) {
        // Recebe a porta que sera utilizada
        printf("Execução: ./app_cl porta_transporte\n");
        exit(1);
    }
    port = atoi(argv[1]);

    // Cria um socket
    sockfd = socket(AF_INET, SOCK_STREAM, 0);
    if (sockfd < 0) {
        perror("ERROR opening socket");
        exit(1);
    }

    // Define o hostname
    server = gethostbyname("127.0.0.1");
    if (server == NULL) {
        fprintf(stderr,"ERROR, no such host\n");
        exit(0);
    }

    // Preenche o endereco do servidor com zeros
    bzero((char *) &server_end, sizeof(server_end));
    // Precisa especificar AF_INET para utilizar o TCP/IP
    server_end.sin_family = AF_INET;
    bcopy((char *)server->h_addr, (char *)&server_end.sin_addr.s_addr, server->h_length);
    // Atribui a porta ao endereco
    server_end.sin_port = htons(port);

    /* Now connect to the server */
    if (connect(sockfd, (struct sockaddr*)&server_end, sizeof(server_end)) < 0) {
        perror("ERROR connecting");
        exit(1);
    }

    // Envia uma mensagem digitada pelo usuario para o server
    printf("URL: ");
    cin >> buffer;

    if (strchr(buffer, '/') == NULL)
        strcat(buffer, "/");

    // Faz a requisição
    string str = string(buffer);

    char req[1024] = "GET ";
    strcat(req, str.substr(str.find("/")).c_str());
    strcat(req, " HTTP/1.1\r\n");
    strcat(req, "Host: ");
    str.at(str.find("/")) = '\0';
    strcat(req, str.c_str());
    strcat(req, "\r\nUser-Agent: Mozilla/5.0\r\n");
    strcat(req, "Accept: text/html\r\n");
    strcat(req, "Accept-Language: pt-BR,pt\r\n");
    strcat(req, "Accept-Encoding: gzip, deflate\r\n");

    cout << "Requisição: " << endl;
    cout << req << endl;

    //char *msg_resposta = prepara_mensagem(req);
    //não precisa mais adicionar os cabeçalhos nessa camada.

    /* Send message to the server */
    n = write(sockfd, req, strlen(req));

    //delete[] msg_resposta;

    if (n < 0) {
        perror("ERROR writing to socket");
        exit(1);
    }

    cout << "Aguardando resposta do servidor...\n";

    bzero(buffer, 1024);
    n = read(sockfd, buffer, 1024);

    if (n < 0) {
        perror("ERROR reading from socket");
        exit(1);
    }

    strtok(buffer, " "); //HTTP/1.1
    cout << "Status: " << strtok(NULL, "\r\n") << endl; //Status Message
    strtok(NULL, "\r\n"); //Location
    strtok(NULL, "\r\n"); //Date
    strtok(NULL, "\r\n"); //Server
    strtok(NULL, "\r\n"); //Content-Type
    strtok(NULL, "\r\n"); //Connection
    cout << "Página:" << endl;
    char *pagina = strtok(NULL, "");
    cout << (pagina + 3) << endl;

    close(sockfd);

    return 0;
}
