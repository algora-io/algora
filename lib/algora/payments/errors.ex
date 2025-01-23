defmodule Algora.Payments.StripeAccountLinkError do
  @moduledoc false
  defexception [:message]
end

defmodule Algora.Payments.StripeAccountCreateError do
  @moduledoc false
  defexception [:message]
end

defmodule Algora.Payments.StripeAccountDeleteError do
  @moduledoc false
  defexception [:message]
end
