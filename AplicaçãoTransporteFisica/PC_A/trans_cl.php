<?php
require_once 'camadas.php';
/*
pack format
n   unsigned short (always 16 bit, big endian byte order)

Cabeçalho UDP:
Source Port -> S
Destination Port -> S
Length -> S
Checksum -> S

pack("nnnn")
*/

/*

echo PHP_EOL . "MSG: " . $VAR . PHP_EOL;

    Recebe:
    - IP destino
    - porta destino
    - mensagem

    Parte em segmentos e envia para Física

    Envia:
    - IP destino
    - porta destino
    - segmento
*/

const TMS = 2048;
const SEGMENTO = "segmento";
const MENSAGEM = "mensagem";        // nome do arquivo da mensagem
const UDP = "udp";
const TCP = "tcp";
const CONEXAO = "conexao";



if ($argc < 5) {
    echo "*** Camada de Transporte **" . PHP_EOL;
    echo "Parâmetros insuficientes!" . PHP_EOL;
    echo "php trans_cl.php protocolo porta_origm(fis) ip_destino porta_destino(fis)" . PHP_EOL;
    die;
}


$protocolo = $argv[1];
$porta_origem = $argv[2];
$ip_destino = $argv[3];
$porta_destino = $argv[4];


// Coloca os campos de cabeçalho
function criaSegmentoUDP($seq_num, $parte) {
    global $porta_origem, $ip_destino, $porta_destino;
    $segmento = $seq_num . PHP_EOL . $porta_origem . PHP_EOL . $ip_destino . PHP_EOL . $porta_destino . PHP_EOL . strlen($parte) . PHP_EOL;
    $crc32 = crc32($segmento) + crc32($parte);
    $segmento = $segmento . $crc32 . PHP_EOL . $parte;
    return $segmento;
}


// Coloca os campos de cabeçalho
function criaSegmentoTCP($seq_num, $parte) {
    global $ip_destino, $porta_destino;
    $segmento = $seq_num . PHP_EOL . $ip_destino . PHP_EOL . $porta_destino . PHP_EOL . strlen($parte) . PHP_EOL;
    $crc32 = crc32($segmento) + crc32($parte);
    $segmento = $segmento . $crc32 . PHP_EOL . $parte;
    return $segmento;
}


function divideMensagem() {
    global $protocolo;
    $arquivo = fopen(MENSAGEM, "r") or die("Unable to open file!");
    $conteudo = fread($arquivo,filesize(MENSAGEM));
    fclose($arquivo);

    $segmentos = array();
    $num_segmentos = strlen($conteudo) / TMS;
    for ($i = 0; $i <= $num_segmentos; $i++) {
        $parte = substr($conteudo, $i * TMS, TMS);
        if ($protocolo == UDP) {
            array_push($segmentos, criaSegmentoUDP($i, $parte));    
        }
        else {
            array_push($segmentos, criaSegmentoTCP($i, $parte));
        }
    }

    foreach ($segmentos as $segmento) {
        $seq_num = strtok($segmento, "\n");
        $seg_name = SEGMENTO.$seq_num;
        $arquivo = fopen($seg_name, "w") or die("Unable to open file!");
        $conteudo = fwrite($arquivo, $segmento);
        fclose($arquivo);
    }

}


function retiraCabecalhoUDP($segmento) {
    $seq_num = strtok($segmento, "\n");
    $porta_destino = strtok("\n");
    $ip_origem = strtok("\n");
    $porta_origem = strtok("\n");
    $tamanho = strtok("\n");
    $crc32 = strtok("\n");
    $parte = strtok(feof());
    return array('seq_num' => $seq_num, 'porta_destino' => $porta_destino,  'ip_origem' => $ip_origem,
                'porta_origem' => $porta_origem, 'tamanho' => $tamanho, 'crc32' => $crc32,
                'parte' => $parte);
}


function retiraCabecalhoTCP($segmento) {
    $seq_num = strtok($segmento, "\n");
    $porta_destino = strtok("\n");
    $ip_origem = strtok("\n");
    $porta_origem = strtok("\n");
    $tamanho = strtok("\n");
    $crc32 = strtok("\n");
    $parte = strtok(feof());
    return array('seq_num' => $seq_num, 'porta_destino' => $porta_destino,  'ip_origem' => $ip_origem,
                'porta_origem' => $porta_origem, 'tamanho' => $tamanho, 'crc32' => $crc32,
                'parte' => $parte);
}


function reconstruirMensagem($qtd_seg) {
    global $protocolo;
    $arquivo = fopen(MENSAGEM, "w") or die("Unable to open file!");
    $conteudo = fread($arquivo, filesize("Novo.sh"));
    for ($i = 0; $i < $qtd_seg; $i++){
        // concatena a string segmento com numero da sequencia
        $seg_name = SEGMENTO . $i;
        // Se o segmento n existir ele continua a execução
        if (!file_exists($seg_name))
            continue;
        $seg = fopen($seg_name, "r");
        $conteudo = fread($seg,filesize($seg_name));
        fclose($seg);
        $segmento = NULL;
        if ($protocolo == UDP) {
            $segmento = retiraCabecalhoUDP($conteudo);    
        } else {
            $segmento = retiraCabecalhoTCP($conteudo);    
        }
        fwrite($arquivo, $segmento['parte']);
    }
    // Le mensagem
    fclose($arquivo);
}


function deletarPacotes() {
    system("for i in `ls | grep -h ^pacote[0-9]*$`; do rm $i; done")
}


function chamarCamadaRede() {
    //Chamar rede (balbo?DeuBom:Fudeu)
    // passa por parametro: protocolo porta_origm(fis) ip_destino porta_destino(fis)  
    system(..., $qtd_seg);
    return $qtd_seg;
}




if ($protocolo == UDP) {
    // Se for UDP nao estabelece conexao, ja envia os segmentos
    divideMensagem();                   // Divide em segmentos
    $qtd_seg = chamarCamadaRede();      // Ja escreveu os segmentos em arquivos e chama a rede  
    deletarPacotes();
    reconstruirMensagem($qtd_seg);      // Reconstroi as mensagens
} else {
    //--------- Estabelece conexao criando um segmento com a string "conexao"
    $segmento = criaSegmentoTCP(0, CONEXAO);
    $seg_name = SEGMENTO . '0';
    // Escreve no segmento para mandar
    $arquivo = fopen($seg_name, "w") or die("Unable to open file!");
    $conteudo = fwrite($arquivo, $segmento);
    // ------- Verifica se a conexao foi estabelecida

    system()
}






deletarPacotes();
reconstruirMensagem($qtd_seg);

?>