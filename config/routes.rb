if ENV['MOUNT_ALL'] == '1' || ENV['MOUNT_ADMIN'] == '1'
  require_relative '../config/routes/admin'
end
if ENV['MOUNT_ALL'] == '1' || ENV['MOUNT_ENGINE'] == '1'
  require_relative '../config/routes/engine'
end
if ENV['MOUNT_ALL'] == '1' || ENV['MOUNT_EXTERNAL'] == '1'
  require_relative '../config/routes/external'
end