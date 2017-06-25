'use strict';
let fs = require('fs');
let shell = require('shelljs');

const SEGMENTO = "segmento";
const PACOTE = "pacote";
const TMP = 512;

var montaPacote = function () {
    console.log("REDES - Montando Pacotes...");
	var i = 0;
	var totalPacotes = 0;
	while (true) {
		try {
			let data = fs.readFileSync('./' + SEGMENTO + i, 'utf8');
			i++;
			let num_pacotes = Math.ceil(data.length / TMP);
			for (let j = 0; j < num_pacotes; j++) {
				let pacote = data.substr(j * TMP, TMP);
				if (j == num_pacotes - 1) pacote += '\n|fimSegmento|'
				fs.writeFileSync(PACOTE + totalPacotes, pacote);
                console.log("REDES - " + PACOTE + totalPacotes + " montado.");
				totalPacotes++;
			}
		} catch (err) {
            console.log("REDES - Montagem de pacotes concluida.");
			break;
		}
	}
}

var montaSegmento = function () {
	var i = 0;
	var j = 0;
	var segmento = '';
    console.log("REDES - Montando Segmentos...");
	while (true) {
		try {
			segmento += fs.readFileSync('./' + PACOTE + i, 'utf8');
			if (segmento.indexOf('|fimSegmento|') == segmento.length - 13) {
				segmento = segmento.substr(0, segmento.length - 13);
				fs.writeFileSync(SEGMENTO + j, segmento);
                console.log("REDES - " + SEGMENTO + j + " montado.");
				j++;
				segmento = '';
			}
			i++;
		} catch (err) {
            console.log("REDES - Montagem dos segmentos concluida.");
			break;
		}
	}
}

var destroi = function (fileName) {
    console.log("REDES - Destruindo " + fileName + "s...");
	shell.exec('for i in `ls | grep -h ^' + fileName + '[0-9]*$`; do rm $i; done');
    console.log("REDES - " + fileName + "s destruidos.")
}

exports.montaPacote = montaPacote;
exports.montaSegmento = montaSegmento;
exports.destroi = destroi;