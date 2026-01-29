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
  defp icon_url("drizzle orm"), do: "https://avatars.githubusercontent.com/u/108468352?s=48&v=4"
  defp icon_url("zod"), do: "https://raw.githubusercontent.com/colinhacks/zod/main/logo.svg"
  defp icon_url("livekit"), do: "https://avatars.githubusercontent.com/u/69438833?s=200&v=4"
  defp icon_url("webrtc"), do: "https://avatars.githubusercontent.com/u/10526312?s=200&v=4"
  defp icon_url("snowflake"), do: "https://avatars.githubusercontent.com/u/6453780?s=200&v=4"
  defp icon_url("langchain"), do: "https://avatars.githubusercontent.com/u/126733545?s=200&v=4"
  defp icon_url("llamaindex"), do: "https://avatars.githubusercontent.com/u/130722866?s=200&v=4"
  defp icon_url("pinecone"), do: "https://avatars.githubusercontent.com/u/54333248?s=200&v=4"
  defp icon_url("lancedb"), do: "https://avatars.githubusercontent.com/u/108903835?s=200&v=4"
  defp icon_url("datadog"), do: "https://avatars.githubusercontent.com/u/365230?s=200&v=4"
  defp icon_url("modal"), do: "https://avatars.githubusercontent.com/u/88658467?s=200&v=4"
  defp icon_url("tanstack"), do: "https://avatars.githubusercontent.com/u/72518640?s=200&v=4"
  defp icon_url("google maps"), do: "https://avatars.githubusercontent.com/u/3717923?s=200&v=4"
  defp icon_url("mapbox"), do: "https://avatars.githubusercontent.com/u/600935?s=200&v=4"
  defp icon_url("maplibre"), do: "https://avatars.githubusercontent.com/u/75709127?s=200&v=4"
  defp icon_url("datafusion"), do: "https://datafusion.apache.org/blog/images/logo_original4x.png"
  defp icon_url("grpc"), do: "https://algora-console.t3.storage.dev/avatars/grpc.png"
  defp icon_url("ebpf"), do: "https://algora-console.t3.storage.dev/avatars/ebpf.png"
  defp icon_url("scylladb"), do: "https://algora-console.t3.storage.dev/avatars/scylladb.png"
  defp icon_url("temporal"), do: "https://avatars.githubusercontent.com/u/56493103?s=200&v=4"
  defp icon_url("wireguard"), do: "https://avatars.githubusercontent.com/u/13991055?s=200&v=4"
  defp icon_url("ceph"), do: "https://algora-console.t3.storage.dev/avatars/ceph.png"
  defp icon_url(tech), do: "https://cdn.jsdelivr.net/gh/devicons/devicon@latest/icons/#{icon_path(tech)}"

  defp icon_path("aws"), do: "amazonwebservices/amazonwebservices-plain-wordmark.svg"
  defp icon_path("gcp"), do: "googlecloud/googlecloud-original.svg"
  defp icon_path("objectivec"), do: "objectivec/objectivec-plain.svg"
  defp icon_path("rails"), do: "rails/rails-plain.svg"
  defp icon_path("django"), do: "django/django-plain.svg"
  defp icon_path("graphql"), do: "graphql/graphql-plain.svg"
  defp icon_path("axios"), do: "axios/axios-plain.svg"
  defp icon_path("jest"), do: "jest/jest-plain.svg"
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
  defp icon_class("expo"), do: "bg-white invert saturate-0"
  defp icon_class("threejs"), do: "bg-white invert saturate-0"
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

      "node" ->
        "nodejs"

      "swiftui" ->
        "swift"

      "shell" ->
        "bash"

      "liveview" ->
        "phoenix"

      "ios" ->
        "apple"

      "jupyter notebook" ->
        "jupyter"

      "sql" ->
        "azuresqldatabase"

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

      "openai apis" ->
        "openai"

      "elk" ->
        "elasticsearch"

      "elk stack" ->
        "elasticsearch"

      "cypress" ->
        "cypressio"

      "vite" ->
        "vitejs"

      "react query" ->
        "tanstack"

      "webgl / webgpu" ->
        "webgpu"

      "webassembly" ->
        "wasm"

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
      "Cloudflare",
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
      "OCI",
      "Supabase",
      "Drizzle ORM",
      "Zod",
      "Expo",
      "Unity",
      "Powershell",
      "LiveKit",
      "WebRTC",
      "SQL",
      "Snowflake",
      "LangChain",
      "LlamaIndex",
      "Pinecone",
      "LanceDB",
      "Elasticsearch",
      "Datadog",
      "GraphQL",
      "Axios",
      "Styledcomponents",
      "SASS",
      "Jest",
      "Playwright",
      "Cypress",
      "Vite",
      "Webpack",
      "SQLite",
      "DataFusion",
      "Modal",
      "MongoDB",
      "Tanstack",
      "Clojure",
      "Mapbox",
      "MapLibre",
      "ThreeJS",
      "WebGPU",
      "Google Maps",
      "gRPC",
      "eBPF",
      "ScyllaDB",
      "Temporal",
      "WireGuard",
      "Ceph"
    ]
  end
end
