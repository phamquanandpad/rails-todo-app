module Maintenance
  class PurgeTodosService < BaseService
    BATCH_SIZE = 500

    def initialize(cutoff)
      @cutoff = cutoff
    end

    def call
      purged = 0
      Todo.where.not(deleted_at: nil)
          .where(deleted_at: ..@cutoff)
          .in_batches(of: BATCH_SIZE) do |batch|
        ActiveRecord::Base.transaction do
          rows = batch.map { |todo| archive_row(todo) }
          ArchivedTodo.insert_all(rows) if rows.any?
          purged += batch.delete_all
        end
      end
      success(data: { purged: purged })
    end

    private

    def archive_row(todo)
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
  end
end
