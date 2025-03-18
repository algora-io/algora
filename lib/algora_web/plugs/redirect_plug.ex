defmodule AlgoraWeb.RedirectPlug do
  @moduledoc false
  import Plug.Conn

  alias Phoenix.Controller

  def init(opts) do
    if opts[:to] do
      nil
    else
      raise ArgumentError, "expected :to option"
    end

    if opts[:type] do
      nil
    else
      raise ArgumentError, "expected :type option"
    end

    case opts[:type] do
      :permanent -> nil
      :temporary -> nil
      _ -> raise ArgumentError, "expected :type option to be set to :permanent or :temporary"
    end

    opts
    |> Keyword.put(
      :preserve_query_string,
      Keyword.get(opts[:opts], :preserve_query_string, false)
    )
    |> Keyword.delete(:opts)
  end

  def call(conn, opts) do
    conn
    |> put_redirect_status(opts[:type])
    |> do_redirect(opts)
    |> halt()
  end

  defp put_redirect_status(conn, :permanent), do: put_status(conn, 301)
  defp put_redirect_status(conn, :temporary), do: put_status(conn, 302)

  defp do_redirect(conn, opts) do
    query_string =
      if opts[:preserve_query_string] && conn.params != %{} do
        "?#{URI.encode_query(conn.params)}"
      else
        ""
      end

    case opts[:to] do
      "http" <> _ = to -> Controller.redirect(conn, external: to <> query_string)
      to -> Controller.redirect(conn, to: to <> query_string)
    end
  end

  defmacro redirect(path, to, type, opts \\ [])

  defmacro redirect(path, to, type, opts) do
    quote do
      match(:*, unquote(path), unquote(__MODULE__),
        to: unquote(to),
        type: unquote(type),
        opts: unquote(opts)
      )
    end
  end
end
