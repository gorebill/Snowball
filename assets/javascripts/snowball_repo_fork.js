$(document).ready(function() {
    $('.contextual').prepend($('#repo_fork_btn').detach());

    $('#fork_from_label').detach().insertAfter($('.contextual').next());
});
