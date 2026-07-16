module Api
  module V1
    class BookmarksController < BaseController
      # GET /api/v1/bookmarks?q=&tag=&filter=&sort=&page=
      def index
        scope = current_user.bookmarks.includes(:tags)

        scope = case params[:filter]
        when "archived"  then scope.archived
        when "favorites" then scope.active.favorites
        when "all"       then scope
        else scope.active
        end

        scope = scope.tagged_with(params[:tag]) if params[:tag].present?
        scope = scope.search(params[:q]) if params[:q].present?

        pagy, bookmarks = pagy(scope.sorted_by(params[:sort]))

        render json: {
          bookmarks: bookmarks.map { |bookmark| bookmark_json(bookmark) },
          page: pagy.page,
          pages: pagy.pages,
          count: pagy.count
        }
      end

      # GET /api/v1/bookmarks/1
      def show
        render json: bookmark_json(bookmark)
      end

      # POST /api/v1/bookmarks
      def create
        new_bookmark = current_user.bookmarks.new(bookmark_params)

        if new_bookmark.save
          render json: bookmark_json(new_bookmark), status: :created
        else
          render json: { errors: new_bookmark.errors.full_messages }, status: :unprocessable_entity
        end
      end

      # DELETE /api/v1/bookmarks/1
      def destroy
        bookmark.destroy!
        head :no_content
      end

      private
        def bookmark
          @bookmark ||= current_user.bookmarks.find(params.expect(:id))
        end

        def bookmark_params
          params.expect(bookmark: [ :url, :title, :description, :tag_list, :favorite ])
        end

        def bookmark_json(bookmark)
          {
            id: bookmark.id,
            title: bookmark.title,
            url: bookmark.url,
            description: bookmark.description,
            tags: bookmark.tags.map(&:name).sort,
            favorite: bookmark.favorite?,
            archived: bookmark.archived?,
            visits: bookmark.visits_count,
            created_at: bookmark.created_at.iso8601,
            updated_at: bookmark.updated_at.iso8601
          }
        end
    end
  end
end
