module Rule
  extend ActiveSupport::Concern
  STATUS = [ACTIVE = 1, INACTIVE = 2]
  included do
    validates_inclusion_of :status, in: STATUS
    before_validation do
      self.status ||= INACTIVE
      self.valid_from ||= Time.now
      self.valid_till ||= 10.years.from_now
    end
    scope :active, -> { where('valid_from <= ?', Time.now).where('valid_till >= ?', Time.now).where(status: ACTIVE) }
    scope :inactive, -> { where('valid_from > ? or valid_till < ? or status = ?', Time.now, Time.now, INACTIVE) }
  end

  def active?
    !expired? && !disabled?
  end

  def expired?
    !Time.now.between?(self.valid_from, self.valid_till)
  end

  def disabled?
    self.status == INACTIVE
  end

  def may_disable?
    self.status == ACTIVE
  end

  def may_enable?
    self.status == INACTIVE
  end

  def may_edit?
    !active?
  end

  def may_destroy?
    !active?
  end
end