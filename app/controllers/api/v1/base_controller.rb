module Api
  module V1
    class BaseController < ActionController::API
      include ActionController::HttpAuthentication::Token::ControllerMethods
      include Pagy::Backend

      before_action :authenticate!
      rate_limit to: 120, within: 1.minute, by: -> { request.authorization.to_s },
                 with: -> { render json: { error: "Rate limit exceeded" }, status: :too_many_requests }

      rescue_from ActiveRecord::RecordNotFound do
        render json: { error: "Not found" }, status: :not_found
      end

      private
        attr_reader :current_user

        def authenticate!
          @current_user = authenticate_with_http_token do |token, _options|
            User.find_by(api_token: token) if token.present?
          end

          return if @current_user

          response.headers["WWW-Authenticate"] = %(Bearer realm="Bookmarks API")
          render json: { error: "Unauthorized" }, status: :unauthorized
        end
    end
  end
end
