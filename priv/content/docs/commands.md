---
title: Slash commands reference
---

# Slash commands reference

<div class="scrollbar-thin w-full overflow-auto">
  <table class="caption-bottom w-full text-sm -ml-4">
    <thead class="[&amp;_tr]:border-b">
      <tr class="border-b transition-colors hover:bg-gray-100/50 data-[state=selected]:bg-gray-100 dark:hover:bg-white/[2.5%] dark:data-[state=selected]:bg-gray-800">
        <th class="h-12 px-4 text-left align-middle font-medium text-gray-500 dark:text-gray-400 [&amp;:has([role=checkbox])]:pr-0">
          Command
        </th>
        <th class="h-12 px-4 text-left align-middle font-medium text-gray-500 dark:text-gray-400 [&amp;:has([role=checkbox])]:pr-0">
          Description
        </th>
        <th class="h-12 px-4 text-left align-middle font-medium text-gray-500 dark:text-gray-400 [&amp;:has([role=checkbox])]:pr-0">
          Where
        </th>
      </tr>
    </thead>
    <tbody class="[&amp;_tr:last-child]:border-0">
      <tr
        class="border-b transition-colors hover:bg-gray-100/50 data-[state=selected]:bg-gray-100 dark:hover:bg-white/[2.5%] dark:data-[state=selected]:bg-gray-800"
        data-state="false"
      >
        <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0">
          <div class="whitespace-nowrap font-mono text-sm font-semibold leading-6 text-emerald-300">
            /bounty $500
          </div>
        </td>
        <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0">
          <div class="whitespace-nowrap font-mono text-sm font-normal text-gray-300">
            Create a $500 bounty
          </div>
        </td>
        <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0">
          <div class="whitespace-nowrap font-mono text-sm font-normal text-gray-300">
            Issue/PR comment
          </div>
        </td>
      </tr>
      <tr
        class="border-b transition-colors hover:bg-gray-100/50 data-[state=selected]:bg-gray-100 dark:hover:bg-white/[2.5%] dark:data-[state=selected]:bg-gray-800"
        data-state="false"
      >
        <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0">
          <div class="whitespace-nowrap font-mono text-sm font-semibold leading-6 text-emerald-300">
            /tip $100
          </div>
        </td>
        <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0">
          <div class="whitespace-nowrap font-mono text-sm font-normal text-gray-300">
            Tip the author $100
          </div>
        </td>
        <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0">
          <div class="whitespace-nowrap font-mono text-sm font-normal text-gray-300">
            Issue/PR comment
          </div>
        </td>
      </tr>
      <tr
        class="border-b transition-colors hover:bg-gray-100/50 data-[state=selected]:bg-gray-100 dark:hover:bg-white/[2.5%] dark:data-[state=selected]:bg-gray-800"
        data-state="false"
      >
        <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0">
          <div class="whitespace-nowrap font-mono text-sm font-semibold leading-6 text-emerald-300">
            /tip $100 @jsmith
          </div>
        </td>
        <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0">
          <div class="whitespace-nowrap font-mono text-sm font-normal text-gray-300">
            Tip the Github user with jsmith handle $100
          </div>
        </td>
        <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0">
          <div class="whitespace-nowrap font-mono text-sm font-normal text-gray-300">
            Issue/PR comment
          </div>
        </td>
      </tr>
      <tr
        class="border-b transition-colors hover:bg-gray-100/50 data-[state=selected]:bg-gray-100 dark:hover:bg-white/[2.5%] dark:data-[state=selected]:bg-gray-800"
        data-state="false"
      >
        <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0">
          <div class="whitespace-nowrap font-mono text-sm font-semibold leading-6 text-emerald-300">
            /attempt #137
          </div>
        </td>
        <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0">
          <div class="whitespace-nowrap font-mono text-sm font-normal text-gray-300">
            Declare that you started working on the issue #137
          </div>
        </td>
        <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0">
          <div class="whitespace-nowrap font-mono text-sm font-normal text-gray-300">
            Issue comment
          </div>
        </td>
      </tr>
      <tr
        class="border-b transition-colors hover:bg-gray-100/50 data-[state=selected]:bg-gray-100 dark:hover:bg-white/[2.5%] dark:data-[state=selected]:bg-gray-800"
        data-state="false"
      >
        <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0">
          <div class="whitespace-nowrap font-mono text-sm font-semibold leading-6 text-emerald-300">
            /claim #137
          </div>
        </td>
        <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0">
          <div class="whitespace-nowrap font-mono text-sm font-normal text-gray-300">
            Submit an individual claim for the bounty of the issue #137
          </div>
        </td>
        <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0">
          <div class="whitespace-nowrap font-mono text-sm font-normal text-gray-300">PR body</div>
        </td>
      </tr>
      <tr
        class="border-b transition-colors hover:bg-gray-100/50 data-[state=selected]:bg-gray-100 dark:hover:bg-white/[2.5%] dark:data-[state=selected]:bg-gray-800"
        data-state="false"
      >
        <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0">
          <div class="whitespace-nowrap font-mono text-sm font-semibold leading-6 text-emerald-300">
            /claim #137 <br />/split @jsmith <br />/split @jdoe
          </div>
        </td>
        <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0">
          <div class="whitespace-nowrap font-mono text-sm font-normal text-gray-300">
            Submit a joint claim for the bounty of the issue #137<br />In this example, the award would be split evenly into 3
          </div>
        </td>
        <td class="p-4 align-middle [&amp;:has([role=checkbox])]:pr-0">
          <div class="whitespace-nowrap font-mono text-sm font-normal text-gray-300">PR body</div>
        </td>
      </tr>
    </tbody>

  </table>
</div>
