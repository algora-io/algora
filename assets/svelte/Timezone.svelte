<script>
  import { onMount } from 'svelte';
  export let live;

  let timezone = Intl.DateTimeFormat().resolvedOptions().timeZone;

  onMount(() => {
    // Send timezone on component mount
    live.pushEvent('timezone_changed', { timezone });
  });
</script>

<input type="hidden" name="timezone" value={timezone} /> 