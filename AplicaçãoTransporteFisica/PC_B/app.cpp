#include <stdio.h>
#include <stdlib.h>
#include <iostream>

#include <netdb.h>
#include <netinet/in.h>

#include <string.h>
#include <unistd.h>

//Constantes de entrada
#define PORTA argv[2]
#define FILESERVER argv[3]

using namespace std;
FILE *openfile;

int main(int argc, char **argv) {
	char resultcode[50], linha[300] = "", result[1024] = "";
    openfile = fopen ("./mensagem", "r");
    while (fgets(linha, 300, openfile) != NULL){
            strcat(result, linha);          // append the new data
    }
    fclose(openfile);
    char *metodo = strtok(result, "\n");
    char *ip = strtok(NULL, "\n");
    char *porta = strtok(NULL, "\n");
    char *hostname = strtok(NULL, "\n");
    char *fileserver = strtok(NULL, "\n");

	/***Le arquivo html no servidor**/
	string caminho = string("./") + string(fileserver) + string(".html");

	openfile = fopen (caminho.c_str(), "r");
	if (openfile) {
	    strcpy(resultcode, "200 OK");
	} else {
	    strcpy(resultcode, "404 Not Found");
	    openfile = fopen ("404.html", "r");
	}

	char  html[1024] = "";

	while (fgets(linha, 300, openfile) != NULL)
	    strcat(html, linha);          // append the new data

	fclose(openfile);
	system("rm mensagem");

	openfile = fopen ("./mensagem", "w");
	fprintf(openfile, "HTTP/1.1 %s\r\nLocation: http://%s:%s\r\nDate: %s %s\r\nServer: Apache/2.2.22\r\nContent-Type: text/html\r\nConnection: close\r\n\n%s", resultcode, ip, porta, __DATE__, __TIME__, html);
	fclose(openfile);

    return 0;
}
