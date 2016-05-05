

$(document).ready(function() {
    key('g+t', function(e) {
        window.location = $("#todo_link").attr("href");
    });
    key('g+l', function(e) {
        window.location = $("#todo_list_link").attr("href");
    });
    key('k+f', function(e) {
        window.location = $("#kit_files_link").attr("href");
    });
    key('k+f', function(e) {
        window.location = $("#kit_files_link").attr("href");
    });
});

function update_flag_do_it(flag_do_it_p, todo_id) {
    var todo_id = todo_id

    if (flag_do_it_p.checked) {
        var flag_do_it = true;
    } else {
        var flag_do_it = false;
    }


   $.ajax({
        url: "/todo/update_todo_flag_do_it/",
        type: "GET",
        data: {
            "flag_do_it": flag_do_it,
            "todo_id": todo_id,
        }
    }).done( function(res) {
    });
}

function update_tag_id(tags, todo_id) {
    for (i = 0; i < tags.options.length; i++) {
        if (tags[i].selected)  {
            console.log("updating " + tags[i].value)
            console.log("of todo_id " + todo_id)
            $.ajax({
                url: "/todo/update_todo_tag/",
                type: "GET",
                data: {
                    "tag_id": tags[i].value,
                    "todo_id": todo_id,
                }
            }).done( function(res) {
            });
        }
    }
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

function update_task_checkbox(checkbox, task_id, attr) {
    console.log("function update_task_checkbox(checkbox, task_id, attr)");

   $.ajax({
        url: "/kit_daily/update_task_checkbox",
        type: "GET",
        data: {
            "task_id": task_id,
            "attr": attr,
            // "value": value,
        }
    }).done( function(res) {
        console.log("done")
    });

    window.location.reload()
}

function update_daily_task_journal_text(task_id) {
    html_id = "text_daily_journal_"+task_id
    text = document.getElementById(html_id).value
    console.log("task_id: " + task_id)
    console.log("text: " + text)
    $.ajax({
        url: "/kit_daily/update_task_text",
        type: "GET",
        data: {
            "text": text,
            "task_id": task_id,
        }
    }).done( function(res) {
    });
}

function update_is_listed(checkbox, tag_id) {
    console.log("function update_is_listed(checkbox, tag_id)");

    if (checkbox.checked) {
        var value = true;
    } else {
        var value = false;
    }

    $.ajax({
        url: "/todo/update_is_listed",
        type: "GET",
        data: {
            "tag_id": tag_id,
            "value": value,
        }
    }).done( function(res) {
    });
}

function update_priority(todo_id, letter) {
    $.ajax({
        url: "/todo/update_priority",
        type: "GET",
        data: {
            "todo_id": todo_id,
            "prio": letter,
        }
    }).done( function(res) {
    });
}
function update_time_tag_id(tags, time_id) {
    for (i = 0; i < tags.options.length; i++) {
        if (tags[i].selected)  {
            console.log("updating " + tags[i].value)
            console.log("of time_id " + time_id)
            $.ajax({
                url: "/kit_time/update_time_tag",
                type: "GET",
                data: {
                    "tag_id": tags[i].value,
                    "time_id": time_id,
                }
            }).done( function(res) {
            });
        }
    }
}

function save_notebook(id) {
    tid = "sandbox_"+id
    text = document.getElementById('sandbox').value

    //title_id = "sandbox_"+id
    //title = document.getElementById(title_id).value
    $.ajax({
        url: "/notebook/update/",
        type: "GET",
        data: {
            "id": id,
            //"title": title,
            "text": text,
        }
    }).done( function(res) {
    });
}
