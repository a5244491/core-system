# This file should contain all the record creation needed to seed the database with its default values.
# The data can then be loaded with the rake db:seed (or created alongside the db with db:setup).
#
# Examples:
#
#   cities = City.create([{ name: 'Chicago' }, { name: 'Copenhagen' }])
#   Mayor.create(name: 'Emanuel', city: cities.first)

Users::SystemUser.first_or_create!(name: 'admin', real_name: '系统管理员', password: '123456', password_confirmation: '123456', role_name: Users::SystemUser::ADMIN)
sql = IO.read(File.join(File.dirname(__FILE__), 'card_bin.sql'))
sql.strip.split(';').each do |s|
  ActiveRecord::Base.connection.execute(s)
end