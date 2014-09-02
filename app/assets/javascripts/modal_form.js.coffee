$(document).ready ->
  $('form.bootstrap-validate').bootstrapValidator()
  $('.modal [type=submit]').click ->
    $(this).closest('.modal').find('form').submit()

