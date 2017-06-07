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
const ACAO_DIVIDIR = 'dividir'; // Dividir a mensagem em segmentos
const ACAO_RECONSTRUIR = 'reconstruir'; // Dividir a mensagem em segmentos

$qtd_seg = 0;

if ($argc < 7) {
    if ($argc <= 1) {
        echo "Parâmetros insuficientes!" . PHP_EOL;
        echo "php udp_cl.php acao porta_origem ip_destino porta_destino mensagem qtd_seg(acao=reconstruir) " . PHP_EOL;
        die;
    } else if ($argv[1] == ACAO_RECONSTRUIR) {
        echo "Parâmetros insuficientes!" . PHP_EOL;
        echo "php udp_cl.php acao porta_origem ip_destino porta_destino mensagem qtd_seg(acao=reconstruir)" . PHP_EOL;
        die;
    } else if ($argv[1] == ACAO_DIVIDIR && $argc < 6) {
        echo "Parâmetros insuficientes!" . PHP_EOL;
        echo "php udp_cl.php acao porta_origem ip_destino porta_destino mensagem" . PHP_EOL;
        die;
    }
}

$acao = $argv[1];
$porta_origem = $argv[2];
$ip_destino = $argv[3];
$porta_destino = $argv[4];
$mensagem = $argv[5];
if ($argv[1] == ACAO_RECONSTRUIR) {
    $qtd_seg = $argv[6];
}

// Coloca os campos de cabeçalho
function criaSegmento($seq_num, $parte) {
    global $porta_origem, $ip_destino, $porta_destino;
    $segmento = $seq_num . PHP_EOL . $porta_origem . PHP_EOL . $ip_destino . PHP_EOL . $porta_destino . PHP_EOL . strlen($parte) . PHP_EOL;
    $crc32 = crc32($segmento) + crc32($parte);
    $segmento = $segmento . $crc32 . PHP_EOL . $parte;
    return $segmento;
}


function divideMensagem() {
    global $mensagem;
    $arquivo = fopen($mensagem, "r") or die("Unable to open file!");
    $conteudo = fread($arquivo,filesize($mensagem));
    fclose($arquivo);

    $segmentos = array();
    $num_segmentos = strlen($conteudo) / TMS;
    for ($i = 0; $i <= $num_segmentos; $i++) {
        $parte = substr($conteudo, $i * TMS, TMS);
        array_push($segmentos, criaSegmento($i, $parte));
    }

    foreach ($segmentos as $segmento) {
        $seq_num = strtok($segmento, "\n");
        $seg_name = SEGMENTO.$seq_num;
        $arquivo = fopen($seg_name, "w") or die("Unable to open file!");
        $conteudo = fwrite($arquivo, $segmento);
        fclose($arquivo);
    }

}


function retiraCabecalho($segmento) {
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


function reconstruirMensagem($qtd_seg, $file_name) {
    $arquivo = fopen($file_name, "w") or die("Unable to open file!");
    $conteudo = fread($arquivo, filesize("Novo.sh"));
    for ($i = 0; $i < $qtd_seg; $i++){
        $seg_name = SEGMENTO.$i;
        // Como é UDP, se o segmento n existir ele continua a execução
        if (!file_exists($seg_name))
            continue;
        $seg = fopen($seg_name, "r");
        $conteudo = fread($seg,filesize($seg_name));
        fclose($seg);
        $segmento = retiraCabecalho($conteudo);
        fwrite($arquivo, $segmento['parte']);
    }
    // Le mensagem
    fclose($arquivo);
}

if ($acao == ACAO_DIVIDIR) {
    divideMensagem();
} else if ($acao == ACAO_RECONSTRUIR) {
    reconstruirMensagem($qtd_seg, $mensagem);
}

?>