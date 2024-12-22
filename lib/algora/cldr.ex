defmodule Algora.Cldr do
  use Cldr,
    locales: ["en", "de"],
    default_locale: "en",
    providers: [Cldr.Number, Money]
end
