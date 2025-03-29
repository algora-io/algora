defmodule AlgoraWeb.Challenges.PrettierLive do
  @moduledoc false
  use AlgoraWeb, :live_view

  alias AlgoraWeb.Components.Footer
  alias AlgoraWeb.Components.Header

  def render(assigns) do
    ~H"""
    <div class="relative bg-[#050217]">
      <div class="absolute top-0 z-10 w-full"><Header.header /></div>
      <main class="relative z-0">
        <article>
          <div class="text-white">
            <div class="relative z-20">
              <section class="mb-24 md:mb-36">
                <div class="relative z-20 mx-auto max-w-7xl px-6 lg:px-8">
                  <div class="max-w-5xl pt-24 md:pt-60">
                    <h1 class="!mb-2 text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                      Write a pretty printer in Rust<br />
                      <span style="background: radial-gradient(53.44% 245.78% at 13.64% 46.56%, rgb(110, 231, 183) 0%, rgb(45, 212, 191) 100%) text; -webkit-text-fill-color: transparent;">
                        Win <span class="font-mono text-[2.5rem] md:text-[5rem]">$25,000</span>
                      </span>
                    </h1>
                    <p class="mb-8 w-4/5 text-lg font-medium leading-none tracking-tight opacity-80 md:w-full md:text-xl md:opacity-70">
                      The Prettier Bounty is a challenge to write a prettier-compliant pretty printer in Rust
                    </p>
                    <div class="grid gap-6 md:grid-cols-2 md:pt-12">
                      <a
                        target="_blank"
                        rel="noopener"
                        class="group hover:no-underline"
                        href="https://twitter.com/Vjeux/status/1722733472522142022"
                      >
                        <div
                          class="relative flex h-full max-w-2xl overflow-hidden rounded-3xl border-2 border-solid border-[#6366f1] px-5 py-4 md:px-7 md:py-5"
                          style="background: radial-gradient(circle at right bottom, rgb(199, 210, 254) 0%, rgb(99, 102, 241) 28%, rgb(30, 27, 75) 63.02%, rgb(5, 2, 23) 100%); box-shadow: rgba(30, 27, 75, 0.08) 0px 3.26536px 2.21381px 0px, rgba(30, 27, 75, 0.11) 0px 7.84712px 5.32008px 0px, rgba(30, 27, 75, 0.14) 0px 14.7754px 10.0172px 0px, rgba(30, 27, 75, 0.16) 0px 26.3568px 17.8691px 0px, rgba(30, 27, 75, 0.19) 0px 49.2976px 33.4221px 0px, rgba(30, 27, 75, 0.27) 0px 118px 80px 0px;"
                        >
                          <div class="flex flex-1 flex-col">
                            <h2 class="!mb-0 !mt-0 text-4xl font-black leading-none tracking-tighter md:text-6xl">
                              Grand Prize
                            </h2>
                            <h3
                              class="text-3xl font-black leading-none tracking-tighter md:text-5xl"
                              style="background: radial-gradient(53.44% 245.78% at 13.64% 46.56%, rgb(110, 231, 183) 0%, rgb(45, 212, 191) 100%) text; -webkit-text-fill-color: transparent;"
                            >
                              <div class="font-mono text-4xl md:text-6xl">$22,500</div>
                            </h3>
                            <p class="flex-1 pb-8 pt-4 text-lg font-medium leading-none tracking-tight opacity-70 md:text-xl">
                              Pass &gt; 95% of the prettier JavaScript tests
                            </p>
                            <div class="flex items-center">
                              <div class="mr-1 hidden font-bold uppercase tracking-wider transition-all group-hover:mr-3 sm:block">
                                Read the Announcement
                              </div>
                              <div class="mr-1 block font-bold uppercase tracking-wider sm:hidden">
                                Announcement
                              </div>
                              <svg
                                xmlns="http://www.w3.org/2000/svg"
                                width="24"
                                height="24"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="2"
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                class="h-5 w-5 text-purple-300"
                                aria-hidden="true"
                              >
                                <path d="M5 12l14 0"></path>
                                <path d="M13 18l6 -6"></path>
                                <path d="M13 6l6 6"></path>
                              </svg>
                            </div>
                          </div>
                          <div
                            class="absolute inset-0 opacity-20 mix-blend-overlay"
                            style="background: url(&quot;/images/grid.png&quot;);"
                          >
                          </div>
                        </div>
                      </a>
                      <a
                        target="_blank"
                        rel="noopener"
                        class="group relative flex flex-1 flex-col rounded-2xl border-2 border-solid border-white bg-zinc-950/70 p-4 md:p-6"
                        href="https://twitter.com/wasmerio/status/1723059294151626906"
                      >
                        <h2 class="!mb-0 !mt-0 text-4xl font-black leading-none tracking-tighter md:text-6xl">
                          WASIX Prize
                        </h2>
                        <h3
                          class="font-mono text-4xl font-black leading-none tracking-tighter md:text-6xl"
                          style="background: radial-gradient(53.44% 245.78% at 13.64% 46.56%, rgb(110, 231, 183) 0%, rgb(45, 212, 191) 100%) text; -webkit-text-fill-color: transparent;"
                        >
                          $2,500
                        </h3>
                        <p class="flex-1 pb-8 pt-4 text-lg font-medium leading-none tracking-tight opacity-70 md:text-xl">
                          Compile to WASIX and publish (via CI) to Wasmer
                        </p>
                        <div class="flex items-center">
                          <div class="mr-1 hidden font-bold uppercase tracking-wider transition-all group-hover:mr-3 sm:block">
                            Read the Announcement
                          </div>
                          <div class="mr-1 block font-bold uppercase tracking-wider sm:hidden">
                            Announcement
                          </div>
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            width="24"
                            height="24"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            class="h-5 w-5 text-purple-300"
                            aria-hidden="true"
                          >
                            <path d="M5 12l14 0"></path>
                            <path d="M13 18l6 -6"></path>
                            <path d="M13 6l6 6"></path>
                          </svg>
                        </div>
                      </a>
                    </div>
                  </div>
                </div>
                <div
                  class="absolute inset-0 z-10 h-[810px]"
                  style="background: linear-gradient(90deg, rgba(28, 26, 29, 0.4) 0%, rgba(28, 26, 29, 0) 64.42%), linear-gradient(0deg, rgb(5, 2, 23) 1%, rgba(28, 26, 29, 0) 30%);"
                >
                </div>
                <div class="absolute inset-0 z-0 h-[810px]">
                  <img
                    src={~p"/images/challenges/prettier/bg.png"}
                    alt="Background"
                    class="h-full w-full object-cover object-[50%]"
                  />
                </div>
              </section>
              <section class="mb-24 md:mb-36">
                <div class="relative z-30 mx-auto max-w-7xl px-6 lg:px-8">
                  <div class="mb-6 md:mb-10">
                    <h2 class="mb-8 flex justify-center text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                      Sponsors
                    </h2>
                    <div class="grid grid-cols-2 gap-8 text-center xl:grid-cols-4">
                      <a
                        target="_blank"
                        rel="noopener"
                        class="flex flex-1 flex-col items-center text-white no-underline hover:no-underline"
                        href="https://twitter.com/Vjeux"
                      >
                        <div class="relative h-36 w-36 md:h-48 md:w-48">
                          <img
                            alt="Christopher Chedeau"
                            loading="lazy"
                            class="rounded-full saturate-0"
                            src={~p"/images/challenges/prettier/vjeux.jpg"}
                            style="position: absolute; height: 100%; width: 100%; inset: 0px; color: transparent;"
                          />
                        </div>
                        <h2 class="mt-4 text-2xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-4xl xl:text-3xl">
                          Christopher Chedeau
                        </h2>
                        <h3
                          class="mt-1 font-mono text-2xl font-extrabold leading-none tracking-tighter text-purple-100 mix-blend-exclusion md:text-4xl xl:text-3xl"
                          style="background: radial-gradient(53.44% 245.78% at 13.64% 46.56%, rgb(110, 231, 183) 0%, rgb(45, 212, 191) 100%) text; -webkit-text-fill-color: transparent;"
                        >
                          $10,000
                        </h3>
                      </a>
                      <a
                        target="_blank"
                        rel="noopener"
                        class="flex flex-1 flex-col items-center text-white no-underline hover:no-underline"
                        href="https://twitter.com/rauchg"
                      >
                        <div class="relative h-36 w-36 md:h-48 md:w-48">
                          <img
                            alt="Guillermo Rauch"
                            loading="lazy"
                            class="rounded-full saturate-0"
                            src={~p"/images/challenges/prettier/rauchg.jpg"}
                            style="position: absolute; height: 100%; width: 100%; inset: 0px; color: transparent;"
                          />
                        </div>
                        <h2 class="mt-4 text-2xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-4xl xl:text-3xl">
                          Guillermo Rauch
                        </h2>
                        <h3
                          class="mt-1 font-mono text-2xl font-extrabold leading-none tracking-tighter text-purple-100 mix-blend-exclusion md:text-4xl xl:text-3xl"
                          style="background: radial-gradient(53.44% 245.78% at 13.64% 46.56%, rgb(110, 231, 183) 0%, rgb(45, 212, 191) 100%) text; -webkit-text-fill-color: transparent;"
                        >
                          $10,000
                        </h3>
                      </a>
                      <a
                        target="_blank"
                        rel="noopener"
                        class="flex flex-1 flex-col items-center text-white no-underline hover:no-underline"
                        href="https://wasmer.io"
                      >
                        <div class="relative h-36 w-36 md:h-48 md:w-48">
                          <img
                            alt="Wasmer"
                            loading="lazy"
                            class="rounded-full saturate-0"
                            src={~p"/images/challenges/prettier/wasmer.png"}
                            style="position: absolute; height: 100%; width: 100%; inset: 0px; color: transparent;"
                          />
                        </div>
                        <h2 class="mt-4 text-2xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-4xl xl:text-3xl">
                          Wasmer
                        </h2>
                        <h3
                          class="mt-1 font-mono text-2xl font-extrabold leading-none tracking-tighter text-purple-100 mix-blend-exclusion md:text-4xl xl:text-3xl"
                          style="background: radial-gradient(53.44% 245.78% at 13.64% 46.56%, rgb(110, 231, 183) 0%, rgb(45, 212, 191) 100%) text; -webkit-text-fill-color: transparent;"
                        >
                          $2,500
                        </h3>
                      </a>
                      <a
                        target="_blank"
                        rel="noopener"
                        class="flex flex-1 flex-col items-center text-white no-underline hover:no-underline"
                        href="https://napi.rs"
                      >
                        <div class="relative h-36 w-36 md:h-48 md:w-48">
                          <img
                            alt="NAPI-RS"
                            loading="lazy"
                            class="rounded-full saturate-0"
                            src={~p"/images/challenges/prettier/napi-rs.png"}
                            style="position: absolute; height: 100%; width: 100%; inset: 0px; color: transparent;"
                          />
                        </div>
                        <h2 class="mt-4 text-2xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-4xl xl:text-3xl">
                          NAPI-RS
                        </h2>
                        <h3
                          class="mt-1 font-mono text-2xl font-extrabold leading-none tracking-tighter text-purple-100 mix-blend-exclusion md:text-4xl xl:text-3xl"
                          style="background: radial-gradient(53.44% 245.78% at 13.64% 46.56%, rgb(110, 231, 183) 0%, rgb(45, 212, 191) 100%) text; -webkit-text-fill-color: transparent;"
                        >
                          $2,500
                        </h3>
                      </a>
                    </div>
                  </div>
                </div>
              </section>
              <section class="mb-24 md:mb-36">
                <div class="relative z-30 mx-auto max-w-7xl px-6 lg:px-8">
                  <div class="mb-6 md:mb-10">
                    <h2 class="text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                      Participate
                    </h2>
                    <p class="mb-8 mt-2 text-lg font-medium leading-7 text-gray-300">
                      Have a question? Send us an email at
                      <a
                        class="font-semibold text-purple-300 hover:text-purple-200"
                        href="mailto:info@algora.io"
                      >
                        info@algora.io
                      </a>
                      and we’ll get back to you as soon as we can!
                    </p>
                    <div class="cursor-not-allowed">
                      <div class="grid gap-6 md:grid-cols-2 pointer-events-none grayscale">
                        <button
                          type="button"
                          aria-haspopup="dialog"
                          aria-expanded="false"
                          aria-controls="radix-:r6:"
                          data-state="closed"
                          class="group relative flex max-w-2xl overflow-hidden rounded-3xl border-2 border-solid border-[#6366f1] px-5 py-4 text-left md:px-7 md:py-5"
                          style="background: radial-gradient(circle at right bottom, rgb(224, 231, 255) 0%, rgb(99, 102, 241) 28%, rgb(30, 27, 75) 63.02%, rgb(5, 2, 23) 100%); box-shadow: rgba(30, 27, 75, 0.08) 0px 3.26536px 2.21381px 0px, rgba(30, 27, 75, 0.11) 0px 7.84712px 5.32008px 0px, rgba(30, 27, 75, 0.14) 0px 14.7754px 10.0172px 0px, rgba(30, 27, 75, 0.16) 0px 26.3568px 17.8691px 0px, rgba(30, 27, 75, 0.19) 0px 49.2976px 33.4221px 0px, rgba(30, 27, 75, 0.27) 0px 118px 80px 0px;"
                        >
                          <div class="flex flex-1 flex-col">
                            <h3 class="!mt-0 mb-12 text-3xl font-black leading-none tracking-tighter md:text-6xl">
                              Become a sponsor
                            </h3>
                            <div class="flex items-center pt-12 md:pt-16">
                              <div class="mr-1 font-bold uppercase tracking-wider transition-all group-hover:mr-3">
                                Get started
                              </div>
                              <svg
                                xmlns="http://www.w3.org/2000/svg"
                                width="24"
                                height="24"
                                viewBox="0 0 24 24"
                                fill="none"
                                stroke="currentColor"
                                stroke-width="2"
                                stroke-linecap="round"
                                stroke-linejoin="round"
                                class="h-5 w-5 text-purple-100"
                                aria-hidden="true"
                              >
                                <path d="M5 12l14 0"></path>
                                <path d="M13 18l6 -6"></path>
                                <path d="M13 6l6 6"></path>
                              </svg>
                            </div>
                          </div>
                          <div
                            class="absolute inset-0 bg-cover bg-center opacity-100 mix-blend-overlay"
                            style="background-image: url(&quot;/images/challenges/prettier/sponsor.png&quot;);"
                          >
                          </div>
                          <div
                            class="absolute inset-0 opacity-50 mix-blend-overlay"
                            style="background: url(&quot;/images/grid.png&quot;);"
                          >
                          </div>
                        </button>
                        <button
                          type="button"
                          aria-haspopup="dialog"
                          aria-expanded="false"
                          aria-controls="radix-:r9:"
                          data-state="closed"
                          class="group relative flex flex-1 flex-col overflow-hidden rounded-2xl border-2 border-solid border-white p-4 text-left md:p-6"
                          style="background: radial-gradient(circle at right bottom, rgb(203, 206, 225) 0%, rgb(101, 104, 139) 28%, rgb(5, 2, 23) 63.02%, rgb(5, 2, 23) 100%); box-shadow: rgba(30, 27, 75, 0.08) 0px 3.26536px 2.21381px 0px, rgba(30, 27, 75, 0.11) 0px 7.84712px 5.32008px 0px, rgba(30, 27, 75, 0.14) 0px 14.7754px 10.0172px 0px, rgba(30, 27, 75, 0.16) 0px 26.3568px 17.8691px 0px, rgba(30, 27, 75, 0.19) 0px 49.2976px 33.4221px 0px, rgba(30, 27, 75, 0.27) 0px 118px 80px 0px;"
                        >
                          <h3 class="!mt-0 mb-12 text-3xl font-black leading-none tracking-tighter md:text-6xl">
                            Submit a solution
                          </h3>
                          <div class="flex items-center pt-12 md:pt-16">
                            <div class="mr-1 font-bold uppercase tracking-wider transition-all group-hover:mr-3">
                              Get started
                            </div>
                            <svg
                              xmlns="http://www.w3.org/2000/svg"
                              width="24"
                              height="24"
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="currentColor"
                              stroke-width="2"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              class="h-5 w-5 text-purple-100"
                              aria-hidden="true"
                            >
                              <path d="M5 12l14 0"></path>
                              <path d="M13 18l6 -6"></path>
                              <path d="M13 6l6 6"></path>
                            </svg>
                          </div>
                          <div
                            class="absolute inset-0 bg-cover bg-center opacity-100 mix-blend-overlay"
                            style="background-image: url(&quot;/images/challenges/prettier/solve.png&quot;);"
                          >
                          </div>
                          <div
                            class="absolute inset-0 opacity-50 mix-blend-overlay"
                            style="background: url(&quot;/images/grid.png&quot;);"
                          >
                          </div>
                        </button>
                      </div>
                    </div>
                  </div>
                </div>
                <div class="relative z-50 mx-auto max-w-7xl divide-y divide-white/10 px-6 pt-6 lg:px-8">
                  <h2 class="text-2xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-5xl">
                    Challenge specs
                  </h2>
                  <div class="mt-4 space-y-4 divide-y divide-white/10">
                    <div class="pt-4">
                      <div>
                        <div class="flex w-full items-start justify-between text-left text-white">
                          <span class="text-base font-medium leading-7">
                            The bounty is split into two distinct prize pools: Grand Prize &amp; WASIX Prize.
                          </span>
                        </div>
                      </div>
                    </div>
                    <div class="pt-4">
                      <div>
                        <div class="flex w-full items-start justify-between text-left text-white">
                          <span class="text-base font-medium leading-7">
                            Winning the Grand Prize requires passing &gt; 95% of the prettier JavaScript tests.
                          </span>
                        </div>
                      </div>
                    </div>
                    <div class="pt-4">
                      <div>
                        <div class="flex w-full items-start justify-between text-left text-white">
                          <span class="text-base font-medium leading-7">
                            Winning the WASIX Prize requires compiling the formatter to WASIX and publishing it to Wasmer via CI.
                          </span>
                        </div>
                      </div>
                    </div>
                    <div class="pt-4">
                      <div>
                        <div class="flex w-full items-start justify-between text-left text-white">
                          <span class="text-base font-medium leading-7">
                            The scope for the challenge is JavaScript — only ES6 syntax is required.
                          </span>
                        </div>
                      </div>
                    </div>
                    <div class="pt-4">
                      <div>
                        <div class="flex w-full items-start justify-between text-left text-white">
                          <span class="text-base font-medium leading-7">
                            TypeScript, GraphQL, CSS, or any other
                            <a
                              rel="noopener"
                              class="underline"
                              target="_blank"
                              href="https://prettier.io/docs/en/options.html#embedded-language-formatting"
                            >
                              embedded language
                            </a>
                            or
                            <a
                              rel="noopener"
                              class="underline"
                              target="_blank"
                              href="https://prettier.io/docs/en/rationale.html#disclaimer-about-non-standard-syntax"
                            >
                              unstable syntax
                            </a>
                            are out of scope for the challenge.
                          </span>
                        </div>
                      </div>
                    </div>
                    <div class="pt-4">
                      <div>
                        <div class="flex w-full items-start justify-between text-left text-white">
                          <span class="text-base font-medium leading-7">
                            All
                            <a
                              rel="noopener"
                              class="underline"
                              target="_blank"
                              href="https://prettier.io/docs/en/options.html"
                            >
                              formatting options
                            </a>
                            must be supported.
                          </span>
                        </div>
                      </div>
                    </div>
                    <div class="pt-4">
                      <div>
                        <div class="flex w-full items-start justify-between text-left text-white">
                          <span class="text-base font-medium leading-7">
                            The bounty will be awarded to the first successful solution.
                          </span>
                        </div>
                      </div>
                    </div>
                    <div class="pt-4">
                      <div>
                        <div class="flex w-full items-start justify-between text-left text-white">
                          <span class="text-base font-medium leading-7">
                            You can (and are encouraged to) work as a team and split the bounty with your teammates.
                          </span>
                        </div>
                      </div>
                    </div>
                  </div>
                </div>
                <div class="relative z-50 mx-auto max-w-7xl px-6 pt-6 lg:px-8">
                  <div class="relative pt-24">
                    <h2 class="flex justify-center text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                      🎉 Winner 🎉
                    </h2>
                    <div class="mt-8 flex flex-col items-center justify-center">
                      <div class="flex flex-col items-center">
                        <a
                          rel="noopener noreferrer"
                          class="underline"
                          target="_blank"
                          href="https://github.com/biomejs"
                        >
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            viewBox="0 0 1374 600"
                            class="h-auto w-64 sm:w-96"
                          >
                            <g transform="translate(62.5,62.5)" fill="#f7b911">
                              <path d="M300.94 207.56a96.04 96.04 0 0 0-15.88-24.06c-3.25-3.06-6.7-5.92-10.16-8.87-1.67-1.48-1.97-2.96-.39-4.34a78.49 78.49 0 0 0 20.31-26.33 90.71 90.71 0 0 0 7.2-26.62 66.95 66.95 0 0 0 0-15.09q-1.58-17.06-3.55-22.68-1.28-5.13-2.56-8.97c-10.85-27.8-35.8-46.54-51.97-56.2a136.37 136.37 0 0 0-15.28-6.12 161.02 161.02 0 0 0-27.6-6.3A145.14 145.14 0 0 0 180.14 0H0v82.33h175.12a77.3 77.3 0 0 1 17.16 1.98c7.49 1.57 13.9 4.73 17.45 12.02a36.09 36.09 0 0 1 2.17 11.34v8.29a19.42 19.42 0 0 1-5.52 10.45 33.52 33.52 0 0 1-20.9 7.4c-13.42.98-26.93.2-40.44.39H0v223.73h82.33c2.57 0 2.96-.99 2.96-3.26v-133.5c0-7.2 0-7.2 7.1-7.2h88.64a56.6 56.6 0 0 1 28.2 6.11.79.79 0 0 0 .5 0l2.86 2.66a28.6 28.6 0 0 1 7.5 31.36 27.8 27.8 0 0 1-9.67 12.52 48.12 48.12 0 0 1-25.44 8.09c-11.24.2-22.48 0-33.72 0-2.86 0-3.65.88-3.65 3.55v72.77c0 6.9 0 7.2 7 6.9a398.26 398.26 0 0 0 44.86-1.28q23.27-3.26 39.64-7.9a11.73 11.73 0 0 0 .7-.29 119.9 119.9 0 0 0 33.91-17.65 64.1 64.1 0 0 0 15.97-15.77 5.03 5.03 0 0 0 1-1A86.97 86.97 0 0 0 306.64 282a174.33 174.33 0 0 0 4.15-20.7 93.38 93.38 0 0 0-9.86-53.64zM140.8 78.88z">
                              </path>
                              <path
                                fill="#e75115"
                                d="M338.4 326.47h54.33v-212.1H338.4zm27.02-235.16a31.06 31.06 0 0 0 30.86-31.56 31.45 31.45 0 0 0-30.86-32.14 31.75 31.75 0 0 0-31.26 32.04c0 17.56 14 31.56 31.26 31.56zm168.32 19.12c-64.1 0-116.06 48.91-116.06 109.75 0 60.64 51.96 109.45 116.06 109.45 64.09 0 116.05-48.81 116.05-109.45 0-60.84-51.96-109.75-116.05-109.75zm0 170.39a61.82 61.82 0 0 1-62.52-60.64c0-33.53 28.2-60.84 62.52-60.84a61.63 61.63 0 0 1 62.51 60.84 61.53 61.53 0 0 1-62.51 60.64zm388-170.39a97.62 97.62 0 0 0-66.36 26.92c-14.5-18.73-37.47-26.92-70.3-26.92a94.66 94.66 0 0 0-55.22 17.16v-13.21h-54.63v212.2h54.63V176.1a65.08 65.08 0 0 1 45.75-16.76c28.1 0 42.6 16.27 42.6 48.71v118.42h54.42V209.04c0-19.13-.4-27.02-2.36-32.84a58.57 58.57 0 0 1 42.3-16.76c29.58 0 46.05 15.97 46.05 48.71v118.42h54.23V208.25c0-68.73-28.5-97.72-91.01-97.72zm326.87 125.43c0-3.55.39-7.8.39-12.13 0-66.06-37.96-113.4-103.14-113.4-64.09 0-108.66 49.01-108.66 109.85 0 60.64 44.57 109.45 108.66 109.45 41.41 0 76.12-17.16 95.65-43.78l-34.71-28.9a68.04 68.04 0 0 1-54.73 26.24c-32.44 0-54.72-19.63-60.54-47.33zm-102.85-82.04c36.29 0 49.2 22.97 51.18 47.33h-105.11c5.03-26.23 25.34-47.33 53.93-47.33z"
                              >
                              </path>
                              <path d="M117.63 425.86v-10.55h42.1v10.55h-15.47v47.93H133.2v-47.93zm50.68 25.25v-13.12c0-7.59 1.98-13.4 5.72-17.55 3.85-4.24 9.08-6.3 15.78-6.3 6.8 0 12.03 2.06 15.88 6.3A25.24 25.24 0 0 1 211.4 438v13.12c0 7.79-1.97 13.7-5.71 17.75a20.7 20.7 0 0 1-15.78 6.1c-6.8 0-12.03-1.96-15.78-6.1-3.94-4.05-5.82-9.96-5.82-17.75zm21.5 13.8c1.97 0 3.65-.3 5.03-.99a8.48 8.48 0 0 0 3.25-2.66 9.86 9.86 0 0 0 1.78-4.14c.3-1.67.5-3.45.5-5.42v-14.3c0-1.97-.2-3.65-.6-5.23-.3-1.57-.99-2.95-1.78-4.23a12.71 12.71 0 0 0-3.25-2.77 10.73 10.73 0 0 0-4.93-.98 9.07 9.07 0 0 0-8.09 3.84 16 16 0 0 0-1.87 4.14 28.6 28.6 0 0 0-.5 5.23v14.2c0 1.97.1 3.75.5 5.42.3 1.58.89 2.96 1.68 4.14a9.47 9.47 0 0 0 8.28 3.65zm29.58-13.8v-13.12c0-7.59 1.97-13.4 5.72-17.55 3.85-4.24 9.07-6.3 15.87-6.3 6.71 0 12.03 2.06 15.78 6.3a25.24 25.24 0 0 1 5.72 17.55v13.12c0 7.79-1.87 13.7-5.72 17.75a20.5 20.5 0 0 1-15.78 6.1 20.7 20.7 0 0 1-15.77-6.1c-3.95-4.05-5.82-9.96-5.82-17.75zm21.7 13.8c1.97 0 3.54-.3 4.92-.99a8.68 8.68 0 0 0 3.16-2.66 11.36 11.36 0 0 0 1.87-4.14c.3-1.67.5-3.45.5-5.42v-14.3c0-1.97-.2-3.65-.7-5.23-.3-1.57-.98-2.95-1.77-4.23a11.24 11.24 0 0 0-3.25-2.77 10.58 10.58 0 0 0-4.84-.98c-1.97 0-3.54.3-4.93.98a9.07 9.07 0 0 0-3.15 2.77 12.66 12.66 0 0 0-1.87 4.23 21.7 21.7 0 0 0-.6 5.23v14.2c0 1.97.2 3.75.5 5.42.4 1.58.98 2.96 1.77 4.14a9.47 9.47 0 0 0 8.28 3.65zm32.24 8.88V415.3h11.14v47.92h26.52v10.56zm70-8.88c2.17 0 3.95-.3 5.23-.99a7.89 7.89 0 0 0 3.16-2.56 9.76 9.76 0 0 0 1.57-3.75c.3-1.38.5-2.95.5-4.33v-1.68h10.94v1.58c0 6.9-1.77 12.32-5.52 16.07-3.55 3.75-8.87 5.62-15.78 5.62-6.7 0-12.03-1.97-15.87-6.11-3.95-4.05-5.92-9.96-5.92-17.75v-13.12c0-3.74.5-7 1.48-10.05a19.72 19.72 0 0 1 11.24-12.13 23.84 23.84 0 0 1 8.97-1.68c3.46 0 6.51.5 9.27 1.58a17.35 17.35 0 0 1 10.85 11.14 31.27 31.27 0 0 1 1.28 8.97v1.58H353.8v-1.48a14.99 14.99 0 0 0-2.27-7.88 7.89 7.89 0 0 0-3.16-2.77 10.46 10.46 0 0 0-4.93-.98c-1.97 0-3.55.3-4.93.98a10.35 10.35 0 0 0-5.22 7.1c-.4 1.58-.6 3.16-.6 4.93V452c0 1.77.2 3.54.6 5.12.4 1.58.98 2.96 1.77 4.14a8.87 8.87 0 0 0 3.35 2.66c1.38.7 2.96 1 4.93 1zm30.57 8.88V415.3h10.95v23.87h18.83V415.3h11.14v58.48h-11.14v-24.16h-18.74v24.06zm84.3 0-2.85-12.53h-19.92l-2.76 12.53h-11.54l13.9-58.48h20.71l14 58.48zm-13.5-52.95-6.9 29.87h15.18l-6.8-29.87zm32.34 4.93V415.3h39.05v10.55h-14v37.47h14v10.46h-39.05v-10.56h14v-37.46zm71.78-10.46 6.8 52.95h1.49v-52.95h11.04v58.48h-21.6l-6.9-52.95h-1.48v52.95h-10.94V415.3zm79.48 35.8v-13.12c0-7.59 1.97-13.4 5.72-17.55 3.94-4.24 9.17-6.3 15.87-6.3 6.7 0 12.03 2.06 15.78 6.3a25.24 25.24 0 0 1 5.72 17.55v13.12c0 7.79-1.88 13.7-5.72 17.75a20.5 20.5 0 0 1-15.78 6.1 20.7 20.7 0 0 1-15.78-6.1c-3.94-4.05-5.81-9.96-5.81-17.75zm21.69 13.8c1.97 0 3.55-.3 4.93-.99a8.48 8.48 0 0 0 3.25-2.66 9.86 9.86 0 0 0 1.78-4.14c.3-1.67.5-3.45.5-5.42v-14.3c0-1.97-.2-3.65-.6-5.23-.4-1.57-.99-2.95-1.87-4.23a11.24 11.24 0 0 0-3.26-2.77 10.3 10.3 0 0 0-4.83-.98c-1.97 0-3.55.3-4.93.98a9.07 9.07 0 0 0-3.16 2.77 12.66 12.66 0 0 0-1.87 4.23 28.6 28.6 0 0 0-.5 5.23v14.2c0 1.97.1 3.75.5 5.42.3 1.58.89 2.96 1.68 4.14a9.47 9.47 0 0 0 8.28 3.65zm32.83 8.88V415.3h37.47v10.55h-26.42v13.32h25.83v10.55h-25.83v24.06zm99.4-47.93v-10.55h42.1v10.55h-15.48v47.93H797.7v-47.93zm51.66 47.93V415.3h11.05v23.87h18.83V415.3h11.04v58.48h-11.04v-24.16h-18.74v24.06zm52.85 0V415.3h36.88v10.55h-25.83v13.32h24.94v10.55h-24.94v13.5h26.92v10.56zm145.94-58.48-2.07 58.48h-19.23l-2.66-44.38v-8.08h-1.98v8.08l-2.66 44.38h-19.23l-1.97-58.48h9.96l1.28 44.38v7.59h2.07v-7.6l2.67-44.37h17.74l2.67 44.38v7.59h1.97v-7.6l1.28-44.37zm7.4 58.48V415.3h36.97v10.55h-25.84v13.32h24.85v10.55h-24.95v13.5h26.82v10.56zm48.1 0v-10.56h5.63v-37.46h-5.62V415.3h25.64c2.86 0 5.32.4 7.4 1.19 2.16.79 3.93 1.87 5.41 3.15a12.82 12.82 0 0 1 3.36 4.74 16.07 16.07 0 0 1 1.18 6.1v1c0 3.35-.99 6-2.86 8.08a14.79 14.79 0 0 1-6.9 4.14v1.58c2.76.69 5.13 2.07 6.9 4.14 1.97 1.97 2.86 4.73 2.86 8.09v.98c0 2.17-.4 4.14-1.18 6.02a11.31 11.31 0 0 1-3.36 4.93 16.47 16.47 0 0 1-5.42 3.15 20.59 20.59 0 0 1-7.3 1.19zm16.57-24.06v13.5h8a9.86 9.86 0 0 0 5.71-1.47c1.48-.99 2.17-2.67 2.17-5.03v-.5c0-2.26-.7-3.94-2.17-4.93a9.66 9.66 0 0 0-5.72-1.57zm0-23.87v13.32h8a9.86 9.86 0 0 0 5.71-1.48c1.48-.99 2.17-2.57 2.17-4.93v-.5c0-2.36-.7-3.94-2.17-4.93a9.86 9.86 0 0 0-5.72-1.48z">
                              </path>
                            </g>
                          </svg>
                        </a>
                        <div class="flex items-center gap-4">
                          <a rel="noopener" href="https://twitter.com/biomejs">
                            <svg
                              xmlns="http://www.w3.org/2000/svg"
                              width="24"
                              height="24"
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="currentColor"
                              stroke-width="2"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              class="h-7 w-7 text-yellow-600 transition-colors duration-150 hover:text-yellow-500 hover:opacity-100"
                            >
                              <path d="M4 4l11.733 16h4.267l-11.733 -16z"></path>
                              <path d="M4 20l6.768 -6.768m2.46 -2.46l6.772 -6.772"></path>
                            </svg>
                          </a>
                          <a rel="noopener" href="https://discord.gg/BypW39g6Yc">
                            <svg
                              xmlns="http://www.w3.org/2000/svg"
                              width="24"
                              height="24"
                              viewBox="0 0 24 24"
                              fill="none"
                              stroke="currentColor"
                              stroke-width="2"
                              stroke-linecap="round"
                              stroke-linejoin="round"
                              class="h-7 w-7 text-yellow-600 transition-colors duration-150 hover:text-yellow-500 hover:opacity-100"
                            >
                              <path d="M8 12a1 1 0 1 0 2 0a1 1 0 0 0 -2 0"></path>
                              <path d="M14 12a1 1 0 1 0 2 0a1 1 0 0 0 -2 0"></path>
                              <path d="M15.5 17c0 1 1.5 3 2 3c1.5 0 2.833 -1.667 3.5 -3c.667 -1.667 .5 -5.833 -1.5 -11.5c-1.457 -1.015 -3 -1.34 -4.5 -1.5l-.972 1.923a11.913 11.913 0 0 0 -4.053 0l-.975 -1.923c-1.5 .16 -3.043 .485 -4.5 1.5c-2 5.667 -2.167 9.833 -1.5 11.5c.667 1.333 2 3 3.5 3c.5 0 2 -2 2 -3">
                              </path>
                              <path d="M7 16.5c3.5 1 6.5 1 10 0"></path>
                            </svg>
                          </a><a rel="noopener noreferrer" href="https://github.com/biomejs"><svg
                            xmlns="http://www.w3.org/2000/svg"
                            width="24"
                            height="24"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            class="h-7 w-7 text-yellow-600 transition-colors duration-150 hover:text-yellow-500 hover:opacity-100"
                          ><path d="M9 19c-4.3 1.4 -4.3 -2.5 -6 -3m12 5v-3.5c0 -1 .1 -1.4 -.5 -2c2.8 -.3 5.5 -1.4 5.5 -6a4.6 4.6 0 0 0 -1.3 -3.2a4.2 4.2 0 0 0 -.1 -3.2s-1.1 -.3 -3.5 1.3a12.3 12.3 0 0 0 -6.2 0c-2.4 -1.6 -3.5 -1.3 -3.5 -1.3a4.2 4.2 0 0 0 -.1 3.2a4.6 4.6 0 0 0 -1.3 3.2c0 4.6 2.7 5.7 5.5 6c-.6 .6 -.6 1.2 -.5 2v3.5"></path></svg></a><a
                            rel="noopener"
                            href="https://fosstodon.org/@biomejs"
                          ><svg
                            xmlns="http://www.w3.org/2000/svg"
                            width="24"
                            height="24"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            class="h-7 w-7 text-yellow-600 transition-colors duration-150 hover:text-yellow-500 hover:opacity-100"
                          ><path d="M18.648 15.254c-1.816 1.763 -6.648 1.626 -6.648 1.626a18.262 18.262 0 0 1 -3.288 -.256c1.127 1.985 4.12 2.81 8.982 2.475c-1.945 2.013 -13.598 5.257 -13.668 -7.636l-.026 -1.154c0 -3.036 .023 -4.115 1.352 -5.633c1.671 -1.91 6.648 -1.666 6.648 -1.666s4.977 -.243 6.648 1.667c1.329 1.518 1.352 2.597 1.352 5.633s-.456 4.074 -1.352 4.944z"></path><path d="M12 11.204v-2.926c0 -1.258 -.895 -2.278 -2 -2.278s-2 1.02 -2 2.278v4.722m4 -4.722c0 -1.258 .895 -2.278 2 -2.278s2 1.02 2 2.278v4.722"></path></svg></a><a
                            rel="noopener"
                            href="https://biomejs.dev"
                          ><svg
                            xmlns="http://www.w3.org/2000/svg"
                            width="24"
                            height="24"
                            viewBox="0 0 24 24"
                            fill="none"
                            stroke="currentColor"
                            stroke-width="2"
                            stroke-linecap="round"
                            stroke-linejoin="round"
                            class="h-7 w-7 text-yellow-600 transition-colors duration-150 hover:text-yellow-500 hover:opacity-100"
                          ><path d="M3 12a9 9 0 1 0 18 0a9 9 0 0 0 -18 0"></path><path d="M3.6 9h16.8"></path><path d="M3.6 15h16.8"></path><path d="M11.5 3a17 17 0 0 0 0 18"></path><path d="M12.5 3a17 17 0 0 1 0 18"></path></svg></a>
                        </div>
                      </div>
                    </div>
                    <dl class="mt-4 grid grid-cols-1 gap-4 overflow-hidden rounded-2xl text-center sm:grid-cols-2 lg:grid-cols-4">
                      <a
                        target="_blank"
                        rel="noopener noreferrer"
                        class="group relative flex flex-col bg-purple-950 p-8 transition-colors duration-150 hover:bg-gray-800"
                        href="https://github.com/biomejs/biome/blob/main/crates/biome_js_formatter/report.md"
                      >
                        <div class="absolute left-0 top-0 z-0 h-full w-full bg-[radial-gradient(ellipse_at_top_left,_var(--tw-gradient-stops))] from-gray-800 via-gray-900 to-gray-950">
                        </div>
                        <div class="absolute left-0 top-0 z-0 h-full w-full bg-purple-900/10 transition-colors duration-150 group-hover:bg-purple-900/20">
                        </div>
                        <div class="relative">
                          <dt class="text-sm font-semibold leading-6 text-gray-300">
                            Average compatibility
                          </dt>
                          <dd class="order-first text-3xl font-semibold tracking-tight text-white">
                            96.10%
                          </dd>
                        </div>
                      </a>
                      <a
                        target="_blank"
                        rel="noopener noreferrer"
                        class="group relative flex flex-col bg-purple-950 p-8 transition-colors duration-150 hover:bg-gray-800"
                        href="https://github.com/biomejs/biome/blob/main/crates/biome_js_formatter/report.md"
                      >
                        <div class="absolute left-0 top-0 z-0 h-full w-full bg-[radial-gradient(ellipse_at_top_left,_var(--tw-gradient-stops))] from-gray-800 via-gray-900 to-gray-950">
                        </div>
                        <div class="absolute left-0 top-0 z-0 h-full w-full bg-purple-900/10 transition-colors duration-150 group-hover:bg-purple-900/20">
                        </div>
                        <div class="relative">
                          <dt class="text-sm font-semibold leading-6 text-gray-300">
                            Compatible lines
                          </dt>
                          <dd class="order-first text-3xl font-semibold tracking-tight text-white">
                            96.62%
                          </dd>
                        </div>
                      </a><a
                        target="_blank"
                        rel="noopener noreferrer"
                        class="group relative flex flex-col bg-purple-950 p-8 transition-colors duration-150 hover:bg-gray-800"
                        href="https://github.com/biomejs/biome/pulls?q=challenge%28formatter%29"
                      ><div class="absolute left-0 top-0 z-0 h-full w-full bg-[radial-gradient(ellipse_at_top_left,_var(--tw-gradient-stops))] from-gray-800 via-gray-900 to-gray-950"></div><div class="absolute left-0 top-0 z-0 h-full w-full bg-purple-900/10 transition-colors duration-150 group-hover:bg-purple-900/20"></div><div class="relative"><dt class="text-sm font-semibold leading-6 text-gray-300">Pull requests</dt><dd class="order-first text-3xl font-semibold tracking-tight text-white">42</dd></div></a><a
                        target="_blank"
                        rel="noopener noreferrer"
                        class="group relative flex flex-col bg-purple-950 p-8 transition-colors duration-150 hover:bg-gray-800"
                        href="https://github.com/biomejs/biome/pulls?q=challenge%28formatter%29"
                      ><div class="absolute left-0 top-0 z-0 h-full w-full bg-[radial-gradient(ellipse_at_top_left,_var(--tw-gradient-stops))] from-gray-800 via-gray-900 to-gray-950"></div><div class="absolute left-0 top-0 z-0 h-full w-full bg-purple-900/10 transition-colors duration-150 group-hover:bg-purple-900/20"></div><div class="relative"><dt class="text-sm font-semibold leading-6 text-gray-300">Contributors</dt><dd class="order-first text-3xl font-semibold tracking-tight text-white">9</dd></div></a>
                    </dl>
                    <div class="scrollbar-thin -mb-4 mt-8 overflow-x-auto pb-4">
                      <table class="w-full whitespace-nowrap text-left">
                        <colgroup>
                          <col class="w-full sm:w-4/12" /><col class="lg:w-4/12" /><col class="lg:w-2/12" /><col class="lg:w-1/12" /><col class="lg:w-1/12" />
                        </colgroup>
                        <thead class="border-b border-white/10 text-sm leading-6 text-white">
                          <tr>
                            <th
                              scope="col"
                              class="py-2 pl-12 pr-8 text-base font-semibold sm:pl-14 sm:text-xl"
                            >
                              Contributor
                            </th>
                            <th
                              scope="col"
                              class="py-2 pl-0 pr-8 text-base font-semibold sm:table-cell sm:text-xl"
                            >
                              Pull request
                            </th>
                            <th
                              scope="col"
                              class="py-2 pl-0 text-center text-base font-semibold sm:text-xl"
                            >
                              Status
                            </th>
                            <th
                              scope="col"
                              class="py-2 pl-4 pr-6 text-right text-base font-semibold sm:table-cell sm:pl-8 sm:pr-0 sm:text-xl lg:pl-20"
                            >
                              Created
                            </th>
                          </tr>
                        </thead>
                        <tbody class="divide-y divide-white/5">
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/faultyserver"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/783733?v=4"
                                  alt="faultyserver"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  faultyserver
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/627"
                              >
                                add `bracketSpacing` option matching Prettier's setting
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-10-30T00:23:29Z">Oct 30, 2023, 02:23:29 AM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/Conaclos"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/2358560?u=a1c44faaf0503bdc1c55bd4a0a5a9b5776c8594f&amp;v=4"
                                  alt="Conaclos"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  Conaclos
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/719"
                              >
                                predictable order of type parameter modifiers
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-14T14:16:01Z">Nov 14, 2023, 04:16:01 PM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/Conaclos"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/2358560?u=a1c44faaf0503bdc1c55bd4a0a5a9b5776c8594f&amp;v=4"
                                  alt="Conaclos"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  Conaclos
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/730"
                              >
                                Attach comments to labels
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-14T22:24:15Z">Nov 15, 2023, 00:24:15 AM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/TaKO8Ki"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/41065217?u=54ba8f078375dcf0e23a49a5e0716c36f8f89635&amp;v=4"
                                  alt="TaKO8Ki"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  TaKO8Ki
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/733"
                              >
                                fix self closing compatibility with Prettier
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-15T04:56:58Z">Nov 15, 2023, 06:56:58 AM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/Conaclos"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/2358560?u=a1c44faaf0503bdc1c55bd4a0a5a9b5776c8594f&amp;v=4"
                                  alt="Conaclos"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  Conaclos
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/734"
                              >
                                don't print empty import assertion
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-15T13:19:50Z">Nov 15, 2023, 03:19:50 PM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/Conaclos"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/2358560?u=a1c44faaf0503bdc1c55bd4a0a5a9b5776c8594f&amp;v=4"
                                  alt="Conaclos"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  Conaclos
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/738"
                              >
                                add parens around instantiation expr when needed
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-15T22:57:36Z">Nov 16, 2023, 00:57:36 AM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/victor-teles"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/78874691?u=5564c16cc8020a4cf675d4d00e8b4b52fc9d2d5a&amp;v=4"
                                  alt="victor-teles"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  victor-teles
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/740"
                              >
                                consider JsArrayHole as simple argument
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-16T00:15:28Z">Nov 16, 2023, 02:15:28 AM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/Conaclos"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/2358560?u=a1c44faaf0503bdc1c55bd4a0a5a9b5776c8594f&amp;v=4"
                                  alt="Conaclos"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  Conaclos
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/743"
                              >
                                fix arrow function expression needs parens
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-16T10:40:54Z">Nov 16, 2023, 00:40:54 PM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/Conaclos"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/2358560?u=a1c44faaf0503bdc1c55bd4a0a5a9b5776c8594f&amp;v=4"
                                  alt="Conaclos"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  Conaclos
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/746"
                              >
                                fix uneeded parens on decoaretd class expr
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-16T16:24:03Z">Nov 16, 2023, 06:24:03 PM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/Conaclos"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/2358560?u=a1c44faaf0503bdc1c55bd4a0a5a9b5776c8594f&amp;v=4"
                                  alt="Conaclos"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  Conaclos
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/748"
                              >
                                fix default export expression parens
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-16T16:57:22Z">Nov 16, 2023, 06:57:22 PM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/Conaclos"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/2358560?u=a1c44faaf0503bdc1c55bd4a0a5a9b5776c8594f&amp;v=4"
                                  alt="Conaclos"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  Conaclos
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/749"
                              >
                                no space after asserts without predicate
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-16T17:19:03Z">Nov 16, 2023, 07:19:03 PM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/faultyserver"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/783733?v=4"
                                  alt="faultyserver"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  faultyserver
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/750"
                              >
                                (also parser) Respect, parse, and format BOM characters from source files
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-17T09:16:47Z">Nov 17, 2023, 11:16:47 AM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/Conaclos"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/2358560?u=a1c44faaf0503bdc1c55bd4a0a5a9b5776c8594f&amp;v=4"
                                  alt="Conaclos"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  Conaclos
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/752"
                              >
                                ignore embdedded languages and unstable syntaxes
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-17T14:58:16Z">Nov 17, 2023, 04:58:16 PM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/Conaclos"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/2358560?u=a1c44faaf0503bdc1c55bd4a0a5a9b5776c8594f&amp;v=4"
                                  alt="Conaclos"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  Conaclos
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/754"
                              >
                                edge case with expression statement and type cast
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-17T16:06:48Z">Nov 17, 2023, 06:06:48 PM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/victor-teles"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/78874691?u=5564c16cc8020a4cf675d4d00e8b4b52fc9d2d5a&amp;v=4"
                                  alt="victor-teles"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  victor-teles
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/756"
                              >
                                handle line break and comments for array holes
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-17T20:05:01Z">Nov 17, 2023, 10:05:01 PM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/faultyserver"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/783733?v=4"
                                  alt="faultyserver"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  faultyserver
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/757"
                              >
                                Handle more unary and update expressions as simple arguments
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-17T21:07:11Z">Nov 17, 2023, 11:07:11 PM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/Conaclos"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/2358560?u=a1c44faaf0503bdc1c55bd4a0a5a9b5776c8594f&amp;v=4"
                                  alt="Conaclos"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  Conaclos
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/760"
                              >
                                remove trailing spaces after shebang
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-17T21:29:15Z">Nov 17, 2023, 11:29:15 PM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/faultyserver"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/783733?v=4"
                                  alt="faultyserver"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  faultyserver
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/762"
                              >
                                allow `require` to split lines
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-17T21:43:51Z">Nov 17, 2023, 11:43:51 PM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/Conaclos"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/2358560?u=a1c44faaf0503bdc1c55bd4a0a5a9b5776c8594f&amp;v=4"
                                  alt="Conaclos"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  Conaclos
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/764"
                              >
                                ignore throw expression
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-17T21:54:36Z">Nov 17, 2023, 11:54:36 PM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/Conaclos"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/2358560?u=a1c44faaf0503bdc1c55bd4a0a5a9b5776c8594f&amp;v=4"
                                  alt="Conaclos"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  Conaclos
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/767"
                              >
                                format numeric properties and unquote exact floats
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-17T23:51:45Z">Nov 18, 2023, 01:51:45 AM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/unvalley"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/38400669?u=cbe753ea76f6a8666f7b3dced3fec749b6cc7e5a&amp;v=4"
                                  alt="unvalley"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  unvalley
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/768"
                              >
                                quit hard line break if default clause has no consequent
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-18T06:24:17Z">Nov 18, 2023, 08:24:17 AM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/TaKO8Ki"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/41065217?u=54ba8f078375dcf0e23a49a5e0716c36f8f89635&amp;v=4"
                                  alt="TaKO8Ki"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  TaKO8Ki
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/770"
                              >
                                add a block indent to dangling comments
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-18T13:38:13Z">Nov 18, 2023, 03:38:13 PM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/TaKO8Ki"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/41065217?u=54ba8f078375dcf0e23a49a5e0716c36f8f89635&amp;v=4"
                                  alt="TaKO8Ki"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  TaKO8Ki
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/772"
                              >
                                check if the third member of test call expression is appropriate
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-18T20:47:37Z">Nov 18, 2023, 10:47:37 PM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/victor-teles"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/78874691?u=5564c16cc8020a4cf675d4d00e8b4b52fc9d2d5a&amp;v=4"
                                  alt="victor-teles"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  victor-teles
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/773"
                              >
                                fix unnecessary indent to nested await
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-18T23:18:42Z">Nov 19, 2023, 01:18:42 AM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/Gumichocopengin8"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/34010665?u=2ece34080a2e47e144e2dc303539f52906c8fc1b&amp;v=4"
                                  alt="Gumichocopengin8"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  Gumichocopengin8
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/774"
                              >
                                respect prettier `Range` options
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-19T00:19:43Z">Nov 19, 2023, 02:19:43 AM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/Yash-Singh1"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/53054099?u=cb5b0c881e0c9f7c7aa00da0a6b5bed62da4618e&amp;v=4"
                                  alt="Yash-Singh1"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  Yash-Singh1
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/775"
                              >
                                fix typescript/union/inlining
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-19T03:31:34Z">Nov 19, 2023, 05:31:34 AM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/victor-teles"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/78874691?u=5564c16cc8020a4cf675d4d00e8b4b52fc9d2d5a&amp;v=4"
                                  alt="victor-teles"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  victor-teles
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/776"
                              >
                                assignment with await/yield do not break
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-19T07:00:25Z">Nov 19, 2023, 09:00:25 AM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/faultyserver"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/783733?v=4"
                                  alt="faultyserver"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  faultyserver
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/777"
                              >
                                Handle special first-argument expansions in call arguments
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-19T07:57:47Z">Nov 19, 2023, 09:57:47 AM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/TaKO8Ki"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/41065217?u=54ba8f078375dcf0e23a49a5e0716c36f8f89635&amp;v=4"
                                  alt="TaKO8Ki"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  TaKO8Ki
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/780"
                              >
                                fix prettier differences in test declarations
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-19T10:17:28Z">Nov 19, 2023, 00:17:28 PM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/suxin2017"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/28481035?u=eb4a1f69cf00a57a4c8a65f7ee8f8857186a3142&amp;v=4"
                                  alt="suxin2017"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  suxin2017
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/785"
                              >
                                arrows comment
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-19T14:11:56Z">Nov 19, 2023, 04:11:56 PM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/SuperchupuDev"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/53496941?u=6fa0ed9e99def45f50eddf49b5fa8c840462c01e&amp;v=4"
                                  alt="SuperchupuDev"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  SuperchupuDev
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/786"
                              >
                                add `lineEnding` option
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-19T15:41:56Z">Nov 19, 2023, 05:41:56 PM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/TaKO8Ki"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/41065217?u=54ba8f078375dcf0e23a49a5e0716c36f8f89635&amp;v=4"
                                  alt="TaKO8Ki"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  TaKO8Ki
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/789"
                              >
                                add parens to tail body for a chain of arrow functions
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-19T17:43:53Z">Nov 19, 2023, 07:43:53 PM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/Conaclos"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/2358560?u=a1c44faaf0503bdc1c55bd4a0a5a9b5776c8594f&amp;v=4"
                                  alt="Conaclos"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  Conaclos
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/790"
                              >
                                highligh prettier reformat issue
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-19T18:11:21Z">Nov 19, 2023, 08:11:21 PM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/faultyserver"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/783733?v=4"
                                  alt="faultyserver"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  faultyserver
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/793"
                              >
                                Fix multi-expression template literal indention
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-19T19:18:59Z">Nov 19, 2023, 09:18:59 PM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/Yash-Singh1"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/53054099?u=cb5b0c881e0c9f7c7aa00da0a6b5bed62da4618e&amp;v=4"
                                  alt="Yash-Singh1"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  Yash-Singh1
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/794"
                              >
                                fix typescript declarations and soft wrap index signatures
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-19T19:25:02Z">Nov 19, 2023, 09:25:02 PM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/faultyserver"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/783733?v=4"
                                  alt="faultyserver"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  faultyserver
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/799"
                              >
                                Implement `bracketSameLine` option to match Prettier
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-20T00:27:55Z">Nov 20, 2023, 02:27:55 AM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/victor-teles"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/78874691?u=5564c16cc8020a4cf675d4d00e8b4b52fc9d2d5a&amp;v=4"
                                  alt="victor-teles"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  victor-teles
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/801"
                              >
                                sloppy mode tests
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-20T03:20:09Z">Nov 20, 2023, 05:20:09 AM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/Yash-Singh1"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/53054099?u=cb5b0c881e0c9f7c7aa00da0a6b5bed62da4618e&amp;v=4"
                                  alt="Yash-Singh1"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  Yash-Singh1
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/802"
                              >
                                `noInitializerWithDefinite` rule
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-20T04:54:22Z">Nov 20, 2023, 06:54:22 AM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/suxin2017"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/28481035?u=eb4a1f69cf00a57a4c8a65f7ee8f8857186a3142&amp;v=4"
                                  alt="suxin2017"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  suxin2017
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/804"
                              >
                                arrows chain as arg
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-20T09:34:08Z">Nov 20, 2023, 11:34:08 AM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/Conaclos"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/2358560?u=a1c44faaf0503bdc1c55bd4a0a5a9b5776c8594f&amp;v=4"
                                  alt="Conaclos"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  Conaclos
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/806"
                              >
                                disambiguate unary expr in instanceof and in expr
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-20T09:50:44Z">Nov 20, 2023, 11:50:44 AM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/Conaclos"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/2358560?u=a1c44faaf0503bdc1c55bd4a0a5a9b5776c8594f&amp;v=4"
                                  alt="Conaclos"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  Conaclos
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/814"
                              >
                                handle let variable name in non-strict mode
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-21T11:33:50Z">Nov 21, 2023, 01:33:50 PM</time>
                            </td>
                          </tr>
                          <tr>
                            <td class="py-4 pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="flex items-center gap-x-4"
                                href="https://github.com/Conaclos"
                              >
                                <img
                                  src="https://avatars.githubusercontent.com/u/2358560?u=a1c44faaf0503bdc1c55bd4a0a5a9b5776c8594f&amp;v=4"
                                  alt="Conaclos"
                                  class="h-8 w-8 rounded-full bg-gray-800 sm:h-10 sm:w-10"
                                />
                                <div class="truncate text-xs font-medium leading-6 text-white sm:text-sm">
                                  Conaclos
                                </div>
                              </a>
                            </td>
                            <td class="w-full py-4 pl-0 pr-4 sm:table-cell sm:pr-8">
                              <a
                                rel="noopener noreferrer"
                                class="truncate text-xs font-medium leading-6 text-white sm:text-sm"
                                href="https://github.com/biomejs/biome/pull/816"
                              >
                                indent nested conditional expressions
                              </a>
                            </td>
                            <td class="py-4 pl-0 text-xs leading-6 sm:text-sm">
                              <div class="flex items-center justify-center gap-x-2">
                                <div class="text-green-400 bg-green-400/10 flex-none rounded-full p-1">
                                  <div class="h-1.5 w-1.5 rounded-full bg-current"></div>
                                </div>
                                <div class="text-white">Merged</div>
                              </div>
                            </td>
                            <td class="py-4 pl-4 pr-6 text-right text-xs leading-6 text-gray-400 sm:table-cell sm:pl-8 sm:pr-0 sm:text-sm lg:pl-20">
                              <time datetime="2023-11-21T13:51:56Z">Nov 21, 2023, 03:51:56 PM</time>
                            </td>
                          </tr>
                        </tbody>
                      </table>
                    </div>
                  </div>
                </div>
              </section>
            </div>
          </div>
        </article>
      </main>
      <Footer.footer />
    </div>
    """
  end
end
