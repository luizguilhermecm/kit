
$(document).ready(function() {
        console.log("ready");
    $('#new_todo').on('click','.todo',function() {
        console.log("asdf");
        $(this).siblings().each(
            function(){
                if ($(this).find('input').length){
                    $(this).text($(this).find('input').val());
                }
                else {
                    var t = $(this).text();
                    $(this).html($('<input />',{'value' : t}).val(t));
                }
            });
    });
});
function edit_todo_item(index, idx) {
        console.log(idx);
        console.log(index);
        var x=document.getElementById('todo_list_table').rows
        var y=x[index].cells
        //y[0].innerHTML="NEW CONTENT"
        var text = y[0].innerHTML
        y[0].innerHTML = "<form method=\"get\" action=\"\/edit_todo\"><input name=\"idx\" type=\"text\" value=\""+idx+"\" \/><input name=\"text\"type=\"text\" value=\""+text.trim()+"\" \/><input type=\"submit\" value=\""+idx+"\" \/><\/form>"
        console.log(text.trim())
}
