class PurgeSoftDeletedRecordsJob < ApplicationJob
  queue_as :low

  RETENTION = 30.days

  def perform(retention: RETENTION)
    cutoff = retention.ago
    # Users first: archiving a user also archives all of its todos (any deleted_at),
    # so todos owned by a purged user never fall through to the todo pass.
    Maintenance::PurgeUsersService.new(cutoff).call
    Maintenance::PurgeTodosService.new(cutoff).call
  end
end
