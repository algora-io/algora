<!-- PROJECT LOGO -->
<p align="center">
  <a href="https://algora.io">
    <img src="https://algora.io/images/og/home.png" alt="Homepage">
  </a>

  <h3 align="center">Algora</h3>

  <p align="center">
  The open source Upwork for engineers
    <!-- Discover GitHub bounties, contract work and jobs. Hire the top 1% open source developers. -->
    <br/>
    <a href="https://algora.io">Website</a>
    ·
    <a href="https://algora.io/docs">Docs</a>
    ·
    <a href="https://algora.io/discord">Discord</a>
    ·
    <a href="https://twitter.com/algoraio">Twitter</a>
    ·
    <a href="https://www.youtube.com/@algora-io">YouTube</a>
    ·
    <a href="https://github.com/algora-io/console/issues">Issues</a>
  </p>

</p>

Algora exists to reduce the friction in hiring, collaborating and paying open source developers.

Algora combines:

- a GitHub app to reward bounties and tips on issues/PRs
- a payment processor to handle payouts, compliance & 1099s
- a web app for sharing bounties, contracts and jobs
- a history of transactions, invoices and peer reviews
- a marketplace to meet and collaborate with top contributors

| Use with your                | Benefit                                           |
| ---------------------------- | ------------------------------------------------- |
| **open source community**    | fund, solve and reward bounties on GitHub issues  |
| **contractors**              | manage work and complete outcome based payments   |
| **job candidates**           | collaborate on paid projects for interviews       |
| **teammates**                | run an internal bounty program for fun and profit |
| **Algora community experts** | get work done and grow your team                  |

<table>

  <!-- Dashboards -->
  <tr>
    <td align="center">
      <img src="https://algora.io/images/screenshots/user-dashboard.png" alt="User Dashboard" width="1000">
    </td>
    <td align="center">
      <img src="https://algora.io/images/screenshots/org-dashboard.png" alt="Organization Dashboard" width="1000">
    </td>
  </tr>

  <!-- Payments & Transactions -->
  <tr>
    <td align="center">
      <img src="https://algora.io/images/screenshots/global-payments.png" alt="Global Payments" width="1000">
    </td>
    <td align="center">
      <img src="https://algora.io/images/docs/dashboard-pending-payments.png" alt="Pending Payments" width="1000">
    </td>
  </tr>

  <!-- Embeds -->
  <tr>
   <td align="center">
      <img src="https://algora.io/images/screenshots/og-bounty-board.png" alt="Bounty Board" width="1000">
    </td>
    <td align="center">
      <img src="https://algora.io/images/screenshots/og-crowdfund.png" alt="Crowdfund" width="1000">
    </td>
  </tr>
    <tr>
    <td align="center">
      <img src="https://algora.io/images/screenshots/og-profile.png" alt="User Profile" width="1000">
    </td>
    <td align="center">
      <img src="https://algora.io/images/screenshots/embed-profile.png" alt="Embed Profile" width="1000">
    </td>
  </tr>

  <!-- Bounty Creation & Management -->
  <tr>
    <td align="center">
      <img src="https://algora.io/images/docs/create-custom-bounty.png" alt="Create Custom Bounty" width="1000">
    </td>
    <td align="center">
      <img src="https://algora.io/images/docs/view-custom-bounty.png" alt="View Custom Bounty" width="1000">
    </td>
  </tr>

  <!-- Tips -->
  <tr>
    <td align="center">
      <img src="https://algora.io/images/docs/create-tip-on-algora-1.png" alt="Create Tip Step 1" width="1000">
    </td>
    <td align="center">
      <img src="https://algora.io/images/docs/create-tip-on-algora-2.png" alt="Create Tip Step 2" width="1000">
    </td>
  </tr>
</table>

<!-- GETTING STARTED -->

## Getting Started

To get a local copy up and running, follow these steps.

### Prerequisites

The easiest way to get up and running is to [install](https://docs.docker.com/get-docker/) and use Docker for running Postgres.

Make sure Docker, Elixir, Erlang and Node.js are all installed on your development machine. The [.tool-versions](https://github.com/algora-io/algora/blob/main/.tool-versions) file is available to use with [asdf](https://github.com/asdf-vm/asdf) or similar tools.

We also recommend using [direnv](https://github.com/direnv/direnv) to load environment variables and [entr](https://github.com/eradman/entr) to watch for file changes.

### Setting up the project

1. Clone the repo and go to the project folder

   ```sh
   git clone git@github.com:algora-io/algora.git && cd algora
   ```

2. Install Elixir and Erlang/OTP

   ```sh
   asdf install
   ```

3. Initialize and load `.env`

   ```sh
   cp .env.example .env && direnv allow .env
   ```

4. Start a container with latest postgres

   ```sh
   make postgres
   ```

5. Install and setup dependencies

   ```sh
   make install
   ```

6. Start the web server inside IEx

   ```sh
   make server
   ```

7. (Optional) Watch for file changes and auto reload IEx shell in a separate terminal

   ```sh
   make watch
   ```

### Setting up external services

Some features of Algora rely on external services. If you're not planning on using these features, feel free to skip setting them up.

#### Tunnel

To receive webhooks from GitHub or Stripe on your local machine, you'll need a way to expose your local server to the internet. The easiest way to get up and running is to use a tool like [ngrok](https://ngrok.com/) or [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/).

Here's how you can setup a re-usable named tunnel on your own domain name so you have a consistent URL:

```sh
cloudflared tunnel login
cloudflared tunnel create local
cloudflared tunnel route dns local http://local.yourdomain.com
```

Once you have setup your tunnel, add it to your `.env` file and run `direnv allow .env`.

```env
CLOUDFLARE_TUNNEL="local"
```

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

Once you have obtained your client ID and secret, add them to your `.env` file.

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
