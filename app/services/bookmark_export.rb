require "csv"

# Serializes a user's bookmarks for download. The HTML variant follows the
# NETSCAPE-Bookmark-file-1 convention understood by Chrome, Firefox et al.
class BookmarkExport
  class << self
    def to_json(bookmarks)
      JSON.pretty_generate(
        bookmarks.map do |bookmark|
          {
            title: bookmark.title,
            url: bookmark.url,
            description: bookmark.description,
            tags: bookmark.tags.map(&:name).sort,
            favorite: bookmark.favorite?,
            archived: bookmark.archived?,
            visits: bookmark.visits_count,
            created_at: bookmark.created_at.iso8601
          }
        end
      )
    end

    def to_csv(bookmarks)
      CSV.generate(headers: true) do |csv|
        csv << %w[title url description tags favorite archived visits created_at]

        bookmarks.each do |bookmark|
          csv << [
            bookmark.title,
            bookmark.url,
            bookmark.description,
            bookmark.tags.map(&:name).sort.join(", "),
            bookmark.favorite?,
            bookmark.archived?,
            bookmark.visits_count,
            bookmark.created_at.iso8601
          ]
        end
      end
    end

    def to_netscape_html(bookmarks)
      entries = bookmarks.map do |bookmark|
        anchor = %(<DT><A HREF="#{escape(bookmark.url)}" ADD_DATE="#{bookmark.created_at.to_i}" TAGS="#{escape(bookmark.tags.map(&:name).sort.join(','))}">#{escape(bookmark.display_title)}</A>)
        anchor += "\n    <DD>#{escape(bookmark.description)}" if bookmark.description.present?
        "    #{anchor}"
      end

      <<~HTML
        <!DOCTYPE NETSCAPE-Bookmark-file-1>
        <!-- This is an automatically generated file. Do not edit. -->
        <META HTTP-EQUIV="Content-Type" CONTENT="text/html; charset=UTF-8">
        <TITLE>Bookmarks</TITLE>
        <H1>Bookmarks</H1>
        <DL><p>
        #{entries.join("\n")}
        </DL><p>
      HTML
    end

    private
      def escape(text)
        CGI.escapeHTML(text.to_s)
      end
  end
end
