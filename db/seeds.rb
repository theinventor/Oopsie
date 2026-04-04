# Oopsie seed data
# Run with: bin/rails db:seed
#
# Creates an admin user (if none exists) and optionally a demo project
# with sample exceptions so you can see the UI in action immediately.

# --- Admin User ---
if User.none?
  email = ENV.fetch("OOPSIE_ADMIN_EMAIL", "admin@example.com")
  password = ENV.fetch("OOPSIE_ADMIN_PASSWORD") { SecureRandom.base58(16) }

  User.create!(email_address: email, password: password, password_confirmation: password)

  puts ""
  puts "=" * 60
  puts "  Oopsie admin user created!"
  puts "  Email:    #{email}"
  puts "  Password: #{password}"
  puts "  (Save these credentials — the password won't be shown again)"
  puts "=" * 60
  puts ""
end

# --- Demo Project & Sample Data ---
# Skip with OOPSIE_SKIP_DEMO=1
unless ENV["OOPSIE_SKIP_DEMO"] == "1" || Project.exists?(name: "Demo App")
  project = Project.create!(name: "Demo App")

  puts "  Demo project created!"
  puts "  API Key: #{project.api_key}"
  puts ""

  # Sample error group 1: unresolved with multiple occurrences
  group1 = project.error_groups.create!(
    fingerprint: Digest::SHA256.hexdigest("NoMethodError:app/models/user.rb:load"),
    error_class: "NoMethodError",
    message: "undefined method 'downloads' for nil",
    status: :unresolved,
    first_seen_at: 3.days.ago,
    last_seen_at: 10.minutes.ago
  )

  [ 3.days.ago, 2.days.ago, 1.day.ago, 6.hours.ago, 10.minutes.ago ].each do |time|
    group1.occurrences.create!(
      message: "undefined method 'downloads' for nil",
      backtrace: [
        "app/models/user.rb:42:in 'downloads'",
        "app/controllers/users_controller.rb:18:in 'show'",
        "actionpack (8.1.3) lib/action_controller/metal/basic_implicit_render.rb:8:in 'process_action'"
      ],
      first_line: { "file" => "app/models/user.rb", "line" => 42, "method" => "downloads" },
      context: { "request" => { "url" => "/users/1", "method" => "GET" }, "action" => "UsersController#show" },
      server_info: { "hostname" => "web-1", "pid" => 12345, "ruby_version" => "4.0.2", "rails_version" => "8.1.3" },
      environment: "production",
      handled: false,
      occurred_at: time
    )
  end

  # Sample error group 2: resolved
  group2 = project.error_groups.create!(
    fingerprint: Digest::SHA256.hexdigest("ActiveRecord::RecordNotFound:app/controllers/posts_controller.rb:find_post"),
    error_class: "ActiveRecord::RecordNotFound",
    message: "Couldn't find Post with 'id'=999",
    status: :resolved,
    first_seen_at: 5.days.ago,
    last_seen_at: 2.days.ago
  )

  group2.occurrences.create!(
    message: "Couldn't find Post with 'id'=999",
    backtrace: [
      "app/controllers/posts_controller.rb:58:in 'find_post'",
      "activesupport (8.1.3) lib/active_support/callbacks.rb:118:in 'run_callbacks'"
    ],
    first_line: { "file" => "app/controllers/posts_controller.rb", "line" => 58, "method" => "find_post" },
    context: { "request" => { "url" => "/posts/999", "method" => "GET" }, "action" => "PostsController#show" },
    environment: "production",
    handled: false,
    occurred_at: 2.days.ago
  )

  # Sample error group 3: ignored
  group3 = project.error_groups.create!(
    fingerprint: Digest::SHA256.hexdigest("ActionController::RoutingError:middleware:call"),
    error_class: "ActionController::RoutingError",
    message: "No route matches [GET] '/wp-login.php'",
    status: :ignored,
    first_seen_at: 7.days.ago,
    last_seen_at: 1.hour.ago
  )

  [ 7.days.ago, 3.days.ago, 1.hour.ago ].each do |time|
    group3.occurrences.create!(
      message: "No route matches [GET] '/wp-login.php'",
      backtrace: [
        "actionpack (8.1.3) lib/action_dispatch/middleware/debug_exceptions.rb:72:in 'call'"
      ],
      first_line: { "file" => "lib/action_dispatch/middleware/debug_exceptions.rb", "line" => 72, "method" => "call" },
      context: { "request" => { "url" => "/wp-login.php", "method" => "GET" } },
      environment: "production",
      handled: false,
      occurred_at: time
    )
  end

  # Email notification rule for demo
  project.notification_rules.create!(
    channel: :email,
    destination: "dev@example.com",
    enabled: true
  )

  puts "  Created #{ErrorGroup.count} error groups with #{Occurrence.count} occurrences"
  puts "  Created 1 email notification rule (dev@example.com)"
  puts ""
  puts "  Try the API:"
  puts "  curl -X POST http://localhost:3000/api/v1/exceptions \\"
  puts "    -H 'Authorization: Bearer #{project.api_key}' \\"
  puts "    -H 'Content-Type: application/json' \\"
  puts "    -d '{\"error\":{\"class_name\":\"TestError\",\"message\":\"Hello from curl!\",\"backtrace\":[\"app/test.rb:1:in test\"],\"first_line\":{\"file\":\"app/test.rb\",\"line\":1,\"method\":\"test\"}},\"app\":{\"environment\":\"development\"}}'"
  puts ""
end
