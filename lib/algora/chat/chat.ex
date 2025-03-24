defmodule Algora.Chat do
  @moduledoc false
  import Ecto.Query

  alias Algora.Accounts.User
  alias Algora.Chat.Message
  alias Algora.Chat.Participant
  alias Algora.Chat.Thread
  alias Algora.Repo

  def broadcast(message) do
    Phoenix.PubSub.broadcast(Algora.PubSub, "chat:thread:#{message.thread_id}", message)
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

      # Add participants
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
      # Add participants
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

  def send_message(thread_id, sender_id, content) do
    case %Message{}
         |> Message.changeset(%{
           thread_id: thread_id,
           sender_id: sender_id,
           content: content
         })
         |> Repo.insert() do
      {:ok, message} ->
        message |> Repo.preload(:sender) |> broadcast()
        {:ok, message}

      {:error, changeset} ->
        {:error, changeset}
    end
  end

  def list_messages(thread_id, limit \\ 50) do
    Message
    |> where(thread_id: ^thread_id)
    |> order_by(asc: :inserted_at)
    |> limit(^limit)
    |> Repo.all()
  end

  def list_threads(user_id) do
    Thread
    |> join(:inner, [t], p in Participant, on: p.thread_id == t.id)
    |> where([_t, p], p.user_id == ^user_id)
    |> preload(:participants)
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
end
