$(document).ready ->
  $('.modal_submit').click ->
    $(this).parents().find('form').submit()
