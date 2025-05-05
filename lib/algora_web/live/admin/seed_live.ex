defmodule AlgoraWeb.Admin.SeedLive do
  @moduledoc false

  use AlgoraWeb, :live_view

  import Ecto.Changeset
  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.Jobs.JobPosting
  alias Algora.Organizations
  alias Algora.Repo
  alias Algora.Workspace
  alias AlgoraWeb.LocalStore

  require Logger

  @user_cache_table :seed_user_cache

  def start_link do
    :ets.new(@user_cache_table, [:named_table, :set, :public])
  end

  defmodule Form do
    @moduledoc false
    use Ecto.Schema

    embedded_schema do
      field :csv, :string
      field :visible_columns, {:array, :string}, default: []
    end

    def changeset(campaign, attrs \\ %{}) do
      campaign
      |> cast(attrs, [:csv, :visible_columns])
      |> validate_required([:csv])
      |> validate_length(:csv, min: 1)
    end
  end

  @impl true
  def mount(_params, _session, socket) do
    timezone = if(params = get_connect_params(socket), do: params["timezone"])

    {:ok,
     socket
     |> assign(:timezone, timezone)
     |> assign(:page_title, "Seed")
     |> assign(:form, to_form(Form.changeset(%Form{}, %{visible_columns: []})))
     |> assign_preview()}
  end

  @impl true
  def handle_params(_params, _uri, socket) do
    {:noreply,
     socket
     |> LocalStore.init(key: __MODULE__, ttl: :infinity)
     |> LocalStore.subscribe()}
  end

  @impl true
  def handle_event("restore_settings", params, socket) do
    {:noreply,
     socket
     |> LocalStore.restore(params)
     |> assign_preview()}
  end

  @impl true
  def handle_event("preview", %{"form" => params}, socket) do
    {:noreply,
     socket
     |> LocalStore.assign_cached(:form, to_form(Form.changeset(%Form{}, params)))
     |> assign_preview()}
  end

  @impl true
  def handle_event("seed", _params, socket) do
    case seed_rows(socket.assigns.csv_data) do
      {:ok, _} ->
        {:noreply,
         socket
         |> put_flash(:info, "Jobs created successfully")
         |> assign_preview()}

      {:error, reason} ->
        {:noreply, put_flash(socket, :error, "Failed to create jobs: #{inspect(reason)}")}
    end
  end

  @impl true
  def render(assigns) do
    ~H"""
    <div class="bg-background" phx-hook="LocalStateStore" id="seed-page" data-storage="localStorage">
      <div class="max-w-7xl mx-auto py-8 space-y-8">
        <.header>
          Seed jobs
          <:subtitle>Seed entries in database</:subtitle>
        </.header>

        <.form for={@form} phx-change="preview" class="space-y-4">
          <.input
            type="textarea"
            field={@form[:csv]}
            label="CSV Data"
            helptext="Enter your CSV data with headers matching the template variables"
          />

          <div class="flex flex-wrap gap-4 mb-4">
            <label
              :for={col <- @csv_columns |> Enum.reject(&(&1 == "org_id"))}
              class="flex items-center gap-2"
            >
              <input
                type="checkbox"
                name="form[visible_columns][]"
                value={col}
                checked={col in (@form.params["visible_columns"] || [])}
              />
              <span>{col}</span>
            </label>
          </div>

          <div>
            <div class="-mx-4 overflow-x-auto">
              <div class="flex justify-end mb-4">
                <.button type="button" phx-click="seed">
                  Seed {length(@csv_data)} entries
                </.button>
              </div>
              <.table id="csv-data" rows={@csv_data}>
                <:col
                  :let={row}
                  :for={
                    key <-
                      @csv_columns |> Enum.filter(&(&1 in (@form.params["visible_columns"] || [])))
                  }
                  label={key}
                >
                  <.cell value={row[key]} timezone={@timezone} column={key} />
                </:col>
              </.table>
            </div>
          </div>
        </.form>
      </div>
    </div>
    """
  end

  defp cell(%{value: %User{}} = assigns) do
    ~H"""
    <div class="flex flex-col gap-3 md:flex-row">
      <div class="flex-shrink-0">
        <.avatar class="h-12 w-12">
          <.avatar_image src={@value.avatar_url} alt={@value.name} />
          <.avatar_fallback>
            {Algora.Util.initials(@value.name)}
          </.avatar_fallback>
        </.avatar>
      </div>

      <div class="flex-1">
        <div class="flex gap-2 items-center">
          <h1 class="text-base font-bold whitespace-nowrap">{@value.name}</h1>
          <%= for {platform, icon} <- social_links(),
                      url = social_link(@value, platform),
                      not is_nil(url) do %>
            <.link href={url} target="_blank" class="text-muted-foreground hover:text-foreground">
              <.icon name={icon} class="size-5" />
            </.link>
          <% end %>
        </div>
        <%= if @value.domain do %>
          <p class="text-muted-foreground line-clamp-1 font-medium text-sm">
            {@value.domain}
          </p>
        <% else %>
          <p class="text-destructive-400 line-clamp-1 font-medium text-sm">
            Domain not found
          </p>
        <% end %>
      </div>
    </div>
    """
  end

  defp cell(%{value: value} = assigns) when is_list(value) do
    ~H"""
    <div class="flex gap-2 whitespace-nowrap">
      <%= for item <- @value do %>
        <.badge>{item}</.badge>
      <% end %>
    </div>
    """
  end

  defp cell(%{value: %DateTime{}} = assigns) do
    ~H"""
    <span :if={@timezone} class="tabular-nums whitespace-nowrap text-sm">
      {Calendar.strftime(
        DateTime.from_naive!(@value, "Etc/UTC") |> DateTime.shift_zone!(@timezone),
        "%Y/%m/%d, %H:%M:%S"
      )}
    </span>
    """
  end

  defp cell(%{value: "http" <> _value} = assigns) do
    ~H"""
    <.link href={@value} target="_blank" class="text-foreground">
      {@value}
    </.link>
    """
  end

  defp cell(assigns) do
    ~H"""
    <span class="text-sm whitespace-nowrap">
      {@value}
    </span>
    """
  end

  defp assign_csv_data(socket, data) do
    all_rows =
      case String.trim(data) do
        "" -> []
        csv_string -> [csv_string] |> CSV.decode!() |> Enum.to_list()
      end

    {cols, rows} =
      case all_rows do
        [] ->
          {[], []}

        [cols | rows] ->
          {cols, rows}
      end

    rows =
      rows
      |> Enum.map(fn row -> Enum.zip_reduce(cols, row, Map.new(), fn col, val, acc -> Map.put(acc, col, val) end) end)
      |> Enum.map(&process_row/1)

    rows
    |> Enum.uniq_by(&lookup_key/1)
    |> Task.async_stream(&get_user/1, max_concurrency: 10, timeout: :infinity)

    rows = Enum.map(rows, &Map.put(&1, "org", get_user(&1)))

    socket
    |> assign(:csv_data, rows)
    |> assign(:csv_columns, ["org" | cols])
  end

  defp assign_preview(socket) do
    assign_csv_data(
      socket,
      case apply_action(socket.assigns.form.source, :save) do
        {:ok, data} -> data.csv
        {:error, _changeset} -> ""
      end
    )
  end

  defp lookup_key(%{"org_handle" => handle} = _row) when is_binary(handle) and handle != "" do
    handle
  end

  defp lookup_key(%{"company_url" => url} = _row) when is_binary(url) and url != "" do
    to_domain(url)
  end

  defp run_cached(key, fun) do
    case :ets.lookup(@user_cache_table, key) do
      [{_, user}] ->
        user

      _ ->
        case fun.() do
          {:ok, user} ->
            :ets.insert(@user_cache_table, {key, user})
            user

          error ->
            Logger.error("Failed to fetch user #{key}: #{inspect(error)}")
            :ets.insert(@user_cache_table, {key, nil})
            nil
        end
    end
  end

  defp get_user(%{"org_handle" => handle} = _row) when is_binary(handle) and handle != "" do
    run_cached(handle, fn ->
      with {:ok, user} <- Workspace.ensure_user(Algora.Admin.token(), handle) do
        Repo.fetch(User, user.id)
      end
    end)
  end

  defp get_user(%{"company_url" => url} = row) when is_binary(url) and url != "" do
    domain = to_domain(url)

    run_cached(domain, fn ->
      with {:ok, user} <- fetch_or_create_user(domain, %{hiring: true, tech_stack: row["tech_stack"]}) do
        Repo.fetch(User, user.id)
      end
    end)
  end

  defp get_user(_row), do: nil

  def fetch_or_create_user(domain, opts) do
    case Repo.one(from o in User, where: o.domain == ^domain, limit: 1) do
      %User{} = user ->
        {:ok, user}

      _ ->
        res = Organizations.onboard_organization_from_domain(domain, opts)
        res
    end
  end

  defp list_from_string(s) when is_binary(s) and s != "" do
    s
    |> String.split(",")
    |> Enum.map(&String.trim/1)
    |> Enum.reject(&(&1 == ""))
  end

  defp list_from_string(_s), do: []

  defp money_from_string(s) when is_binary(s) and s != "" do
    s
    |> Decimal.new()
    |> Money.new!(:USD)
  end

  defp money_from_string(_s), do: nil

  defp process_row(row) do
    Map.merge(row, %{
      "tech_stack" =>
        cond do
          row["tech_stack"] != "" -> list_from_string(row["tech_stack"])
          row["org"] -> Enum.take(row["org"].tech_stack, 1)
          true -> []
        end,
      "countries" => list_from_string(row["countries"]),
      "regions" => list_from_string(row["regions"]),
      "price" => money_from_string(row["price"])
    })
  end

  defp seed_rows(rows) do
    Repo.transact(
      fn ->
        rows
        |> Enum.filter(& &1["org"])
        |> Enum.map(&seed_row/1)
        |> Enum.reduce_while(:ok, fn result, _acc ->
          case result do
            {:ok, _job} -> {:cont, :ok}
            {:error, reason} -> {:halt, {:error, reason}}
          end
        end)
      end,
      timeout: :infinity
    )
  end

  defp to_domain(nil), do: nil

  defp to_domain(url) do
    url
    |> String.trim_leading("https://")
    |> String.trim_leading("http://")
    |> String.trim_leading("www.")
  end

  defp seed_row(row) do
    with {:ok, org} <- Repo.fetch(User, row["org"].id),
         {:ok, org} <-
           org
           |> change(
             Map.merge(
               %{
                 domain: org.domain || to_domain(row["website_url"]),
                 hiring_subscription: :trial,
                 subscription_price: row["price"],
                 billing_name: org.billing_name || row["billing_name"],
                 billing_address: org.billing_address || row["billing_address"],
                 executive_name: org.executive_name || row["executive_name"],
                 executive_role: org.executive_role || row["executive_role"]
               },
               if org.handle do
                 %{}
               else
                 %{handle: Organizations.ensure_unique_org_handle(row["org_handle"])}
               end
             )
           )
           |> Repo.update() do
      Repo.insert(%JobPosting{
        status: :processing,
        id: Nanoid.generate(),
        user_id: org.id,
        company_name: org.name,
        company_url: org.website_url,
        title: row["title"],
        url: row["url"],
        description: row["description"],
        tech_stack: row["tech_stack"],
        location: row["location"],
        compensation: row["compensation"],
        seniority: row["seniority"],
        countries: row["countries"],
        regions: row["regions"]
      })
    end
  end

  defp social_links do
    [
      {:website, "tabler-world"},
      {:github, "github"},
      {:twitter, "tabler-brand-x"},
      {:youtube, "tabler-brand-youtube"},
      {:twitch, "tabler-brand-twitch"},
      {:discord, "tabler-brand-discord"},
      {:slack, "tabler-brand-slack"},
      {:linkedin, "tabler-brand-linkedin"}
    ]
  end

  defp social_link(user, :github), do: if(login = user.provider_login, do: "https://github.com/#{login}")
  defp social_link(user, platform), do: Map.get(user, :"#{platform}_url")
end
