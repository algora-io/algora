defmodule Algora.ChatTest do
  use Algora.DataCase
  use Oban.Testing, repo: Algora.Repo

  alias Algora.Chat

  describe "chat" do
    test "direct" do
      user_1 = insert(:user)
      user_2 = insert(:user)
      {:ok, thread} = Chat.create_direct_thread(user_1, user_2)
      {:ok, message_1} = Chat.send_message(thread.id, user_1.id, "hello")
      {:ok, message_2} = Chat.send_message(thread.id, user_2.id, "there")
      assert thread.id |> Chat.list_messages() |> Enum.map(& &1.id) == [message_1.id, message_2.id]
      assert Chat.mark_as_read(thread.id, user_1.id) == {1, nil}
      assert Chat.get_thread_for_users(user_1.id, user_2.id).id == thread.id
      assert user_1.id |> Chat.list_threads() |> Enum.map(& &1.id) == [thread.id]
      assert user_2.id |> Chat.list_threads() |> Enum.map(& &1.id) == [thread.id]
    end

    test "contract" do
      client = insert(:user)
      contractor = insert(:user)
      contract = insert(:contract, client: client, contractor: contractor)
      thread = Chat.get_or_create_thread!(contract)
      assert Chat.get_or_create_thread!(contract).id == thread.id
      assert client.id |> Chat.list_threads() |> Enum.map(& &1.id) == [thread.id]
      assert contractor.id |> Chat.list_threads() |> Enum.map(& &1.id) == [thread.id]
    end
  end
end
