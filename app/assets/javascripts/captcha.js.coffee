$(document).ready ->
  $('#reset-image-captcha').click ->
    $(this).prev('img').attr('src', '/captcha?action=captcha&i='+ new Date().getTime());