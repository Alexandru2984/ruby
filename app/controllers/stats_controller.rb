class StatsController < ApplicationController
  MONTHS_SHOWN = 6

  def show
    bookmarks = Current.user.bookmarks

    @totals = {
      bookmarks: bookmarks.count,
      favorites: bookmarks.active.favorites.count,
      archived: bookmarks.archived.count,
      broken: bookmarks.active.broken.count,
      tags: Current.user.tags.count,
      visits: bookmarks.sum(:visits_count)
    }

    @top_tags = Current.user.tags
                       .left_joins(:taggings)
                       .select("tags.*, COUNT(taggings.id) AS bookmarks_count")
                       .group("tags.id")
                       .order(Arel.sql("COUNT(taggings.id) DESC, tags.name ASC"))
                       .limit(10)

    @most_visited = bookmarks.active.where(visits_count: 1..).order(visits_count: :desc, id: :desc).limit(5)

    @monthly = monthly_counts(bookmarks)
  end

  private
    # [[month_date, count], …] oldest first, zero-filled.
    def monthly_counts(bookmarks)
      months = (MONTHS_SHOWN - 1).downto(0).map { |i| Date.current.beginning_of_month << i }
      counts = bookmarks.where(created_at: months.first.beginning_of_day..)
                        .group(Arel.sql("strftime('%Y-%m', created_at)"))
                        .count

      months.map { |month| [ month, counts.fetch(month.strftime("%Y-%m"), 0) ] }
    end
end
