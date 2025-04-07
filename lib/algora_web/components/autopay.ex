defmodule AlgoraWeb.Components.Autopay do
  @moduledoc false
  use AlgoraWeb.Component

  def autopay(assigns) do
    ~H"""
    <div class="flex w-full flex-col space-y-3 sm:w-auto">
      <div
        class="w-full items-center rounded-md bg-gradient-to-b from-gray-400 to-gray-800 p-px"
        style="opacity: 1; transform: translateX(0.2px) translateZ(0px);"
      >
        <div class="flex items-center space-x-2 rounded-md bg-gradient-to-b from-gray-800 to-gray-900 p-2">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 20 20"
            fill="currentColor"
            aria-hidden="true"
            class="h-4 w-4 text-success-500"
          >
            <path
              fill-rule="evenodd"
              d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z"
              clip-rule="evenodd"
            >
            </path>
          </svg>
          <p class="pb-8 font-sans text-sm text-gray-200 last:pb-0">
            Merged pull request
          </p>
        </div>
      </div>
      <div
        class="w-full items-center rounded-md bg-gradient-to-b from-gray-400 to-gray-800 p-px"
        style="opacity: 1; transform: translateX(0.2px) translateZ(0px);"
      >
        <div class="flex items-center space-x-2 rounded-md bg-gradient-to-b from-gray-800 to-gray-900 p-2">
          <svg
            xmlns="http://www.w3.org/2000/svg"
            viewBox="0 0 20 20"
            fill="currentColor"
            aria-hidden="true"
            class="h-4 w-4 text-success-500"
          >
            <path
              fill-rule="evenodd"
              d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.857-9.809a.75.75 0 00-1.214-.882l-3.483 4.79-1.88-1.88a.75.75 0 10-1.06 1.061l2.5 2.5a.75.75 0 001.137-.089l4-5.5z"
              clip-rule="evenodd"
            >
            </path>
          </svg>
          <p class="pb-8 font-sans text-sm text-gray-200 last:pb-0">
            Charged saved payment method
          </p>
        </div>
      </div>
      <div
        class="w-full items-center rounded-md bg-gradient-to-b from-gray-400 to-gray-800 p-px"
        style="opacity: 0.7; transform: translateX(0.357815px) translateZ(0px);"
      >
        <div class="flex items-center space-x-2 rounded-md bg-gradient-to-b from-gray-800 to-gray-900 p-2">
          <svg
            width="20"
            height="20"
            viewBox="0 0 20 20"
            fill="none"
            xmlns="http://www.w3.org/2000/svg"
            class="h-4 w-4 animate-spin motion-reduce:hidden"
          >
            <rect
              x="2"
              y="2"
              width="16"
              height="16"
              rx="8"
              stroke="rgba(59, 130, 246, 0.4)"
              stroke-width="3"
            >
            </rect>
            <path
              d="M10 18C5.58172 18 2 14.4183 2 10C2 5.58172 5.58172 2 10 2"
              stroke="rgba(59, 130, 246)"
              stroke-width="3"
              stroke-linecap="round"
            >
            </path>
          </svg>
          <p class="pb-8 font-sans text-sm text-gray-400 last:pb-0">
            Transferring funds to contributor
          </p>
        </div>
      </div>
    </div>
    """
  end
end
