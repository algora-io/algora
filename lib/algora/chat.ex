defmodule Algora.Chat do
  import Ecto.Query
  alias Algora.Repo
  alias Algora.Chat.{Thread, Message, Participant}

  def create_direct_thread(user_1, user_2) do
    Repo.transaction(fn ->
      {:ok, thread} =
        %Thread{}
        |> Thread.changeset(%{title: "#{user_1.handle} <> #{user_2.handle}"})
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

  def send_message(thread_id, sender_id, content) do
    %Message{}
    |> Message.changeset(%{
      thread_id: thread_id,
      sender_id: sender_id,
      content: content
    })
    |> Repo.insert()
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

  def get_thread_for_users(user1_id, user2_id) do
    Thread
    |> join(:inner, [t], p in Participant, on: p.thread_id == t.id)
    |> where([t, p], p.user_id in [^user1_id, ^user2_id])
    |> group_by([t], t.id)
    |> having([t, p], count(p.id) == 2)
    |> limit(1)
    |> Repo.one()
  end

  def get_or_create_thread(contract) do
    case get_thread_for_users(contract.client_id, contract.contractor_id) do
      nil -> create_direct_thread(contract.client, contract.contractor)
      thread -> {:ok, thread}
    end
  end

  def get_or_create_thread!(contract) do
    {:ok, thread} = get_or_create_thread(contract)
    thread
  end
end
