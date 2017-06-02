#include <stdio.h>
#include <stdlib.h>
#include <iostream>

#include <netdb.h>
#include <netinet/in.h>

#include <string.h>
#include <unistd.h>

//Constantes de entrada
#define IP argv[1]
#define PORTA argv[2]
#define FILESERVER argv[3]

using namespace std;
FILE *openfile;

int main(int argc, char **argv) {
	char resultcode[50];

	/***Le arquivo html no servidor**/
	string caminho = string("./") + string(FILESERVER) + string(".html");

	openfile = fopen (caminho.c_str(), "r");
	if (openfile) {
	    strcpy(resultcode, "200 OK");
	} else {
	    strcpy(resultcode, "404 Not Found");
	    openfile = fopen ("404.html", "r");
	}

	char  linha[300] = "", html[1024] = "";

	while (fgets(linha, 300, openfile) != NULL)
	    strcat(html, linha);          // append the new data

	fclose(openfile);

	caminho = string("./") + string(FILESERVER);
	openfile = fopen (caminho.c_str(), "w");
	fprintf(openfile, "HTTP/1.1 %s\r\nLocation: http://%s:%s\r\nDate: %s %s\r\nServer: Apache/2.2.22\r\nContent-Type: text/html\r\nConnection: close\r\n%s", resultcode, IP, PORTA, __DATE__, __TIME__, html);
	fclose(openfile);

    return 0;
}
