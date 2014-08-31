module Bank::CardBinsHelper
  cattr_accessor :organization_type_hash, :credit_type_hash
  self.organization_type_hash = {
      1 => '银联卡',
      0 => '其他卡'
  }

  self.credit_type_hash = {
      1 => '借记卡',
      2 => '信用卡',
      3 => '其他',
      4 => '其他',
      5 => '其他'
  }
end
