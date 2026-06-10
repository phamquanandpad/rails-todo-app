module Maintenance
  class PurgeUsersService < BaseService
    BATCH_SIZE = 500

    def initialize(cutoff)
      @cutoff = cutoff
    end

    def call
      purged = 0
      User.where.not(deleted_at: nil)
          .where(deleted_at: ..@cutoff)
          .in_batches(of: BATCH_SIZE) do |batch|
        ActiveRecord::Base.transaction do
          batch.each do |user|
            archive_user_todos(user)
          end

          user_ids = batch.pluck(:id)

          # Archive users
          rows = batch.map { |user| archive_user_row(user) }
          ArchivedUser.insert_all(rows) if rows.any?

          # Hard-delete dependent records (bypass callbacks for bulk efficiency)
          RefreshToken.where(user_id: user_ids).delete_all
          UserPermission.where(user_id: user_ids).delete_all

          purged += batch.delete_all
        end
      end
      success(data: { purged: purged })
    end

    private

    def archive_user_todos(user)
      Todo.where(user_id: user.id).in_batches(of: BATCH_SIZE) do |todos_batch|
         rows = todos_batch.map { |todo| archive_todo_row(todo) }
         ArchivedTodo.insert_all(rows) if rows.any?
         todos_batch.delete_all
       end
    end

    def archive_todo_row(todo)
      {
        original_id:          todo.id,
        user_id:              todo.user_id,
        task:                 todo.task,
        description:          todo.description,
        status:               Todo.statuses[todo.status],
        deleted_at:           todo.deleted_at,
        original_created_at:  todo.created_at,
        original_updated_at:  todo.updated_at,
        archived_at:          Time.current,
        created_at:           Time.current,
        updated_at:           Time.current
      }
    end

    def archive_user_row(user)
      {
        original_id:          user.id,
        username:             user.username,
        email:                user.email,
        password_digest:      user.password_digest,
        role:                 User.roles[user.role],
        deleted_at:           user.deleted_at,
        original_created_at:  user.created_at,
        original_updated_at:  user.updated_at,
        archived_at:          Time.current,
        created_at:           Time.current,
        updated_at:           Time.current
      }
    end
  end
end
