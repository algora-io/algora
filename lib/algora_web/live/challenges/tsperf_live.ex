defmodule AlgoraWeb.Challenges.TsperfLive do
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
                  <div class="max-w-6xl pt-24 md:pt-48">
                    <h1 class="!mb-2 text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                      <span class="[text-shadow:#020617_1px_0_10px]">
                        Build a VSCode plugin for TypeScript
                      </span>
                      <br /><span style="background:radial-gradient(53.44% 245.78% at 13.64% 46.56%, #6ee7b7 0%, #2dd4bf 100%);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;text-fill-color:transparent">
                        Win<!-- -->
                        <span class="font-mono text-[2.5rem] md:text-[5rem]">$15,000</span>
                      </span>
                    </h1>
                    <p class="mb-8 w-4/5 text-lg font-medium leading-none tracking-tight opacity-80 md:w-full md:text-xl md:opacity-70">
                      The TSPerf Bounty is a challenge to build a VSCode plugin that shows you the complexity / time to load of a type in TypeScript
                    </p>
                    <div class="grid gap-6 md:grid-cols-2 md:pt-12">
                      <div class="group hover:no-underline">
                        <div
                          class="relative flex h-full max-w-2xl overflow-hidden rounded-3xl border-2 border-solid border-[#6366f1] px-5 py-4 md:px-7 md:py-5"
                          style="background:radial-gradient(circle at bottom right, #c7d2fe 0%, #6366f1 28%, #1e1b4b 63.02%, #050217 100%);box-shadow:0px 3.26536px 2.21381px 0px rgba(30, 27, 75, 0.08), 0px 7.84712px 5.32008px 0px rgba(30, 27, 75, 0.11), 0px 14.77543px 10.01724px 0px rgba(30, 27, 75, 0.14), 0px 26.35684px 17.86905px 0px rgba(30, 27, 75, 0.16), 0px 49.29758px 33.42209px 0px rgba(30, 27, 75, 0.19), 0px 118px 80px 0px rgba(30, 27, 75, 0.27)"
                        >
                          <div class="flex flex-1 flex-col">
                            <h2 class="!mb-0 !mt-0 text-4xl font-black leading-none tracking-tighter md:text-6xl">
                              Grand Prize
                            </h2>
                            <h3
                              class="text-3xl font-black leading-none tracking-tighter md:text-5xl"
                              style="background:radial-gradient(53.44% 245.78% at 13.64% 46.56%, #6ee7b7 0%, #2dd4bf 100%);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;text-fill-color:transparent"
                            >
                              <div class="font-mono text-4xl md:text-6xl">$10,000</div>
                            </h3>
                            <p class="flex-1 pb-8 pt-4 text-lg font-medium leading-none tracking-tight opacity-70 md:text-xl">
                              Build a VSCode plugin for TypeScript
                            </p>
                          </div>
                          <div
                            class="absolute inset-0 opacity-20 mix-blend-overlay"
                            style="background:url(/images/grid.png)"
                          >
                          </div>
                        </div>
                      </div>
                      <div class="group relative flex flex-1 flex-col rounded-2xl border-2 border-solid border-white bg-zinc-950/70 p-4 md:p-6">
                        <h2 class="!mb-0 !mt-0 text-4xl font-black leading-none tracking-tighter md:text-6xl">
                          Livestream Prize
                        </h2>
                        <h3
                          class="font-mono text-4xl font-black leading-none tracking-tighter md:text-6xl"
                          style="background:radial-gradient(53.44% 245.78% at 13.64% 46.56%, #6ee7b7 0%, #2dd4bf 100%);-webkit-background-clip:text;-webkit-text-fill-color:transparent;background-clip:text;text-fill-color:transparent"
                        >
                          $5,000
                        </h3>
                        <p class="flex-1 pb-8 pt-4 text-lg font-medium leading-none tracking-tight opacity-70 md:text-xl">
                          Livestream on Algora TV while you build it
                        </p>
                      </div>
                    </div>
                  </div>
                </div>
                <div
                  class="absolute inset-0 z-10 h-[810px]"
                  style="background:linear-gradient(90deg, rgba(28, 26, 29, 0.4) 0%, rgba(28, 26, 29, 0) 64.42%),linear-gradient(0deg, #050217 1%, rgba(28, 26, 29, 0) 30%)"
                >
                  <div class="absolute inset-0 bg-gradient-to-br from-transparent to-purple-700/60 mix-blend-multiply">
                  </div>
                  <div class="absolute inset-0 bg-[linear-gradient(to_left,rgba(0,_0,_0,_0),rgba(0,_0,_0,_0.69))]">
                  </div>
                </div>
                <div class="absolute inset-0 z-0 h-[810px]">
                  <img
                    src="/images/challenges/tsperf/hero.png"
                    alt="Background"
                    class="h-full w-full object-cover object-[50%]"
                  />
                </div>
              </section>
              <section class="mb-24 md:mb-36">
                <div class="relative z-30 mx-auto max-w-7xl px-6 lg:px-8">
                  <div class="mb-6 md:mb-10">
                    <h2 class="flex justify-center text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                      Sponsors
                    </h2>
                    <div class="mx-auto grid max-w-6xl gap-16 pt-16 text-center md:grid-cols-3">
                      <a
                        target="_blank"
                        rel="noopener"
                        class="flex h-full flex-1 flex-col items-center text-white no-underline hover:no-underline"
                        href="https://unkey.com"
                      >
                        <img
                          src="/images/wordmarks/unkey.png"
                          alt="Unkey"
                          class="-mb-2 md:mb-0 md:-mt-2 h-24 w-auto saturate-0"
                        />
                        <h3 class="mt-auto text-2xl font-extrabold leading-none tracking-tighter text-purple-100 mix-blend-exclusion md:text-4xl xl:text-xl">
                          Open Source<br /> API Key Management
                        </h3>
                      </a><a
                        target="_blank"
                        rel="noopener"
                        class="flex h-full flex-1 flex-col items-center text-white no-underline hover:no-underline"
                        href="https://scalar.com"
                      ><img src="/images/wordmarks/scalar.png" alt="Scalar" class="h-20 w-auto saturate-0" /><h3 class="mt-auto text-2xl font-extrabold leading-none tracking-tighter text-purple-100 mix-blend-exclusion md:text-4xl xl:text-xl">Open Source<br /> API Documentation</h3></a><a
                        target="_blank"
                        rel="noopener"
                        class="flex h-full flex-1 flex-col items-center text-white no-underline hover:no-underline"
                        href="https://tigrisdata.com"
                      ><img
                        src="https://assets-global.website-files.com/657988158c7fb30f4d9ef37b/657990b61fd3a5d674cf2298_tigris-logo.svg"
                        alt="Tigris"
                        class="mb-4 md:mb-0 md:mt-4 h-16 w-auto saturate-0"
                      /><h3 class="mt-auto text-2xl font-extrabold leading-none tracking-tighter text-purple-100 mix-blend-exclusion md:text-4xl xl:text-xl">Globally Distributed<br /> Object Storage</h3></a>
                    </div>
                  </div>
                </div>
              </section>
              <section class="mb-24 md:mb-36">
                <div class="mx-auto grid max-w-7xl gap-8 md:grid-cols-2">
                  <div class="relative z-50 divide-y divide-white/10 px-6 pt-6 lg:px-8">
                    <h2 class="text-2xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-5xl">
                      Challenge specs
                    </h2>
                    <div class="mt-4 space-y-4 divide-y divide-white/10">
                      <div class="pt-4">
                        <div>
                          <div class="flex w-full items-start justify-between text-left text-white">
                            <span class="text-base font-medium leading-7">
                              The bounty is split into two distinct prizes: Grand Prize &amp; Livestream Prize.
                            </span>
                          </div>
                        </div>
                      </div>
                      <div class="pt-4">
                        <div>
                          <div class="flex w-full items-start justify-between text-left text-white">
                            <span class="text-base font-medium leading-7">
                              Winning the Grand Prize requires building and open sourcing an MIT licensed VSCode plugin that shows you the complexity / time to load of a type in TypeScript
                            </span>
                          </div>
                        </div>
                      </div>
                      <div class="pt-4">
                        <div>
                          <div class="flex w-full items-start justify-between text-left text-white">
                            <span class="text-base font-medium leading-7">
                              Winning the Livestream Prize requires livestreaming on Algora TV while you build it.
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
                    </div>
                  </div>
                  <div class="px-4">
                    <div class="relative aspect-[704/605] overflow-hidden rounded-xl shadow-[0px_3.26536px_2.21381px_0px_rgba(30,_27,_75,_0.08),_0px_7.84712px_5.32008px_0px_rgba(30,_27,_75,_0.11),_0px_14.77543px_10.01724px_0px_rgba(30,_27,_75,_0.14),_0px_26.35684px_17.86905px_0px_rgba(30,_27,_75,_0.16),_0px_49.29758px_33.42209px_0px_rgba(30,_27,_75,_0.19),_0px_118px_80px_0px_rgba(30,_27,_75,_0.27)] ring-1 ring-white/15">
                      <img
                        alt="Example"
                        loading="lazy"
                        style="position:absolute;height:100%;width:100%;left:0;top:0;right:0;bottom:0;color:transparent"
                        src="/images/challenges/tsperf/example.png"
                      />
                    </div>
                    <div class="mt-4 text-center text-lg font-medium text-purple-100">
                      Example VSCode plugin
                    </div>
                  </div>
                </div>
              </section>
              <section class="my-24 md:my-36">
                <h2 class="flex justify-center text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                  Submissions
                </h2>
                <div class="mx-auto flex flex-col items-start justify-center gap-4 px-4 pt-6 sm:flex-row md:pt-12">
                  <a
                    rel="noopener noreferrer"
                    class="relative aspect-[1200/600] w-full max-w-xl overflow-hidden rounded-xl rounded-r-none shadow-[0px_3.26536px_2.21381px_0px_rgba(30,_27,_75,_0.08),_0px_7.84712px_5.32008px_0px_rgba(30,_27,_75,_0.11),_0px_14.77543px_10.01724px_0px_rgba(30,_27,_75,_0.14),_0px_26.35684px_17.86905px_0px_rgba(30,_27,_75,_0.16),_0px_49.29758px_33.42209px_0px_rgba(30,_27,_75,_0.19),_0px_118px_80px_0px_rgba(30,_27,_75,_0.27)] ring-1 ring-white/15"
                    href="https://github.com/tsperf/tracer"
                  >
                    <img
                      alt="tsperf/tracer"
                      loading="lazy"
                      style="position:absolute;height:100%;width:100%;left:0;top:0;right:0;bottom:0;color:transparent"
                      src="/images/challenges/tsperf/tracer-repo.png"
                    />
                  </a><a
                    rel="noopener noreferrer"
                    class="relative aspect-[1200/600] w-full max-w-xl overflow-hidden rounded-xl rounded-l-none shadow-[0px_3.26536px_2.21381px_0px_rgba(30,_27,_75,_0.08),_0px_7.84712px_5.32008px_0px_rgba(30,_27,_75,_0.11),_0px_14.77543px_10.01724px_0px_rgba(30,_27,_75,_0.14),_0px_26.35684px_17.86905px_0px_rgba(30,_27,_75,_0.16),_0px_49.29758px_33.42209px_0px_rgba(30,_27,_75,_0.19),_0px_118px_80px_0px_rgba(30,_27,_75,_0.27)] ring-1 ring-white/15"
                    href="https://marketplace.visualstudio.com/items?itemName=tsperf.tracer"
                  ><img
                    alt="Type Complexity Tracer"
                    loading="lazy"
                    style="position:absolute;height:100%;width:100%;left:0;top:0;right:0;bottom:0;color:transparent"
                    src="/images/challenges/tsperf/tracer-extension.png"
                  /></a>
                </div>
                <div class="px-4 pt-8">
                  <button
                    type="button"
                    aria-haspopup="dialog"
                    aria-expanded="false"
                    aria-controls="radix-:Reaf6:"
                    data-state="closed"
                    class="group relative mx-auto flex aspect-[1200/600] w-full max-w-xl flex-1 flex-col overflow-hidden rounded-xl border-2 border-solid border-white p-4 text-left transition-all md:p-6"
                    style="box-shadow:0px 3.26536px 2.21381px 0px rgba(30, 27, 75, 0.08), 0px 7.84712px 5.32008px 0px rgba(30, 27, 75, 0.11), 0px 14.77543px 10.01724px 0px rgba(30, 27, 75, 0.14), 0px 26.35684px 17.86905px 0px rgba(30, 27, 75, 0.16), 0px 49.29758px 33.42209px 0px rgba(30, 27, 75, 0.19), 0px 118px 80px 0px rgba(30, 27, 75, 0.27)"
                  >
                    <div class="absolute inset-0 bg-[radial-gradient(circle_at_bottom_right,_#cbcee1_0%,_#65688b_28%,_#050217_63.02%,_#050217_100%)] opacity-100 transition-opacity group-hover:opacity-75">
                    </div>
                    <div
                      class="absolute inset-0 bg-cover bg-center opacity-100 mix-blend-overlay"
                      style="background-image:url(/images/challenges/solve.png)"
                    >
                    </div>
                    <div
                      class="absolute inset-0 opacity-50 mix-blend-overlay"
                      style="background:url(/images/grid.png)"
                    >
                    </div>
                    <div class="relative flex h-full flex-col">
                      <h3 class="!mt-0 mb-12 text-3xl font-black leading-none tracking-tighter md:text-6xl">
                        Submit a solution
                      </h3>
                      <div class="mt-auto flex items-center">
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
                  </button>
                </div>
              </section>
              <section class="mx-auto my-24 max-w-7xl md:my-36">
                <h2 class="flex justify-center text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                  Livestreams
                </h2>
                <div class="mx-auto grid gap-6 px-6 sm:grid-cols-2 lg:px-8">
                  <a class="block pt-6 md:pt-12" href="https://tv.algora.io/typeholes/9472">
                    <div class="relative z-30 mx-auto max-w-7xl">
                      <div class="relative mx-auto">
                        <div class="group/card h-full border border-white/10 bg-white/[2%] bg-gradient-to-br from-white/[2%] via-white/[2%] to-white/[2%] md:gap-8 group relative flex-1 overflow-hidden rounded-xl bg-cover shadow-[0px_3.26536px_2.21381px_0px_rgba(69,_10,_10,_0.08),_0px_7.84712px_5.32008px_0px_rgba(69,_10,_10,_0.11),_0px_14.77543px_10.01724px_0px_rgba(69,_10,_10,_0.14),_0px_26.35684px_17.86905px_0px_rgba(69,_10,_10,_0.16),_0px_49.29758px_33.42209px_0px_rgba(69,_10,_10,_0.19),_0px_118px_80px_0px_rgba(69,_10,_10,_0.27)] ring-2 ring-red-500 hover:no-underline">
                          <div class="grid h-6 grid-cols-[1fr_auto_1fr] overflow-hidden border-b border-gray-800 ">
                            <div class="ml-2 flex items-center gap-1">
                              <div class="h-2 w-2 rounded-full bg-red-400"></div>
                              <div class="h-2 w-2 rounded-full bg-yellow-400"></div>
                              <div class="h-2 w-2 rounded-full bg-green-400"></div>
                            </div>
                            <div class="flex items-center justify-center">
                              <div class="text-xs text-gray-500">tv.algora.io</div>
                            </div>
                            <div></div>
                          </div>
                          <div class="relative flex aspect-[16/9] h-full w-full items-center justify-center text-balance bg-gray-950 text-center text-xl font-medium text-red-100 sm:text-2xl">
                            <div class="absolute right-2 top-2 hidden rounded-lg bg-red-500 px-2 py-1 text-2xl font-bold text-white [text-shadow:#450a0a_1px_0_2px] sm:right-5 sm:top-5 sm:text-4xl">
                              LIVE
                            </div>
                            <img
                              src="/asset/storage/v1/object/public/images/challenges/tsperf-larry-david.png"
                              alt="TSPerf Live Review with Larry &amp; David"
                            />
                          </div>
                        </div>
                      </div>
                    </div>
                  </a><a class="block pt-6 md:pt-12" href="https://tv.algora.io/danielroe/9476"><div class="relative z-30 mx-auto max-w-7xl"><div class="relative mx-auto"><div class="group/card h-full border border-white/10 bg-white/[2%] bg-gradient-to-br from-white/[2%] via-white/[2%] to-white/[2%] md:gap-8 group relative flex-1 overflow-hidden rounded-xl bg-cover shadow-[0px_3.26536px_2.21381px_0px_rgba(69,_10,_10,_0.08),_0px_7.84712px_5.32008px_0px_rgba(69,_10,_10,_0.11),_0px_14.77543px_10.01724px_0px_rgba(69,_10,_10,_0.14),_0px_26.35684px_17.86905px_0px_rgba(69,_10,_10,_0.16),_0px_49.29758px_33.42209px_0px_rgba(69,_10,_10,_0.19),_0px_118px_80px_0px_rgba(69,_10,_10,_0.27)] ring-2 ring-red-500 hover:no-underline"><div class="grid h-6 grid-cols-[1fr_auto_1fr] overflow-hidden border-b border-gray-800 "><div class="ml-2 flex items-center gap-1"><div class="h-2 w-2 rounded-full bg-red-400"></div><div class="h-2 w-2 rounded-full bg-yellow-400"></div><div class="h-2 w-2 rounded-full bg-green-400"></div></div><div class="flex items-center justify-center"><div class="text-xs text-gray-500">tv.algora.io</div></div><div></div></div><div class="relative flex aspect-[16/9] h-full w-full items-center justify-center text-balance bg-gray-950 text-center text-xl font-medium text-red-100 sm:text-2xl"><div class="absolute right-2 top-2 hidden rounded-lg bg-red-500 px-2 py-1 text-2xl font-bold text-white [text-shadow:#450a0a_1px_0_2px] sm:right-5 sm:top-5 sm:text-4xl">LIVE</div><img
                            src="/asset/storage/v1/object/public/images/challenges/tsperf-daniel-rhys.png"
                            alt="TSPerf Live Review with Daniel &amp; Rhys"
                          /></div></div></div></div></a>
                </div>
              </section>
              <section class="my-24 md:my-36">
                <h2 class="flex justify-center text-4xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-7xl">
                  Discussions
                </h2>
                <div class="mx-auto flex max-w-7xl flex-col items-start gap-2 px-4 pt-6 sm:flex-row md:pt-12">
                  <div class="flex w-full flex-col gap-2">
                    <a
                      rel="noopener noreferrer"
                      class="relative aspect-[1210/951] w-full overflow-hidden rounded-xl shadow-[0px_3.26536px_2.21381px_0px_rgba(30,_27,_75,_0.08),_0px_7.84712px_5.32008px_0px_rgba(30,_27,_75,_0.11),_0px_14.77543px_10.01724px_0px_rgba(30,_27,_75,_0.14),_0px_26.35684px_17.86905px_0px_rgba(30,_27,_75,_0.16),_0px_49.29758px_33.42209px_0px_rgba(30,_27,_75,_0.19),_0px_118px_80px_0px_rgba(30,_27,_75,_0.27)] ring-1 ring-white/15"
                      href="https://www.reddit.com/r/typescript/comments/1comkca/comment/l3gucio/"
                    >
                      <img
                        alt="Discussion on Reddit"
                        loading="lazy"
                        decoding="async"
                        data-nimg="fill"
                        style="position:absolute;height:100%;width:100%;left:0;top:0;right:0;bottom:0;color:transparent"
                        src="/images/challenges/tsperf/reddit.png"
                      />
                    </a>
                    <div class="relative aspect-[808/193] w-full overflow-hidden rounded-xl shadow-[0px_3.26536px_2.21381px_0px_rgba(30,_27,_75,_0.08),_0px_7.84712px_5.32008px_0px_rgba(30,_27,_75,_0.11),_0px_14.77543px_10.01724px_0px_rgba(30,_27,_75,_0.14),_0px_26.35684px_17.86905px_0px_rgba(30,_27,_75,_0.16),_0px_49.29758px_33.42209px_0px_rgba(30,_27,_75,_0.19),_0px_118px_80px_0px_rgba(30,_27,_75,_0.27)] ring-1 ring-white/15">
                      <img
                        alt="Rhys Sullivan's tweet"
                        loading="lazy"
                        decoding="async"
                        data-nimg="fill"
                        style="position:absolute;height:100%;width:100%;left:0;top:0;right:0;bottom:0;color:transparent"
                        src="/images/challenges/tsperf/twitter2.png"
                      />
                    </div>
                  </div>
                  <div class="relative aspect-[813/1008] w-full overflow-hidden rounded-xl shadow-[0px_3.26536px_2.21381px_0px_rgba(30,_27,_75,_0.08),_0px_7.84712px_5.32008px_0px_rgba(30,_27,_75,_0.11),_0px_14.77543px_10.01724px_0px_rgba(30,_27,_75,_0.14),_0px_26.35684px_17.86905px_0px_rgba(30,_27,_75,_0.16),_0px_49.29758px_33.42209px_0px_rgba(30,_27,_75,_0.19),_0px_118px_80px_0px_rgba(30,_27,_75,_0.27)] ring-1 ring-white/15">
                    <img
                      alt="Discussion on Twitter"
                      loading="lazy"
                      decoding="async"
                      data-nimg="fill"
                      style="position:absolute;height:100%;width:100%;left:0;top:0;right:0;bottom:0;color:transparent"
                      src="/images/challenges/tsperf/twitter.png"
                    />
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
