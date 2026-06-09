class Api::V1::TodosController < ApplicationController
  before_action :authorize_todo_collection!, only: [ :index, :create ]
  before_action :set_todo, only: [ :show, :update, :destroy ]
  before_action -> { authorize!(@todo) }, only: [ :show, :update, :destroy ]

  def index
    todos = TodosQuery.new(scope).call(filter_params)
    @pagy, @todos = pagy(todos, limit: params[:limit])
  end

  def show
    @todo
  end

  def create
    @todo = scope.build(todo_params)
    @todo.save!
    render :create, status: :created
  end

  def update
    @todo.update!(todo_params)
  end

  def destroy
    @todo.soft_delete!
    head :no_content
  end

  private

  def scope
    current_user.todos.active
  end

  def set_todo
    @todo = scope.find(params[:id])
  end

  def authorize_todo_collection!
    authorize!(Todo.new)
  end

  def todo_params
    params.permit(:task, :description, :status)
  end

  def filter_params
    params.permit(:status)
  end
end
