function update_flag_do_it(flag_do_it_p, todo_id) {
    var todo_id = todo_id

    if (flag_do_it_p.checked) {
        var flag_do_it = true;
    } else {
        var flag_do_it = false;
    }


   $.ajax({
        url: "/update_todo_flag_do_it/",
        type: "GET",
        data: {
            "flag_do_it": flag_do_it,
            "todo_id": todo_id,
        }
    }).done( function(res) {
    });
}

function update_tag_id(tag_id, todo_id) {
    var tag_id = tag_id.value;
    var todo_id = todo_id

   $.ajax({
        url: "/update_todo_tag/",
        type: "GET",
        data: {
            "tag_id": tag_id,
            "todo_id": todo_id,
        }
    }).done( function(res) {
    });
}

function update_frase(frase_id, target_table) {
    html_id = "translate_"+frase_id
    translate = document.getElementById(html_id).value

   $.ajax({
        url: "/update_frase",
        type: "GET",
        data: {
            "frase_id": frase_id,
            "translate": translate,
            "target_table": target_table,
        }
    }).done( function(res) {
    });
}

function delete_frase(frase_id, target_table) {
   $.ajax({
        url: "/delete_frase",
        type: "GET",
        data: {
            "frase_id": frase_id,
            "target_table": target_table,
        }
    }).done( function(res) {
    });
}

function update_word(word_id, frase_id, target_table) {
    html_id = "pt_translate_"+frase_id+"_"+word_id
    translate = document.getElementById(html_id).value

   $.ajax({
        url: "/update_word",
        type: "GET",
        data: {
            "word_id": word_id,
            "pt_translate": translate,
            "target_table": target_table,
        }
    }).done( function(res) {
    });
}

function update_word_cognato(flag_is_cognato, word_id, frase_id, target_table) {
    if (flag_is_cognato.checked) {
        var is_cognato = true;
    } else {
        var is_cognato= false;
    }


   $.ajax({
        url: "/update_word_cognato",
        type: "GET",
        data: {
            "word_id": word_id,
            "is_cognato": is_cognato,
            "target_table": target_table,
        }
    }).done( function(res) {
    });
}

