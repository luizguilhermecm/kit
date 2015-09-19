var t_global;
var g_ativado = false;
var vir_ativada = false;
var g_pilha_numero = [];
var p_pressionado = false;

$(document).ready(function() {

    atualizar_cache();

    if (localStorage["playbackRate"] != undefined) {
        player.playbackRate = localStorage["playbackRate"];
        player.defaultPlaybackRate = localStorage["playbackRate"];
    }

    key.filter = function(event) {
        var tagName = (event.target || event.srcElement).tagName;
        key.setScope(/^(INPUT|TEXTAREA|SELECT)$/.test(tagName) ? 'input' : 'other');
        return true;
    }

    key('backspace', function(e) {
        e.preventDefault();
    });

    key('p', function() {
        var video = document.getElementById('player');
        var thecanvas = document.getElementById('thecanvas');
        var img = document.getElementById('thumbnail_img');
        p_pressionado = true;
        window.setTimeout(function() {
            p_pressionado = false;
        }, 1000);
        draw(video, thecanvas, img);
        salvar_imagem();
        restaurar_player(video.currentTime);
    });

    key('o', function() {
        if ($("#select_videos option").size() == 0) {
            $("#openfile_diretorio").click();
        } else if (confirm("Já existem vídeos carregados. Deseja realmente carregar mais vídeos?")) {
            $("#openfile_diretorio").click();
        }
    });

    key('a', function() {
        if ($("#select_videos option").size() == 0) {
            $("#openfile_arquivo").click();
        } else if (confirm("Já existem vídeos carregados. Deseja realmente carregar mais vídeos?")) {
            $("#openfile_arquivo").click();
        }
    });

    key('r', function() {
        t_global = document.getElementById('player').currentTime;
        document.getElementById('player').play();
        window.setTimeout(function() {
            document.getElementById('player').currentTime = t_global;
        }, 400);
    });

    key('g', function() {
        if (g_ativado == true) {
            g_ativado = false;
            var indice = g_pilha_numero.join("");
            g_pilha_numero = [];
            if (indice != "") {
                $("#select_videos").val(parseInt(indice, 10) - 1);
                $("#player")[0].src = get_url(videos_disponiveis[parseInt(indice, 10) - 1]);
                if ($("#player")[0].played) $("#player")[0].play();
            }
        } else {
            g_ativado = true;
            window.setTimeout(function() {
                g_ativado = false;
            }, 3000);
        }
    });

    key(',', function() {
        vir_ativada = true;
        window.setTimeout(function() {
            vir_ativada = false;
        }, 1000);
    });

    key('h', function() {
        $("#help").toggle();
    });

    key('.', function() {
        var video = document.getElementById('player');
        var thecanvas = document.getElementById('thecanvas');
        var img = document.getElementById('thumbnail_img');
        draw(video, thecanvas, img);
        popupWindow = window.open('about:blank', "_blank", "directories=no, status=no, menubar=no, scrollbars=yes, titlebar=0, resizable=no,width=600, height=280,top=200,left=200");
        popupWindow.window.document.write($("#imagem_gerada").html())
    });

    key('t', function() {
        $("#readme").toggle();
    });

    key('up', function() {
        avancar_video(15);
    });

    key('down', function() {
        avancar_video(-15);
    });

    key('left', function() {
        avancar_video(-5);
    });

    key('right', function() {
        avancar_video(5);
    });

    key('shift+1', function() {
        velocidade_video(1);
        legenda("velocidade vídeo: " + $("#player")[0].playbackRate.toFixed(2));
    });

    key('shift+2', function() {
        velocidade_video(2);
        legenda("velocidade vídeo: " + $("#player")[0].playbackRate.toFixed(2));
    });

    key('shift+3', function() {
        velocidade_video(3);
        legenda("velocidade vídeo: " + $("#player")[0].playbackRate.toFixed(2));
    });

    key('shift+4', function() {
        velocidade_video(4);
        legenda("velocidade vídeo: " + $("#player")[0].playbackRate.toFixed(2));
    });

    key('shift+up', function() {
        alterar_velocidade_video(0.5);
        legenda("acelerando vídeo: " + $("#player")[0].playbackRate.toFixed(2));
    });

    key('shift+down', function() {
        alterar_velocidade_video(-0.5);
        legenda("acelerando vídeo: " + $("#player")[0].playbackRate.toFixed(2));
    });

    key('shift+left', function() {
        desacelerar_video();
        legenda("desacelerando vídeo: " + $("#player")[0].playbackRate.toFixed(2));
    });

    key('shift+right', function() {
        acelerar_video();
        legenda("acelerando vídeo: " + $("#player")[0].playbackRate.toFixed(2));
    });

    key('j', function() {
        var nome_video = proximo_video();
        legenda("carregando próximo vídeo: " + nome_video);
    });

    key('k', function() {
        var nome_video = video_anterior();
        legenda("carregando vídeo anterior: " + nome_video);
    });

    key('i', function() {
        var p = $("#player")[0];
        var id_atual = parseInt($("#select_videos").val());
        var video_atual = videos_disponiveis[id_atual].name;
        var duracao_atual = videos_duracoes[id_atual];
        var tempo_restante = videos_duracoes.slice(id_atual).reduce(function(i, j) {
            return i + j;
        }) - p.currentTime;
        var info = "Vídeo atual: " + video_atual + "<br>Velocidade atual: " + p.playbackRate.toFixed(2) + "<br>Executado " + (id_atual + 1) + " de " + videos_disponiveis.length + " vídeos disponíveis<br>Tempo total restante: " + format_tempo(tempo_restante);
        var info_2 = "";
        if (p.playbackRate != 1) {
            info_2 = "<br>Tempo total estimado na velocidade atual: " + format_tempo(tempo_restante / p.playbackRate);
        }
        var info_3 = "<br>Tempo restante do vídeo atual: " + format_tempo((p.duration - p.currentTime) / p.playbackRate);
        legenda(info + info_2 + info_3);
    });

    key('f', function() {
        screenfull.toggle($("#container")[0]);
    });

    for (i = 0; i < 10; i++) {
        (function(numero) {
            key("" + numero, function() {
                if (g_ativado) {
                    g_pilha_numero.push(numero);
                }
             	else if (vir_ativada) {
             		vir_ativada = false;
                    var player = $("#player")[0];
                    $("#player")[0].currentTime = (player.duration / 20) * ((numero + 1 + numero));
/*
    nro pressionado:  0   1   2   3   4     5     6     7     8     9
    quanto somar:     1   2   3   4   5     6      
                    0 1 2 3 4 5 6 7 8 9 10 11 12 13 14 15 16 17 18 19
*/
             	}
                else {
                    var player = $("#player")[0];
                    $("#player")[0].currentTime = (player.duration / 10) * numero;
                }
            });
        })(i);
    }

    key('space', function() {
        iniciar_ou_parar_video();
    });

    $("#player")[0].addEventListener('loadeddata', function() {
        if (carga_inicial) {
        	$(".loading").show();
            tempo_atual = $('#player')[0].duration;
            tempo_total = tempo_total + tempo_atual;

            videos_duracoes.unshift(tempo_atual);


            $("#select_videos option").eq(proximo_indice).append(" --- " + format_tempo(tempo_atual));

            proximo_indice -= 1;

            if (proximo_indice >= 0) {
            	$(".progresso").text((videos_duracoes.length) + "/" + videos_disponiveis.length);
                carregar_tempo(proximo_indice);
            } else {
                carga_inicial = false;
                $(".loading").hide();

                console.log(format_tempo(tempo_total));

                $("#container").show();
                $("#container_selecao_videos").show();
            }

        }
    }, false);
});

var tempo_total = 0;
var carga_inicial = false;
var proximo_indice = -1;
var videos_disponiveis = [];
var videos_duracoes = [];

function restaurar_player(tempo_anterior) {
	var player = $("#player")[0];

    window.setTimeout(function() {
    	console.log(tempo_anterior, player.currentTime)
    	//if (tempo_anterior == player.currentTime) {
			console.log("tentativa 1");
			player.play();
			t_global = tempo_anterior;
			window.setTimeout(function() {
            	document.getElementById('player').currentTime = t_global;
        	}, 400);
		//}
	}, 500);
}

function draw(video, thecanvas, img) {
    thecanvas.height = video.offsetHeight;
    thecanvas.width = video.offsetWidth;
    var context = thecanvas.getContext('2d');
    context.drawImage(video, 0, 0, thecanvas.width, thecanvas.height);
    var dataURL = thecanvas.toDataURL();
    img.setAttribute('src', dataURL);
}

function salvar_imagem() {
    window.location.href = document.getElementById('thumbnail_img').src.replace('image/png', 'image/octet-stream');
}

function iniciar_ou_parar_video() {
    var player = $("#player")[0];
    if (player.paused == true) {
        player.play()
        legenda("play");
    } else {
        player.pause();
        legenda("pause");
    }
}

function format_tempo(tempo_atual) {
    var h = Math.floor(tempo_atual / 3600);
    var m = Math.floor((tempo_atual - (h * 3600)) / 60);
    var s = Math.floor(tempo_atual - (h * 3600) - (m * 60));

    var ret = "";
    if (h > 0) ret = h + "h"
    ret += lpad(m.toString(), 2, "0") + "min"
    ret += lpad(s.toString(), 2, "0") + "s"

    return ret;
}

function lpad(originalstr, length, strToPad) {
    while (originalstr.length < length)
        originalstr = strToPad + originalstr;
    return originalstr;
}

function rpad(originalstr, length, strToPad) {
    while (originalstr.length < length)
        originalstr = originalstr + strToPad;
    return originalstr;
}

var legendas_stack = [];

function legenda(title) {
    $("#legenda_video_container").css("display", "block");
    legendas_stack.push(1);
    $("#legenda_video_texto").html(title);
    setTimeout(
        (function() {
            legendas_stack.pop();
            if (legendas_stack.length == 0) {
                $("#legenda_video_container").css("display", "none");
            }
        }),
        3000
    );
}

document.addEventListener(screenfull.raw.fullscreenchange, function() {
    if (screenfull.isFullscreen) {
        $("#container").css("height", "100%");
        $("#container").css("width", "100%");
    } else {
        $("#container").css("height", "100%");
        $("#container").css("width", "100%");
    }
});

function carregar_videos(files) {
	//var qtde_anterior = videos_disponiveis.length;

    for (var i = 0; i < files.length; i++) {
        var file = files[i];

        var path = file.webkitRelativePath || file.mozFullPath || file.name;

        if (path.indexOf('.AppleDouble') != -1) {
            // Meta-data folder on Apple file systems, skip
            continue;
        }
        var size = file.size || file.fileSize || 4096;
        /*
        	if(size < 4095) {
        	  // Most probably not a real MP3
        	  console.log(path)
        	  continue;
        	}
        */

        if (file.name.indexOf('mp4') != -1 || file.name.indexOf('flv') != -1) {
            videos_disponiveis.push(file);
        } else if (file.name.toLowerCase().indexOf('txt') != -1) {
            var r = new FileReader();
            r.onload = (function(f) {
                return function(e) {
                    var contents = e.target.result;
                    $("#readme").html(contents.replace(/\n/g, "<br>"));
                };
            })(file);
            r.readAsText(file);
        }
    }

    var html = "<select id=select_videos style='width:90%;' onchange='carregar_video(this)'>";
    for (i = 0 ; i < videos_disponiveis.length; i++) {
        html += "<option value='" + i + "'>" + (videos_disponiveis[i].webkitRelativePath || videos_disponiveis[i].name) + "</option>";
    }
    html += "</select>";

    $("#container_selecao_videos").html(html);

	$("#container").hide();
    carga_inicial = true;
    proximo_indice = videos_disponiveis.length - 1;
    carregar_tempo(proximo_indice);
}

function carregar_tempo(indice_atual) {
    var v = $("#player")[0];
    v.src = get_url(videos_disponiveis[indice_atual]);
}

function get_url(f) {
    var url;

    if (window.createObjectURL) {
        url = window.createObjectURL(f)
    } else if (window.createBlobURL) {
        url = window.createBlobURL(f)
    } else if (window.URL && window.URL.createObjectURL) {
        url = window.URL.createObjectURL(f)
    } else if (window.webkitURL && window.webkitURL.createObjectURL) {
        url = window.webkitURL.createObjectURL(f)
    }
    return url;
}

function carregar_video(obj) {
    var f = videos_disponiveis[obj.value];
    var v = $("#player")[0];
    v.src = get_url(f);
}


function velocidade_video(v) {
    var player = $("#player")[0];

    player.playbackRate = v;
    player.defaultPlaybackRate = v;
    localStorage["playbackRate"] = player.playbackRate;
}

function alterar_velocidade_video(velocidade) {
    var player = $("#player")[0];

    player.playbackRate += velocidade;
    player.defaultPlaybackRate += velocidade;
    localStorage["playbackRate"] = player.playbackRate;
}

function acelerar_video() {
    var player = $("#player")[0];

    player.playbackRate += 0.1;
    player.defaultPlaybackRate += 0.1;
    localStorage["playbackRate"] = player.playbackRate;
}

function desacelerar_video() {
    var player = $("#player")[0];

    player.playbackRate -= 0.1;
    player.defaultPlaybackRate -= 0.1;
    localStorage["playbackRate"] = player.playbackRate;
}



function video_anterior() {
    var player = $("#player")[0];
    var index_atual = +$("#select_videos").val();

    if (index_atual == 0) return "não existe vídeo anterior";

    $("#select_videos").val(index_atual - 1);
    player.src = get_url(videos_disponiveis[index_atual - 1]);
    player.play();

    return $("#select_videos option:selected").text();
}

function proximo_video() {
    var player = $("#player")[0];
    var index_atual = +$("#select_videos").val();

    if (index_atual == videos_disponiveis.length - 1) return "não existe próximo vídeo";

    $("#select_videos").val(index_atual + 1);
    player.src = get_url(videos_disponiveis[index_atual + 1]);
    player.play();

    return $("#select_videos option:selected").text();
}

function avancar_video(time) {
    $("#player")[0].currentTime += time;
}

if (annyang) {
    var commands = {
        'adiantar 1': function() {
            avancar_video(1);
        },
        'adiantar 2': function() {
            avancar_video(2);
        },
        'adiantar 3': function() {
            avancar_video(3);
        },
        'adiantar 4': function() {
            avancar_video(4);
        },
        'adiantar 5': function() {
            avancar_video(5);
        },
        'adiantar 10': function() {
            avancar_video(10);
        },
        'retroceder 1': function() {
            avancar_video(-1);
        },
        'retroceder 2': function() {
            avancar_video(-2);
        },
        'retroceder 3': function() {
            avancar_video(-3);
        },
        'retroceder 4': function() {
            avancar_video(-4);
        },
        'retroceder 5': function() {
            avancar_video(-5);
        },
        'retroceder 10': function() {
            avancar_video(-10);
        },
        'próximo': function() {
            proximo_video();
        },
        'reproduzir': function() {
            legenda("comando de voz reproduzir");
            $("#player")[0].play();
        },
        'pausar': function() {
            legenda("comando de voz pausar");
            $("#player")[0].pause();
        }
    };

    annyang.addCallback('resultNoMatch', function() {
        legenda("comando de voz desconhecido");
    });
    annyang.setLanguage('pt-BR');
    annyang.init(commands);
    annyang.start();
}

function atualizar_cache() {
    if (window.applicationCache) {
        window.applicationCache.addEventListener('updateready', function(e) {
            if (window.applicationCache.status == window.applicationCache.UPDATEREADY) {
                window.applicationCache.swapCache();
                if (confirm('Existe uma nova versão disponível. Deseja atualizar agora?')) {
                    window.location.reload();
                }
            } else {}
        }, false);
    }
}


window.onbeforeunload = function (e) {
	if (p_pressionado || videos_disponiveis.length == 0) return ;

    e = e || window.event;

    // For IE and Firefox prior to version 4
    if (e) {
        e.returnValue = 'Sure?';
    }

    // For Safari
    return 'Sure?';
};
