defmodule AlgoraWeb.LiveComponent do
  @moduledoc """
  The entrypoint for defining live components.

  This can be used in your components as:

    use AlgoraWeb

  Do NOT define functions inside the quoted expressions
  below. Instead, define additional modules and import
  those modules here.
  """

  defmacro __using__(_) do
    quote do
      use Phoenix.LiveComponent

      import AlgoraWeb.ComponentHelpers
      import AlgoraWeb.CoreComponents
      import Tails, only: [classes: 1]

      alias Phoenix.LiveView.JS
    end
  end
end
