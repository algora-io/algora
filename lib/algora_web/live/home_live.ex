defmodule AlgoraWeb.HomeLive do
  use AlgoraWeb, :live_view

  @impl true
  def render(assigns) do
    ~H"""
    <header class="bg-gray-900 text-white py-4 px-6 md:px-12">
      <nav class="flex justify-between items-center">
        <.logo class="h-8 w-auto" />
      </nav>
    </header>

    <main class="bg-gray-900 text-white py-16 px-6 md:px-12 flex flex-col md:flex-row justify-between items-start">
      <div class="md:w-1/2 mb-8 md:mb-0">
        <h1 class="text-4xl md:text-5xl font-bold leading-tight mb-4 font-display">
          Open source <span class="text-green-400">UpWork</span>
          <br /> for <span class="text-orange-400">developers</span>
        </h1>
        <p class="text-gray-300 text-lg mb-8">
          GitHub bounties, freelancing and full-time jobs.
        </p>
        <div id="button-container" class={if @show_onboarding, do: "hidden", else: "flex space-x-4"}>
          <button
            phx-click="show_onboarding"
            phx-value-type="companies"
            class="bg-blue-500 hover:bg-blue-600 text-white font-bold py-3 px-6 rounded transition duration-300"
          >
            Companies
          </button>
          <button
            phx-click="show_onboarding"
            phx-value-type="developers"
            class="bg-transparent hover:bg-white hover:bg-opacity-10 text-white font-bold py-3 px-6 rounded border-2 border-white transition duration-300"
          >
            Developers
          </button>
        </div>
        <div id="onboarding-section" class={if @show_onboarding, do: "", else: "hidden"}>
          <div id="first-question" class={if @show_tech_question, do: "hidden", else: ""}>
            <h3 class="text-xl font-bold mb-4">What do you want?</h3>
            <form phx-submit="show_tech_question">
              <div class="space-y-4">
                <%= for {option, label} <- [{"option1", "Share open source bounties"}, {"option2", "Share freelancing projects"}, {"option3", "Share full-time jobs"}] do %>
                  <div class="flex items-center space-x-2">
                    <input
                      type="checkbox"
                      id={option}
                      name="selected_options[]"
                      value={option}
                      class="custom-checkbox"
                    />
                    <label for={option}><%= label %></label>
                  </div>
                <% end %>
              </div>
              <button
                type="submit"
                class="mt-6 bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded transition duration-300"
              >
                Proceed
              </button>
            </form>
          </div>

          <div
            id="tech-question"
            class={if @show_tech_question && !@show_third_question, do: "", else: "hidden"}
          >
            <h3 class="text-xl font-bold mb-4">What technology?</h3>
            <form phx-submit="show_third_question">
              <div class="flex flex-wrap gap-4">
                <%= for tech <- ["TypeScript", "Scala", "Java", "C++", "C#", "Kotlin", "Swift", "Ruby", "Golang", "Elixir", "PHP", "Rust"] do %>
                  <div class="flex items-center">
                    <input
                      type="checkbox"
                      id={"tech-#{String.downcase(tech)}"}
                      name="selected_tech[]"
                      value={tech}
                      class="custom-checkbox"
                    />
                    <label for={"tech-#{String.downcase(tech)}"} class="ml-2"><%= tech %></label>
                  </div>
                <% end %>
              </div>
              <button
                type="submit"
                class="mt-6 bg-blue-500 hover:bg-blue-600 text-white font-bold py-2 px-4 rounded transition duration-300"
              >
                Proceed
              </button>
            </form>
          </div>

          <div id="third-question" class={if @show_third_question, do: "", else: "hidden"}>
            <h3 class="text-xl font-bold mb-4">Great! We've found some matches for you.</h3>
            <p id="match-count" class="text-lg mb-4">
              We found <%= @matches.count %> potential matches for you!
            </p>
            <div id="match-list" class="space-y-4 mb-6">
              <%= for match <- @matches.sample_matches do %>
                <div class="bg-gray-800 p-4 rounded">
                  <h5 class="font-semibold"><%= match.name %></h5>
                  <p><%= match.description %></p>
                </div>
              <% end %>
            </div>

            <h4 class="text-lg font-semibold mb-2">Connect with GitHub to see all matches:</h4>
            <.link
              href={Algora.Github.authorize_url()}
              class="mt-2 bg-gray-800 hover:bg-gray-700 text-white font-bold py-2 px-4 rounded transition duration-300 flex items-center justify-center"
            >
              <AlgoraWeb.Components.Icons.github class="w-5 h-5 mr-2" /> Connect with GitHub
            </.link>
          </div>
        </div>
      </div>

      <div class="md:w-1/2 flex overflow-hidden relative p-6 h-[80svh]">
        <div class="absolute rotate-[5deg] inset-0 bg-gradient-to-b from-transparent from-95% to-gray-900 z-10">
        </div>
        <div class="absolute rotate-[5deg] inset-0 bg-gradient-to-t from-transparent from-95% to-gray-900 z-10">
        </div>
        <%= for column <- [0, 1] do %>
          <div class="w-1/2 rotate-[5deg] flex flex-col space-y-6 overflow-hidden px-3">
            <%= for {company, index} <- Enum.with_index([
          {"substack", "bg-blue-400", "$7,809,219", "6,688", "al6z", "🇺🇸"},
          {"Synthesis", "bg-blue-200", "$4,999,989", "1,440", "al6z", "🇬🇧"},
          {"curlmix", "bg-green-200", "$4,537,310", "6,948", "Backstage Capital", "🇨🇦"},
          {"MERCURY", "bg-yellow-300", "$4,914,037", "2,453", "al6z", "🇩🇪"},
          {"TechNova", "bg-purple-300", "$3,250,000", "1,875", "Sequoia", "🇮🇳"},
          {"GreenLeaf", "bg-green-400", "$5,120,500", "3,210", "Accel", "🇦🇺"},
          {"DataFlow", "bg-blue-500", "$6,750,000", "4,500", "Andreessen Horowitz", "🇸🇬"},
          {"RoboTech", "bg-red-300", "$2,980,000", "2,100", "Kleiner Perkins", "🇯🇵"}
        ]) do %>
              <%= if rem(index, 2) == column do %>
                <div
                  class={[
                    "rounded-xl shadow-lg transition duration-300",
                    elem(company, 1),
                    "animate-carousel",
                    if(column == 0, do: "animate-up", else: "animate-down")
                  ]}
                  style="height: 280px;"
                >
                  <div class="p-3 flex flex-col h-full">
                    <div class="flex justify-between items-start mb-2">
                      <h3 class="text-sm font-bold"><%= elem(company, 0) %></h3>
                      <div class="flex items-center">
                        <span class="mr-1 text-lg"><%= elem(company, 5) %></span>
                        <img
                          src={"https://ui-avatars.com/api/?name=#{elem(company, 0)}&background=fff&color=000&size=24"}
                          alt="Company logo"
                          class="w-6 h-6 rounded"
                        />
                      </div>
                    </div>
                    <div class="mb-2 flex-grow">
                      <img
                        src={"https://picsum.photos/seed/#{elem(company, 0)}/200/100"}
                        alt="Founder"
                        class="w-full h-24 object-cover rounded"
                      />
                    </div>
                    <div class="flex justify-between text-xs mb-1">
                      <div>
                        <p class="font-semibold"><%= elem(company, 2) %></p>
                        <p class="text-gray-300">invested</p>
                      </div>
                      <div class="text-right">
                        <p class="font-semibold"><%= elem(company, 3) %></p>
                        <p class="text-gray-300">investors</p>
                      </div>
                    </div>
                    <div class="bg-white bg-opacity-20 px-2 py-1 rounded">
                      <p class="text-xs text-white"><%= elem(company, 4) %> co-invested</p>
                    </div>
                  </div>
                </div>
              <% end %>
            <% end %>
          </div>
        <% end %>
      </div>
    </main>

    <style>
      @keyframes moveUp {
        0% { transform: translateY(0); }
        100% { transform: translateY(-100%); }
      }

      @keyframes moveDown {
        0% { transform: translateY(-100%); }
        100% { transform: translateY(0); }
      }

      .animate-carousel {
        animation-duration: 30s;
        animation-timing-function: linear;
        animation-iteration-count: infinite;
      }

      .animate-up {
        animation-name: moveUp;
      }

      .animate-down {
        animation-name: moveDown;
      }
    </style>
    """
  end

  @impl true
  def mount(_params, _session, socket) do
    {:ok,
     assign(socket,
       page_title: "Home",
       show_onboarding: false,
       show_tech_question: false,
       show_third_question: false,
       matches: %{count: 0, sample_matches: []}
     )}
  end

  @impl true
  def handle_event("show_onboarding", %{"type" => type}, socket) do
    {:noreply, assign(socket, show_onboarding: true, onboarding_type: type)}
  end

  @impl true
  def handle_event("show_tech_question", %{"selected_options" => selected_options}, socket) do
    {:noreply, assign(socket, show_tech_question: true, selected_options: selected_options)}
  end

  @impl true
  def handle_event("show_third_question", %{"selected_tech" => selected_tech}, socket) do
    matches = generate_fake_matches(selected_tech)

    {:noreply,
     assign(socket, show_third_question: true, selected_tech: selected_tech, matches: matches)}
  end

  defp generate_fake_matches(technologies) do
    match_count = Enum.random(5..24)

    sample_matches =
      Enum.take_random(technologies, 3)
      |> Enum.with_index(1)
      |> Enum.map(fn {tech, i} ->
        %{
          name: "Project #{i}",
          description: "A #{tech} project looking for contributors."
        }
      end)

    %{count: match_count, sample_matches: sample_matches}
  end
end
