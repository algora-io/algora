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
          <.avatar_image src={icon_url(@tech_lower)} class={icon_class(@tech_lower)} />
          <.avatar_fallback>
            {Algora.Util.initials(@tech, 1)}
          </.avatar_fallback>
        </.avatar>
      <% end %>
      <span class="line-clamp-1">{@tech}</span>
    </.badge>
    """
  end

  defp icon_url("nvidia"), do: "/images/logos/nvidia.svg"
  defp icon_url("firecracker"), do: "/images/logos/firecracker.png"
  defp icon_url("ray"), do: "/images/logos/ray.png"
  defp icon_url("vllm"), do: "/images/logos/vllm.png"
  defp icon_url("mlir"), do: "/images/logos/mlir.png"

  defp icon_url("huggingface"), do: "/images/logos/huggingface.png"
  defp icon_url("youtube"), do: "/images/logos/youtube.png"
  defp icon_url("tiktok"), do: "/images/logos/tiktok.png"
  defp icon_url("openai"), do: "https://avatars.githubusercontent.com/u/14957082?s=200&v=4"
  defp icon_url("anthropic"), do: "https://avatars.githubusercontent.com/u/76263028?s=200&v=4"
  defp icon_url("claude"), do: "https://avatars.githubusercontent.com/u/76263028?s=200&v=4"
  defp icon_url("gemini"), do: "https://avatars.githubusercontent.com/u/161781182?s=200&v=4"
  defp icon_url("grok"), do: "https://avatars.githubusercontent.com/u/130314967?s=200&v=4"
  defp icon_url("clickhouse"), do: "https://avatars.githubusercontent.com/u/54801242?s=200&v=4"
  defp icon_url("deepspeed"), do: "https://avatars.githubusercontent.com/u/74068820?s=200&v=4"
  defp icon_url("llmfoundry"), do: "https://avatars.githubusercontent.com/u/75143706?s=200&v=4"
  defp icon_url("sglang"), do: "https://avatars.githubusercontent.com/u/147780389?s=200&v=4"
  defp icon_url("electron"), do: "https://avatars.githubusercontent.com/u/13409222?s=200&v=4"
  defp icon_url("oci"), do: "https://avatars.githubusercontent.com/u/12563465?s=200&v=4"
  defp icon_url(tech), do: "https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/#{icon_path(tech)}"

  defp icon_path("aws"), do: "amazonwebservices/amazonwebservices-plain-wordmark.svg"
  defp icon_path("gcp"), do: "googlecloud/googlecloud-original.svg"
  defp icon_path("objectivec"), do: "objectivec/objectivec-plain.svg"
  defp icon_path("rails"), do: "rails/rails-plain.svg"
  defp icon_path("django"), do: "django/django-plain.svg"
  defp icon_path("html"), do: "html5/html5-original.svg"
  defp icon_path("css"), do: "css3/css3-original.svg"
  defp icon_path(tech), do: "#{tech}/#{tech}-original.svg"

  defp icon_class("rust"), do: "bg-white invert saturate-0"
  defp icon_class("solidity"), do: "bg-white invert saturate-0"
  defp icon_class("crystal"), do: "bg-white invert saturate-0"
  defp icon_class("groovy"), do: "bg-white invert saturate-0"
  defp icon_class("objectivec"), do: "bg-white invert saturate-0"
  defp icon_class("django"), do: "bg-white invert saturate-0"
  defp icon_class("purescript"), do: "bg-white invert saturate-0"
  defp icon_class("astro"), do: "bg-white invert saturate-0"
  defp icon_class("apple"), do: "bg-white invert saturate-0"
  defp icon_class("github"), do: "bg-white invert saturate-0"
  defp icon_class("bash"), do: "bg-white invert saturate-0"
  defp icon_class("twitter"), do: "bg-white invert saturate-0"
  defp icon_class("apachekafka"), do: "bg-white invert saturate-0"
  defp icon_class("emacs"), do: "bg-white invert saturate-0"
  defp icon_class("flask"), do: "bg-white invert saturate-0"
  defp icon_class("prisma"), do: "bg-white invert saturate-0"
  defp icon_class("vercel"), do: "bg-white invert saturate-0"
  defp icon_class(_tech), do: "bg-transparent"

  defp normalize(tech) do
    case String.downcase(tech) do
      "golang" ->
        "go"

      "hcl" ->
        "terraform"

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

      "react native" ->
        "react"

      "nest.js" ->
        "nestjs"

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

      "nix" ->
        "nixos"

      "tensorrt" ->
        "nvidia"

      "cuda" ->
        "nvidia"

      "transformers" ->
        "huggingface"

      "hugging face" ->
        "huggingface"

      "spark" ->
        "apachespark"

      "kafka" ->
        "apachekafka"

      "apache kafka" ->
        "apachekafka"

      "vim script" ->
        "vim"

      "emacs lisp" ->
        "emacs"

      "tailwind" ->
        "tailwindcss"

      "llm foundry" ->
        "llmfoundry"

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
      "F#",
      "Kotlin",
      "Swift",
      "Elixir",
      "Haskell",
      "Lua",
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
      "Ecto",
      "Azure",
      "AWS",
      "GCP",
      "React",
      "Svelte",
      "Vue.js",
      "Astro",
      "Node.js",
      "Next.js",
      "Nest.js",
      "HTML",
      "CSS",
      "PostgreSQL",
      "MySQL",
      "Redis",
      "Figma",
      "Prometheus",
      "Grafana",
      "LiveView",
      "Apple",
      "Android",
      "Jupyter",
      "Nomad",
      "JIRA",
      "GitHub",
      "Shell",
      "FastAPI",
      "NixOS",
      "Nvidia",
      "Firecracker",
      "Deepspeed",
      "LLM Foundry",
      "Ray",
      "vLLM",
      "sglang",
      "TensorRT",
      "Hugging face",
      "Huggingface",
      "Twitter",
      "YouTube",
      "LinkedIn",
      "TikTok",
      "Django",
      "ApacheKafka",
      "ApacheSpark",
      "ObjectiveC",
      "Envoy",
      "RabbitMQ",
      "Flutter",
      "Vim",
      "Emacs",
      "Flask",
      "OpenAI",
      "Anthropic",
      "Claude",
      "Gemini",
      "Grok",
      "Solidity",
      "Zig",
      "Prisma",
      "TailwindCSS",
      "tRPC",
      "Clickhouse",
      "Vercel",
      "MLIR",
      "Julia",
      "Electron",
      "OCI"
    ]
  end
end
