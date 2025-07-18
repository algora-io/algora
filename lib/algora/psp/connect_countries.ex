defmodule Algora.PSP.ConnectCountries do
  @moduledoc false

  @spec list() :: [{String.t(), String.t()}]
  def list,
    do: [
      {"Albania", "AL"},
      {"Algeria", "DZ"},
      {"Angola", "AO"},
      {"Antigua and Barbuda", "AG"},
      {"Argentina", "AR"},
      {"Armenia", "AM"},
      {"Australia", "AU"},
      {"Austria", "AT"},
      {"Azerbaijan", "AZ"},
      {"Bahamas", "BS"},
      {"Bahrain", "BH"},
      {"Bangladesh", "BD"},
      {"Belgium", "BE"},
      {"Benin", "BJ"},
      {"Bhutan", "BT"},
      {"Bolivia", "BO"},
      {"Bosnia and Herzegovina", "BA"},
      {"Botswana", "BW"},
      {"Brazil", "BR"},
      {"Brunei", "BN"},
      {"Bulgaria", "BG"},
      {"Cambodia", "KH"},
      {"Canada", "CA"},
      {"Chile", "CL"},
      {"Colombia", "CO"},
      {"Costa Rica", "CR"},
      {"Croatia", "HR"},
      {"Cyprus", "CY"},
      {"Czech Republic", "CZ"},
      {"Denmark", "DK"},
      {"Dominican Republic", "DO"},
      {"Ecuador", "EC"},
      {"Egypt", "EG"},
      {"El Salvador", "SV"},
      {"Estonia", "EE"},
      {"Ethiopia", "ET"},
      {"Finland", "FI"},
      {"France", "FR"},
      {"Gabon", "GA"},
      {"Gambia", "GM"},
      {"Germany", "DE"},
      {"Ghana", "GH"},
      {"Gibraltar", "GI"},
      {"Greece", "GR"},
      {"Guatemala", "GT"},
      {"Guyana", "GY"},
      {"Hong Kong", "HK"},
      {"Hungary", "HU"},
      {"Iceland", "IS"},
      {"India", "IN"},
      {"Indonesia", "ID"},
      {"Ireland", "IE"},
      {"Israel", "IL"},
      {"Italy", "IT"},
      {"Ivory Coast", "CI"},
      {"Jamaica", "JM"},
      {"Japan", "JP"},
      {"Jordan", "JO"},
      {"Kazakhstan", "KZ"},
      {"Kenya", "KE"},
      {"Kuwait", "KW"},
      {"Laos", "LA"},
      {"Latvia", "LV"},
      {"Liechtenstein", "LI"},
      {"Lithuania", "LT"},
      {"Luxembourg", "LU"},
      {"Macao", "MO"},
      {"Macedonia", "MK"},
      {"Madagascar", "MG"},
      {"Malaysia", "MY"},
      {"Malta", "MT"},
      {"Mauritius", "MU"},
      {"Mexico", "MX"},
      {"Moldova", "MD"},
      {"Monaco", "MC"},
      {"Mongolia", "MN"},
      {"Morocco", "MA"},
      {"Mozambique", "MZ"},
      {"Namibia", "NA"},
      {"Netherlands", "NL"},
      {"New Zealand", "NZ"},
      {"Nigeria", "NG"},
      {"Norway", "NO"},
      {"Oman", "OM"},
      {"Pakistan", "PK"},
      {"Panama", "PA"},
      {"Paraguay", "PY"},
      {"Peru", "PE"},
      {"Philippines", "PH"},
      {"Poland", "PL"},
      {"Portugal", "PT"},
      {"Qatar", "QA"},
      {"Romania", "RO"},
      {"Rwanda", "RW"},
      {"Saint Lucia", "LC"},
      {"San Marino", "SM"},
      {"Saudi Arabia", "SA"},
      {"Senegal", "SN"},
      {"Serbia", "RS"},
      {"Singapore", "SG"},
      {"Slovakia", "SK"},
      {"Slovenia", "SI"},
      {"South Africa", "ZA"},
      {"South Korea", "KR"},
      {"Spain", "ES"},
      {"Sri Lanka", "LK"},
      {"Sweden", "SE"},
      {"Switzerland", "CH"},
      {"Taiwan", "TW"},
      {"Tanzania", "TZ"},
      {"Thailand", "TH"},
      {"Trinidad and Tobago", "TT"},
      {"Tunisia", "TN"},
      {"Turkey", "TR"},
      {"United Arab Emirates", "AE"},
      {"United Kingdom", "GB"},
      {"United States", "US"},
      {"Uruguay", "UY"},
      {"Uzbekistan", "UZ"},
      {"Vietnam", "VN"}
    ]

  def count, do: length(list())

  @spec from_code(String.t()) :: String.t()
  def from_code(code) do
    case Enum.find(list(), &(elem(&1, 1) == code)) do
      nil -> code
      {name, _} -> name
    end
  end

  def abbr_from_code("US"), do: "US"

  def abbr_from_code(code) do
    case Enum.find(list(), &(elem(&1, 1) == code)) do
      nil -> code
      {name, _} -> name
    end
  end

  @spec list_codes() :: [String.t()]
  def list_codes, do: Enum.map(list(), &elem(&1, 1))

  @spec account_type(String.t()) :: :standard | :express
  def account_type("BR"), do: :standard
  def account_type(_), do: :express

  @spec regions() :: %{String.t() => [String.t()]}
  def regions do
    %{
      "LATAM" => [
        "BR",
        "MX",
        "CO",
        "AR",
        "PE",
        "VE",
        "CL",
        "GT",
        "EC",
        "BO",
        "HT",
        "DO",
        "HN",
        "CU",
        "PY",
        "NI",
        "SV",
        "CR",
        "PA",
        "UY",
        "JM",
        "TT",
        "GY",
        "SR",
        "BZ",
        "BS",
        "BB",
        "LC",
        "GD",
        "VC",
        "AG",
        "DM",
        "KN"
      ],
      "APAC" => [
        "AU",
        "BD",
        "BN",
        "BT",
        "HK",
        "ID",
        "IN",
        "JP",
        "KH",
        "KR",
        "LA",
        "LK",
        "MO",
        "MM",
        "MN",
        "MY",
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
        "AL",
        "AM",
        "AO",
        "AT",
        "AZ",
        "BA",
        "BE",
        "BG",
        "BH",
        "BJ",
        "BW",
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
        "GI",
        "GM",
        "GR",
        "HR",
        "HU",
        "IE",
        "IL",
        "IS",
        "IT",
        "JO",
        "KE",
        "KW",
        "KZ",
        "LI",
        "LT",
        "LU",
        "LV",
        "MA",
        "MC",
        "MD",
        "MG",
        "MK",
        "MT",
        "MU",
        "MZ",
        "NA",
        "NG",
        "NL",
        "NO",
        "OM",
        "PL",
        "PT",
        "QA",
        "RO",
        "RS",
        "RW",
        "SA",
        "SE",
        "SI",
        "SK",
        "SM",
        "SN",
        "TN",
        "TR",
        "TZ",
        "ZA"
      ],
      "AMERICAS" => [
        "US",
        "CA",
        "BR",
        "MX",
        "CO",
        "AR",
        "PE",
        "VE",
        "CL",
        "GT",
        "EC",
        "BO",
        "HT",
        "DO",
        "HN",
        "CU",
        "PY",
        "NI",
        "SV",
        "CR",
        "PA",
        "UY",
        "JM",
        "TT",
        "GY",
        "SR",
        "BZ",
        "BS",
        "BB",
        "LC",
        "GD",
        "VC",
        "AG",
        "DM",
        "KN"
      ],
      "NA" => [
        "US",
        "CA"
      ],
      "EU" => [
        "AE",
        "AL",
        "AM",
        "AT",
        "AZ",
        "BA",
        "BE",
        "BG",
        "BH",
        "CH",
        "CY",
        "CZ",
        "DE",
        "DK",
        "EE",
        "ES",
        "FI",
        "FR",
        "GB",
        "GI",
        "GR",
        "HR",
        "HU",
        "IE",
        "IS",
        "IT",
        "JO",
        "KW",
        "KZ",
        "LI",
        "LT",
        "LU",
        "LV",
        "MC",
        "MD",
        "MK",
        "MT",
        "NL",
        "NO",
        "OM",
        "PL",
        "PT",
        "QA",
        "RO",
        "RS",
        "SA",
        "SE",
        "SI",
        "SK",
        "SM",
        "TN",
        "TR"
      ]
    }
  end

  def get_countries(region) do
    case regions()[region] do
      nil -> []
      countries -> countries
    end
  end
end
