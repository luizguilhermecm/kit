
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
