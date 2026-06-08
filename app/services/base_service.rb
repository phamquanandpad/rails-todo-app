class BaseService
  Result = Struct.new(:success, :data, :errors, keyword_init: true) do
    def success? = success
    def failure? = !success
  end

  def self.call(...)
    new(...).call
  end

  def call
    raise NotImplementedError
  end

  private

  def success(data: nil)
    Result.new(success: true, data: data, errors: nil)
  end

  def failure(errors:)
    Result.new(success: false, data: nil, errors: errors)
  end
end
