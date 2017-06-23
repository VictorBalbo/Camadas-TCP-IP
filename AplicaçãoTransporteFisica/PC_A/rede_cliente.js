fs = require('fs');
shell = require('shelljs');

const SEGMENTO = "segmento";
const PACOTE = "pacote";
const TMP = 512;

// Ags
// 0 - node (ignorar)
// 1 - rede.cliente.js (ignorar)
// 2 - protocolo
// 3 - porta de origem
// 4 - ip destino
// 5 - porta destino
if (process.argv.length < 6) {
	console.log("*** Camada de Transporte **");
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

destroi(SEGMENTO);
montaSegmento();
destroi(PACOTE);
//montaPacote();
// //Chama camada de rede
// shell.exec('./fis_client.sh ' + protocolo + ' ' + porta_origem + ' ' + ip_destino + ' ' + porta_destino);

function destroi(fileName) {
	shell.exec('for i in `ls | grep -h ^' + fileName + '[0-9]*$`; do rm $i; done');
}


function montaPacote() {
	var i = 0;
	var totalPacotes = 0;
	while (true) {
		try {
			let data = fs.readFileSync('./' + SEGMENTO + i, 'utf8');
			i++;
			num_pacotes = Math.ceil(data.length / TMP);
			for (j = 0; j < num_pacotes; j++) {
				pacote = data.substr(j * TMP, TMP);
				if (j == num_pacotes - 1) pacote += '\n|fimSegmento|'
				fs.writeFileSync(PACOTE + totalPacotes, pacote);
				totalPacotes++;
			}
		} catch (err) {
			break;
		}
	}
}

function montaSegmento() {
	var i = 0;
	var j = 0;
	var segmento = '';
	while (true) {
		try {
			segmento += fs.readFileSync('./' + PACOTE + i, 'utf8');
			console.log(segmento.indexOf('|fimSegmento|'));
			if (segmento.indexOf('|fimSegmento|') == segmento.length - 13) {
				segmento = segmento.substr(0, segmento.length - 13);
				fs.writeFileSync(SEGMENTO + j, segmento);
				j++;
				segmento = '';
			}
			i++;
		} catch (err) {
			break;
		}
	}
}

// function crc32(str) {
// 	var c;
// 	var crcTable = [];
// 	for (var n = 0; n < 256; n++) {
// 		c = n;
// 		for (var k = 0; k < 8; k++) {
// 			c = ((c & 1) ? (0xEDB88320 ^ (c >>> 1)) : (c >>> 1));
// 		}
// 		crcTable[n] = c;
// 	}
// 	return crcTable;
// }