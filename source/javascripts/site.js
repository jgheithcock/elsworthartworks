// This is where it all goes :)

function goto(rel_link) {
    if (rel_link && rel_link.length > 0)
        window.location.href = $(rel_link)[0].href;
}
$(document).keydown(function(e) {
    switch(e.which) {
        case 37: // left
            goto($("[rel$='prev']"));
        break;

        // case 38: // up
        //break;

        case 39: // right
            goto($("[rel$='next']"));
        break;

        // case 40: // down
        // break;

        default: return; // exit this handler for other keys
    }
    e.preventDefault(); // prevent the default action (scroll / move caret)
});