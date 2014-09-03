class Trade::Receipt
  attr_accessor :transaction_type, :extra_rows, :extra_rows_m, :footer, :footer_m
  def initialize(transaction_type)
    self.transaction_type = transaction_type
    self.extra_rows = []
    self.extra_rows_m = []
    self.footer = ['     轻松一刷 优惠到家    ', '爱刷优惠官网: www.aishua.cn']
    self.footer_m = self.footer
  end
end