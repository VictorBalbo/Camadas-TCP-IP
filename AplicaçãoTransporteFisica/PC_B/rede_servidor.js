'use strict';
let rede = require('./rede.js');
let shell = require('shelljs');

const SEGMENTO = "segmento";
const PACOTE = "pacote";

// Ags
// 0 - node (ignorar)
// 1 - rede.cliente.js (ignorar)
// 2 - protocolo
// 3 - porta de origem
// 4 - ip destino
// 5 - porta destino
if (process.argv.length < 6) {
	console.log("*** Camada de Redes **");
	console.log("Parâmetros insuficientes!");
	console.log("node rede_cliente.js protocolo porta_origm(fis) ip_destino porta_destino(fis)");
	process.exit()
}

var protocolo = process.argv[2];
var ip_origem = shell.exec("ip route show default | grep 'src' | awk '{print $9}' | head -1", { silent: true }).stdout.replace(/\n/, "");
var porta_origem = process.argv[3];
var ip_destino = process.argv[4];
var porta_destino = process.argv[5];
var pacotes = {};

rede.montaSegmento();
rede.destroi(PACOTE);
console.log("REDES - Chama camada fisica e espera resposta...");
shell.exec('php trans_sr.php ' + protocolo + ' ' + porta_origem + ' ' + ip_destino + ' ' + porta_destino);
rede.montaPacote();
rede.destroi(SEGMENTO);

