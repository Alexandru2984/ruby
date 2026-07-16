module ApplicationHelper
  # Opens a small "save bookmark" window prefilled with the current page.
  def bookmarklet_javascript
    "javascript:void(window.open('#{new_bookmark_url}?url='+encodeURIComponent(location.href)+'&title='+encodeURIComponent(document.title),'_blank','width=640,height=720,noopener'))"
  end

  def input_classes(errored: false)
    [
      "block w-full rounded-md border px-3 py-2 mt-2 shadow-sm bg-white dark:bg-zinc-900",
      errored ? "border-red-400 focus:outline-red-600" : "border-zinc-300 dark:border-zinc-700 focus:outline-blue-600"
    ].join(" ")
  end

  def button_classes(variant = :primary)
    base = "rounded-md px-3.5 py-2.5 font-medium cursor-pointer inline-block text-center"

    styles = case variant
    when :primary then "bg-blue-600 hover:bg-blue-500 text-white"
    when :danger  then "bg-red-600 hover:bg-red-500 text-white"
    else "bg-zinc-100 hover:bg-zinc-200 dark:bg-zinc-800 dark:hover:bg-zinc-700"
    end

    "#{base} #{styles}"
  end
end
