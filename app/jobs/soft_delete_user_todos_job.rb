class SoftDeleteUserTodosJob < ApplicationJob
  queue_as :default

  # Discard the job if the user record is gone (hard-deleted or never existed)
  discard_on ActiveJob::DeserializationError

  def perform(user_id)
    Todo.where(user_id: user_id, deleted_at: nil)
        .update_all(deleted_at: Time.current)
  end
end
