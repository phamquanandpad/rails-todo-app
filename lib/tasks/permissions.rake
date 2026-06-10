namespace :permissions do
  desc "Sync the permission catalogue and grant any new role permissions to existing users"
  task sync: :environment do
    result = Permissions::SyncService.call
    data = result.data
    puts "Permissions synced: #{data[:permissions_created]} created, #{data[:permissions_granted]} granted to existing users."
  end
end
