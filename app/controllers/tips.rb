#encoding=utf-8
class Tips
  UPDATE_SUCCESS = '更新成功'
  UPDATE_ERROR = '更新失败'

  CREATE_SUCCESS = '添加成功'
  CREATE_ERROR = '添加失败'

  DELETE_SUCCESS = '删除成功'
  DELETE_ERROR = '删除失败'

  RECORD_NOT_EXIST = '记录不存在'

  MERCHANT_CAN_NOT_SUBMIT_AUDIT = '当前商户状态无法提交审核'
  MERCHANT_CAN_NOT_APPROVE_AUDIT = '当前商户状态无法通过审核'
  MERCHANT_CAN_NOT_REJECT_AUDIT = '当前商户状态无法拒绝审核'
  MERCHANT_CAN_NOT_ACTIVE = '当前商户状态无法变更为生效'
  MERCHANT_CAN_NOT_INACTIVE = '当前商户状态无法变更为失效'
  MERCHANT_CAN_NOT_ENTERING = '当前商户状态无法取消审核'
  MERCHANT_CAN_NOT_DELETE = '当前商户无法删除'

  PAYMENT_PLAN_CAN_NOT_EDIT = '当前支付计划无法编辑'
  PAYMENT_PLAN_VALID_SUCCESS = '当前支付计划生效成功'
  PAYMENT_PLAN_CAN_NOT_VALID = "支付计划无法生效，请先失效当前生效的 '%s' 支付计划"
  PAYMENT_PLAN_INVALID_SUCCESS = '当前支付计划失效成功'
  PAYMENT_PLAN_INVALID_ERROR = '当前支付计划失效失败'

  CREDIT_CASHING_CAN_NOT_REJECT = '当前积分兑现申请不能被拒绝'
  CREDIT_CASHING_REJECT_ERROR = '当前积分兑现申请拒绝失败'
  CREDIT_CASHING_REJECT_SUCCESS = '当前积分兑现申请拒绝成功'

  CREDIT_CASHING_CAN_NOT_APPROVE = '当前积分兑现申请不能被标记为处理结束'
  CREDIT_CASHING_APPROVE_ERROR = '积分兑现申请处理失败'
  CREDIT_CASHING_APPROVE_SUCCESS = '当前积分兑现申请处理成功'

  BANK_NAME_NOT_EXIST = '银行不存在'

  ILLEGAL_OPERATION = '错误的操作'
  OPERATION_ERROR = '操作失败'

  LOGIN_ERROR = '登录失败，用户名或者密码错误'
  PASSWORD_ERROR = '密码错误'
  ACCESS_ERROR = '您无权进行该操作'
  SEQUENCE_ERROR = '请检查上传的序列文件'
end