<script>
  import { clsx } from "clsx";
  import { twMerge } from "tailwind-merge";

  export let tech = [];
  export let classes = "";
  export let form;
  export let live;

  let input = "";
  let techMap = new Map();

  $: {
    techMap.clear();
    tech.forEach((tech) => {
      techMap.set(tech.toLowerCase(), tech);
    });
  }

  function cn(...inputs) {
    return twMerge(clsx(inputs));
  }

  function addTech(e) {
    if (e.key === "Enter" || e.key === ",") {
      e.preventDefault();
      const tech = input.trim();

      if (e.key === "Enter" && tech === "") {
        e.target.closest("form").requestSubmit();
        return;
      }

      const techLower = tech.toLowerCase();
      if (tech && !techMap.has(techLower)) {
        techMap.set(techLower, tech);
        updateTechStack();
      }
      input = "";
    }
  }

  function removeTech(tech) {
    techMap.delete(tech.toLowerCase());
    updateTechStack();
  }

  function updateTechStack() {
    const newTechStack = Array.from(techMap.values());
    tech = newTechStack;
    live.pushEvent("tech_stack_changed", { tech_stack: tech });
  }
</script>

<div class="mt-4">
  <input
    type="text"
    name={`${form}[tech_stack_input]`}
    bind:value={input}
    on:keydown={addTech}
    placeholder="Elixir, Phoenix, PostgreSQL, etc."
    class={cn(
      "bg-background block w-full rounded-lg border-input py-[7px] px-[11px] text-foreground focus:outline-none focus:ring-4 sm:text-sm sm:leading-6 phx-no-feedback:border-input phx-no-feedback:focus:border-ring phx-no-feedback:focus:ring-ring/5 focus:border-ring focus:ring-ring/5",
      classes
    )}
  />

  <input
    type="hidden"
    name={`${form}[tech_stack]`}
    value={JSON.stringify(tech)}
  />

    {#if tech?.length}
	  <div class="flex flex-wrap gap-3 mt-4">
      {#each tech as tech}
        <div
          class="bg-success/10 text-success rounded-lg px-3 py-1.5 text-sm font-semibold flex items-center"
        >
          {tech}
          <button
            type="button"
            class="ml-2 text-success hover:text-success/80"
            on:click={() => removeTech(tech)}
          >
            ×
            </button>
          </div>
        {/each}
      </div>
    {/if}
</div>
