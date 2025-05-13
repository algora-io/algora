<!-- PROJECT LOGO -->
<p align="center">
  <a href="https://algora.io">
    <img src="https://algora.io/images/og/home.png?v=2" alt="Homepage">
  </a>

  <h4 align="center">Hire the top 1% open source engineers</h4>

  <p align="center">
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

Algora connects **companies** and **developers** for full-time and contract work.

This codebase consists of the following:

- a **web app** to publish & manage SWE jobs, contracts & bounties
- a **GitHub app** to create bounties & reward tips on issues and PRs
- a **payment processor** to handle payouts, compliance & 1099s

OSS communities and closed source teams can **self-host** or join **[Algora.io](https://algora.io)** to accomplish the following:

| Use with your                | Benefit                                           |
| ---------------------------- | ------------------------------------------------- |
| **open source community**    | reward open source contributors & maintainers     |
| **contractors**              | manage work and complete outcome based payments   |
| **job candidates**           | collaborate on paid projects for interviews       |
| **teammates**                | run an internal bounty program for fun and profit |

**[Algora.io](https://algora.io)**, hosted by Algora Public Benefit Corporation, extends functionalities including:

- developers' top OSS contributions are automatically displayed on their Algora profiles
- companies' job applicants are automatically screened & ranked for OSS contributions
- companies and developers are automatically matched for full-time & contract work based on tech/budget/location preferences

**[Algora.io](https://algora.io)** is a complete solution for sourcing, screening, interviewing & onboarding engineers to your team.

| Hiring proces                | Benefit                                           |
| ---------------------------- | ------------------------------------------------- |
| **sourcing**                 | publish jobs to 50K+ developers, access matches   |
| **screening**                | auto screen job applicants for OSS contributions  |
| **interviewing**             | trial your candidates using bounties & contracts  |
| **onboarding**               | contribute-first hires are productive on day 1    |

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

<!-- ROADMAP -->

## Roadmap & community requests

- Profile Embed
  - Embeddable profile for GitHub and personal websites
  - One-click bounty and contract sharing
- Apply Embed
  - One-click apply embed for careers pages
- New payment/payout options
  - Alipay, Wise, crypto etc.
- Localization of platform & matches
- New workflow integrations
  - GitLab, Linear, Plane, Cursor etc.
- New clients
  - Mobile, desktop, CLI
- Crowdfunding enhancements

<!-- GETTING STARTED -->

## Getting Started

### Prerequisites

The easiest way to get up and running is to [install](https://docs.docker.com/get-docker/) and use Docker for running Postgres.

Make sure Docker, Elixir, Erlang and Node.js are all installed on your development machine. You can install Elixir and Erlang/OTP by running [`asdf install`](https://github.com/asdf-vm/asdf) from the project root.

We also recommend using [direnv](https://github.com/direnv/direnv) to load environment variables and [entr](https://github.com/eradman/entr) to watch for file changes.

### Setting up the project

1. Clone the repo and go to the project folder

   ```sh
   git clone git@github.com:algora-io/algora.git && cd algora
   ```

2. Initialize and load `.env`

   ```sh
   cp .env.example .env && direnv allow .env
   ```

3. Start a container with latest postgres

   ```sh
   make postgres
   ```

4. Install and setup dependencies

   ```sh
   make install
   ```

5. Start the web server inside IEx

   ```sh
   make server
   ```

6. (Optional) Watch for file changes and auto reload IEx shell in a separate terminal

   ```sh
   make watch
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

Once you have obtained your client ID and secret, add them to your `.env` file and run `direnv allow .env`.

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

#### Tunnel

To receive webhooks from GitHub or Stripe on your local machine, you'll need a way to expose your local server to the internet. The easiest way is to use a service like [Cloudflare Tunnel](https://developers.cloudflare.com/cloudflare-one/connections/connect-networks/) or [ngrok](https://ngrok.com/).

If you'd like to utilize our Cloudflare Tunnel [GenServer](https://github.com/algora-io/algora/blob/main/lib/algora/integrations/tunnel.ex) to automatically run a tunnel when you start the app, you'll need to set up a named tunnel on your own domain:

```sh
cloudflared tunnel login
cloudflared tunnel create local
cloudflared tunnel route dns local http://local.yourdomain.com
```

And then add it to your `.env` file:

```env
CLOUDFLARE_TUNNEL="local"
```

If you're using another service, make sure to start the tunnel manually in another terminal.
