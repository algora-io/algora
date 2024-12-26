<!-- PROJECT LOGO -->
<p align="center">
  <a href="https://github.com/algora-io/console">
   <img src="https://user-images.githubusercontent.com/17045339/231901505-2936b331-3716-4418-9386-4a5d9cb694ba.svg" alt="Logo">
  </a>

  <h3 align="center">Algora Console</h3>

  <p align="center">
    Algora is a developer tool & community simplifying bounties, hiring & open source sustainability.
    <br/>
    <a href="https://console.algora.io">Website</a>
    ·
    <a href="https://algora.io/discord">Discord</a>
    ·
    <a href="https://twitter.com/algoraio">Twitter</a>
    ·
    <a href="https://www.youtube.com/@algora-io">YouTube</a>
    ·
    <a href="https://github.com/algora-io/console/issues">Issues</a>
  </p>

  <p align="center">
    <a href="https://console.algora.io/org/algora/bounties?status=open">
      <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fconsole.algora.io%2Fapi%2Fshields%2Falgora%2Fbounties%3Fstatus%3Dopen" alt="Open Bounties">
    </a>
    <a href="https://console.algora.io/org/algora/bounties?status=completed">
      <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Fconsole.algora.io%2Fapi%2Fshields%2Falgora%2Fbounties%3Fstatus%3Dcompleted" alt="Rewarded Bounties">
    </a>
  </p>
</p>

<!-- GETTING STARTED -->

## Getting Started

To get a local copy up and running, follow these steps.

### Prerequisites

- PostgreSQL
- [asdf](https://github.com/asdf-vm/asdf) (optional) - install Elixir and Erlang/OTP
- [direnv](https://github.com/direnv/direnv) (optional) - load environment variables

### Setting up the project

1. Clone the repo and go to the project folder

   ```sh
   git clone https://github.com/algora-io/console.git; cd console
   ```

2. Install Elixir and Erlang/OTP

   ```sh
   asdf install
   ```

3. Fetch dependencies

   ```sh
   mix deps.get
   ```

   **Note:** If you're using an Apple machine with an ARM-based chip, you need to install the Rust compiler and run `mix compile.rambo`

4. Initialize your `.env` file

   ```sh
   cp .env.example .env
   ```

5. Create your database

   ```sh
   sudo -u postgres psql
   ```

   ```sql
   CREATE USER algora WITH PASSWORD 'password';
   ALTER USER algora WITH CREATEDB;
   ```

6. Paste your connection string into your `.env` file

   ```env
   DATABASE_URL="postgresql://algora:password@localhost:5432/console"
   ```

7. Allow direnv to load the `.env` file

   ```sh
   direnv allow .env
   ```

8. Run migrations and seed your database

   ```sh
   mix ecto.setup
   ```

9. Start your development server

   ```sh
   iex -S mix phx.server
   ```

10. (Optional) Watch for file changes and auto-recompile in a separate terminal

    ```sh
    find lib/ | entr mix compile
    ```

### Setting up external services

Some features of Algora Console rely on external services. If you're not planning on using these features, feel free to skip setting them up.

#### GitHub

GitHub is used for authenticating users.

[Create a GitHub OAuth app](https://github.com/settings/applications/new) and set

- Homepage URL: http://localhost:4000
- Authorization callback URL: http://localhost:4000/callbacks/github/oauth

Once you have obtained your client ID and secret, add them to your `.env` file and run `direnv allow .env`

```env
GITHUB_CLIENT_ID=""
GITHUB_CLIENT_SECRET="..."
```
