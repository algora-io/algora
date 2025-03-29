<!-- PROJECT LOGO -->
<p align="center">
  <a href="https://github.com/algora-io/console">
   <img src="https://user-images.githubusercontent.com/17045339/231901505-2936b331-3716-4418-9386-4a5d9cb694ba.svg" alt="Logo">
  </a>

  <h3 align="center">Algora Console</h3>

  <p align="center">
    Algora is a developer tool & community simplifying bounties, hiring & open source sustainability.
    <br/>
    <a href="https://algora.io">Website</a>
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
    <a href="https://algora.io/org/algora/bounties?status=open">
      <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Falgora.io%2Fapi%2Fshields%2Falgora%2Fbounties%3Fstatus%3Dopen" alt="Open Bounties">
    </a>
    <a href="https://algora.io/org/algora/bounties?status=completed">
      <img src="https://img.shields.io/endpoint?url=https%3A%2F%2Falgora.io%2Fapi%2Fshields%2Falgora%2Fbounties%3Fstatus%3Dcompleted" alt="Rewarded Bounties">
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

10. (Optional) Watch for file changes and auto reload IEx shell in a separate terminal

    ```sh
    find lib/ | entr mix compile
    ```

### Setting up external services

Some features of Algora rely on external services. If you're not planning on using these features, feel free to skip setting them up.

#### GitHub

[Register new GitHub app](https://github.com/settings/apps/new) and set

- Homepage URL: http://localhost:4000
- Callback URL: http://localhost:4000/callbacks/github/oauth
- Setup URL: http://localhost:4000/callbacks/github/installation
- Redirect on update: Yes
- Webhook URL: https://[your-public-proxy]/webhooks/github (e.g. ngrok, Cloudflare Tunnel)
- Secret: [generate new random string]
- Permissions:
  - Read & write issues
  - Read & write pull requests
  - Read account email address
- Events: issues, pull requests, issue comment, pull request review, pull request review comment

Once you have obtained your client ID and secret, add them to your `.env` file and run `direnv allow .env`

```env
GITHUB_CLIENT_ID=""
GITHUB_CLIENT_SECRET=""
GITHUB_APP_HANDLE=""
GITHUB_APP_ID=""
GITHUB_WEBHOOK_SECRET=""
GITHUB_PRIVATE_KEY=""
```

#### Stripe

[Create new Stripe account](https://dashboard.stripe.com/register) to obtain your secrets and add them to your `.env` file.

```env
STRIPE_PUBLISHABLE_KEY=""
STRIPE_SECRET_KEY=""
STRIPE_WEBHOOK_SECRET=""
```

#### Object Storage

To host static assets, set up a public bucket on your preferred S3-compatible storage service and add the following credentials to your `.env` file:

```env
AWS_ENDPOINT_URL_S3=""
AWS_REGION=""
AWS_ACCESS_KEY_ID=""
AWS_SECRET_ACCESS_KEY=""
BUCKET_NAME=""
```
