# Idempotent demo data for local development. Run with bin/rails db:seed.
# Intentionally does nothing in production.
return unless Rails.env.development?

demo = User.find_or_create_by!(email_address: "demo@example.com") do |user|
  user.password = "password123"
end

[
  { url: "https://guides.rubyonrails.org/", title: "Ruby on Rails Guides", tag_list: "rails, docs", favorite: true },
  { url: "https://hotwired.dev/", title: "Hotwire", description: "HTML over the wire.", tag_list: "rails, frontend" },
  { url: "https://sqlite.org/wal.html", title: "SQLite Write-Ahead Logging", tag_list: "sqlite, database" },
  { url: "https://tailwindcss.com/docs", title: "Tailwind CSS Documentation", tag_list: "css, frontend, docs" },
  { url: "https://github.com/basecamp/solid_queue", title: "Solid Queue", description: "DB-backed Active Job backend.", tag_list: "rails, jobs" }
].each do |attributes|
  demo.bookmarks.find_or_create_by!(url: attributes[:url]) do |bookmark|
    bookmark.assign_attributes(attributes.except(:url))
  end
end

puts "Seeded #{demo.bookmarks.count} bookmarks for #{demo.email_address} (password: password123)"
