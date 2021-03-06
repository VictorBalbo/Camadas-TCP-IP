#include "camadas.h"
#include <string.h>

//Cabeçalho TCP aleatório
char tcp_header[32] = {0xd0, 0xaa, 0x00, 0x50, 0x7a, 0x51, 0xc3, 0xfa,
                       0x3c, 0x56, 0xee, 0x6b, 0x80, 0x18, 0x00, 0xe5,
                       0xde, 0xf2, 0x00, 0x00, 0x01, 0x01, 0x08, 0x0a,
                       0x00, 0x1e, 0x34, 0xee, 0x4d, 0x8c, 0xab, 0xa6};

//Cabeçalho IP para TCP aleatório
char ip_header[20]  = {0x45, 0x00, 0x01, 0xb9, 0xf7, 0x1c, 0x40, 0x00,
                       0x40, 0x06, 0x6a, 0xb2,
                       0x0a, 0x00, 0x7f, 0xda,  //IP de origem  [12..15]
                       0x0a, 0x00, 0x02, 0x69}; //IP de destino [16..19]

// Formata a mensagem
char *prepara_mensagem(char *msg) {
    char *nova_msg = new char[5000];
    // Coloca o cabeçalho IP
    bcopy(ip_header, nova_msg, 20);
    // Coloca o cabeçalho TCP
    bcopy(tcp_header, nova_msg + 20, 32);
    // Coloca a resposta HTTP
    bcopy(msg, nova_msg + 52, strlen(msg));

    return nova_msg;
}
