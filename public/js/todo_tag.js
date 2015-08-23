
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
