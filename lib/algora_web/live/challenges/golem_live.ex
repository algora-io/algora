defmodule AlgoraWeb.Challenges.GolemLive do
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
              <section class="mb-24 min-h-[calc(100svh-88px)] md:mb-36">
                <div class="relative z-20 mx-auto max-w-7xl px-6 lg:px-8">
                  <div class="max-w-5xl pt-20 md:pt-36">
                    <div class="xh-[100svh] sm:h-auto">
                      <h1 class="mix-blend-exclusion">
                        <div class="flex items-center gap-3 md:gap-6">
                          <svg
                            xmlns="http://www.w3.org/2000/svg"
                            viewBox="0 0 450 113.5"
                            class="inline-block h-9 shrink-0 fill-current text-white md:h-20"
                          >
                            <g>
                              <g>
                                <g>
                                  <path d="m139.9,35.85c-5.68,5.82-8.71,13.5-8.52,21.63.39,16.11,14.07,29.22,30.51,29.22h29.35v-31.86h-28.84v8.89h19.95v14.07h-20.54c-11.44,0-21.1-9.07-21.52-20.22-.23-5.77,1.86-11.24,5.87-15.4,4-4.17,9.38-6.47,15.15-6.47h29.94v-8.89h-29.94c-8.11,0-15.71,3.21-21.41,9.03Z">
                                  </path>
                                  <path d="m230.89,25.7c-17.12,0-31.05,13.93-31.05,31.05s13.93,31.05,31.05,31.05,31.05-13.93,31.05-31.05-13.93-31.05-31.05-31.05Zm0,52.81c-12,0-21.76-9.76-21.76-21.76s9.76-21.76,21.76-21.76,21.77,9.76,21.77,21.76-9.76,21.76-21.77,21.76Z">
                                  </path>
                                  <path d="m279.44,77.79c0-2.58,0-8.59,0-8.63V26.91h-8.89v59.87h48.97v-8.89l-31.45-.08s-5.4,0-8.61,0Z">
                                  </path>
                                  <polygon points="379.07 26.82 327.15 26.82 327.15 86.69 379.07 86.69 379.07 86.69 379.07 77.8 335.96 77.8 335.96 58.23 367.99 58.23 367.99 49.34 367.99 49.34 335.96 49.34 335.96 35.71 379.07 35.71 379.07 26.82">
                                  </polygon>
                                  <path d="m440.68,33.36s-20.38,15.57-20.62,15.57-20.62-15.57-20.62-15.57l-9.32-7.16v60.5h8.89v-42.32l12.67,9.58,8.37,6.49,8.37-6.49,12.67-9.58v42.32h8.89V26.19l-9.32,7.16Z">
                                  </path>
                                </g>
                                <g>
                                  <polygon points="28.97 107.34 29.31 106.9 31.96 103.54 32.54 102.81 30.15 101.88 29.22 101.52 23.05 99.12 18.03 107.99 30.02 113.5 28.97 107.38 28.97 107.34">
                                  </polygon>
                                  <path d="m43.34,99.73l-8.45,3.1-.47.17.21.54.42,1.11.62,1.63.08.21h-.03s-.25.14-.25.14l-.09.04-.14.07-1.06.52-2.98,1.47-.08.04.11.13,1.53,1.84.39.47-1.06,2.29,20.84-5.52c.03-.1-2.51-10.75-2.45-10.87l-7.14,2.62Z">
                                  </path>
                                  <path d="m50.62,59.27l-2.54,1.43,1.94,2.24-13.83-5.4,5.28,7.56,2.37,3.38h0s2.77,3.97,2.77,3.97l-7.1-1.12,2.36,3.31v.02h.02l7.61,4.02h0l-12.15-2.76h0c-.7.96-3.58,3.25-4.6,4.8-.4,2.44-2.85,11.86-2.85,11.86l3.74,1.09,6.08,1.77h-.12s-.05,0-.05,0l-11.68-.5h0l-4.33,2.38h0s0,0,0,0c0,0,0,0,0,0,.01,0,.02,0,.05.02.31.09,1.73.48,3.42.94.91.25,1.9.52,2.85.78,1.46.4,2.79.76,3.57.97.08.02.17.05.24.06.3.08.47.13.47.13h0l10.14-2.91,3.91-1.12,2.23-.64h.03c0-.11,1.2-2.51,1.2-2.51h0c-.26-.26-4.19-4.16-4.34-4.32h0s2.61.2,2.61.2l2.85.23,4.27-3.24,4.27,3.24,2.85-.23,2.6-.21h0s-4.08,4.06-4.34,4.32h0s1.2,2.41,1.2,2.51l.07.02,2.17.62,3.87,1.11,10.17,2.92h.03s.17-.04.47-.12c.06-.02.14-.04.2-.06.77-.21,2.1-.57,3.56-.97.96-.26,1.96-.53,2.88-.79,1.69-.46,3.1-.85,3.42-.94,0,0,0,0,0,0,.03,0,.05-.02.06-.02l-4.34-2.39h0l-11.68.5h-.17s6.25-1.81,6.25-1.81l3.57-1.04s-2.45-9.42-2.85-11.86c-1.02-1.55-3.9-3.83-4.6-4.8h0s-12.14,2.76-12.14,2.76h0l7.61-4.02h.01s2.36-3.32,2.36-3.32h0s-7.1,1.12-7.1,1.12l2.8-3.94h0s8.25-13.3,8.25-13.3l-10.92,8.53,1.27-3.44-9.54-2.2-4.65-1.07-2.38,1.33-1.63.92Zm-4.97,28.53h0l-7.61-3.48-4.34,7.93,1.08-8.9v-.09s-.25-.35-.25-.35h0l-1.24-1.67,4.29,1.22.25.07,5.46-2.89h0s-1.56,3.12-1.56,3.12l3.96,5.06h-.02Zm25.1-8.16h0s5.46,2.88,5.46,2.88l.24-.07,4.3-1.22-1.24,1.67h0l-.26.35v.09s1.09,8.9,1.09,8.9l-4.34-7.93-7.62,3.48h-.02s3.96-5.05,3.96-5.05l-1.56-3.12Z">
                                  </path>
                                  <polygon points="90.93 99.14 84.73 101.54 83.84 101.89 81.47 102.81 81.47 102.81 82.04 103.53 84.7 106.9 85.05 107.34 85.04 107.38 84.02 113.33 83.99 113.5 95.98 107.99 90.96 99.12 90.93 99.14">
                                  </polygon>
                                  <path d="m79.82,107.26l-1.05-.52-.24-.12-.27-.13.09-.24.61-1.58.44-1.16.19-.5-.08-.03-.42-.15-8.5-3.12-7.06-2.59s0,0,0,.01c.01.31-2.48,10.76-2.45,10.86l20.8,5.51h0s.03,0,.03,0l-.02-.04-1.04-2.25.38-.45,1.51-1.81.15-.18-.11-.05-2.96-1.46Z">
                                  </path>
                                  <path d="m104.36,57.96l9.65-12-.83-2.33-4.68,1.83-4.54,1.78,7.89-9.07-11.83-13.54-5.61.91,1.44-2.94h-.01s0,0,0,0l-7.83-.24-1.65-.05h0l.84-3.81h0s0,0,0,0l.69-3.13-15.5-14.09-15.25-1.27-2.2,3.98h0l-3.82,6.91-10.78-7.49h.01s0,0,0,0l-15.5,10.24.31,2.65.32,2.74.39,3.39-7.71-5,1.23,6.7-4.53-.89-12.7,14.96h0s7.89,9.06,7.89,9.06l-4.55-1.78h0s-4.67-1.83-4.67-1.83l-.84,2.33h0s9.65,12,9.65,12l-6.74-3.76h0s-2.14-1.19-2.14-1.19l.72,22.37,8.72,9.31,13.13,2.27,4.17-6.29-6.02-2.39h0s-7.37,1.16-7.37,1.16l2.15-1.78h0s1.26-1.05,1.26-1.05l5.41-.56.89-2.59-3.73-1.4h0s-10.33,2.21-10.33,2.21l.87-2.55,1.4-4.1,6.34-2.32-.97-1.82h0s-1.72-3.24-1.72-3.24l10.78,4.59h0s7.3-4.36,7.3-4.36l1.48-4.77-4.92-1.45-1.74-4.35-10.85-2.32,2.2-14.43.17-1.13-6.96,2.12,6.76-7.31.56,3.02.36,1.95.16.86,2.37,12.88,5.91-3.72h0s.66-.41.66-.41l.42,2.39h0s.7,3.98.7,3.98l.52,2.92,4.49,2.41,10.15,5.44h0s.06.07.06.07l-.03-.05h.04s3.33-.6,3.33-.6l.62-.11,4.42-.79h6s9.4-.02,9.4-.02l3.24-5.74h0s.01-.03.01-.03h.01s4.83-4.14,4.83-4.14h0s1.39-1.2,1.39-1.2l2.46,4.96,8.44-17.21,1-2.03,1.36-2.77.78-1.58,7.32,6.85-8.81-2.33-.68,2.64-1.88,7.34,7.23,1.58-11.43,4.95-3.31,8.56-3.42-6.98,1.67,10.57,7.3,4.37,10.78-4.59-1.72,3.25-.97,1.82,6.34,2.31,1.39,4.1.87,2.55-10.34-2.21-3.73,1.4.89,2.59,5.41.57,1.27,1.05,2.14,1.78-7.37-1.15-6.03,2.39,4.18,6.29,13.13-2.27,8.72-9.31.72-22.37-2.14,1.19-6.74,3.76Zm-36.23-40.2l5.35.05-4.43,1.78-4.13,3.77,3.21-5.61Zm.36,3.98l4.23-.56,3.01,3.72-4.08-1.48-2.24.46-8.41,5.5,7.49-7.64Zm-23.57,2.6l3.77,6.01,3.52,1.63-3.47-.1-5.3-4.79-4.94-.92,6.42-1.83Zm-13.19,13.49l.85-9.75,7.75,2.53,3.51,1.03,4.18,2.78,6.53,4.34-7.04,5.24-8.44.63-7.33-6.8Zm23.81,13.07l-10.99-4.39,11.03,1.92,11.02-1.92-11.06,4.39Zm17.09-6.27l-8.44-.63-7.04-5.24,6.53-4.34,4.18-2.78,3.51-1.03,7.75-2.53.85,9.75-7.33,6.8Z">
                                  </path>
                                  <polygon points="18.17 17.4 18.16 17.4 18.16 17.4 18.17 17.4">
                                  </polygon>
                                  <path d="m32.88,37.33l4.54,3.42c-.56-1.06-.88-2.31-.88-3.66,0-2.45,1.09-4.6,2.72-5.84l-5.75-1.84-.63,7.92Z">
                                  </path>
                                  <path d="m48.38,36.06c.04.34.09.68.09,1.04,0,1.98-.71,3.74-1.83,5.01h.07s5.08-3.79,5.08-3.79l-3.41-2.26Z">
                                  </path>
                                  <path d="m44.91,34.44c-1.19,0-2.16.92-2.16,2.06s.97,2.06,2.16,2.06,2.16-.92,2.16-2.06-.97-2.06-2.16-2.06Z">
                                  </path>
                                  <path d="m72.41,31.26c1.63,1.24,2.72,3.39,2.72,5.84,0,1.34-.33,2.59-.88,3.66l4.54-3.42-.63-7.92-5.75,1.84Z">
                                  </path>
                                  <path d="m63.29,36.06l-3.41,2.26,5.08,3.79h.07c-1.12-1.27-1.83-3.03-1.83-5.01,0-.36.04-.7.09-1.04Z">
                                  </path>
                                  <path d="m66.76,34.44c-1.19,0-2.16.92-2.16,2.06s.97,2.06,2.16,2.06,2.16-.92,2.16-2.06-.97-2.06-2.16-2.06Z">
                                  </path>
                                </g>
                              </g>
                            </g>
                          </svg><span class="font-display text-[1.75rem] tracking-tight md:text-[4rem]">CHALLENGE</span>
                        </div>
                        <div class="hidden pt-2 text-[3rem] font-black tracking-tighter md:block">
                          Win<!-- -->
                          <span class="-mr-1 bg-gradient-to-r from-green-300 to-teal-400 bg-clip-text font-display font-bold text-transparent">
                            $15,000<!-- -->
                          </span>
                          and land a fantastic 🦀<!-- -->
                          <span class="-mr-1 bg-gradient-to-r from-orange-500 to-orange-400 bg-clip-text font-mono text-transparent">Rust<!-- --></span>job!
                        </div>
                        <div class="block pt-2 text-[1.5rem] font-black tracking-tighter md:hidden">
                          <div>
                            Win<!-- -->
                            <span class="-mr-1 bg-gradient-to-r from-green-300 to-teal-400 bg-clip-text font-display font-bold text-transparent">
                              $15,000<!-- -->
                            </span>
                          </div>
                          <div>
                            Land a fantastic 🦀<!-- -->
                            <span class="-mr-1 bg-gradient-to-r from-orange-500 to-orange-400 bg-clip-text font-mono text-transparent">Rust<!-- --></span>job!
                          </div>
                        </div>
                      </h1>
                      <p class="mt-2 text-base font-medium tracking-tight text-white/90 shadow-black [text-shadow:_0_1px_0_var(--tw-shadow-color)] md:mt-4 md:text-lg md:text-white/80">
                        Bounty-to-hire challenge by<!-- -->
                        <a
                          class="font-semibold text-white underline"
                          href="https://github.com/golemcloud/golem"
                        >Golem</a>, an open-source platform for building and deploying reliable distributed systems
                      </p>
                    </div>
                    <div class="mt-4 flex flex-col gap-2 text-sm font-medium md:mt-8 md:text-base">
                      <div class="flex items-center gap-2">
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
                          class="h-7 w-7 shrink-0 text-white"
                        >
                          <path d="M4 13a8 8 0 0 1 7 7a6 6 0 0 0 3 -5a9 9 0 0 0 6 -8a3 3 0 0 0 -3 -3a9 9 0 0 0 -8 6a6 6 0 0 0 -5 3">
                          </path>
                          <path d="M7 14a6 6 0 0 0 -3 6a6 6 0 0 0 6 -3"></path>
                          <path d="M15 9m-1 0a1 1 0 1 0 2 0a1 1 0 1 0 -2 0"></path>
                        </svg><span class="shadow-black [text-shadow:_0_1px_0_var(--tw-shadow-color)]">Tackle a challenging Rust-based task in Golem's open-source codebase</span>
                      </div>
                      <div class="flex items-center gap-2">
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
                          class="h-7 w-7 shrink-0 text-white"
                        >
                          <path d="M6 5h12l3 5l-8.5 9.5a.7 .7 0 0 1 -1 0l-8.5 -9.5l3 -5"></path>
                          <path d="M10 12l-2 -2.2l.6 -1"></path>
                        </svg><span class="shadow-black [text-shadow:_0_1px_0_var(--tw-shadow-color)]">Best implementation wins a<!-- --><span class="font-semibold">$15,000</span> bounty</span>
                      </div>
                      <div class="flex items-center gap-2">
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
                          class="h-7 w-7 shrink-0 text-white"
                        >
                          <path d="M10 13a2 2 0 1 0 4 0a2 2 0 0 0 -4 0"></path>
                          <path d="M8 21v-1a2 2 0 0 1 2 -2h4a2 2 0 0 1 2 2v1"></path>
                          <path d="M15 5a2 2 0 1 0 4 0a2 2 0 0 0 -4 0"></path>
                          <path d="M17 10h2a2 2 0 0 1 2 2v1"></path>
                          <path d="M5 5a2 2 0 1 0 4 0a2 2 0 0 0 -4 0"></path>
                          <path d="M3 13v-1a2 2 0 0 1 2 -2h2"></path>
                        </svg><span class="shadow-black [text-shadow:_0_1px_0_var(--tw-shadow-color)]">Collaborate with and learn from top-tier Rust developers</span>
                      </div>
                      <div class="flex items-center gap-2">
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
                          class="h-7 w-7 shrink-0 text-white"
                        >
                          <path d="M16 18a2 2 0 0 1 2 2a2 2 0 0 1 2 -2a2 2 0 0 1 -2 -2a2 2 0 0 1 -2 2zm0 -12a2 2 0 0 1 2 2a2 2 0 0 1 2 -2a2 2 0 0 1 -2 -2a2 2 0 0 1 -2 2zm-7 12a6 6 0 0 1 6 -6a6 6 0 0 1 -6 -6a6 6 0 0 1 -6 6a6 6 0 0 1 6 6z">
                          </path>
                        </svg><span class="shadow-black [text-shadow:_0_1px_0_var(--tw-shadow-color)]">Showcase your skills to a wider open-source community</span>
                      </div>
                      <div class="flex items-center gap-2">
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
                          class="h-7 w-7 shrink-0 text-white"
                        >
                          <path d="M3 7m0 2a2 2 0 0 1 2 -2h14a2 2 0 0 1 2 2v9a2 2 0 0 1 -2 2h-14a2 2 0 0 1 -2 -2z">
                          </path>
                          <path d="M8 7v-2a2 2 0 0 1 2 -2h4a2 2 0 0 1 2 2v2"></path>
                          <path d="M12 12l0 .01"></path>
                          <path d="M3 13a20 20 0 0 0 18 0"></path>
                        </svg><span class="shadow-black [text-shadow:_0_1px_0_var(--tw-shadow-color)]">Potential opportunity to<!-- --><span class="font-semibold">join Golem's elite engineering team</span></span>
                      </div>
                    </div>
                  </div>
                </div>
                <div
                  class="absolute inset-0 z-10 h-[100svh]"
                  style="background:linear-gradient(90deg, rgba(28, 26, 29, 0.4) 0%, rgba(28, 26, 29, 0) 64.42%),linear-gradient(0deg, #050217 1%, rgba(28, 26, 29, 0) 30%)"
                >
                </div>
                <div class="absolute inset-0 z-0 h-[100svh]">
                  <img
                    src="/images/challenges/golem/bg.png"
                    alt="Background"
                    class="h-full w-full object-cover object-[calc(-30vw_-_400px)_0] sm:object-[calc(-30vw_-_350px)_0] md:object-[calc(-30vw_-_350px)_0] lg:object-[0_-35vh] xl:object-[0_-40vh]"
                  />
                </div>
              </section>
              <section class="md:mb-18 mb-12">
                <div class="relative z-50 mx-auto max-w-7xl px-6 pt-6 lg:px-8">
                  <h2 class="text-2xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-5xl">
                    Who should participate
                  </h2>
                  <ul class="mt-4 space-y-1.5">
                    <li class="flex w-full items-start justify-between text-left text-white">
                      <span class="text-base font-medium leading-7">
                        • Rust developers looking for their next exciting career move
                      </span>
                    </li>
                    <li class="flex w-full items-start justify-between text-left text-white">
                      <span class="text-base font-medium leading-7">
                        • Open-source enthusiasts eager to contribute to a cutting-edge project
                      </span>
                    </li>
                    <li class="flex w-full items-start justify-between text-left text-white">
                      <span class="text-base font-medium leading-7">
                        • Developers keen on earning a substantial bounty for their coding prowess
                      </span>
                    </li>
                    <li class="flex w-full items-start justify-between text-left text-white">
                      <span class="text-base font-medium leading-7">
                        • Anyone interested in expanding their Rust portfolio and skills
                      </span>
                    </li>
                  </ul>
                  <p class="mt-4 text-sm font-medium text-gray-200">
                    Whether you're happily employed or on the job hunt, all are welcome! This is your chance to work on great open source, build your resume, and potentially get paid for your efforts.
                  </p>
                </div>
              </section>
              <section class="md:mb-18 mb-12">
                <div class="relative z-50 mx-auto max-w-7xl px-6 pt-6 lg:px-8">
                  <h2 class="text-2xl font-black leading-none tracking-tighter mix-blend-exclusion md:text-5xl">
                    How to get involved
                  </h2>
                  <ul class="mt-4 space-y-2 divide-y divide-white/20">
                    <li class="flex w-full items-start justify-between pt-2 text-left text-white">
                      <span class="text-base font-medium leading-7">
                        1.<a
                          target="_blank"
                          class="font-semibold text-white underline"
                          href="https://share.hsforms.com/1R0dEmbBARr2VZeL9D5aExQ444dk"
                        >Sign up for the launch event</a>
                        <!-- -->on Friday, October 11th at 12 PM ET
                      </span>
                    </li>
                    <li class="flex w-full items-start justify-between pt-2 text-left text-white">
                      <span class="text-base font-medium leading-7">
                        2.<a
                          target="_blank"
                          class="font-semibold text-white underline"
                          href="https://github.com/golemcloud/golem/issues/1004"
                        >Learn about the task and requirements</a>
                      </span>
                    </li>
                    <li class="flex w-full items-start justify-between pt-2 text-left text-white">
                      <span class="text-base font-medium leading-7">
                        3. Submit your pull request with your implementation
                      </span>
                    </li>
                    <li class="flex w-full items-start justify-between pt-2 text-left text-white">
                      <span class="text-base font-medium leading-7">
                        4. Potentially win the bounty and/or land a fantastic new Rust position!
                      </span>
                    </li>
                  </ul>
                  <p class="mt-4 text-sm font-medium text-gray-200">
                    Questions?<!-- -->
                    <a
                      target="_blank"
                      class="font-semibold text-white underline"
                      href="https://discord.com/invite/c3esdEfywj#durablecomputing"
                    >Join the Golem community on Discord</a>, where we're actively answering them!
                  </p>
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
