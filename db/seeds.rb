# Create the initial admin user if none exists.
# Credentials come from environment variables or defaults.
if User.none?
  email = ENV.fetch("OOPSIE_ADMIN_EMAIL", "admin@example.com")
  password = ENV.fetch("OOPSIE_ADMIN_PASSWORD") { SecureRandom.base58(16) }

  User.create!(email_address: email, password: password, password_confirmation: password)

  puts ""
  puts "=" * 60
  puts "  Oopsie admin user created!"
  puts "  Email:    #{email}"
  puts "  Password: #{password}"
  puts "=" * 60
  puts ""
end
