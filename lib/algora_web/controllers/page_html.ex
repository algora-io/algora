defmodule AlgoraWeb.PageHTML do
  use AlgoraWeb, :html

  embed_templates "page_html/*"

  def delay_class(index) do
    case index do
      0 -> "animate-delay-[0ms]"
      1 -> "animate-delay-[100ms]"
      2 -> "animate-delay-[200ms]"
      3 -> "animate-delay-[300ms]"
      4 -> "animate-delay-[400ms]"
      5 -> "animate-delay-[500ms]"
      6 -> "animate-delay-[600ms]"
      7 -> "animate-delay-[700ms]"
      _ -> ""
    end
  end
end
