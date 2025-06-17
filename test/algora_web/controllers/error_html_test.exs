defmodule AlgoraWeb.ErrorHTMLTest do
  use AlgoraWeb.ConnCase, async: true

  # Bring render_to_string/4 for testing custom views
  import Phoenix.Template

  test "renders 404.html" do
    assert render_to_string(AlgoraWeb.ErrorHTML, "404", "html", []) =~ "could not be found"
  end

  test "renders 500.html" do
    assert render_to_string(AlgoraWeb.ErrorHTML, "500", "html", []) == "Internal Server Error"
  end
end
