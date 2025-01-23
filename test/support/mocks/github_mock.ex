defmodule Algora.Mocks.GithubMock do
  @moduledoc false
  import Mox

  def setup_installation_token do
    stub(
      Algora.GithubMock,
      :get_installation_token,
      fn _installation_id -> {:ok, "mock-token"} end
    )
  end

  def setup_repository_permissions do
    stub(
      Algora.GithubMock,
      :get_repository_permissions,
      fn _token, _owner, _repo, _user -> {:ok, %{"permission" => "none"}} end
    )
  end

  def setup_create_issue_comment do
    stub(
      Algora.GithubMock,
      :create_issue_comment,
      fn _token, _owner, _repo, _issue_number, _body -> {:ok, %{"id" => random_id()}} end
    )
  end

  def setup_get_user_by_username do
    stub(
      Algora.GithubMock,
      :get_user_by_username,
      fn _token, username -> {:ok, %{"id" => random_id(), "login" => username}} end
    )
  end

  def setup_get_issue do
    stub(
      Algora.GithubMock,
      :get_issue,
      fn _token, owner, repo, issue_number ->
        {:ok,
         %{
           "id" => random_id(),
           "number" => issue_number,
           "title" => "Test Issue",
           "body" => "Test body",
           "html_url" => "https://github.com/#{owner}/#{repo}/issues/#{issue_number}"
         }}
      end
    )
  end

  def setup_get_repository do
    stub(
      Algora.GithubMock,
      :get_repository,
      fn _token, owner, repo ->
        {:ok,
         %{
           "id" => random_id(),
           "name" => repo,
           "html_url" => "https://github.com/#{owner}/#{repo}"
         }}
      end
    )
  end

  defp random_id(n \\ 1000), do: :rand.uniform(n)
end
