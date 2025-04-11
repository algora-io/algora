---
title: "SDK"
---

# Algora Typescript SDK

![npm (scoped)](https://img.shields.io/npm/v/@algora/sdk)

## Showcase

### [Cal.com Jobs](https://cal.com/jobs)

<a href="https://cal.com/jobs"><img src="https://raw.githubusercontent.com/algora-io/sdk/assets/bounties/calcom.png" alt="Cal.com Jobs" width="500" /></a>

### [Remotion Docs](https://www.remotion.dev/docs/contributing/bounty) via [remotion-dev/remotion#2949](https://github.com/remotion-dev/remotion/pull/2949)

<a href="https://www.remotion.dev/docs/contributing/bounty"><img src="https://raw.githubusercontent.com/algora-io/sdk/assets/bounties/remotion.png" alt="Remotion Docs" width="500" /></a>

### [Tembo Blog](https://tembo.io/blog/algora-code-bounties) via [tembo-io/website#678](https://github.com/tembo-io/website/pull/678)

<a href="https://tembo.io/blog/algora-code-bounties"><img src="https://raw.githubusercontent.com/algora-io/sdk/assets/bounties/tembo.png" alt="Tembo Blog" width="500" /></a>

### [Million.js Blog](https://old.million.dev/blog/million-v2.5.1) via [aidenybai/million#492](https://github.com/aidenybai/million/pull/492)

<a href="https://old.million.dev/blog/million-v2.5.1"><img src="https://raw.githubusercontent.com/algora-io/sdk/assets/bounties/millionjs.png" alt="Million.js Blog" width="500" /></a>

## Installation

### Option 1: Package manager

Install the SDK with the package manager of your choice (npm, yarn, pnpm...)

```bash
npm install @algora/sdk
```

```ts
import { algora } from "@algora/sdk";
const { items, next_cursor } = await algora.bounty.list.query({ org: "acme" });
```

### Option 2: CDN

Alternatively, you can use the CDN bundle by adding these tags to your HTML:

```html
<script src="https://cdn.jsdelivr.net/npm/@algora/sdk@0.3.1/dist/index.global.js"></script>
<link
  href="https://cdn.jsdelivr.net/npm/@algora/sdk@0.3.1/dist/index.css"
  rel="stylesheet"
/>

<div
  class="bounty-board"
  data-bounty-org="acme"
  data-bounty-limit="6"
  data-bounty-status="active"
></div>
```

## Quickstart

<details>
  <summary><h3>Bounty board (HTML & CSS)</h3></summary>

Add these tags to the `<head>` of your HTML:

```html
<script src="https://cdn.jsdelivr.net/npm/@algora/sdk@0.3.1/dist/index.global.js"></script>
<link
  href="https://cdn.jsdelivr.net/npm/@algora/sdk@0.3.1/dist/index.css"
  rel="stylesheet"
/>
```

Add a container for the bounty board to the `<body>` of your HTML:

```html
<div
  class="bounty-board"
  data-bounty-org="acme"
  data-bounty-limit="6"
  data-bounty-status="active"
></div>
```

Customize the styling as you like:

```css
.bounty-board {
  max-width: 800px;
  font-family: "Inter";
  --line-clamp: 2;
  --accent-50: 226, 100%, 97%;
  --accent-100: 226, 100%, 94%;
  --accent-200: 228, 96%, 89%;
  --accent-300: 230, 94%, 82%;
  --accent-400: 234, 89%, 74%;
  --accent-500: 239, 84%, 67%;
  --accent-600: 243, 75%, 59%;
  --accent-700: 245, 58%, 51%;
  --accent-800: 244, 55%, 41%;
  --accent-900: 242, 47%, 34%;
  --accent-950: 244, 47%, 20%;
}
```

</details>

<details>
  <summary><h3>Bounty board (React & Tailwind)</h3></summary>

```tsx
import { useEffect, useState } from "react";
import { algora, type AlgoraOutput } from "@algora/sdk";
import Link from "next/link";

// TODO: Use your own Algora handle
const org = "acme";
const limit = 3;

type RemoteData<T> =
  | { _tag: "loading" }
  | { _tag: "failure"; error: Error }
  | { _tag: "success"; data: T };

type Bounty = AlgoraOutput["bounty"]["list"]["items"][number];

export function Bounties() {
  const [bounties, setBounties] = useState<RemoteData<Bounty[]>>({
    _tag: "loading",
  });

  useEffect(() => {
    const ac = new AbortController();

    algora.bounty.list
      .query({ org, limit, status: "active" }, { signal: ac.signal })
      .then(({ items: data }) => setBounties({ _tag: "success", data }))
      .catch((error) => setBounties({ _tag: "failure", error }));

    return () => ac.abort();
  }, []);

  return (
    <div className="space-y-2">
      <Callout />
      <ul className="grid sm:grid-cols-3 gap-2">
        {bounties._tag === "success" &&
          bounties.data.map((bounty) => (
            <li key={bounty.id}>
              <BountyCard bounty={bounty} />
            </li>
          ))}
        {bounties._tag === "loading" &&
          [...Array(limit)].map((_, i) => (
            <li key={i}>
              <BountyCardSkeleton />
            </li>
          ))}
      </ul>
    </div>
  );
}

function BountyCard(props: { bounty: Bounty }) {
  return (
    <Link
      href={props.bounty.task.url}
      target="_blank"
      rel="noopener"
      className="block group relative h-full rounded-lg border border-gray-400/50 dark:border-indigo-500/50 bg-gradient-to-br from-gray-300/30 via-gray-300/40 to-gray-300/50 dark:from-indigo-600/20 dark:via-indigo-600/30 dark:to-indigo-600/40 md:gap-8 transition-colors hover:border-gray-400 hover:dark:border-indigo-500 hover:bg-gray-300/10 hover:dark:bg-gray-600/5 !no-underline"
    >
      <div className="relative h-full p-4">
        <div className="text-2xl font-bold text-green-500 group-hover:text-green-600 dark:text-green-400 dark:group-hover:text-green-300 transition-colors">
          {props.bounty.reward_formatted}
        </div>
        <div className="mt-0.5 text-sm text-gray-700 dark:text-indigo-200 group-hover:text-gray-800 dark:group-hover:text-indigo-100 transition-colors">
          {props.bounty.task.repo_name}#{props.bounty.task.number}
        </div>
        <div className="mt-3 line-clamp-1 break-words text-lg font-medium leading-tight text-gray-800 dark:text-indigo-50 group-hover:text-gray-900 dark:group-hover:text-white">
          {props.bounty.task.title}
        </div>
      </div>
    </Link>
  );
}

function BountyCardSkeleton() {
  return (
    <div className="h-[122px] animate-pulse rounded-lg bg-gray-200 dark:bg-gray-800">
      <div className="relative h-full p-4">
        <div className="mt-1 h-[25px] w-[59px] bg-gray-300 dark:bg-gray-700 rounded-md" />
        <div className="mt-2.5 h-[14px] w-[86px] bg-gray-300 dark:bg-gray-700 rounded-md" />
        <div className="mt-4 h-[20px] bg-gray-300 dark:bg-gray-700 rounded-md" />
      </div>
    </div>
  );
}

function Callout() {
  return (
    <div className="overflow-x-auto mt-6 flex rounded-lg border py-2 ltr:pr-4 rtl:pl-4 contrast-more:border-current contrast-more:dark:border-current border-indigo-100 bg-green-100 text-green-800 dark:border-indigo-400/30 dark:bg-indigo-600/20 dark:text-indigo-300">
      <div className="mt-px select-none text-xl ltr:pl-3 ltr:pr-2 rtl:pr-3 rtl:pl-2">
        💸
      </div>
      <div className="w-full min-w-0 leading-7">
        <p className="mt-6 leading-7 first:mt-0">
          We&apos;re actively looking for and <strong>paying</strong>{" "}
          contributors. Check out our{" "}
          <Link
            href={`https://console.algora.io/org/${org}/bounties`}
            target="_blank"
            rel="noopener"
            className="!underline font-medium"
          >
            active bounties
            <span className="sr-only"> (opens in a new tab)</span>
          </Link>
        </p>
      </div>
    </div>
  );
}
```

</details>

<details>
  <summary><h3>Bounty board (React & CSS)</h3></summary>

```tsx
import { algora, type AlgoraOutput } from "@algora/sdk";
import React, { useEffect, useState } from "react";

// TODO: Use your own color mode hook
import { useColorMode } from "@docusaurus/theme-common";

import "./bounties.css";

// TODO: Use your own Algora handle
const org = "acme";
const limit = 3;

type RemoteData<T> =
  | { _tag: "loading" }
  | { _tag: "failure"; error: Error }
  | { _tag: "success"; data: T };

type Bounty = AlgoraOutput["bounty"]["list"]["items"][number];

export const Bounties = () => {
  const { colorMode } = useColorMode();

  const [bounties, setBounties] = useState<RemoteData<Bounty[]>>({
    _tag: "loading",
  });

  useEffect(() => {
    const ac = new AbortController();

    algora.bounty.list
      .query({ org, limit, status: "active" }, { signal: ac.signal })
      .then(({ items: data }) => setBounties({ _tag: "success", data }))
      .catch((error) => setBounties({ _tag: "failure", error }));

    return () => ac.abort();
  }, []);

  return (
    <div className={`bounty-board ${colorMode}`}>
      {bounties._tag === "success" &&
        bounties.data.map((bounty) => (
          <div key={bounty.id}>
            <BountyCard bounty={bounty} />
          </div>
        ))}
      {bounties._tag === "loading" &&
        [...Array(limit).keys()].map((i) => (
          <div key={i}>
            <BountyCardSkeleton />
          </div>
        ))}
    </div>
  );
};

const BountyCard = (props: { bounty: Bounty }) => (
  <a
    href={props.bounty.task.url}
    target="_blank"
    rel="noopener"
    className="bounty-card"
  >
    <div className="bounty-content">
      <div className="bounty-reward">{props.bounty.reward_formatted}</div>
      <div className="bounty-issue">
        {props.bounty.task.repo_name}#{props.bounty.task.number}
      </div>
      <div className="bounty-title">{props.bounty.task.title}</div>
    </div>
  </a>
);

const BountyCardSkeleton = () => (
  <div className="bounty-skeleton">
    <div className="bounty-content">
      <div className="bounty-reward" />
      <div className="bounty-issue" />
      <div className="bounty-title" />
    </div>
  </div>
);
```

```css
/* bounties.css */

.bounty-board {
  --gray-50: 210, 40%, 98%;
  --gray-100: 210, 40%, 96%;
  --gray-200: 214, 32%, 91%;
  --gray-300: 213, 27%, 84%;
  --gray-400: 215, 20%, 65%;
  --gray-500: 215, 16%, 47%;
  --gray-600: 215, 19%, 35%;
  --gray-700: 215, 25%, 27%;
  --gray-800: 217, 33%, 17%;
  --gray-900: 222, 47%, 11%;
  --gray-950: 229, 84%, 5%;

  --accent-50: 226, 100%, 97%;
  --accent-100: 226, 100%, 94%;
  --accent-200: 228, 96%, 89%;
  --accent-300: 230, 94%, 82%;
  --accent-400: 234, 89%, 74%;
  --accent-500: 239, 84%, 67%;
  --accent-600: 243, 75%, 59%;
  --accent-700: 245, 58%, 51%;
  --accent-800: 244, 55%, 41%;
  --accent-900: 242, 47%, 34%;
  --accent-950: 244, 47%, 20%;

  --green-50: 152, 81%, 96%;
  --green-100: 149, 80%, 90%;
  --green-200: 152, 76%, 80%;
  --green-300: 156, 72%, 67%;
  --green-400: 158, 64%, 52%;
  --green-500: 160, 84%, 39%;
  --green-600: 161, 94%, 30%;
  --green-700: 163, 94%, 24%;
  --green-800: 163, 88%, 20%;
  --green-900: 164, 86%, 16%;
  --green-950: 166, 91%, 9%;
}

.bounty-board {
  display: grid;
  gap: 0.5rem;
  width: 100%;
}

@media (min-width: 640px) {
  .bounty-board {
    grid-template-columns: repeat(3, minmax(0, 1fr));
  }
}

@keyframes bounty-pulse {
  0%,
  100% {
    opacity: 1;
  }
  50% {
    opacity: 0.5;
  }
}

.bounty-board {
  --gradient-to: hsla(var(--accent-400), 0.4);
  --gradient-from: hsla(var(--accent-400), 0.2);
  --gradient-stops: var(--gradient-from), hsla(var(--accent-400), 0.3), var(--gradient-to);
}

.bounty-board.dark {
  --gradient-to: hsla(var(--accent-600), 0.2);
  --gradient-from: hsla(var(--accent-600), 0.3);
  --gradient-stops: var(--gradient-from), hsla(var(--accent-600), 0.4), var(--gradient-to);
}

.bounty-board .bounty-card {
  text-decoration-line: none;
  display: block;
  position: relative;
  border-radius: 0.5rem;
  border-width: 1px;
  height: 100%;
  background-image: linear-gradient(to bottom right, var(--gradient-stops));
}

.bounty-board .bounty-card *,
.bounty-board .bounty-skeleton * {
  transition-property: background-color, color, border-color;
  transition-timing-function: cubic-bezier(0.4, 0, 0.2, 1);
  transition-duration: 300ms;
}

.bounty-board .bounty-card:hover {
  border-color: hsl(var(--gray-400));
}

.bounty-board .bounty-card .bounty-content {
  position: relative;
  padding: 1rem;
  height: 100%;
}

.bounty-board .bounty-card .bounty-reward {
  font-size: 1.5rem;
  line-height: 2rem;
  font-weight: 700;
  color: hsl(var(--green-500));
}

.bounty-board .bounty-card .bounty-issue {
  margin-top: 0.125rem;
  font-size: 0.875rem;
  line-height: 1.25rem;
  color: hsl(var(--gray-700));
}

.bounty-board .bounty-card .bounty-title {
  margin-top: 0.75rem;
  font-size: 1.125rem;
  line-height: 1.75rem;
  font-weight: 500;
  line-height: 1.25;
  color: hsl(var(--gray-800));
  overflow-wrap: break-word;
  overflow: hidden;
  display: -webkit-box;
  -webkit-box-orient: vertical;
  -webkit-line-clamp: var(--line-clamp);
}

.bounty-board.dark .bounty-card .bounty-reward {
  color: hsl(var(--green-400));
}

.bounty-board.dark .bounty-card .bounty-issue {
  color: hsl(var(--accent-200));
}

.bounty-board.dark .bounty-card .bounty-title {
  color: hsl(var(--accent-50));
}

.bounty-board .bounty-card:hover {
  background-color: hsla(var(--gray-300), 0.1);
  border-color: hsl(var(--gray-400));
}

.bounty-board .bounty-card:hover .bounty-reward {
  color: hsl(var(--green-600));
}

.bounty-board .bounty-card:hover .bounty-issue {
  color: hsl(var(--gray-800));
}

.bounty-board .bounty-card:hover .bounty-title {
  color: hsl(var(--gray-900));
}

.bounty-board.dark .bounty-card:hover {
  background-color: hsla(var(--gray-600), 0.05);
  border-color: hsl(var(--accent-500));
}

.bounty-board.dark .bounty-card:hover .bounty-reward {
  color: hsl(var(--green-300));
}

.bounty-board.dark .bounty-card:hover .bounty-issue {
  color: hsl(var(--accent-100));
}

.bounty-board.dark .bounty-card:hover .bounty-title {
  color: white;
}

.bounty-board .bounty-skeleton {
  border-radius: 0.5rem;
  background-color: hsl(var(--gray-200));
  animation: bounty-pulse 2s cubic-bezier(0.4, 0, 0.6, 1) infinite;
  height: 122px;
}

.bounty-board.dark .bounty-skeleton {
  background-color: hsl(var(--gray-800));
}

.bounty-board .bounty-skeleton .bounty-content {
  position: relative;
  padding: 1rem;
  height: 100%;
}

.bounty-board .bounty-skeleton .bounty-reward {
  margin-top: 0.25rem;
  border-radius: 0.375rem;
  height: 25px;
  width: 59px;
  background-color: hsl(var(--gray-300));
}

.bounty-board .bounty-skeleton .bounty-issue {
  margin-top: 0.625rem;
  border-radius: 0.375rem;
  height: 14px;
  width: 86px;
  background-color: hsl(var(--gray-300));
}

.bounty-board .bounty-skeleton .bounty-title {
  margin-top: 1rem;
  border-radius: 0.375rem;
  height: 20px;
  background-color: hsl(var(--gray-300));
}

.bounty-board.dark .bounty-skeleton .bounty-reward {
  background-color: hsl(var(--gray-700));
}

.bounty-board.dark .bounty-skeleton .bounty-issue {
  background-color: hsl(var(--gray-700));
}

.bounty-board.dark .bounty-skeleton .bounty-title {
  background-color: hsl(var(--gray-700));
}
```

</details>

<details>
  <summary><h3>Leaderboard (React & Tailwind)</h3></summary>

```tsx
import { useEffect, useMemo, useState } from "react";
import Image from "next/image";
import Link from "next/link";
import { IconBrandTwitter, IconMapPin } from "@tabler/icons-react";
import { algora, type AlgoraOutput } from "@algora/sdk";

import { Tabs, TabsList, TabsTrigger } from "~/components/ui/tabs";
import { capitalize, range } from "~/utils/util";

// TODO: Use your own Algora handle
const org = "acme";

type RemoteData<T> =
  | { _tag: "loading" }
  | { _tag: "failure"; error: Error }
  | { _tag: "success"; data: T };

type Entry = AlgoraOutput["org"]["getLeaderboard"][number];

const usdFormatter = Intl.NumberFormat("en-US", {
  style: "currency",
  currency: "USD",
  maximumFractionDigits: 0,
});

export function Leaderboard() {
  const [leaderboard, setLeaderboard] = useState<RemoteData<Entry[]>>({
    _tag: "loading",
  });

  const [rewardType, setRewardType] = useState<Entry["reward_type"]>();

  const rewardTypes = useMemo(
    () =>
      leaderboard._tag === "success"
        ? [...new Set(leaderboard.data.map((x) => x.reward_type))]
        : undefined,
    [leaderboard]
  );

  useEffect(() => {
    const ac = new AbortController();

    algora.org.getLeaderboard
      .query({ org }, { signal: ac.signal })
      .then((data) => {
        setLeaderboard({ _tag: "success", data });
        setRewardType(data.at(0)?.reward_type);
      })
      .catch((error) => setLeaderboard({ _tag: "failure", error }));

    return () => ac.abort();
  }, []);

  return (
    <div className="space-y-2">
      <Tabs
        value={rewardType}
        onValueChange={setRewardType as (_: string) => void}
      >
        {rewardTypes && (
          <TabsList
            className="grid w-full gap-1 bg-white/5 text-white/50"
            style={{
              gridTemplateColumns: `repeat(${rewardTypes.length}, minmax(0, 1fr))`,
            }}
          >
            {rewardTypes.map((t) => (
              <TabsTrigger
                key={t}
                className="hover:bg-purple-600/50 data-[state=active]:bg-purple-600 data-[state=active]:text-white"
                value={t}
              >
                {capitalize(t)}
              </TabsTrigger>
            ))}
          </TabsList>
        )}
      </Tabs>
      <ul className="w-full divide-y-2 divide-gray-400/50 overflow-hidden rounded-lg border-2 border-gray-400/50 text-left text-sm text-gray-500 dark:divide-white/10 dark:border-white/10 dark:text-gray-400">
        {leaderboard._tag === "loading" &&
          range(10).map((i) => (
            <LeaderboardEntrySkeleton key={i} isFirst={i === 0} />
          ))}

        {leaderboard._tag === "success" &&
          leaderboard.data
            .filter((entry) => entry.reward_type === rewardType)
            .map((entry, i) => (
              <li key={entry.uid}>
                <LeaderboardEntry entry={entry} isFirst={i === 0} />
              </li>
            ))}
      </ul>
    </div>
  );
}

function LeaderboardEntry({
  entry,
  isFirst,
}: {
  entry: Entry;
  isFirst: boolean;
}) {
  const { user, stats, reward_type } = entry;
  return (
    <div className="group/card relative flex h-full flex-col justify-center gap-4 rounded-none bg-white px-6 py-8 transition-colors dark:bg-white/[2%] dark:bg-gradient-to-br dark:from-white/[2%] dark:via-white/[2%] dark:to-white/[2%] md:flex-row md:justify-between md:gap-4 md:px-12">
      <div className="flex w-full items-center gap-3 text-gray-900 dark:text-white">
        <Link
          href={`https://github.com/${user.login}`}
          rel="noopener noreferrer"
          target="_blank"
          className="relative mr-3 h-16 w-16 shrink-0"
        >
          <Image
            className="rounded-full"
            src={user.avatar_url}
            alt={user.login}
            fill
          />
          {isFirst && (
            <div className="absolute bottom-12 left-0 right-0">
              <div className="relative mx-auto h-12 w-12">
                <Image
                  className="rounded-full"
                  src="https://algora.io/emojis/crown.png"
                  alt="Crown"
                  fill
                />
              </div>
            </div>
          )}
        </Link>
        <div className="w-full shrink truncate md:max-w-[10rem] lg:max-w-sm xl:max-w-xl">
          <Link
            href={`https://github.com/${user.login}`}
            rel="noopener noreferrer"
            target="_blank"
            className="flex flex-col truncate"
          >
            <div className="truncate text-base font-semibold">
              {user.name ?? user.login}
            </div>
            <div className="truncate font-medium text-gray-400 dark:text-gray-400">
              @{user.login}
            </div>
          </Link>
          <div className="mt-1 flex flex-wrap gap-x-4 gap-y-1 font-normal text-gray-500 dark:text-gray-300">
            {user.location && (
              <div className="flex items-center gap-1">
                <IconMapPin className="h-4 w-4" aria-hidden="true" />
                <span>{user.location}</span>
              </div>
            )}
            {user.twitter_username && (
              <Link
                href={`https://twitter.com/${user.twitter_username}`}
                rel="noopener noreferrer"
                target="_blank"
                className="flex items-center gap-1"
              >
                <IconBrandTwitter className="h-4 w-4" aria-hidden="true" />
                <span>{user.twitter_username}</span>
              </Link>
            )}
          </div>
        </div>
      </div>
      <dl className="grid w-full max-w-md grid-cols-3 gap-8 whitespace-nowrap">
        <div className="flex flex-col text-left md:text-center">
          <dt className="order-2 text-sm font-medium leading-6 text-gray-500 dark:text-gray-400">
            Bount{stats.num_completed_bounties === 1 ? "y" : "ies"}{" "}
            <span className="hidden sm:inline-block">Completed</span>
          </dt>
          <dd className="order-1 font-mono text-4xl font-bold tracking-tight text-gray-900 dark:text-white">
            {stats.num_completed_bounties}
          </dd>
        </div>
        <div className="col-span-2 flex flex-col text-left md:text-center">
          <dt className="order-2 text-sm font-medium leading-6 text-gray-500 dark:text-gray-400">
            Total {reward_type === "cash" ? "Earnings" : "Points"}
          </dt>
          <dd className="order-1 font-mono text-4xl font-bold tracking-tight text-green-500 dark:text-green-400">
            {reward_type === "cash"
              ? usdFormatter.format(stats.total_earnings / 100)
              : stats.total_earnings}
          </dd>
        </div>
      </dl>
    </div>
  );
}

function LeaderboardEntrySkeleton(props: { isFirst: boolean }) {
  return (
    <div className="h-[212px] w-full animate-pulse bg-white px-6 py-8 dark:bg-gray-900 md:h-[132px] md:px-12">
      <div className="flex items-center gap-3">
        <div className="relative mr-3 h-16 w-16 shrink-0 ">
          <div className="h-full w-full rounded-full bg-gray-200 dark:bg-gray-800" />
          {props.isFirst && (
            <div className="absolute bottom-12 left-0 right-0">
              <div className="relative mx-auto -mb-[2px] h-12 w-12">
                <Image
                  className="rounded-full"
                  src="https://algora.io/emojis/crown.png"
                  alt="Crown"
                  fill
                />
              </div>
            </div>
          )}
        </div>
        <div className="flex flex-col space-y-2">
          <div className="h-6 w-36 rounded-md bg-gray-200 dark:bg-gray-800" />
          <div className="h-4 w-20 rounded-md bg-gray-200 dark:bg-gray-800" />
        </div>
      </div>
    </div>
  );
}
```

</details>
