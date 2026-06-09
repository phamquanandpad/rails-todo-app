module ErrorHandling
  extend ActiveSupport::Concern

  included do
    rescue_from StandardError,                               with: :render_500
    rescue_from ActiveRecord::RecordInvalid,                 with: :render_422
    rescue_from ActiveRecord::RecordNotSaved,                with: :render_422
    rescue_from ActiveRecord::RecordNotDestroyed,            with: :render_422
    rescue_from ApplicationPolicy::UnprocessableEntity,      with: :render_422
    rescue_from ActiveRecord::RecordNotFound,                with: :render_404
    rescue_from ApplicationPolicy::Forbidden,                with: :render_403
    rescue_from ApplicationPolicy::Unauthorized,             with: :render_401
    rescue_from ActionController::BadRequest,                with: :render_400
    rescue_from ActionController::ParameterMissing,          with: :render_400
    rescue_from ActionDispatch::Http::Parameters::ParseError, with: :render_400
  end

  private

  def render_400(exception) = render_json(400, exception)
  def render_401(exception) = render_json(401, exception)
  def render_403(exception) = render_json(403, exception)
  def render_404(exception) = render_json(404, exception)
  def render_422(exception) = render_json(422, exception)
  def render_500(exception) = render_json(500, exception)

  def render_json(status_code, exception, opt = {})
    error_body = { message: exception.message }
    error_body[:debug] = exception.full_message if ENV["DEBUG_ENABLED"].present?

    payload = { error: error_body, details: opt.fetch(:details, []) }

    render json: payload, status: status_code
  end
end
