defmodule AlgoraWeb.Plugs.RuntimeRedirectPlug do
  import Plug.Conn
  alias Phoenix.Controller

  def init(opts), do: opts

  def call(conn, _opts) do
    redirects =
      Enum.map(Application.get_env(:algora, :redirects, []), fn {from, to} ->
        {from, to, :temporary}
      end)

    alias_redirects =
      Enum.flat_map(Application.get_env(:algora, :candidate_aliases, %{}), fn {sub, org} ->
        [{"/#{sub}", "/#{org}", :permanent}, {"/#{sub}/*path", "/#{org}/*path", :permanent}]
      end)

    case find_redirect(conn.request_path, redirects ++ alias_redirects) do
      {to, status} ->
        conn
        |> put_status(if(status == :permanent, do: 301, else: 302))
        |> redirect_to(to, conn.query_string)
        |> halt()

      nil ->
        conn
    end
  end

  defp find_redirect(path, redirects) do
    Enum.find_value(redirects, fn {from, to, type} ->
      case match_pattern(path, from) do
        {:ok, bindings} -> {build_destination(to, bindings), type}
        :error -> nil
      end
    end)
  end

  defp match_pattern(path, pattern) do
    orig = String.split(path, "/")
    lower = Enum.map(orig, &String.downcase/1)
    pattern_segs = String.split(String.downcase(pattern), "/")
    match_segments(orig, lower, pattern_segs, %{})
  end

  defp match_segments(orig, [], [], bindings) when orig == [], do: {:ok, bindings}
  defp match_segments(orig, _, ["*" <> name], bindings), do: {:ok, Map.put(bindings, name, Enum.join(orig, "/"))}
  defp match_segments(_, _, [], _), do: :error
  defp match_segments([], _, _, _), do: :error
  defp match_segments([o | ot], [_ | lt], [":" <> name | pt], bindings), do: match_segments(ot, lt, pt, Map.put(bindings, name, o))
  defp match_segments([_ | ot], [lh | lt], [lh | pt], bindings), do: match_segments(ot, lt, pt, bindings)
  defp match_segments(_, _, _, _), do: :error

  defp build_destination(template, bindings) do
    bindings
    |> Enum.sort_by(fn {k, _} -> -String.length(k) end)
    |> Enum.reduce(template, fn {k, v}, acc ->
      acc |> String.replace(":#{k}", v) |> String.replace("*#{k}", v)
    end)
  end

  defp redirect_to(conn, to, query_string) do
    qs = if query_string != "", do: "?#{query_string}", else: ""

    case to do
      "http" <> _ -> Controller.redirect(conn, external: to <> qs)
      _ -> Controller.redirect(conn, to: to <> qs)
    end
  end
end
