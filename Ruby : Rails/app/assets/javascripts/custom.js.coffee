$ ->
  $("[data-update-target]").on "ajax:success", (evt, data) ->
    target = $(this).data("update-target")
    $("#" + target).html data
    $("#note_content").val('');