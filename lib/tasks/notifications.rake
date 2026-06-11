namespace :notifications do
  desc "Send a test notification. Usage: bin/rails 'notifications:send[USER_ID,TITLE,BODY,LINK]'"
  task :send, %i[user_id title body link] => :environment do |_t, args|
    user = User.find(args[:user_id])
    result = Notifications::CreateService.call(
      user:  user,
      title: args[:title] || "Hello 👋",
      body:  args[:body],
      link:  args[:link]
    )

    if result.success?
      puts "✅ Sent notification ##{result.data[:notification].id} to user #{user.id} (#{user.email})"
    else
      warn "❌ Failed: #{result.errors.join(', ')}"
    end
  end
end
