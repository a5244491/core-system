$(document).ready ->
  $('.modal [type=submit]').click ->
    $(this).closest('.modal').find('form').submit()
