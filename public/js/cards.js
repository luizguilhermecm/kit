var card_atual = 0;

$(document).ready(function() {
    var url = location.href.match(/#card(\d+)$/);

    //carregar_variaveis("banca", "orgao", "alternativa", "prova", "ano", "assunto", "disciplina");

    if (url != null ) {
        //card_atual =+ url[1];
        card_atual = 0;

        alert("if");
        $(".card").css("border-left", "0px solid #C0C0C0");
        $(".card").eq(card_atual).css("border-left", "6px solid #C0C0C0");
        //ir_para();
    } else {
        card_atual = 0;
        $(".card").eq(card_atual).addClass("card_front_main");
        $(".card").eq(card_atual).find(".card_front").addClass("card_front_main");
        $(".card").css("border-left", "0px solid #C0C0C0");
        $(".card").eq(card_atual).css("border-left", "6px solid #C0C0C0");
        //ir_para();
    }

    $( ".to_deck_name" ).autocomplete({
        source: function(request, response) {
            $.ajax({
                url: "auto_deck",
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
            $(".deck_id").val(ui.item.id); },
        response: function(event, ui) {
            if (ui.content.length === 0) {
                $(".empty-message-deck").text("Nada encontrado.");
            }
            else {
                $(".empty-message-deck").empty();
            }
        }
    });

    key('c', function(e) {
        if($(".card").eq(card_atual).find(".card_back").css("display") == "none"){
            //$(".card").eq(card_atual).find(".separator").addClass("separatorx");
            $(".card").eq(card_atual).find(".separator").addClass("fail");
            $(".card").eq(card_atual).find(".revisao_message_separator").text("responde primeiro");
        } else {
            $(".card").eq(card_atual).find(".gabarito").addClass("success");
            $(".card").eq(card_atual).find(".gabarito").text("certo");
        }
    });

    key('j', function(e) {
        //inc_view_count() 
        if (card_atual < $(".card").size()) {
            if($(".card").eq(card_atual).find(".card_back").css("display") == "none"){
                $(".card").eq(card_atual).find(".separator").toggle();
                $(".card").eq(card_atual).find(".card_back").toggle();
            } else {
                if(submit_card() == false) {
                    return;
                }
                //$(".card").eq(card_atual).toggle();

                $(".card").eq(card_atual).removeClass("card_front_main");
                $(".card").eq(card_atual).find(".card_front").removeClass("card_front_main");
                $(".card").eq(card_atual).find(".card_back").toggle();

                card_atual += 1;

                $(".card").eq(card_atual).addClass("card_front_main");
                $(".card").eq(card_atual).find(".card_front").addClass("card_front_main");

                mostrar_card();
            }
        }
        else {
            //proxima_pagina();
        }
    });

    // vai para a questão anterior ou página anterior caso a questão atual seja a primeira
    key('k', function(e) {
        //inc_view_count() 
        if (card_atual > 1) {
            $(".card").eq(card_atual).toggle();
            card_atual -= 1;
            $(".card").eq(card_atual).toggle();
            mostrar_card();
        }
        else {
            //pagina_anterior();
        }
    });

    key('0', function(e) {
        console.log("key(0)");
        next_view_in_days(0); 
    });
    key('1', function(e) {
        console.log("key(1)");
        next_view_in_days(1); 
    });
    key('2', function(e) {
        console.log("key(2)");
        next_view_in_days(2); 
    });
    key('3', function(e) {
        console.log("key(3)");
        next_view_in_days(3); 
    });
    key('4', function(e) {
        console.log("key(4)");
        next_view_in_days(4); 
    });
    key('5', function(e) {
        console.log("key(5)");
        next_view_in_days(5); 
    });
    key('6', function(e) {
        console.log("key(6)");
        next_view_in_days(6); 
    });
    key('7', function(e) {
        console.log("key(7)");
        next_view_in_days(7); 
    });    
    key('8', function(e) {
        console.log("key(8)");
        next_view_in_days(8); 
    });    
    key('9', function(e) {
        console.log("key(9)");
        next_view_in_days(9); 
    });

});


function new_card() {
    console.log("new_card");
    var deck = $(".deck_id").val();
    console.log("deck: " + deck);
    if (deck == "") {
        //$(".new_card_message").text("this deck does not exist");
        $(".new_card_message").removeClass("success").addClass("fail").text("this deck does not exist");
        //$(".new_card_message").addClass("fail").text("this deck does not exist");
        return false;
    }
    $.ajax({
        url: "/new_card/",
        type: "GET",
        data: {
            "front": $(".new_card_question_text").val(),
            "back": $(".new_card_answer_text").val(),
            "deck_id": deck, 
        }
    }).done( function(res) {
        //$(".new_card_message").text("card added");
        $(".new_card_message").removeClass("fail").addClass("success").text("card added");
        ///$(".new_card_message").addClass("success").text("card added");
        $(".deck_id").val("");
    });
}

function new_deck() {
    console.log("new_deck");
    $.ajax({
        url: "/new_deck/",
        type: "GET",
        data: {
            "name": $(".new_deck_name").val(),
        }
    }).done( function(res) {
        $(".new_deck_message").text("deck created");
    });
}

function next_view_in_days(days) {
    console.log("next_view_in_days");

    if($(".card").eq(card_atual).find(".card_back").css("display") == "none"){
        $(".revisao_message").text("revisao");
    }

    $(".card").eq(card_atual).find(".days").val("asdf");
    $(".card").eq(card_atual).find(".n_days").text(days + " dias");
}

function has_days() {
}
function submit_card() {
    var card_id = $(".card_id").eq(card_atual).val();
    var days = $(".card").eq(card_atual).find(".days").val();

    if(days == undefined){
        $(".card").eq(card_atual).find(".n_days").addClass("fail");
        $(".card").eq(card_atual).find(".n_days").text("dias??");
        return false;
    }
    console.log("card_id: " + card_id);
    console.log("days: " + days);
    $.ajax({
        url: "/submit_card/",
        type: "GET",
        data: {
            "days": days,
            "card_id": card_id,
        }
    }).done( function(res) {
        $(".revisao_message").text("revisao");
    });
    return true;
}

function mostrar_card() {
    var aTag = $("a[name='"+ "card" + card_atual +"']");
    //go_card = $(".card").eq(card_atual - 1);
    //go_card.find(".front,.back,.id,.deck_id").toggle();

    var myDiv = $('html,body');
    //var scrollto = myDiv.offset().top + (myDiv.height() / 2);
    if (aTag && aTag.offset()) {
        myDiv.animate({
            //scrollTop: scrollto
            scrollTop: aTag.offset().top - 300
        },
        'fast',
        function() {

            $(".card").css("border-left", "0px solid #C0C0C0");
            $(".card").eq(card_atual).css("border-left", "6px solid #C0C0C0");
        });

    }
}
