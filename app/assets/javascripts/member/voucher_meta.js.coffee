$(document).ready ->
  $('#voucher_meta_form').bootstrapValidator()
  init_form = ->
    if $('#limit_per_account_on').is(':checked')
      $('#limit_per_account').hide()
    else
      $('#limit_per_account').show()

    if $('#initial_amount_on').is(':checked')
      $('#initial_amount').hide()
    else
      $('#initial_amount').show()

    if $('#applicable_type').val() == '0'
      $('#applicable_target_name').hide()
    else if  $('#applicable_type').val() == '1'
      $('#applicable_target_name').attr('placeholder', '请输入商户名称')
      $('#applicable_target_name').show()
    else if  $('#applicable_type').val() == '2'
      $('#applicable_target_name').attr('placeholder', '请输入商户群组名称')
      $('#applicable_target_name').show()

  init_form()

  $('input[type=checkbox]').click ->
    init_form()

  $('select').change ->
    init_form()