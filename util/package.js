function getSection(name) {
    var h2 = document.getElementsByTagName('h2')
    return h2[name]
}

function toggle_visibility(id) {
    var header = getSection(id)
    var elem = header.nextElementSibling
    var block = 'none';
    var type = '+';

    if(elem.style.display == 'none')
    {
        block = 'block';
        type = '-';
    }

    header.innerHTML = id + ' [' + type + ']';
    elem.style.display = block;
}

document.addEventListener('DOMContentLoaded', function() {
    toggle_visibility('contents')
    var d = getSection('contents')
    d.onclick = function() {
        toggle_visibility('contents')
    };
});
