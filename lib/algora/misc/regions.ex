defmodule Algora.Misc.Regions do
  @regions %{
    "APAC" => [
      "AU",
      "BD",
      "CN",
      "HK",
      "ID",
      "IN",
      "JP",
      "KR",
      "LK",
      "MN",
      "MY",
      "NP",
      "NZ",
      "PH",
      "PK",
      "SG",
      "TH",
      "TW",
      "VN"
    ],
    "EMEA" => [
      "AE",
      "AM",
      "AT",
      "AZ",
      "BA",
      "BE",
      "BG",
      "BH",
      "BJ",
      "CH",
      "CI",
      "CY",
      "CZ",
      "DE",
      "DK",
      "DZ",
      "EE",
      "EG",
      "ES",
      "ET",
      "FI",
      "FR",
      "GA",
      "GB",
      "GH",
      "GR",
      "HR",
      "HU",
      "IE",
      "IL",
      "IT",
      "KE",
      "KZ",
      "LT",
      "LU",
      "LV",
      "MA",
      "MD",
      "MG",
      "MT",
      "NG",
      "NL",
      "NO",
      "PL",
      "PT",
      "RO",
      "RS",
      "RW",
      "SA",
      "SE",
      "SI",
      "SK",
      "SN",
      "TN",
      "TR",
      "UZ",
      "ZA"
    ],
    "AMERICAS" => [
      "AR",
      "BR",
      "CA",
      "CL",
      "CO",
      "DO",
      "EC",
      "GT",
      "MX",
      "PE",
      "US",
      "UY"
    ]
  }

  def get_region(country_code) when is_binary(country_code) do
    country_code = String.upcase(country_code)

    cond do
      country_code in @regions["APAC"] -> "APAC"
      country_code in @regions["EMEA"] -> "EMEA"
      country_code in @regions["AMERICAS"] -> "AMERICAS"
      true -> "OTHER"
    end
  end

  def all_regions, do: Map.keys(@regions)
end
