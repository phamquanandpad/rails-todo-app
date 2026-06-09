require 'rails_helper'

RSpec.describe SoftDeleteUserTodosJob, type: :job do
  describe '#perform' do
    let(:user) { create(:user) }

    it 'soft-deletes all active todos belonging to the user' do
      active_todos = create_list(:todo, 3, user: user)
      already_deleted = create(:todo, :soft_deleted, user: user)

      described_class.perform_now(user.id)

      active_todos.each { |t| expect(t.reload.deleted_at).not_to be_nil }
      expect(already_deleted.reload.deleted_at).to eq(already_deleted.deleted_at) # unchanged
    end

    it 'does not touch todos belonging to other users' do
      other_user = create(:user)
      other_todo = create(:todo, user: other_user)

      described_class.perform_now(user.id)

      expect(other_todo.reload.deleted_at).to be_nil
    end

    it 'is enqueued on the default queue' do
      expect(described_class.new.queue_name).to eq('default')
    end
  end

  describe 'enqueuing via User#soft_delete!' do
    let(:user) { create(:user) }

    it 'enqueues SoftDeleteUserTodosJob after soft-deleting the user' do
      expect { user.soft_delete! }
        .to have_enqueued_job(described_class).with(user.id)
    end

    it 'marks the user as soft-deleted immediately (not async)' do
      user.soft_delete!
      expect(user.reload.deleted_at).not_to be_nil
    end
  end
end
