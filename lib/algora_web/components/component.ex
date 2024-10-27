defmodule AlgoraWeb.Component do
  @moduledoc """
  The entrypoint for defining UI components.

  This can be used in your components as:

    use AlgoraWeb

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  defmacro __using__(_) do
    quote do
      use Phoenix.Component

      import AlgoraWeb.ComponentHelpers
      import Tails, only: [classes: 1]

      alias Phoenix.LiveView.JS
    end
  end
end
