$(document).ready ->
  $('#credit_back_form').bootstrapValidator()
  init_form = ->
    if $('#use_merchant_standard_rate').is(':checked')
      $('#merchant_credit_back_merchant_rate').hide()
    else
      $('#merchant_credit_back_merchant_rate').show()
    if $('#use_default_referer_rate').is(':checked')
      $('#merchant_credit_back_referer_rate').hide()
    else
      $('#merchant_credit_back_referer_rate').show()
  init_form()
  $('input[type=checkbox]').click ->
    init_form()

  $('#bank_discount_form').submit ->
    if $('#use_merchant_standard_rate').is(':checked')
      $('#merchant_credit_back_merchant_rate').val('')
    if $('#use_default_referer_rate').is(':checked')
      $('#merchant_credit_back_referer_rate').val('')