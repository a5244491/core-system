class Users::SystemUserForm < Reform::Form
  property :name
  property :real_name
  property :role_name
  property :password
  property :password_confirmation, :empty => true

  validates_inclusion_of :role_name, in: [Users::SystemUser::NORMAL_USER, Users::SystemUser::DEPT_MANAGER, Users::SystemUser::SALES_ASSIST]
  validates_uniqueness_of :name
  validates_presence_of :role_name

  def password=(value)
    unless value.blank?
      super(value)
      self.password_confirmation = value
    end
  end
end