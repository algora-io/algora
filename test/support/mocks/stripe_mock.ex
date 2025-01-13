defmodule Algora.Mocks.StripeMock do
  @moduledoc false
  import Mox

  def setup_create_session do
    stub(
      Algora.StripeMock,
      :create_session,
      fn _a -> {:ok, %{url: "https://example.com/stripe"}} end
    )
  end
end
