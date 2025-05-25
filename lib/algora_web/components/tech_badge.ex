defmodule AlgoraWeb.Components.TechBadge do
  @moduledoc false
  use Phoenix.Component

  import AlgoraWeb.Components.UI.Avatar
  import AlgoraWeb.Components.UI.Badge

  attr :tech, :string, required: true
  attr :variant, :string, default: "outline"
  attr :rest, :global

  def tech_badge(assigns) do
    assigns =
      assign(assigns, :tech_lower, normalize(assigns.tech))

    ~H"""
    <.badge variant={@variant} {@rest}>
      <%= if Enum.any?(langs(), &(normalize(&1) == @tech_lower)) do %>
        <.avatar class="w-4 h-4 mr-1 rounded-sm">
          <.avatar_image
            src={"https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/#{icon_path(@tech_lower)}"}
            class={icon_class(@tech_lower)}
          />
          <.avatar_fallback>
            {Algora.Util.initials(@tech, 1)}
          </.avatar_fallback>
        </.avatar>
      <% end %>
      {@tech}
    </.badge>
    """
  end

  defp icon_path("aws"), do: "amazonwebservices/amazonwebservices-plain-wordmark.svg"
  defp icon_path("gcp"), do: "googlecloud/googlecloud-original.svg"
  defp icon_path("objectivec"), do: "objectivec/objectivec-plain.svg"
  defp icon_path("rails"), do: "rails/rails-plain.svg"
  defp icon_path("html"), do: "html5/html5-original.svg"
  defp icon_path("css"), do: "css3/css3-original.svg"
  defp icon_path(tech), do: "#{tech}/#{tech}-original.svg"

  defp icon_class("rust"), do: "bg-white invert saturate-0"
  defp icon_class("solidity"), do: "bg-white invert saturate-0"
  defp icon_class("crystal"), do: "bg-white invert saturate-0"
  defp icon_class("groovy"), do: "bg-white invert saturate-0"
  defp icon_class("objectivec"), do: "bg-white invert saturate-0"
  defp icon_class("purescript"), do: "bg-white invert saturate-0"
  defp icon_class("astro"), do: "bg-white invert saturate-0"
  defp icon_class("apple"), do: "bg-white invert saturate-0"
  defp icon_class(_tech), do: "bg-transparent"

  defp normalize(tech) do
    case String.downcase(tech) do
      "plpgsql" ->
        "postgresql"

      "postgres" ->
        "postgresql"

      "vue" ->
        "vuejs"

      "vuejs" ->
        "vuejs"

      "reactjs" ->
        "react"

      "react.js" ->
        "react"

      "shell" ->
        "bash"

      "liveview" ->
        "phoenix"

      "ios" ->
        "apple"

      "jupyter notebook" ->
        "jupyter"

      "dockerfile" ->
        "docker"

      t ->
        t
        |> String.replace("+", "plus")
        |> String.replace("#", "sharp")
        |> String.replace("-", "")
        |> String.replace(".", "")
    end
  end

  def langs do
    [
      "JavaScript",
      "TypeScript",
      "Python",
      "Go",
      "Rust",
      "Java",
      "C++",
      "PHP",
      "Ruby",
      "Rails",
      "Scala",
      "C",
      "Dart",
      "C#",
      "Kotlin",
      "Swift",
      "Elixir",
      "Lua",
      "Julia",
      "Haskell",
      "Clojure",
      "Solidity",
      "Objective-C",
      "R",
      "Erlang",
      "Perl",
      "Zig",
      "Nim",
      "Groovy",
      "F#",
      "OCaml",
      "Crystal",
      "PureScript",
      "Elm",
      "Kubernetes",
      "Docker",
      "Terraform",
      "Ansible",
      "Linux",
      "LLVM",
      "WASM",
      "Pulumi",
      "TensorFlow",
      "PyTorch",
      "Azure",
      "AWS",
      "GCP",
      "React",
      "Svelte",
      "Vue.js",
      "Astro",
      "Node.js",
      "Next.js",
      "HTML",
      "CSS",
      "PostgreSQL",
      "Figma",
      "Prometheus",
      "Grafana",
      "LiveView",
      "Apple",
      "Android",
      "Jupyter",
      "Nomad"
    ]
  end
end
