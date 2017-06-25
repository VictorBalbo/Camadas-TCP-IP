'use strict';
let rede = require('./rede.js');

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


rede.montaPacote();
rede.destroi(SEGMENTO);