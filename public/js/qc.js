var questao_atual = 0;
var hrs = [];

$(window).scroll(function (event) {
    /*
       for(i = 1; i < hrs.length - 1; i++) {
       tamanho = hrs[i] - hrs[i-1];
       if (scrollY < hrs[i] && (hrs[i] - scrollY)/tamanho > 0.2 ) {
       if (i-1 >= 0) {
        //console.log('scroll questao: ', questao_atual, tamanho, i-1, (hrs[i] - scrollY)/tamanho)
        ir_para_sem_scroll(i-1);
        }
        break;
        }

        }
        */
});

//executado qndo pagina terminar
$(document).ready(function() {

    $(".spark").each(function(){
        $(this).sparkline( eval($(this).attr("val")), {type: 'line', width: '100px', height: '25px'});
    });
    var url = location.href.match(/#questao(\d+)$/);

    carregar_variaveis("banca", "orgao", "alternativa", "prova", "ano", "assunto", "disciplina");

    $("blockquote").toggle();

    if (url != null ) {
        questao_atual = + url[1];

        $(".questao").css("border-left", "0px solid #C0C0C0");
        $(".questao").eq(questao_atual - 1).css("border-left", "6px solid #C0C0C0");
        //ir_para();
    } else {
        questao_atual = 1;

        $(".questao").css("border-left", "0px solid #C0C0C0");
        $(".questao").eq(questao_atual - 1).css("border-left", "6px solid #C0C0C0");
        //ir_para();
    }
    $( ".nsdk_auto" ).autocomplete({
        source: "/buscar_nsdk/",
        minLength: 2,
        select: function( event, ui ) {
            $(".assunto_id").val(ui.item.assunto);
            $(".disciplina_id").val(ui.item.disciplina);
        },
        response: function(event, ui) {
            if (ui.content.length === 0) {
                $(".empty-message-assunto").text("Nada encontrado.");
            }
            else {
                $(".empty-message-assunto").empty();
            }
        }
    });

    $( ".disciplina_auto" ).autocomplete({
        source: "buscar_disciplina/",
        minLength: 2,
        select: function( event, ui ) {
            $(".disciplina_id").eq(questao_atual-1).val(ui.item.disciplina);
        },
        response: function(event, ui) {
            if (ui.content.length === 0) {
                $(".empty-message-assunto").eq(questao_atual-1).text("Nada encontrado.");
            }
            else {
                $(".empty-message-assunto").eq(questao_atual-1).empty();
            }
        }
    });

    $( ".assunto_auto_b" ).autocomplete({
        source: function(request, response) {
            $.ajax({
                url: "buscar_assunto/",
                dataType: "json",
                data: {
                    term : request.term,
                    disciplina_id: $(".disciplina").eq(questao_atual-1).text()
                },
                success: function(data) {
                    response(data);
                }
            });
        },
        select: function( event, ui ) {
            $(".assunto_id_b").eq(questao_atual-1).val(ui.item.assunto);
        },
        response: function(event, ui) {
            if (ui.content.length === 0) {
                $(".empty-message-assunto").eq(questao_atual-1).text("Nada encontrado.");
            }
            else {
                $(".empty-message-assunto").eq(questao_atual-1).empty();
            }
        }
    });


    $( ".assunto_auto" ).autocomplete({
        source: function(request, response) {
            $.ajax({
                url: "buscar_assunto/",
                dataType: "json",
                data: {
                    term : request.term,
                    disciplina_id: $(".disciplina").eq(questao_atual-1).text()
                },
                success: function(data) {
                    response(data);
                }
            });
        },
        select: function( event, ui ) {
            $(".assunto_id").eq(questao_atual-1).val(ui.item.assunto);
        },
        response: function(event, ui) {
            if (ui.content.length === 0) {
                $(".empty-message-assunto").eq(questao_atual-1).text("Nada encontrado.");
            }
            else {
                $(".empty-message-assunto").eq(questao_atual-1).empty();
            }
        }
    });

    $( ".prova_auto" ).autocomplete({
        source: "buscar_prova/",
        minLength: 2,
        select: function( event, ui ) {
            limpar_busca();
            $("#banca").val(ui.item.banca);
            $("#ano").val(ui.item.ano);
            $("#orgao").val(ui.item.orgao);
            $("#prova").val(ui.item.prova);
            $("form").submit();
        },
        response: function(event, ui) {
            if (ui.content.length === 0) {
                $(".empty-message-prova").text("Nada encontrado.");
            }
            else {
                $(".empty-message-prova").empty();
            }
        }
    });

    $( ".word_auto" ).autocomplete({
        source: function(request, response) {
            $.ajax({
                url: "buscar_word/",
                dataType: "json",
                data: {
                    term : request.term,
                },
                success: function(data) {
                    response(data);
                }
            });
        },
        select: function( event, ui ) {
            $(".word_id").eq(questao_atual-1).val(ui.item.word);
        },
        response: function(event, ui) {
            if (ui.content.length === 0) {
                $(".empty-message-assunto").eq(questao_atual-1).text("Nada encontrado.");
            }
            else {
                $(".empty-message-assunto").eq(questao_atual-1).empty();
            }
        }
    });

    $(".q_word_key").click(function(){
        $(this).hide();
        valor_atual = $(this).text();

        $(".q_candidate_words").eq(questao_atual-1).append("<mark class='q_candidate_word'>" + valor_atual + "</mark> ");

        $(".q_word").each(function() {
            if(valor_atual == $(this).text()) {
                $(this).hide();
            }
        });

        $.ajax({
            url: "/insert_key_word/",
            type: "GET",
            data: {
                "word": $(this).text(),
            }
        })
    });


    $(".q_word").click(function(){
        $(this).hide();
        valor_atual = $(this).text();

        $(".q_word_key").each(function() {
            if(valor_atual == $(this).text()) {
                $(this).hide();
            }
        });

        $.ajax({
            url: "/insert_stop_word/",
            type: "GET",
            data: {
                "word": $(this).text(),
            }
        })
    });

    $(".q_candidate_word").click(function(){

        var id_questao = $(".id_questao").eq(questao_atual-1).val();
        $(this).hide();
        console.log(1)
        $.ajax({
            url: "/insert_hot_key_word/",
            type: "GET",
            data: {
                "id": id_questao,
                "word": $(this).text(),
            }
        })
    });




    hrs = $('hr').map(function() { 
        return $(this)[0].offsetTop;
    });


    // ATALHOS

    // exibe apenas a alternativa correta de todas as questoes da tela
    key('shift+g', function(e) {
        $(".questao").each(function() {
            $(this).find(".alternativa_a,.alternativa_b,.alternativa_c,.alternativa_d,.alternativa_e,.dados_cabecalho").toggle();
            $(this).find(".alternativa_" + $(this).find(".resposta").html()).toggle();
            $(this).find(".resposta_cespe").toggle();
        })

    });

    key('shift+w', function(e) {
        $(".questao").each(function() {
            $(this).find(".word_class").toggle();
        })
    });

    key('1', function() {
        questao_atual = 1;
        ir_para();
    });

    key('h', function() {
        $("#help").toggle();
    });

    // mostra/esconde comentário
    key('.', function(e) {
        $(".comentarios").eq(questao_atual-1).toggle();
    });

    // exibe/esconde sumário
    key('s', function(e) {
        $("#sumario").toggle();
        ir_para_name("sumario");
    });

    key('f', function() {
        ir_para()
        $(".bad_flag_button").eq(questao_atual-1).blur()
    });


    // exibe apenas a alternativa correta da questão atual
    key('g', function(e) {
        jQuestao = $(".questao").eq(questao_atual - 1);
        jQuestao.find(".alternativa_a,.alternativa_b,.alternativa_c,.alternativa_d,.alternativa_e").toggle();
        jQuestao.find(".alternativa_" + jQuestao.find(".resposta").html()).toggle();
        jQuestao.find(".resposta_cespe").toggle();
    });

    // desativa backspace
    key('backspace', function(e) {
        e.preventDefault();
    });

    key('shift+n', function(e) {
        e.preventDefault();
        $(".organizar_nsdk").eq(questao_atual-1).show();
        $(".nsdk_auto").eq(questao_atual-1).focus();
    });


    key('shift+o', function(e) {
        e.preventDefault();
        $(".organizar_assunto").eq(questao_atual-1).show();
        $(".assunto_auto").eq(questao_atual-1).focus();
    });

    key('shift+p', function(e) {
        e.preventDefault();
        $(".organizar_assunto_b").eq(questao_atual-1).show();
        $(".assunto_auto_b").eq(questao_atual-1).focus();
    });



    // exibe o campo de categorizar a questão
    key('o', function(e) {
        e.preventDefault();
        $(".organizar_disciplina").eq(questao_atual-1).show();
        $(".disciplina_auto").eq(questao_atual-1).focus();
    });

    key('w', function(e) {
        e.preventDefault();
        $(".hot_key").eq(questao_atual-1).show();
        $(".word_auto").eq(questao_atual-1).focus();
    });

    key('t', function(e) {
        e.preventDefault();
        $(".comentario_snk").eq(questao_atual-1).show();
        $(".comentario_value").eq(questao_atual-1).focus();
    });

    key('shift+f', function(e) {
        var id_questao = $(".id_questao").eq(questao_atual-1).val();
        acertou = false;
        alternativa = 'F'
        $.ajax({
            url: "/salvar_resposta/",
            type: "GET",
            data: {
                "id": id_questao,
                "acertou": acertou,
                "resposta": alternativa.toUpperCase()
            }
        }).done( function(res) {
            $(".gabarito_z").eq(questao_atual-1).addClass("errou").text(" => F  ");
        });
    });

    key('shift+y', function(e) {
        var id_questao = $(".id_questao").eq(questao_atual-1).val();
        acertou = false;
        alternativa = 'Y'
        $.ajax({
            url: "/salvar_resposta/",
            type: "GET",
            data: {
                "id": id_questao,
                "acertou": acertou,
                "resposta": alternativa.toUpperCase()
            }
        }).done( function(res) {
            $(".gabarito_z").eq(questao_atual-1).addClass("errou").text(" => Y ");
        });
    });

    key('shift+m', function(e) {
        var id_questao = $(".id_questao").eq(questao_atual-1).val();
        acertou = false;
        alternativa = 'M'
        $.ajax({
            url: "/salvar_resposta/",
            type: "GET",
            data: {
                "id": id_questao,
                "acertou": acertou,
                "resposta": alternativa.toUpperCase()
            }
        }).done( function(res) {

            $(".gabarito_z").eq(questao_atual-1).addClass("errou").text(" => M  ");
        });
    });


    key('shift+z', function(e) {

        var id_questao = $(".id_questao").eq(questao_atual-1).val();
        acertou = false;
        alternativa = 'Z'
        $.ajax({
            url: "/salvar_resposta/",
            type: "GET",
            data: {
                "id": id_questao,
                "acertou": acertou,
                "resposta": alternativa.toUpperCase()
            }
        }).done( function(res) {

            $(".gabarito_z").eq(questao_atual-1).addClass("errou").text(" => Z  ");
        });
    });


    // vai para a próxima página
    key('n', function(e) {
        $("#botao_proximo").click();
    });

    key('f', function(e) {
        $(".bad_flag_button").eq(questao_atual-1).focus();
    });


    // vai para a página anterior
    key('p', function(e) {
        $("#botao_anterior").click();
    });

    // vai para a próxima questão ou próxima página caso a questão atual seja a última
    key('j', function(e) {
        inc_view_count() 
        if (questao_atual < $(".questao").size()) {
            questao_atual += 1;
            ir_para();

        }
        else {
            proxima_pagina();
        }
    });

    // vai para a questão anterior ou página anterior caso a questão atual seja a primeira
    key('k', function(e) {
        inc_view_count() 
        if (questao_atual > 1) {
            questao_atual -= 1;
            ir_para();
        }
        else {
            pagina_anterior();
        }
    });

    // coloca o foco no campo de busca
    key('shift+/', function(e) {
        e.preventDefault();
        $("#prova_auto").focus();
    });

    // coloca o foco no campo de busca
    key('/', function(e) {
        e.preventDefault();
        $("#alternativa").focus();
    });

    var opcoes = ['a', 'b', 'c', 'd', 'e'];

    for (i in opcoes) {
        (function(alternativa) {
            key(alternativa, function(e) {
                var id_questao = $(".id_questao").eq(questao_atual-1).val();
                var resposta = $(".resposta").eq(questao_atual-1).text().toUpperCase();
                var jQuestao = $(".mensagem").eq(questao_atual-1);
                var acertou;

                if ($(".questao").eq(questao_atual - 1).find(".resposta_cespe").size() > 0 && /[aAbBdD]/.test(alternativa)) {
                    alert("apenas certou ou errado");
                    return;
                }

                jQuestao.removeClass("acertou").removeClass("errou");
                if (resposta == alternativa.toUpperCase()) {
                    acertou = true;
                    jQuestao.addClass("acertou").html("Letra " + resposta + ". Resposta certa.");

                    $(".questao").css("border-left", "0px solid #329932");
                    $(".questao").eq(questao_atual - 1).css("border-left", "6px solid #329932");

                    var jQtdeAcertos = $('.qtde_acertos').eq(questao_atual-1);
                    jQtdeAcertos.html( parseInt(jQtdeAcertos.html(), 10) + 1);

                }
                else {
                    acertou = false;
                    jQuestao.addClass("errou").html("Letra " + alternativa.toUpperCase() + ". Resposta errada.");

                    $(".questao").css("border-left", "0px solid #FF3333");
                    $(".questao").eq(questao_atual - 1).css("border-left", "6px solid #FF3333");

                    var jQtdeErros = $('.qtde_erros').eq(questao_atual-1);
                    jQtdeErros.html( parseInt(jQtdeErros.html(), 10) + 1);
                }
                jQuestao.show();

                $.ajax({
                    url: "/salvar_resposta/",
                    type: "GET",
                    data: {
                        "id": id_questao,
                        "acertou": acertou,
                        "resposta": alternativa.toUpperCase()
                    }
                }).done( function(res) {

                });
            });
        })(opcoes[i]);

        (function(alternativa) {
            key('shift+'+alternativa, function(e) {
                jQuestao = $(".questao").eq(questao_atual - 1);
                jAlternativa = jQuestao.find(".alternativa_" + alternativa);
                if (jAlternativa.hasClass("taxado")) {
                    jAlternativa.removeClass("taxado");
                }
                else {
                    jAlternativa.addClass("taxado");
                }
            });
        })(opcoes[i]);
    }
});

function ir_para_sem_scroll(indice) {
    questao_atual = indice + 1;
    $(".questao").css("border-left", "0px solid #C0C0C0")
    $(".questao").eq(questao_atual - 1).css("border-left", "6px solid #C0C0C0")
}

function ir_para_name(name) {
    var aTag = $("a[name='"+ name +"']");

    if (aTag && aTag.offset()) {
        $('html,body').animate({
            scrollTop: aTag.offset().top
        },
        'slow');
    }	
}

function ir_para() {
    var aTag = $("a[name='"+ "questao" + questao_atual +"']");

    if (aTag && aTag.offset()) {
        $('html,body').animate({
            scrollTop: aTag.offset().top
        },
        'slow',
        function() {
            $(".questao").css("border-left", "0px solid #C0C0C0");
            $(".questao").eq(questao_atual - 1).css("border-left", "6px solid #C0C0C0");
        });
    }
}

function getParameterByName(name) {
    name = name.replace(/[\[]/, "\\[").replace(/[\]]/, "\\]");
        var regex = new RegExp("[\\?&]" + name + "=([^&#]*)"),
        results = regex.exec(location.search);
        return results === null ? "" : decodeURIComponent(results[1].replace(/\+/g, " "));
}

function carregar_variaveis() {
    for(i = 0; i < arguments.length; i++) {
        $("#" + arguments[i]).val(getParameterByName(arguments[i]));
    }
}

function proxima_pagina() {
    if ($("#pagina_atual").val() == $("#qtde_paginas").val()) return;

    $("#primeira_pagina").val("");
    $("#pagina_atual").val(+$("#pagina_atual").val() + 1);
    $("#form_busca").submit();
}

function pagina_anterior() {
    if ($("#pagina_atual").val() == "1") return;

    $("#primeira_pagina").val("");
    $("#pagina_atual").val($("#pagina_atual").val() - 1);	
    $("#form_busca").submit();
}

function organizar_nsdk() {
    var id_questao = $(".id_questao").eq(questao_atual-1).val();
    var assunto = $(".assunto_id").eq(questao_atual-1).val();
    var disciplina = $(".disciplina_id").eq(questao_atual-1).val();

    $(".assunto").eq(questao_atual-1).html(assunto);
    $(".disciplina").eq(questao_atual-1).html(disciplina);

    $(".nsdk_auto").val("");
    $(".organizar_nsdk").hide();

    $.ajax({
        url: "/organizar_nsdk/",
        type: "GET",
        data: {
            "id": id_questao,
            "assunto": assunto,
            "disciplina": disciplina
        }
    });

    $(".organizar_nsdk_button").eq(questao_atual-1).blur()
    $(".organizar_nsdk").eq(questao_atual-1).hide();
}


function organizar_assunto() {
    var id_questao = $(".id_questao").eq(questao_atual-1).val();
    var assunto = $(".assunto_id").eq(questao_atual-1).val();
    var disciplina = $(".disciplina_id").eq(questao_atual-1).val();

    $(".assunto").eq(questao_atual-1).html(assunto);
    //	$(".disciplina").eq(questao_atual-1).html(disciplina);

    $(".assunto_disciplina").val("");
    $(".organizar_assunto").hide();

    $.ajax({
        url: "/organizar_assunto/",
        type: "GET",
        data: {
            "id": id_questao,
            "assunto": assunto,
            "disciplina": disciplina
        }
    });

    $(".organizar_assunto_button").eq(questao_atual-1).blur()
    $(".organizar_assunto").eq(questao_atual-1).hide();
}


function organizar_assunto_b() {
    var id_questao = $(".id_questao").eq(questao_atual-1).val();
    var assunto = $(".assunto_id_b").eq(questao_atual-1).val();
    var disciplina = $(".disciplina_id").eq(questao_atual-1).val();

    $(".assunto_b").eq(questao_atual-1).html(assunto);
    //	$(".disciplina").eq(questao_atual-1).html(disciplina);

    $(".assunto_disciplina").val("");
    $(".organizar_assunto_b").hide();

    $.ajax({
        url: "/organizar_assunto_b/",
        type: "GET",
        data: {
            "id": id_questao,
            "assunto_b": assunto,
            "disciplina": disciplina
        }
    });

    $(".organizar_assunto_button_b").eq(questao_atual-1).blur()
    $(".organizar_assunto_b").eq(questao_atual-1).hide();
}


function organizar_disciplina() {
    var id_questao = $(".id_questao").eq(questao_atual-1).val();
    //	var assunto = $(".assunto_id").eq(questao_atual-1).val();
    var disciplina = $(".disciplina_id").eq(questao_atual-1).val();

    //	$(".assunto").eq(questao_atual-1).html(assunto);
    $(".disciplina").eq(questao_atual-1).html(disciplina);

    $(".assunto_disciplina").val("");
    $(".organizar_disciplina").hide();

    $.ajax({
        url: "/organizar_disciplina/",
        type: "GET",
        data: {
            "id": id_questao,
            //			"assunto": assunto,
            "disciplina": disciplina
        }
    });

    $(".organizar_disciplina_button").eq(questao_atual-1).blur()
    $(".organizar_disciplina").eq(questao_atual-1).hide();
}

function limpar_busca() {
    $("form").find("select").val("---");
    $("form input[type=text]").val("");
}

function snk_word() {

    var word = $(".word_auto").eq(questao_atual-1).val()
    var url = "/?filtro_and_lower_1="+word;

    window.open(url, '_blank');
    win.focus();
    //window.location="/?alternativa_gabarito_a1="+word;
    /*
    // adiciona hot key
    var id_questao = $(".id_questao").eq(questao_atual-1).val();
    $.ajax({
url: "/snk_word/",
type: "GET",
data: {
"id": id_questao,
"hot_keys": $(".word_auto").eq(questao_atual-1).val()
}
}).done( function(res) {
$(".hot_key_message").eq(questao_atual-1).text(":D");
});
$(".hot_key_button").eq(questao_atual-1).blur()

$(".hot_key").eq(questao_atual-1).hide();
*/
}
function snk_comentario() {
    var id_questao = $(".id_questao").eq(questao_atual-1).val();
    $.ajax({
        url: "/snk_comentario/",
        type: "GET",
        data: {
            "id": id_questao,
            "snk_comment": $(".comentario_value").eq(questao_atual-1).val()
        }
    }).done( function(res) {
        $(".comentario_message").eq(questao_atual-1).text(":X");
    });
    $(".comment_button").eq(questao_atual-1).blur()
    $(".comentario_snk").eq(questao_atual-1).hide();
}
function check_flag_button() {
    var id_questao = $(".id_questao").eq(questao_atual-1).val();
    $.ajax({
        url: "/set_check_flag/",
        type: "GET",
        data: {
            "id": id_questao,
        }
    }).done( function(res) {
        $(".check_flag_comment").eq(questao_atual-1).text(" => flag_check was setted");
    });
    $(".check_flag_button").eq(questao_atual-1).blur()

}

function bad_flag_button() {
    var id_questao = $(".id_questao").eq(questao_atual-1).val();
    $.ajax({
        url: "/set_bad_flag/",
        type: "GET",
        data: {
            "id": id_questao,
        }
    }).done( function(res) {
        $(".bad_flag_comment").eq(questao_atual-1).text(" => flag_bad was setted");
    });
    $(".bad_flag_button").eq(questao_atual-1).blur()

}

function cancel_button() {
    $(".cancel_button").eq(questao_atual-1).blur()
}
function inc_view_count() {
    var id_questao = $(".id_questao").eq(questao_atual-1).val();
    $.ajax({
        url: "/view_count/",
        type: "GET",
        data: {
            "id": id_questao,
        }
    })
}
