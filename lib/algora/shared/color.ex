defmodule Algora.Color do
  @moduledoc false
  @doc """
  Converts HSL string to hex color code.

  ## Examples

      iex> Algora.Color.hsl_to_hex("217deg 91% 60%")
      "#3CAFF6"
  """
  def hsl_to_hex(hsl) when is_binary(hsl) do
    hsl
    |> String.replace("deg", "")
    |> String.split(~r/[,\s]+/, trim: true)
    |> Enum.map(&String.trim/1)
    |> Enum.map(fn str ->
      str
      |> String.replace("%", "")
      |> Float.parse()
      |> then(fn {num, _} -> num end)
    end)
    |> then(fn [h, s, l] -> hsl_to_hex(h, s, l) end)
  end

  @doc """
  Converts HSL values to hex color code.

  ## Examples

      iex> Algora.Color.hsl_to_hex(217, 91, 60)
      "#3CAFF6"
  """
  def hsl_to_hex(h, s, l) when is_number(h) and is_number(s) and is_number(l) do
    h
    |> Chameleon.HSL.new(s, l)
    |> Chameleon.convert(Chameleon.Hex)
    |> then(&("#" <> &1.hex))
  end

  @doc """
  Converts HSL string to hex and finds nearest Tailwind color.

  ## Examples

      iex> Algora.Color.from_hsl("217deg 91% 60%")
      %{hex: "#3CAFF6", tailwind: "sky-400"}
  """
  def from_hsl(hsl) do
    hex = hsl_to_hex(hsl)
    nearest = find_nearest_tailwind_color(hex)
    %{hex: hex, tailwind: nearest}
  end

  @doc """
  Converts HSL values to hex and finds nearest Tailwind color.

  ## Examples

      iex> Algora.Color.from_hsl(217, 91, 60)
      %{hex: "#3CAFF6", tailwind: "sky-400"}
  """
  def from_hsl(h, s, l) do
    hex = hsl_to_hex(h, s, l)
    nearest = find_nearest_tailwind_color(hex)
    %{hex: hex, tailwind: nearest}
  end

  @doc """
  Converts a map of color names and hex values to CSS custom properties (variables).

  ## Examples

      iex> Algora.Color.to_css_vars(%{
      ...>   "primary": "#3b82f6",
      ...>   "secondary": "#6366f1"
      ...> })
      --primary: 217deg 91% 60%;
      --secondary: 239deg 84% 67%;
      :ok
  """
  def to_css_vars(hex_map) when is_map(hex_map) do
    hex_map
    |> Enum.map_join("\n", fn {name, hex} ->
      {h, s, l} =
        hex
        |> String.replace_prefix("#", "")
        |> Chameleon.Hex.new()
        |> Chameleon.convert(Chameleon.HSL)
        |> then(fn %{h: h, s: s, l: l} -> {h, s, l} end)

      "--#{name}: #{round(h)}deg #{round(s)}% #{round(l)}%;"
    end)
    |> IO.puts()
  end

  @doc """
  Converts CSS variable string to map of colors with hex and nearest Tailwind color.

  ## Examples

      iex> Algora.Color.from_css_vars(\"\"\"
      ...> --primary: 217deg 91% 60%;
      ...> --secondary: 239deg 84% 67%;
      ...> \"\"\")
      %{
        "primary" => %{hex: "#3CAFF6", tailwind: "sky-400"},
        "secondary" => %{hex: "#64EFF2", tailwind: "cyan-300"}
      }
  """
  def from_css_vars(css_string) when is_binary(css_string) do
    css_string
    |> String.split("\n", trim: true)
    |> Enum.map(&parse_css_var/1)
    |> Enum.reject(&is_nil/1)
    |> Map.new()
  end

  @doc """
  Finds the nearest Tailwind color name for a given hex color.

  ## Examples

      iex> Algora.Color.find_nearest_tailwind_color("#3B82F6")
      "blue-500"
  """
  def find_nearest_tailwind_color(hex) do
    hex_rgb = hex |> String.replace_prefix("#", "") |> Chameleon.Hex.new() |> Chameleon.convert(Chameleon.RGB)

    tailwind_colors()
    |> Enum.min_by(fn {_name, color} ->
      color_rgb = color |> String.replace_prefix("#", "") |> Chameleon.Hex.new() |> Chameleon.convert(Chameleon.RGB)
      color_distance(hex_rgb, color_rgb)
    end)
    |> elem(0)
  end

  defp color_distance(rgb1, rgb2) do
    :math.sqrt(
      :math.pow(rgb1.r - rgb2.r, 2) +
        :math.pow(rgb1.g - rgb2.g, 2) +
        :math.pow(rgb1.b - rgb2.b, 2)
    )
  end

  defp parse_css_var(line) do
    case Regex.run(~r/\s*--([^:]+):\s*([^;]+);/, line) do
      [_, var_name, hsl] -> {var_name, from_hsl(String.trim(hsl))}
      _ -> nil
    end
  end

  defp parse_color_line(line) do
    cond do
      # Match nested color objects like "slate: {"
      Regex.match?(~r/^\s*['"]?([^'"]+)['"]?:\s*{/, line) ->
        [_, color_name] = Regex.run(~r/^\s*['"]?([^'"]+)['"]?:\s*{/, line)
        {color_name, :start_object}

      # Match color-shade pairs like "500: '#123456'"
      Regex.match?(~r/^\s*['"]?(\d+)['"]?:\s*['"]#([^'"]+)['"]/, line) ->
        [_, shade, hex] = Regex.run(~r/^\s*['"]?(\d+)['"]?:\s*['"]#([^'"]+)['"]/, line)
        {:shade, shade, "##{hex}"}

      # Match simple color pairs like "black: '#000'"
      Regex.match?(~r/^\s*['"]?([^'"]+)['"]?:\s*['"]#([^'"]+)['"]/, line) ->
        [_, name, hex] = Regex.run(~r/^\s*['"]?([^'"]+)['"]?:\s*['"]#([^'"]+)['"]/, line)
        {name, "##{hex}"}

      true ->
        nil
    end
  end

  def tailwind_colors do
    colors_path = "assets/node_modules/tailwindcss/lib/public/colors.js"

    case File.read(colors_path) do
      {:ok, content} ->
        content
        |> String.split("\n")
        |> Enum.filter(&String.contains?(&1, ":"))
        |> Enum.reduce({%{}, nil}, fn line, {acc, current_color} ->
          case parse_color_line(line) do
            {color_name, :start_object} ->
              {acc, color_name}

            {:shade, shade, hex} when is_binary(current_color) ->
              {Map.put(acc, "#{current_color}-#{shade}", hex), current_color}

            {name, hex} ->
              {Map.put(acc, name, hex), current_color}

            nil ->
              {acc, current_color}
          end
        end)
        |> elem(0)

      {:error, _} ->
        raise "Could not find Tailwind colors at #{colors_path}. Ensure tailwindcss is installed in your assets."
    end
  end
end
