defmodule Algora.Cldr do
  @moduledoc false
  use Cldr,
    locales: ["en", "de"],
    default_locale: "en",
    providers: [Cldr.Number, Money]
end
