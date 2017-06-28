<?php
/*
pack format
n   unsigned short (always 16 bit, big endian byte order)

Cabeçalho UDP:
Source Port -> S
Destination Port -> S
Length -> S
Checksum -> S
pack("nnnn")

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
const ACK = "ack";
const OK = "ok";                  // conferir conexão e outras respostas
const FIMMSG = "|fimMensagem|";

if ($argc < 5) {
    echo "*** Camada de Transporte **" . PHP_EOL;
    echo "Parâmetros insuficientes!" . PHP_EOL;
    echo "php trans_cl.php protocolo porta_origem(fis) ip_destino porta_destino(fis)" . PHP_EOL;
    die;
}

$protocolo = $argv[1];
$porta_origem = $argv[2];
$ip_destino = $argv[3];
$porta_destino = $argv[4];

// Coloca os campos de cabeçalho UDP
function criaSegmentoUDP($seq_num, $parte) {
    global $porta_origem, $porta_destino;
    $segmento = $seq_num . PHP_EOL . $porta_origem . PHP_EOL . $porta_destino . PHP_EOL . strlen($parte) . PHP_EOL;
    $crc32 = crc32($segmento) + crc32($parte);
    $segmento = $segmento . $crc32 . PHP_EOL . $parte;
    return $segmento;
}

// Coloca os campos de cabeçalho TCP
function criaSegmentoTCP($seq_num, $parte) {
    global $porta_origem, $ip_destino, $porta_destino;
    $ack = ( int ) $seq_num + strlen($parte);
    $tamanho_janela_trans = '0000';
    $tamanho_cabecalho = '00';
    $segmento = $seq_num . PHP_EOL . $porta_origem . PHP_EOL . $ack . PHP_EOL . $porta_destino . PHP_EOL . $tamanho_janela_trans . PHP_EOL . $tamanho_cabecalho . PHP_EOL ;
    $crc32 = crc32($segmento) + crc32($parte);
    $segmento = $segmento . $crc32 . PHP_EOL . $parte;
    return $segmento;
}

function escreveSegmentos ($segmentos){
    $ultimo = array_pop($segmentos);
    $ultimo = $ultimo . PHP_EOL . FIMMSG . PHP_EOL;
    array_push($segmentos, $ultimo);
    foreach ($segmentos as $segmento) {
      $seq_num = strtok($segmento, "\n");
      $seg_name = SEGMENTO.$seq_num;
      $arquivo = fopen($seg_name, "w") or die("Unable to open file!");
      $conteudo = fwrite($arquivo, $segmento);
      fclose($arquivo);
    }
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
        else { // TCP
            array_push($segmentos, criaSegmentoTCP($i, $parte));
        }
    }
    escreveSegmentos($segmentos);
    return $segmentos;
}

function retiraCabecalhoUDP($segmento) {
    $seq_num = strtok($segmento, "\n");
    $porta_origem = strtok("\n");
    $porta_destino = strtok("\n");
    $tamanho = strtok("\n");
    $crc32 = strtok("\n");
    $parte = strtok("");
    $parte = substr($parte, 0, -strlen(FIMMSG)-2);
    return array('seq_num' => $seq_num, 'porta_destino' => $porta_destino, 'porta_origem' => $porta_origem,
                'tamanho' => $tamanho, 'crc32' => $crc32, 'parte' => $parte);
}

function retiraCabecalhoTCP($segmento) {
    $seq_num = strtok($segmento, "\n");
    $porta_origem = strtok("\n");
    $ack = strtok("\n");
    $porta_destino = strtok("\n");
    $tamanho_janela_trans = strtok("\n");
    $tamanho_cabecalho = strtok("\n");
    $crc32 = strtok("\n");
    $parte = strtok("");
    $parte = substr($parte, 0, -strlen(FIMMSG)-2);
    return array('seq_num' => $seq_num, 'porta_destino' => $porta_destino,
                'porta_origem' => $porta_origem, 'ack' => $ack, 'tamanho_cabecalho' => $tamanho_cabecalho, 'tamanho_janela_trans' => $tamanho_janela_trans,'crc32' => $crc32,
                'parte' => $parte);
}

function reconstruirMensagem($nome_arquivo) {
    global $protocolo;
    $arquivo = fopen($nome_arquivo, "w") or die("Unable to open file!");
    $segmento = NULL;
    $i=0;
    $seg_name = SEGMENTO . '0';
    // Enquanto o segmento existir ele continua a execução
    while(file_exists($seg_name)){
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
        $i = $i + 1;
        // concatena a string segmento com numero da sequencia
        $seg_name = SEGMENTO . $i;
    }
    // Le mensagem
    fclose($arquivo);
    return $segmento['parte'];
}

function deletar($tipo) {
    system('for i in `ls | grep -h ^' . $tipo . '[0-9]*$`; do rm $i; done');
}


function chamarCamadaRede() {
  global $protocolo, $porta_origem, $ip_destino, $porta_destino;
    system("node rede_cliente.js $protocolo $porta_origem $ip_destino $porta_destino");
}

function chamarCamadaAplicacao() {
    system("./app");

}
if ($protocolo == UDP) {
    // Se for UDP nao estabelece conexao, ja envia os segmentos
    reconstruirMensagem(MENSAGEM);      // Reconstroi as mensagens
    deletar(SEGMENTO);
    chamarCamadaAplicacao();
    divideMensagem();                   // Divide em segmentos
    deletar(MENSAGEM);
} else { // TCP
    $resposta = reconstruirMensagem(MENSAGEM);
    deletar(SEGMENTO);
    if(strcmp (CONEXAO, substr($resposta, 0, -1)) == 0){
      echo "*** Camada de Transporte **" . PHP_EOL;
      echo "Solicitaçao de conexao recebida!... Enviando confirmacao de conexao..." . PHP_EOL;
      $segmento = criaSegmentoTCP(0, OK) . PHP_EOL . PHP_EOL . FIMMSG . PHP_EOL;
      $seg_name = SEGMENTO . '0';
      // Escreve no segmento para mandar
      $arquivo = fopen($seg_name, "w") or die("Unable to open file!");
      $conteudo = fwrite($arquivo, $segmento);
      fclose($arquivo);
    }else if((strcmp (ACK, substr($resposta, 0, -1)) == 0)){
      $segmento = criaSegmentoTCP(0, OK) . PHP_EOL . PHP_EOL . FIMMSG . PHP_EOL;
      $seg_name = SEGMENTO . '0';
      // Escreve no segmento para mandar
      $arquivo = fopen($seg_name, "w") or die("Unable to open file!");
      $conteudo = fwrite($arquivo, $segmento);
      fclose($arquivo);
      echo "Conexão finalizada com sucesso" . PHP_EOL;
    } else {
      chamarCamadaAplicacao();
      divideMensagem();
      deletar(MENSAGEM);
    }
}
?>
