defmodule Algora.Chat do
  @moduledoc false
  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.Chat.Message
  alias Algora.Chat.Participant
  alias Algora.Chat.Thread
  alias Algora.Repo

  defmodule MessageCreated do
    @moduledoc false
    defstruct message: nil, participant: nil
  end

  def broadcast(%MessageCreated{} = event) do
    Phoenix.PubSub.broadcast(Algora.PubSub, "chat:thread:#{event.message.thread_id}", event)
  end

  def subscribe(thread_id) do
    Phoenix.PubSub.subscribe(Algora.PubSub, "chat:thread:#{thread_id}")
  end

  def create_direct_thread(user_1, user_2) do
    Repo.transaction(fn ->
      {:ok, thread} =
        %Thread{}
        |> Thread.changeset(%{title: "#{User.handle(user_1)} <> #{User.handle(user_2)}"})
        |> Repo.insert()

      for user <- [user_1, user_2] do
        %Participant{}
        |> Participant.changeset(%{
          thread_id: thread.id,
          user_id: user.id,
          last_read_at: DateTime.utc_now()
        })
        |> Repo.insert!()
      end

      thread
    end)
  end

  def create_admin_thread(user, admins) do
    Repo.transaction(fn ->
      {:ok, thread} =
        %Thread{}
        |> Thread.changeset(%{title: "Chat with Algora founders"})
        |> Repo.insert()

      participants = Enum.uniq_by([user | admins], & &1.id)

      for u <- participants do
        %Participant{}
        |> Participant.changeset(%{
          thread_id: thread.id,
          user_id: u.id,
          last_read_at: DateTime.utc_now()
        })
        |> Repo.insert!()
      end

      thread
    end)
  end

  defp ensure_participant(thread_id, user_id) do
    case Repo.fetch_by(Participant, thread_id: thread_id, user_id: user_id) do
      {:ok, participant} ->
        {:ok, participant}

      {:error, _} ->
        %Participant{}
        |> Participant.changeset(%{
          thread_id: thread_id,
          user_id: user_id,
          last_read_at: DateTime.utc_now()
        })
        |> Repo.insert()
    end
  end

  defp insert_message(thread_id, sender_id, content) do
    %Message{}
    |> Message.changeset(%{
      thread_id: thread_id,
      sender_id: sender_id,
      content: content
    })
    |> Repo.insert()
  end

  def send_message(thread_id, sender_id, content) do
    with {:ok, participant} <- ensure_participant(thread_id, sender_id),
         {:ok, message} <- insert_message(thread_id, sender_id, content) do
      message = Repo.preload(message, :sender)

      broadcast(%MessageCreated{
        message: message,
        participant: Repo.preload(participant, :user)
      })

      Algora.Admin.alert(
        "Message received by #{message.sender.email}: #{AlgoraWeb.Endpoint.url()}/admin/chat/#{thread_id}",
        :info
      )

      {:ok, message}
    end
  end

  def list_messages(thread_id, limit \\ 50) do
    Message
    |> where(thread_id: ^thread_id)
    |> order_by(asc: :inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  def get_thread(thread_id) do
    Repo.get(Thread, thread_id)
  end

  # TODO: filter by user_id
  def list_threads(_user_id) do
    last_message_query =
      from m in Message,
        select: %{
          thread_id: m.thread_id,
          last_message_at: max(m.inserted_at)
        },
        group_by: m.thread_id

    Thread
    |> join(:left, [t], lm in subquery(last_message_query), on: t.id == lm.thread_id)
    |> order_by([t, lm], desc: lm.last_message_at)
    |> preload(participants: :user)
    |> Repo.all()
  end

  def list_participants(thread_id) do
    Participant
    |> where(thread_id: ^thread_id)
    |> Repo.all()
  end

  def mark_as_read(thread_id, user_id) do
    Participant
    |> where(thread_id: ^thread_id, user_id: ^user_id)
    |> Repo.update_all(set: [last_read_at: DateTime.utc_now()])
  end

  def get_thread_for_users(users) do
    participants = Enum.uniq_by(users, & &1.id)

    Thread
    |> join(:inner, [t], p in Participant, on: p.thread_id == t.id)
    |> where([t, p], p.user_id in ^Enum.map(participants, & &1.id))
    |> group_by([t], t.id)
    |> having([t, p], count(p.id) == ^length(participants))
    |> limit(1)
    |> Repo.one()
  end

  def get_or_create_thread(contract) do
    case get_thread_for_users([contract.client, contract.contractor]) do
      nil -> create_direct_thread(contract.client, contract.contractor)
      thread -> {:ok, thread}
    end
  end

  def get_or_create_thread!(contract) do
    {:ok, thread} = get_or_create_thread(contract)
    thread
  end

  def get_or_create_admin_thread(current_user) do
    admins = Repo.all(from u in User, where: u.is_admin == true)

    case get_thread_for_users([current_user] ++ admins) do
      nil -> create_admin_thread(current_user, admins)
      thread -> {:ok, thread}
    end
  end

  def get_or_create_bounty_thread(bounty) do
    case Repo.fetch_by(Thread, bounty_id: bounty.id) do
      {:ok, thread} ->
        {:ok, thread}

      {:error, _} ->
        %Thread{}
        |> Thread.changeset(%{title: "Contributor chat", bounty_id: bounty.id})
        |> Repo.insert()
    end
  end
end
